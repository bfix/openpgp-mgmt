#!/bin/bash

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

BASE=$(mktemp -d)

# cold storage device detection
echo "Make sure that the COLD STORAGE stick is unplugged."
echo "Press ENTER to continue..."
read
lsblk -d > ${BASE}/1

echo "Plug-in the COLD STORAGE stick."
echo "Press ENTER when done..."
read
lsblk -d > ${BASE}/2

SPEC=$(diff ${BASE}/{1,2} | grep "^>" | tr -s " ")
rm ${BASE}/{1,2}
if [ -z "${SPEC}" ]; then
    echo "No new device detected -- please try again..."
    exit 1
fi

DVCE=$(echo $SPEC | cut -d " " -f 2)
SIZE=$(echo $SPEC | cut -d " " -f 5)
TYPE=$(echo $SPEC | cut -d " " -f 7)
if [ ${TYPE} != "disk" ]; then
    echo "New device is of type '${TYPE}', not 'disk' as expected."
    echo "Please try again with another device."
    exit 1
fi
echo "Found a device with capacity ${SIZE} at /dev/${DVCE}."
read -p "Do you want to proceed? Enter YES (in captial letters): " yn
if [ ${yn} != "YES" ]; then
    echo "Terminating -- COLD STORAGE was NOT initialized."
    exit 1
fi
echo

# reparing the cold storage
echo "Resetting COLD STORAGE device..."
dd if=/dev/zero of=/dev/${DVCE} bs=16M count=1 2>/dev/null
echo "Encrypting COLD STORAGE device..."
cryptsetup luksFormat /dev/${DVCE}
echo
echo "Initializing COLD STORAGE device..."
cryptsetup open /dev/${DVCE} coldstore
if [ $? -ne 0 ]; then
    echo "Initialization failed -- please try again..."
    exit 1
fi
mkfs -t ext4 /dev/mapper/coldstore >/dev/null 2>&1

echo
echo "Closing COLD STORAGE device..."
cryptsetup close coldstore 2>/dev/null

echo
echo "COLD STORAGE successfully set-up."
echo "You can now unplug the device."

exit 0
