package main

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"
)

type JWK struct {
	KTY         string   `json:"kty"`
	KID         string   `json:"kid"`
	CRV         string   `json:"crv"`
	X           string   `json:"x"`
	Y           string   `json:"y"`
	Fingerprint string   `json:"x5t#S256"`
	X5C         []string `json:"x5c"`
	ALG         string   `json:"alg"`
	USE         string   `json:"use"`
}

func main() {
	var chain []string
	filePath := os.Args[1]
	pemFile, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Fatalln("Failed to read file")
	}

	publicPem, _ := pem.Decode(pemFile)
	if publicPem == nil {
		log.Fatalln("Failed to find PEM block")
	}

	cert, err := x509.ParseCertificate(publicPem.Bytes)

	if err != nil {
		log.Fatalln("Failed to parse certificate")
	}
	ecdsaPublicKey := cert.PublicKey.(*ecdsa.PublicKey)

	sha := sha256.Sum256(cert.Raw)

	chain = append(chain, base64.StdEncoding.EncodeToString(cert.Raw))

	jwk := JWK{
		KTY:         "EC",
		KID:         strings.ReplaceAll(cert.Issuer.CommonName, ".", "_") + "_" + fmt.Sprint(time.Now().Year()),
		CRV:         "P-256",
		X:           base64.URLEncoding.EncodeToString(ecdsaPublicKey.X.Bytes()),
		Y:           base64.URLEncoding.EncodeToString(ecdsaPublicKey.Y.Bytes()),
		Fingerprint: strings.TrimRight(base64.URLEncoding.EncodeToString(sha[:]), "="),
		X5C:         chain,
		ALG:         "ES256",
		USE:         "sig",
	}

	jsonData, _ := json.MarshalIndent(jwk, "", "  ")

	fmt.Println(string(jsonData))
}
