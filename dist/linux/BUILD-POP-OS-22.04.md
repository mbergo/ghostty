# Building Ghostty from Source on Pop!_OS 22.04

This guide provides instructions for compiling Ghostty from source on Pop!_OS 22.04 (also compatible with Ubuntu 22.04).

## Quick Start

For the easiest build experience, use the provided build script:

```bash
# Clone the repository
git clone https://github.com/ghostty-org/ghostty
cd ghostty

# Run the build script
./dist/linux/build-pop-os-22.04.sh
```

The script will:
1. Install all required system dependencies
2. Download and install Zig 0.15.2
3. Build Ghostty with optimizations
4. Optionally run tests
5. Optionally install system-wide

## Script Options

```bash
./dist/linux/build-pop-os-22.04.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -s, --skip-deps         Skip installing system dependencies
  -t, --skip-tests        Skip running tests
  --prefix PATH           Installation prefix (default: /usr/local)
  --build-type TYPE       Build type: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall
```

### Examples

**Standard build:**
```bash
./dist/linux/build-pop-os-22.04.sh
```

**Build without installing dependencies** (if you've already installed them):
```bash
./dist/linux/build-pop-os-22.04.sh --skip-deps
```

**Install to custom location** (e.g., your home directory):
```bash
./dist/linux/build-pop-os-22.04.sh --prefix ~/.local
```

**Debug build** (for development):
```bash
./dist/linux/build-pop-os-22.04.sh --build-type Debug
```

## Manual Build Instructions

If you prefer to build manually or need more control:

### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  git \
  curl \
  wget \
  pkg-config \
  libgl1-mesa-dev \
  libbz2-dev \
  libexpat1-dev \
  libpng-dev \
  zlib1g-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libharfbuzz-dev \
  libgtk-4-dev \
  libadwaita-1-dev \
  libglib2.0-dev \
  gobject-introspection \
  libgirepository1.0-dev \
  gsettings-desktop-schemas-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-good1.0-dev \
  libx11-dev \
  libxcursor-dev \
  libxi-dev \
  libxrandr-dev \
  libwayland-dev \
  libxkbcommon-dev \
  libonig-dev
```

### 2. Install Zig 0.15.2

```bash
# Download Zig
wget https://ziglang.org/download/0.15.2/zig-linux-x86_64-0.15.2.tar.xz

# Extract
tar -xf zig-linux-x86_64-0.15.2.tar.xz

# Install to /opt
sudo mv zig-linux-x86_64-0.15.2 /opt/zig-0.15.2

# Add to PATH
export PATH="/opt/zig-0.15.2:$PATH"
echo 'export PATH="/opt/zig-0.15.2:$PATH"' >> ~/.bashrc
```

### 3. Clone Ghostty Repository

```bash
git clone https://github.com/ghostty-org/ghostty
cd ghostty
```

### 4. Build Ghostty

**Release build** (recommended for daily use):
```bash
zig build -Doptimize=ReleaseFast
```

**Debug build** (for development):
```bash
zig build
```

The binary will be located at: `./zig-out/bin/ghostty`

### 5. Run Tests (Optional)

```bash
zig build test
```

### 6. Install System-Wide (Optional)

```bash
sudo zig build install --prefix /usr/local -Doptimize=ReleaseFast
```

Or install to your home directory:
```bash
zig build install --prefix ~/.local -Doptimize=ReleaseFast
```

## Running Ghostty

After building:

**Without installation:**
```bash
./zig-out/bin/ghostty
```

**After system-wide installation:**
```bash
ghostty
```

**After local installation to ~/.local:**
```bash
~/.local/bin/ghostty
# Make sure ~/.local/bin is in your PATH
```

## Troubleshooting

### Missing Dependencies

If you encounter build errors about missing libraries, ensure all dependencies are installed:
```bash
sudo apt-get update
sudo apt-get install -y <missing-package>
```

### Wrong Zig Version

Ghostty requires Zig 0.15.2. Check your version:
```bash
zig version
```

If incorrect, follow step 2 above to install the correct version.

### GTK/Wayland Issues

For the best experience on Pop!_OS, ensure you have the latest GTK4 and libadwaita:
```bash
sudo apt-get install --reinstall libgtk-4-dev libadwaita-1-dev
```

### Build Fails with "permission denied"

Make sure the build script is executable:
```bash
chmod +x dist/linux/build-pop-os-22.04.sh
```

## Build Types

Ghostty supports different build types:

- **ReleaseFast**: Optimized for performance (recommended for daily use)
- **ReleaseSafe**: Optimized with safety checks (slower but safer)
- **ReleaseSmall**: Optimized for binary size
- **Debug**: Unoptimized with debug symbols (for development)

## Additional Resources

- **Official Documentation**: https://ghostty.org/docs
- **Build from Source Guide**: https://ghostty.org/docs/install/build
- **Contributing Guide**: [CONTRIBUTING.md](../../CONTRIBUTING.md)
- **Development Guide**: [HACKING.md](../../HACKING.md)
- **Packaging Guide**: [PACKAGING.md](../../PACKAGING.md)

## System Requirements

- Pop!_OS 22.04 or Ubuntu 22.04 (may work on other Debian-based distributions)
- At least 2GB of RAM for building
- About 1.5GB of disk space for dependencies and build artifacts
- Internet connection for downloading Zig and dependencies

## Notes

- The build script will prompt before installing system-wide
- Zig is installed to `/opt/zig-0.15.2` to avoid conflicts with system packages
- The script adds Zig to your PATH in `~/.bashrc`
- You may need to start a new terminal session or run `source ~/.bashrc` for PATH changes to take effect

## Support

If you encounter issues:
1. Check the [GitHub Issues](https://github.com/ghostty-org/ghostty/issues)
2. Join the [Discord Server](https://discord.gg/ghostty)
3. Open an [Issue Triage Discussion](https://github.com/ghostty-org/ghostty/discussions/new?category=issue-triage)
