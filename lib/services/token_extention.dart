import 'package:firedart/auth/token_store.dart';

extension TokenExtension on Token {
  String? get userId => userId;
  String get idToken => idToken;
  String get refreshToken => refreshToken;
  DateTime get expiry => expiry;
}
