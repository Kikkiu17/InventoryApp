import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_de.dart';

abstract class AppLocalizations {
  static const supportedLocales = [
    Locale('en'),
    Locale('it'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  static const supportedLanguageCodes = ['en', 'it', 'es', 'fr', 'de'];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  static AppLocalizations current = AppLocalizationsIt();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        current;
  }

  static AppLocalizations fromLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'it':
        return AppLocalizationsIt();
      case 'es':
        return AppLocalizationsEs();
      case 'fr':
        return AppLocalizationsFr();
      case 'de':
        return AppLocalizationsDe();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get add;
  String get close;
  String get apply;
  String get confirm;
  String get error;
  String get warning;
  String get success;
  String get search;
  String get loading;
  String get nameLabel;
  String get options;
  String get details;
  String get actions;
  String get select;
  String get none;
  String get all;
  String get yes;
  String get no;
  String get check;

  // Navigation / Tabs
  String get tabInventory;
  String get tabBuffer;
  String get tabInventories;
  String get tabFiles;
  String get tabSettings;

  // Home Screen
  String get viewList;
  String get viewMap;
  String get searchPlaceholder;
  String get searchTooltip;
  String get sortTitle;
  String get sortNone;
  String get sortName;
  String get sortQuantity;
  String get sortDrawer;
  String get sortAscending;
  String get sortDescending;
  String get filterAll;
  String get filterUnassigned;
  String get filterCabinet;
  String get clearFilters;
  String get filterByTag;
  String get filterByProperty;
  String get exportPdfTooltip;
  String get exportPdfTitle;
  String get colName;
  String get colPosition;
  String get colQuantity;
  String get colDetails;
  String get unassignedPosition;
  String get exportSuccess;
  String get exportError;
  String get serverConnected;
  String get serverDisconnected;
  String get switchInventory;
  String get selectInventory;
  String get drawerTitle;
  String get emptyDrawer;
  String get addComponentHere;
  String get configureDrawer;
  String get bulkActions;
  String get bulkMove;
  String get bulkDelete;
  String get bulkAddTag;
  String get bulkRemoveTag;
  String get selectedComponents;
  String get deleteComponentTitle;
  String deleteComponentConfirm(String name);
  String get noComponentsFound;
  String errorChangingInventory(String error);
  String errorSaving(String error);
  String errorDeleting(String error);

  // Buffer Screen
  String get bufferTitle;
  String get searchBufferPlaceholder;
  String get allBags;
  String get unassignedBag;
  String get addBag;
  String get deleteBag;
  String get bagName;
  String get renameBag;
  String get emptyBufferTitle;
  String get emptyBufferSubtitle;
  String get moveToDrawer;
  String get addComponentToBuffer;
  String get bulkMoveToDrawer;
  String deleteBagConfirm(String bag);
  String get newBagTitle;

  // Inventory List Screen
  String get inventoriesTitle;
  String get searchAllInventoriesPlaceholder;
  String get localInventory;
  String get remoteInventory;
  String get currentBadge;
  String itemsCount(int count);
  String get newInventoryTitle;
  String get inventoryName;
  String get create;
  String get deleteInventoryTitle;
  String deleteInventoryConfirm(String name);
  String get syncNow;
  String get syncSuccess;
  String get syncError;
  String get restoreBackup;
  String get noResults;
  String noResultsDescription(String query);
  String get bufferComponentsCategory;

  // Files Screen
  String get filesTitle;
  String get searchFilesPlaceholder;
  String get allFiles;
  String get componentFiles;
  String get noFiles;
  String get shareFile;
  String get deleteFile;
  String deleteFileConfirm(String fileName);
  String get fileSize;
  String get openFileError;

  // Settings Screen
  String get settingsTitle;
  String get saveSettings;
  String get sectionRemoteServer;
  String get sectionAppearance;
  String get sectionLanguage;
  String get sectionContainers;
  String get sectionTagTree;
  String get sectionGenericTags;
  String get sectionProperties;
  String get sectionData;
  String get sectionAbout;
  String get useRemoteServer;
  String get serverConnectedStatus;
  String get serverDisconnectedStatus;
  String get localStorageStatus;
  String get serverUrl;
  String get testConnection;
  String get connectionSuccess;
  String get connectionFailed;
  String get themeMode;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get languageLabel;
  String get languageSystem;
  String get langEn;
  String get langIt;
  String get langEs;
  String get langFr;
  String get langDe;
  String get containersDesc;
  String get newContainer;
  String get containerName;
  String get rows;
  String get columns;
  String get invertRows;
  String get invertColumns;
  String get previewAndShape;
  String get drawerGridHint;
  String get deleteContainer;
  String get drawerConfigTitle;
  String get drawerDisabled;
  String get drawerZones;
  String get mergeDrawers;
  String get splitDrawers;
  String get tagTreeDesc;
  String get genericTagsDesc;
  String get newGenericTag;
  String get addTag;
  String deleteTagConfirm(String tag);
  String get propertiesDesc;
  String get propName;
  String get propUnit;
  String get propSigla;
  String get propSiglaHint;
  String get propText;
  String get addProp;
  String get noPropsConfigured;
  String get editPropTitle;
  String get propUnitLabel;
  String get propTextFree;
  String deletePropConfirm(String name);
  String get dataBackupDesc;
  String get exportJson;
  String get importJson;
  String get restoreRemoteBackup;
  String get backupCreated;
  String get checkUpdates;
  String get checkUpdatesSubtitle;
  String get openGitHub;
  String get appVersion;
  String get manualDrawerConfigTitle;
  String get manualDrawerCode;
  String get manualDrawerHint;
  String get configureButton;
  String get noGenericTags;
  String get settingsSaved;
  String get activeInventory;
  String get enableAll;
  String get disableAll;
  String get enabled;
  String get divideIntoZones;
  String get restoreBackupTitle;
  String get confirmRestoreTitle;
  String get confirmRestoreMsg;
  String get restoreSuccess;
  String get noBackupsFound;
  String bulkDrawerAction(int count);
  String get bulkDrawerActionDesc;
  String get setZones;
  String zonesCount(int count);
  String get noDividers;
  String get filterRemoveAll;
  String get filterOnlyUnassigned;
  String get filterOnlyUnassignedDesc;
  String get quickTags;
  String get cabinetContainer;
  String get navigateTagTree;
  String get tagTreeRoot;
  String get noSubtags;
  String get propertyFilters;
  String get containsText;
  String get exactValue;
  String get fromMin;
  String get toMax;
  String get applyFilters;
  String get selectedTagsLabel;
  String get invalidDrawerCoords;
  String get moveAction;
  String get selectTargetInventory;
  String componentMovedSuccess(String targetName);
  String get errorMovingComponent;
  String get addAttachmentLink;
  String get addAttachmentFile;
  String get addAttachmentExisting;
  String get takePhotoNow;
  String get chooseFromGallery;
  String get addPhoto;
  String get renameFile;
  String get filesFound;
  String get fileOptions;
  String get rename;
  String get notAssigned;
  String get selectFromMap;
  String changeDrawerSeparators(int zones);
  String get configureDrawerSeparators;
  String get zoneSeparatorLabel;

  // Component Dialog
  String get newComponentTitle;
  String get editComponentTitle;
  String get duplicateComponentTitle;
  String get compNameLabel;
  String get compNameError;
  String get compDescLabel;
  String get compQtyLabel;
  String get compCabinetLabel;
  String get compDrawerLabel;
  String get compZoneLabel;
  String get tagsSectionTitle;
  String get selectTreeTags;
  String get selectGenericTags;
  String get showGenericTags;
  String get hideGenericTags;
  String get propertiesSectionTitle;
  String get addCustomProperty;
  String get imagesSectionTitle;
  String get addImage;
  String get camera;
  String get gallery;
  String get removeImage;
  String get keepInBuffer;
  String get assignToDrawer;
  String get saveButton;
  String get cancelButton;
  String get deleteButton;
  String get draftSaved;
  String get draftRestored;

  // Component View Dialog
  String get componentDetailsTitle;
  String get quantityLabel;
  String get locationLabel;
  String get drawerLabel;
  String get cabinetLabel;
  String get zoneLabel;
  String get tagsLabel;
  String get propertiesLabel;
  String get notesLabel;
  String get attachedFilesLabel;
  String get editAction;
  String get duplicateAction;
  String get moveToBufferAction;
  String get printLabelAction;
  String get deleteAction;
  String confirmDeleteMsg(String name);

  // Drawer Picker Dialog
  String get selectDrawerTitle;
  String get searchDrawerPlaceholder;
  String get selectZone;
  String cabinetTab(int id, String name);

  // Update Service
  String get updateAvailableTitle;
  String updateAvailableDesc(String version);
  String get updateNowButton;
  String get laterButton;
  String get dontShowAgain;
  String get releaseNotes;
  String get downloadingUpdate;
  String get installUpdate;
  String get updateError;
  String get noUpdateAvailable;

  // Conflicts
  String get conflictTitle;
  String get conflictDesc;
  String get useLocal;
  String get useRemote;
  String get compare;

  // Additional Common & Screen Strings
  String get selectCabinetLabel;
  String get tapDrawerToSelect;
  String drawerSelected(String label, [int? zone]);
  String get noContainersConfigured;
  String get offlineUsingLocal;
  String get switchButton;
  String get sync;
  String get sortBy;
  String resultsCount(int count);
  String componentsCount(int count);
  String updateAvailableBadge(String version);
  String get updateAvailableQuestion;
  String get positionLabel;
  String get targetInventoryLabel;
  String get noneToSelect;
  String get rowLabel;
  String get columnLabel;
  String get requiredField;
  String get disabledDrawer;
  String get savePosition;
  String get placeAction;
  String placeComponentSuccess(String name);
  String get cannotOpenLink;
  String get cannotOpenFile;
  String get refreshList;
  String get localModeTitle;
  String get localModeDesc;
  String get serverUnreachableTitle;
  String get serverUnreachableDesc;
  String get retry;
  String get noInventoriesTitle;
  String get noInventoriesDesc;
  String get createInventory;
  String get inventoryAlreadyActive;
  String switchedToInventory(String name);
  String get deleteInventoryPermanentWarning;
  String get activeBadge;
  String get uploadedFilesTitle;
  String filesFoundCount(int count);
  String get noFilesFound;
  String get searchFilesPlaceholderLong;
  String deleteAttachmentConfirm(String name);
  String get deleteImageTitle;
  String get deleteFileTitle;
  String get componentPrefix;

  // Zone labels
  String get zoneNearLabel;
  String get zoneFarLabel;
  String get zoneMiddleLabel;
  String zoneMiddleIndex(int index);

  // Buffer Screen additions
  String deleteBufferComponentConfirm(String name);
  String assignedDestination(String target);
  String get destinationUnspecified;
  String get noDestination;
  String get emptyBufferDesc;
  String get noBufferResultsDesc;
  String placeItemDialogTitle(String name);
  String get placeItemDialogDesc;
  String destinationLabel(String target);
  String get changeDestinationAndTags;
  String maxColumnLabel(String col);
  String maxRowLabel(int row);
  String get drawerZoneSeparator;
  String get selectTargetInventoryFirst;
  String get setDestinationAndTags;

  // Inventory List Screen additions
  String get clear;
  String get newInventory;
  String searchError(String error);
  String noMatchesForQuery(String query);
  String get inventoriesSectionHeader;
  String get inventoryComponentsSectionHeader;
  String get bufferComponentsSectionHeader;
  String get nameRequired;
  String get descriptionOptional;
  String inventoryCreatedAndSelected(String name);
  String get renameInventoryTitle;
  String get renameAction;

  // Files Screen additions
  String get cannotOpenLocalFile;
  String get renameFileTitle;
  String deleteAttachmentPermanentConfirm(String name);
  String get searchFileOrComponentPlaceholder;

  // Component Dialogs additions
  String get deleteComponentConfirmMsg;
  String get loadingTags;
  String get selectedTagsTitle;
  String get treeRoot;
  String get noSubtagsAvailable;
  String get showGenericLooseTags;
  String get addLinkTitle;
  String get uploadFileLabel;
  String get existingFileLabel;
  String get noExistingFiles;
  String get chooseExistingFile;
  String get selectFromGallery;
  String get divideDrawerInZones;
  String get divideDrawerSubtitle;
  String get moveToAnotherInventory;
  String get moveComponentTitle;
  String selectDestinationInventoryFor(String name);
  String componentMovedTo(String name);
  String errorDuringMove(String error);
  String get unassignedDrawerShort;
  String get newComponent;
  String get createFromScratchAndInsert;
  String get assignExisting;
  String get assignExistingComponentTitle;
  String get passedToBuffer;
  String get editComponentDirectlyFromList;
  String get searchInAllInventories;
  String installedVersion(String version);
  String newVersion(String version);
  String get downloadManualGithub;
  String get openOnGithub;
  String fileDownloadedTo(String path);
  String downloadError(String error);

  // Remaining UI additions
  String get noteReminder;
  String get columnHeader;
  String get rowHeader;
  String get columnHint;
  String get rowHint;
  String get missingColumn;
  String get missingRow;
  String get positionTitle;
  String get selectTargetToConfigureTags;
  String get freeTextHint;
  String get specialTagNumericHint;
  String get invalidNumberFormat;
  String get invalidNumber;
  String get attachmentsTitle;
  String get linkNameHint;
  String get linkUrlHint;
  String get link;
  String get iconBadge;
  String configureSeparatorsForDrawer(String label, int cabinet);
  String get selectContainerPrompt;
  String selectedDrawerLabel(String drawer);
  String drawerNumber(String drawer);
  String containerNumber(int id);
  String get noDescription;
  String qtyShort(int qty);
  String get appUpToDate;
  String appUpToDateDesc(String version);
  String get updateDialogDesc;
  String get updatingTitle;
  String get dragToScrollGrid;
  String activeDrawersCount(int count);
  String mergedDrawers(String drawers);
  String get drawerContent;
  String get emptyZoneNotice;
  String get chooseFromUnassigned;
  String get noUnassignedAvailable;
  String get searchByName;
  String componentAssignedSuccess(String name);
  String assignError(String error);
  String get addMainTag;
  String addSubTag(String parent);
  String get addComponentTitle;

  // What's Changed
  String get whatsNewTitle;
  String get whatsNewSubtitle;
  String get whatsNewDontShowAgain;
  String whatsNewTooltip(int count);
  String get whatsNewNoChanges;
  String get whatsNewAdded;
  String get whatsNewModified;
  String get whatsNewDeleted;
  String get whatsNewComponentDeletedNotice;
  String whatsNewQuantityChanged(String oldQty, String newQty);
  String whatsNewDrawerChanged(String oldDrawer, String newDrawer);
  String whatsNewNameChanged(String oldName, String newName);
  String get whatsNewDescriptionChanged;
  String get whatsNewTagsChanged;
  String get whatsNewPropertiesChanged;
  String get whatsNewMarkAsRead;
  String get whatsNewSettingTitle;
  String get whatsNewSettingSubtitle;
  String get whatsNewViewRecentChanges;
  String whatsNewChangesCount(int count);
}


class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final loc = AppLocalizations.fromLocale(locale);
    AppLocalizations.current = loc;
    return loc;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
