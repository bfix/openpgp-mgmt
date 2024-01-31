# Notice

This file is part of *openpgp-mgmt*. Copyright (C) 2019-2024 Bernd Fix  >Y<

*openpgp-mgmt* is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

*openpgp-mgmt* is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL3.0-or-later

# Building OpenPGP management tools

This step is usually not required; all necessary tools come pre-compiled with the installation archive. In case you want to change something (for whatever reason), you can do so by following these instructions.

## Requirements

* [Go v1.20+](https://go.dev)

## opgp2rsa

`opgp2rsa` is a tool to convert the `RSA` private primary OpenPGP key to a format usable with PKCS #11 tokens.

    $ cd /opt/openpgp-mgmt
    $ go build -o bin/opgp2rsa ./src/opgp2rsa
