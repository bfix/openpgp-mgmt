// This file is part of openpgp-mgmt.
// Copyright (C) 2019-2024 Bernd Fix  >Y<
//
// openpgp-mgmt is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// openpgp-mgmt is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: AGPL3.0-or-later

package main

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/ProtonMail/go-crypto/openpgp"
)

func main() {
	// parse command line arguments
	var inf, outf, pp string
	flag.StringVar(&inf, "i", "", "PEM encoded PGP private key")
	flag.StringVar(&outf, "o", "", "PEM encoded RSA private key")
	flag.StringVar(&pp, "p", "", "Passphrase")
	flag.Parse()

	// read PGP key
	if len(inf) == 0 {
		flag.Usage()
		log.Fatal("no input file")
	}
	f, err := os.Open(inf)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	ents, err := openpgp.ReadArmoredKeyRing(f)
	if err != nil {
		log.Fatal(err)
	}
	if len(ents) == 0 {
		log.Fatal("no entities found")
	}
	fmt.Printf("Entity: %v\n", ents[0])
	prv := ents[0].PrivateKey
	if prv.Encrypted {
		if len(pp) == 0 {
			log.Fatal("Please provide a passphrase for the key with option '-p'")
		}
		if err = prv.Decrypt([]byte(pp)); err != nil {
			log.Fatal(err)
		}
	}

	// output resulting RSA keys
	f = os.Stdout
	if len(outf) > 0 {
		if f, err = os.Create(outf); err != nil {
			log.Fatal(err)
		}
		defer f.Close()
	}

	key, ok := prv.PrivateKey.(*rsa.PrivateKey)
	if !ok {
		log.Fatal("Private key is not a RSA key")
	}
	pem := pem.EncodeToMemory(
		&pem.Block{
			Type:  "RSA PRIVATE KEY",
			Bytes: x509.MarshalPKCS1PrivateKey(key),
		},
	)
	f.Write(pem)
}
