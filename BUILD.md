# Notice

This file is part of *openpgp-mgmt*. Copyright (C) 2019-2024 Bernd Fix  >Y<

*openpgp-mgmt* is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

*openpgp-mgmt* is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL3.0-or-later

<!-- markdownlint-disable MD014 -->
<!-- markdownlint-disable MD025 -->

# Building the deployment archive

You can build the deployment archive `openpgp-mgmt-deploy.tar.gz` by running the script `bin/mkDeploy.sh`. Building the archive requires the `pandoc` and `libreoffice` packages of your Linux distribution. You also need to [install Go v1.20+](https://go.dev/dl/) to compile the executables.

# Building OpenPGP management tools executables

This step is usually not required; all necessary tools come pre-compiled with the installation archive that is created running the `bin/mkDeploy.sh` script. In case you want to change the source code (for whatever reason), you can compile new executables for testing by following these instructions.

## Requirements

* [Go v1.20+](https://go.dev)

## opgp2rsa

`opgp2rsa` is a tool to convert the `RSA` private primary OpenPGP key to a format usable with PKCS #11 tokens.

    $ go build -o bin/opgp2rsa ./src/opgp2rsa

The tool requires commandline options when run:

    -i <key.asc>: armored OpenPGP key file (input)
    -o <key.pem>: PEM-encoded RSA key (output)
    -p <passphrase>: OpenPGP key passphrase (if key is encrypted)

## Additional executables

There are two additional executables bundled in this repo that are not (yet) required:

### rsa2opgp

`rsa2opgp` is a tool to convert a PEM-encoded private RSA key to a primary OpenPGP key.

    $ go build -o bin/rsa2opgp ./src/rsa2opgp

The tool requires commandline options when run:

    -i <key.pem>: PEM-encoded RSA key (input)
    -o <key.asc>: armored OpenPGP key (output)
    -d <YY-MM-DD_HH:MM:SS GMT>: desired creation date (default: current date)
    -n <name>: Name of key holder
    -c <comment>: Comment (optional)
    -e <email>: EMail address for OpenPGP key

### vanityid

`vanityid` is a tool to create vanity key identifiers for an OpenPGP key.

    $ go build -o bin/vanityid ./src/vanityid

The tool requires commandline options when run:

    -b <bits>: RSA key size (default: 4096)
    -o <folder>: folder for generated private keys
    -d <YY-MM-DD_HH:MM:SS GMT>: desired creation date (default: current date)
    -n <name>: Name of key holder
    -c <comment>: Comment (optional)
    -e <email>: EMail address for OpenPGP key
    -p <pattern>: desired hex pattern in keyid (regexp)
