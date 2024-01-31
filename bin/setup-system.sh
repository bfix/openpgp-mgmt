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

# make sure that script runs as 'root'
if [ $(id -u) -ne 0 ]; then
    exec sudo $0 $*
    echo "Can't run script as root -- aborting..."
    exit 1
fi

# optionally install firewall script
if [ ! -f /etc/init.d/firewall ]; then
    cp inst/firewall /etc/init.d/
    chmod 750 /etc/init.d/firewall
    update-rc.d firewall defaults
fi

# install required common Debian packages
apt update
apt install \
    iptables \
    gnupg2 \
    pinentry-gtk2 \
    pinentry-curses \
    scdaemon \
    pcscd \
    libpcsclite1 \
    gnupg-pkcs11-scd \
    opensc \
    opensc-pkcs11 \
    secure-delete \
    yubikey-manager

exit 0
