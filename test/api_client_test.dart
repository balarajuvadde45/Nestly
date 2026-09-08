import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestly/services/api_client.dart';

void main() {
  test(
    'rejects malformed successful responses instead of reporting success',
    () async {
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response('<html>unavailable</html>', 200),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        client.get('/api/auth/me'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test(
    'network failures expose a readable message without transport details',
    () async {
      final client = ApiClient(
        client: MockClient(
          (_) async =>
              throw http.ClientException('internal connection details'),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        client.patch('/api/auth/me', body: {'name': 'Customer'}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Unable to connect. Check your connection and try again.',
          ),
        ),
      );
    },
  );
}
