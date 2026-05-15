#!/bin/bash
# setup.sh - Scarica le dipendenze header-only e compila il server
# Eseguire su Raspberry Pi / Debian/Ubuntu

set -e

echo "========================================="
echo "  Inventory Server - Setup"
echo "========================================="

# Installa dipendenze di sistema
echo "[1/4] Installazione dipendenze sistema..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential \
    cmake \
    libssl-dev \
    zlib1g-dev \
    wget \
    curl

# Crea cartella include
mkdir -p include

# Scarica nlohmann/json (singolo header)
echo "[2/4] Download nlohmann/json..."
wget -q -O include/json.hpp \
    "https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp"
echo "    ✓ json.hpp scaricato"

# Scarica Crow (singolo header amalgamato)
echo "[3/4] Download Crow..."
wget -q -O include/crow_all.h \
    "https://github.com/CrowCpp/Crow/releases/download/v1.2.0/crow_all.h"
echo "    ✓ crow_all.h scaricato"

# Compila
echo "[4/4] Compilazione..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17
make -j$(nproc)
cp inventory_server ..
cd ..

echo ""
echo "========================================="
echo "  Compilazione completata!"
echo ""
echo "  Avvio:  ./inventory_server"
echo "          ./inventory_server 8080"
echo "          ./inventory_server 8080 /path/to/db.json"
echo ""
echo "  Per avviare come servizio systemd:"
echo "    sudo cp inventory.service /etc/systemd/system/"
echo "    sudo systemctl enable --now inventory"
echo "========================================="
