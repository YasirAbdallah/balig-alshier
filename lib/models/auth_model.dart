// ignore_for_file: empty_catches, avoid_print

import 'dart:convert';
import 'package:desktop_webview_auth/google.dart';
import 'package:firedart/firedart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final bool isAdmin;
  final String? photoURL;
  final String? username;

  UserModel({
    required this.uid,
    required this.email,
    required this.isAdmin,
    this.photoURL,
    this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isAdmin': isAdmin,
      'photoURL': photoURL,
      'username': username,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      isAdmin: map['isAdmin'],
      photoURL: map['photoURL'],
      username: map['username'],
    );
  }
}

class Admin {
  final String name;
  final String email;

  Admin({required this.name, required this.email});

  // تحويل بيانات من خريطة إلى نموذج Admin
  factory Admin.fromMap(Map<String, dynamic> map) {
    // تحقق من أن القيم ليست null قبل تمريرها إلى Admin
    return Admin(
      name: map['name'] != null
          ? map['name'] as String
          : 'غير محدد', // أو يمكنك استخدام قيمة افتراضية
      email: map['email'] != null
          ? map['email'] as String
          : 'غير محدد', // أو استخدام قيمة افتراضية
    );
  }

  // تحويل نموذج Admin إلى خريطة
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }
}

// خدمة المصادقة
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? accessToken;
  String? idToken;
  final String projectId = 'poem-app-e89f8';
  final String apiKey = 'AIzaSyCNtfRU7_9QVz4ESzcMSwga4abjT2ZMPjU';
  FirebaseAuth auth = FirebaseAuth.instance;

  Firestore firestore = Firestore.instance;

  // تسجيل الدخول باستخدام Google
  /////////////////////////////////////
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleProvider = GoogleSignInArgs(
        clientId:
            '603100377144-u6js8ej25khgmj2op31tsk6eoa4a9gtk.apps.googleusercontent.com',
        redirectUri:
            'https://poem-app-e89f8.firebaseapp.com/docs/hosting?hl=ar', // Postman callback URI
        scope: 'email',
      );

      final result = await DesktopWebviewAuth.signIn(googleProvider);
      if (result != null) {
        // الحصول على الـ idToken و accessToken
        final String? idToken = result.idToken;
        final String? accessToken = result.accessToken;

        // تهيئة Firebase Auth باستخدام firedart

        // تسجيل الدخول باستخدام `idToken`
        if (idToken != null && accessToken != null) {
          await auth.signInWithCustomToken(idToken);
          // جلب معلومات المستخدم بعد تسجيل الدخول
          var userId = auth.userId;
          var userDoc =
              await firestore.collection('users').document(userId).get();
          bool isAdmin = userDoc['isAdmin'] ?? false;
          final userInfo = await fetchGoogleUserInfo(accessToken);
          if (userInfo != null) {
            final user = UserModel(
              uid: userId,
              email: userInfo['email'],
              isAdmin: isAdmin,
              photoURL: userInfo['email'],
              username: userInfo['email'],
            );
            final paymentsDocRef =
                firestore.collection('payments').document(user.uid);
            // حفظ بيانات المستخدم في قاعدة البيانات
            await firestore
                .collection('users')
                .document(user.uid)
                .set(user.toMap());

            // حفظ بيانات المستخدم في SharedPreferences
            await saveUserToPreferences(user);

            if (isAdmin == false) {
              final docSnapshot = await paymentsDocRef.get();

              if (docSnapshot.map.isNotEmpty) {
                // إذا كانت الوثيقة موجودة، نقوم بتحديث البيانات
                await paymentsDocRef.update({
                  'userId': user.uid,
                  'userName': user.username,
                  'userEmail': user.email,
                  'userPhoto': user.photoURL ?? '',
                });
                print('تم تحديث بيانات الدفع بنجاح.');
              } else {
                // إذا كانت الوثيقة غير موجودة، نقوم بإنشائها باستخدام set
                await paymentsDocRef.set({
                  'userId': user.uid,
                  'userName': user.username,
                  'userEmail': user.email,
                  'userPhoto': user.photoURL ?? '',
                });
                print('تم إنشاء وثيقة الدفع وتخزين البيانات بنجاح.');
              }
            }
            return user;
          }
        }
      }
    } catch (e) {
      print('++++++++++++++++++++++++++++++$e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchGoogleUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Failed to fetch user info: ${response.statusCode}");
      return null;
    }
  }

  Future<UserModel?> signInWithGoogleFirebaseAPI(
      String accessToken, String idToken) async {
    try {
      // إرسال الطلب إلى Firebase REST API لتسجيل الدخول باستخدام Google
      final response = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'postBody':
              'id_token=$idToken&providerId=google.com&access_token=$accessToken',
          'requestUri': 'http://localhost',
          'returnIdpCredential': true,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String uid = data['localId'];
        String email = data['email'];
        bool isAdmin = await _checkAdmin(email);

        // جلب الاسم والصورة من Firebase
        String? username = data['displayName'];
        String? photoURL = data['photoUrl'];

        final user = UserModel(
          uid: uid,
          email: email,
          isAdmin: isAdmin,
          photoURL: photoURL,
          username: username,
        );

        // حفظ بيانات المستخدم في قاعدة البيانات
        await _updateUserData(user);

        // حفظ بيانات المستخدم في SharedPreferences
        await saveUserToPreferences(user);

        return user;
      } else {
        print('Error during Firebase API sign-in: ${response.body}');
      }
    } catch (e) {
      print('Error during Google sign-in with Firebase API: $e');
    }
    return null;
  }

  // تحديث بيانات المستخدم في قاعدة البيانات
  Future<void> _updateUserData(UserModel user) async {
    try {
      await http.patch(
        Uri.parse(
            'https://$projectId.firebaseio.com/users/${user.uid}.json?auth=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toMap()),
      );
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // تحقق من كون المستخدم Admin
  Future<bool> _checkAdmin(String email) async {
    try {
      final response = await http.get(
        Uri.parse('https://$projectId.firebaseio.com/admins.json?auth=$apiKey'),
      );
      if (response.statusCode == 200) {
        final admins = json.decode(response.body);
        return admins.contains(email);
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> saveUserToPreferences(UserModel user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('email', user.email);
    await prefs.setBool('isAdmin', user.isAdmin);
    await prefs.setBool('isLoggedIn', true);
    if (user.photoURL != null) {
      await prefs.setString('photoURL', user.photoURL!);
    }
    if (user.username != null) {
      await prefs.setString('username', user.username!);
    }
  }

  // إضافة مدير عبر REST API
  Future<void> addAdmin(Admin admin) async {
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/admins/${admin.email}',
      );

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey', // تأكد من أن يكون التوكن صالحاً.
        },
        body: json.encode(
          {
            'fields': admin.toMap().map(
                  (key, value) => MapEntry(
                    key,
                    {'stringValue': value.toString()},
                  ),
                ),
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Admin added successfully.');
      } else {
        print('Failed to add admin: ${response.body}');
      }
    } catch (e) {
      print('Error adding admin: $e');
      rethrow; // إعادة الخطأ
    }
  }

  // حذف مدير عبر REST API
  Future<void> deleteAdmin(String email) async {
    try {
      // 1. حذف وثيقة المدير من مجموعة admins
      final deleteAdminUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/admins/$email',
      );

      final deleteAdminResponse = await http.delete(
        deleteAdminUrl,
        headers: {
          'Authorization': 'Bearer $apiKey', // تأكد من صلاحية التوكن
        },
      );

      if (deleteAdminResponse.statusCode == 200) {
        print('Admin deleted successfully.');
      } else {
        print('Failed to delete admin: ${deleteAdminResponse.body}');
      }

      // 2. البحث عن المستخدم في مجموعة users باستخدام البريد الإلكتروني
      final findUserUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
      );

      final findUserResponse = await http.post(
        findUserUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'structuredQuery': {
            'from': [
              {'collectionId': 'users'}
            ],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': 'email'},
                'op': 'EQUAL',
                'value': {'stringValue': email},
              },
            },
            'limit': 1,
          },
        }),
      );

      if (findUserResponse.statusCode == 200) {
        final userData = json.decode(findUserResponse.body);

        if (userData.isNotEmpty) {
          final userDocumentPath = userData[0]['document']['name'];

          // 3. تحديث حقل isAdmin إلى false للمستخدم المسترجع
          final updateUserUrl = Uri.parse(
            'https://firestore.googleapis.com/v1/$userDocumentPath',
          );

          final updateUserResponse = await http.patch(
            updateUserUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: json.encode({
              'fields': {
                'isAdmin': {'booleanValue': false},
              },
            }),
          );

          if (updateUserResponse.statusCode == 200) {
            print('User admin status updated successfully.');
          } else {
            print(
                'Failed to update user admin status: ${updateUserResponse.body}');
          }
        } else {
          print('No user found with the provided email.');
        }
      } else {
        print('Error finding user by email: ${findUserResponse.body}');
      }
    } catch (e) {
      print('Error deleting admin: $e');
      throw e;
    }
  }

  // تحويل دالة getAdmins إلى Stream
  Future<List<Admin>> getAdmins() async {
    // تحميل الوثائق دفعة واحدة من مجموعة "admins"
    var snapshot = await firestore.collection('admins').get();
    List<Admin> admins = snapshot.map((doc) => Admin.fromMap(doc.map)).toList();
    for (Admin admin in admins) {
      print(admin.name);
    }
    return admins;
  }

  // دالة لمساعدة في تحويل بيانات Firestore إلى Map<String, dynamic>
  Map<String, dynamic> _parseFirestoreData(Map<String, dynamic> fields) {
    final parsedData = <String, dynamic>{};

    fields.forEach((key, value) {
      if (value.containsKey('stringValue')) {
        parsedData[key] = value['stringValue'];
      } else if (value.containsKey('booleanValue')) {
        parsedData[key] = value['booleanValue'];
      } else if (value.containsKey('integerValue')) {
        parsedData[key] = int.parse(value['integerValue']);
      }
      // يمكن إضافة أنواع بيانات إضافية حسب الحاجة
    });

    return parsedData;
  }

  // جلب UID حسب البريد الإلكتروني باستخدام REST API
  Future<String?> getUidByEmail(String email) async {
    try {
      // بناء رابط الاستعلام للبحث في مجموعة users
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
      );

      // نص الطلب لجلب الوثائق التي تحتوي على البريد الإلكتروني
      final queryBody = json.encode({
        "structuredQuery": {
          "from": [
            {"collectionId": "users"}
          ],
          "where": {
            "fieldFilter": {
              "field": {"fieldPath": "email"},
              "op": "EQUAL",
              "value": {"stringValue": email}
            }
          },
          "limit": 1
        }
      });

      // إرسال طلب POST للاستعلام
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: queryBody,
      );

      // التحقق من الاستجابة
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // التأكد من وجود البيانات والـ UID
        if (responseData is List && responseData.isNotEmpty) {
          final document = responseData[0];
          final fields = document['document']['fields'];
          final uid = fields['uid']['stringValue'];
          return uid;
        } else {
          return null; // لم يتم العثور على المستخدم بالبريد المحدد
        }
      } else {
        print('Failed to fetch UID by email: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching UID by email: $e');
      return null;
    }
  }
}
