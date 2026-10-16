#!/usr/bin/env bash
#
# Build RPM package for openSUSE (Tumbleweed / Leap) and other RPM-based Linux distributions.
#
set -euo pipefail

# Project root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

say() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m==>\033[0m %s\n" "$*" >&2; }
die() { printf "\033[1;31m==>\033[0m %s\n" "$*" >&2; exit 1; }

# 1. Check prerequisites
command -v rpmbuild >/dev/null || die "rpmbuild is not installed. Run: sudo zypper install rpm-build"
command -v go >/dev/null || die "go compiler is not installed or not in PATH."
command -v pkg-config >/dev/null || die "pkg-config is not installed. Run: sudo zypper install pkgconf-pkg-config"

pkg-config --exists gtk+-3.0 || die "gtk+-3.0 development headers not found. Run: sudo zypper install gtk3-devel"
pkg-config --exists webkit2gtk-4.1 || die "webkit2gtk-4.1 development headers not found. Run: sudo zypper install webkitgtk3-devel"

# 2. Derive version from git or environment
RAW_VER="${VERSION:-$(git describe --tags --always --dirty 2>/dev/null || echo "0.1.0")}"
# Strip leading 'v'
RAW_VER="${RAW_VER#v}"

# RPM Version: numbers and dots only for base version
PKG_VER="$(echo "$RAW_VER" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
if [[ -z "$PKG_VER" ]]; then
    PKG_VER="0.1.0"
fi

# RPM Release: if there is extra git info (-7-g138188a3), turn into release tag
EXTRA="$(echo "$RAW_VER" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+-?//')"
if [[ -n "$EXTRA" ]]; then
    PKG_REL="$(echo "$EXTRA" | tr '-' '.')"
else
    PKG_REL="1"
fi

say "Building RPM for magpie version ${PKG_VER}, release ${PKG_REL}..."

# 3. Setup RPM build tree
DIST_DIR="$ROOT_DIR/dist"
RPM_DIST="$DIST_DIR/rpm"
RPMBUILD_DIR="$DIST_DIR/rpmbuild"

rm -rf "$RPMBUILD_DIR"
mkdir -p "$RPMBUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$RPM_DIST"

# 4. Prepare sources
say "Preparing packaging sources..."
cp "$ROOT_DIR/build/linux/magpie.desktop" "$RPMBUILD_DIR/SOURCES/"
cp "$ROOT_DIR/build/linux/magpie.service" "$RPMBUILD_DIR/SOURCES/"

# Archive current repository state
say "Creating source archive magpie-${PKG_VER}.tar.gz..."
tar --exclude-vcs \
    --exclude="./dist" \
    --exclude="./magpie" \
    --exclude="./magpie-*" \
    --transform="s|^./|magpie-${PKG_VER}/|" \
    -czf "$RPMBUILD_DIR/SOURCES/magpie-${PKG_VER}.tar.gz" .

# 5. Prepare spec file with current version and release
sed \
    -e "s/^Version:[[:space:]]*.*/Version:        ${PKG_VER}/" \
    -e "s/^Release:[[:space:]]*.*/Release:        ${PKG_REL}/" \
    "$ROOT_DIR/build/linux/magpie.spec" > "$RPMBUILD_DIR/SPECS/magpie.spec"

# Check if build dependencies are satisfied in RPM database
RPMBUILD_ARGS=()
if ! rpm -q --whatprovides "golang(API)" >/dev/null 2>&1; then
    warn "Go package is not registered in rpmdb; using --nodeps for local build."
    RPMBUILD_ARGS+=("--nodeps")
fi

# 6. Build RPM package
say "Executing rpmbuild..."
rpmbuild \
    --define "_topdir $RPMBUILD_DIR" \
    "${RPMBUILD_ARGS[@]}" \
    -ba "$RPMBUILD_DIR/SPECS/magpie.spec"

# 7. Collect build artifacts
find "$RPMBUILD_DIR/RPMS" -type f -name "*.rpm" -exec cp -v {} "$RPM_DIST/" \;
find "$RPMBUILD_DIR/SRPMS" -type f -name "*.src.rpm" -exec cp -v {} "$RPM_DIST/" \;

say "Cleaning temporary rpmbuild tree..."
rm -rf "$RPMBUILD_DIR"

say "Build completed successfully!"
printf "\nGenerated RPM packages in \033[1;36m%s\033[0m:\n" "$RPM_DIST"
ls -lh "$RPM_DIST"/*.rpm

printf "\n\033[1;32mInstall on openSUSE Tumbleweed using zypper:\033[0m\n"
printf "  sudo zypper install %s/magpie-%s-%s.*.rpm\n\n" "$RPM_DIST" "$PKG_VER" "$PKG_REL"
