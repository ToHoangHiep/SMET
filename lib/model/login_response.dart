class LoginResponse {
  final String token;
  final String refreshToken;
  final String expiresIn;
  final String tokenType;
  final String scope;
  final String idToken;
  final String sessionState;
  final String error;
  final String errorDescription;
  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.scope,
    required this.idToken,
    required this.sessionState,
    required this.error,
    required this.errorDescription,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      expiresIn: json['expiresIn'],
      tokenType: json['tokenType'],
      scope: json['scope'],
      idToken: json['idToken'],
      sessionState: json['sessionState'],
      error: json['error'],
      errorDescription: json['errorDescription'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
      'scope': scope,
      'idToken': idToken,
      'sessionState': sessionState,
    };
  }
}