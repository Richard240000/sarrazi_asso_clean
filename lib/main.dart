import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sarrazi_asso_clean/pages/accueil_page.dart';
import 'package:sarrazi_asso_clean/pages/force_update_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late SharedPreferences sharedPreferences;
String? version;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint(
    '📦 [BG] Notification en arrière-plan : '
    '${message.notification?.title}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  sharedPreferences = await SharedPreferences.getInstance();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  try {
    version = (await PackageInfo.fromPlatform()).version;

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    await FirebaseMessaging.instance.requestPermission(provisional: true);

    await FirebaseMessaging.instance.getAPNSToken();

    await FirebaseMessaging.instance.subscribeToTopic('all');
    debugPrint("[DEBUG] ✅ Abonné au topic 'all'");

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[DEBUG] 🔑 Token FCM : $token');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await initializeDateFormatting('fr-FR');
  } catch (e) {
    debugPrint("Erreur pendant l'initialisation de l'application : $e");
  }

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
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.blue[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.black12),
          ),
          margin: const EdgeInsets.only(bottom: 20),
        ),
      ),
      home: const VersionCheckPage(),
    );
  }
}

class VersionCheckPage extends StatefulWidget {
  const VersionCheckPage({super.key});

  @override
  State<VersionCheckPage> createState() {
    return _VersionCheckPageState();
  }
}

class _VersionCheckPageState extends State<VersionCheckPage> {
  bool _verificationEffectuee = false;

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  Future<void> checkVersion() async {
    if (_verificationEffectuee) {
      return;
    }

    _verificationEffectuee = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('Version installée : $currentVersion');

      final result = await HttpService.checkAppVersion(currentVersion);

      if (!mounted) {
        return;
      }

      if (!result.isSuccess) {
        debugPrint('Échec de la vérification de version : ${result.data}');
        _ouvrirAccueil();
        return;
      }

      final dynamic data = result.data;

      if (data is! Map<String, dynamic>) {
        debugPrint('Réponse serveur invalide : $data');
        _ouvrirAccueil();
        return;
      }

      final bool forceUpdate = data['force_update'] == true;
      final bool updateAvailable = data['update_available'] == true;

      final String latestVersion = data['latest_version']?.toString() ?? '';
      final String storeUrl = data['store_url']?.toString() ?? '';

      final String requiredMessage =
          data['message_required']?.toString() ??
          'Cette version de Sarrazi doit être mise à jour '
              'pour continuer.';

      final String optionalMessage =
          data['message_optional']?.toString() ??
          'Une nouvelle version de Sarrazi est disponible.';

      debugPrint(
        'Version serveur : $latestVersion — '
        'facultative : $updateAvailable — '
        'obligatoire : $forceUpdate',
      );

      if (forceUpdate) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ForceUpdatePage(storeUrl: storeUrl, message: requiredMessage),
          ),
        );
        return;
      }

      if (updateAvailable) {
        await _afficherMiseAJourFacultative(
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          message: optionalMessage,
        );

        if (!mounted) {
          return;
        }
      }

      _ouvrirAccueil();
    } catch (e) {
      debugPrint('Erreur lors de la vérification de version : $e');

      if (!mounted) {
        return;
      }

      _ouvrirAccueil();
    }
  }

  Future<void> _afficherMiseAJourFacultative({
    required String latestVersion,
    required String storeUrl,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Text(
            latestVersion.isEmpty
                ? message
                : '$message\n\n'
                      'Version disponible : $latestVersion',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Plus tard'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(storeUrl);

                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Mettre à jour'),
            ),
          ],
        );
      },
    );
  }

  void _ouvrirAccueil() {
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AccueilPage()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
