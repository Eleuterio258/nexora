import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/rest_client/rest_client.dart';
import 'package:nexora/core/rest_client/rest_client_exception.dart';
import 'package:nexora/core/rest_client/rest_client_response.dart';
import 'package:nexora/features/auth/data/datasources/auth_remote_datasource.dart';

class MockRestClient extends Mock implements RestClient {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockRestClient restClient;

  setUp(() {
    restClient = MockRestClient();
    dataSource = AuthRemoteDataSourceImpl(restClient: restClient);
    when(() => restClient.unauth()).thenReturn(restClient);
  });

  const tUsername = 'user@example.com';
  const tPassword = 'secret';

  group('login', () {
    test('deve devolver AuthResultModel quando todas as chamadas forem bem-sucedidas', () async {
      when(() => restClient.post<Map<String, dynamic>>(
            '/oauth/token',
            data: any(named: 'data'),
            header: any(named: 'header'),
          )).thenAnswer(
        (_) async => RestClientResponse(
          statusCode: 200,
          data: {
            'access_token': 'a',
            'refresh_token': 'r',
            'token_type': 'Bearer',
            'expires_in': 3600,
          },
        ),
      );
      when(() => restClient.get<Map<String, dynamic>>(
            '/api/auth/me',
            header: any(named: 'header'),
          )).thenAnswer(
        (_) async => RestClientResponse(
          statusCode: 200,
          data: {'id': 1, 'nome': 'User', 'email': tUsername},
        ),
      );
      when(() => restClient.get<Map<String, dynamic>>(
            '/api/auth/me/acesso',
            header: any(named: 'header'),
          )).thenAnswer(
        (_) async => RestClientResponse(
          statusCode: 200,
          data: {
            'user_id': 1,
            'tenant_id': 1,
            'tipo': 'funcionario',
            'escopo': 'erp',
            'modulos': [],
          },
        ),
      );

      final result = await dataSource.login(tUsername, tPassword);

      expect(result.accessToken, 'a');
      expect(result.user.email, tUsername);
    });

    test('deve lançar excepção quando /oauth/token devolver erro', () async {
      when(() => restClient.post<Map<String, dynamic>>(
            '/oauth/token',
            data: any(named: 'data'),
            header: any(named: 'header'),
          )).thenThrow(
        RestClientException(
          error: 'invalid_grant',
          statusCode: 400,
          response: RestClientResponse(
            statusCode: 400,
            data: {'error': 'invalid_grant'},
          ),
        ),
      );

      expect(
        () => dataSource.login(tUsername, tPassword),
        throwsA(isA<Exception>()),
      );
    });
  });
}
