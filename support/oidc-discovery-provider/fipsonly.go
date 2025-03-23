//go:build fipsonly

/*
 * See pkg/common/entrypoint/fipsonly.go
 */

package main

import (
	_ "crypto/tls/fipsonly"
)
