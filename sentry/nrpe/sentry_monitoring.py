#!/usr/local/sentry/bin/python

"""
Create organization/team/user for sentry monitoring
"""

__author__ = 'Diep Pham'
__maintainer__ = 'Diep Pham'
__email__ = 'favadi@robotinfra.com'

import logging

import yaml

import pysc

# Bootstrap the Sentry environment
from sentry.utils.runner import configure
configure()

from sentry.models import (
    ApiKey,
    Organization,
    OrganizationMember,
    Project,
    ProjectKey,
    Team,
    User,
)

logger = logging.getLogger(__name__)


class SentryMonitoring(pysc.Application):
    def get_argument_parser(self):
        argp = super(SentryMonitoring, self).get_argument_parser()
        argp.add_argument(
            "--dsn-file", help="path to write monitoring sentry dsn",
            required=True)
        argp.add_argument(
            "--test", help="run in test mode", action="store_true")

        return argp

    def main(self):
        dsn_file = self.config["dsn_file"]
        test_mode = self.config["test"]

        # get or create monitoring user
        user, _ = User.objects.get_or_create(username="monitoring")
        user.is_superuser = False
        user.save()

        # get or create Monitoring organization
        organization, _ = Organization.objects.get_or_create(name="Monitoring")

        # Web API is now separated from client API
        api_key = ApiKey.objects.get_or_create(
            organization=organization,
            label='Monitoring'
        )

        organization_member, _ = OrganizationMember.objects.get_or_create(
            user=user,
            organization=organization,
            defaults={
                'role': 'member',
            }
        )

        # get or create Monitoring team
        team, _ = Team.objects.get_or_create(
            name="Monitoring",
            defaults={
                'organization': organization,
            }
        )

        # get or create Monitoring project
        project, _ = Project.objects.get_or_create(
            name="Monitoring",
            team=team,
            defaults={
                'organization': organization,
            }
        )

        key = ProjectKey.objects.get(project=project)
        key.roles = 3  # enable Web API access role
        key.save()

        dsn = key.get_dsn()
        # disable verify_ssl in test mode
        if test_mode:
            dsn += "?verify_ssl=0"

        with open(dsn_file, "w") as f:
            yaml.dump({"dsn": dsn}, f)

if __name__ == '__main__':
    SentryMonitoring().run()
