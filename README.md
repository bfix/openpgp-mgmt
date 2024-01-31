# Notice

This file is part of *openpgp-mgmt*. Copyright (C) 2019-2024 Bernd Fix  >Y<

*openpgp-mgmt* is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

*openpgp-mgmt* is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL3.0-or-later

# Private OpenPGP key management for the paranoid

This tutorial is for people who have multiple identities/email addresses, use OpenPGP for many or all of them and are paranoid about the integrity and confidentiality of their keys (and messages). It will not dive into the mechanics of how to create secure passphrases or PINs or what *really* is a safe place to store physical objects like hardware tokens or USB sticks (cold storage). But the proposed workflow in this manual - if followed to the end - will provide a high level of technical protection for your OpenPGP secrets.

The basic approach is that there is a long-term OpenPGP primary key that will be stored on a hardware token and in cold storage. This primary key is **not** exposed in the daily use of OpenPGP operations (signing,decrypting and authenticating) and can be considered *protected* and valid for a long time (10+ years). The subkeys for the OpenPGP operations are also stored on a (separate) token for daily use. These subkeys can expire, be revoked, extended or created based on personal requirements. Only changes to the subkeys (or the user identities) require the primary key for certification.

**Good expertise of the GNU/Linux operating system is mandatory to follow this tutorial!**

# Requirements

* One `PKCS #11` token:

  This token will be called the *management token* (**MT**). It is mandatory to use a token that supports `RSA-4096`. The current list of tested tokens include:

  * SmartCard-HSM 4K: `schsm4k`
  * SafeNet eToken 5110 CC: `et5110cc`
  * Nitrokey HSM 2: `nkhsm2`

* Multiple OpenPGP-compliant cards or tokens (one per OpenPGP key, can be mixed):

  * YubiKey 4 & 5
  * GnuPG smartcard
  * ...

  These tokens will be called *OpenPGP tokens* (**OT**s).

* Three USB memory sticks (`8GB` is sufficient in most cases; R/W speed is the critical factor):

  * **Linux Live System (LLS)**:

    Install GNU/Linux (Debian 12) on a new USB stick to be used as the environment for the OpenGPG key management. No GUI/X11 packages are required as everything will be done in a shell on the command line, but to support vendor-specific utilities for token handling the installation of X11 (e.g. Xfce) is recommended. Make sure you install Linux into encrypted LVM partitions to protect the integrity of the **LLS**.
    
    Do **not** use this stick for anything else but OpenPGP key management!

  * **Cold storage** (backup secrets stored in a safe place)

  * **Exchange** (installation and data files, daily-use keyring, public keys):

    Format the stick with a *vfat* filesystem that can be read by all major operating systems like Windows, MacOS and Linux. Copy the setup archive **openpgp-mgmt-deploy.tar.gz** to the stick.

# Overview

A private OpenPGP key consist of a primary key (used for `C`ertification), user identities (names with email addresses) and subkeys for `S`igning, `E`ncryption and `A`uthentication. In this tutorial the primary key is always of type `RSA-4096`; subkeys can either be `RSA-4096` (for `SEA`), `EdDSA` (for `SA`) or `Curve25519` (for `E`). Make sure your **OT** supports the algorithms you want to use for keys.

The workflow described in this tutorial will use different incarnations (stages) of a private OpenPGP key:

## The initial private key (INIT_PRV)

This private key is only used if you want to migrate an existing OpenPGP key into the management framework; it contains the key material (secrets) of the primary key and the subkeys. In this form the key can be used in any OpenPGP-compliant application directly:

    ┌─────────────────────────────────┐
    |  Private OpenPGP key (INIT_PRV) |
    ├─────────────────────────────────┤
    | [C]ertification key (primary):  |
    |    19 ab 41 ... 2d 20 f8        |
    ├─────────────────────────────────┤
    | User IDs:                       |
    |   (1) Name-1 <EMail-1>          |
    |   (2) Name-2 <EMail-2>          |
    |   (3) ...                       |
    |    :                            |
    ├─────────────────────────────────┤
    | SubKeys:                        |
    |   [S]igning key:                |
    |      e5 74 d6 ... 8f 9a 79      |
    |   [E]ncryption key:             |
    |      19 19 7a ... ca 91 9b      |
    |   [A]uthentication key:         |
    |      98 1f e6 ... 19 9b b7      |
    └─────────────────────────────────┘

## The managed private key (MGMT_PRV)

The managed private key is only used in the secure environment to manage the key, e.g. adding, deleting or changing user identies and revoking, extending or creating new subkeys. It does *not contain the secrets of the primary key*; instead it refers to a key on the **MT**:

    ┌─────────────────────────────────┐
    |  Private OpenPGP key (MGMT_PRV) |
    ├─────────────────────────────────┤    ┌─────────────────────┐
    | [C]ertification key (primary) ◄─┼──► | PKCS #11 token (MT) |
    ├─────────────────────────────────┤    └─────────────────────┘
    | User IDs:                       |
    |   (1) Name-1 <EMail-1>          |
    |   (2) Name-2 <EMail-2>          |
    |   (3) ...                       |
    |    :                            |
    ├─────────────────────────────────┤
    | SubKeys:                        |
    |   [S]igning key:                |
    |      e5 74 d6 ... 8f 9a 79      |
    |   [E]ncryption key:             |
    |      19 19 7a ... ca 91 9b      |
    |   [A]uthentication key:         |
    |      98 1f e6 ... 19 9b b7      |
    └─────────────────────────────────┘

This is the key you will start with if you create a new OpenPGP key in this management framework. As described later, you will create a key on the **MT** first; this key gets "imported" when a new OpenPGP key is created in GnuPG.

The managed key is used to create the **public OpenPGP** key that is associated with the private key. You should publish this public key (via WKD, keyserver or direct) so that others can send encrypted messages to you and verify your signatures. If you migrated an existing key, your old public key is still valid and does not need any replacements.

Make sure you backup the managed private key to **cold storage**; you will need it (and the **MT**) the next time when key management functions are performed.

*Remark*: A single **MT** that can hold the primary key of **multiple** OpenPGP keys. Even if only one **MT** is required, you can of course use multiple **MT**s (for groups of keys or even individual keys) if you want.

## The private key for daily-use (USE_PRV)

This key is the last step towards the private key that will be used for daily work. The key does not contain the secrets of the subkeys anymore, but references keys on your **OT**; each OpenPGP key needs its own token:

    ┌─────────────────────────────────┐
    |  Private OpenPGP key (TEMP_PRV) |
    ├─────────────────────────────────┤       ┌─────────────────────┐
    | [C]ertification key (primary) ◄─┼─────► | PKCS #11 token (MT) |
    ├─────────────────────────────────┤       └─────────────────────┘
    | User IDs:                       |
    |   (1) Name-1 <EMail-1>          |
    |   (2) Name-2 <EMail-2>          |
    |   (3) ...                       |
    |    :                            |
    ├─────────────────────────────────┤
    | SubKeys:                        |
    |   [S]igning key:        ◄───\   |        ┌────────────────────┐
    |   [E]ncryption key:     ◄────==========► | OpenPGP token (OT) |
    |   [A]uthentication key: ◄───/   |        └────────────────────┘
    └─────────────────────────────────┘

You need to import this private key on all machines where you want to use OpenPGP functionality. The asscoiated public key should be published via WKD or keyserver, so others can write encrypted messages and verify your signatures.

# Conventions

In this tutorial the following conventions are used:

  > | Command prompt | Description |
  > |---|---|
  > | `#` | execute command as `root` (or use `sudo` if installed) |
  > | `$` | execute command as `user` |
  > | `mt%`| run `$ bin/mgmt-mt.sh <token>` first |
  > | `ot%`| run `$ bin/mgmt-ot.sh` first |

# Setting up and using a secured environment

Key Management for OpenPGP keys (creating, revoking, rotating/extending, export to tokens) **must** be performed in a reasonable secure environment. Boot the Linux Live USB stick and prepare it for use.

## Deploy the management tools and utilities

Login as administrator (`root`), insert the **Exchange** USB stick and mount it on `/mnt`. Extract the deployment archive from the stick:

    # cd /opt
    # tar xzf /mnt/openpgp-mgmt-deploy.tar.gz
    # cd openpgp-mgmt
    # bin/setup-system.sh

Unmount and unplug the **Exchange** USB stick.

## Prepare cold storage

Secrets generated during key management **must** only be stored in a temporary filesystem (`/tmp`) and on a *cold storage* for backup. The cold storage is a LUKS-encrypted USB stick that is initialized by running

    # bin/init-coldstore.sh

If you later mount and unmount the cold storage in a file manager (e.g. Thunar), or you can mount and unmount it manually using the following commands:

    # bin/mount-coldstore.sh <device> <mountpnt>
    # :
    # bin/unmount-coldstore <mountpnt>

`<device>` is the device name of the USB stick (`sda`, `sdb`,...) and `mountpnt` specifies the mount point (defaults to `/mnt`).

## Prepare the management token (MT)

Steps preparing the **MT** for use in our key management depend on the brand/model of the token you want to use. Please see the document `TOKEN.{md,pdf}` for a detailed description for tested tokens.

# Key Management

## Setting up a new OpenPGP key

Setting up a new OpenPGP key for an email account involves multiple steps. The example assumes that the email address is `foo@bar.net` (replace with your real email address) and the name is `John Doe` (replace with your real name). Save your settings in environment variables:

    $ export USER="John Doe"
    $ export EMAIL=foo@bar.net

### 1. Create a RSA key and self-signed X.509 certificate in PEM format:

You can start with a new key or migrate an existing OpenPGP key:

#### Create a new key ...

    $ cd /tmp
    $ openssl genrsa -out key.pem 4096

#### ... or migrate an existing OpenPGP key

If you want to migrate an existing OpenPGP key, the primary key must be of type `RSA`. If the old key has a length of less than 3072 bits, you should consider replacing the old key with a new key before 2030.

First you have to export the existing private keys on **your work computer** and save it on the **Exchange** stick:

    $ gpg --armor --export-secret-keys [keyid|email] > exported-prvkey.asc
    $ gpg --armor --export-secret-subkeys [keyid|email] > exported-prvsubkeys.asc

It is **important to write down the exact creation time of the existing primary key** as it will influence the key identifier in OpenPGP:

    $ gpg --list-packets exported-prv.key.asc | head -n 20

The creation time is expressed in Unix epoch.

Insert the **Exchange** stick on the Linux Live System, copy the exported keys to `/tmp` and extract the RSA key:

    $ cd /tmp
    $ /opt/openpgp-mgmt/bin/opgp2rsa -i exported-prvkey.asc -o key.pem -p <passphrase>

#### Create self-signed X.509 certificate for the key

    $ openssl req -new -key key.pem -out cert.pem \
        -subj "/CN=${EMAIL}" -sha256 -x509 -days 3653 \
        -config <(echo '[ext]'; echo 'basicConstraints=CA:FALSE') \
        -extensions ext

The certificate for `key.pem` is generated and saved in `cert.pem`. It is valid for ten years.

#### Backup the RSA key and X.509 certificate in cold storage

In both cases, plugin and mount the **Cold Storage** stick and save the files `key.pem` and `cert.pem` under appropriate names (e.g. `${EMAIL}.key.pem` and `${EMAIL}.cert.pem`) in a folder of your choice. If you are afraid of loosing a cold storage due to damage of the USB stick, you can have as many cold storages as you think you need. Just prepare each cold storage as described above and copy the files to all of them now - the files are gone after a reboot.

### 2. Move the RSA key and the X.509 certificate to the management token (MT)

The generated key will become the certification/primary key of the OpenPGP key. It is the most critical key and must be even stronger protected than the subkeys used for Signing, Decryption and Authentication.

This is why the RSA key is kept on the **MT**: it is separate and independent from the daily-used **OT**s; it can be stored in a safe place for a long time. The **MT** is rarely required; you just need it to create new OpenPGP keys, revoke keys or parts of it or to sign 3rd party keys for a WoT. The **OT**s on the other hand probably handle dozens of messages each day and are carried around and used on multiple devices. The risk of compromise for an **OT** is much higher than for an **MT** (if the **MT** is stashed away in a *really* secure place).

#### Smartcard-HSM 4k

To store the key `key.pem` and the certificate `cert.pem` on the token, you first need to convert them to a `PKCS #12` object:

    mt% openssl pkcs12 -export -inkey key.pem -in cert.pem -out key_cert.p12

The import process requires the use of the `Smart Card Shell`:

    mt% bash /opt/openpgp-mgmt/scsh3.17.617/scsh3gui

Choose `File > Key Manager` and login to thze token with your user PIN from the context menu, then select `Import from PKCS#12 (Old)` in the context menu of the token. Follow the instructions and select the appropriate files for DKEK share and PKCS#12 object. A more detailed decsription (for the compatible Nitrokey HSM) can be found [here](https://docs.nitrokey.com/hsm/linux/import-keys-certs.html).

Check that the entries for the key and the certificate are on the token:

    mt% p11t --login --list-objects

#### eToken 5110 CC

A key and its associated certificate on the **MT** token are identified by a hexadecimal `id` (without a `0x` prefix). First list the objects already stored on the token to see their ids:

    mt% p11t --list-objects --type privkey

Make up your own new id and store it in an environment variable:

    mt% export TID=bf01

Store the key and the certificate on the token:

    mt% p11t --login --write-object key.pem --type privkey --id ${TID}
    mt% p11t --login --write-object cert.pem --type cert --id ${TID}

### 3. Import the key on the MT as managed OpenPGP key (MGMT_PRV)

To import the key in GnuPG, you need to know the keygrip of the key on the token. Run the following command and examine the output:

    mt% gpg-agent --server gpg-connect-agent << EOF
    > RELOADAGENT
    > SCD LEARN
    > EOF

Look for a line returning the keygrip for the common name (email address) you specified earlier:

    S KEY-FRIEDNLY AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEE /CN=...

The keygrip is the string following `KEY-FRIENDLY`. Make your life easier by exporting it to an environment variable, so you can look it up when needed:

    mt% export KEYGRIP=AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEE

Make GnuPG agent aware of the smartcard (*N.B.*: you need to run this command once after opening the management shell and before doing an operation with the primary key, otherwise the key on the **MT** will not be recognized):

    mt% gpg --card-status

Generate an OpenPGP key by importing the primary key from the **MT**:

    mt% gpg --expert --full-generate-key --faked-system-time <epoch>!

If you re-create an existing OpenPGP key you **must set the creation time of the key** with the `--faked-system-time` option and specify the date as Unix epoch (suffixed with an exclamation mark). You don't have to specify this option if you don't want a specific creation time for the new key.

Select the option `(13) Existing key` and enter the keygrip from the previous step. The key usage of the primary key **must** be limited to *Certify*, so toggle the other capabilities off. The later steps are the usual queries for expiration date, user identification and passphrase. At the end the newly created OpenPGP key is displayed; save the keyid in an environment variable:

    mt% export KEYID=.....

Export the new OpenPGP key to `prv.init.asc` and save it to **cold storage**:

    mt% gpg --armor --export-secret-key ${KEYID} > prv.init.asc
    mt% cp prv.init.asc ...

### 4. Create or migrate OpenPGP subkeys

You can either create new subkeys (if the primary key was newly created in a previous step) or migrate existing subkeys from your OpenPGP key.

#### Create new subkeys ...

    mt% gpg --expert --edit-key ${KEYID}
        > addkey
        > :
        > save

You should create subkeys for **S**igning, **E**ncryption and **A**uthentication. Make sure the desired key algorithms are supported by the **OT**.

#### ... or migrate existing subkeys

    mt% gpg --import exported-prvsubkeys.asc

#### Add or modify user idenities (optional)

Add new user identities if required (e.g. because the key is migrated and additional user ids did exist):

    mt% gpg --expert --edit-key ${KEYID}
        > adduid
        > :
        > save

#### Export the final management key

    mt% gpg --armor --export-secret-key ${KEYID} > prv.mgmt.asc

and save `prv.mgmt.asc` to **cold storage**. This is the key that future key management functions will work on.

### 5. Move the subkeys to the OpenPGP token (OT)

Remove the **MT** (if plugged in) and plu-in the **OT**. If you need to prepare the token first, see `TOKEN.{md,pdf}` for a detailed description.

Start the OpenPGP token management and set the key id we are working on:

    $ bin/mgmt-ot.sh
    ot% export KEYID=.....

Check the **OT** status; it should indicate that it is prepared for OpenPGP:

    ot% gpg --card-status

Import the management key (from **cold storage**) and store the subkeys on the **OT**:

    ot% gpg --import prv.mgmt.asc
    ot% gpg --expert --edit-key ${KEYID}
        > key 1
        > keytocard
        > key 2
        > keytocard
        > key 3
        > keytocard
        > save

Change properties of the **OT** by running `gpg --edit-card` and applying changes as desired.

**IMPORTANT**: Do not leave the management shell until the next step is completed. Doing otherwise will require to start over from the beginning of step 5.

### 6. Prepare the public and private keys for daily use

To save the key (private and public) for daily use, export them to files that **must** be stored on the **Exchange** stick (and on **cold storage** too), so you can use them on other maschines:

    ot% gpg --armor --export-secret-key ${KEYID} > prv.use.asc
    ot% gpg --armor --export-key ${KEYID} > pub.use.asc
    ot% cp *.use.asc ...

## Rotating OpenPGP keys

(TBD)
