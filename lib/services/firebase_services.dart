class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  // Firebase configuration for the web app
  static const String apiKey = "AIzaSyCNtfRU7_9QVz4ESzcMSwga4abjT2ZMPjU";
  static const String authDomain = "poem-app-e89f8.firebaseapp.com";
  static const String projectId = "poem-app-e89f8";
  static const String storageBucket = "poem-app-e89f8.appspot.com";
  static const String messagingSenderId = "603100377144";
  static const String appId = "1:603100377144:web:4c195b530fc48f9f3ab6cd";
  static const String measurementId = "G-ZWRBL07Z79";

//  // Accessing the Singleton instance
//   FirebaseService firebaseService = FirebaseService();

//   // Now you can access individual configuration variables
//   print(firebaseService.apiKey);
//   print(firebaseService.authDomain);
//   print(firebaseService.projectId);
//   print(firebaseService.storageBucket);
//   print(firebaseService.messagingSenderId);
//   print(firebaseService.appId);
//   print(firebaseService.measurementId);

  // Initialize Firebase
  // Future<void> initialize() async {
  //   await Firebase.initializeApp();
  //   analytics = FirebaseAnalytics.instance;
  // }
}
