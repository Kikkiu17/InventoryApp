import 'app_localizations.dart';

class AppLocalizationsIt extends AppLocalizations {
  @override
  String get appName => 'Inventario Componenti';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Annulla';
  @override
  String get save => 'Salva';
  @override
  String get delete => 'Elimina';
  @override
  String get edit => 'Modifica';
  @override
  String get add => 'Aggiungi';
  @override
  String get close => 'Chiudi';
  @override
  String get apply => 'Applica';
  @override
  String get confirm => 'Conferma';
  @override
  String get error => 'Errore';
  @override
  String get warning => 'Attenzione';
  @override
  String get success => 'Operazione riuscita';
  @override
  String get search => 'Cerca';
  @override
  String get loading => 'Caricamento...';
  @override
  String get nameLabel => 'Nome';
  @override
  String get options => 'Opzioni';
  @override
  String get details => 'Dettagli';
  @override
  String get actions => 'Azioni';
  @override
  String get select => 'Seleziona';
  @override
  String get none => 'Nessuno';
  @override
  String get all => 'Tutti';
  @override
  String get yes => 'Sì';
  @override
  String get no => 'No';
  @override
  String get check => 'Verifica';

  // Navigation / Tabs
  @override
  String get tabInventory => 'Inventario';
  @override
  String get tabBuffer => 'Buffer';
  @override
  String get tabInventories => 'Inventari';
  @override
  String get tabFiles => 'File';
  @override
  String get tabSettings => 'Impostazioni';

  // Home Screen
  @override
  String get viewList => 'Lista';
  @override
  String get viewMap => 'Mappa';
  @override
  String get searchPlaceholder => 'Cerca componenti...';
  @override
  String get searchTooltip => 'Cerca';
  @override
  String get sortTitle => 'Ordinamento';
  @override
  String get sortNone => 'Nessun ordinamento';
  @override
  String get sortName => 'Nome';
  @override
  String get sortQuantity => 'Quantità';
  @override
  String get sortDrawer => 'Cassetto';
  @override
  String get sortAscending => 'Ordine: Crescente';
  @override
  String get sortDescending => 'Ordine: Decrescente';
  @override
  String get filterAll => 'Tutti i cassetti';
  @override
  String get filterUnassigned => 'Non assegnati';
  @override
  String get filterCabinet => 'Contenitore';
  @override
  String get clearFilters => 'Azzera filtri';
  @override
  String get filterByTag => 'Filtra per tag';
  @override
  String get filterByProperty => 'Filtra per proprietà';
  @override
  String get exportPdfTooltip => 'Esporta lista in PDF';
  @override
  String get exportPdfTitle => 'Inventario Componenti';
  @override
  String get colName => 'Nome';
  @override
  String get colPosition => 'Posizione';
  @override
  String get colQuantity => 'Qtà';
  @override
  String get colDetails => 'Dettagli';
  @override
  String get unassignedPosition => 'Non ass.';
  @override
  String get exportSuccess => 'PDF esportato con successo';
  @override
  String get exportError => 'Errore esportazione PDF';
  @override
  String get serverConnected => 'Server connesso';
  @override
  String get serverDisconnected => 'Server non connesso';
  @override
  String get switchInventory => 'Cambia';
  @override
  String get selectInventory => 'Seleziona Inventario';
  @override
  String get drawerTitle => 'Cassetto';
  @override
  String get emptyDrawer => 'Nessun componente in questo cassetto';
  @override
  String get addComponentHere => 'Aggiungi componente qui';
  @override
  String get configureDrawer => 'Configura cassetto';
  @override
  String get bulkActions => 'Azioni di gruppo';
  @override
  String get bulkMove => 'Sposta selezionati';
  @override
  String get bulkDelete => 'Elimina selezionati';
  @override
  String get bulkAddTag => 'Aggiungi tag a selezionati';
  @override
  String get bulkRemoveTag => 'Rimuovi tag da selezionati';
  @override
  String get selectedComponents => 'componenti selezionati';
  @override
  String get deleteComponentTitle => 'Elimina componente';
  @override
  String deleteComponentConfirm(String name) =>
      'Sei sicuro di voler eliminare "$name"?';
  @override
  String get noComponentsFound => 'Nessun componente trovato';
  @override
  String errorChangingInventory(String error) =>
      'Errore nel cambio inventario: $error';
  @override
  String errorSaving(String error) => 'Errore nel salvare: $error';
  @override
  String errorDeleting(String error) => 'Errore nell\'eliminare: $error';

  // Buffer Screen
  @override
  String get bufferTitle => 'Buffer';
  @override
  String get searchBufferPlaceholder => 'Cerca nel buffer...';
  @override
  String get allBags => 'Tutti';
  @override
  String get unassignedBag => 'Senza busta';
  @override
  String get addBag => 'Nuova busta';
  @override
  String get deleteBag => 'Elimina busta';
  @override
  String get bagName => 'Nome busta';
  @override
  String get renameBag => 'Rinomina busta';
  @override
  String get emptyBufferTitle => 'Buffer vuoto';
  @override
  String get emptyBufferSubtitle =>
      'I componenti non ancora riposti nei cassetti appariranno qui.';
  @override
  String get moveToDrawer => 'Assegna cassetto';
  @override
  String get addComponentToBuffer => 'Aggiungi al buffer';
  @override
  String get bulkMoveToDrawer => 'Assegna a cassetto';
  @override
  String deleteBagConfirm(String bag) =>
      'Eliminare la busta "$bag"? I componenti rimarranno nel buffer.';
  @override
  String get newBagTitle => 'Nuova Busta';

  // Inventory List Screen
  @override
  String get inventoriesTitle => 'Inventari';
  @override
  String get searchAllInventoriesPlaceholder =>
      'Cerca in tutti gli inventari…';
  @override
  String get localInventory => 'Inventario Locale';
  @override
  String get remoteInventory => 'Remoto';
  @override
  String get currentBadge => 'ATTUALE';
  @override
  String itemsCount(int count) => '$count componenti';
  @override
  String get newInventoryTitle => 'Nuovo Inventario';
  @override
  String get inventoryName => 'Nome inventario';
  @override
  String get create => 'Crea';
  @override
  String get deleteInventoryTitle => 'Elimina inventario';
  @override
  String deleteInventoryConfirm(String name) =>
      'Sei sicuro di voler eliminare l\'inventario "$name"? Questa azione non può essere annullata.';
  @override
  String get syncNow => 'Sincronizza ora';
  @override
  String get syncSuccess => 'Sincronizzazione completata';
  @override
  String get syncError => 'Errore di sincronizzazione';
  @override
  String get restoreBackup => 'Ripristina backup';
  @override
  String get noResults => 'Nessun risultato';
  @override
  String noResultsDescription(String query) =>
      'Nessun componente o inventario corrisponde a "$query".';
  @override
  String get bufferComponentsCategory => 'COMPONENTI BUFFER';

  // Files Screen
  @override
  String get filesTitle => 'File e Allegati';
  @override
  String get searchFilesPlaceholder => 'Cerca file...';
  @override
  String get allFiles => 'Tutti i file';
  @override
  String get componentFiles => 'File componenti';
  @override
  String get noFiles => 'Nessun file presente';
  @override
  String get shareFile => 'Condividi';
  @override
  String get deleteFile => 'Elimina file';
  @override
  String deleteFileConfirm(String fileName) =>
      'Sei sicuro di voler eliminare "$fileName"?';
  @override
  String get fileSize => 'Dimensione';
  @override
  String get openFileError => 'Impossibile aprire il file';

  // Settings Screen
  @override
  String get settingsTitle => 'Impostazioni';
  @override
  String get saveSettings => 'Salva';
  @override
  String get sectionRemoteServer => 'Server remoto';
  @override
  String get sectionAppearance => 'Aspetto';
  @override
  String get sectionLanguage => 'Lingua';
  @override
  String get sectionContainers => 'Configurazione contenitori (cassetti)';
  @override
  String get sectionTagTree => 'Albero dei Tag';
  @override
  String get sectionGenericTags => 'Tag Generici (Sfusi)';
  @override
  String get sectionProperties => 'Proprietà con valore';
  @override
  String get sectionData => 'Dati';
  @override
  String get sectionAbout => 'Informazioni e aggiornamenti';
  @override
  String get useRemoteServer => 'Usa server remoto';
  @override
  String get serverConnectedStatus => '✅ Connesso';
  @override
  String get serverDisconnectedStatus => '❌ Non connesso';
  @override
  String get localStorageStatus => 'Archiviazione locale';
  @override
  String get serverUrl => 'Indirizzo server';
  @override
  String get testConnection => 'Test connessione';
  @override
  String get connectionSuccess => 'Connessione stabilita con successo!';
  @override
  String get connectionFailed => 'Impossibile connettersi al server';
  @override
  String get themeMode => 'Tema dell\'app';
  @override
  String get themeSystem => 'Sistema';
  @override
  String get themeLight => 'Chiaro';
  @override
  String get themeDark => 'Scuro';
  @override
  String get languageLabel => 'Lingua dell\'app';
  @override
  String get languageSystem => 'Predefinita di sistema';
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
      'Gestisci i contenitori fisici. Ciascun contenitore può avere dimensioni personalizzate e forme ritagliate disattivando cassetti nell\'anteprima.';
  @override
  String get newContainer => 'Aggiungi contenitore';
  @override
  String get containerName => 'Nome contenitore';
  @override
  String get rows => 'Righe';
  @override
  String get columns => 'Colonne';
  @override
  String get invertRows => 'Inverti numerazione righe (dal basso in alto)';
  @override
  String get invertColumns => 'Inverti colonne (da destra a sinistra)';
  @override
  String get previewAndShape => 'Anteprima e forma';
  @override
  String get drawerGridHint =>
      'Anteprima (clicca per configurare, premi a lungo e trascina per selezionare in blocco)';
  @override
  String get deleteContainer => 'Elimina contenitore';
  @override
  String get drawerConfigTitle => 'Configurazione cassetto';
  @override
  String get drawerDisabled => 'Cassetto disattivato';
  @override
  String get drawerZones => 'Zone / Divisori';
  @override
  String get mergeDrawers => 'Unisci cassetti';
  @override
  String get splitDrawers => 'Separa cassetti';
  @override
  String get tagTreeDesc =>
      'Crea categorie e sottocategorie digitando nel campo apposito e premendo invio.';
  @override
  String get genericTagsDesc =>
      'Tag generici senza gerarchia utilizzabili per etichettare rapidamente i componenti.';
  @override
  String get newGenericTag => 'Nuovo tag generico';
  @override
  String get addTag => 'Aggiungi';
  @override
  String deleteTagConfirm(String tag) => 'Eliminare il tag "$tag"?';
  @override
  String get propertiesDesc =>
      'Definisci proprietà numeriche o stringhe. Trascina per riordinarle.';
  @override
  String get propName => 'Nome';
  @override
  String get propUnit => 'Unità';
  @override
  String get propSigla => 'Sigla';
  @override
  String get propSiglaHint => 'es. L';
  @override
  String get propText => 'Testo';
  @override
  String get addProp => 'Aggiungi';
  @override
  String get noPropsConfigured => 'Nessuna proprietà configurata.';
  @override
  String get editPropTitle => 'Modifica proprietà';
  @override
  String get propUnitLabel => 'Unità';
  @override
  String get propTextFree => 'Testo libero';
  @override
  String deletePropConfirm(String name) => 'Eliminare la proprietà "$name"?';
  @override
  String get dataBackupDesc => 'Gestione backup ed esportazione';
  @override
  String get exportJson => 'Esporta backup locale (JSON)';
  @override
  String get importJson => 'Ripristina da file JSON';
  @override
  String get restoreRemoteBackup => 'Ripristina backup remoto';
  @override
  String get backupCreated => 'Backup creato con successo';
  @override
  String get checkUpdates => 'Controlla aggiornamenti';
  @override
  String get checkUpdatesSubtitle =>
      'Verifica e scarica l\'ultima versione da GitHub';
  @override
  String get openGitHub => 'Apri pagina GitHub';
  @override
  String get appVersion => 'Versione app';
  @override
  String get manualDrawerConfigTitle =>
      'Configura cassetto per coordinate (per cassetti non visibili nell\'anteprima)';
  @override
  String get manualDrawerCode => 'Codice cassetto';
  @override
  String get manualDrawerHint => 'Es: A20 o K4';
  @override
  String get configureButton => 'Configura';
  @override
  String get noGenericTags => 'Nessun tag generico.';
  @override
  String get settingsSaved => 'Impostazioni salvate';
  @override
  String get activeInventory => 'Inventario attivo';
  @override
  String get enableAll => 'Attiva tutti';
  @override
  String get disableAll => 'Disattiva tutti';
  @override
  String get enabled => 'Abilitato';
  @override
  String get divideIntoZones => 'Dividi in zone';
  @override
  String get restoreBackupTitle => 'Ripristina backup';
  @override
  String get confirmRestoreTitle => 'Conferma ripristino';
  @override
  String get confirmRestoreMsg =>
      'Sovrascrivere i dati attuali? (Verrà creato un backup di sicurezza automatico prima di procedere).';
  @override
  String get restoreSuccess => 'Backup ripristinato con successo';
  @override
  String get noBackupsFound => 'Nessun backup trovato';
  @override
  String bulkDrawerAction(int count) => 'Azione di gruppo ($count cassetti)';
  @override
  String get bulkDrawerActionDesc =>
      'Cosa vuoi fare con i cassetti selezionati?\nPuoi disattivarli, riattivarli, impostare le zone o unire/dividere i cassetti selezionati.';
  @override
  String get setZones => 'Imposta zone...';
  @override
  String zonesCount(int count) => '$count zone';
  @override
  String get noDividers => 'Nessun divisore (1 zona)';
  @override
  String get filterRemoveAll => 'Rimuovi tutti';
  @override
  String get filterOnlyUnassigned => 'Mostra solo componenti senza posizione';
  @override
  String get filterOnlyUnassignedDesc =>
      'Nasconde i componenti a cui è già stato assegnato un cassetto';
  @override
  String get quickTags => 'Tag rapidi';
  @override
  String get cabinetContainer => 'Contenitore / Cassettiera';
  @override
  String get navigateTagTree => 'Naviga nei tag';
  @override
  String get tagTreeRoot => 'Inizio';
  @override
  String get noSubtags => 'Nessun sottotag disponibile.';
  @override
  String get propertyFilters => 'Filtri per Proprietà';
  @override
  String get containsText => 'Contiene testo...';
  @override
  String get exactValue => 'Valore esatto';
  @override
  String get fromMin => 'Da (min)';
  @override
  String get toMax => 'A (max)';
  @override
  String get applyFilters => 'Applica filtri';
  @override
  String get selectedTagsLabel => 'Tag selezionati';
  @override
  String get invalidDrawerCoords =>
      'Coordinate cassetto non valide per le dimensioni attuali della cassettiera';
  @override
  String get moveAction => 'Sposta';
  @override
  String get selectTargetInventory =>
      'Seleziona l\'inventario di destinazione';
  @override
  String componentMovedSuccess(String targetName) =>
      'Componente spostato in "$targetName"';
  @override
  String get errorMovingComponent => 'Errore durante lo spostamento';
  @override
  String get addAttachmentLink => 'Link';
  @override
  String get addAttachmentFile => 'Carica File';
  @override
  String get addAttachmentExisting => 'File Esistente';
  @override
  String get takePhotoNow => 'Scatta Foto Ora';
  @override
  String get chooseFromGallery => 'Seleziona dalla Galleria';
  @override
  String get addPhoto => 'Aggiungi Foto';
  @override
  String get renameFile => 'Rinomina file';
  @override
  String get filesFound => 'file trovati';
  @override
  String get fileOptions => 'Opzioni';
  @override
  String get rename => 'Rinomina';
  @override
  String get notAssigned => 'Non assegnato';
  @override
  String get selectFromMap => 'Seleziona da mappa';
  @override
  String changeDrawerSeparators(int zones) =>
      'Modifica separatori ($zones zone)';
  @override
  String get configureDrawerSeparators =>
      'Configura separatori (cassetto normale)';
  @override
  String get zoneSeparatorLabel => 'Zona del cassetto (Separatore)';

  // Component Dialog
  @override
  String get newComponentTitle => 'Nuovo Componente';
  @override
  String get editComponentTitle => 'Modifica Componente';
  @override
  String get duplicateComponentTitle => 'Duplica Componente';
  @override
  String get compNameLabel => 'Nome';
  @override
  String get compNameError => 'Inserisci un nome';
  @override
  String get compDescLabel => 'Descrizione o note';
  @override
  String get compQtyLabel => 'Quantità';
  @override
  String get compCabinetLabel => 'Contenitore';
  @override
  String get compDrawerLabel => 'Cassetto';
  @override
  String get compZoneLabel => 'Zona cassetto';
  @override
  String get tagsSectionTitle => 'Tag e Categorie';
  @override
  String get selectTreeTags => 'Albero dei tag';
  @override
  String get selectGenericTags => 'Tag generici';
  @override
  String get showGenericTags => 'Mostra tag generici (sfusi)';
  @override
  String get hideGenericTags => 'Nascondi tag generici';
  @override
  String get propertiesSectionTitle => 'Proprietà';
  @override
  String get addCustomProperty => 'Aggiungi proprietà';
  @override
  String get imagesSectionTitle => 'Immagini e Allegati';
  @override
  String get addImage => 'Aggiungi immagine';
  @override
  String get camera => 'Fotocamera';
  @override
  String get gallery => 'Galleria';
  @override
  String get removeImage => 'Rimuovi';
  @override
  String get keepInBuffer => 'Mantieni nel buffer';
  @override
  String get assignToDrawer => 'Assegna cassetto';
  @override
  String get saveButton => 'Salva';
  @override
  String get cancelButton => 'Annulla';
  @override
  String get deleteButton => 'Elimina';
  @override
  String get draftSaved => 'Bozza salvata';
  @override
  String get draftRestored => 'Bozza ripristinata';

  // Component View Dialog
  @override
  String get componentDetailsTitle => 'Dettagli Componente';
  @override
  String get quantityLabel => 'Quantità:';
  @override
  String get locationLabel => 'Posizione:';
  @override
  String get drawerLabel => 'Cassetto:';
  @override
  String get cabinetLabel => 'Contenitore:';
  @override
  String get zoneLabel => 'Zona:';
  @override
  String get tagsLabel => 'Tag:';
  @override
  String get propertiesLabel => 'Proprietà:';
  @override
  String get notesLabel => 'Note:';
  @override
  String get attachedFilesLabel => 'Allegati:';
  @override
  String get editAction => 'Modifica';
  @override
  String get duplicateAction => 'Duplica';
  @override
  String get moveToBufferAction => 'Sposta nel buffer';
  @override
  String get printLabelAction => 'Stampa etichetta';
  @override
  String get deleteAction => 'Elimina';
  @override
  String confirmDeleteMsg(String name) =>
      'Sei sicuro di voler eliminare "$name"?';

  // Drawer Picker Dialog
  @override
  String get selectDrawerTitle => 'Seleziona Cassetto';
  @override
  String get searchDrawerPlaceholder => 'Filtra cassetto...';
  @override
  String get selectZone => 'Zona:';
  @override
  String cabinetTab(int id, String name) =>
      name.isNotEmpty ? name : 'Contenitore $id';

  // Update Service
  @override
  String get updateAvailableTitle => 'Aggiornamento disponibile';
  @override
  String updateAvailableDesc(String version) =>
      'È disponibile una nuova versione ($version). Vuoi scaricarla ora?';
  @override
  String get updateNowButton => 'Aggiorna ora';
  @override
  String get laterButton => 'Più tardi';
  @override
  String get dontShowAgain => 'Non mostrare più all\'avvio';
  @override
  String get releaseNotes => 'Note di rilascio';
  @override
  String get downloadingUpdate => 'Download dell\'aggiornamento...';
  @override
  String get installUpdate => 'Installa aggiornamento';
  @override
  String get updateError => 'Errore durante l\'aggiornamento';
  @override
  String get noUpdateAvailable => 'L\'app è già aggiornata all\'ultima versione.';

  // Conflicts
  @override
  String get conflictTitle => 'Conflitto di sincronizzazione';
  @override
  String get conflictDesc =>
      'I dati remoti sono stati modificati dopo l\'ultima sincronizzazione locale. Scegli quale versione mantenere.';
  @override
  String get useLocal => 'Mantieni locale';
  @override
  String get useRemote => 'Mantieni remoto';
  @override
  String get compare => 'Confronta';

  @override
  String get selectCabinetLabel => 'Seleziona contenitore:';
  @override
  String get tapDrawerToSelect => 'Tocca un cassetto per selezionarlo';
  @override
  String drawerSelected(String label, [int? zone]) =>
      'Selezionato: Cassetto $label${zone != null ? " (Zona $zone)" : ""}';
  @override
  String get noContainersConfigured =>
      'Nessun contenitore configurato nelle impostazioni.';
  @override
  String get offlineUsingLocal => 'Offline · usando dati locali';
  @override
  String get switchButton => 'Cambia';
  @override
  String get sync => 'Sincronizza';
  @override
  String get sortBy => 'Per';
  @override
  String resultsCount(int count) => '$count risultati';
  @override
  String componentsCount(int count) => '$count componenti';
  @override
  String updateAvailableBadge(String version) =>
      'Aggiornamento disponibile (v$version)';
  @override
  String get updateAvailableQuestion =>
      'È disponibile una nuova versione. Vuoi scaricarla e installarla adesso?';
  @override
  String get positionLabel => 'Posizione';
  @override
  String get targetInventoryLabel => 'Inventario di destinazione';
  @override
  String get noneToSelect => 'Nessuno (Da selezionare)';
  @override
  String get rowLabel => 'Riga';
  @override
  String get columnLabel => 'Colonna';
  @override
  String get requiredField => 'Obbligatorio';
  @override
  String get disabledDrawer => 'Disattivato';
  @override
  String get savePosition => 'Salva Posizione';
  @override
  String get placeAction => 'Posiziona';
  @override
  String placeComponentSuccess(String name) =>
      '"$name" posizionato con successo!';
  @override
  String get cannotOpenLink => 'Impossibile aprire il link';
  @override
  String get cannotOpenFile => 'Impossibile aprire il file';
  @override
  String get refreshList => 'Aggiorna lista';
  @override
  String get localModeTitle => 'Modalità locale';
  @override
  String get localModeDesc =>
      'Attiva il server remoto nelle Impostazioni per gestire più inventari.';
  @override
  String get serverUnreachableTitle => 'Server non raggiungibile';
  @override
  String get serverUnreachableDesc =>
      'Controlla la connessione e l\'indirizzo del server.';
  @override
  String get retry => 'Riprova';
  @override
  String get noInventoriesTitle => 'Nessun inventario';
  @override
  String get noInventoriesDesc => 'Crea il primo inventario per iniziare.';
  @override
  String get createInventory => 'Crea inventario';
  @override
  String get inventoryAlreadyActive => 'Inventario già attivo';
  @override
  String switchedToInventory(String name) => 'Passato a "$name"';
  @override
  String get deleteInventoryPermanentWarning =>
      'Tutti i componenti verranno eliminati definitivamente.';
  @override
  String get activeBadge => 'Attivo';
  @override
  String get uploadedFilesTitle => 'File Caricati';
  @override
  String filesFoundCount(int count) => '$count file trovati';
  @override
  String get noFilesFound => 'Nessun file trovato';
  @override
  String get searchFilesPlaceholderLong => 'Cerca file o componente...';
  @override
  String deleteAttachmentConfirm(String name) =>
      'Vuoi eliminare definitivamente "$name"?';
  @override
  String get deleteImageTitle => 'Elimina immagine';
  @override
  String get deleteFileTitle => 'Elimina file';
  @override
  String get componentPrefix => 'Componente';

  @override
  String get zoneNearLabel => 'Vicina (davanti)';
  @override
  String get zoneFarLabel => 'Lontana (retro)';
  @override
  String get zoneMiddleLabel => 'In mezzo';
  @override
  String zoneMiddleIndex(int index) => 'In mezzo ($index)';

  @override
  String deleteBufferComponentConfirm(String name) =>
      'Sei sicuro di voler eliminare "$name" dal buffer?';
  @override
  String assignedDestination(String target) => 'Destinazione assegnata: $target';
  @override
  String get destinationUnspecified => 'Destinazione non specificata';
  @override
  String get noDestination => 'Senza destinazione';
  @override
  String get emptyBufferDesc =>
      'Aggiungi i componenti per registrarli temporaneamente prima di posizionarli.';
  @override
  String get noBufferResultsDesc =>
      'Nessun componente nel buffer corrisponde alla tua ricerca.';
  @override
  String placeItemDialogTitle(String name) => 'Posiziona "$name"';
  @override
  String get placeItemDialogDesc =>
      'Specifica la posizione fisica per spostare il componente dal buffer all\'inventario.';
  @override
  String destinationLabel(String target) => 'Destinazione: $target';
  @override
  String get changeDestinationAndTags => 'Cambia destinazione (e tag)';
  @override
  String maxColumnLabel(String col) => 'Max colonna: $col';
  @override
  String maxRowLabel(int row) => 'Max riga: $row';
  @override
  String get drawerZoneSeparator => 'Zona del cassetto (Separatore)';
  @override
  String get selectTargetInventoryFirst =>
      'Seleziona prima un inventario di destinazione.';
  @override
  String get setDestinationAndTags => 'Imposta destinazione e tag';

  @override
  String get clear => 'Cancella';
  @override
  String get newInventory => 'Nuovo inventario';
  @override
  String searchError(String error) => 'Errore durante la ricerca: $error';
  @override
  String noMatchesForQuery(String query) =>
      'Nessun componente o inventario corrisponde a "$query".';
  @override
  String get inventoriesSectionHeader => 'INVENTARI';
  @override
  String get inventoryComponentsSectionHeader => 'COMPONENTI INVENTARI';
  @override
  String get bufferComponentsSectionHeader => 'COMPONENTI BUFFER';
  @override
  String get nameRequired => 'Nome *';
  @override
  String get descriptionOptional => 'Descrizione (opzionale)';
  @override
  String inventoryCreatedAndSelected(String name) =>
      '"$name" creato e selezionato';
  @override
  String get renameInventoryTitle => 'Rinomina inventario';
  @override
  String get renameAction => 'Rinomina';

  @override
  String get cannotOpenLocalFile => 'Impossibile aprire il file locale';
  @override
  String get renameFileTitle => 'Rinomina file';
  @override
  String deleteAttachmentPermanentConfirm(String name) =>
      'Vuoi eliminare definitivamente "$name"?';
  @override
  String get searchFileOrComponentPlaceholder => 'Cerca file o componente...';

  @override
  String get deleteComponentConfirmMsg =>
      'Vuoi davvero eliminare questo componente?';
  @override
  String get loadingTags => 'Caricamento tag...';
  @override
  String get selectedTagsTitle => 'Tag selezionati';
  @override
  String get treeRoot => 'Inizio';
  @override
  String get noSubtagsAvailable => 'Nessun sottotag disponibile.';
  @override
  String get showGenericLooseTags => 'Mostra tag generici (sfusi)';
  @override
  String get addLinkTitle => 'Aggiungi Link';
  @override
  String get uploadFileLabel => 'Carica File';
  @override
  String get existingFileLabel => 'File Esistente';
  @override
  String get noExistingFiles => 'Nessun file esistente';
  @override
  String get chooseExistingFile => 'Scegli file esistente';
  @override
  String get selectFromGallery => 'Seleziona dalla Galleria';
  @override
  String get divideDrawerInZones => 'Dividi cassetto in zone';
  @override
  String get divideDrawerSubtitle =>
      'Consente di posizionare fino a 3 componenti separati nello stesso cassetto';
  @override
  String get moveToAnotherInventory => 'Sposta in un altro inventario';
  @override
  String get moveComponentTitle => 'Sposta componente';
  @override
  String selectDestinationInventoryFor(String name) =>
      'Seleziona l\'inventario di destinazione per "$name":';
  @override
  String componentMovedTo(String name) => 'Componente spostato in "$name"';
  @override
  String errorDuringMove(String error) => 'Errore durante lo spostamento: $error';
  @override
  String get unassignedDrawerShort => 'Non\nass.';
  @override
  String get newComponent => 'Nuovo componente';
  @override
  String get createFromScratchAndInsert =>
      'Crea da zero ed inserisci in questa posizione';
  @override
  String get assignExisting => 'Assegna esistente';
  @override
  String get assignExistingComponentTitle => 'Assegna componente esistente';
  @override
  String get passedToBuffer => 'Passato al Buffer';
  @override
  String get editComponentDirectlyFromList =>
      'Modifica il componente direttamente dalla lista.';
  @override
  String get searchInAllInventories =>
      'Cerca componenti in tutti gli inventari.';
      @override
  String installedVersion(String version) => 'Installata: v$version';
  @override
  String newVersion(String version) => 'Nuova: v$version';
  @override
  String get downloadManualGithub => "Puoi scaricare l'aggiornamento manualmente da GitHub.";
  @override
  String get openOnGithub => 'Apri su GitHub';
  @override
  String fileDownloadedTo(String path) => 'File scaricato in: $path';
  @override
  String downloadError(String error) => 'Errore durante il download: $error';

  @override
  String get noteReminder => 'Nota (promemoria)';
  @override
  String get columnHeader => 'Colonna';
  @override
  String get rowHeader => 'Riga';
  @override
  String get columnHint => 'Es: A';
  @override
  String get rowHint => 'Es: 3';
  @override
  String get missingColumn => 'Manca colonna';
  @override
  String get missingRow => 'Manca riga';
  @override
  String get positionTitle => 'Posizione';
  @override
  String get selectTargetToConfigureTags => 'Seleziona un inventario di destinazione per impostare tag e proprietà.';
  @override
  String get freeTextHint => 'Testo libero';
  @override
  String get specialTagNumericHint => 'Lascia vuoto o usa K, V, M... (es. 1K2)';
  @override
  String get invalidNumberFormat => 'Formato numerico non valido';
  @override
  String get invalidNumber => 'Non valido';
  @override
  String get attachmentsTitle => 'Allegati';
  @override
  String get linkNameHint => 'Nome (es. Datasheet)';
  @override
  String get linkUrlHint => 'URL (https://...)';
  @override
  String get link => 'Link';
  @override
  String get iconBadge => 'Icona';
  @override
  String configureSeparatorsForDrawer(String label, int cabinet) => 'Configura separatori per $label (Cassettiera $cabinet)';
  @override
  String get selectContainerPrompt => 'Seleziona contenitore:';
  @override
  String selectedDrawerLabel(String drawer) => 'Selezionato: Cassetto $drawer';
  @override
  String drawerNumber(String drawer) => 'Cassetto $drawer';
  @override
  String containerNumber(int id) => 'Contenitore $id';
  @override
  String get noDescription => 'Nessuna descrizione';
  @override
  String qtyShort(int qty) => 'Q.tà: $qty';
  @override
  String get appUpToDate => "L'applicazione è aggiornata all'ultima versione.";
  @override
  String appUpToDateDesc(String version) => "L'applicazione è aggiornata all'ultima versione (v$version).";
  @override
  String get updateDialogDesc => 'È disponibile una nuova versione. Vuoi scaricarla e installarla adesso?';
  @override
  String get updatingTitle => 'Aggiornamento';
@override
  String get dragToScrollGrid => 'Usa il trascinamento per scorrere la griglia';
  @override
  String activeDrawersCount(int count) => '$count cassetti attivi';
  @override
  String mergedDrawers(String drawers) => 'Cassetti Uniti ($drawers)';
  @override
  String get drawerContent => 'Contenuto cassetto';
  @override
  String get emptyZoneNotice => 'Nessun componente in questa zona (Vuota)';
  @override
  String get chooseFromUnassigned => 'Scegli tra i componenti senza posizione';
  @override
  String get noUnassignedAvailable => 'Nessun componente senza posizione disponibile';
  @override
  String get searchByName => 'Cerca per nome...';
  @override
  String componentAssignedSuccess(String name) => 'Componente "$name" assegnato con successo.';
  @override
  String assignError(String error) => 'Errore durante l\'assegnazione: $error';
  @override
  String get addMainTag => 'Aggiungi principale...';
  @override
  String addSubTag(String parent) => 'Aggiungi in $parent...';
  @override
  String get addComponentTitle => 'Aggiungi componente';
}
