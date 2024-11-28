// // خدمة المصادقة
// import 'package:firedart/firedart.dart';
// import 'package:poem_app/models/auth_model.dart';
// import 'package:poem_app/services/firebase_services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {


    

//   // final FirebaseAuth _auth =
//   //     FirebaseAuth.initialize(FirebaseService.apiKey, VolatileStore());
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   /////////////////////////////////////
//   Future<UserModel?> signInWithGoogle() async {
//     FirebaseAuth auth = FirebaseAuth.instance;
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser != null) {
//         final GoogleSignInAuthentication googleAuth =
//             await googleUser.authentication;

//            // الحصول على الـ idToken و accessToken
//         final String? idToken = googleAuth.idToken;

//         // تهيئة Firebase Auth باستخدام firedart
      
//         Firestore firestore = Firestore.instance;

//         // تسجيل الدخول باستخدام `idToken`
//         if(idToken != null){
//   await auth.signInWithCustomToken(idToken);
//         // جلب معلومات المستخدم بعد تسجيل الدخول
//         var userId = auth.userId;
//         var userDoc =
//             await firestore.collection('users').document(userId).get();
//         bool isAdmin = userDoc['isAdmin'] ?? false;

//         final user = UserModel(
//           uid: userId,
//           email: googleUser.email,
//           isAdmin: isAdmin,
//           photoURL: googleUser.photoUrl,
//           username: googleUser.displayName,
//         );
//         final paymentsDocRef = firestore.collection('payments').document(user.uid);
//         // حفظ بيانات المستخدم في قاعدة البيانات
//         await firestore.collection('users').document(user.uid).set(user.toMap());

//         // حفظ بيانات المستخدم في SharedPreferences
//         await saveUserToPreferences(user);

//         if (isAdmin == false) {
//           final docSnapshot = await paymentsDocRef.get();

//           if (docSnapshot.exists) {
//             // إذا كانت الوثيقة موجودة، نقوم بتحديث البيانات
//             await paymentsDocRef.update({
//               'userId': user.uid,
//               'userName': user.username,
//               'userEmail': user.email,
//               'userPhoto': user.photoURL ?? '',
//             });
//             print('تم تحديث بيانات الدفع بنجاح.');
//           } else {
//             // إذا كانت الوثيقة غير موجودة، نقوم بإنشائها باستخدام set
//             await paymentsDocRef.set({
//               'userId': user.uid,
//               'userName': user.username,
//               'userEmail': user.email,
//               'userPhoto': user.photoURL ?? '',
//             });
//             print('تم إنشاء وثيقة الدفع وتخزين البيانات بنجاح.');
//           }
//         }
//           return user;
//         }
//       }
//     } catch (e) {
//       print('++++++++++++++++++++++++++++++$e')
//     }
//     return null;
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//     // إزالة بيانات المستخدم من SharedPreferences عند تسجيل الخروج
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }

//   Future<bool> _checkAdmin(String email) async {
//     DocumentSnapshot snapshot = await _db.collection('admins').doc(email).get();
//     return snapshot.exists;
//   }

//   Future<void> saveUserToPreferences(UserModel user) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userId', user.uid);
//     await prefs.setString('email', user.email);
//     await prefs.setBool('isAdmin', user.isAdmin);
//     await prefs.setBool('isLoggedIn', true); // حفظ حالة تسجيل الدخول
//     if (user.photoURL != null) {
//       await prefs.setString('photoURL', user.photoURL!);
//     }
//     if (user.username != null) {
//       await prefs.setString('username', user.username!);
//     }
//   }

//   // إضافة مدير
//   Future<void> addAdmin(Admin admin) async {
//     try {
//       await _db.collection('admins').doc(admin.email).set(admin.toMap());
//     } catch (e) {
//       print('Error adding admin: $e');
//       rethrow; // إعادة الخطأ
//     }
//   }

//   // حذف مدير
//   Future<void> deleteAdmin(String email) async {
//     try {
//       await _db.collection('admins').doc(email).delete();
//       // استعلام Firestore للحصول على الوثيقة التي تحتوي على البريد الإلكتروني
//       QuerySnapshot querySnapshot = await _db
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();

//       // التحقق من وجود الوثيقة قبل تحديثها
//       if (querySnapshot.docs.isNotEmpty) {
//         // تحديث حقل isAdmin في الوثيقة المسترجعة
//         await querySnapshot.docs.first.reference.update({
//           'isAdmin': false,
//         });
//       }
//     } catch (e) {
//       print('Error deleting admin: $e');
//       // ignore: use_rethrow_when_possible
//       throw e; // إعادة الخطأ
//     }
//   }

  // // تحويل دالة getAdmins إلى Stream
  // stream Future<List<Admin>> getAdmins() {
  //   return _db.collection('admins').snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) => Admin.fromMap(doc.data())).toList();
  //   });
  // }

//   String? getUserId() {
//     User? user = FirebaseAuth.instance.currentUser;
//     return user
//         ?.uid; // إذا كان هناك مستخدم، يتم إرجاع الـ user ID، وإذا لم يكن هناك يتم إرجاع null
//   }

//   Future<String?> getUidByEmail(String email) async {
//     try {
//       // استعلام Firestore للحصول على الوثيقة التي تحتوي على البريد الإلكتروني
//       QuerySnapshot querySnapshot = await _db
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();

//       // التحقق من الوثيقة المسترجعة
//       if (querySnapshot.docs.isNotEmpty) {
//         // استرجاع userId من الحقل الموجود
//         return querySnapshot.docs.first.get('uid') as String?;
//       } else {
//         return null; // لم يتم العثور على مستخدم بالبريد المحدد
//       }
//     } catch (e) {
//       print('Error fetching userId by email: $e');
//       return null;
//     }
//   }
// }
