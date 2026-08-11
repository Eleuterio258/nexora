import '../../../../core/errors/exceptions.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/branding_model.dart';

abstract interface class BrandingRemoteDatasource {
  Future<BrandingModel> fetchBranding();
}

class BrandingRemoteDatasourceImpl implements BrandingRemoteDatasource {
  const BrandingRemoteDatasourceImpl(this._client);

  final RestClient _client;

  @override
  Future<BrandingModel> fetchBranding() async {
    try {
      final response = await _client.unauth().get<Map<String, dynamic>>(
        '/api/v1/branding',
      );
      final data = response.data ?? {};
      return BrandingModel.fromJson(data);
    } on RestClientException catch (e) {
      if (e.statusCode == null) throw const NetworkException();
      if (e.statusCode == 401) throw const UnauthorizedException();
      throw const ServerException();
    }
  }
}