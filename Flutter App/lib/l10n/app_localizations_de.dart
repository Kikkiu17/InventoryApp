import 'app_localizations.dart';

class AppLocalizationsDe extends AppLocalizations {
  @override
  String get appName => 'Bauteile-Inventar';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get save => 'Speichern';
  @override
  String get delete => 'Löschen';
  @override
  String get edit => 'Bearbeiten';
  @override
  String get add => 'Hinzufügen';
  @override
  String get close => 'Schließen';
  @override
  String get apply => 'Anwenden';
  @override
  String get confirm => 'Bestätigen';
  @override
  String get error => 'Fehler';
  @override
  String get warning => 'Warnung';
  @override
  String get success => 'Erfolgreich';
  @override
  String get search => 'Suchen';
  @override
  String get loading => 'Laden...';
  @override
  String get nameLabel => 'Name';
  @override
  String get options => 'Optionen';
  @override
  String get details => 'Details';
  @override
  String get actions => 'Aktionen';
  @override
  String get select => 'Auswählen';
  @override
  String get none => 'Keine';
  @override
  String get all => 'Alle';
  @override
  String get yes => 'Ja';
  @override
  String get no => 'Nein';
  @override
  String get check => 'Prüfen';

  // Navigation / Tabs
  @override
  String get tabInventory => 'Inventar';
  @override
  String get tabBuffer => 'Puffer';
  @override
  String get tabInventories => 'Inventare';
  @override
  String get tabFiles => 'Dateien';
  @override
  String get tabSettings => 'Einstellungen';

  // Home Screen
  @override
  String get viewList => 'Liste';
  @override
  String get viewMap => 'Karte';
  @override
  String get searchPlaceholder => 'Bauteile suchen...';
  @override
  String get searchTooltip => 'Suchen';
  @override
  String get sortTitle => 'Sortieren nach';
  @override
  String get sortNone => 'Keine Sortierung';
  @override
  String get sortName => 'Name';
  @override
  String get sortQuantity => 'Menge';
  @override
  String get sortDrawer => 'Schublade';
  @override
  String get sortAscending => 'Reihenfolge: Aufsteigend';
  @override
  String get sortDescending => 'Reihenfolge: Absteigend';
  @override
  String get filterAll => 'Alle Schubladen';
  @override
  String get filterUnassigned => 'Nicht zugewiesen';
  @override
  String get filterCabinet => 'Schrank';
  @override
  String get clearFilters => 'Filter zurücksetzen';
  @override
  String get filterByTag => 'Nach Tag filtern';
  @override
  String get filterByProperty => 'Nach Eigenschaft filtern';
  @override
  String get exportPdfTooltip => 'Liste als PDF exportieren';
  @override
  String get exportPdfTitle => 'Bauteile-Inventar';
  @override
  String get colName => 'Name';
  @override
  String get colPosition => 'Position';
  @override
  String get colQuantity => 'Menge';
  @override
  String get colDetails => 'Details';
  @override
  String get unassignedPosition => 'Nicht zugew.';
  @override
  String get exportSuccess => 'PDF erfolgreich exportiert';
  @override
  String get exportError => 'Fehler beim PDF-Export';
  @override
  String get serverConnected => 'Server verbunden';
  @override
  String get serverDisconnected => 'Server getrennt';
  @override
  String get switchInventory => 'Wechseln';
  @override
  String get selectInventory => 'Inventar auswählen';
  @override
  String get drawerTitle => 'Schublade';
  @override
  String get emptyDrawer => 'Keine Bauteile in dieser Schublade';
  @override
  String get addComponentHere => 'Bauteil hier hinzufügen';
  @override
  String get configureDrawer => 'Schublade konfigurieren';
  @override
  String get bulkActions => 'Massenaktionen';
  @override
  String get bulkMove => 'Ausgewählte verschieben';
  @override
  String get bulkDelete => 'Ausgewählte löschen';
  @override
  String get bulkAddTag => 'Tag zu ausgewählten hinzufügen';
  @override
  String get bulkRemoveTag => 'Tag von ausgewählten entfernen';
  @override
  String get selectedComponents => 'ausgewählte Bauteile';
  @override
  String get deleteComponentTitle => 'Bauteil löschen';
  @override
  String deleteComponentConfirm(String name) =>
      'Möchten Sie "$name" wirklich löschen?';
  @override
  String get noComponentsFound => 'Keine Bauteile gefunden';
  @override
  String errorChangingInventory(String error) =>
      'Fehler beim Wechseln des Inventars: $error';
  @override
  String errorSaving(String error) => 'Fehler beim Speichern: $error';
  @override
  String errorDeleting(String error) => 'Fehler beim Löschen: $error';

  // Buffer Screen
  @override
  String get bufferTitle => 'Puffer';
  @override
  String get searchBufferPlaceholder => 'Im Puffer suchen...';
  @override
  String get allBags => 'Alle';
  @override
  String get unassignedBag => 'Ohne Beutel';
  @override
  String get addBag => 'Neuer Beutel';
  @override
  String get deleteBag => 'Beutel löschen';
  @override
  String get bagName => 'Beutelname';
  @override
  String get renameBag => 'Beutel umbenennen';
  @override
  String get emptyBufferTitle => 'Puffer ist leer';
  @override
  String get emptyBufferSubtitle =>
      'Bauteile, die noch nicht in Schubladen einsortiert sind, erscheinen hier.';
  @override
  String get moveToDrawer => 'Schublade zuweisen';
  @override
  String get addComponentToBuffer => 'Zum Puffer hinzufügen';
  @override
  String get bulkMoveToDrawer => 'Schublade zuweisen';
  @override
  String deleteBagConfirm(String bag) =>
      'Beutel "$bag" löschen? Die Bauteile verbleiben im Puffer.';
  @override
  String get newBagTitle => 'Neuer Beutel';

  // Inventory List Screen
  @override
  String get inventoriesTitle => 'Inventare';
  @override
  String get searchAllInventoriesPlaceholder => 'In allen Inventaren suchen…';
  @override
  String get localInventory => 'Lokales Inventar';
  @override
  String get remoteInventory => 'Entfernt';
  @override
  String get currentBadge => 'AKTUELL';
  @override
  String itemsCount(int count) => '$count Bauteile';
  @override
  String get newInventoryTitle => 'Neues Inventar';
  @override
  String get inventoryName => 'Inventarname';
  @override
  String get create => 'Erstellen';
  @override
  String get deleteInventoryTitle => 'Inventar löschen';
  @override
  String deleteInventoryConfirm(String name) =>
      'Möchten Sie das Inventar "$name" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  @override
  String get syncNow => 'Jetzt synchronisieren';
  @override
  String get syncSuccess => 'Synchronisierung abgeschlossen';
  @override
  String get syncError => 'Synchronisierungsfehler';
  @override
  String get restoreBackup => 'Backup wiederherstellen';
  @override
  String get noResults => 'Keine Ergebnisse';
  @override
  String noResultsDescription(String query) =>
      'Kein Bauteil oder Inventar entspricht "$query".';
  @override
  String get bufferComponentsCategory => 'PUFFER-BAUTEILE';

  // Files Screen
  @override
  String get filesTitle => 'Dateien & Anhänge';
  @override
  String get searchFilesPlaceholder => 'Dateien suchen...';
  @override
  String get allFiles => 'Alle Dateien';
  @override
  String get componentFiles => 'Bauteildateien';
  @override
  String get noFiles => 'Keine Dateien vorhanden';
  @override
  String get shareFile => 'Teilen';
  @override
  String get deleteFile => 'Datei löschen';
  @override
  String deleteFileConfirm(String fileName) =>
      'Möchten Sie "$fileName" wirklich löschen?';
  @override
  String get fileSize => 'Größe';
  @override
  String get openFileError => 'Datei konnte nicht geöffnet werden';

  // Settings Screen
  @override
  String get settingsTitle => 'Einstellungen';
  @override
  String get saveSettings => 'Speichern';
  @override
  String get sectionRemoteServer => 'Remote-Server';
  @override
  String get sectionAppearance => 'Erscheinungsbild';
  @override
  String get sectionLanguage => 'Sprache';
  @override
  String get sectionContainers => 'Schrank-Konfiguration (Schubladen)';
  @override
  String get sectionTagTree => 'Tag-Baum';
  @override
  String get sectionGenericTags => 'Allgemeine Tags';
  @override
  String get sectionProperties => 'Eigenschaften mit Wert';
  @override
  String get sectionData => 'Daten';
  @override
  String get sectionAbout => 'Über & Updates';
  @override
  String get useRemoteServer => 'Remote-Server verwenden';
  @override
  String get serverConnectedStatus => '✅ Verbunden';
  @override
  String get serverDisconnectedStatus => '❌ Nicht verbunden';
  @override
  String get localStorageStatus => 'Lokaler Speicher';
  @override
  String get serverUrl => 'Server-Adresse';
  @override
  String get testConnection => 'Verbindung testen';
  @override
  String get connectionSuccess => 'Verbindung erfolgreich hergestellt!';
  @override
  String get connectionFailed => 'Verbindung zum Server fehlgeschlagen';
  @override
  String get themeMode => 'App-Design';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Hell';
  @override
  String get themeDark => 'Dunkel';
  @override
  String get languageLabel => 'App-Sprache';
  @override
  String get languageSystem => 'Systemstandard';
  @override
  String get langEn => 'English';
  @override
  String get langIt => 'Italiano';
  @override
  String get langEs => 'Español';
  @override
  String get langFr => 'Français';
  @override
  String get langDe => 'Deutsch';
  @override
  String get containersDesc =>
      'Physische Schränke verwalten. Jeder Schrank kann individuelle Maße und Formen haben, indem Schubladen in der Vorschau deaktiviert werden.';
  @override
  String get newContainer => 'Schrank hinzufügen';
  @override
  String get containerName => 'Schrankname';
  @override
  String get rows => 'Zeilen';
  @override
  String get columns => 'Spalten';
  @override
  String get invertRows => 'Zeilennummerierung umkehren (von unten nach oben)';
  @override
  String get invertColumns => 'Spalten umkehren (von rechts nach links)';
  @override
  String get previewAndShape => 'Vorschau & Form';
  @override
  String get drawerGridHint =>
      'Vorschau (Klicken zum Konfigurieren, langes Drücken und Ziehen für Mehrfachauswahl)';
  @override
  String get deleteContainer => 'Schrank löschen';
  @override
  String get drawerConfigTitle => 'Schubladen-Konfiguration';
  @override
  String get drawerDisabled => 'Schublade deaktiviert';
  @override
  String get drawerZones => 'Zonen / Teiler';
  @override
  String get mergeDrawers => 'Schubladen zusammenführen';
  @override
  String get splitDrawers => 'Schubladen trennen';
  @override
  String get tagTreeDesc =>
      'Kategorien und Unterkategorien durch Eingabe und Drücken der Eingabetaste erstellen.';
  @override
  String get genericTagsDesc =>
      'Hierarchielose Tags zur schnellen Kennzeichnung von Bauteilen.';
  @override
  String get newGenericTag => 'Neuer allgemeiner Tag';
  @override
  String get addTag => 'Hinzufügen';
  @override
  String deleteTagConfirm(String tag) => 'Tag "$tag" löschen?';
  @override
  String get propertiesDesc =>
      'Numerische oder Text-Eigenschaften definieren. Zum Sortieren ziehen.';
  @override
  String get propName => 'Name';
  @override
  String get propUnit => 'Einheit';
  @override
  String get propSigla => 'Kürzel';
  @override
  String get propSiglaHint => 'z.B. L';
  @override
  String get propText => 'Text';
  @override
  String get addProp => 'Hinzufügen';
  @override
  String get noPropsConfigured => 'Keine Eigenschaften konfiguriert.';
  @override
  String get editPropTitle => 'Eigenschaft bearbeiten';
  @override
  String get propUnitLabel => 'Einheit';
  @override
  String get propTextFree => 'Freitext';
  @override
  String deletePropConfirm(String name) => 'Eigenschaft "$name" löschen?';
  @override
  String get dataBackupDesc => 'Backup- und Exportverwaltung';
  @override
  String get exportJson => 'Lokales Backup exportieren (JSON)';
  @override
  String get importJson => 'Aus JSON-Datei wiederherstellen';
  @override
  String get restoreRemoteBackup => 'Remote-Backup wiederherstellen';
  @override
  String get backupCreated => 'Backup erfolgreich erstellt';
  @override
  String get checkUpdates => 'Nach Updates suchen';
  @override
  String get checkUpdatesSubtitle =>
      'Neueste Version von GitHub prüfen und herunterladen';
  @override
  String get openGitHub => 'GitHub-Seite öffnen';
  @override
  String get appVersion => 'App-Version';
  @override
  String get manualDrawerConfigTitle =>
      'Schublade nach Koordinaten konfigurieren (für nicht sichtbare Schubladen)';
  @override
  String get manualDrawerCode => 'Schubladencode';
  @override
  String get manualDrawerHint => 'z.B. A20 oder K4';
  @override
  String get configureButton => 'Konfigurieren';
  @override
  String get noGenericTags => 'Keine allgemeinen Tags.';
  @override
  String get settingsSaved => 'Einstellungen gespeichert';
  @override
  String get activeInventory => 'Aktives Inventar';
  @override
  String get enableAll => 'Alle aktivieren';
  @override
  String get disableAll => 'Alle deaktivieren';
  @override
  String get enabled => 'Aktiviert';
  @override
  String get divideIntoZones => 'In Zonen unterteilen';
  @override
  String get restoreBackupTitle => 'Sicherung wiederherstellen';
  @override
  String get confirmRestoreTitle => 'Wiederherstellung bestätigen';
  @override
  String get confirmRestoreMsg =>
      'Aktuelle Daten überschreiben? (Zuvor wird eine automatische Sicherheitskopie erstellt).';
  @override
  String get restoreSuccess => 'Sicherung erfolgreich wiederhergestellt';
  @override
  String get noBackupsFound => 'Keine Sicherungen gefunden';
  @override
  String bulkDrawerAction(int count) => 'Massenaktion ($count Schubladen)';
  @override
  String get bulkDrawerActionDesc =>
      'Was möchten Sie mit den ausgewählten Schubladen tun?\nSie können sie deaktivieren, aktivieren, Zonen festlegen oder zusammenführen/teilen.';
  @override
  String get setZones => 'Zonen festlegen...';
  @override
  String zonesCount(int count) => '$count Zonen';
  @override
  String get noDividers => 'Keine Trennwand (1 Zone)';
  @override
  String get filterRemoveAll => 'Alle entfernen';
  @override
  String get filterOnlyUnassigned => 'Nur Bauteile ohne Position anzeigen';
  @override
  String get filterOnlyUnassignedDesc =>
      'Blendet Bauteile aus, denen bereits eine Schublade zugewiesen ist';
  @override
  String get quickTags => 'Schnell-Tags';
  @override
  String get cabinetContainer => 'Behälter / Schrank';
  @override
  String get navigateTagTree => 'Tags durchsuchen';
  @override
  String get tagTreeRoot => 'Start';
  @override
  String get noSubtags => 'Keine Unter-Tags verfügbar.';
  @override
  String get propertyFilters => 'Eigenschaftsfilter';
  @override
  String get containsText => 'Enthält Text...';
  @override
  String get exactValue => 'Exakter Wert';
  @override
  String get fromMin => 'Von (min)';
  @override
  String get toMax => 'Bis (max)';
  @override
  String get applyFilters => 'Filter anwenden';
  @override
  String get selectedTagsLabel => 'Ausgewählte Tags';
  @override
  String get invalidDrawerCoords =>
      'Ungültige Schubladenkoordinaten für die aktuellen Schrankabmessungen';
  @override
  String get moveAction => 'Verschieben';
  @override
  String get selectTargetInventory => 'Zielinventar auswählen';
  @override
  String componentMovedSuccess(String targetName) =>
      'Bauteil nach "$targetName" verschoben';
  @override
  String get errorMovingComponent => 'Fehler beim Verschieben';
  @override
  String get addAttachmentLink => 'Link';
  @override
  String get addAttachmentFile => 'Datei hochladen';
  @override
  String get addAttachmentExisting => 'Vorhandene Datei';
  @override
  String get takePhotoNow => 'Jetzt Foto aufnehmen';
  @override
  String get chooseFromGallery => 'Aus Galerie wählen';
  @override
  String get addPhoto => 'Foto hinzufügen';
  @override
  String get renameFile => 'Datei umbenennen';
  @override
  String get filesFound => 'Dateien gefunden';
  @override
  String get fileOptions => 'Optionen';
  @override
  String get rename => 'Umbenennen';
  @override
  String get notAssigned => 'Nicht zugewiesen';
  @override
  String get selectFromMap => 'Aus Karte wählen';
  @override
  String changeDrawerSeparators(int zones) =>
      'Trennwände bearbeiten ($zones Zonen)';
  @override
  String get configureDrawerSeparators =>
      'Trennwände konfigurieren (normale Schublade)';
  @override
  String get zoneSeparatorLabel => 'Schubladenzone (Trennwand)';

  // Component Dialog
  @override
  String get newComponentTitle => 'Neues Bauteil';
  @override
  String get editComponentTitle => 'Bauteil bearbeiten';
  @override
  String get duplicateComponentTitle => 'Bauteil duplizieren';
  @override
  String get compNameLabel => 'Name';
  @override
  String get compNameError => 'Bitte einen Namen eingeben';
  @override
  String get compDescLabel => 'Beschreibung oder Notizen';
  @override
  String get compQtyLabel => 'Menge';
  @override
  String get compCabinetLabel => 'Schrank';
  @override
  String get compDrawerLabel => 'Schublade';
  @override
  String get compZoneLabel => 'Schubladenzone';
  @override
  String get tagsSectionTitle => 'Tags & Kategorien';
  @override
  String get selectTreeTags => 'Tag-Baum';
  @override
  String get selectGenericTags => 'Allgemeine Tags';
  @override
  String get showGenericTags => 'Allgemeine Tags anzeigen';
  @override
  String get hideGenericTags => 'Allgemeine Tags ausblenden';
  @override
  String get propertiesSectionTitle => 'Eigenschaften';
  @override
  String get addCustomProperty => 'Eigenschaft hinzufügen';
  @override
  String get imagesSectionTitle => 'Bilder & Anhänge';
  @override
  String get addImage => 'Bild hinzufügen';
  @override
  String get camera => 'Kamera';
  @override
  String get gallery => 'Galerie';
  @override
  String get removeImage => 'Entfernen';
  @override
  String get keepInBuffer => 'Im Puffer behalten';
  @override
  String get assignToDrawer => 'Schublade zuweisen';
  @override
  String get saveButton => 'Speichern';
  @override
  String get cancelButton => 'Abbrechen';
  @override
  String get deleteButton => 'Löschen';
  @override
  String get draftSaved => 'Entwurf gespeichert';
  @override
  String get draftRestored => 'Entwurf wiederhergestellt';

  // Component View Dialog
  @override
  String get componentDetailsTitle => 'Bauteildetails';
  @override
  String get quantityLabel => 'Menge:';
  @override
  String get locationLabel => 'Ort:';
  @override
  String get drawerLabel => 'Schublade:';
  @override
  String get cabinetLabel => 'Schrank:';
  @override
  String get zoneLabel => 'Zone:';
  @override
  String get tagsLabel => 'Tags:';
  @override
  String get propertiesLabel => 'Eigenschaften:';
  @override
  String get notesLabel => 'Notizen:';
  @override
  String get attachedFilesLabel => 'Anhänge:';
  @override
  String get editAction => 'Bearbeiten';
  @override
  String get duplicateAction => 'Duplizieren';
  @override
  String get moveToBufferAction => 'In Puffer verschieben';
  @override
  String get printLabelAction => 'Etikett drucken';
  @override
  String get deleteAction => 'Löschen';
  @override
  String confirmDeleteMsg(String name) =>
      'Möchten Sie "$name" wirklich löschen?';

  // Drawer Picker Dialog
  @override
  String get selectDrawerTitle => 'Schublade auswählen';
  @override
  String get searchDrawerPlaceholder => 'Schublade filtern...';
  @override
  String get selectZone => 'Zone:';
  @override
  String cabinetTab(int id, String name) =>
      name.isNotEmpty ? name : 'Schrank $id';

  // Update Service
  @override
  String get updateAvailableTitle => 'Update verfügbar';
  @override
  String updateAvailableDesc(String version) =>
      'Eine neue Version ($version) ist verfügbar. Jetzt herunterladen?';
  @override
  String get updateNowButton => 'Jetzt aktualisieren';
  @override
  String get laterButton => 'Später';
  @override
  String get dontShowAgain => 'Beim Start nicht mehr anzeigen';
  @override
  String get releaseNotes => 'Versionshinweise';
  @override
  String get downloadingUpdate => 'Update wird heruntergeladen...';
  @override
  String get installUpdate => 'Update installieren';
  @override
  String get updateError => 'Fehler beim Update';
  @override
  String get noUpdateAvailable => 'Die App ist bereits auf dem neuesten Stand.';

  // Conflicts
  @override
  String get conflictTitle => 'Synchronisierungskonflikt';
  @override
  String get conflictDesc =>
      'Entfernte Daten wurden seit der letzten lokalen Synchronisierung geändert. Wählen Sie, welche Version beibehalten werden soll.';
  @override
  String get useLocal => 'Lokal behalten';
  @override
  String get useRemote => 'Entfernt behalten';
  @override
  String get compare => 'Vergleichen';

  @override
  String get selectCabinetLabel => 'Behälter auswählen:';
  @override
  String get tapDrawerToSelect =>
      'Tippen Sie auf eine Schublade, um sie auszuwählen';
  @override
  String drawerSelected(String label, [int? zone]) =>
      'Ausgewählt: Schublade $label${zone != null ? " (Zone $zone)" : ""}';
  @override
  String get noContainersConfigured =>
      'Keine Behälter in den Einstellungen konfiguriert.';
  @override
  String get offlineUsingLocal => 'Offline · lokale Daten verwendet';
  @override
  String get switchButton => 'Wechseln';
  @override
  String get sync => 'Synchronisieren';
  @override
  String get sortBy => 'Nach';
  @override
  String resultsCount(int count) => '$count Ergebnisse';
  @override
  String componentsCount(int count) => '$count Komponenten';
  @override
  String updateAvailableBadge(String version) =>
      'Update verfügbar (v$version)';
  @override
  String get updateAvailableQuestion =>
      'Eine neue Version ist verfügbar. Möchten Sie sie jetzt herunterladen und installieren?';
  @override
  String get positionLabel => 'Position';
  @override
  String get targetInventoryLabel => 'Ziel-Inventar';
  @override
  String get noneToSelect => 'Keines (Auszuwählen)';
  @override
  String get rowLabel => 'Reihe';
  @override
  String get columnLabel => 'Spalte';
  @override
  String get requiredField => 'Erforderlich';
  @override
  String get disabledDrawer => 'Deaktiviert';
  @override
  String get savePosition => 'Position speichern';
  @override
  String get placeAction => 'Platzieren';
  @override
  String placeComponentSuccess(String name) =>
      '"$name" erfolgreich platziert!';
  @override
  String get cannotOpenLink => 'Link kann nicht geöffnet werden';
  @override
  String get cannotOpenFile => 'Datei kann nicht geöffnet werden';
  @override
  String get refreshList => 'Liste aktualisieren';
  @override
  String get localModeTitle => 'Lokaler Modus';
  @override
  String get localModeDesc =>
      'Aktivieren Sie den Remote-Server in den Einstellungen, um mehrere Inventare zu verwalten.';
  @override
  String get serverUnreachableTitle => 'Server nicht erreichbar';
  @override
  String get serverUnreachableDesc =>
      'Überprüfen Sie Ihre Verbindung und die Serveradresse.';
  @override
  String get retry => 'Wiederholen';
  @override
  String get noInventoriesTitle => 'Keine Inventare';
  @override
  String get noInventoriesDesc =>
      'Erstellen Sie Ihr erstes Inventar, um zu beginnen.';
  @override
  String get createInventory => 'Inventar erstellen';
  @override
  String get inventoryAlreadyActive => 'Inventar bereits aktiv';
  @override
  String switchedToInventory(String name) => 'Zu "$name" gewechselt';
  @override
  String get deleteInventoryPermanentWarning =>
      'Alle Komponenten werden dauerhaft gelöscht.';
  @override
  String get activeBadge => 'Aktiv';
  @override
  String get uploadedFilesTitle => 'Hochgeladene Dateien';
  @override
  String filesFoundCount(int count) => '$count Dateien gefunden';
  @override
  String get noFilesFound => 'Keine Dateien gefunden';
  @override
  String get searchFilesPlaceholderLong =>
      'Datei oder Komponente suchen...';
  @override
  String deleteAttachmentConfirm(String name) =>
      'Möchten Sie "$name" dauerhaft löschen?';
  @override
  String get deleteImageTitle => 'Bild löschen';
  @override
  String get deleteFileTitle => 'Datei löschen';
  @override
  String get componentPrefix => 'Komponente';

  @override
  String get zoneNearLabel => 'Nah (vorne)';
  @override
  String get zoneFarLabel => 'Fern (hinten)';
  @override
  String get zoneMiddleLabel => 'In der Mitte';
  @override
  String zoneMiddleIndex(int index) => 'In der Mitte ($index)';

  @override
  String deleteBufferComponentConfirm(String name) =>
      'Möchten Sie "$name" wirklich aus dem Puffer entfernen?';
  @override
  String assignedDestination(String target) =>
      'Zugewiesenes Ziel: $target';
  @override
  String get destinationUnspecified => 'Ziel nicht angegeben';
  @override
  String get noDestination => 'Kein Ziel';
  @override
  String get emptyBufferDesc =>
      'Fügen Sie Komponenten hinzu, um sie vorübergehend zu registrieren, bevor Sie sie platzieren.';
  @override
  String get noBufferResultsDesc =>
      'Keine Komponenten im Puffer entsprechen Ihrer Suche.';
  @override
  String placeItemDialogTitle(String name) => '"$name" platzieren';
  @override
  String get placeItemDialogDesc =>
      'Geben Sie den physischen Standort an, um die Komponente vom Puffer in das Inventar zu verschieben.';
  @override
  String destinationLabel(String target) => 'Ziel: $target';
  @override
  String get changeDestinationAndTags => 'Ziel ändern (und Tags)';
  @override
  String maxColumnLabel(String col) => 'Max. Spalte: $col';
  @override
  String maxRowLabel(int row) => 'Max. Zeile: $row';
  @override
  String get drawerZoneSeparator => 'Schubladenzone (Teiler)';
  @override
  String get selectTargetInventoryFirst =>
      'Wählen Sie zuerst ein Zielinventar.';
  @override
  String get setDestinationAndTags => 'Ziel und Tags festlegen';

  @override
  String get clear => 'Löschen';
  @override
  String get newInventory => 'Neues Inventar';
  @override
  String searchError(String error) => 'Suchfehler: $error';
  @override
  String noMatchesForQuery(String query) =>
      'Keine Komponente oder kein Inventar entspricht "$query".';
  @override
  String get inventoriesSectionHeader => 'INVENTARE';
  @override
  String get inventoryComponentsSectionHeader => 'INVENTAR-KOMPONENTEN';
  @override
  String get bufferComponentsSectionHeader => 'PUFFER-KOMPONENTEN';
  @override
  String get nameRequired => 'Name *';
  @override
  String get descriptionOptional => 'Beschreibung (optional)';
  @override
  String inventoryCreatedAndSelected(String name) =>
      '"$name" erstellt und ausgewählt';
  @override
  String get renameInventoryTitle => 'Inventar umbenennen';
  @override
  String get renameAction => 'Umbenennen';

  @override
  String get cannotOpenLocalFile =>
      'Lokale Datei kann nicht geöffnet werden';
  @override
  String get renameFileTitle => 'Datei umbenennen';
  @override
  String deleteAttachmentPermanentConfirm(String name) =>
      'Möchten Sie "$name" dauerhaft löschen?';
  @override
  String get searchFileOrComponentPlaceholder =>
      'Datei oder Komponente suchen...';

  @override
  String get deleteComponentConfirmMsg =>
      'Möchten Sie diese Komponente wirklich löschen?';
  @override
  String get loadingTags => 'Tags werden geladen...';
  @override
  String get selectedTagsTitle => 'Ausgewählte Tags';
  @override
  String get treeRoot => 'Anfang';
  @override
  String get noSubtagsAvailable => 'Keine Unter-Tags verfügbar.';
  @override
  String get showGenericLooseTags => 'Generische Tags anzeigen (lose)';
  @override
  String get addLinkTitle => 'Link hinzufügen';
  @override
  String get uploadFileLabel => 'Datei hochladen';
  @override
  String get existingFileLabel => 'Vorhandene Datei';
  @override
  String get noExistingFiles => 'Keine vorhandenen Dateien';
  @override
  String get chooseExistingFile => 'Vorhandene Datei wählen';
  @override
  String get selectFromGallery => 'Aus Galerie auswählen';
  @override
  String get divideDrawerInZones => 'Schublade in Zonen unterteilen';
  @override
  String get divideDrawerSubtitle =>
      'Ermöglicht die Platzierung von bis zu 3 separaten Komponenten in derselben Schublade';
  @override
  String get moveToAnotherInventory => 'In ein anderes Inventar verschieben';
  @override
  String get moveComponentTitle => 'Komponente verschieben';
  @override
  String selectDestinationInventoryFor(String name) =>
      'Wählen Sie das Zielinventar für "$name":';
  @override
  String componentMovedTo(String name) =>
      'Komponente nach "$name" verschoben';
  @override
  String errorDuringMove(String error) =>
      'Fehler beim Verschieben: $error';
  @override
  String get unassignedDrawerShort => 'Nicht\nzug.';
  @override
  String get newComponent => 'Neue Komponente';
  @override
  String get createFromScratchAndInsert =>
      'Neu erstellen und an dieser Position einfügen';
  @override
  String get assignExisting => 'Vorhandene zuweisen';
  @override
  String get assignExistingComponentTitle =>
      'Vorhandene Komponente zuweisen';
  @override
  String get passedToBuffer => 'In den Puffer verschoben';
  @override
  String get editComponentDirectlyFromList =>
      'Bearbeiten Sie die Komponente direkt aus der Liste.';
  @override
  String get searchInAllInventories =>
      'Komponenten in allen Inventaren suchen.';
      @override
  String installedVersion(String version) => 'Installiert: v$version';
  @override
  String newVersion(String version) => 'Neu: v$version';
  @override
  String get downloadManualGithub => 'Sie können das Update manuell von GitHub herunterladen.';
  @override
  String get openOnGithub => 'Auf GitHub öffnen';
  @override
  String fileDownloadedTo(String path) => 'Datei heruntergeladen nach: $path';
  @override
  String downloadError(String error) => 'Download-Fehler: $error';

  @override
  String get noteReminder => 'Notiz (Erinnerung)';
  @override
  String get columnHeader => 'Spalte';
  @override
  String get rowHeader => 'Reihe';
  @override
  String get columnHint => 'Z.B.: A';
  @override
  String get rowHint => 'Z.B.: 3';
  @override
  String get missingColumn => 'Fehlende Spalte';
  @override
  String get missingRow => 'Fehlende Reihe';
  @override
  String get positionTitle => 'Position';
  @override
  String get selectTargetToConfigureTags => 'Wählen Sie ein Zielinventar, um Tags und Eigenschaften festzulegen.';
  @override
  String get freeTextHint => 'Freitext';
  @override
  String get specialTagNumericHint => 'Leer lassen oder K, V, M... verwenden (z.B. 1K2)';
  @override
  String get invalidNumberFormat => 'Ungültiges Zahlenformat';
  @override
  String get invalidNumber => 'Ungültig';
  @override
  String get attachmentsTitle => 'Anhänge';
  @override
  String get linkNameHint => 'Name (z.B. Datenblatt)';
  @override
  String get linkUrlHint => 'URL (https://...)';
  @override
  String get link => 'Link';
  @override
  String get iconBadge => 'Icon';
  @override
  String configureSeparatorsForDrawer(String label, int cabinet) => 'Trennstege konfigurieren für $label (Schrank $cabinet)';
  @override
  String get selectContainerPrompt => 'Behälter auswählen:';
  @override
  String selectedDrawerLabel(String drawer) => 'Ausgewählt: Schublade $drawer';
  @override
  String drawerNumber(String drawer) => 'Schublade $drawer';
  @override
  String containerNumber(int id) => 'Behälter $id';
  @override
  String get noDescription => 'Keine Beschreibung';
  @override
  String qtyShort(int qty) => 'Menge: $qty';
  @override
  String get appUpToDate => 'Die Anwendung ist auf dem neuesten Stand.';
  @override
  String appUpToDateDesc(String version) => 'Die Anwendung ist mit der neuesten Version (v$version) auf dem aktuellen Stand.';
  @override
  String get updateDialogDesc => 'Eine neue Version ist verfügbar. Möchten Sie sie jetzt herunterladen und installieren?';
  @override
  String get updatingTitle => 'Aktualisierung';
@override
  String get dragToScrollGrid => 'Ziehen, um das Raster zu verschieben';
  @override
  String activeDrawersCount(int count) => '$count aktive Schubladen';
  @override
  String mergedDrawers(String drawers) => 'Zusammengeführte Schubladen ($drawers)';
  @override
  String get drawerContent => 'Schubladeninhalt';
  @override
  String get emptyZoneNotice => 'Keine Komponenten in dieser Zone (Leer)';
  @override
  String get chooseFromUnassigned => 'Aus Komponenten ohne Position wählen';
  @override
  String get noUnassignedAvailable => 'Keine Komponenten ohne Position verfügbar';
  @override
  String get searchByName => 'Nach Name suchen...';
  @override
  String componentAssignedSuccess(String name) => 'Komponente "$name" erfolgreich zugewiesen.';
  @override
  String assignError(String error) => 'Fehler bei der Zuweisung: $error';
  @override
  String get addMainTag => 'Haupt-Tag hinzufügen...';
  @override
  String addSubTag(String parent) => 'Hinzufügen in $parent...';
  @override
  String get addComponentTitle => 'Komponente hinzufügen';

  // What's Changed
  @override
  String get whatsNewTitle => 'Was hat sich geändert';
  @override
  String get whatsNewSubtitle => 'Änderungen in Inventaren seit dem letzten Start';
  @override
  String get whatsNewDontShowAgain => 'Dieses Popup beim Start nicht mehr anzeigen';
  @override
  String whatsNewTooltip(int count) => '$count kürzliche Änderungen in Inventaren';
  @override
  String get whatsNewNoChanges => 'Keine kürzlichen Änderungen in Inventaren';
  @override
  String get whatsNewAdded => 'Hinzugefügt';
  @override
  String get whatsNewModified => 'Geändert';
  @override
  String get whatsNewDeleted => 'Gelöscht';
  @override
  String get whatsNewComponentDeletedNotice => 'Diese Komponente wurde aus dem Inventar gelöscht';
  @override
  String whatsNewQuantityChanged(String oldQty, String newQty) => 'Menge: $oldQty → $newQty';
  @override
  String whatsNewDrawerChanged(String oldDrawer, String newDrawer) => 'Schublade: $oldDrawer → $newDrawer';
  @override
  String whatsNewNameChanged(String oldName, String newName) => 'Name: $oldName → $newName';
  @override
  String get whatsNewDescriptionChanged => 'Beschreibung geändert';
  @override
  String get whatsNewTagsChanged => 'Tags geändert';
  @override
  String get whatsNewPropertiesChanged => 'Eigenschaften geändert';
  @override
  String get whatsNewMarkAsRead => 'Als gelesen markieren';
  @override
  String get whatsNewSettingTitle => '"Was hat sich geändert" beim Start anzeigen';
  @override
  String get whatsNewSettingSubtitle => 'Wenn deaktiviert, wird ein Symbol in der oberen Leiste angezeigt';
  @override
  String get whatsNewViewRecentChanges => 'Kürzliche Änderungen anzeigen';
  @override
  String whatsNewChangesCount(int count) => '$count Änderungen';
}
