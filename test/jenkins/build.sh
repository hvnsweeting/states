#!/bin/bash
# Use of this is governed by a license that can be found in doc/license.rst.

# NOTICE: this script executed as jenkins user
# NOTICE: this script use special bash trap to handle error, do not set -e

set -x

BUILD_IDENTITY="integration-$JOB_NAME-${BUILD_DISPLAY_NAME/\#/}"

# allow multiple --repo options to get all non-common repositories
# each value passed to  --repo is relative path to user-specific directory from
# $WORKSPACE. The structure after all SCM checkout looks like:
#  - common
#  - pillar
#  - repo1
#  - repo2
# then use --repo repo1 --repo repo2
options=$(getopt \
    --options "" \
    --longoptions \
      "repo:,profile:,find-step-longer:,master-timeout:,failfast,destroy" \
    -- "$@")

if [[ $? -ne 0 ]]; then
    exit 1
fi
eval set -- "$options"
repos=()
profile='ci-minion'
time_threshold=30
master_timeout=300
failfast=""
tests=""


function destroy_test_vm() {
    sudo salt-cloud --destroy --assume-yes "$BUILD_IDENTITY"
}

while true; do
    case "$1" in
        --destroy)
            destroy_test_vm
            exit $?
            ;;
        --repo)
            shift
            repo="$1"
            repos+=("../$repo")
            ;;
        --profile)
            shift
            profile="$1"
            ;;
        --find-step-longer)
            shift
            time_threshold="$1"
            ;;
        --master-timeout)
            shift
            master_timeout="$1"
            ;;
        --failfast)
            failfast="--failfast"
            ;;
        --)
            shift
            break
            ;;
        esac
    shift
done

tests="$*"

PREPARE_STDOUT_LOG=/root/salt/stdout.prepare
PREPARE_STDERR_LOG=/root/salt/stderr.prepare
CUSTOM_CONFIG_DIR=/root/salt/states/test

function timer {
    finish_run_test_time=$(date +%s)
    echo "TIME-METER: Run integration.py took: $((finish_run_test_time - start_run_test_time)) seconds"
}

function destroy_vm_on_condition {
    if ${DESTROY_VM:-true}; then
        destroy_test_vm
    fi
}

function collect_logs {
    timer

    echo "Analysing stdout.log"
    sudo salt -t 30 "$BUILD_IDENTITY" --output json cmd.run "$CUSTOM_CONFIG_DIR/findgap.py --verbose --larger-equal $time_threshold /root/salt/stdout.log"

    echo "Start collecting log files..."
    for prepare_log in $PREPARE_STDOUT_LOG $PREPARE_STDERR_LOG; do
        sudo salt -t 30 "$BUILD_IDENTITY" --output json cmd.run "xz -c $prepare_log > /tmp/$BUILD_IDENTITY-$(basename $prepare_log).log.xz"
    done

    for ltype in stdout stderr; do
        sudo salt -t 30 "$BUILD_IDENTITY" --output json cmd.run "xz -c /root/salt/$ltype.log > /tmp/$BUILD_IDENTITY-$ltype.log.xz"
    done

    sudo salt -t 30 "$BUILD_IDENTITY" --output json cmd.run "tar -C /var/log -cJf /tmp/$BUILD_IDENTITY-upstart.log.tar.xz upstart syslog"
    echo "Finished collecting log files."

    sudo salt -t 30 "$BUILD_IDENTITY" --output yaml cmd.run "grep COUNTER: /root/salt/stdout.log"
    sudo salt -t 60 --verbose "$BUILD_IDENTITY" --output json cmd.run_all "salt-call -l info -c $CUSTOM_CONFIG_DIR state.sls test.jenkins.result"

    echo "Organizing files in current workspaces..."
    cp /home/ci-agent/$BUILD_IDENTITY-result.xml $WORKSPACE/result.xml

    for f in /home/ci-agent/$BUILD_IDENTITY-*.xz; do
      cp $f $WORKSPACE/`basename $f | sed "s/$BUILD_IDENTITY/$JOB_NAME/"`
    done
    mv /srv/salt/jenkins_archives/$BUILD_IDENTITY.tar.gz $WORKSPACE/bootstrap-archive.tar.gz

    echo "Start of error logs"
    xz -d -c /home/ci-agent/$BUILD_IDENTITY-stderr.log.xz
    echo "End of error logs."

    echo "TIME-METER: Total time: $(($(date +%s) - start_time)) seconds"
    destroy_vm_on_condition
}

function collect_logs_then_fail {
    exit 1
}

trap collect_logs_then_fail ERR
trap collect_logs EXIT

start_time=$(date +%s)
rm -f $WORKSPACE/bootstrap-archive.tar.gz $WORKSPACE/stderr.log.xz $WORKSPACE/stdout.log.xz $WORKSPACE/result.xml
rm -rf $WORKSPACE/salt-common-doc
virtualenv --system-site-packages $WORKSPACE/virtualenv
. $WORKSPACE/virtualenv/bin/activate

if [ "${with_ssl:-true}" = "false" ]; then
  find pillar -name '*.sls' -type f -exec sed -i -e 's/  ssl_redirect:.*//g' -e 's/  ssl:.*//g' {} \;
fi

if [ "${WITH_FILES_ARCHIVE:-true}" = "false" ]; then
  find pillar -name '*.sls' -type f -exec sed -i -e 's/^files_archive:.*//g' {} \;
fi

echo "---- Diff to Pillar ----"
(cd pillar; git diff)
echo "---- End of Diff to Pillar ----"

cd common
test/lint.py --warn-nonstable
pip install -r doc/requirements.txt
doc/build.py

# create archive from common, pillar, and all user-specific formulas repos
./bootstrap_archive.py ../pillar ${repos[@]} > /srv/salt/jenkins_archives/$BUILD_IDENTITY.tar.gz

sudo salt-cloud --profile $profile $BUILD_IDENTITY
sudo salt $BUILD_IDENTITY test.ping | grep True
sudo salt -t 10 "$BUILD_IDENTITY" cmd.run "hostname $BUILD_IDENTITY"
sudo salt -t 60 "$BUILD_IDENTITY" cp.get_file salt://jenkins_archives/$BUILD_IDENTITY.tar.gz /tmp/bootstrap-archive.tar.gz
sudo salt -t 60 "$BUILD_IDENTITY" cmd.run "tar -C / -xzf /tmp/bootstrap-archive.tar.gz"

function run_and_check_return_code {
    sudo salt -t $1 "$BUILD_IDENTITY" --output json cmd.run_all "$2" | ./test/jenkins/retcode_check.py
}

master_ip=$(sudo salt -t 60 "$BUILD_IDENTITY" --out=yaml grains.item master | cut -f2- -d ':' | tr -d '\n')
run_and_check_return_code 10 "sed -i \"s/master:.*/master: $master_ip/g\" $CUSTOM_CONFIG_DIR/minion"
run_and_check_return_code 20 "salt-call -c $CUSTOM_CONFIG_DIR saltutil.sync_all >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
run_and_check_return_code 600 "salt-call -c $CUSTOM_CONFIG_DIR state.sls test.sync >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
run_and_check_return_code 600 "salt-call -c $CUSTOM_CONFIG_DIR state.sls salt >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
sudo salt -t 60 "$BUILD_IDENTITY" cmd.run "$CUSTOM_CONFIG_DIR/jenkins/upgrade_salt.sh"
sudo salt -t 5 "$BUILD_IDENTITY" --output json cmd.run "salt-call test.ping"
echo '------------ From here, salt with version supported by salt-common is running ------------'
run_and_check_return_code 10 "salt-call -c $CUSTOM_CONFIG_DIR state.sls salt.patch_salt >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
sudo salt -t 20 "$BUILD_IDENTITY" --output json cmd.run "restart salt-minion"
# first cmd after restart often does not return, just ping
sudo salt -t 5 "$BUILD_IDENTITY" --output json cmd.run "salt-call test.ping"
# for some reasons, calling test.setup in integration.py using Caller interface sometimes does not sync the "fake" mine module
# move it here and let the saltutil.sync_all run one more time after that
run_and_check_return_code 600 "salt-call -c $CUSTOM_CONFIG_DIR state.sls test.setup >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
run_and_check_return_code 20 "salt-call -c $CUSTOM_CONFIG_DIR saltutil.sync_all >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
run_and_check_return_code 10 "salt-call -c $CUSTOM_CONFIG_DIR saltutil.refresh_modules >> $PREPARE_STDOUT_LOG 2>> $PREPARE_STDERR_LOG"
# ping again before run integration.py, thing may brake after refresh_modules.
sudo salt -t 5 "$BUILD_IDENTITY" --output json cmd.run "salt-call test.ping"
start_run_test_time=$(date +%s)
echo "TIME-METER: Preparing for test took: $((start_run_test_time - start_time)) seconds"
echo '------------ Running CI test  ------------'
sudo salt --verbose -t 100 "$BUILD_IDENTITY" cmd.run \
    "$CUSTOM_CONFIG_DIR/jenkins/run.py --dry-run $failfast $tests"

sudo salt --verbose -t "$master_timeout" "$BUILD_IDENTITY" cmd.run \
    "$CUSTOM_CONFIG_DIR/jenkins/run.py $failfast $tests"
finish_run_test_time=$(date +%s)
echo "TIME-METER: Run integration.py took: $((finish_run_test_time - start_run_test_time)) seconds"

sudo salt -t 5 "$BUILD_IDENTITY" --output json cmd.run "salt-call test.ping"
sudo salt -t 5 "$BUILD_IDENTITY" --output yaml cmd.run "cat /root/salt/*.xml"

echo "Check if cmd.run integration.py returned, if not, wait up to 5 minutes \
      for test finishing."
for i in {1..5}; do
  tmpfile=$(mktemp)
  sudo salt -t 5 "$BUILD_IDENTITY" --output yaml cmd.run 'ps xau | grep integration.p[y]' > ${tmpfile}
  if ( grep integration.p[y] ${tmpfile} ); then
     sleep 60
  fi
  rm -f ${tmpfile}
done

sudo salt -t 5 --verbose "$BUILD_IDENTITY" --output yaml cmd.run "salt-call -c $CUSTOM_CONFIG_DIR state.sls test.teardown -lerror"
