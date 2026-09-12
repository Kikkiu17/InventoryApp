import 'app_localizations.dart';

class AppLocalizationsEs extends AppLocalizations {
  @override
  String get appName => 'Inventario de Componentes';
  @override
  String get ok => 'Aceptar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get save => 'Guardar';
  @override
  String get delete => 'Eliminar';
  @override
  String get edit => 'Editar';
  @override
  String get add => 'Añadir';
  @override
  String get close => 'Cerrar';
  @override
  String get apply => 'Aplicar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get error => 'Error';
  @override
  String get warning => 'Advertencia';
  @override
  String get success => 'Operación exitosa';
  @override
  String get search => 'Buscar';
  @override
  String get loading => 'Cargando...';
  @override
  String get nameLabel => 'Nombre';
  @override
  String get options => 'Opciones';
  @override
  String get details => 'Detalles';
  @override
  String get actions => 'Acciones';
  @override
  String get select => 'Seleccionar';
  @override
  String get none => 'Ninguno';
  @override
  String get all => 'Todos';
  @override
  String get yes => 'Sí';
  @override
  String get no => 'No';
  @override
  String get check => 'Comprobar';

  // Navigation / Tabs
  @override
  String get tabInventory => 'Inventario';
  @override
  String get tabBuffer => 'Búfer';
  @override
  String get tabInventories => 'Inventarios';
  @override
  String get tabFiles => 'Archivos';
  @override
  String get tabSettings => 'Ajustes';

  // Home Screen
  @override
  String get viewList => 'Lista';
  @override
  String get viewMap => 'Mapa';
  @override
  String get searchPlaceholder => 'Buscar componentes...';
  @override
  String get searchTooltip => 'Buscar';
  @override
  String get sortTitle => 'Ordenar por';
  @override
  String get sortNone => 'Sin ordenar';
  @override
  String get sortName => 'Nombre';
  @override
  String get sortQuantity => 'Cantidad';
  @override
  String get sortDrawer => 'Cajón';
  @override
  String get sortAscending => 'Orden: Ascendente';
  @override
  String get sortDescending => 'Orden: Descendente';
  @override
  String get filterAll => 'Todos los cajones';
  @override
  String get filterUnassigned => 'Sin asignar';
  @override
  String get filterCabinet => 'Contenedor';
  @override
  String get clearFilters => 'Restablecer filtros';
  @override
  String get filterByTag => 'Filtrar por etiqueta';
  @override
  String get filterByProperty => 'Filtrar por propiedad';
  @override
  String get exportPdfTooltip => 'Exportar lista a PDF';
  @override
  String get exportPdfTitle => 'Inventario de Componentes';
  @override
  String get colName => 'Nombre';
  @override
  String get colPosition => 'Posición';
  @override
  String get colQuantity => 'Cant.';
  @override
  String get colDetails => 'Detalles';
  @override
  String get unassignedPosition => 'Sin asig.';
  @override
  String get exportSuccess => 'PDF exportado con éxito';
  @override
  String get exportError => 'Error al exportar PDF';
  @override
  String get serverConnected => 'Servidor conectado';
  @override
  String get serverDisconnected => 'Servidor desconectado';
  @override
  String get switchInventory => 'Cambiar';
  @override
  String get selectInventory => 'Seleccionar Inventario';
  @override
  String get drawerTitle => 'Cajón';
  @override
  String get emptyDrawer => 'No hay componentes en este cajón';
  @override
  String get addComponentHere => 'Añadir componente aquí';
  @override
  String get configureDrawer => 'Configurar cajón';
  @override
  String get bulkActions => 'Acciones en grupo';
  @override
  String get bulkMove => 'Mover seleccionados';
  @override
  String get bulkDelete => 'Eliminar seleccionados';
  @override
  String get bulkAddTag => 'Añadir etiqueta a seleccionados';
  @override
  String get bulkRemoveTag => 'Quitar etiqueta de seleccionados';
  @override
  String get selectedComponents => 'componentes seleccionados';
  @override
  String get deleteComponentTitle => 'Eliminar componente';
  @override
  String deleteComponentConfirm(String name) =>
      '¿Estás seguro de que deseas eliminar "$name"?';
  @override
  String get noComponentsFound => 'No se encontraron componentes';
  @override
  String errorChangingInventory(String error) =>
      'Error al cambiar de inventario: $error';
  @override
  String errorSaving(String error) => 'Error al guardar: $error';
  @override
  String errorDeleting(String error) => 'Error al eliminar: $error';

  // Buffer Screen
  @override
  String get bufferTitle => 'Búfer';
  @override
  String get searchBufferPlaceholder => 'Buscar en el búfer...';
  @override
  String get allBags => 'Todos';
  @override
  String get unassignedBag => 'Sin bolsa';
  @override
  String get addBag => 'Nueva bolsa';
  @override
  String get deleteBag => 'Eliminar bolsa';
  @override
  String get bagName => 'Nombre de la bolsa';
  @override
  String get renameBag => 'Renombrar bolsa';
  @override
  String get emptyBufferTitle => 'Búfer vacío';
  @override
  String get emptyBufferSubtitle =>
      'Los componentes aún no guardados en cajones aparecerán aquí.';
  @override
  String get moveToDrawer => 'Asignar cajón';
  @override
  String get addComponentToBuffer => 'Añadir al búfer';
  @override
  String get bulkMoveToDrawer => 'Asignar a cajón';
  @override
  String deleteBagConfirm(String bag) =>
      '¿Eliminar la bolsa "$bag"? Los componentes permanecerán en el búfer.';
  @override
  String get newBagTitle => 'Nueva Bolsa';

  // Inventory List Screen
  @override
  String get inventoriesTitle => 'Inventarios';
  @override
  String get searchAllInventoriesPlaceholder => 'Buscar en todos los inventarios…';
  @override
  String get localInventory => 'Inventario Local';
  @override
  String get remoteInventory => 'Remoto';
  @override
  String get currentBadge => 'ACTUAL';
  @override
  String itemsCount(int count) => '$count componentes';
  @override
  String get newInventoryTitle => 'Nuevo Inventario';
  @override
  String get inventoryName => 'Nombre del inventario';
  @override
  String get create => 'Crear';
  @override
  String get deleteInventoryTitle => 'Eliminar inventario';
  @override
  String deleteInventoryConfirm(String name) =>
      '¿Estás seguro de que deseas eliminar el inventario "$name"? Esta acción no se puede deshacer.';
  @override
  String get syncNow => 'Sincronizar ahora';
  @override
  String get syncSuccess => 'Sincronización completada';
  @override
  String get syncError => 'Error de sincronización';
  @override
  String get restoreBackup => 'Restaurar copia';
  @override
  String get noResults => 'Sin resultados';
  @override
  String noResultsDescription(String query) =>
      'Ningún componente o inventario coincide con "$query".';
  @override
  String get bufferComponentsCategory => 'COMPONENTES EN BÚFER';

  // Files Screen
  @override
  String get filesTitle => 'Archivos y Adjuntos';
  @override
  String get searchFilesPlaceholder => 'Buscar archivos...';
  @override
  String get allFiles => 'Todos los archivos';
  @override
  String get componentFiles => 'Archivos de componentes';
  @override
  String get noFiles => 'No hay archivos';
  @override
  String get shareFile => 'Compartir';
  @override
  String get deleteFile => 'Eliminar archivo';
  @override
  String deleteFileConfirm(String fileName) =>
      '¿Estás seguro de que deseas eliminar "$fileName"?';
  @override
  String get fileSize => 'Tamaño';
  @override
  String get openFileError => 'No se puede abrir el archivo';

  // Settings Screen
  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get saveSettings => 'Guardar';
  @override
  String get sectionRemoteServer => 'Servidor remoto';
  @override
  String get sectionAppearance => 'Apariencia';
  @override
  String get sectionLanguage => 'Idioma';
  @override
  String get sectionContainers => 'Configuración de contenedores (cajones)';
  @override
  String get sectionTagTree => 'Árbol de Etiquetas';
  @override
  String get sectionGenericTags => 'Etiquetas Genéricas';
  @override
  String get sectionProperties => 'Propiedades con valor';
  @override
  String get sectionData => 'Datos';
  @override
  String get sectionAbout => 'Información y actualizaciones';
  @override
  String get useRemoteServer => 'Usar servidor remoto';
  @override
  String get serverConnectedStatus => '✅ Conectado';
  @override
  String get serverDisconnectedStatus => '❌ No conectado';
  @override
  String get localStorageStatus => 'Almacenamiento local';
  @override
  String get serverUrl => 'URL del servidor';
  @override
  String get testConnection => 'Probar conexión';
  @override
  String get connectionSuccess => '¡Conexión establecida con éxito!';
  @override
  String get connectionFailed => 'No se pudo conectar al servidor';
  @override
  String get themeMode => 'Tema de la app';
  @override
  String get themeSystem => 'Sistema';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';
  @override
  String get languageLabel => 'Idioma de la app';
  @override
  String get languageSystem => 'Predeterminado del sistema';
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
      'Gestiona contenedores físicos. Cada contenedor puede tener dimensiones y formas personalizadas desactivando cajones en la vista previa.';
  @override
  String get newContainer => 'Añadir contenedor';
  @override
  String get containerName => 'Nombre del contenedor';
  @override
  String get rows => 'Filas';
  @override
  String get columns => 'Columnas';
  @override
  String get invertRows => 'Invertir filas (de abajo a arriba)';
  @override
  String get invertColumns => 'Invertir columnas (de derecha a izquierda)';
  @override
  String get previewAndShape => 'Vista previa y forma';
  @override
  String get drawerGridHint =>
      'Vista previa (haz clic para configurar, mantén presionado y arrastra para seleccionar en lote)';
  @override
  String get deleteContainer => 'Eliminar contenedor';
  @override
  String get drawerConfigTitle => 'Configuración del cajón';
  @override
  String get drawerDisabled => 'Cajón desactivado';
  @override
  String get drawerZones => 'Zonas / Divisores';
  @override
  String get mergeDrawers => 'Unir cajones';
  @override
  String get splitDrawers => 'Separar cajones';
  @override
  String get tagTreeDesc =>
      'Crea categorías y subcategorías escribiendo en el campo y pulsando Enter.';
  @override
  String get genericTagsDesc =>
      'Etiquetas genéricas sin jerarquía para clasificar rápidamente los componentes.';
  @override
  String get newGenericTag => 'Nueva etiqueta genérica';
  @override
  String get addTag => 'Añadir';
  @override
  String deleteTagConfirm(String tag) => '¿Eliminar la etiqueta "$tag"?';
  @override
  String get propertiesDesc =>
      'Define propiedades numéricas o de texto. Arrastra para reordenarlas.';
  @override
  String get propName => 'Nombre';
  @override
  String get propUnit => 'Unidad';
  @override
  String get propSigla => 'Sigla';
  @override
  String get propSiglaHint => 'ej. L';
  @override
  String get propText => 'Texto';
  @override
  String get addProp => 'Añadir';
  @override
  String get noPropsConfigured => 'No hay propiedades configuradas.';
  @override
  String get editPropTitle => 'Modificar propiedad';
  @override
  String get propUnitLabel => 'Unidad';
  @override
  String get propTextFree => 'Texto libre';
  @override
  String deletePropConfirm(String name) => '¿Eliminar la propiedad "$name"?';
  @override
  String get dataBackupDesc => 'Gestión de copias de seguridad y exportación';
  @override
  String get exportJson => 'Exportar copia local (JSON)';
  @override
  String get importJson => 'Restaurar desde archivo JSON';
  @override
  String get restoreRemoteBackup => 'Restaurar copia remota';
  @override
  String get backupCreated => 'Copia de seguridad creada con éxito';
  @override
  String get checkUpdates => 'Buscar actualizaciones';
  @override
  String get checkUpdatesSubtitle =>
      'Comprobar y descargar la última versión desde GitHub';
  @override
  String get openGitHub => 'Abrir página de GitHub';
  @override
  String get appVersion => 'Versión de la app';
  @override
  String get manualDrawerConfigTitle =>
      'Configurar cajón por coordenadas (para cajones no visibles en la vista previa)';
  @override
  String get manualDrawerCode => 'Código del cajón';
  @override
  String get manualDrawerHint => 'Ej: A20 o K4';
  @override
  String get configureButton => 'Configurar';
  @override
  String get noGenericTags => 'No hay etiquetas genéricas.';
  @override
  String get settingsSaved => 'Ajustes guardados';
  @override
  String get activeInventory => 'Inventario activo';
  @override
  String get enableAll => 'Activar todos';
  @override
  String get disableAll => 'Desactivar todos';
  @override
  String get enabled => 'Habilitado';
  @override
  String get divideIntoZones => 'Dividir en zonas';
  @override
  String get restoreBackupTitle => 'Restaurar copia';
  @override
  String get confirmRestoreTitle => 'Confirmar restauración';
  @override
  String get confirmRestoreMsg =>
      '¿Sobrescribir los datos actuales? (Se creará una copia de seguridad automática primero).';
  @override
  String get restoreSuccess => 'Copia restaurada con éxito';
  @override
  String get noBackupsFound => 'No se encontraron copias de seguridad';
  @override
  String bulkDrawerAction(int count) => 'Acción en lote ($count cajones)';
  @override
  String get bulkDrawerActionDesc =>
      '¿Qué deseas hacer con los cajones seleccionados?\nPuedes desactivarlos, activarlos, definir zonas o unirlos/dividirlos.';
  @override
  String get setZones => 'Definir zonas...';
  @override
  String zonesCount(int count) => '$count zonas';
  @override
  String get noDividers => 'Sin separadores (1 zona)';
  @override
  String get filterRemoveAll => 'Eliminar todos';
  @override
  String get filterOnlyUnassigned => 'Mostrar solo componentes sin ubicación';
  @override
  String get filterOnlyUnassignedDesc =>
      'Oculta los componentes que ya tienen un cajón asignado';
  @override
  String get quickTags => 'Etiquetas rápidas';
  @override
  String get cabinetContainer => 'Contenedor / Mueble';
  @override
  String get navigateTagTree => 'Navegar en etiquetas';
  @override
  String get tagTreeRoot => 'Inicio';
  @override
  String get noSubtags => 'No hay subetiquetas disponibles.';
  @override
  String get propertyFilters => 'Filtros por Propiedad';
  @override
  String get containsText => 'Contiene texto...';
  @override
  String get exactValue => 'Valor exacto';
  @override
  String get fromMin => 'Desde (mín)';
  @override
  String get toMax => 'Hasta (máx)';
  @override
  String get applyFilters => 'Aplicar filtros';
  @override
  String get selectedTagsLabel => 'Etiquetas seleccionadas';
  @override
  String get invalidDrawerCoords =>
      'Coordenadas de cajón no válidas para las dimensiones actuales del mueble';
  @override
  String get moveAction => 'Mover';
  @override
  String get selectTargetInventory => 'Selecciona inventario de destino';
  @override
  String componentMovedSuccess(String targetName) =>
      'Componente movido a "$targetName"';
  @override
  String get errorMovingComponent => 'Error al mover el componente';
  @override
  String get addAttachmentLink => 'Enlace';
  @override
  String get addAttachmentFile => 'Subir Archivo';
  @override
  String get addAttachmentExisting => 'Archivo Existente';
  @override
  String get takePhotoNow => 'Hacer Foto Ahora';
  @override
  String get chooseFromGallery => 'Elegir de la Galería';
  @override
  String get addPhoto => 'Añadir Foto';
  @override
  String get renameFile => 'Renombrar archivo';
  @override
  String get filesFound => 'archivos encontrados';
  @override
  String get fileOptions => 'Opciones';
  @override
  String get rename => 'Renombrar';
  @override
  String get notAssigned => 'No asignado';
  @override
  String get selectFromMap => 'Seleccionar desde el mapa';
  @override
  String changeDrawerSeparators(int zones) =>
      'Modificar separadores ($zones zonas)';
  @override
  String get configureDrawerSeparators =>
      'Configurar separadores (cajón normal)';
  @override
  String get zoneSeparatorLabel => 'Zona del cajón (Separador)';

  // Component Dialog
  @override
  String get newComponentTitle => 'Nuevo Componente';
  @override
  String get editComponentTitle => 'Editar Componente';
  @override
  String get duplicateComponentTitle => 'Duplicar Componente';
  @override
  String get compNameLabel => 'Nombre';
  @override
  String get compNameError => 'Introduce un nombre';
  @override
  String get compDescLabel => 'Descripción o notas';
  @override
  String get compQtyLabel => 'Cantidad';
  @override
  String get compCabinetLabel => 'Contenedor';
  @override
  String get compDrawerLabel => 'Cajón';
  @override
  String get compZoneLabel => 'Zona del cajón';
  @override
  String get tagsSectionTitle => 'Etiquetas y Categorías';
  @override
  String get selectTreeTags => 'Árbol de etiquetas';
  @override
  String get selectGenericTags => 'Etiquetas genéricas';
  @override
  String get showGenericTags => 'Mostrar etiquetas genéricas';
  @override
  String get hideGenericTags => 'Ocultar etiquetas genéricas';
  @override
  String get propertiesSectionTitle => 'Propiedades';
  @override
  String get addCustomProperty => 'Añadir propiedad';
  @override
  String get imagesSectionTitle => 'Imágenes y Adjuntos';
  @override
  String get addImage => 'Añadir imagen';
  @override
  String get camera => 'Cámara';
  @override
  String get gallery => 'Galería';
  @override
  String get removeImage => 'Eliminar';
  @override
  String get keepInBuffer => 'Mantener en el búfer';
  @override
  String get assignToDrawer => 'Asignar cajón';
  @override
  String get saveButton => 'Guardar';
  @override
  String get cancelButton => 'Cancelar';
  @override
  String get deleteButton => 'Eliminar';
  @override
  String get draftSaved => 'Borrador guardado';
  @override
  String get draftRestored => 'Borrador restaurado';

  // Component View Dialog
  @override
  String get componentDetailsTitle => 'Detalles del Componente';
  @override
  String get quantityLabel => 'Cantidad:';
  @override
  String get locationLabel => 'Ubicación:';
  @override
  String get drawerLabel => 'Cajón:';
  @override
  String get cabinetLabel => 'Contenedor:';
  @override
  String get zoneLabel => 'Zona:';
  @override
  String get tagsLabel => 'Etiquetas:';
  @override
  String get propertiesLabel => 'Propiedades:';
  @override
  String get notesLabel => 'Notas:';
  @override
  String get attachedFilesLabel => 'Adjuntos:';
  @override
  String get editAction => 'Editar';
  @override
  String get duplicateAction => 'Duplicar';
  @override
  String get moveToBufferAction => 'Mover al búfer';
  @override
  String get printLabelAction => 'Imprimir etiqueta';
  @override
  String get deleteAction => 'Eliminar';
  @override
  String confirmDeleteMsg(String name) =>
      '¿Estás seguro de que deseas eliminar "$name"?';

  // Drawer Picker Dialog
  @override
  String get selectDrawerTitle => 'Seleccionar Cajón';
  @override
  String get searchDrawerPlaceholder => 'Filtrar cajón...';
  @override
  String get selectZone => 'Zona:';
  @override
  String cabinetTab(int id, String name) =>
      name.isNotEmpty ? name : 'Contenedor $id';

  // Update Service
  @override
  String get updateAvailableTitle => 'Actualización disponible';
  @override
  String updateAvailableDesc(String version) =>
      'Hay una nueva versión disponible ($version). ¿Deseas descargarla ahora?';
  @override
  String get updateNowButton => 'Actualizar ahora';
  @override
  String get laterButton => 'Más tarde';
  @override
  String get dontShowAgain => 'No volver a mostrar al inicio';
  @override
  String get releaseNotes => 'Notas de la versión';
  @override
  String get downloadingUpdate => 'Descargando actualización...';
  @override
  String get installUpdate => 'Instalar actualización';
  @override
  String get updateError => 'Error durante la actualización';
  @override
  String get noUpdateAvailable => 'La aplicación ya está actualizada a la última versión.';

  // Conflicts
  @override
  String get conflictTitle => 'Conflicto de sincronización';
  @override
  String get conflictDesc =>
      'Los datos remotos han sido modificados tras la última sincronización local. Elige qué versión conservar.';
  @override
  String get useLocal => 'Conservar local';
  @override
  String get useRemote => 'Conservar remoto';
  @override
  String get compare => 'Comparar';

  @override
  String get selectCabinetLabel => 'Seleccionar contenedor:';
  @override
  String get tapDrawerToSelect => 'Toca un cajón para seleccionarlo';
  @override
  String drawerSelected(String label, [int? zone]) =>
      'Seleccionado: Cajón $label${zone != null ? " (Zona $zone)" : ""}';
  @override
  String get noContainersConfigured =>
      'No hay contenedores configurados en los ajustes.';
  @override
  String get offlineUsingLocal => 'Desconectado · usando datos locales';
  @override
  String get switchButton => 'Cambiar';
  @override
  String get sync => 'Sincronizar';
  @override
  String get sortBy => 'Por';
  @override
  String resultsCount(int count) => '$count resultados';
  @override
  String componentsCount(int count) => '$count componentes';
  @override
  String updateAvailableBadge(String version) =>
      'Actualización disponible (v$version)';
  @override
  String get updateAvailableQuestion =>
      'Hay una nueva versión disponible. ¿Deseas descargarla e instalarla ahora?';
  @override
  String get positionLabel => 'Posición';
  @override
  String get targetInventoryLabel => 'Inventario de destino';
  @override
  String get noneToSelect => 'Ninguno (Por seleccionar)';
  @override
  String get rowLabel => 'Fila';
  @override
  String get columnLabel => 'Columna';
  @override
  String get requiredField => 'Obligatorio';
  @override
  String get disabledDrawer => 'Desactivado';
  @override
  String get savePosition => 'Guardar Posición';
  @override
  String get placeAction => 'Colocar';
  @override
  String placeComponentSuccess(String name) =>
      '¡"$name" colocado con éxito!';
  @override
  String get cannotOpenLink => 'No se puede abrir el enlace';
  @override
  String get cannotOpenFile => 'No se puede abrir el archivo';
  @override
  String get refreshList => 'Actualizar lista';
  @override
  String get localModeTitle => 'Modo local';
  @override
  String get localModeDesc =>
      'Habilita el servidor remoto en Ajustes para gestionar múltiples inventarios.';
  @override
  String get serverUnreachableTitle => 'Servidor no accesible';
  @override
  String get serverUnreachableDesc =>
      'Comprueba tu conexión y la dirección del servidor.';
  @override
  String get retry => 'Reintentar';
  @override
  String get noInventoriesTitle => 'No hay inventarios';
  @override
  String get noInventoriesDesc =>
      'Crea tu primer inventario para comenzar.';
  @override
  String get createInventory => 'Crear inventario';
  @override
  String get inventoryAlreadyActive => 'Inventario ya activo';
  @override
  String switchedToInventory(String name) => 'Cambiado a "$name"';
  @override
  String get deleteInventoryPermanentWarning =>
      'Todos los componentes se eliminarán definitivamente.';
  @override
  String get activeBadge => 'Activo';
  @override
  String get uploadedFilesTitle => 'Archivos Subidos';
  @override
  String filesFoundCount(int count) => '$count archivos encontrados';
  @override
  String get noFilesFound => 'No se encontraron archivos';
  @override
  String get searchFilesPlaceholderLong => 'Buscar archivo o componente...';
  @override
  String deleteAttachmentConfirm(String name) =>
      '¿Deseas eliminar definitivamente "$name"?';
  @override
  String get deleteImageTitle => 'Eliminar imagen';
  @override
  String get deleteFileTitle => 'Eliminar archivo';
  @override
  String get componentPrefix => 'Componente';

  @override
  String get zoneNearLabel => 'Cercana (frente)';
  @override
  String get zoneFarLabel => 'Lejana (fondo)';
  @override
  String get zoneMiddleLabel => 'En medio';
  @override
  String zoneMiddleIndex(int index) => 'En medio ($index)';

  @override
  String deleteBufferComponentConfirm(String name) =>
      '¿Estás seguro de que deseas eliminar "$name" del búfer?';
  @override
  String assignedDestination(String target) => 'Destino asignado: $target';
  @override
  String get destinationUnspecified => 'Destino no especificado';
  @override
  String get noDestination => 'Sin destino';
  @override
  String get emptyBufferDesc =>
      'Agrega componentes para registrarlos temporalmente antes de colocarlos.';
  @override
  String get noBufferResultsDesc =>
      'Ningún componente en el búfer coincide con tu búsqueda.';
  @override
  String placeItemDialogTitle(String name) => 'Colocar "$name"';
  @override
  String get placeItemDialogDesc =>
      'Especifica la ubicación física para mover el componente del búfer al inventario.';
  @override
  String destinationLabel(String target) => 'Destino: $target';
  @override
  String get changeDestinationAndTags => 'Cambiar destino (y etiquetas)';
  @override
  String maxColumnLabel(String col) => 'Columna máx.: $col';
  @override
  String maxRowLabel(int row) => 'Fila máx.: $row';
  @override
  String get drawerZoneSeparator => 'Zona del cajón (Separador)';
  @override
  String get selectTargetInventoryFirst =>
      'Selecciona primero un inventario de destino.';
  @override
  String get setDestinationAndTags => 'Establecer destino y etiquetas';

  @override
  String get clear => 'Borrar';
  @override
  String get newInventory => 'Nuevo inventario';
  @override
  String searchError(String error) => 'Error en la búsqueda: $error';
  @override
  String noMatchesForQuery(String query) =>
      'Ningún componente o inventario coincide con "$query".';
  @override
  String get inventoriesSectionHeader => 'INVENTARIOS';
  @override
  String get inventoryComponentsSectionHeader => 'COMPONENTES DE INVENTARIOS';
  @override
  String get bufferComponentsSectionHeader => 'COMPONENTES DEL BÚFER';
  @override
  String get nameRequired => 'Nombre *';
  @override
  String get descriptionOptional => 'Descripción (opcional)';
  @override
  String inventoryCreatedAndSelected(String name) =>
      '"$name" creado y seleccionado';
  @override
  String get renameInventoryTitle => 'Renombrar inventario';
  @override
  String get renameAction => 'Renombrar';

  @override
  String get cannotOpenLocalFile => 'No se puede abrir el archivo local';
  @override
  String get renameFileTitle => 'Renombrar archivo';
  @override
  String deleteAttachmentPermanentConfirm(String name) =>
      '¿Deseas eliminar definitivamente "$name"?';
  @override
  String get searchFileOrComponentPlaceholder =>
      'Buscar archivo o componente...';

  @override
  String get deleteComponentConfirmMsg =>
      '¿Estás seguro de que deseas eliminar este componente?';
  @override
  String get loadingTags => 'Cargando etiquetas...';
  @override
  String get selectedTagsTitle => 'Etiquetas seleccionadas';
  @override
  String get treeRoot => 'Inicio';
  @override
  String get noSubtagsAvailable => 'No hay subetiquetas disponibles.';
  @override
  String get showGenericLooseTags => 'Mostrar etiquetas genéricas (sueltas)';
  @override
  String get addLinkTitle => 'Agregar enlace';
  @override
  String get uploadFileLabel => 'Subir archivo';
  @override
  String get existingFileLabel => 'Archivo existente';
  @override
  String get noExistingFiles => 'Sin archivos existentes';
  @override
  String get chooseExistingFile => 'Elegir archivo existente';
  @override
  String get selectFromGallery => 'Seleccionar de la galería';
  @override
  String get divideDrawerInZones => 'Dividir cajón en zonas';
  @override
  String get divideDrawerSubtitle =>
      'Permite colocar hasta 3 componentes separados en el mismo cajón';
  @override
  String get moveToAnotherInventory => 'Mover a otro inventario';
  @override
  String get moveComponentTitle => 'Mover componente';
  @override
  String selectDestinationInventoryFor(String name) =>
      'Selecciona el inventario de destino para "$name":';
  @override
  String componentMovedTo(String name) => 'Componente movido a "$name"';
  @override
  String errorDuringMove(String error) =>
      'Error durante el movimiento: $error';
  @override
  String get unassignedDrawerShort => 'Sin\nasg.';
  @override
  String get newComponent => 'Nuevo componente';
  @override
  String get createFromScratchAndInsert =>
      'Crear desde cero e insertar en esta posición';
  @override
  String get assignExisting => 'Asignar existente';
  @override
  String get assignExistingComponentTitle => 'Asignar componente existente';
  @override
  String get passedToBuffer => 'Movido al búfer';
  @override
  String get editComponentDirectlyFromList =>
      'Edita el componente directamente desde la lista.';
  @override
  String get searchInAllInventories =>
      'Buscar componentes en todos los inventarios.';
      @override
  String installedVersion(String version) => 'Instalada: v$version';
  @override
  String newVersion(String version) => 'Nueva: v$version';
  @override
  String get downloadManualGithub => 'Puedes descargar la actualización manualmente desde GitHub.';
  @override
  String get openOnGithub => 'Abrir en GitHub';
  @override
  String fileDownloadedTo(String path) => 'Archivo descargado en: $path';
  @override
  String downloadError(String error) => 'Error de descarga: $error';

  @override
  String get noteReminder => 'Nota (recordatorio)';
  @override
  String get columnHeader => 'Columna';
  @override
  String get rowHeader => 'Fila';
  @override
  String get columnHint => 'Ej: A';
  @override
  String get rowHint => 'Ej: 3';
  @override
  String get missingColumn => 'Falta columna';
  @override
  String get missingRow => 'Falta fila';
  @override
  String get positionTitle => 'Ubicación';
  @override
  String get selectTargetToConfigureTags => 'Selecciona un inventario de destino para configurar etiquetas y propiedades.';
  @override
  String get freeTextHint => 'Texto libre';
  @override
  String get specialTagNumericHint => 'Dejar vacío o usar K, V, M... (ej. 1K2)';
  @override
  String get invalidNumberFormat => 'Formato numérico no válido';
  @override
  String get invalidNumber => 'No válido';
  @override
  String get attachmentsTitle => 'Archivos adjuntos';
  @override
  String get linkNameHint => 'Nombre (ej. Ficha técnica)';
  @override
  String get linkUrlHint => 'URL (https://...)';
  @override
  String get link => 'Enlace';
  @override
  String get iconBadge => 'Icono';
  @override
  String configureSeparatorsForDrawer(String label, int cabinet) => 'Configurar separadores para $label (Cajonera $cabinet)';
  @override
  String get selectContainerPrompt => 'Seleccionar contenedor:';
  @override
  String selectedDrawerLabel(String drawer) => 'Seleccionado: Cajón $drawer';
  @override
  String drawerNumber(String drawer) => 'Cajón $drawer';
  @override
  String containerNumber(int id) => 'Contenedor $id';
  @override
  String get noDescription => 'Sin descripción';
  @override
  String qtyShort(int qty) => 'Cant.: $qty';
  @override
  String get appUpToDate => 'La aplicación está actualizada a la última versión.';
  @override
  String appUpToDateDesc(String version) => 'La aplicación está actualizada a la última versión (v$version).';
  @override
  String get updateDialogDesc => 'Hay una nueva versión disponible. ¿Deseas descargarla e instalarla ahora?';
  @override
  String get updatingTitle => 'Actualización';
@override
  String get dragToScrollGrid => 'Arrastra para mover la cuadrícula';
  @override
  String activeDrawersCount(int count) => '$count cajones activos';
  @override
  String mergedDrawers(String drawers) => 'Cajones Unidos ($drawers)';
  @override
  String get drawerContent => 'Contenido del cajón';
  @override
  String get emptyZoneNotice => 'Ningún componente en esta zona (Vacía)';
  @override
  String get chooseFromUnassigned => 'Elegir entre componentes sin posición';
  @override
  String get noUnassignedAvailable => 'No hay componentes sin posición disponibles';
  @override
  String get searchByName => 'Buscar por nombre...';
  @override
  String componentAssignedSuccess(String name) => 'Componente "$name" asignado con éxito.';
  @override
  String assignError(String error) => 'Error durante la asignación: $error';
  @override
  String get addMainTag => 'Añadir etiqueta principal...';
  @override
  String addSubTag(String parent) => 'Añadir en $parent...';
  @override
  String get addComponentTitle => 'Añadir componente';
}
