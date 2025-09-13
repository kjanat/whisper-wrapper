# Whisper Wrapper (Go)

Small pass-through CLI that wraps the Python `whisper` command and mirrors its usage. It forwards all arguments directly to the underlying `whisper` binary and returns the same exit code. Now built with Cobra, it provides shell completion scripts for Bash, Zsh, Fish, and PowerShell.

Build

- Requires Go (1.21+ recommended). The module declares a newer Go version but standard toolchains work.
- Build the binary:
  - `make build` (outputs `bin/whisper-wrapper`)
  - Or directly: `go build -o bin/whisper-wrapper ./cmd/whisper-wrapper`

Usage

- Ensure the Python `whisper` CLI is installed and on your `PATH` (e.g. via `pip install git+https://github.com/openai/whisper`).
- Run the wrapper with the same flags you would pass to `whisper`:

  - `./bin/whisper-wrapper --model small --language en audio.mp3`

- If run without arguments, the wrapper shows `whisper -h` help.

Configuration

- `WHISPER_BIN`: optional environment variable to override the underlying executable path. Defaults to `whisper`.

  - Example: `WHISPER_BIN=/path/to/venv/bin/whisper ./bin/whisper-wrapper --model base audio.wav`

Shell Completions

## Prerequisites

- **Bash**: Requires `bash-completion` package installed
  - Manjaro/Arch: `sudo pacman -S bash-completion`
  - Ubuntu/Debian: `sudo apt install bash-completion`
  - macOS: `brew install bash-completion`

## Installation

- Generate a completion script for your shell and install it:
  - Makefile helpers: `make completions` writes files into `./completions/`
  - Bash: `whisper-wrapper completion bash > /etc/bash_completion.d/whisper-wrapper` (root) or `~/.local/share/bash-completion/completions/whisper-wrapper`
  - Zsh: `whisper-wrapper completion zsh > ${fpath[1]}/_whisper-wrapper` or copy `./completions/_whisper-wrapper` to your zsh completion directory
  - Fish: `whisper-wrapper completion fish > ~/.config/fish/completions/whisper-wrapper.fish`
  - PowerShell: `whisper-wrapper completion powershell | Out-String | Invoke-Expression` (temporary session) or save to your profile directory.

**Note**: For zsh, do NOT use `eval "$(whisper-wrapper completion zsh)"` - instead install the completion file to your zsh fpath.

- The wrapper declares common Whisper flags for completion suggestions, but does not parse them; all flags are passed directly to the Python `whisper` CLI unchanged.

Notes

- Stdout and stderr are passed through verbatim from the underlying process.
- Exit status matches the underlying `whisper` command when possible.

Makefile targets

- `make build` — build the binary to `bin/whisper-wrapper`
- `make install` — `go install` to your `GOBIN`
- `make fmt` — `go fmt ./...`
- `make lint` — `golangci-lint run`
- `make completions` — generate completion scripts into `./completions/`
- `make clean` — remove build artifacts
