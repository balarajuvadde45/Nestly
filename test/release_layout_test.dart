import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestly/providers/auth_provider.dart';
import 'package:nestly/screens/auth/login_screen.dart';
import 'package:nestly/services/api_client.dart';
import 'package:nestly/services/socket_service.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('authentication layouts fit ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final auth = AuthProvider(api, SocketService());
      addTearDown(api.close);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sign up').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
