# Inventory Server

Server REST in C++ (Crow + nlohmann/json) per l'app Inventario Componenti.  
Progettato per girare su Raspberry Pi, ma funziona su qualsiasi Linux.  
Supporta connessioni sia **HTTP** che **HTTPS** (TLS/SSL).

## Setup rapido

```bash
chmod +x setup.sh
./setup.sh
```

Lo script installa le dipendenze (`build-essential`, `cmake`, `libssl-dev`, `libasio-dev`, `zlib1g-dev`), scarica gli header necessari e compila l'eseguibile.

## Avvio del server

### Modalità HTTP (porta di default 8080)
```bash
./inventory_server                                # porta 8080, cartella dati "inventories"
./inventory_server 9090                           # porta personalizzata
./inventory_server 8080 /data/inventories         # path dati personalizzato
```

### Modalità HTTPS
È possibile avviare il server in HTTPS fornendo un certificato SSL e una chiave privata (.pem o .crt/.key):

```bash
# Avvio con certificato e chiave esistenti
./inventory_server 8443 /data/inventories --ssl cert.pem key.pem

# Oppure tramite argomenti posizionali
./inventory_server 8443 /data/inventories cert.pem key.pem

# Generazione automatica di un certificato autofirmato (se assente) e avvio immediato
./inventory_server 8443 /data/inventories --generate-cert

# Tramite variabili d'ambiente
export SSL_CERT=/path/to/cert.pem
export SSL_KEY=/path/to/key.pem
./inventory_server 8443 /data/inventories
```

### Come creare manualmente un certificato autofirmato con OpenSSL

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -subj "/CN=InventoryServer"
```

## Opzioni da riga di comando

```
Uso: ./inventory_server [porta] [data_dir] [opzioni]

Argomenti posizionali:
  porta               Porta di ascolto (default: 8080)
  data_dir            Cartella dati/inventari (default: inventories)
  cert.pem key.pem    File certificato e chiave SSL (opzionali)

Opzioni HTTPS:
  --ssl <cert> <key>  Abilita HTTPS con certificato e chiave specificati
  --ssl-cert <cert>   Percorso del file certificato SSL (.pem o .crt)
  --ssl-key <key>     Percorso del file chiave privata SSL (.pem o .key)
  --generate-cert     Genera cert.pem e key.pem autofirmati se mancanti e avvia in HTTPS
  --help, -h          Mostra la guida
```

## Avvio automatico (systemd)

Modifica `inventory.service` se desideri eseguire in HTTPS:
```ini
ExecStart=/home/pi/inventario/inventory_server 8443 /home/pi/inventario/inventories --ssl /home/pi/inventario/cert.pem /home/pi/inventario/key.pem
```

Installazione del servizio:
```bash
sudo cp inventory.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now inventory
sudo systemctl status inventory
```

## API REST

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| GET | `/api/status` | Ping/stato server (restituisce anche `"https": true/false`) |
| GET | `/api/inventories` | Lista tutti gli inventari |
| POST | `/api/inventories` | Crea nuovo inventario |
| PUT | `/api/inventories/:id` | Rinomina/aggiorna inventario |
| DELETE | `/api/inventories/:id` | Elimina inventario |
| GET | `/api/inventories/:id/components` | Lista componenti inventario |
| POST | `/api/inventories/:id/components` | Crea componente |
| PUT | `/api/inventories/:id/components/:cid` | Aggiorna componente |
| PATCH | `/api/inventories/:id/components/:cid/quantity` | Aggiorna quantità (+/- delta) |
| DELETE | `/api/inventories/:id/components/:cid` | Elimina componente |
| POST | `/api/inventories/:id/components/:cid/move` | Sposta componente in altro inventario |
| GET | `/api/inventories/:id/settings` | Leggi impostazioni inventario |
| PUT | `/api/inventories/:id/settings` | Salva impostazioni inventario |
| GET | `/api/inventories/:id/db` | Scarica backup JSON |
| POST | `/api/inventories/:id/db` | Carica/ripristina DB |
| GET | `/api/inventories/:id/backups` | Lista snapshot automatici |
| POST | `/api/inventories/:id/backup` | Crea snapshot manuale |
| POST | `/api/inventories/:id/backups/:fn/restore` | Ripristina snapshot |
| POST | `/api/inventories/:id/attachments` | Carica allegato |
| GET | `/api/inventories/:id/attachments/:fn` | Scarica allegato |
| DELETE | `/api/inventories/:id/attachments/:fn` | Elimina allegato |
| GET | `/api/search?q=...` | Ricerca globale su tutti gli inventari |

### Esempi curl

```bash
# Verifica stato in HTTPS (con -k per accettare certificati autofirmati)
curl -k https://192.168.1.2:8443/api/status

# Lista inventari in HTTPS
curl -k https://192.168.1.2:8443/api/inventories

# Lista componenti inventario
curl -k https://192.168.1.2:8443/api/inventories/default/components
```

## Dipendenze

- **Crow** v1.2.0 — framework HTTP/HTTPS C++ header-only
- **nlohmann/json** v3.11.3 — JSON header-only
- **OpenSSL** (`libssl-dev`) — supporto crittografico e TLS/HTTPS
- **Asio** (`libasio-dev` o scaricato automaticamente via CMake FetchContent)
- **zlib** (`zlib1g-dev`) — compressione opzionale
