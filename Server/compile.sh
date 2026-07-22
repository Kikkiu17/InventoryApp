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
echo "  Avvio:  ./inventory_server"
echo "          ./inventory_server 8080"
echo "          ./inventory_server 8080 /path/to/db.json"
echo ""
echo "  Per avviare come servizio systemd:"
echo "    sudo cp inventory.service /etc/systemd/system/"
echo "    sudo systemctl enable --now inventory"
echo "========================================="
