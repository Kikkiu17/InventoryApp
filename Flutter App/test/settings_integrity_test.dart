import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/settings.dart';
import 'package:inventario/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DataService.ensureSettingsIntegrity', () {
    test('expands container dimensions if components exceed them', () {
      final ds = DataService();
      final comps = [
        Component(
          id: 'c1',
          name: 'Vite L15',
          cabinet: 1,
          drawer: 'L15',
        ),
      ];

      final defaultEmptySettings = AppSettings(
        containers: [
          ContainerConfig(id: 1, name: '', rows: 4, columns: 6),
        ],
      );

      final healed = ds.ensureSettingsIntegrity(defaultEmptySettings, comps);
      expect(healed.containers.first.rows, greaterThanOrEqualTo(15));
      expect(healed.containers.first.columns, greaterThanOrEqualTo(12));
    });

    test('restores drawerDividers from components with drawerZone', () {
      final ds = DataService();
      final comps = [
        Component(
          id: 'c1',
          name: 'Dado F10 z5',
          cabinet: 1,
          drawer: 'F10',
          drawerZone: 5,
        ),
        Component(
          id: 'c2',
          name: 'Rondella A2 z3',
          cabinet: 1,
          drawer: 'A2',
          drawerZone: 3,
        ),
        Component(
          id: 'c3',
          name: 'Vite B2 z1',
          cabinet: 1,
          drawer: 'B2',
          drawerZone: 1,
        ),
      ];

      final emptySettings = AppSettings(drawerDividers: {});
      final healed = ds.ensureSettingsIntegrity(emptySettings, comps);

      expect(healed.drawerDividers['1_F10'], 5);
      expect(healed.drawerDividers['1_A2'], 3);
      expect(healed.drawerDividers['1_B2'], 2);
    });

    test('preserves and gathers all component tags and special properties', () {
      final ds = DataService();
      final comps = [
        Component(
          id: 'c1',
          name: 'Componente Test',
          cabinet: 1,
          drawer: 'A1',
          tags: ['vite', 'inox', 'M3'],
          specialTagValues: {
            'diametro': '3',
            'lunghezza': '20',
          },
        ),
      ];

      final emptySettings = AppSettings(
        availableTags: [],
        specialTags: [],
      );

      final healed = ds.ensureSettingsIntegrity(emptySettings, comps);
      expect(healed.availableTags, containsAll(['M3', 'inox', 'vite']));
      expect(healed.specialTags.any((st) => st.name == 'diametro'), isTrue);
      expect(healed.specialTags.any((st) => st.name == 'lunghezza'), isTrue);
    });

    test('does not pollute availableTags with tags that exist in tagTree', () {
      final ds = DataService();
      final comps = [
        Component(
          id: 'c1',
          name: 'Vite metrica',
          cabinet: 1,
          drawer: 'A1',
          tags: ['vite', 'metrica', 'M4', 'inox'],
        ),
      ];

      final treeSettings = AppSettings(
        tagTree: {
          'vite': {
            'metrica': <String, dynamic>{},
          },
        },
        availableTags: ['vite', 'M4'], // 'vite' was mistakenly here
      );

      final healed = ds.ensureSettingsIntegrity(treeSettings, comps);
      expect(healed.availableTags, containsAll(['M4', 'inox']));
      expect(healed.availableTags.contains('vite'), isFalse);
      expect(healed.availableTags.contains('metrica'), isFalse);
      expect(healed.allTags, containsAll(['vite', 'metrica', 'M4', 'inox']));
    });

    test('preserves bufferBags without dropping them', () {
      final ds = DataService();
      final s = AppSettings(
        bufferBags: ['Sacchetto viti', 'Sacchetto LED'],
      );

      final healed = ds.ensureSettingsIntegrity(s, []);
      expect(healed.bufferBags, containsAll(['Sacchetto viti', 'Sacchetto LED']));
    });
  });
}
