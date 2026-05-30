#!/bin/bash

set -e

# ===================== CONFIG =====================
JAR_NAME="paper.jar"
RAM_MIN="2G"
RAM_MAX="4G"
MC_PORT=25565

NGROK_TOKEN="3EQvAIAE6q5HOFl9fKmpPne9AAR_4QhdfcCvbKs4GJhBfizjx"

# ===================== 1. JDK 25 INSTALL =====================
echo "[+] Checking Java..."

if ! command -v java &> /dev/null; then
  echo "[+] Installing JDK 25..."

  sudo apt update
  sudo apt install -y wget gnupg

  wget -O- https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb -O jdk25.deb
  sudo apt install -y ./jdk25.deb
  rm jdk25.deb

else
  echo "[+] Java already installed"
fi

# ===================== 2. NGROK INSTALL (OFFICIAL METHOD) =====================
if ! command -v ngrok &> /dev/null; then
  echo "[+] Installing ngrok..."

  curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

  echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
    | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null

  sudo apt update
  sudo apt install -y ngrok

else
  echo "[+] ngrok already installed"
fi

# ===================== 3. SET AUTHTOKEN =====================
echo "[+] Configuring ngrok authtoken..."
ngrok config add-authtoken "$NGROK_TOKEN"

# ===================== 4. MINECRAFT EULA =====================
echo "[+] Accepting EULA..."
echo "eula=true" > eula.txt

# ===================== 5. START NGROK =====================
echo "[+] Starting ngrok tunnel..."
ngrok tcp $MC_PORT > ngrok.log 2>&1 &

sleep 3

echo "[+] Ngrok public address:"
curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o '[^"]*$' || echo "Check ngrok dashboard"

# ===================== 6. START SERVER =====================
echo "[+] Starting PaperMC server..."
java -Xms$RAM_MIN -Xmx$RAM_MAX -jar "$JAR_NAME" --nogui