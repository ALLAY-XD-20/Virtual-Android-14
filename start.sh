#!/bin/bash
set -e

#####################################
# Rooted Android 14 (Generic Device)
#####################################

clear
cat <<'EOF'
██████╗  ██████╗  ██████╗ ████████╗
██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝
██████╔╝██║   ██║██║   ██║   ██║   
██╔══██╗██║   ██║██║   ██║   ██║   
██║  ██║╚██████╔╝╚██████╔╝   ██║   
╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   
 Rooted Android 14 • Docker • AOSP
EOF

#####################################
# CONFIG
#####################################
IMAGE="budtmo/docker-android:emulator_14.0"
CONTAINER="android14-rooted"

NOVNC_PORT=8080
VNC_PORT=5901

BASE="$(pwd)"
APK_DIR="$BASE/apks"
DATA_DIR="$BASE/data"
#####################################

# INSTALL DOCKER IF NEEDED
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

# START DOCKER
docker info >/dev/null 2>&1 || sudo service docker start || true

# CREATE DIRS
mkdir -p "$APK_DIR" "$DATA_DIR"

# REMOVE OLD CONTAINER
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

# PULL IMAGE
docker pull "$IMAGE"

# RUN ROOTED ANDROID
docker run -d \
  --name "$CONTAINER" \
  --privileged \
  -p ${NOVNC_PORT}:6080 \
  -p ${VNC_PORT}:5900 \
  -v "$APK_DIR":/apks \
  -v "$DATA_DIR":/data \
  -e DEVICE="generic" \
  -e ANDROID_EMULATOR_FORCE_32BIT=false \
  -e WEB_VNC=true \
  -e AUTO_INSTALL_APKS=true \
  -e APK_PATH=/apks \
  -e ENABLE_ROOT=true \
  "$IMAGE"

# AUTO PUBLIC PORT (CODESPACES)
if [ -n "$CODESPACES" ]; then
  gh codespace ports visibility 8080:public || true
fi

echo ""
echo "======================================"
echo " ✅ ROOTED ANDROID 14 STARTED"
echo ""
echo " 🌐 noVNC : http://localhost:8080"
echo " 🖥  VNC   : localhost:5901"
echo " 🔓 Root  : adb root enabled"
echo " 💾 Data  : ./data"
echo "======================================"
