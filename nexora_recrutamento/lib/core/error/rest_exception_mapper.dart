import '../rest_client/rest_client_exception.dart';
import 'exceptions.dart';

/// Converte uma [RestClientException] (nível de transporte) num dos
/// exceptions de domínio que os repositórios sabem apanhar
/// (AuthException/ServerException). Usado por todos os datasources que
/// falam com o [RestClient] directamente.
Never mapRestException(RestClientException e) {
  if (e.statusCode == 401) {
    throw AuthException(e.message ?? 'Não autorizado.');
  }
  if (e.statusCode == 404) {
    throw const ServerException('Recurso não encontrado.', statusCode: 404);
  }
  throw ServerException(e.message ?? 'Erro de servidor.', statusCode: e.statusCode);
}
