#!/bin/bash -e

# This file is part of openpgp-mgmt.
# Copyright (C) 2019-2024 Bernd Fix  >Y<
#
# openpgp-mgmt is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# openpgp-mgmt is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL3.0-or-later

# make sure we run this script as root
if [ $(id -u) -ne 0 ]; then
        exec sudo $0 $*
        echo "Can't run script as root -- aborting..."
        exit 1
fi

# check if already mounted
if [ -e /dev/mapper/coldstore ]; then
    echo "COLD STORAGE already mounted -- aborting."
    exit 1
fi

# check if a device is specified
DEV=/dev/$1
if [ -z "${DEV}" -o ! -e ${DEV} ]; then
    echo "No (valid) device specified -- aborting."
    exit 1
fi

# check mount point
MNT=${2:-/mnt}
if [ ! -d ${MNT} ]; then
    echo "mount point ${MNT} does not exist -- aborting."
    exit 1
fi

# mount cold storage
cryptsetup open ${DEV} coldstore
mount /dev/mapper/coldstore ${MNT}

exit 0
