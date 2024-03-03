#! /bin/bash

function print_color()
{
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

function is_cloned() {
    if [ $? -eq 0 ]; then
        print_color "deepgreen" "Repository cloned successfully"
    else
        print_color "red" "Failed to clone repository: $1"
        exit 1
    fi
}


function clone_repo() {
    local repo_url=$1
    local repo_dir=$2

    output=$(git clone $repo_url $repo_dir 2>&1) || \
    { print_color "red" "Failed to clone repository: $output"; exit 3; }
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
clone_repo "https://github.com/neovim/neovim.git" "$HOME/neovim"

# Install and configure Database
dir_path="$HOME/neovim"
if [ -d "$dir_path" ]; then
    cd "$dir_path" || { print_color "red" "Unable to change directory!!!"; exit 2; }
else
    print_color "red" "$dir_path directory doesn't exist!"
    exit 2
fi

# Execute commands and check for failure
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/neovim && \
make -j4 && \
make install || \
{ print_color "red" "One of the commands failed"; exit 3; }


# Append the export PATH command with a newline
echo -e "\nexport PATH=\$HOME/neovim/bin:\$PATH" >> "$SHELL_RC_FILE" || \
{ print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 5; }


source "$SHELL_RC_FILE" || { print_color "red" "Failed to reload $SHELL_RC_FILE"; exit 6; }

nvim --version || \
{ print_color "red" "Installation failed"; exit 4; }

# Clone AstoNvim 
clone_repo "--depth 1 https://github.com/AstroNvim/AstroNvim" "$HOME/.config/nvim"
dir_path="$HOME/.config/nvim"
if [ -d "$dir_path" ]; then
    cd "$dir_path" || { print_color "red" "Unable to change directory!!!"; exit 2; }
else
    print_color "red" "$dir_path directory doesn't exist!"
    exit 2
fi

nvim || { print_color "red" "Something went wrong..."; exit 7;}

# Append the export PATH command with a newline
echo -e "\nexport MYVIMRC=\"$HOME/.config/nvim/init.lua\"" >> "$SHELL_RC_FILE" || \
{ print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 8; }


print_color "green" "---------------- AstroNvim successfully installed ------------------"
