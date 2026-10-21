import 'app_localizations.dart';

class AppLocalizationsFr extends AppLocalizations {
  @override
  String get appName => 'Inventaire des Composants';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Annuler';
  @override
  String get save => 'Enregistrer';
  @override
  String get delete => 'Supprimer';
  @override
  String get edit => 'Modifier';
  @override
  String get add => 'Ajouter';
  @override
  String get close => 'Fermer';
  @override
  String get apply => 'Appliquer';
  @override
  String get confirm => 'Confirmer';
  @override
  String get error => 'Erreur';
  @override
  String get warning => 'Attention';
  @override
  String get success => 'Opération réussie';
  @override
  String get search => 'Rechercher';
  @override
  String get loading => 'Chargement...';
  @override
  String get nameLabel => 'Nom';
  @override
  String get options => 'Options';
  @override
  String get details => 'Détails';
  @override
  String get actions => 'Actions';
  @override
  String get select => 'Sélectionner';
  @override
  String get none => 'Aucun';
  @override
  String get all => 'Tous';
  @override
  String get yes => 'Oui';
  @override
  String get no => 'Non';
  @override
  String get check => 'Vérifier';

  // Navigation / Tabs
  @override
  String get tabInventory => 'Inventaire';
  @override
  String get tabBuffer => 'Tampon';
  @override
  String get tabInventories => 'Inventaires';
  @override
  String get tabFiles => 'Fichiers';
  @override
  String get tabSettings => 'Paramètres';

  // Home Screen
  @override
  String get viewList => 'Liste';
  @override
  String get viewMap => 'Carte';
  @override
  String get searchPlaceholder => 'Rechercher des composants...';
  @override
  String get searchTooltip => 'Rechercher';
  @override
  String get sortTitle => 'Trier par';
  @override
  String get sortNone => 'Aucun tri';
  @override
  String get sortName => 'Nom';
  @override
  String get sortQuantity => 'Quantité';
  @override
  String get sortDrawer => 'Tiroir';
  @override
  String get sortAscending => 'Ordre : Croissant';
  @override
  String get sortDescending => 'Ordre : Décroissant';
  @override
  String get filterAll => 'Tous les tiroirs';
  @override
  String get filterUnassigned => 'Non assigné';
  @override
  String get filterCabinet => 'Casier';
  @override
  String get clearFilters => 'Effacer les filtres';
  @override
  String get filterByTag => 'Filtrer par étiquette';
  @override
  String get filterByProperty => 'Filtrer par propriété';
  @override
  String get exportPdfTooltip => 'Exporter la liste en PDF';
  @override
  String get exportPdfTitle => 'Inventaire des Composants';
  @override
  String get colName => 'Nom';
  @override
  String get colPosition => 'Position';
  @override
  String get colQuantity => 'Qté';
  @override
  String get colDetails => 'Détails';
  @override
  String get unassignedPosition => 'Non ass.';
  @override
  String get exportSuccess => 'PDF exporté avec succès';
  @override
  String get exportError => 'Erreur lors de l\'exportation du PDF';
  @override
  String get serverConnected => 'Serveur connecté';
  @override
  String get serverDisconnected => 'Serveur déconnecté';
  @override
  String get switchInventory => 'Changer';
  @override
  String get selectInventory => 'Sélectionner l\'inventaire';
  @override
  String get drawerTitle => 'Tiroir';
  @override
  String get emptyDrawer => 'Aucun composant dans ce tiroir';
  @override
  String get addComponentHere => 'Ajouter un composant ici';
  @override
  String get configureDrawer => 'Configurer le tiroir';
  @override
  String get bulkActions => 'Actions groupées';
  @override
  String get bulkMove => 'Déplacer la sélection';
  @override
  String get bulkDelete => 'Supprimer la sélection';
  @override
  String get bulkAddTag => 'Ajouter une étiquette à la sélection';
  @override
  String get bulkRemoveTag => 'Retirer une étiquette de la sélection';
  @override
  String get selectedComponents => 'composants sélectionnés';
  @override
  String get deleteComponentTitle => 'Supprimer le composant';
  @override
  String deleteComponentConfirm(String name) =>
      'Êtes-vous sûr de vouloir supprimer "$name" ?';
  @override
  String get noComponentsFound => 'Aucun composant trouvé';
  @override
  String errorChangingInventory(String error) =>
      'Erreur lors du changement d\'inventaire : $error';
  @override
  String errorSaving(String error) => 'Erreur lors de l\'enregistrement : $error';
  @override
  String errorDeleting(String error) => 'Erreur lors de la suppression : $error';

  // Buffer Screen
  @override
  String get bufferTitle => 'Tampon';
  @override
  String get searchBufferPlaceholder => 'Rechercher dans le tampon...';
  @override
  String get allBags => 'Tous';
  @override
  String get unassignedBag => 'Sans sachet';
  @override
  String get addBag => 'Nouveau sachet';
  @override
  String get deleteBag => 'Supprimer le sachet';
  @override
  String get bagName => 'Nom du sachet';
  @override
  String get renameBag => 'Renommer le sachet';
  @override
  String get emptyBufferTitle => 'Tampon vide';
  @override
  String get emptyBufferSubtitle =>
      'Les composants non encore rangés dans les tiroirs apparaîtront ici.';
  @override
  String get moveToDrawer => 'Assigner un tiroir';
  @override
  String get addComponentToBuffer => 'Ajouter au tampon';
  @override
  String get bulkMoveToDrawer => 'Assigner au tiroir';
  @override
  String deleteBagConfirm(String bag) =>
      'Supprimer le sachet "$bag" ? Les composants resteront dans le tampon.';
  @override
  String get newBagTitle => 'Nouveau Sachet';

  // Inventory List Screen
  @override
  String get inventoriesTitle => 'Inventaires';
  @override
  String get searchAllInventoriesPlaceholder => 'Rechercher dans tous les inventaires…';
  @override
  String get localInventory => 'Inventaire Local';
  @override
  String get remoteInventory => 'Distant';
  @override
  String get currentBadge => 'ACTUEL';
  @override
  String itemsCount(int count) => '$count composants';
  @override
  String get newInventoryTitle => 'Nouvel Inventaire';
  @override
  String get inventoryName => 'Nom de l\'inventaire';
  @override
  String get create => 'Créer';
  @override
  String get deleteInventoryTitle => 'Supprimer l\'inventaire';
  @override
  String deleteInventoryConfirm(String name) =>
      'Êtes-vous sûr de vouloir supprimer l\'inventaire "$name" ? Cette action ne peut pas être annulée.';
  @override
  String get syncNow => 'Synchroniser maintenant';
  @override
  String get syncSuccess => 'Synchronisation terminée';
  @override
  String get syncError => 'Erreur de synchronisation';
  @override
  String get restoreBackup => 'Restaurer la sauvegarde';
  @override
  String get noResults => 'Aucun résultat';
  @override
  String noResultsDescription(String query) =>
      'Aucun composant ou inventaire ne correspond à "$query".';
  @override
  String get bufferComponentsCategory => 'COMPOSANTS DU TAMPON';

  // Files Screen
  @override
  String get filesTitle => 'Fichiers et Pièces jointes';
  @override
  String get searchFilesPlaceholder => 'Rechercher des fichiers...';
  @override
  String get allFiles => 'Tous les fichiers';
  @override
  String get componentFiles => 'Fichiers composants';
  @override
  String get noFiles => 'Aucun fichier présent';
  @override
  String get shareFile => 'Partager';
  @override
  String get deleteFile => 'Supprimer le fichier';
  @override
  String deleteFileConfirm(String fileName) =>
      'Êtes-vous sûr de vouloir supprimer "$fileName" ?';
  @override
  String get fileSize => 'Taille';
  @override
  String get openFileError => 'Impossible d\'ouvrir le fichier';

  // Settings Screen
  @override
  String get settingsTitle => 'Paramètres';
  @override
  String get saveSettings => 'Enregistrer';
  @override
  String get sectionRemoteServer => 'Serveur distant';
  @override
  String get sectionAppearance => 'Apparence';
  @override
  String get sectionLanguage => 'Langue';
  @override
  String get sectionContainers => 'Configuration des casiers (tiroirs)';
  @override
  String get sectionTagTree => 'Arborescence des Étiquettes';
  @override
  String get sectionGenericTags => 'Étiquettes Génériques';
  @override
  String get sectionProperties => 'Propriétés avec valeur';
  @override
  String get sectionData => 'Données';
  @override
  String get sectionAbout => 'Informations et mises à jour';
  @override
  String get useRemoteServer => 'Utiliser le serveur distant';
  @override
  String get serverConnectedStatus => '✅ Connecté';
  @override
  String get serverDisconnectedStatus => '❌ Non connecté';
  @override
  String get localStorageStatus => 'Stockage local';
  @override
  String get serverUrl => 'Adresse du serveur';
  @override
  String get trustSelfSignedCertificates => 'Faire confiance aux certificats auto-signés';
  @override
  String get trustSelfSignedCertificatesDesc =>
      'Autoriser les connexions HTTPS avec des certificats SSL/TLS auto-signés ou non vérifiés (recommandé pour les serveurs locaux)';
  @override
  String get testConnection => 'Tester la connexion';
  @override
  String get connectionSuccess => 'Connexion établie avec succès !';
  @override
  String get connectionFailed => 'Impossible de se connecter au serveur';
  @override
  String get themeMode => 'Thème de l\'application';
  @override
  String get themeSystem => 'Système';
  @override
  String get themeLight => 'Clair';
  @override
  String get themeDark => 'Sombre';
  @override
  String get languageLabel => 'Langue de l\'application';
  @override
  String get languageSystem => 'Par défaut du système';
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
      'Gérer les casiers physiques. Chaque casier peut avoir des dimensions et des formes personnalisées en désactivant des tiroirs dans l\'aperçu.';
  @override
  String get newContainer => 'Ajouter un casier';
  @override
  String get containerName => 'Nom du casier';
  @override
  String get rows => 'Lignes';
  @override
  String get columns => 'Colonnes';
  @override
  String get invertRows => 'Inverser les lignes (de bas en haut)';
  @override
  String get invertColumns => 'Inverser les colonnes (de droite à gauche)';
  @override
  String get previewAndShape => 'Aperçu et forme';
  @override
  String get drawerGridHint =>
      'Aperçu (cliquez pour configurer, appui long et glisser pour sélectionner en masse)';
  @override
  String get deleteContainer => 'Supprimer le casier';
  @override
  String get drawerConfigTitle => 'Configuration du tiroir';
  @override
  String get drawerDisabled => 'Tiroir désactivé';
  @override
  String get drawerZones => 'Zones / Séparateurs';
  @override
  String get mergeDrawers => 'Fusionner les tiroirs';
  @override
  String get splitDrawers => 'Séparer les tiroirs';
  @override
  String get tagTreeDesc =>
      'Créer des catégories et sous-catégories en tapant dans le champ et en appuyant sur Entrée.';
  @override
  String get genericTagsDesc =>
      'Étiquettes génériques sans hiérarchie pour étiqueter rapidement les composants.';
  @override
  String get newGenericTag => 'Nouvelle étiquette générique';
  @override
  String get addTag => 'Ajouter';
  @override
  String deleteTagConfirm(String tag) => 'Supprimer l\'étiquette "$tag" ?';
  @override
  String get propertiesDesc =>
      'Définir des propriétés numériques ou de texte. Glisser pour réorganiser.';
  @override
  String get propName => 'Nom';
  @override
  String get propUnit => 'Unité';
  @override
  String get propSigla => 'Sigle';
  @override
  String get propSiglaHint => 'ex. L';
  @override
  String get propText => 'Texte';
  @override
  String get addProp => 'Ajouter';
  @override
  String get noPropsConfigured => 'Aucune propriété configurée.';
  @override
  String get editPropTitle => 'Modifier la propriété';
  @override
  String get propUnitLabel => 'Unité';
  @override
  String get propTextFree => 'Texte libre';
  @override
  String deletePropConfirm(String name) => 'Supprimer la propriété "$name" ?';
  @override
  String get dataBackupDesc => 'Gestion des sauvegardes et exportation';
  @override
  String get exportJson => 'Exporter sauvegarde locale (JSON)';
  @override
  String get importJson => 'Restaurer depuis un fichier JSON';
  @override
  String get restoreRemoteBackup => 'Restaurer sauvegarde distante';
  @override
  String get backupCreated => 'Sauvegarde créée avec succès';
  @override
  String get checkUpdates => 'Vérifier les mises à jour';
  @override
  String get checkUpdatesSubtitle =>
      'Vérifier et télécharger la dernière version depuis GitHub';
  @override
  String get openGitHub => 'Ouvrir la page GitHub';
  @override
  String get appVersion => 'Version de l\'application';
  @override
  String get manualDrawerConfigTitle =>
      'Configurer le tiroir par coordonnées (pour les tiroirs non visibles dans l\'aperçu)';
  @override
  String get manualDrawerCode => 'Code tiroir';
  @override
  String get manualDrawerHint => 'Ex : A20 ou K4';
  @override
  String get configureButton => 'Configurer';
  @override
  String get noGenericTags => 'Aucune étiquette générique.';
  @override
  String get settingsSaved => 'Paramètres enregistrés';
  @override
  String get activeInventory => 'Inventaire actif';
  @override
  String get enableAll => 'Tout activer';
  @override
  String get disableAll => 'Tout désactiver';
  @override
  String get enabled => 'Activé';
  @override
  String get divideIntoZones => 'Diviser en zones';
  @override
  String get restoreBackupTitle => 'Restaurer la sauvegarde';
  @override
  String get confirmRestoreTitle => 'Confirmer la restauration';
  @override
  String get confirmRestoreMsg =>
      'Écraser les données actuelles ? (Une sauvegarde de sécurité sera créée automatiquement au préalable).';
  @override
  String get restoreSuccess => 'Sauvegarde restaurée avec succès';
  @override
  String get noBackupsFound => 'Aucune sauvegarde trouvée';
  @override
  String bulkDrawerAction(int count) => 'Action groupée ($count tiroirs)';
  @override
  String get bulkDrawerActionDesc =>
      'Que souhaitez-vous faire avec les tiroirs sélectionnés ?\nVous pouvez les désactiver, les activer, définir des zones ou les fusionner/diviser.';
  @override
  String get setZones => 'Définir des zones...';
  @override
  String zonesCount(int count) => '$count zones';
  @override
  String get noDividers => 'Aucun séparateur (1 zone)';
  @override
  String get filterRemoveAll => 'Tout effacer';
  @override
  String get filterOnlyUnassigned => 'Composants sans emplacement uniquement';
  @override
  String get filterOnlyUnassignedDesc =>
      'Masque les composants auxquels un tiroir a déjà été assigné';
  @override
  String get quickTags => 'Étiquettes rapides';
  @override
  String get cabinetContainer => 'Conteneur / Meuble';
  @override
  String get navigateTagTree => 'Parcourir les étiquettes';
  @override
  String get tagTreeRoot => 'Racine';
  @override
  String get noSubtags => 'Aucune sous-étiquette disponible.';
  @override
  String get propertyFilters => 'Filtres par Propriété';
  @override
  String get containsText => 'Contient le texte...';
  @override
  String get exactValue => 'Valeur exacte';
  @override
  String get fromMin => 'De (min)';
  @override
  String get toMax => 'À (max)';
  @override
  String get applyFilters => 'Appliquer les filtres';
  @override
  String get selectedTagsLabel => 'Étiquettes sélectionnées';
  @override
  String get invalidDrawerCoords =>
      'Coordonnées de tiroir non valides pour les dimensions actuelles du meuble';
  @override
  String get moveAction => 'Déplacer';
  @override
  String get selectTargetInventory => 'Sélectionner l\'inventaire cible';
  @override
  String componentMovedSuccess(String targetName) =>
      'Composant déplacé vers "$targetName"';
  @override
  String get errorMovingComponent => 'Erreur lors du déplacement';
  @override
  String get addAttachmentLink => 'Lien';
  @override
  String get addAttachmentFile => 'Téléverser un Fichier';
  @override
  String get addAttachmentExisting => 'Fichier Existant';
  @override
  String get takePhotoNow => 'Prendre une photo';
  @override
  String get chooseFromGallery => 'Choisir dans la galerie';
  @override
  String get addPhoto => 'Ajouter une photo';
  @override
  String get renameFile => 'Renommer le fichier';
  @override
  String get filesFound => 'fichiers trouvés';
  @override
  String get fileOptions => 'Options';
  @override
  String get rename => 'Renommer';
  @override
  String get notAssigned => 'Non assigné';
  @override
  String get selectFromMap => 'Sélectionner sur la carte';
  @override
  String changeDrawerSeparators(int zones) =>
      'Modifier séparateurs ($zones zones)';
  @override
  String get configureDrawerSeparators =>
      'Configurer séparateurs (tiroir standard)';
  @override
  String get zoneSeparatorLabel => 'Zone du tiroir (Séparateur)';

  // Component Dialog
  @override
  String get newComponentTitle => 'Nouveau Composant';
  @override
  String get editComponentTitle => 'Modifier le Composant';
  @override
  String get duplicateComponentTitle => 'Dupliquer le Composant';
  @override
  String get compNameLabel => 'Nom';
  @override
  String get compNameError => 'Veuillez entrer un nom';
  @override
  String get compDescLabel => 'Description ou notes';
  @override
  String get compQtyLabel => 'Quantité';
  @override
  String get compCabinetLabel => 'Casier';
  @override
  String get compDrawerLabel => 'Tiroir';
  @override
  String get compZoneLabel => 'Zone du tiroir';
  @override
  String get tagsSectionTitle => 'Étiquettes et Catégories';
  @override
  String get selectTreeTags => 'Arborescence';
  @override
  String get selectGenericTags => 'Étiquettes génériques';
  @override
  String get showGenericTags => 'Afficher les étiquettes génériques';
  @override
  String get hideGenericTags => 'Masquer les étiquettes génériques';
  @override
  String get propertiesSectionTitle => 'Propriétés';
  @override
  String get addCustomProperty => 'Ajouter une propriété';
  @override
  String get imagesSectionTitle => 'Images et Pièces jointes';
  @override
  String get addImage => 'Ajouter une image';
  @override
  String get camera => 'Appareil photo';
  @override
  String get gallery => 'Galerie';
  @override
  String get removeImage => 'Supprimer';
  @override
  String get keepInBuffer => 'Garder dans le tampon';
  @override
  String get assignToDrawer => 'Assigner un tiroir';
  @override
  String get saveButton => 'Enregistrer';
  @override
  String get cancelButton => 'Annuler';
  @override
  String get deleteButton => 'Supprimer';
  @override
  String get draftSaved => 'Brouillon enregistré';
  @override
  String get draftRestored => 'Brouillon restauré';

  // Component View Dialog
  @override
  String get componentDetailsTitle => 'Détails du Composant';
  @override
  String get quantityLabel => 'Quantité :';
  @override
  String get locationLabel => 'Emplacement :';
  @override
  String get drawerLabel => 'Tiroir :';
  @override
  String get cabinetLabel => 'Casier :';
  @override
  String get zoneLabel => 'Zone :';
  @override
  String get tagsLabel => 'Étiquettes :';
  @override
  String get propertiesLabel => 'Propriétés :';
  @override
  String get notesLabel => 'Notes :';
  @override
  String get attachedFilesLabel => 'Pièces jointes :';
  @override
  String get editAction => 'Modifier';
  @override
  String get duplicateAction => 'Dupliquer';
  @override
  String get moveToBufferAction => 'Déplacer dans le tampon';
  @override
  String get printLabelAction => 'Imprimer l\'étiquette';
  @override
  String get deleteAction => 'Supprimer';
  @override
  String confirmDeleteMsg(String name) =>
      'Êtes-vous sûr de vouloir supprimer "$name" ?';

  // Drawer Picker Dialog
  @override
  String get selectDrawerTitle => 'Sélectionner le Tiroir';
  @override
  String get searchDrawerPlaceholder => 'Filtrer le tiroir...';
  @override
  String get selectZone => 'Zone :';
  @override
  String cabinetTab(int id, String name) =>
      name.isNotEmpty ? name : 'Casier $id';

  // Update Service
  @override
  String get updateAvailableTitle => 'Mise à jour disponible';
  @override
  String updateAvailableDesc(String version) =>
      'Une nouvelle version ($version) est disponible. Télécharger maintenant ?';
  @override
  String get updateNowButton => 'Mettre à jour';
  @override
  String get laterButton => 'Plus tard';
  @override
  String get dontShowAgain => 'Ne plus afficher au démarrage';
  @override
  String get releaseNotes => 'Notes de version';
  @override
  String get downloadingUpdate => 'Téléchargement de la mise à jour...';
  @override
  String get installUpdate => 'Installer la mise à jour';
  @override
  String get updateError => 'Erreur lors de la mise à jour';
  @override
  String get noUpdateAvailable => 'L\'application est déjà à jour.';

  // Conflicts
  @override
  String get conflictTitle => 'Conflit de synchronisation';
  @override
  String get conflictDesc =>
      'Les données distantes ont été modifiées depuis votre dernière synchronisation. Choisissez quelle version conserver.';
  @override
  String get useLocal => 'Conserver locale';
  @override
  String get useRemote => 'Conserver distante';
  @override
  String get compare => 'Comparer';

  @override
  String get selectCabinetLabel => 'Sélectionner un conteneur :';
  @override
  String get tapDrawerToSelect => 'Touchez un tiroir pour le sélectionner';
  @override
  String drawerSelected(String label, [int? zone]) =>
      'Sélectionné : Tiroir $label${zone != null ? " (Zone $zone)" : ""}';
  @override
  String get noContainersConfigured =>
      'Aucun conteneur configuré dans les paramètres.';
  @override
  String get offlineUsingLocal => 'Hors ligne · données locales';
  @override
  String get switchButton => 'Changer';
  @override
  String get sync => 'Synchroniser';
  @override
  String get sortBy => 'Par';
  @override
  String resultsCount(int count) => '$count résultats';
  @override
  String componentsCount(int count) => '$count composants';
  @override
  String updateAvailableBadge(String version) =>
      'Mise à jour disponible (v$version)';
  @override
  String get updateAvailableQuestion =>
      'Une nouvelle version est disponible. Voulez-vous la télécharger et l\'installer maintenant ?';
  @override
  String get positionLabel => 'Position';
  @override
  String get targetInventoryLabel => 'Inventaire cible';
  @override
  String get noneToSelect => 'Aucun (À sélectionner)';
  @override
  String get rowLabel => 'Rangée';
  @override
  String get columnLabel => 'Colonne';
  @override
  String get requiredField => 'Obligatoire';
  @override
  String get disabledDrawer => 'Désactivé';
  @override
  String get savePosition => 'Enregistrer la position';
  @override
  String get placeAction => 'Placer';
  @override
  String placeComponentSuccess(String name) =>
      '"$name" placé avec succès !';
  @override
  String get cannotOpenLink => 'Impossible d\'ouvrir le lien';
  @override
  String get cannotOpenFile => 'Impossible d\'ouvrir le fichier';
  @override
  String get refreshList => 'Rafraîchir la liste';
  @override
  String get localModeTitle => 'Mode local';
  @override
  String get localModeDesc =>
      'Activez le serveur distant dans les Paramètres pour gérer plusieurs inventaires.';
  @override
  String get serverUnreachableTitle => 'Serveur inaccessible';
  @override
  String get serverUnreachableDesc =>
      'Vérifiez votre connexion et l\'adresse du serveur.';
  @override
  String get retry => 'Réessayer';
  @override
  String get noInventoriesTitle => 'Aucun inventaire';
  @override
  String get noInventoriesDesc =>
      'Créez votre premier inventaire pour commencer.';
  @override
  String get createInventory => 'Créer un inventaire';
  @override
  String get inventoryAlreadyActive => 'Inventaire déjà actif';
  @override
  String switchedToInventory(String name) => 'Passé à "$name"';
  @override
  String get deleteInventoryPermanentWarning =>
      'Tous les composants seront définitivement supprimés.';
  @override
  String get activeBadge => 'Actif';
  @override
  String get uploadedFilesTitle => 'Fichiers Téléchargés';
  @override
  String filesFoundCount(int count) => '$count fichiers trouvés';
  @override
  String get noFilesFound => 'Aucun fichier trouvé';
  @override
  String get searchFilesPlaceholderLong =>
      'Rechercher un fichier ou un composant...';
  @override
  String deleteAttachmentConfirm(String name) =>
      'Voulez-vous supprimer définitivement "$name" ?';
  @override
  String get deleteImageTitle => 'Supprimer l\'image';
  @override
  String get deleteFileTitle => 'Supprimer le fichier';
  @override
  String get componentPrefix => 'Composant';

  @override
  String get zoneNearLabel => 'Proche (avant)';
  @override
  String get zoneFarLabel => 'Lointaine (arrière)';
  @override
  String get zoneMiddleLabel => 'Au milieu';
  @override
  String zoneMiddleIndex(int index) => 'Au milieu ($index)';

  @override
  String deleteBufferComponentConfirm(String name) =>
      'Êtes-vous sûr de vouloir supprimer "$name" du tampon ?';
  @override
  String assignedDestination(String target) =>
      'Destination assignée : $target';
  @override
  String get destinationUnspecified => 'Destination non spécifiée';
  @override
  String get noDestination => 'Sans destination';
  @override
  String get emptyBufferDesc =>
      'Ajoutez des composants pour les enregistrer temporairement avant de les placer.';
  @override
  String get noBufferResultsDesc =>
      'Aucun composant dans le tampon ne correspond à votre recherche.';
  @override
  String placeItemDialogTitle(String name) => 'Placer "$name"';
  @override
  String get placeItemDialogDesc =>
      'Spécifiez l\'emplacement physique pour déplacer le composant du tampon vers l\'inventaire.';
  @override
  String destinationLabel(String target) => 'Destination : $target';
  @override
  String get changeDestinationAndTags =>
      'Changer la destination (et les étiquettes)';
  @override
  String maxColumnLabel(String col) => 'Colonne max. : $col';
  @override
  String maxRowLabel(int row) => 'Ligne max. : $row';
  @override
  String get drawerZoneSeparator => 'Zone du tiroir (Séparateur)';
  @override
  String get selectTargetInventoryFirst =>
      'Sélectionnez d\'abord un inventaire de destination.';
  @override
  String get setDestinationAndTags => 'Définir la destination et les étiquettes';

  @override
  String get clear => 'Effacer';
  @override
  String get newInventory => 'Nouvel inventaire';
  @override
  String searchError(String error) =>
      'Erreur lors de la recherche : $error';
  @override
  String noMatchesForQuery(String query) =>
      'Aucun composant ou inventaire ne correspond à "$query".';
  @override
  String get inventoriesSectionHeader => 'INVENTAIRES';
  @override
  String get inventoryComponentsSectionHeader =>
      'COMPOSANTS DES INVENTAIRES';
  @override
  String get bufferComponentsSectionHeader => 'COMPOSANTS DU TAMPON';
  @override
  String get nameRequired => 'Nom *';
  @override
  String get descriptionOptional => 'Description (facultatif)';
  @override
  String inventoryCreatedAndSelected(String name) =>
      '"$name" créé et sélectionné';
  @override
  String get renameInventoryTitle => 'Renommer l\'inventaire';
  @override
  String get renameAction => 'Renommer';

  @override
  String get cannotOpenLocalFile =>
      'Impossible d\'ouvrir le fichier local';
  @override
  String get renameFileTitle => 'Renommer le fichier';
  @override
  String deleteAttachmentPermanentConfirm(String name) =>
      'Voulez-vous supprimer définitivement "$name" ?';
  @override
  String get searchFileOrComponentPlaceholder =>
      'Rechercher un fichier ou un composant...';

  @override
  String get deleteComponentConfirmMsg =>
      'Êtes-vous sûr de vouloir supprimer ce composant ?';
  @override
  String get loadingTags => 'Chargement des étiquettes...';
  @override
  String get selectedTagsTitle => 'Étiquettes sélectionnées';
  @override
  String get treeRoot => 'Début';
  @override
  String get noSubtagsAvailable => 'Aucune sous-étiquette disponible.';
  @override
  String get showGenericLooseTags =>
      'Afficher les étiquettes génériques (en vrac)';
  @override
  String get addLinkTitle => 'Ajouter un lien';
  @override
  String get uploadFileLabel => 'Téléverser un fichier';
  @override
  String get existingFileLabel => 'Fichier existant';
  @override
  String get noExistingFiles => 'Aucun fichier existant';
  @override
  String get chooseExistingFile => 'Choisir un fichier existant';
  @override
  String get selectFromGallery => 'Sélectionner depuis la galerie';
  @override
  String get divideDrawerInZones => 'Diviser le tiroir en zones';
  @override
  String get divideDrawerSubtitle =>
      'Permet de placer jusqu\'à 3 composants séparés dans le même tiroir';
  @override
  String get moveToAnotherInventory => 'Déplacer vers un autre inventaire';
  @override
  String get moveComponentTitle => 'Déplacer le composant';
  @override
  String selectDestinationInventoryFor(String name) =>
      'Sélectionnez l\'inventaire de destination pour "$name" :';
  @override
  String componentMovedTo(String name) =>
      'Composant déplacé vers "$name"';
  @override
  String errorDuringMove(String error) =>
      'Erreur lors du déplacement : $error';
  @override
  String get unassignedDrawerShort => 'Non\naff.';
  @override
  String get newComponent => 'Nouveau composant';
  @override
  String get createFromScratchAndInsert =>
      'Créer de zéro et insérer à cette position';
  @override
  String get assignExisting => 'Assigner un existant';
  @override
  String get assignExistingComponentTitle =>
      'Assigner un composant existant';
  @override
  String get passedToBuffer => 'Déplacé vers le tampon';
  @override
  String get editComponentDirectlyFromList =>
      'Modifiez le composant directement depuis la liste.';
  @override
  String get searchInAllInventories =>
      'Rechercher des composants dans tous les inventaires.';
      @override
  String installedVersion(String version) => 'Installée : v$version';
  @override
  String newVersion(String version) => 'Nouvelle : v$version';
  @override
  String get downloadManualGithub => 'Vous pouvez télécharger la mise à jour manuellement depuis GitHub.';
  @override
  String get openOnGithub => 'Ouvrir sur GitHub';
  @override
  String fileDownloadedTo(String path) => 'Fichier téléchargé dans : $path';
  @override
  String downloadError(String error) => 'Erreur de téléchargement : $error';

  @override
  String get noteReminder => 'Note (rappel)';
  @override
  String get columnHeader => 'Colonne';
  @override
  String get rowHeader => 'Ligne';
  @override
  String get columnHint => 'Ex : A';
  @override
  String get rowHint => 'Ex : 3';
  @override
  String get missingColumn => 'Colonne manquante';
  @override
  String get missingRow => 'Ligne manquante';
  @override
  String get positionTitle => 'Emplacement';
  @override
  String get selectTargetToConfigureTags => 'Sélectionnez un inventaire de destination pour définir les étiquettes et les propriétés.';
  @override
  String get freeTextHint => 'Texte libre';
  @override
  String get specialTagNumericHint => 'Laisser vide ou utiliser K, V, M... (ex. 1K2)';
  @override
  String get invalidNumberFormat => 'Format numérique invalide';
  @override
  String get invalidNumber => 'Invalide';
  @override
  String get attachmentsTitle => 'Pièces jointes';
  @override
  String get linkNameHint => 'Nom (ex. Fiche technique)';
  @override
  String get linkUrlHint => 'URL (https://...)';
  @override
  String get link => 'Lien';
  @override
  String get iconBadge => 'Icône';
  @override
  String configureSeparatorsForDrawer(String label, int cabinet) => 'Configurer les séparateurs pour $label (Meuble $cabinet)';
  @override
  String get selectContainerPrompt => 'Sélectionner le conteneur :';
  @override
  String selectedDrawerLabel(String drawer) => 'Sélectionné : Tiroir $drawer';
  @override
  String drawerNumber(String drawer) => 'Tiroir $drawer';
  @override
  String containerNumber(int id) => 'Conteneur $id';
  @override
  String get noDescription => 'Aucune description';
  @override
  String qtyShort(int qty) => 'Qté : $qty';
  @override
  String get appUpToDate => "L'application est à jour.";
  @override
  String appUpToDateDesc(String version) => "L'application est à jour avec la dernière version (v$version).";
  @override
  String get updateDialogDesc => 'Une nouvelle version est disponible. Voulez-vous la télécharger et l\'installer maintenant ?';
  @override
  String get updatingTitle => 'Mise à jour';
@override
  String get dragToScrollGrid => 'Faites glisser pour faire défiler la grille';
  @override
  String activeDrawersCount(int count) => '$count tiroirs actifs';
  @override
  String mergedDrawers(String drawers) => 'Tiroirs Fusionnés ($drawers)';
  @override
  String get drawerContent => 'Contenu du tiroir';
  @override
  String get emptyZoneNotice => 'Aucun composant dans cette zone (Vide)';
  @override
  String get chooseFromUnassigned => 'Choisir parmi les composants sans position';
  @override
  String get noUnassignedAvailable => 'Aucun composant sans position disponible';
  @override
  String get searchByName => 'Rechercher par nom...';
  @override
  String componentAssignedSuccess(String name) => 'Composant "$name" assigné avec succès.';
  @override
  String assignError(String error) => 'Erreur lors de l\'assignation: $error';
  @override
  String get addMainTag => 'Ajouter étiquette principale...';
  @override
  String addSubTag(String parent) => 'Ajouter dans $parent...';
  @override
  String get addComponentTitle => 'Ajouter un composant';

  // What's Changed
  @override
  String get whatsNewTitle => 'Ce qui a changé';
  @override
  String get whatsNewSubtitle => 'Modifications dans les inventaires depuis le dernier lancement';
  @override
  String get whatsNewDontShowAgain => 'Ne plus afficher cette popup au démarrage';
  @override
  String whatsNewTooltip(int count) => '$count modifications récentes dans les inventaires';
  @override
  String get whatsNewNoChanges => 'Aucune modification récente dans les inventaires';
  @override
  String get whatsNewAdded => 'Ajouté';
  @override
  String get whatsNewModified => 'Modifié';
  @override
  String get whatsNewDeleted => 'Supprimé';
  @override
  String get whatsNewComponentDeletedNotice => 'Ce composant a été supprimé de l\'inventaire';
  @override
  String whatsNewQuantityChanged(String oldQty, String newQty) => 'Quantité : $oldQty → $newQty';
  @override
  String whatsNewDrawerChanged(String oldDrawer, String newDrawer) => 'Tiroir : $oldDrawer → $newDrawer';
  @override
  String whatsNewNameChanged(String oldName, String newName) => 'Nom : $oldName → $newName';
  @override
  String get whatsNewDescriptionChanged => 'Description modifiée';
  @override
  String get whatsNewTagsChanged => 'Tags modifiés';
  @override
  String get whatsNewPropertiesChanged => 'Propriétés modifiées';
  @override
  String get whatsNewMarkAsRead => 'Marquer comme lu';
  @override
  String get whatsNewSettingTitle => 'Afficher "Ce qui a changé" au démarrage';
  @override
  String get whatsNewSettingSubtitle => 'Si désactivé, une icône apparaît dans la barre supérieure quand il y a des changements';
  @override
  String get whatsNewViewRecentChanges => 'Voir les modifications récentes';
  @override
  String whatsNewChangesCount(int count) => '$count modifications';
}
