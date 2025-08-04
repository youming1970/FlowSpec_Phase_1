package main

import (
	"fmt"
	"runtime"
)

// Version information
var (
	// Version is the current version of FlowSpec CLI
	Version = "0.1.0-dev"

	// GitCommit is the git commit hash
	GitCommit = "unknown"

	// BuildDate is the build date
	BuildDate = "unknown"

	// GoVersion is the Go version used to build
	GoVersion = runtime.Version()

	// Platform is the target platform
	Platform = fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH)
)

// GetVersionInfo returns formatted version information
func GetVersionInfo() string {
	return fmt.Sprintf(`FlowSpec CLI %s
Git Commit: %s
Build Date: %s
Go Version: %s
Platform: %s`, Version, GitCommit, BuildDate, GoVersion, Platform)
}

// GetShortVersion returns just the version number
func GetShortVersion() string {
	return Version
}
