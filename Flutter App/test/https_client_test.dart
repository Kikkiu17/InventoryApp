import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/models/component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient URL Normalization & HTTPS Construction Tests', () {
    test('Normalizes baseUrl by stripping trailing slashes', () {
      final clientHttp = ApiClient('http://192.168.1.5:8080///');
      expect(clientHttp.baseUrl, equals('http://192.168.1.5:8080'));

      final clientHttps = ApiClient('https://192.168.1.5:8443/');
      expect(clientHttps.baseUrl, equals('https://192.168.1.5:8443'));

      expect(clientHttps.getAttachmentUrl('photo.jpg'),
          equals('https://192.168.1.5:8443/api/inventories/default/attachments/photo.jpg'));
    });

    test('withInventory preserves https baseUrl and client', () {
      final client = ApiClient('https://192.168.1.10:8443', inventoryId: 'main');
      final cloned = client.withInventory('workshop');

      expect(cloned.baseUrl, equals('https://192.168.1.10:8443'));
      expect(cloned.inventoryId, equals('workshop'));
      expect(cloned.allowSelfSigned, isTrue);
    });

    test('ApiClient works with mock HTTP client over HTTPS URLs', () async {
      final mock = MockClient((request) async {
        expect(request.url.scheme, equals('https'));
        expect(request.url.host, equals('myinventory.local'));
        expect(request.url.port, equals(8443));

        if (request.url.path == '/api/status') {
          return http.Response(
            jsonEncode({'status': 'ok', 'server': 'inventory-multi', 'https': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/inventories/default/components') {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'id': 'c1',
                  'name': 'Test Resistor',
                  'quantity': 10,
                  'drawer': 'A1',
                  'tags': ['Resistor'],
                  'description': '',
                }
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (request.method == 'POST') {
            final data = jsonDecode(request.body);
            return http.Response(
              jsonEncode(data),
              200,
              headers: {'content-type': 'application/json', 'x-last-updated': '2026-10-21T18:00:00Z'},
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient('https://myinventory.local:8443', client: mock);

      final pingOk = await client.ping();
      expect(pingOk, isTrue);

      final components = await client.getComponents();
      expect(components.length, equals(1));
      expect(components.first.name, equals('Test Resistor'));

      final newComp = Component(id: 'c2', name: 'Capacitor', quantity: 5, drawer: 'B2');
      final created = await client.createComponent(newComp);
      expect(created.name, equals('Capacitor'));
      expect(client.lastUpdated, equals('2026-10-21T18:00:00Z'));
    });

    test('ApiClient connects to loopback HTTPS server with allowSelfSigned', () async {
      final tempDir = Directory.systemTemp.createTempSync('ssl_test_');
      try {
        final keyFile = File('${tempDir.path}/key.pem');
        final certFile = File('${tempDir.path}/cert.pem');
        Process.runSync('openssl', [
          'req',
          '-x509',
          '-newkey',
          'rsa:2048',
          '-nodes',
          '-keyout',
          keyFile.path,
          '-out',
          certFile.path,
          '-days',
          '1',
          '-subj',
          '/CN=localhost',
        ]);

        final context = SecurityContext();
        context.useCertificateChain(certFile.path);
        context.usePrivateKey(keyFile.path);

        final server = await HttpServer.bindSecure(
          InternetAddress.loopbackIPv4,
          0,
          context,
        );

        server.listen((HttpRequest request) {
          if (request.uri.path == '/api/status') {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'status': 'ok', 'https': true}))
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..close();
          }
        });

        // 1. With allowSelfSigned = true (default)
        HttpOverrides.global = null;
        final clientAllowed = ApiClient(
          'https://127.0.0.1:${server.port}',
          allowSelfSigned: true,
        );
        final res = await clientAllowed.ping();
        expect(res, isTrue);
        clientAllowed.close();

        // 2. With allowSelfSigned = false, ping fails because self-signed cert is rejected
        final clientRejected = ApiClient(
          'https://127.0.0.1:${server.port}',
          allowSelfSigned: false,
        );
        expect(await clientRejected.ping(), isFalse);
        clientRejected.close();

        await server.close(force: true);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('DataService HTTPS & Self-Signed Cert Settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setServerUrl normalizes http and https URLs and adds default scheme', () async {
      final ds = DataService();
      await ds.load();

      // With https and trailing slash
      await ds.setServerUrl('https://192.168.1.100:8443/');
      expect(ds.serverUrl, equals('https://192.168.1.100:8443'));

      // Without scheme
      await ds.setServerUrl('192.168.1.100:8080');
      expect(ds.serverUrl, equals('http://192.168.1.100:8080'));
    });

    test('setTrustSelfSigned updates setting, persistence and overrides', () async {
      final ds = DataService();
      await ds.load();

      expect(ds.trustSelfSigned, isTrue);

      await ds.setTrustSelfSigned(false);
      expect(ds.trustSelfSigned, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('trustSelfSigned'), isFalse);

      await ds.setTrustSelfSigned(true);
      expect(ds.trustSelfSigned, isTrue);
      expect(prefs.getBool('trustSelfSigned'), isTrue);
    });
  });
}
