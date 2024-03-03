#!/bin/bash

function print_color() {
    NC='\033[0m' # No Color

    case $1 in
        "deepgreen") COLOR='\033[0;38;5;22m' ;;
        "orange") COLOR='\033[0;33m' ;;
        "green") COLOR='\033[0;32m' ;;
        "red") COLOR='\033[0;31m' ;;
        "*") COLOR='\033[0m' ;;
    esac

    echo -e "${COLOR} $2 ${NC}"
}

function is_cloned() {
    if [ $? -eq 0 ]; then
        print_color "deepgreen" "Repository cloned successfully"
    else
        print_color "red" "Failed to clone repository: $1"
        exit 1
    fi
}

function dir_exist() {
    if [ -d "$1" ]; then
        print_color "" "Entering into $1 directory"
        cd "$1" || { print_color "red" "Unable to change directory!!!"; exit 2; }
        print_color "deepgreen" "Successfully changed directory"
    else
        print_color "red" "$1 directory doesn't exist!"
        exit 2
    fi
}

# Check if directories exist and create if not
function create_directory() {
    if [ ! -d "$1" ]; then
        print_color "orange" "Creating directory: $1"
        mkdir -p "$1" || { print_color "red" "Failed to create directory: $1"; exit 1; }
        print_color "green" "Directory created successfully: $1"
    else
        print_color "orange" "Directory already exists: $1"
    fi
}

# Detect user's default shell and set shell configuration file
if [[ -n "$BASH" ]]; then
    SHELL_RC_FILE="$HOME/.bashrc"
elif [[ -n "$ZSH_NAME" ]]; then
    SHELL_RC_FILE="$HOME/.zshrc"
else
    # Default to .bashrc if neither Bash nor Zsh is detected
    SHELL_RC_FILE="$HOME/.bashrc"
fi

# Install Neovim
print_color "orange" "---------------- Installing Neovim ------------------"
output=$(git clone https://github.com/neovim/neovim.git "$HOME/neovim" 2>&1)
is_cloned "$output"

# Install and configure Neovim
dir_path="$HOME/neovim"
dir_exist "$dir_path"

# Execute commands and check for failure
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/neovim && \
make -j4 && \
make install || \
{ print_color "red" "One of the commands failed"; exit 3; }

nvim --version || \
{ print_color "red" "Installation failed"; exit 4; }

# Add neovim's binary directory to PATH if not already in PATH
neovim_bin_path="$HOME/neovim/bin"
if [[ ":$PATH:" != *":$neovim_bin_path:"* ]]; then
    echo "export PATH=\$PATH:$neovim_bin_path" >> "$SHELL_RC_FILE" || \
    { print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 5; }
fi

# Applying the changes on your shell
source "$SHELL_RC_FILE" || { print_color "red" "Failed to reload $SHELL_RC_FILE"; exit 6; }

print_color "green" "---------------- Neovim installed ------------------"

# Install AstroNvim
print_color "orange" "---------------- Installing AstroNvim ------------------"
output2=$(git clone --depth 1 https://github.com/AstroNvim/AstroNvim "$HOME/.config/nvim" 2>&1)
is_cloned "$output2"

# Entering AstroNvim directory
dir_path="$HOME/.config/nvim"
dir_exist "$dir_path"

# Install AstroNvim plugins
nvim || { print_color "red" "Something went wrong..."; exit 7; }

# Add MYVIMRC path if not already set
MYVIMRC="$HOME/.config/nvim/init.lua"
if ! grep -qF "export MYVIMRC=\"$MYVIMRC\"" "$SHELL_RC_FILE"; then
    echo "export MYVIMRC=\"$MYVIMRC\"" >> "$SHELL_RC_FILE" || \
    { print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 8; }
fi

print_color "green" "---------------- AstroNvim installed ------------------"
