import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventario/models/settings.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/cabinet_map_view.dart';
import 'package:inventario/widgets/drawer_picker_dialog.dart';

void main() {
  group('CabinetMapView tests', () {
    testWidgets('CabinetMapView fits cabinet on different screen sizes and resizes',
        (WidgetTester tester) async {
      final settings = AppSettings(
        containers: [
          ContainerConfig(
            id: 1,
            name: 'Cabinet 1',
            rows: 6,
            columns: 8,
          ),
          ContainerConfig(
            id: 2,
            name: 'Cabinet 2 (Large)',
            rows: 15,
            columns: 20,
          ),
        ],
      );

      final dataService = DataService();

      Widget buildView(Size size) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        return MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DataService>.value(
              value: dataService,
              child: CabinetMapView(
                settings: settings,
                dataService: dataService,
                onViewComponent: (_) {},
                onEditComponent: (_) {},
                onAddComponentAt: (_, __, ___) async {},
              ),
            ),
          ),
        );
      }

      const contentWidth = 8 * 88.0 + 24.0; // 728.0
      const contentHeight = 6 * 68.0 + 24.0; // 432.0

      // 1. Wide window (e.g. 1400 x 600)
      await tester.pumpWidget(buildView(const Size(1400, 600)));
      await tester.pumpAndSettle();

      expect(find.byType(CabinetMapView), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      final ivWide = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrixWide = ivWide.transformationController!.value;
      final scaleWide = matrixWide.storage[0];

      // Verify scale fits content within viewport
      expect(scaleWide, lessThanOrEqualTo(1.5));
      expect(contentWidth * scaleWide, lessThanOrEqualTo(1400));
      expect(contentHeight * scaleWide, lessThanOrEqualTo(600));

      // 2. Resize to Narrow / Tall window (e.g. 600 x 1000)
      await tester.pumpWidget(buildView(const Size(600, 1000)));
      await tester.pumpAndSettle();

      final ivTall = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrixTall = ivTall.transformationController!.value;
      final scaleTall = matrixTall.storage[0];

      expect(contentWidth * scaleTall, lessThanOrEqualTo(600));
      expect(contentHeight * scaleTall, lessThanOrEqualTo(1000));

      // 3. Resize to Small square window (e.g. 400 x 400)
      await tester.pumpWidget(buildView(const Size(400, 400)));
      await tester.pumpAndSettle();

      final ivSmall = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrixSmall = ivSmall.transformationController!.value;
      final scaleSmall = matrixSmall.storage[0];

      expect(contentWidth * scaleSmall, lessThanOrEqualTo(400));
      expect(contentHeight * scaleSmall, lessThanOrEqualTo(400));

      // 4. Switch to large cabinet
      await tester.tap(find.text('Cabinet 2 (Large)'));
      await tester.pumpAndSettle();

      const largeContentWidth = 20 * 88.0 + 24.0; // 1784.0
      const largeContentHeight = 15 * 68.0 + 24.0; // 1044.0

      final ivLarge = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrixLarge = ivLarge.transformationController!.value;
      final scaleLarge = matrixLarge.storage[0];

      expect(largeContentWidth * scaleLarge, lessThanOrEqualTo(400));
      expect(largeContentHeight * scaleLarge, lessThanOrEqualTo(400));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('DrawerGridPicker tests', () {
    testWidgets('DrawerGridPicker fits cabinet on resize', (WidgetTester tester) async {
      final settings = AppSettings(
        containers: [
          ContainerConfig(
            id: 1,
            name: 'Cabinet 1',
            rows: 6,
            columns: 8,
          ),
        ],
      );

      final dataService = DataService();

      Widget buildPicker(Size size) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        return MaterialApp(
          home: Scaffold(
            body: DrawerGridPicker(
              settings: settings,
              dataService: dataService,
              selectedCabinetId: 1,
              selectedCol: 'A',
              selectedRow: '1',
              onDrawerSelected: (cabinetId, col, row, zone) {},
            ),
          ),
        );
      }

      const pickerContentWidth = 8 * 80.0 + 16.0; // 656.0
      const pickerContentHeight = 6 * 62.0 + 16.0; // 388.0

      await tester.pumpWidget(buildPicker(const Size(500, 700)));
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrix = iv.transformationController!.value;
      final scale = matrix.storage[0];

      expect(pickerContentWidth * scale, lessThanOrEqualTo(500));
      expect(pickerContentHeight * scale, lessThanOrEqualTo(700));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
