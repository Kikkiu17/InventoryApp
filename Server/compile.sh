echo "Compilazione..."
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
echo "  Avvio HTTP:   ./inventory_server"
echo "                ./inventory_server 8080"
echo "                ./inventory_server 8080 /path/to/db"
echo ""
echo "  Avvio HTTPS:  ./inventory_server 8443 /path/to/db --ssl cert.pem key.pem"
echo "                ./inventory_server 8443 /path/to/db --generate-cert"
echo ""
echo "  Per avviare come servizio systemd:"
echo "    sudo cp inventory.service /etc/systemd/system/"
echo "    sudo systemctl enable --now inventory"
echo "========================================="
