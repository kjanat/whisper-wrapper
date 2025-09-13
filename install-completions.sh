#!/bin/bash
# Install completion scripts for whisper-wrapper

set -e

BINARY="whisper-wrapper"
DRY_RUN=false

# Parse flags
while [[ $# -gt 0 ]]; do
	case $1 in
	--dry-run | --whatif | --what-if | -n)
		DRY_RUN=true
		shift
		;;
	-h | --help)
		echo "Usage: $0 [OPTIONS] [SHELL]"
		echo ""
		echo "Install shell completions for whisper-wrapper"
		echo ""
		echo "SHELL:"
		echo "  auto    Auto-detect current shell (default)"
		echo "  bash    Install for bash only"
		echo "  zsh     Install for zsh only"
		echo "  fish    Install for fish only"
		echo "  all     Install for all shells"
		echo ""
		echo "OPTIONS:"
		echo "  -n, --dry-run, --whatif    Show what would be installed without doing it"
		echo "  -h, --help                 Show this help message"
		echo ""
		echo "Examples:"
		echo "  $0                  # Auto-detect and install"
		echo "  $0 --dry-run        # Show what would be installed"
		echo "  $0 zsh              # Install for zsh only"
		echo "  $0 --dry-run all    # Show what would be installed for all shells"
		exit 0
		;;
	*)
		SHELL_TYPE="$1"
		shift
		;;
	esac
done

# Set default shell type if not provided
SHELL_TYPE="${SHELL_TYPE:-auto}"

# Check if binary exists
if ! command -v "$BINARY" &>/dev/null && [ ! -x "./bin/$BINARY" ]; then
	echo "Error: $BINARY not found. Please run 'make build' first."
	exit 1
fi

# Use local binary if available, otherwise system binary
if [ -x "./bin/$BINARY" ]; then
	BIN="./bin/$BINARY"
else
	BIN="$BINARY"
fi

if [ "$DRY_RUN" = true ]; then
	echo "🔍 Checking what completions would be installed for whisper-wrapper..."
else
	echo "Installing shell completions for whisper-wrapper..."
fi
echo ""

# Detect shell and install accordingly
install_bash() {
	local target=""

	# Check for user-specific location first
	if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
		target="$HOME/.local/share/bash-completion/completions/$BINARY"
	elif [ -w "/etc/bash_completion.d" ]; then
		target="/etc/bash_completion.d/$BINARY"
	else
		# Create user directory if it doesn't exist
		mkdir -p "$HOME/.local/share/bash-completion/completions"
		target="$HOME/.local/share/bash-completion/completions/$BINARY"
	fi

	if [ "$DRY_RUN" = true ]; then
		echo "[DRY RUN] Would install Bash completion to: $target"
		echo "Command: $BIN completion bash > $target"
	else
		echo "Installing Bash completion to: $target"
		$BIN completion bash >"$target"
		echo "✅ Bash completion installed"
		echo "   Reload your shell or run: source $target"
	fi
}

install_zsh() {
	local target=""

	# Check for common zsh completion directories
	if [ -d "$HOME/.oh-my-zsh/completions" ]; then
		target="$HOME/.oh-my-zsh/completions/_$BINARY"
	elif [ -d "$HOME/.local/share/zsh/site-functions" ]; then
		target="$HOME/.local/share/zsh/site-functions/_$BINARY"
	elif [ -w "/usr/local/share/zsh/site-functions" ]; then
		target="/usr/local/share/zsh/site-functions/_$BINARY"
	else
		# Create user directory if it doesn't exist
		mkdir -p "$HOME/.local/share/zsh/site-functions"
		target="$HOME/.local/share/zsh/site-functions/_$BINARY"
	fi

	if [ "$DRY_RUN" = true ]; then
		echo "[DRY RUN] Would install Zsh completion to: $target"
		echo "Command: $BIN completion zsh > $target"
	else
		echo "Installing Zsh completion to: $target"
		$BIN completion zsh >"$target"
		echo "✅ Zsh completion installed"
		echo "   Reload your shell or run: compinit"
	fi
}

install_fish() {
	local target="$HOME/.config/fish/completions/$BINARY.fish"

	if [ "$DRY_RUN" = true ]; then
		echo "[DRY RUN] Would install Fish completion to: $target"
		echo "Command: mkdir -p $HOME/.config/fish/completions && $BIN completion fish > $target"
	else
		mkdir -p "$HOME/.config/fish/completions"
		echo "Installing Fish completion to: $target"
		$BIN completion fish >"$target"
		echo "✅ Fish completion installed"
		echo "   Completions will be available immediately"
	fi
}

# Detect current shell or install all
case "$SHELL_TYPE" in
bash)
	install_bash
	;;
zsh)
	install_zsh
	;;
fish)
	install_fish
	;;
all)
	install_bash
	echo ""
	install_zsh
	echo ""
	install_fish
	;;
auto | *)
	# Try to detect current shell
	if [ -n "$BASH_VERSION" ]; then
		install_bash
	elif [ -n "$ZSH_VERSION" ]; then
		install_zsh
	elif [ -n "$FISH_VERSION" ]; then
		install_fish
	else
		# Check parent process
		parent_shell=$(ps -p $PPID -o comm=)
		case "$parent_shell" in
		*bash*)
			install_bash
			;;
		*zsh*)
			install_zsh
			;;
		*fish*)
			install_fish
			;;
		*)
			echo "Could not detect shell. Please specify: $0 [bash|zsh|fish|all]"
			echo ""
			echo "Or install manually:"
			echo "  Bash: $BIN completion bash > ~/.local/share/bash-completion/completions/$BINARY"
			echo "  Zsh:  $BIN completion zsh > ~/.local/share/zsh/site-functions/_$BINARY"
			echo "  Fish: $BIN completion fish > ~/.config/fish/completions/$BINARY.fish"
			exit 1
			;;
		esac
	fi
	;;
esac

echo ""
if [ "$DRY_RUN" = true ]; then
	echo "🔍 Dry run complete! Use without --dry-run to actually install."
else
	echo "✅ Installation complete!"
fi
