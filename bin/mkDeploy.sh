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

BASE=$(mktemp -d)

function md2pdf() {
    pandoc -o $1.docx $1.md
    lowriter --convert-to pdf $1.docx >/dev/null 2>&1
    rm -f $1.docx
}

go build -o bin/opgp2rsa ./src/opgp2rsa
go build -o bin/rsa2opgp ./src/rsa2opgp
go build -o bin/vanityid ./src/vanityid
md2pdf README
md2pdf TOKEN
md2pdf BUILD

mkdir -p ${BASE}/openpgp-mgmt/{bin,conf,inst}

cp bin/init-coldstore.sh       ${BASE}/openpgp-mgmt/bin/
cp bin/mount-coldstore.sh      ${BASE}/openpgp-mgmt/bin/
cp bin/unmount-coldstore.sh    ${BASE}/openpgp-mgmt/bin/
cp bin/setup-system.sh         ${BASE}/openpgp-mgmt/bin/
cp bin/mgmt-mt.sh              ${BASE}/openpgp-mgmt/bin/
cp bin/mgmt-ot.sh              ${BASE}/openpgp-mgmt/bin/
cp bin/opgp2rsa                ${BASE}/openpgp-mgmt/bin/
cp bin/rsa2opgp                ${BASE}/openpgp-mgmt/bin/
cp bin/vanityid                ${BASE}/openpgp-mgmt/bin/

cp conf/gpg-agent.conf         ${BASE}/openpgp-mgmt/conf/
cp conf/gnupg-pkcs11-scd.conf  ${BASE}/openpgp-mgmt/conf/

cp inst/firewall               ${BASE}/openpgp-mgmt/inst/
cp inst/libssl1.1_amd64.deb    ${BASE}/openpgp-mgmt/inst/

cp README.pdf                  ${BASE}/openpgp-mgmt/
cp TOKEN.pdf                   ${BASE}/openpgp-mgmt/
cp BUILD.pdf                   ${BASE}/openpgp-mgmt/

chmod -R o-rwx ${BASE}/*

tar czf openpgp-mgmt-deploy.tar.gz -C ${BASE} .
