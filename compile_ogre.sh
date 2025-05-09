#!/bin/bash
#
# Unix_vs_Ogre3D+++
# written by Andrea Giani
#
#
# Parameters:
#
# * no arguments 						: Normal compilation with NASM base
# * --nasm-max 							: Maximum NASM mode (extra optimizations)
# * --no-nasm 							: Disable NASM completely
# * --sse2 									: Enable SSE2
# * --avx2 									: Enable AVX2
# * --march=native 					: Specify architecture (native,haswell,skylake,etc)
# * --show-native-features	: Show defined Macros (useful for checking SSE/AVX/AVX2/etc.).
#

set -e  # Terminate immediately on error

# Definitions
CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
CMAKE_ARGS=(
    -G "Ninja"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=/mingw64
    -DOGRE_BUILD_DEPENDENCIES=OFF
    -DOGRE_INSTALL_DEPENDENCIES=OFF
    -DOGRECave_USE_BULLET=System
    -DOGRE_CONFIG_THREADS=1
)

# Control variable
ENABLE_NASM=true
ENABLE_DEMO=false 
EXTRA_CXX_FLAGS=""
EXTRA_C_FLAGS=""

# Parsing arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nasm-max)
            CMAKE_ARGS+=(-DCMAKE_ASM_NASM_FLAGS="-f win64 -Ox -Worphan-labels -DDEBUG=0")
            ENABLE_NASM=false  # Disable NASM by default
            echo "NASM Max Mode"
            shift
            ;;
        --no-nasm)
            ENABLE_NASM=false
            echo "NASM Disabled"
            shift
            ;;
        --sse2)
            EXTRA_CXX_FLAGS+=" -msse2"
            EXTRA_C_FLAGS+=" -msse2"
            echo "SSE2 Enabled"
            shift
            ;;
        --avx2)
            EXTRA_CXX_FLAGS+=" -mavx2"
            EXTRA_C_FLAGS+=" -mavx2"
            echo "AVX2 Enabled"
            shift
            ;;
        --march=*)
            ARCH="${1#*=}"
            EXTRA_CXX_FLAGS+=" -march=$ARCH"
            EXTRA_C_FLAGS+=" -march=$ARCH"
            echo "Specified architecture: $ARCH"
            shift
            ;;
				--run-demo)
				    ENABLE_DEMO=true
				    shift
				    ;;
        --show-native-features)
            echo "Macros enabled by -march=native:"
            gcc -march=native -dM -E - </dev/null | sort | grep '^#define __[[:upper:]]\+__\>'
            exit 0
            ;;                        
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# extra optimization flags if specified
if [ -n "$EXTRA_CXX_FLAGS" ]; then
    CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS="$EXTRA_CXX_FLAGS")
    CMAKE_ARGS+=(-DCMAKE_C_FLAGS="$EXTRA_C_FLAGS")
fi

# Update and install the necessary packages
pacman -Syu --noconfirm
pacman -S --needed --noconfirm \
    base-devel \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-cmake \
    mingw-w64-x86_64-ogre3d \
    mingw-w64-x86_64-boost \
    mingw-w64-x86_64-bullet \
    mingw-w64-x86_64-openal \
    mingw-w64-x86_64-freealut \
    mingw-w64-x86_64-freeimage \
    mingw-w64-x86_64-pugixml \
    mingw-w64-x86_64-glew \
    mingw-w64-x86_64-glm \
    mingw-w64-x86_64-glsl-optimizer \
    mingw-w64-x86_64-sqlite3 \
    mingw-w64-x86_64-zziplib \
    mingw-w64-x86_64-ninja \
    git \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-glib2 \
    mingw-w64-x86_64-pixman \
    mingw-w64-x86_64-zlib \
    mingw-w64-x86_64-nasm \
    python3 \
    wget \
    ninja \
    meson \
    curl

# Clone and prepare the repository
rm -rf ~/ogre
git clone --recursive https://github.com/OGRECave/ogre.git
cd ogre
git submodule update --init --recursive

# Build configuration
rm -rf build
mkdir -p build
cd build

# Add NASM flags only if required
if $ENABLE_NASM; then
    CMAKE_ARGS+=(-DCMAKE_ASM_NASM_FLAGS="-f win64 -Ox -Worphan-labels")
fi

# CMake Configuration
cmake "${CMAKE_ARGS[@]}" ..

# Compiling and Installing
ninja -j $CPU_CORES
ninja install

echo "OGRE 3D compiled successfully!"

# Run the Sample Browser
if $ENABLE_DEMO; then
# Run the Sample Browser (only if the executable exists)
	if [[ -f /mingw64/bin/SampleBrowser.exe ]]; then
	    echo "Starting the OGRE 3D demo..."
	    start "/mingw64/bin/SampleBrowser.exe"
	else
	    echo "Warning: SampleBrowser.exe not found. The build may have failed."
	fi
fi
