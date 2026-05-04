import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sarrazi_asso_clean/pages/accueil_page.dart';
import 'package:sarrazi_asso_clean/pages/force_update_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
late SharedPreferences sharedPreferences;
String? version;

// Handler pour messages reçus en arrière-plan ou appli fermée
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📦 [BG] Notification en arrière-plan : ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  sharedPreferences = await SharedPreferences.getInstance();
  // 🔔 Notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: DarwinInitializationSettings());

  try {
    version = (await PackageInfo.fromPlatform()).version;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    // You may set the permission requests to "provisional" which allows the user to choose what type
    // of notifications they would like to receive once the user receives a notification.
    final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);

    // For apple platforms, make sure the APNS token is available before making any FCM plugin API calls
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      // APNS token is available, make FCM plugin API requests...
    }
    // 📬 Abonnement au topic 'all'
    await FirebaseMessaging.instance.subscribeToTopic('all');
    print("[DEBUG] ✅ Abonné au topic 'all'");

    // 🔑 Token FCM affiché pour vérification
    final token = await FirebaseMessaging.instance.getToken();
    print('[DEBUG] 🔑 Token FCM : $token');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    initializeDateFormatting('fr-FR');
  } on Exception catch (e) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarrazi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(color: Colors.blue[800], fontSize: 18, fontWeight: FontWeight.w600),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: BorderSide(color: Colors.black12),
          ),
          margin: EdgeInsets.only(bottom: 20),
        ),
      ),
      home: const VersionCheckPage(),
    );
  }
}

class VersionCheckPage extends StatefulWidget {
  const VersionCheckPage({super.key});

  @override
  State<VersionCheckPage> createState() => _VersionCheckPageState();
}

class _VersionCheckPageState extends State<VersionCheckPage> {
  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  Future<void> checkVersion() async {
    var currentVersion = (await PackageInfo.fromPlatform()).version;
    //const String currentVersion = "1.1.1"; // à automatiser plus tard

    var result = await HttpService.checkAppVersion(currentVersion);

    if (!mounted) return;

    if (result.isSuccess) {
      var data = result.data;

      if (data['force_update'] == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ForceUpdatePage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccueilPage()));
      }
    } else {
      // En cas d’erreur, on laisse passer
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccueilPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
