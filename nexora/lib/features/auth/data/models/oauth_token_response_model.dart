class OAuthTokenResponseModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String scope;

  OAuthTokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    this.scope = '',
  });

  factory OAuthTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return OAuthTokenResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      scope: (json['scope'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'scope': scope,
    };
  }
}
