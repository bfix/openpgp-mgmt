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
	"bytes"
	"crypto"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/ProtonMail/go-crypto/openpgp"
	"github.com/ProtonMail/go-crypto/openpgp/armor"
	"github.com/ProtonMail/go-crypto/openpgp/packet"
)

func main() {
	log.Println("--------------------------------------")
	log.Println("vanityid: Generate vanity OpenPGP keys")
	log.Println("Copyright (c) 2014-2024 Bernd Fix  >Y<")
	log.Println("--------------------------------------")

	// parse command line arguments
	var out, date, name, comment, email, pattern string
	var bits int
	flag.IntVar(&bits, "b", 4096, "RSA key size")
	flag.StringVar(&out, "o", ".", "folder for PEM encoded PGP private keys")
	flag.StringVar(&date, "d", "", "Creation date (YY-MM-DD_HH:MM:SS GMT)")
	flag.StringVar(&name, "n", "", "Name of key holder")
	flag.StringVar(&comment, "c", "", "Comment (optional)")
	flag.StringVar(&email, "e", "", "EMail address")
	flag.StringVar(&pattern, "p", "", "desired hex pattern in keyid (regexp)")
	flag.Parse()

	// check arguments
	usage := func(err string) {
		flag.Usage()
		log.Fatal(err)
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

	// build list of regexp
	log.Println("defined patterns:")
	re := make([]*regexp.Regexp, 0)
	for _, p := range strings.Split(pattern, ",") {
		r, err := regexp.Compile(p)
		if err != nil {
			log.Printf("invalid pattern: '%s': %s\n", p, err)
			continue
		}
		log.Printf("    '%s'\n", p)
		re = append(re, r)
	}
	if len(re) == 0 {
		log.Println("no pattern defined -- terminating")
	}

	// try forever...
	const rot = "/-\\|"
	for i := 0; ; i++ {
		// generate new OpenPGP entity
		cfg := &packet.Config{
			Time:          func() time.Time { return tt },
			DefaultHash:   crypto.SHA256,
			DefaultCipher: packet.CipherAES256,
			Algorithm:     packet.PubKeyAlgoRSA,
			RSABits:       bits,
		}
		ent, err := openpgp.NewEntity(name, comment, email, cfg)
		if err != nil {
			log.Fatal(err)
		}
		buf := new(bytes.Buffer)
		binary.Write(buf, binary.BigEndian, ent.PrimaryKey.KeyId)
		id := hex.EncodeToString(buf.Bytes())
		fmt.Printf("%c\b", rot[i%4])

		// check if keyid matches a pattern
		found := false
		for _, r := range re {
			if r.Match([]byte(id)) {
				found = true
				break
			}
		}
		if found {
			// yes: generate output
			fmt.Println()
			log.Printf("Found: '%s'\n", id)

			// write OpenPGP key
			f, err := os.Create(out + "/" + id + ".asc")
			if err != nil {
				log.Fatal(err)
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
			f.Close()

			// write RSA key
			if f, err = os.Create(out + "/" + id + ".pem"); err != nil {
				log.Fatal(err)
			}

			if arm, err = armor.Encode(f, "RSA PRIVATE KEY BLOCK", nil); err != nil {
				log.Fatal(err)
			}
			prv := ent.PrivateKey
			if err = prv.Serialize(arm); err != nil {
				log.Fatal(err)
			}
			arm.Close()
			_, _ = f.WriteString("\n")

			if arm, err = armor.Encode(f, "RSA PUBLIC KEY BLOCK", nil); err != nil {
				log.Fatal(err)
			}
			if err = prv.PublicKey.Serialize(arm); err != nil {
				log.Fatal(err)
			}
			arm.Close()
			f.Close()
		}
	}
}
