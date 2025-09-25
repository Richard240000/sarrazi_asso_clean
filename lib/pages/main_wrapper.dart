import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accueil.dart';
import 'information.dart';
import 'documents.dart';
import 'annuaire.dart';
import 'artisans.dart';
import 'agenda.dart';
import 'afficher_annonces.dart';
import 'login_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentNavIndex = 0;
  late Widget _currentPage;
  late Map<String, Widget> _allPages;
  String? userName;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final List<String> _pagesAvecDeconnexion = [
    'AfficherAnnoncesPage',
    'AfficherIdeesPage',
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserData();
    _initializePages();
  }

  void _initializeNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'Notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.subscribeToTopic('all');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] 🔔 Notification reçue : ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('nom');
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des données utilisateur')),
      );
    }
  }

  void _initializePages() {
    _allPages = {
      'Accueil': AccueilPage(onTilePressed: _handleTilePressed),
      'Alerte-Info': InformationPage(),
      'Documents': DocumentsPage(),
      'Annuaire': AnnuairePage(),
      'Artisans': ArtisansPage(),
      'Agenda': AgendaPage(),
      'Annonces': AfficherAnnoncesPage(),
    };
    _currentPage = _allPages['Accueil']!;
  }

  void _handleTilePressed(Widget page) {
    final pageEntry = _allPages.entries.firstWhere(
          (entry) => entry.value.runtimeType == page.runtimeType,
      orElse: () => MapEntry('', page),
    );

    setState(() {
      _currentPage = pageEntry.value;
      _currentNavIndex = pageEntry.key == 'Accueil' ? 0 : 1;
    });
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool afficherLogout = userName != null &&
        _pagesAvecDeconnexion.contains(_currentPage.runtimeType.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text('Association des Habitants de Sarrazi'),
        actions: [
          if (afficherLogout)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: _currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: PopupMenuButton<String>(
              icon: Icon(Icons.menu),
              onSelected: (pageName) {
                setState(() {
                  _currentPage = _allPages[pageName]!;
                  _currentNavIndex = 1;
                });
              },
              itemBuilder: (context) => _allPages.keys
                  .where((name) => name != 'Accueil')
                  .map((name) => PopupMenuItem(
                value: name,
                child: Text(name),
              ))
                  .toList(),
            ),
            label: 'Menu',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _currentPage = _allPages['Accueil']!;
              _currentNavIndex = 0;
            });
          }
        },
      ),
    );
  }
}
