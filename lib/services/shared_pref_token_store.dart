import 'package:firedart/auth/token_store.dart';
import 'package:poem_app/services/token_extention.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesTokenStore implements TokenStore {
  static const _tokenKey = 'token_key';

  @override
  void clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey); // Clear the token
  }

  @override
  void delete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey); // Delete the token from storage
  }

  @override
  void expireToken() async {
    assert(hasToken); // Ensure the token exists
  //  SharedPreferences prefs = await SharedPreferences.getInstance();
    Token? token =  read();
    if (token != null) {
      token = Token(
        token.userId,
        token.idToken,
        token.refreshToken,
        DateTime.now(), // Expire the token immediately
      );
       write(token); // Save the updated token
    }
  }

  @override
  DateTime? get expiry {
    if (hasToken) {
      Token? token = read();
      return token?.expiry;
    }
    return null;
  }

  @override
  bool get hasToken {
    return read() != null;
  }

  @override
  String? get idToken {
    Token? token = read();
    return token?.idToken;
  }

  @override
  String? get refreshToken {
    Token? token = read();
    return token?.refreshToken;
  }

  @override
  String? get userId {
    Token? token = read();
    return token?.userId;
  }

  @override
  Token? read() {
    SharedPreferences.getInstance().then((prefs) {
      String? tokenJson = prefs.getString(_tokenKey);
      if (tokenJson != null) {
        Map<String, dynamic> tokenMap = jsonDecode(tokenJson);
        return Token.fromMap(tokenMap);
      }
      return null;
    });
    return null;
  }

  @override
  void setToken(String? userId, String idToken, String refreshToken,
      int expiresIn) async {
    DateTime expiry = DateTime.now().add(Duration(seconds: expiresIn));
    Token token = Token(userId, idToken, refreshToken, expiry);
     write(token);
  }

  @override
  void write(Token? token) async {
    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tokenJson = jsonEncode(token.toMap()); // Convert the token to JSON
      await prefs.setString(
          _tokenKey, tokenJson); // Save the token as a JSON string
    }
  }
}
