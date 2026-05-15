import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/inventory_list_screen.dart';

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
    return MaterialApp(
      title: 'Inventario Componenti',
      debugShowCheckedModeBanner: false,
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

    // Le pagine sono ricreate per permettere l'aggiornamento della tab inventari
    final pages = [
      const HomeScreen(),
      const InventoryListScreen(),
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
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
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
            label: 'Inventari',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}
