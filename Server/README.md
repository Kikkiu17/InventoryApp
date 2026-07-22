# Inventory Server

Server REST in C++ (Crow + nlohmann/json) per l'app Inventario Componenti.  
Progettato per girare su Raspberry Pi, ma funziona su qualsiasi Linux.

## Setup rapido

```bash
chmod +x setup.sh
./setup.sh
```

Lo script installa le dipendenze, scarica i due header-only (Crow e nlohmann/json) e compila.

## Avvio manuale

```bash
./inventory_server                          # porta 8080, db locale
./inventory_server 9090                     # porta diversa
./inventory_server 8080 /data/inventory.json  # path DB personalizzato
```

## Avvio automatico (systemd)

```bash
# Modifica inventory.service se l'utente non è "pi"
sudo cp inventory.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now inventory
sudo systemctl status inventory
```

## API REST

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| GET | `/api/status` | Ping/stato server |
| GET | `/api/components` | Lista tutti i componenti |
| POST | `/api/components` | Crea componente |
| GET | `/api/components/:id` | Dettaglio componente |
| PUT | `/api/components/:id` | Aggiorna componente |
| PATCH | `/api/components/:id/quantity` | Aggiorna quantità |
| DELETE | `/api/components/:id` | Elimina componente |
| GET | `/api/settings` | Leggi impostazioni |
| PUT | `/api/settings` | Salva impostazioni |
| GET | `/api/db` | Scarica intero database |
| POST | `/api/db` | Carica/sovrascrive database |

### Esempi curl

```bash
# Stato server
curl http://192.168.1.2:8080/api/status

# Lista componenti
curl http://192.168.1.2:8080/api/components

# Aggiungi componente
curl -X POST http://192.168.1.2:8080/api/components \
  -H "Content-Type: application/json" \
  -d '{"id":"abc123","name":"Vite M3","quantity":50,"drawer":"A1","tags":["M3","Vite"]}'

# Incrementa quantità di 5
curl -X PATCH http://192.168.1.2:8080/api/components/abc123/quantity \
  -H "Content-Type: application/json" \
  -d '{"delta": 5}'

# Scarica tutto il DB
curl http://192.168.1.2:8080/api/db -o backup.json
```

## Database

Il database è un semplice file JSON (`inventory.json`). È leggibile/modificabile a mano.

```json
{
  "settings": { "drawerRows": 4, "drawerColumns": 6, "availableTags": [...] },
  "components": [
    { "id": "...", "name": "Vite M3x8", "quantity": 50, "drawer": "A1", "tags": ["M3","Vite"], "description": "" }
  ]
}
```

## Dipendenze

- **Crow** v1.2.0 — framework HTTP header-only
- **nlohmann/json** v3.11.3 — JSON header-only
- **libssl-dev** + **zlib1g-dev** — opzionali (TLS e compressione)
