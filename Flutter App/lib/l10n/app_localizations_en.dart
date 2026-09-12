import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appName => 'Component Inventory';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get add => 'Add';
  @override
  String get close => 'Close';
  @override
  String get apply => 'Apply';
  @override
  String get confirm => 'Confirm';
  @override
  String get error => 'Error';
  @override
  String get warning => 'Warning';
  @override
  String get success => 'Success';
  @override
  String get search => 'Search';
  @override
  String get loading => 'Loading...';
  @override
  String get nameLabel => 'Name';
  @override
  String get options => 'Options';
  @override
  String get details => 'Details';
  @override
  String get actions => 'Actions';
  @override
  String get select => 'Select';
  @override
  String get none => 'None';
  @override
  String get all => 'All';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get check => 'Check';

  // Navigation / Tabs
  @override
  String get tabInventory => 'Inventory';
  @override
  String get tabBuffer => 'Buffer';
  @override
  String get tabInventories => 'Inventories';
  @override
  String get tabFiles => 'Files';
  @override
  String get tabSettings => 'Settings';

  // Home Screen
  @override
  String get viewList => 'List';
  @override
  String get viewMap => 'Map';
  @override
  String get searchPlaceholder => 'Search components...';
  @override
  String get searchTooltip => 'Search';
  @override
  String get sortTitle => 'Sort by';
  @override
  String get sortNone => 'No sorting';
  @override
  String get sortName => 'Name';
  @override
  String get sortQuantity => 'Quantity';
  @override
  String get sortDrawer => 'Drawer';
  @override
  String get sortAscending => 'Order: Ascending';
  @override
  String get sortDescending => 'Order: Descending';
  @override
  String get filterAll => 'All drawers';
  @override
  String get filterUnassigned => 'Unassigned';
  @override
  String get filterCabinet => 'Cabinet';
  @override
  String get clearFilters => 'Clear filters';
  @override
  String get filterByTag => 'Filter by tag';
  @override
  String get filterByProperty => 'Filter by property';
  @override
  String get exportPdfTooltip => 'Export list to PDF';
  @override
  String get exportPdfTitle => 'Component Inventory';
  @override
  String get colName => 'Name';
  @override
  String get colPosition => 'Position';
  @override
  String get colQuantity => 'Qty';
  @override
  String get colDetails => 'Details';
  @override
  String get unassignedPosition => 'Unassigned';
  @override
  String get exportSuccess => 'PDF exported successfully';
  @override
  String get exportError => 'PDF export error';
  @override
  String get serverConnected => 'Server connected';
  @override
  String get serverDisconnected => 'Server disconnected';
  @override
  String get switchInventory => 'Switch';
  @override
  String get selectInventory => 'Select Inventory';
  @override
  String get drawerTitle => 'Drawer';
  @override
  String get emptyDrawer => 'No components in this drawer';
  @override
  String get addComponentHere => 'Add component here';
  @override
  String get configureDrawer => 'Configure drawer';
  @override
  String get bulkActions => 'Bulk actions';
  @override
  String get bulkMove => 'Move selected';
  @override
  String get bulkDelete => 'Delete selected';
  @override
  String get bulkAddTag => 'Add tag to selected';
  @override
  String get bulkRemoveTag => 'Remove tag from selected';
  @override
  String get selectedComponents => 'selected components';
  @override
  String get deleteComponentTitle => 'Delete component';
  @override
  String deleteComponentConfirm(String name) =>
      'Are you sure you want to delete "$name"?';
  @override
  String get noComponentsFound => 'No components found';
  @override
  String errorChangingInventory(String error) =>
      'Error switching inventory: $error';
  @override
  String errorSaving(String error) => 'Error saving: $error';
  @override
  String errorDeleting(String error) => 'Error deleting: $error';

  // Buffer Screen
  @override
  String get bufferTitle => 'Buffer';
  @override
  String get searchBufferPlaceholder => 'Search in buffer...';
  @override
  String get allBags => 'All';
  @override
  String get unassignedBag => 'No bag';
  @override
  String get addBag => 'New bag';
  @override
  String get deleteBag => 'Delete bag';
  @override
  String get bagName => 'Bag name';
  @override
  String get renameBag => 'Rename bag';
  @override
  String get emptyBufferTitle => 'Buffer is empty';
  @override
  String get emptyBufferSubtitle =>
      'Components not yet stored in drawers will appear here.';
  @override
  String get moveToDrawer => 'Assign drawer';
  @override
  String get addComponentToBuffer => 'Add to buffer';
  @override
  String get bulkMoveToDrawer => 'Assign to drawer';
  @override
  String deleteBagConfirm(String bag) =>
      'Delete bag "$bag"? Components will remain in the buffer.';
  @override
  String get newBagTitle => 'New Bag';

  // Inventory List Screen
  @override
  String get inventoriesTitle => 'Inventories';
  @override
  String get searchAllInventoriesPlaceholder => 'Search all inventories…';
  @override
  String get localInventory => 'Local Inventory';
  @override
  String get remoteInventory => 'Remote';
  @override
  String get currentBadge => 'CURRENT';
  @override
  String itemsCount(int count) => '$count components';
  @override
  String get newInventoryTitle => 'New Inventory';
  @override
  String get inventoryName => 'Inventory name';
  @override
  String get create => 'Create';
  @override
  String get deleteInventoryTitle => 'Delete inventory';
  @override
  String deleteInventoryConfirm(String name) =>
      'Are you sure you want to delete inventory "$name"? This action cannot be undone.';
  @override
  String get syncNow => 'Sync now';
  @override
  String get syncSuccess => 'Sync completed';
  @override
  String get syncError => 'Sync error';
  @override
  String get restoreBackup => 'Restore backup';
  @override
  String get noResults => 'No results';
  @override
  String noResultsDescription(String query) =>
      'No component or inventory matches "$query".';
  @override
  String get bufferComponentsCategory => 'BUFFER COMPONENTS';

  // Files Screen
  @override
  String get filesTitle => 'Files & Attachments';
  @override
  String get searchFilesPlaceholder => 'Search files...';
  @override
  String get allFiles => 'All files';
  @override
  String get componentFiles => 'Component files';
  @override
  String get noFiles => 'No files found';
  @override
  String get shareFile => 'Share';
  @override
  String get deleteFile => 'Delete file';
  @override
  String deleteFileConfirm(String fileName) =>
      'Are you sure you want to delete "$fileName"?';
  @override
  String get fileSize => 'Size';
  @override
  String get openFileError => 'Unable to open file';

  // Settings Screen
  @override
  String get settingsTitle => 'Settings';
  @override
  String get saveSettings => 'Save';
  @override
  String get sectionRemoteServer => 'Remote Server';
  @override
  String get sectionAppearance => 'Appearance';
  @override
  String get sectionLanguage => 'Language';
  @override
  String get sectionContainers => 'Container configuration (drawers)';
  @override
  String get sectionTagTree => 'Tag Tree';
  @override
  String get sectionGenericTags => 'Generic Tags';
  @override
  String get sectionProperties => 'Properties with value';
  @override
  String get sectionData => 'Data';
  @override
  String get sectionAbout => 'About & Updates';
  @override
  String get useRemoteServer => 'Use remote server';
  @override
  String get serverConnectedStatus => '✅ Connected';
  @override
  String get serverDisconnectedStatus => '❌ Not connected';
  @override
  String get localStorageStatus => 'Local storage';
  @override
  String get serverUrl => 'Server URL';
  @override
  String get testConnection => 'Test connection';
  @override
  String get connectionSuccess => 'Connected successfully!';
  @override
  String get connectionFailed => 'Could not connect to server';
  @override
  String get themeMode => 'App theme';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get languageLabel => 'App language';
  @override
  String get languageSystem => 'System default';
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
      'Manage physical containers. Each container can have custom dimensions and shapes by disabling drawers in the preview.';
  @override
  String get newContainer => 'Add container';
  @override
  String get containerName => 'Container name';
  @override
  String get rows => 'Rows';
  @override
  String get columns => 'Columns';
  @override
  String get invertRows => 'Invert row numbers (bottom to top)';
  @override
  String get invertColumns => 'Invert columns (right to left)';
  @override
  String get previewAndShape => 'Preview & shape';
  @override
  String get drawerGridHint =>
      'Preview (click to configure, long press and drag for bulk selection)';
  @override
  String get deleteContainer => 'Delete container';
  @override
  String get drawerConfigTitle => 'Drawer configuration';
  @override
  String get drawerDisabled => 'Drawer disabled';
  @override
  String get drawerZones => 'Zones / Dividers';
  @override
  String get mergeDrawers => 'Merge drawers';
  @override
  String get splitDrawers => 'Split drawers';
  @override
  String get tagTreeDesc =>
      'Create categories and subcategories by typing in the field and pressing Enter.';
  @override
  String get genericTagsDesc =>
      'Generic tags without hierarchy for quick labeling of components.';
  @override
  String get newGenericTag => 'New generic tag';
  @override
  String get addTag => 'Add';
  @override
  String deleteTagConfirm(String tag) => 'Delete tag "$tag"?';
  @override
  String get propertiesDesc =>
      'Define numeric or string properties. Drag to reorder them.';
  @override
  String get propName => 'Name';
  @override
  String get propUnit => 'Unit';
  @override
  String get propSigla => 'Sigla';
  @override
  String get propSiglaHint => 'e.g. L';
  @override
  String get propText => 'Text';
  @override
  String get addProp => 'Add';
  @override
  String get noPropsConfigured => 'No properties configured.';
  @override
  String get editPropTitle => 'Edit property';
  @override
  String get propUnitLabel => 'Unit';
  @override
  String get propTextFree => 'Free text';
  @override
  String deletePropConfirm(String name) => 'Delete property "$name"?';
  @override
  String get dataBackupDesc => 'Backup & export management';
  @override
  String get exportJson => 'Export local backup (JSON)';
  @override
  String get importJson => 'Restore from JSON file';
  @override
  String get restoreRemoteBackup => 'Restore remote backup';
  @override
  String get backupCreated => 'Backup created successfully';
  @override
  String get checkUpdates => 'Check for updates';
  @override
  String get checkUpdatesSubtitle => 'Check and download latest version from GitHub';
  @override
  String get openGitHub => 'Open GitHub page';
  @override
  String get appVersion => 'App version';
  @override
  String get manualDrawerConfigTitle =>
      'Configure drawer by coordinates (for drawers not visible in preview)';
  @override
  String get manualDrawerCode => 'Drawer code';
  @override
  String get manualDrawerHint => 'e.g. A20 or K4';
  @override
  String get configureButton => 'Configure';
  @override
  String get noGenericTags => 'No generic tags.';
  @override
  String get settingsSaved => 'Settings saved';
  @override
  String get activeInventory => 'Active inventory';
  @override
  String get enableAll => 'Enable all';
  @override
  String get disableAll => 'Disable all';
  @override
  String get enabled => 'Enabled';
  @override
  String get divideIntoZones => 'Divide into zones';
  @override
  String get restoreBackupTitle => 'Restore backup';
  @override
  String get confirmRestoreTitle => 'Confirm restore';
  @override
  String get confirmRestoreMsg =>
      'Overwrite current data? (An automatic safety backup will be created first).';
  @override
  String get restoreSuccess => 'Backup restored successfully';
  @override
  String get noBackupsFound => 'No backups found';
  @override
  String bulkDrawerAction(int count) => 'Bulk action ($count drawers)';
  @override
  String get bulkDrawerActionDesc =>
      'What do you want to do with the selected drawers?\nYou can disable, enable, set zones, or merge/split them.';
  @override
  String get setZones => 'Set zones...';
  @override
  String zonesCount(int count) => '$count zones';
  @override
  String get noDividers => 'No dividers (1 zone)';
  @override
  String get filterRemoveAll => 'Remove all';
  @override
  String get filterOnlyUnassigned => 'Show only components without location';
  @override
  String get filterOnlyUnassignedDesc =>
      'Hides components that have already been assigned to a drawer';
  @override
  String get quickTags => 'Quick tags';
  @override
  String get cabinetContainer => 'Container / Cabinet';
  @override
  String get navigateTagTree => 'Navigate tag tree';
  @override
  String get tagTreeRoot => 'Root';
  @override
  String get noSubtags => 'No subtags available.';
  @override
  String get propertyFilters => 'Property Filters';
  @override
  String get containsText => 'Contains text...';
  @override
  String get exactValue => 'Exact value';
  @override
  String get fromMin => 'From (min)';
  @override
  String get toMax => 'To (max)';
  @override
  String get applyFilters => 'Apply filters';
  @override
  String get selectedTagsLabel => 'Selected tags';
  @override
  String get invalidDrawerCoords =>
      'Drawer coordinates invalid for the current cabinet dimensions';
  @override
  String get moveAction => 'Move';
  @override
  String get selectTargetInventory => 'Select target inventory';
  @override
  String componentMovedSuccess(String targetName) =>
      'Component moved to "$targetName"';
  @override
  String get errorMovingComponent => 'Error while moving component';
  @override
  String get addAttachmentLink => 'Link';
  @override
  String get addAttachmentFile => 'Upload File';
  @override
  String get addAttachmentExisting => 'Existing File';
  @override
  String get takePhotoNow => 'Take Photo Now';
  @override
  String get chooseFromGallery => 'Choose from Gallery';
  @override
  String get addPhoto => 'Add Photo';
  @override
  String get renameFile => 'Rename file';
  @override
  String get filesFound => 'files found';
  @override
  String get fileOptions => 'Options';
  @override
  String get rename => 'Rename';
  @override
  String get notAssigned => 'Not assigned';
  @override
  String get selectFromMap => 'Select from map';
  @override
  String changeDrawerSeparators(int zones) =>
      'Edit dividers ($zones zones)';
  @override
  String get configureDrawerSeparators =>
      'Configure dividers (normal drawer)';
  @override
  String get zoneSeparatorLabel => 'Drawer zone (Divider)';

  // Component Dialog
  @override
  String get newComponentTitle => 'New Component';
  @override
  String get editComponentTitle => 'Edit Component';
  @override
  String get duplicateComponentTitle => 'Duplicate Component';
  @override
  String get compNameLabel => 'Name';
  @override
  String get compNameError => 'Enter a name';
  @override
  String get compDescLabel => 'Description or notes';
  @override
  String get compQtyLabel => 'Quantity';
  @override
  String get compCabinetLabel => 'Cabinet';
  @override
  String get compDrawerLabel => 'Drawer';
  @override
  String get compZoneLabel => 'Drawer zone';
  @override
  String get tagsSectionTitle => 'Tags & Categories';
  @override
  String get selectTreeTags => 'Tag tree';
  @override
  String get selectGenericTags => 'Generic tags';
  @override
  String get showGenericTags => 'Show generic tags';
  @override
  String get hideGenericTags => 'Hide generic tags';
  @override
  String get propertiesSectionTitle => 'Properties';
  @override
  String get addCustomProperty => 'Add property';
  @override
  String get imagesSectionTitle => 'Images & Attachments';
  @override
  String get addImage => 'Add image';
  @override
  String get camera => 'Camera';
  @override
  String get gallery => 'Gallery';
  @override
  String get removeImage => 'Remove';
  @override
  String get keepInBuffer => 'Keep in buffer';
  @override
  String get assignToDrawer => 'Assign to drawer';
  @override
  String get saveButton => 'Save';
  @override
  String get cancelButton => 'Cancel';
  @override
  String get deleteButton => 'Delete';
  @override
  String get draftSaved => 'Draft saved';
  @override
  String get draftRestored => 'Draft restored';

  // Component View Dialog
  @override
  String get componentDetailsTitle => 'Component Details';
  @override
  String get quantityLabel => 'Quantity:';
  @override
  String get locationLabel => 'Location:';
  @override
  String get drawerLabel => 'Drawer:';
  @override
  String get cabinetLabel => 'Cabinet:';
  @override
  String get zoneLabel => 'Zone:';
  @override
  String get tagsLabel => 'Tags:';
  @override
  String get propertiesLabel => 'Properties:';
  @override
  String get notesLabel => 'Notes:';
  @override
  String get attachedFilesLabel => 'Attachments:';
  @override
  String get editAction => 'Edit';
  @override
  String get duplicateAction => 'Duplicate';
  @override
  String get moveToBufferAction => 'Move to buffer';
  @override
  String get printLabelAction => 'Print label';
  @override
  String get deleteAction => 'Delete';
  @override
  String confirmDeleteMsg(String name) =>
      'Are you sure you want to delete "$name"?';

  // Drawer Picker Dialog
  @override
  String get selectDrawerTitle => 'Select Drawer';
  @override
  String get searchDrawerPlaceholder => 'Filter drawer...';
  @override
  String get selectZone => 'Zone:';
  @override
  String cabinetTab(int id, String name) =>
      name.isNotEmpty ? name : 'Cabinet $id';

  // Update Service
  @override
  String get updateAvailableTitle => 'Update available';
  @override
  String updateAvailableDesc(String version) =>
      'A new version ($version) is available. Download now?';
  @override
  String get updateNowButton => 'Update now';
  @override
  String get laterButton => 'Later';
  @override
  String get dontShowAgain => 'Don\'t show again on startup';
  @override
  String get releaseNotes => 'Release notes';
  @override
  String get downloadingUpdate => 'Downloading update...';
  @override
  String get installUpdate => 'Install update';
  @override
  String get updateError => 'Error during update';
  @override
  String get noUpdateAvailable => 'The app is already up to date.';

  // Conflicts
  @override
  String get conflictTitle => 'Sync Conflict';
  @override
  String get conflictDesc =>
      'Remote data has been modified since your last local sync. Choose which version to keep.';
  @override
  String get useLocal => 'Keep local';
  @override
  String get useRemote => 'Keep remote';
  @override
  String get compare => 'Compare';

  @override
  String get selectCabinetLabel => 'Select container:';
  @override
  String get tapDrawerToSelect => 'Tap a drawer to select it';
  @override
  String drawerSelected(String label, [int? zone]) =>
      'Selected: Drawer $label${zone != null ? " (Zone $zone)" : ""}';
  @override
  String get noContainersConfigured => 'No containers configured in settings.';
  @override
  String get offlineUsingLocal => 'Offline · using local data';
  @override
  String get switchButton => 'Switch';
  @override
  String get sync => 'Sync';
  @override
  String get sortBy => 'By';
  @override
  String resultsCount(int count) => '$count results';
  @override
  String componentsCount(int count) => '$count components';
  @override
  String updateAvailableBadge(String version) => 'Update available (v$version)';
  @override
  String get updateAvailableQuestion =>
      'A new version is available. Would you like to download and install it now?';
  @override
  String get positionLabel => 'Position';
  @override
  String get targetInventoryLabel => 'Target inventory';
  @override
  String get noneToSelect => 'None (To be selected)';
  @override
  String get rowLabel => 'Row';
  @override
  String get columnLabel => 'Column';
  @override
  String get requiredField => 'Required';
  @override
  String get disabledDrawer => 'Disabled';
  @override
  String get savePosition => 'Save Position';
  @override
  String get placeAction => 'Place';
  @override
  String placeComponentSuccess(String name) => '"$name" placed successfully!';
  @override
  String get cannotOpenLink => 'Cannot open link';
  @override
  String get cannotOpenFile => 'Cannot open file';
  @override
  String get refreshList => 'Refresh list';
  @override
  String get localModeTitle => 'Local mode';
  @override
  String get localModeDesc =>
      'Enable the remote server in Settings to manage multiple inventories.';
  @override
  String get serverUnreachableTitle => 'Server unreachable';
  @override
  String get serverUnreachableDesc =>
      'Check your connection and the server address.';
  @override
  String get retry => 'Retry';
  @override
  String get noInventoriesTitle => 'No inventories';
  @override
  String get noInventoriesDesc => 'Create your first inventory to get started.';
  @override
  String get createInventory => 'Create inventory';
  @override
  String get inventoryAlreadyActive => 'Inventory already active';
  @override
  String switchedToInventory(String name) => 'Switched to "$name"';
  @override
  String get deleteInventoryPermanentWarning =>
      'All components will be permanently deleted.';
  @override
  String get activeBadge => 'Active';
  @override
  String get uploadedFilesTitle => 'Uploaded Files';
  @override
  String filesFoundCount(int count) => '$count files found';
  @override
  String get noFilesFound => 'No files found';
  @override
  String get searchFilesPlaceholderLong => 'Search file or component...';
  @override
  String deleteAttachmentConfirm(String name) =>
      'Do you want to permanently delete "$name"?';
  @override
  String get deleteImageTitle => 'Delete image';
  @override
  String get deleteFileTitle => 'Delete file';
  @override
  String get componentPrefix => 'Component';

  @override
  String get zoneNearLabel => 'Near (front)';
  @override
  String get zoneFarLabel => 'Far (back)';
  @override
  String get zoneMiddleLabel => 'Middle';
  @override
  String zoneMiddleIndex(int index) => 'Middle ($index)';

  @override
  String deleteBufferComponentConfirm(String name) =>
      'Are you sure you want to remove "$name" from the buffer?';
  @override
  String assignedDestination(String target) => 'Assigned destination: $target';
  @override
  String get destinationUnspecified => 'Destination not specified';
  @override
  String get noDestination => 'No destination';
  @override
  String get emptyBufferDesc =>
      'Add components to register them temporarily before placing them.';
  @override
  String get noBufferResultsDesc =>
      'No components in buffer match your search.';
  @override
  String placeItemDialogTitle(String name) => 'Place "$name"';
  @override
  String get placeItemDialogDesc =>
      'Specify physical location to move the component from the buffer to inventory.';
  @override
  String destinationLabel(String target) => 'Destination: $target';
  @override
  String get changeDestinationAndTags => 'Change destination (and tags)';
  @override
  String maxColumnLabel(String col) => 'Max column: $col';
  @override
  String maxRowLabel(int row) => 'Max row: $row';
  @override
  String get drawerZoneSeparator => 'Drawer zone (Divider)';
  @override
  String get selectTargetInventoryFirst =>
      'Select a destination inventory first.';
  @override
  String get setDestinationAndTags => 'Set destination and tags';

  @override
  String get clear => 'Clear';
  @override
  String get newInventory => 'New inventory';
  @override
  String searchError(String error) => 'Search error: $error';
  @override
  String noMatchesForQuery(String query) =>
      'No component or inventory matches "$query".';
  @override
  String get inventoriesSectionHeader => 'INVENTORIES';
  @override
  String get inventoryComponentsSectionHeader => 'INVENTORY COMPONENTS';
  @override
  String get bufferComponentsSectionHeader => 'BUFFER COMPONENTS';
  @override
  String get nameRequired => 'Name *';
  @override
  String get descriptionOptional => 'Description (optional)';
  @override
  String inventoryCreatedAndSelected(String name) =>
      '"$name" created and selected';
  @override
  String get renameInventoryTitle => 'Rename inventory';
  @override
  String get renameAction => 'Rename';

  @override
  String get cannotOpenLocalFile => 'Cannot open local file';
  @override
  String get renameFileTitle => 'Rename file';
  @override
  String deleteAttachmentPermanentConfirm(String name) =>
      'Do you want to permanently delete "$name"?';
  @override
  String get searchFileOrComponentPlaceholder => 'Search file or component...';

  @override
  String get deleteComponentConfirmMsg =>
      'Are you sure you want to delete this component?';
  @override
  String get loadingTags => 'Loading tags...';
  @override
  String get selectedTagsTitle => 'Selected tags';
  @override
  String get treeRoot => 'Start';
  @override
  String get noSubtagsAvailable => 'No sub-tags available.';
  @override
  String get showGenericLooseTags => 'Show generic tags (loose)';
  @override
  String get addLinkTitle => 'Add Link';
  @override
  String get uploadFileLabel => 'Upload File';
  @override
  String get existingFileLabel => 'Existing File';
  @override
  String get noExistingFiles => 'No existing files';
  @override
  String get chooseExistingFile => 'Choose existing file';
  @override
  String get selectFromGallery => 'Select from Gallery';
  @override
  String get divideDrawerInZones => 'Divide drawer into zones';
  @override
  String get divideDrawerSubtitle =>
      'Allows you to place up to 3 separate components in the same drawer';
  @override
  String get moveToAnotherInventory => 'Move to another inventory';
  @override
  String get moveComponentTitle => 'Move component';
  @override
  String selectDestinationInventoryFor(String name) =>
      'Select destination inventory for "$name":';
  @override
  String componentMovedTo(String name) => 'Component moved to "$name"';
  @override
  String errorDuringMove(String error) => 'Error during move: $error';
  @override
  String get unassignedDrawerShort => 'Not\nass.';
  @override
  String get newComponent => 'New component';
  @override
  String get createFromScratchAndInsert =>
      'Create from scratch and insert into this position';
  @override
  String get assignExisting => 'Assign existing';
  @override
  String get assignExistingComponentTitle => 'Assign existing component';
  @override
  String get passedToBuffer => 'Moved to Buffer';
  @override
  String get editComponentDirectlyFromList =>
      'Edit the component directly from the list.';
  @override
  String get searchInAllInventories =>
      'Search components across all inventories.';
      @override
  String installedVersion(String version) => 'Installed: v$version';
  @override
  String newVersion(String version) => 'New: v$version';
  @override
  String get downloadManualGithub => 'You can download the update manually from GitHub.';
  @override
  String get openOnGithub => 'Open on GitHub';
  @override
  String fileDownloadedTo(String path) => 'File downloaded to: $path';
  @override
  String downloadError(String error) => 'Download error: $error';

  @override
  String get noteReminder => 'Note (reminder)';
  @override
  String get columnHeader => 'Column';
  @override
  String get rowHeader => 'Row';
  @override
  String get columnHint => 'E.g.: A';
  @override
  String get rowHint => 'E.g.: 3';
  @override
  String get missingColumn => 'Missing column';
  @override
  String get missingRow => 'Missing row';
  @override
  String get positionTitle => 'Location';
  @override
  String get selectTargetToConfigureTags => 'Select a destination inventory to configure tags and properties.';
  @override
  String get freeTextHint => 'Free text';
  @override
  String get specialTagNumericHint => 'Leave empty or use K, V, M... (e.g. 1K2)';
  @override
  String get invalidNumberFormat => 'Invalid numeric format';
  @override
  String get invalidNumber => 'Invalid';
  @override
  String get attachmentsTitle => 'Attachments';
  @override
  String get linkNameHint => 'Name (e.g. Datasheet)';
  @override
  String get linkUrlHint => 'URL (https://...)';
  @override
  String get link => 'Link';
  @override
  String get iconBadge => 'Icon';
  @override
  String configureSeparatorsForDrawer(String label, int cabinet) => 'Configure separators for $label (Cabinet $cabinet)';
  @override
  String get selectContainerPrompt => 'Select container:';
  @override
  String selectedDrawerLabel(String drawer) => 'Selected: Drawer $drawer';
  @override
  String drawerNumber(String drawer) => 'Drawer $drawer';
  @override
  String containerNumber(int id) => 'Container $id';
  @override
  String get noDescription => 'No description';
  @override
  String qtyShort(int qty) => 'Qty: $qty';
  @override
  String get appUpToDate => 'The application is up to date.';
  @override
  String appUpToDateDesc(String version) => 'The application is up to date with the latest version (v$version).';
  @override
  String get updateDialogDesc => 'A new version is available. Do you want to download and install it now?';
  @override
  String get updatingTitle => 'Update';
@override
  String get dragToScrollGrid => 'Drag to pan the grid';
  @override
  String activeDrawersCount(int count) => '$count active drawers';
  @override
  String mergedDrawers(String drawers) => 'Merged Drawers ($drawers)';
  @override
  String get drawerContent => 'Drawer content';
  @override
  String get emptyZoneNotice => 'No components in this zone (Empty)';
  @override
  String get chooseFromUnassigned => 'Choose from components without position';
  @override
  String get noUnassignedAvailable => 'No components without position available';
  @override
  String get searchByName => 'Search by name...';
  @override
  String componentAssignedSuccess(String name) => 'Component "$name" assigned successfully.';
  @override
  String assignError(String error) => 'Error during assignment: $error';
  @override
  String get addMainTag => 'Add root tag...';
  @override
  String addSubTag(String parent) => 'Add in $parent...';
  @override
  String get addComponentTitle => 'Add component';
}
