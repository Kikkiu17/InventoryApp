# AppImage Packaging for Inventario

This directory contains the files and scripts required to package the Linux build of **Inventario** into a standalone `.AppImage` executable.

## Directory Contents

- `build_appimage.sh`: Main build script (embeds update information and packages with `appimagetool`).
- `inventario.desktop`: Desktop entry template (the script automatically updates `X-AppImage-Version` and `X-AppImage-UpdateInformation`).
- `AppRun`: Entrypoint script configured to set library paths (`LD_LIBRARY_PATH`) and run the binary.
- `AppDir/`: Temporary directory created during the build process containing the application bundle and metadata.

## How to Build

Run the script directly from this directory or project root:

```bash
./build_appimage.sh
```

### What the script does:
1. Reads the `version` field from `Flutter App/pubspec.yaml` (e.g. `1.15.0`).
2. Runs `flutter build linux --release` to ensure the latest release binaries are compiled.
3. Assembles the `AppDir` layout (executable, `lib/`, `data/`, app icon, `.desktop` file).
4. Sets the version (`X-AppImage-Version`) and update information (`X-AppImage-UpdateInformation`) in `.desktop`.
5. Downloads `appimagetool` automatically (if not already installed).
6. Embeds GitHub Releases update information (`gh-releases-zsync|Kikkiu17|InventoryApp|latest|Inventario-*-x86_64.AppImage.zsync`) via `appimagetool -u`.
7. Packages the app into `Inventario-<VERSION>-x86_64.AppImage` (and generates `.zsync` when `zsyncmake` is present).
