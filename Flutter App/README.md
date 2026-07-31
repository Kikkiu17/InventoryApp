# Inventario Componenti

App Flutter per la gestione dell'inventario di viti, rondelle e altri componenti nei cassetti.

## Funzionalità

### Schermata principale (Inventario)
- **Barra di ricerca** in cima: cerca per nome, cassetto, descrizione o tag
- **Filtro per tag**: tasto filtro che apre un pannello con i tag disponibili (M2, M3, Vite, ecc.)
- **Lista componenti**: mostra nome, cassetto, quantità e tag
  - Scorri verso sinistra per **eliminare** un componente
  - Tocca su un componente per **modificarlo**
  - Usa i pulsanti **+/−** per aggiornare rapidamente la quantità
- **Ordinamento**: menu in alto a destra (per nome, quantità, cassetto)
- **FAB** "Aggiungi" per creare nuovi componenti

### Schermata Impostazioni
- **Configurazione cassetti**: slider per righe e colonne (genera etichette A1, A2… B1, B2…)
  - Con un'anteprima visiva della griglia dei cassetti
- **Gestione tag**: aggiungi/rimuovi tag da usare per i componenti
- **Statistiche**: numero componenti, pezzi totali, tag configurati
- **Export**: esporta il database in formato JSON (share/salva)
- **Import**: importa un file JSON precedentemente esportato

## Setup

### Requisiti
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### Installazione

```bash
cd inventory_app
flutter pub get
flutter run
```

### Build per Android
```bash
flutter build apk --release
```

### Build per iOS
```bash
flutter build ipa
```

## Struttura del progetto

```
lib/
├── main.dart                  # Entry point e shell navigazione
├── models/
│   ├── component.dart         # Modello Component
│   └── settings.dart          # Modello AppSettings
├── services/
│   └── data_service.dart      # Persistenza, ricerca, import/export
├── screens/
│   ├── home_screen.dart       # Schermata principale inventario
│   └── settings_screen.dart   # Schermata impostazioni
└── widgets/
    ├── component_tile.dart    # Card componente con controlli quantità
    └── component_dialog.dart  # Dialog add/edit componente
```

## Formato file di esportazione

```json
{
  "exportedAt": "2024-01-15T10:30:00.000Z",
  "settings": {
    "drawerRows": 4,
    "drawerColumns": 6,
    "availableTags": ["M2", "M3", "Vite", "Rondella", ...]
  },
  "components": [
    {
      "id": "uuid",
      "name": "Vite M3x8",
      "description": "Testa piana philips",
      "quantity": 50,
      "drawer": "A1",
      "tags": ["M3", "Vite"]
    }
  ]
}
```

## Dipendenze principali

| Package | Uso |
|---|---|
| `provider` | State management |
| `shared_preferences` | Persistenza locale |
| `file_picker` | Selezione file per import |
| `share_plus` | Condivisione file per export |
| `path_provider` | Directory temporanea |
| `uuid` | ID univoci per componenti |

## Note per Android

Per il file picker su Android, assicurarsi che `AndroidManifest.xml` contenga i permessi necessari (già inclusi nel template Flutter di default). Su Android 13+ i permessi di storage non sono necessari per i file JSON grazie al SAF (Storage Access Framework).
