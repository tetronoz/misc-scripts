package main

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
)

type JWKS struct {
	Keys   []JWK `json:"keys"`       	
}

type JWK struct {
	KID         string   `json:"kid"`
	KTY         string   `json:"kty"`
	ALG         string   `json:"alg"`
	CRV         string   `json:"crv"`
	X           string   `json:"x"`
}

func main() {
	publicKey, privateKey, err := ed25519.GenerateKey(nil)

	if err != nil {
		log.Fatalf("Failed to generate ed25519 keys: %v", err)
	}

	fmt.Println(base64.StdEncoding.EncodeToString(privateKey))
	fmt.Println(base64.StdEncoding.EncodeToString(publicKey))

	jwk := JWK{
		KID: "A",
		KTY: "OKP",
		ALG: "EdDSA",
		CRV: "Ed25519",
		X: base64.URLEncoding.EncodeToString(publicKey),
	}

    keys := []JWK{jwk}

    jwks := JWKS{
        Keys: keys,
    }

	jsonData, _ := json.MarshalIndent(jwks, "", "  ")

	fmt.Printf("\n%v\n", string(jsonData))
}
