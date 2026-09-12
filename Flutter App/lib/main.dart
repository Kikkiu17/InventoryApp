import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/data_service.dart';
import 'screens/home_screen.dart';
import 'screens/buffer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/files_screen.dart';
import 'widgets/component_dialog.dart';
import 'models/component.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ds = DataService();
  await ds.load();
  runApp(
    ChangeNotifierProvider.value(
      value: ds,
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      locale: ds.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ds.themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: MainShell(key: globalMainShellKey),
    );
  }
}

final GlobalKey<MainShellState> globalMainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDraftIfNeeded();
    });
  }

  Future<void> _restoreDraftIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('pending_component_draft');
    if (draftStr == null) return;

    final Map<String, dynamic> draft = jsonDecode(draftStr);

    // Check for lost data from image_picker
    final picker = ImagePicker();
    final lostData = await picker.retrieveLostData();
    if (!lostData.isEmpty && lostData.file != null) {
      final List<String> images = List<String>.from(draft['images'] ?? []);
      images.add(lostData.file!.path);
      draft['images'] = images;
      // Save again with new image
      await prefs.setString('pending_component_draft', jsonEncode(draft));
    }

    if (!mounted) return;

    final ds = Provider.of<DataService>(context, listen: false);

    // Find existing component if we were editing
    Component? existing;
    final existingId = draft['existingId'];
    final isBuffer = draft['isBuffer'] == true;
    if (existingId != null) {
      final list = isBuffer ? ds.bufferComponents : ds.components;
      existing = list.firstWhere(
        (c) => c.id == existingId,
        orElse: () => Component(id: existingId, name: draft['name'] ?? '', drawer: ''),
      );
    }

    // Show dialog
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => ComponentDialog(
        existing: existing,
        settings: ds.settings,
        isDuplicate: draft['isDuplicate'] ?? false,
        bagName: draft['bagName'],
        isBuffer: isBuffer,
        prefilledCabinet: draft['prefilledCabinet'],
        prefilledDrawer: draft['prefilledDrawer'],
        prefilledDrawerZone: draft['prefilledDrawerZone'],
        draft: draft,
      ),
    );

    // Process result
    if (result is Component) {
      try {
        if (isBuffer) {
          if (existing != null) {
            await ds.updateBufferComponent(result);
          } else {
            await ds.addBufferComponent(result);
          }
        } else {
          if (existing != null && draft['isDuplicate'] != true) {
            await ds.updateComponent(result);
          } else {
            await ds.addComponent(result);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorSaving(e.toString()))),
          );
        }
      }
    } else if (result == 'DELETE' && existing != null) {
      try {
        if (isBuffer) {
          await ds.deleteBufferComponent(existing.id);
        } else {
          await ds.deleteComponent(existing.id);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorDeleting(e.toString()))),
          );
        }
      }
    }

    // Clear draft
    await prefs.remove('pending_component_draft');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void switchTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // paused: l'app va in background, detached: l'app viene chiusa
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      context.read<DataService>().createBackup();
    } else if (state == AppLifecycleState.resumed) {
      // Sincronizza quando l'app torna in primo piano
      context.read<DataService>().refreshFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final l10n = context.l10n;

    // Le pagine sono ricreate per permettere l'aggiornamento della tab inventari
    final pages = [
      const HomeScreen(),
      const BufferScreen(),
      const InventoryListScreen(),
      const FilesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l10n.tabInventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_bag_outlined),
            selectedIcon: const Icon(Icons.shopping_bag),
            label: l10n.tabBuffer,
          ),
          NavigationDestination(
            icon: Badge(
              // Mostra badge se ci sono più inventari disponibili
              isLabelVisible: ds.isRemote && ds.inventories.length > 1,
              label: Text('${ds.inventories.length}'),
              child: const Icon(Icons.folder_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: ds.isRemote && ds.inventories.length > 1,
              label: Text('${ds.inventories.length}'),
              child: const Icon(Icons.folder),
            ),
            label: l10n.tabInventories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.attachment_outlined),
            selectedIcon: const Icon(Icons.attachment),
            label: l10n.tabFiles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
