#!/bin/bash
# Install completion scripts for whisper-wrapper

set -e

BINARY="whisper-wrapper"

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

echo "Installing shell completions for whisper-wrapper..."
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

	echo "Installing Bash completion to: $target"
	$BIN completion bash >"$target"
	echo "✅ Bash completion installed"
	echo "   Reload your shell or run: source $target"
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

	echo "Installing Zsh completion to: $target"
	$BIN completion zsh >"$target"
	echo "✅ Zsh completion installed"
	echo "   Reload your shell or run: compinit"
}

install_fish() {
	local target="$HOME/.config/fish/completions/$BINARY.fish"

	mkdir -p "$HOME/.config/fish/completions"
	echo "Installing Fish completion to: $target"
	$BIN completion fish >"$target"
	echo "✅ Fish completion installed"
	echo "   Completions will be available immediately"
}

# Detect current shell or install all
case "${1:-auto}" in
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
echo "Installation complete!"
