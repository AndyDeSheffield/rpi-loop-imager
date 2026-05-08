#!/usr/bin/env bash
set -e

# ----------------------------------------
# 1. Architecture‑aware setup (single block)
# ----------------------------------------

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        DEPLOY="linuxdeploy-x86_64.AppImage"
        QTPLUGIN="linuxdeploy-plugin-qt-x86_64.AppImage"
        QTROOT="$HOME/Qt/6.9.3/gcc_64"
        ;;
    aarch64|arm64)
        DEPLOY="linuxdeploy-aarch64.AppImage"
        QTPLUGIN="linuxdeploy-plugin-qt-aarch64.AppImage"
        QTROOT="$HOME/Qt/6.9.3/gcc_arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Validate Qt installation
if [ ! -d "$QTROOT" ]; then
    echo "ERROR: Qt directory not found: $QTROOT"
    exit 1
fi

# Export environment for linuxdeploy-plugin-qt
export QMAKE="$QTROOT/bin/qmake"
export LD_LIBRARY_PATH="$QTROOT/lib"
export PATH="$QTROOT/bin:$PATH"
export QML_SOURCES_PATHS="../src"

echo "Detected architecture: $ARCH"
echo "Using linuxdeploy:    $DEPLOY"
echo "Using Qt plugin:      $QTPLUGIN"
echo "Using Qt root:        $QTROOT"
echo "Using qmake:          $QMAKE"

# ----------------------------------------
# 2. Move into the packaging directory
# ----------------------------------------

cd "$(dirname "$0")/packaging"

# ----------------------------------------
# 3. Ensure linuxdeploy + plugin exist
# ----------------------------------------

if [ ! -f "$DEPLOY" ]; then
    echo "Downloading $DEPLOY..."
    wget "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/$DEPLOY"
    chmod +x "$DEPLOY"
fi

if [ ! -f "$QTPLUGIN" ]; then
    echo "Downloading $QTPLUGIN..."
    wget "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/$QTPLUGIN"
    chmod +x "$QTPLUGIN"
fi

echo "Packaging tools ready."

# ----------------------------------------
# 4. Create minimal .desktop file (required)
# ----------------------------------------

cat > ../rpi-imager.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Raspberry Pi Imager
Exec=rpi-imager
Icon=dummy
Categories=Utility;
EOF

echo "Created minimal desktop file: ../rpi-imager.desktop"

# ----------------------------------------
# 5. Confirm dummy icon exists and is valid
# ----------------------------------------

if [ ! -f ../dummy.png ]; then
    echo "ERROR: ../dummy.png not found."
    echo "Create it with:"
    echo "  convert -size 32x32 xc:transparent ../dummy.png"
    exit 1
fi

echo "Using existing valid dummy icon: ../dummy.png"

# ----------------------------------------
# 6. Clean previous AppDir if it exists
# ----------------------------------------

rm -rf AppDir

# ----------------------------------------
# 7. Run linuxdeploy with Qt plugin
# ----------------------------------------

./"$DEPLOY" \
    --appdir AppDir \
    -e ../src/build/rpi-imager \
    -d ../rpi-imager.desktop \
    -i ../dummy.png \
    --plugin qt

# ----------------------------------------
# 8. Build the final AppImage
# ----------------------------------------

./"$DEPLOY" \
    --appdir AppDir \
    --output appimage

echo
echo "----------------------------------------"
echo "AppImage build complete!"
echo "Output file:"
ls -1 *.AppImage
echo "----------------------------------------"
