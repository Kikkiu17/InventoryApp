# Inventory App

A multi-platform inventory management application designed for organizing hardware components, electronics, fasteners, and storage drawer cabinets.

Built with **Flutter** for the cross-platform client application and **C++ (Crow Framework)** for an optional lightweight self-hosted backend server.

---

## Features

- **Visual Drawer Cabinet Map**: Interactive grid view to organize and locate components within physical drawer cabinets.
- **Search and Tagging**: Filter components by name, drawer position, description, or custom tags.
- **Multi-Platform Support**: Cross-platform support for Android, Linux (AppImage), and Windows (Single Executable Installer).
- **Quantity Adjustments**: Quick increment and decrement controls for component stock levels.
- **Local and Server Sync**: Operates offline using local storage or syncs with the self-hosted C++ REST server.
- **Data Export and Import**: Export inventory reports to PDF or perform database backup and restoration via JSON files.

---

## Tech Stack and Architecture

```
InventoryApp/
├── Flutter App/        # Cross-platform Flutter client (Android, Linux, Windows, macOS)
├── Server/             # C++ REST API backend (Crow + nlohmann/json)
├── AppImage/           # Linux packaging scripts and resources
└── .github/workflows/  # Multi-platform CI/CD build pipeline
```

- **Frontend**: Flutter (Dart), Provider state management, `shared_preferences`, `http`, `pdf`.
- **Backend Server**: C++20, Crow Web Framework, `nlohmann/json`.
- **CI/CD**: GitHub Actions building Android APK, Linux AppImage, and Windows Setup Executable via Inno Setup.

---

## Downloads and Installation

Pre-compiled release binaries are automatically built and published for tagged releases:

- **Android**: Download `app-release.apk`
- **Linux**: Download `Inventario-x86_64.AppImage` (mark executable with `chmod +x` before running)
- **Windows**: Download `Inventario-Windows-x64-Setup.exe` (run setup executable)

---

## Building from Source

### Prerequisites
- **Flutter SDK**: `>= 3.0.0`
- **Dart SDK**: `>= 3.0.0`
- **C++ Compiler** (GCC or Clang) & **CMake** (for building the server)

### 1. Flutter Client
```bash
cd "Flutter App"

# Install dependencies
flutter pub get

# Run application
flutter run

# Build release packages
flutter build apk --release            # Android APK
flutter build linux --release          # Linux Desktop
flutter build windows --release        # Windows Desktop
```

### 2. C++ Server (Optional)
```bash
cd Server

# Install dependencies and compile
chmod +x setup.sh
./setup.sh

# Run server on port 8080
./inventory_server 8080
```

#### Systemd Service Installation (Linux / Raspberry Pi)
```bash
sudo cp Server/inventory.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now inventory
```

---

## REST API Specification

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/status` | Server status check |
| `GET` | `/api/components` | Retrieve all inventory components |
| `POST` | `/api/components` | Create a new component |
| `GET` | `/api/components/:id` | Get details for a specific component |
| `PUT` | `/api/components/:id` | Update component data |
| `PATCH` | `/api/components/:id/quantity` | Update component quantity |
| `DELETE` | `/api/components/:id` | Delete a component |
| `GET` | `/api/db` | Export JSON database backup |
| `POST` | `/api/db` | Overwrite JSON database |

---

## Continuous Integration

The repository includes a GitHub Actions workflow ([.github/workflows/build.yml](.github/workflows/build.yml)):
- Compiles Android APK, Linux AppImage, and Windows Setup Executable targets.
- Triggers on version tag pushes (e.g. `v1.11.0`) or when creating releases via GitHub Web UI.
- Automatically attaches compiled binaries to the corresponding GitHub Release.

---

## License

Distributed under the MIT License. See `LICENSE` for details.
