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

# check if mounted
if [ ! -e /dev/mapper/coldstore ]; then
    echo "COLD STORAGE not mounted -- aborting."
    exit 1
fi

# check mount point
MNT=${1:-/mnt}
if [ ! -d ${MNT} ]; then
    echo "mount point ${MNT} does not exist -- aborting."
    exit 1
fi

# unmount cold storage
umount ${MNT}
cryptsetup close coldstore

exit 0
