# Linux Packaging for Otzaria

This directory contains configuration files for creating Linux distribution packages (.deb and .rpm) for Otzaria.

## Prerequisites

To build Linux packages, you need:

### On Ubuntu/Debian:
```bash
sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev rpm patchelf
```

### Flutter Distributor:
```bash
dart pub global activate flutter_distributor
```

## Configuration Files

- `deb/make_config.yaml`: Configuration for Debian (.deb) packages
- `rpm/make_config.yaml`: Configuration for RPM (.rpm) packages

## Building Packages

### Build .deb package:
```bash
flutter_distributor release --name=prod --jobs=release-linux-deb
```

### Build .rpm package:
```bash
flutter_distributor release --name=prod --jobs=release-linux-rpm
```

### Build both:
```bash
flutter_distributor release --name=prod
```

## Installation

### .deb package:
```bash
sudo dpkg -i otzaria_*.deb
# or
sudo apt install ./otzaria_*.deb
```

### .rpm package:
```bash
sudo dnf localinstall ./otzaria_*.rpm
# or
sudo rpm -i otzaria_*.rpm
# or
sudo yum localinstall ./otzaria_*.rpm
```

## GitHub Actions

The packaging is automated in the GitHub Actions workflow (`.github/workflows/flutter.yml`). The workflow builds:

1. Regular Linux bundle (existing functionality)
2. .deb package for Debian/Ubuntu users
3. .rpm package for Fedora/RHEL users

All packages are automatically uploaded as artifacts and can be downloaded from the Actions tab.

## Dependencies

The packages include the following system dependencies:
- libgtk-3-0 / gtk3
- libblkid1 / util-linux  
- liblzma5 / xz-libs

These will be automatically installed when users install your package.

## Testing

To test the setup locally, ensure you have all prerequisites installed and run:

```bash
# Test .deb build
flutter_distributor release --name=prod --jobs=release-linux-deb

# Test .rpm build  
flutter_distributor release --name=prod --jobs=release-linux-rpm
```

The generated packages will be in the `dist/` directory.
