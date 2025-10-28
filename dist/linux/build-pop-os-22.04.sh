#!/bin/bash
# Build script for compiling Ghostty from source on Pop!_OS 22.04
# This script automates the installation of dependencies and compilation of Ghostty
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ZIG_VERSION="0.15.2"
ZIG_ARCH="x86_64-linux"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_TYPE="${BUILD_TYPE:-ReleaseFast}"

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on Pop!_OS or Ubuntu 22.04
check_os() {
    echo_info "Checking operating system..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "pop" ]] || [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "22.04" ]]; then
                echo_success "Running on $NAME $VERSION_ID"
                return 0
            fi
        fi
    fi
    echo_warning "This script is designed for Pop!_OS 22.04 or Ubuntu 22.04"
    echo_warning "Your system: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
}

# Install system dependencies
install_dependencies() {
    echo_info "Installing system dependencies..."
    
    sudo apt-get update
    
    # Core build dependencies
    local PACKAGES=(
        build-essential
        git
        curl
        wget
        pkg-config
        
        # Graphics and rendering
        libgl1-mesa-dev
        
        # Compression and utilities
        libbz2-dev
        libexpat1-dev
        libpng-dev
        zlib1g-dev
        libxml2-dev
        
        # Fonts and text rendering
        libfontconfig1-dev
        libfreetype6-dev
        libharfbuzz-dev
        
        # GTK and GNOME dependencies
        libgtk-4-dev
        libadwaita-1-dev
        libglib2.0-dev
        gobject-introspection
        libgirepository1.0-dev
        gsettings-desktop-schemas-dev
        
        # GStreamer for media
        libgstreamer1.0-dev
        libgstreamer-plugins-base1.0-dev
        libgstreamer-plugins-good1.0-dev
        
        # X11 support
        libx11-dev
        libxcursor-dev
        libxi-dev
        libxrandr-dev
        
        # Wayland support
        libwayland-dev
        libxkbcommon-dev
        
        # Additional dependencies
        libonig-dev
    )
    
    echo_info "Installing packages: ${PACKAGES[*]}"
    sudo apt-get install -y "${PACKAGES[@]}"
    
    echo_success "System dependencies installed"
}

# Install Zig
install_zig() {
    echo_info "Checking for Zig $ZIG_VERSION..."
    
    # Check if Zig is already installed with correct version
    if command -v zig &> /dev/null; then
        CURRENT_ZIG_VERSION=$(zig version 2>/dev/null || echo "unknown")
        if [[ "$CURRENT_ZIG_VERSION" == "$ZIG_VERSION" ]]; then
            echo_success "Zig $ZIG_VERSION is already installed"
            return 0
        else
            echo_warning "Found Zig $CURRENT_ZIG_VERSION, but need $ZIG_VERSION"
        fi
    fi
    
    echo_info "Installing Zig $ZIG_VERSION..."
    
    local ZIG_TARBALL="zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    local ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}"
    local TEMP_DIR=$(mktemp -d)
    
    cd "$TEMP_DIR"
    echo_info "Downloading Zig from $ZIG_URL"
    wget -q --show-progress "$ZIG_URL"
    
    echo_info "Extracting Zig..."
    tar -xf "$ZIG_TARBALL"
    
    echo_info "Installing Zig to /opt/zig-${ZIG_VERSION}..."
    sudo rm -rf "/opt/zig-${ZIG_VERSION}"
    sudo mv "zig-linux-${ZIG_ARCH}-${ZIG_VERSION}" "/opt/zig-${ZIG_VERSION}"
    
    # Update PATH
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "/opt/zig-${ZIG_VERSION}" "$HOME/.bashrc"; then
            echo "export PATH=\"/opt/zig-${ZIG_VERSION}:\$PATH\"" >> "$HOME/.bashrc"
            echo_info "Added Zig to PATH in ~/.bashrc"
        fi
    fi
    
    export PATH="/opt/zig-${ZIG_VERSION}:$PATH"
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    if command -v zig &> /dev/null; then
        echo_success "Zig $(zig version) installed successfully"
    else
        echo_error "Zig installation failed"
        exit 1
    fi
}

# Clone or update Ghostty repository
setup_ghostty_repo() {
    echo_info "Setting up Ghostty repository..."
    
    if [ ! -d ".git" ]; then
        echo_error "This script should be run from the Ghostty repository root"
        echo_info "Clone the repository first: git clone https://github.com/ghostty-org/ghostty"
        exit 1
    fi
    
    echo_success "Repository found"
}

# Build Ghostty
build_ghostty() {
    echo_info "Building Ghostty..."
    echo_info "Build type: $BUILD_TYPE"
    echo_info "Install prefix: $INSTALL_PREFIX"
    
    # Clean previous builds
    if [ -d "zig-out" ]; then
        echo_info "Cleaning previous build..."
        rm -rf zig-out
    fi
    
    # Build Ghostty
    echo_info "Running: zig build -Doptimize=$BUILD_TYPE"
    zig build -Doptimize="$BUILD_TYPE"
    
    echo_success "Ghostty built successfully"
    echo_info "Binary location: zig-out/bin/ghostty"
}

# Install Ghostty
install_ghostty() {
    echo_info "Installing Ghostty to $INSTALL_PREFIX..."
    
    read -p "Do you want to install Ghostty system-wide? (requires sudo) (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Skipping installation. You can run Ghostty from: ./zig-out/bin/ghostty"
        return 0
    fi
    
    sudo zig build install --prefix "$INSTALL_PREFIX" -Doptimize="$BUILD_TYPE"
    
    echo_success "Ghostty installed to $INSTALL_PREFIX/bin/ghostty"
}

# Run tests
run_tests() {
    echo_info "Running tests..."
    
    read -p "Do you want to run tests? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Skipping tests"
        return 0
    fi
    
    zig build test
    
    echo_success "Tests completed"
}

# Print usage information
print_usage() {
    cat << EOF
Ghostty Build Script for Pop!_OS 22.04

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -s, --skip-deps         Skip installing system dependencies
    -t, --skip-tests        Skip running tests
    --prefix PATH           Installation prefix (default: /usr/local)
    --build-type TYPE       Build type: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall
                           (default: ReleaseFast)

Environment Variables:
    INSTALL_PREFIX          Installation prefix (default: /usr/local)
    BUILD_TYPE              Build optimization type (default: ReleaseFast)

Examples:
    # Full build with all dependencies
    $0

    # Build without installing dependencies (if already installed)
    $0 --skip-deps

    # Build with custom prefix
    $0 --prefix ~/.local

    # Debug build
    $0 --build-type Debug

EOF
}

# Parse command line arguments
SKIP_DEPS=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -s|--skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        -t|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        *)
            echo_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "========================================="
    echo "   Ghostty Build Script for Pop!_OS 22.04"
    echo "========================================="
    echo ""
    
    check_os
    setup_ghostty_repo
    
    if [ "$SKIP_DEPS" = false ]; then
        install_dependencies
    else
        echo_info "Skipping dependency installation"
    fi
    
    install_zig
    build_ghostty
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    else
        echo_info "Skipping tests"
    fi
    
    install_ghostty
    
    echo ""
    echo "========================================="
    echo_success "Ghostty build completed successfully!"
    echo "========================================="
    echo ""
    echo "To run Ghostty:"
    if [ -f "$INSTALL_PREFIX/bin/ghostty" ]; then
        echo "  $INSTALL_PREFIX/bin/ghostty"
    else
        echo "  ./zig-out/bin/ghostty"
    fi
    echo ""
    echo "For more information, visit: https://ghostty.org"
    echo ""
}

main
