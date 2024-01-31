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
export PS1="\w:\033[01;31m\]ot\033[00m\]% "
cd ${BASE}
EOF
bash --rcfile <(cat ${RC})
