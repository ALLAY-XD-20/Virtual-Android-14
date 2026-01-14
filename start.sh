#!/bin/bash
set -e

#####################################
# PxTool - Docker Android 14 noVNC
#####################################

clear
cat <<'EOF'
██████╗ ██╗  ██╗████████╗ ██████╗  ██████╗ ██╗     
██╔══██╗╚██╗██╔╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██████╔╝ ╚███╔╝    ██║   ██║   ██║██║   ██║██║     
██╔═══╝  ██╔██╗    ██║   ██║   ██║██║   ██║██║     
██║     ██╔╝ ██╗   ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝     ╚═╝  ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
        PxTool - Docker Android 14 (noVNC)
EOF

echo "🔍 Checking Docker..."

#####################################
# INSTALL DOCKER IF NOT PRESENT
#####################################
if ! command -v docker >/dev/null 2>&1; then
  echo "📦 Docker not found. Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

#####################################
# START DOCKER DAEMON (CODESPACES SAFE)
#####################################
if ! docker info >/dev/null 2>&1; then
  echo "🚀 Starting Docker daemon..."
  sudo service docker start || true
fi

#####################################
# CLEAN OLD CONTAINER
#####################################
docker rm -f android14 >/dev/null 2>&1 || true

#####################################
# PULL ANDROID 14 IMAGE
#####################################
echo "⬇️ Pulling Android 14 Docker image..."
docker pull budtmo/docker-android:emulator_14.0

#####################################
# RUN ANDROID 14
#####################################
echo "🚀 Starting Android 14 container..."

docker run -d \
  --name android14 \
  --privileged \
  -p 8080:6080 \
  -p 5901:5900 \
  -e DEVICE="pixel" \
  -e WEB_VNC=true \
  -e WEB_VNC_PORT=6080 \
  -e APPIUM=false \
  -e ADB_SERVER_PORT=5037 \
  budtmo/docker-android:emulator_14.0

#####################################
# DONE
#####################################
echo ""
echo "======================================"
echo " ✅ ANDROID 14 IS STARTING"
echo ""
echo " 🌐 noVNC  : http://localhost:8080"
echo " 🖥  VNC    : localhost:5901"
echo ""
echo " ⏳ First boot takes 1–3 minutes"
echo "======================================"
