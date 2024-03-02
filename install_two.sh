#! /bin/bash

chmod +x "$0" # Make the script itself executable

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

# Function to install essential build tools locally in $HOME/local
function install_build_tools() {
    print_color "orange" "Installing build tools locally..."

    mkdir -p $HOME/local
    export PATH=$HOME/local/bin:$PATH

    # Install necessary packages using yum
    yum_install() {
        if ! command -v $1 &> /dev/null; then
            print_color "orange" "Installing $1..."
            sudo yum install -y $1 <<< "$PASSWORD" || { print_color "red" "Failed to install $1"; exit 1; }
            print_color "green" "$1 installed successfully"
        fi
    }

    yum_install make
    yum_install wget
    yum_install bzip2

    print_color "orange" "Installing Development Tools..."
    sudo yum groupinstall -y "Development Tools" <<< "$PASSWORD" || { print_color "red" "Failed to install Development Tools"; exit 1; }
    print_color "green" "Development Tools installed successfully"

    print_color "orange" "Installing gcc from source..."
    curl -OL https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.gz
    tar -xzf gcc-11.2.0.tar.gz
    cd gcc-11.2.0
    ./contrib/download_prerequisites
    mkdir build
    cd build
    ../configure --prefix=$HOME/local/gcc-11.2.0 --enable-languages=c,c++
    make -j4 && make install
    cd ../..
    print_color "green" "gcc installed successfully"

    print_color "orange" "Installing make from source..."
    curl -OL http://ftp.gnu.org/gnu/make/make-4.3.tar.gz
    tar -xzf make-4.3.tar.gz
    cd make-4.3
    ./configure --prefix=$HOME/local
    make && make install
    cd ..
    print_color "green" "make installed successfully"
}

# Check if make is installed
if ! command -v make &> /dev/null; then
    echo -n "Enter sudo password: "
    read -s PASSWORD
    echo ""
    install_build_tools
fi

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

# Install and configure Database
print_color "orange" "---------------- Entering into neovim directory ------------------"
dir_exist "$HOME/neovim"

print_color "orange" "---------------- Building for local installation ------------------"
# Execute commands and check for failure
make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/neovim && \
make -j4 && \
make install || \
{ print_color "red" "One of the commands failed"; exit 3; }

nvim --version || \
{ print_color "red" "Installation failed"; exit 4; }

print_color "orange" "---------------- Adding neovim's binary directory to PATH ------------------"
# Append the export PATH command with a newline
echo -e "\nexport PATH=\$HOME/neovim/bin:\$PATH" >> "$SHELL_RC_FILE" \
{ print_color "red" "Failed to write into $SHELL_RC_FILE"; exit 5; }

print_color "orange" "---------------- Applying the changes on your shell ------------------"
exec $SHELL || { print_color "red" "Failed to restart $SHELL shell"; exit 6; }

print_color "green" "---------------- Neovim installed successfully ------------------"

print_color "orange" "---------------- Installing AstroNvim ------------------"
output2=$(git clone https://github.com/neovim/neovim.git "$HOME/neovim" 2>&1)
is_cloned "$output2"

# Installing AstroNvim plugins
print_color "orange" "---------------- Installing AstroNvim plugins ------------------"
nvim --headless +PackerSync +qall || { print_color "red" "Something went wrong..."; exit 7; }

# Append the export MYVIMRC command with a newline
print_color "orange" "---------------- Adding $MYVIMRC to PATH ------------------"
echo -e "\nexport MYVIMRC=\"$HOME/.config/nvim/init.lua\"" >> "$SHELL_RC_FILE" || \
{ print_color "red" "Failed to write into ~/.bashrc"; exit 8; }

print_color "green" "---------------- AstroNvim successfully installed ------------------"
