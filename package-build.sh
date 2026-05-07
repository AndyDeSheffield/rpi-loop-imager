#!/usr/bin/env bash
set -e

# ----------------------------------------
# 1. Move into the packaging directory
# ----------------------------------------

# Move into packaging directory
cd "$(dirname "$0")/packaging"

# Detect architecture
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        DEPLOY=linuxdeploy-x86_64.AppImage
        QTPLUGIN=linuxdeploy-plugin-qt-x86_64.AppImage
        ;;
    aarch64|arm64)
        DEPLOY=linuxdeploy-aarch64.AppImage
        QTPLUGIN=linuxdeploy-plugin-qt-aarch64.AppImage
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH"
echo "Using linuxdeploy: $DEPLOY"
echo "Using Qt plugin:   $QTPLUGIN"

# Download linuxdeploy if missing
if [ ! -f "$DEPLOY" ]; then
    echo "Downloading $DEPLOY..."
    wget "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/$DEPLOY"
    chmod +x "$DEPLOY"
fi

# Download Qt plugin if missing
if [ ! -f "$QTPLUGIN" ]; then
    echo "Downloading $QTPLUGIN..."
    wget "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/$QTPLUGIN"
    chmod +x "$QTPLUGIN"
fi

echo "Packaging tools ready."



# ----------------------------------------
# 2. Force linuxdeploy to use Qt 6.9.3
# ----------------------------------------
export LD_LIBRARY_PATH=/home/andrew/Qt/6.9.3/gcc_64/lib
export PATH=/home/andrew/Qt/6.9.3/gcc_64/bin:$PATH
export QML_SOURCES_PATHS=../src

echo "Using Qt from: $LD_LIBRARY_PATH"
echo "Binary path:   ../src/build/rpi-imager"

# ----------------------------------------
# 3. Create minimal .desktop file (required)
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
# 4. Confirm dummy icon exists and is valid
# ----------------------------------------
if [ ! -f ../dummy.png ]; then
    echo "ERROR: ../dummy.png not found."
    echo "Create it with:"
    echo "  convert -size 32x32 xc:transparent ../dummy.png"
    exit 1
fi

echo "Using existing valid dummy icon: ../dummy.png"

# ----------------------------------------
# 5. Clean previous AppDir if it exists
# ----------------------------------------
rm -rf AppDir

# ----------------------------------------
# 6. Run linuxdeploy with Qt plugin
# ----------------------------------------
./linuxdeploy-x86_64.AppImage \
    --appdir AppDir \
    -e ../src/build/rpi-imager \
    -d ../rpi-imager.desktop \
    -i ../dummy.png \
    --plugin qt

# ----------------------------------------
# 7. Build the final AppImage
# ----------------------------------------
./linuxdeploy-x86_64.AppImage \
    --appdir AppDir \
    --output appimage

echo
echo "----------------------------------------"
echo "AppImage build complete!"
echo "Output file:"
ls -1 *.AppImage
echo "----------------------------------------"
