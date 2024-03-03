#!/bin/bash

# Function to print colored text
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
    echo # Add a newline
}

# Function to clone repository
function clone_repo() {
    local repo_url=$1
    local repo_dir=$2

    output=$(git clone $repo_url $repo_dir 2>&1) || \
    { print_color "red" "Failed to clone repository: $output"; exit 3; }
    cd "$repo_dir" || { print_color "red" "Failed to change directory: $repo_dir"; exit 2; }
}

# Function to check if directory exists and create if not
function dir_exist() {
    if [ ! -d "$1" ]; then
        print_color "red" "$1 directory doesn't exist!"
        exit 2
    fi
}

# Function to update progress
function update_progress() {
    local percentage=$1
    local bar_length=50
    local progress=$((bar_length * percentage / 100))
    local bar=$(printf "%${progress}s" | tr ' ' '#')

    printf "\rProgress: [%-${bar_length}s] %d%%\n" "$bar" "$percentage"
}

# Detect user's default shell and set shell configuration file
if [[ -n "$BASH" ]]; then
    SHELL_RC_FILE="$HOME/.bashrc"
elif [[ -n "$ZSH_NAME" ]]; then
    SHELL_RC_FILE="$HOME/.zshrc"
else
    SHELL_RC_FILE="$HOME/.bashrc"
fi

# Install Neovim
print_color "orange" "---------------- Installing Neovim & AstroNvim ------------------"
update_progress 0
clone_repo "https://github.com/neovim/neovim.git"  "$HOME/neovim"

# Update progress after cloning Neovim
update_progress 20

# Install and configure Neovim
dir_path="$HOME/neovim"
dir_exist "$dir_path"

# Execute commands and check for failure
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/neovim > /dev/null && \
make -j4 > /dev/null && \
make install > /dev/null || \
{ print_color "red" "One of the commands failed"; exit 3; }

# Add neovim's binary directory to PATH if not already in PATH
neovim_bin_path="$HOME/neovim/bin"
if [[ ":$PATH:" != *":$neovim_bin_path:"* ]]; then
    echo "export PATH=\$PATH:$neovim_bin_path" >> "$SHELL_RC_FILE" || \
    { print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 5; }
fi

# Applying the changes on your shell
source "$SHELL_RC_FILE" || { print_color "red" "Failed to reload $SHELL_RC_FILE"; exit 6; }

# Install AstroNvim
clone_repo "https://github.com/AstroNvim/AstroNvim.git" "$HOME/.config/nvim"

# Update progress after cloning AstroNvim
update_progress 40

# Entering AstroNvim directory
dir_path="$HOME/.config/nvim"
dir_exist "$dir_path"

# Install AstroNvim plugins
nvim || { print_color "red" "Something went wrong..."; exit 7; }

# Update progress after installing AstroNvim plugins
update_progress 60

# Add MYVIMRC path if not already set
MYVIMRC="$HOME/.config/nvim/init.lua"
if ! grep -qF "export MYVIMRC=\"$MYVIMRC\"" "$SHELL_RC_FILE"; then
    echo "export MYVIMRC=\"$MYVIMRC\"" >> "$SHELL_RC_FILE" || \
    { print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 8; }
fi

update_progress 100
print_color "green" "---------------- AstroNvim installed ------------------"
