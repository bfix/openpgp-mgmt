# Notice

This file is part of *openpgp-mgmt*. Copyright (C) 2019-2024 Bernd Fix  >Y<

*openpgp-mgmt* is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

*openpgp-mgmt* is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL3.0-or-later

<!-- markdownlint-disable MD014 -->
<!-- markdownlint-disable MD024 -->
<!-- markdownlint-disable MD025 -->

# Prepare the management token (MT)

Steps preparing the **MT** for use in our key management depend on the brand/model of the token you want to use:

## SmartCard-HSM 4k

*Hint*: The SmartCard-HSM is very well supported by the `opensc` framework and you can find more information and procedures in the [Github repository](https://github.com/OpenSC/OpenSC/wiki/SmartCardHSM) of the OpenSC project.

If the token is used for the first time (or needs to be re-initialized), perform the following steps as user:

    $ cd /opt/openpgp-mgmt
    $ bin/mgmt-mt.sh schsm4k

Run the following commands to initialize the token; you will set a new SO-PIN (16 hexadecimal characters) and a user PIN (6-digit number). Make sure you save the SO-PIN and user PIN to the **cold storage**.

    mt% sc-hsm-tool --initialize --label "openpgp-mgmt" --dkek-shares 1
    mt% sc-hsm-tool --create-dkek-share dkek-1.pbe

Save the file `dkek-1.pbe` and its password to **cold storage**

    mt% sc-hsm-tool --import-dkek-share dkek-1.pbe

The **MT** is now initialized and can be used for OpenPGP key management.

To use the `Smart Card Shell` (for importing existing keys to the token), please install a Java Runtime Environment

    # apt install openjdk-17-jre

and [download `scsh3`](https://www.openscdp.org/scsh3/download.html).

    $ cd /opt/openpgp-mgmt
    $ wget https://www.openscdp.org/download/scsh3/scsh3.17.617-noinstall.zip
    $ unzip scsh3.17.617-noinstall.zip
    $ rm scsh3.17.617-noinstall.zip

## eToken 5110 CC

[Download](https://knowledge.digicert.com/general-information/how-to-download-safenet-authentication-client) the latest version (10.8.28) of the SafeNet Authentication Client and install as root:

    # dpkg -i SafenetAuthenticationClient-10.8.28_amd64.deb

The installation will create a background service `safenetauthenicationclient` and a systray icon that are not needed in our workflow. You can optionally disable them by running:

    # systemctl disable safenetauthenicationclient
    # cd /etc/xdg/autostart
    # mv SACMonitor.desktop SACMonitor.desktop.off

To prepare the token, run:

    $ SACTools

and follow the steps described [here](https://knowledge.digicert.com/solution/initialize-safenet-etoken-5110cc). To verify correct operation of the token, run:

    $ cd /opt/openpgp-mgmt
    $ bin/mgmt-mt.sh et5110cc
    mt% p11t --list-slots

The token (with further details) should appear in the output.

# Changing and unblocking PINs on the MT

If you need to change or unblock PINs, use the following commands:

* To change the SO-PIN:

      mt% p11t --login --login-type so --so-pin <old SO-PIN> \
               --change-pin --new-pin <new SO-PIN>

* To change the user PIN:

      mt% p11t --login --pin <old user PIN> \
               --change-pin --new-pin <new user PIN>

* To unblock a user PIN:

      mt% p11t --login --login-type so --so-pin=<SO-PIN> \
               --init-pin --new-pin=<new user PIN>

Please note that a blocked SO-PIN **cannot** be unblocked; the device is rendered unusable!

# Generating a new key on the token

If you choose to generate a new key (with a self-signed certificate) on the token (instead of using `openssl` as described in `README`), you can do so with the following steps:

## 1. Generate a new key

    mt% export TID=bf01
    mt% p11t --login --keypairgen --key-type RSA:4096 --id ${TID} --label ${EMAIL}

## 2. Generate self-signed certificate

    mt% openssl req -x509 -new -out cert.pem \
            -engine pkcs11 -keyform engine -key ${TID} \
            -sha256 -days 3653 -subj "/CN=${EMAIL}"
            -config <(echo "[req]"; \
                    echo "distinguished_name = req_distinguished_name"; \
                    echo "[req_distinguished_name]")

# 3. Upload certificate to token

    mt% p11t --login -write-object cert.pem -type cert --label ${EMAIL} --id $(TID)

# 4. Save key to cold storage

Export the new key and certificate to a file in cold storage.
