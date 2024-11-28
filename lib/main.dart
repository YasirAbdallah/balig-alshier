import 'package:firedart/firedart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poem_app/services/firebase_services.dart';
import 'package:poem_app/views/admin/admin_page.dart';
import 'package:poem_app/views/user/sign_in_page.dart';
import 'package:poem_app/views/user/splash_page.dart';
import 'package:poem_app/views/user/user_poem_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseAuth.initialize(FirebaseService.apiKey, VolatileStore());
  Firestore.initialize(FirebaseService.projectId);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(0.9)),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'بليغ الشعر',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 183, 58, 58)),
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          getPages: [
            GetPage(name: '/splash', page: () => SplashView()),
            GetPage(name: '/', page: () => SignInPage()),
            GetPage(name: '/admin', page: () => AdminPage()),
            GetPage(name: '/user', page: () => UserPoemPage()),
          ],
        ),
      ),
    );
  }
}
