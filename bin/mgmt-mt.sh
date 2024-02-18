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

# generate start script for management shell
RC=$(mktemp)
cat > ${RC} <<"EOF"
BASE=$(mktemp -d)
export GNUPGHOME="${BASE}/.gnupg"
mkdir ${GNUPGHOME}
chmod 700 ${GNUPGHOME}
cp conf/gpg-agent.conf ${GNUPGHOME}
cp conf/gnupg-pkcs11-scd.conf ${GNUPGHOME}
export PKCS11LIB=@PKCS11LIB@
alias p11t="pkcs11-tool --module ${PKCS11LIB}"
export PS1="\w:\033[01;31m\]mt\033[00m\]% "
cd ${BASE}
EOF

case "$1" in
    # tokens supported for productive use
    et5110cc)
        PKCS11LIB=/usr/lib/libIDPrimePKCS11.so
        ;;
    schsm4k)
        PKCS11LIB=/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
        ;;
    nkhsm2)
        PKCS11LIB=/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
        ;;
    # tokens supported for testing ONLY (limited to RSA-2048)!
    yubikey)
        PKCS11LIB=/usr/lib/x86_64-linux-gnu/libykcs11.so
        ;;
    *)
        echo "unknown token '$1': must be 'schsm4k', 'et5110cc', 'nkhsm2' or 'yubikey'"
        exit 1
esac

sed -i -e "s%@PKCS11LIB@%${PKCS11LIB}%" ${RC}
bash --rcfile <(cat ${RC})
