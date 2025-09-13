# Whisper Wrapper (Go)

Small pass-through CLI that wraps the Python `whisper` command and mirrors its usage. It forwards all arguments directly to the underlying `whisper` binary and returns the same exit code. Now built with Cobra, it provides shell completion scripts for Bash, Zsh, Fish, and PowerShell.

## Quick Start

1. **Install whisper-wrapper**:

   ```bash
   go install github.com/kjanat/whisper-wrapper/cmd/whisper-wrapper@latest
   ```

2. **Install Python whisper** (if not already installed):

   ```bash
   pip install git+https://github.com/openai/whisper
   ```

3. **Use it like regular whisper**:

   ```bash
   whisper-wrapper --model small --language en audio.mp3
   ```

4. **Optional**: Install shell completions for better UX

## Installation

## From GitHub (Recommended)

Install directly from the repository:

```bash
# Install latest version
go install github.com/kjanat/whisper-wrapper/cmd/whisper-wrapper@latest

# Install specific version/tag
go install github.com/kjanat/whisper-wrapper/cmd/whisper-wrapper@v1.0.0
```

The binary will be installed to your `$GOBIN` directory (usually `~/go/bin/whisper-wrapper`).

## From Source

- Requires Go (1.21+ recommended). The module declares a newer Go version but standard toolchains work.
- Clone and build:

  ```bash
  git clone https://github.com/kjanat/whisper-wrapper.git
  cd whisper-wrapper
  make build  # outputs bin/whisper-wrapper
  ```

- Or build directly: `go build -o bin/whisper-wrapper ./cmd/whisper-wrapper`

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

### Automatic Installation

If you installed from source, use the helper script to auto-detect your shell and install completions:

```bash
./install-completions.sh                  # Auto-detect current shell
./install-completions.sh bash             # Install for bash only
./install-completions.sh zsh              # Install for zsh only
./install-completions.sh fish             # Install for fish only
./install-completions.sh all              # Install for all shells

# Dry-run to see what would be installed
./install-completions.sh --dry-run        # Check auto-detection
./install-completions.sh --dry-run all    # Check all shells
./install-completions.sh --whatif zsh     # Alternative dry-run syntax
```

**For GitHub installs**: The script will automatically detect the system-installed `whisper-wrapper` binary.

### Manual Installation

- Generate a completion script for your shell and install it:
  - Makefile helpers: `make completions` writes files into `./completions/`
  - Bash: `whisper-wrapper completion bash > ~/.local/share/bash-completion/completions/whisper-wrapper`
    - System-wide: `sudo whisper-wrapper completion bash > /etc/bash_completion.d/whisper-wrapper`
  - Zsh:
    - Oh My Zsh: `whisper-wrapper completion zsh > ~/.oh-my-zsh/completions/_whisper-wrapper`
    - User directory: `whisper-wrapper completion zsh > ~/.local/share/zsh/site-functions/_whisper-wrapper`
    - System-wide: `sudo whisper-wrapper completion zsh > /usr/share/zsh/site-functions/_whisper-wrapper`
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
