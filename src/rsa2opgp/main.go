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
	"crypto"
	"crypto/x509"
	"encoding/pem"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ProtonMail/go-crypto/openpgp"
	"github.com/ProtonMail/go-crypto/openpgp/armor"
	"github.com/ProtonMail/go-crypto/openpgp/packet"
)

func main() {
	// parse command line arguments
	var inf, outf, date, name, comment, email string
	flag.StringVar(&inf, "i", "", "PEM encoded RSA private key")
	flag.StringVar(&outf, "o", "", "PEM encoded PGP private key")
	flag.StringVar(&date, "d", "", "Creation date (YY-MM-DD_HH:MM:SS GMT)")
	flag.StringVar(&name, "n", "", "Name of key holder")
	flag.StringVar(&comment, "c", "", "Comment (optional)")
	flag.StringVar(&email, "e", "", "EMail address")
	flag.Parse()

	// check arguments
	usage := func(err string) {
		flag.Usage()
		log.Fatal(err)
	}
	if len(inf) == 0 {
		usage("no input file")
	}
	if len(name) == 0 {
		usage("no key holder name")
	}
	if len(email) == 0 {
		usage("no key holder email address")
	}
	tt := time.Now()
	if len(date) > 0 {
		var err error
		if tt, err = time.Parse("2006-01-02_15:04:05", date); err != nil {
			usage("unknown date format")
		}
	}

	// parse input file (RSA key)
	buf, err := os.ReadFile(inf)
	if err != nil {
		log.Fatal(err)
	}
	block, _ := pem.Decode(buf)
	key, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		log.Fatal(err)
	}

	// construct OpenPGP key
	ent := new(openpgp.Entity)
	ent.PrivateKey = packet.NewRSAPrivateKey(tt, key)
	ent.PrimaryKey = &ent.PrivateKey.PublicKey

	uid := &packet.UserId{
		Name:    name,
		Comment: comment,
		Email:   email,
	}
	if len(comment) == 0 {
		uid.Id = fmt.Sprintf("%s <%s>", name, email)
	} else {
		uid.Id = fmt.Sprintf("%s (%s) <%s>", name, comment, email)
	}

	ent.Identities = make(map[string]*openpgp.Identity)
	ident := &openpgp.Identity{
		Name:          uid.Id,
		UserId:        uid,
		SelfSignature: nil,
		Signatures:    nil,
	}
	ent.Identities[uid.Id] = ident

	cfg := &packet.Config{
		Time: func() time.Time { return tt },
	}
	sig := new(packet.Signature)
	sig.Hash = crypto.SHA256
	sig.PubKeyAlgo = ent.PrimaryKey.PubKeyAlgo
	sig.CreationTime = tt
	sig.IssuerKeyId = &ent.PrimaryKey.KeyId
	sig.SigType = packet.SigTypeGenericCert
	sig.PreferredSymmetric = []uint8{9}
	sig.PreferredHash = []uint8{8}
	sig.PreferredCompression = []uint8{0}
	sig.FlagsValid = true
	sig.FlagCertify = true
	sig.FlagSign = true
	if err = sig.SignUserId(uid.Id, ent.PrimaryKey, ent.PrivateKey, cfg); err != nil {
		log.Fatal(err)
	}
	ident.SelfSignature = sig
	if err = ent.SignIdentity(uid.Id, ent, cfg); err != nil {
		log.Fatal(err)
	}

	// output resulting openpgp keys
	f := os.Stdout
	if len(outf) > 0 {
		if f, err = os.Create(outf); err != nil {
			log.Fatal(err)
		}
		defer f.Close()
	}
	arm, err := armor.Encode(f, "PGP PUBLIC KEY BLOCK", nil)
	if err != nil {
		log.Fatal(err)
	}
	if err = ent.Serialize(arm); err != nil {
		log.Fatal(err)
	}
	arm.Close()
	f.WriteString("\n")

	if arm, err = armor.Encode(f, "PGP PRIVATE KEY BLOCK", nil); err != nil {
		log.Fatal(err)
	}
	if err = ent.SerializePrivate(arm, cfg); err != nil {
		log.Fatal(err)
	}
	arm.Close()
}
