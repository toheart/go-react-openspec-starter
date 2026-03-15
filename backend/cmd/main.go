package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	version   = "0.1.0"
	commit    = "dev"
	buildTime = "unknown"
)

func newRootCmd() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "go-react-openspec-starter",
		Short: "Go React OpenSpec starter backend service",
	}

	rootCmd.AddCommand(newServerCmd())
	rootCmd.AddCommand(newVersionCmd())

	return rootCmd
}

func newVersionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print build information",
		Run: func(cmd *cobra.Command, _ []string) {
			cmd.Printf("version=%s commit=%s built=%s\n", version, commit, buildTime)
		},
	}
}

func main() {
	if err := newRootCmd().Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
