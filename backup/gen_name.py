#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
grandfather-father-son rotation name generator
https://help.ubuntu.com/lts/serverguide/backups-shellscripts-rotation.html
'''

__author__ = 'Viet Hung Nguyen'
__maintainer__ = 'Viet Hung Nguyen'
__email__ = 'hvn@unblockapp.com'

from datetime import datetime


SATURDAY_DAY_IN_WEEK = 5


def get_week_of_month(date):
    # day 1-7 is week 1, ...
    weekno = ((date.day - 1) // 7) + 1
    if weekno > 3:
        weekno = 4
    return 'week' + weekno


def get_month_order(date):
    return 'month2' if (date.month) % 2 == 0 else 'month1'


def get_grandfather_father_son_name():
    today = datetime.now()
    if today.day == 1:
        suffix = get_month_order(today)
    elif today.isoweekday() != SATURDAY_DAY_IN_WEEK:
        suffix = today.strftime('%A').lower()
    else:
        suffix = get_week_of_month()
    return suffix


def main():
    print get_grandfather_father_son_name()


if __name__ == "__main__":
    main()
