import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/agenda_page.dart';
import 'package:sarrazi_asso_clean/pages/annonces_page.dart';
import 'package:sarrazi_asso_clean/pages/annuaire_page.dart';
import 'package:sarrazi_asso_clean/pages/artisans_page.dart';
import 'package:sarrazi_asso_clean/pages/documents_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/pages/phototheque_page.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';
import 'package:sarrazi_asso_clean/pages/association_page.dart';
import 'package:sarrazi_asso_clean/pages/alerte_signalement.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AccueilPage extends StatefulWidget {
const AccueilPage({super.key});

@override
State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
static const String _baseUrl = 'https://www.association-sarrazi.fr/';
String? utilisateur;
Map<String, dynamic>? bandeauMaj;
bool chargementBandeau = true;
bool hasNewAlert = false;

@override
void initState() {
super.initState();
utilisateur = sharedPreferences.getString('nom');
chargerBandeau();
checkNewAlerts();
}

Future<void> chargerBandeau() async {
final result = await HttpService.chargerBandeauMaj();

if (!mounted) return;

if (result.isSuccess && result.data is Map<String, dynamic>) {
  setState(() {
    bandeauMaj = Map<String, dynamic>.from(result.data);
    chargementBandeau = false;
  });
} else {
  setState(() {
    bandeauMaj = null;
    chargementBandeau = false;
  });
}

}

Future<int?> getLatestNewsId() async {
try {
final response = await http.get(Uri.parse('${_baseUrl}news.php'));

  if (response.statusCode != 200) return null;

  final decoded = json.decode(response.body);

  if (decoded is List && decoded.isNotEmpty) {
    final first = decoded.first;
    if (first is Map<String, dynamic>) {
      final rawId = first['id'];
      if (rawId is int) return rawId;
      return int.tryParse(rawId?.toString() ?? '');
    }
  }
} catch (_) {}

return null;

}

Future<void> checkNewAlerts() async {
final latestId = await getLatestNewsId();
final lastSeenId = sharedPreferences.getInt('last_seen_news_id');


if (!mounted) return;

setState(() {
  hasNewAlert = latestId != null && latestId != lastSeenId;
});

}

Future<void> _openAlerteSignalement() async {
final latestId = await getLatestNewsId();
if (latestId != null) {
await sharedPreferences.setInt('last_seen_news_id', latestId);
}

if (mounted) {
  setState(() {
    hasNewAlert = false;
  });
}

if (!mounted) return;

await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AlerteSignalementPage()),
);

if (!mounted) return;
await checkNewAlerts();

}

@override
Widget build(BuildContext context) {
return FocusDetector(
onVisibilityGained: () {
setState(() {
utilisateur = sharedPreferences.getString('nom');
});
checkNewAlerts();
},
child: BasePage(title: "", body: getBody(), isHome: true),
);
}

Widget getBody() {
  return SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      spacing: 10,
      children: [
        Image.asset(
          'assets/logoS.png',
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            spacing: 12,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildTile(
                      label: 'L\'association',
                      icon: Icons.groups,
                      color: const Color(0xFF455A64),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssociationPage(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTile(
                      label: 'Alertes &\nSignalements',
                      icon: Icons.notifications_active,
                      color: const Color(0xFF1A237E),
                      onTap: _openAlerteSignalement,
                      badgeVisible: hasNewAlert,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildTile(
                      label: 'Annuaire',
                      icon: Icons.contact_phone,
                      color: const Color(0xFF4527A0),
                      isSecure: true,
                      onTap: () async {
                        if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
                          await showModalBottomSheet(
                            context: context,
                            builder: (context) => LoginBottomSheet(),
                            isScrollControlled: true,
                          );
                          setState(() {
                            utilisateur = sharedPreferences.getString('nom');
                          });
                        }

                        if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnnuairePage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildTile(
                      label: 'Documents',
                      icon: Icons.picture_as_pdf,
                      color: const Color(0xFF00695C),
                      isSecure: true,
                      onTap: () async {
                        if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
                          await showModalBottomSheet(
                            context: context,
                            builder: (context) => LoginBottomSheet(),
                            isScrollControlled: true,
                          );
                          setState(() {
                            utilisateur = sharedPreferences.getString('nom');
                          });
                        }

                        if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DocumentsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildTile(
                      label: 'Photothèque',
                      icon: Icons.photo_library,
                      color: const Color(0xFF1565C0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhotothequePage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildTile(
                      label: 'Agenda',
                      icon: Icons.event,
                      color: const Color(0xFFAD1457),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgendaPage(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTile(
                      label: 'Artisans',
                      icon: Icons.handyman,
                      color: const Color(0xFFEF6C00),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtisansPage(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTile(
                      label: 'Annonces',
                      icon: Icons.announcement,
                      color: const Color(0xFF2E7D32),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnoncesPages(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildBandeauMaj(),
      ],
    ),
  );
}

Widget _buildBandeauMaj() {
if (chargementBandeau || bandeauMaj == null) {
return const SizedBox.shrink();
}

if (bandeauMaj!['enabled'] != true) {
  return const SizedBox.shrink();
}

final String message =
    bandeauMaj!['message']?.toString() ?? 'Nouvelle version disponible';
String buttonUrl = '';

if (Platform.isAndroid) {
  buttonUrl = bandeauMaj!['android_url']?.toString() ?? '';
} else if (Platform.isIOS) {
  buttonUrl = bandeauMaj!['ios_url']?.toString() ?? '';
}

Future<void> ouvrirStore() async {
  if (buttonUrl.isEmpty) return;
  final uri = Uri.parse(buttonUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

return GestureDetector(
  onTap: ouvrirStore,
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.orange.shade50),
    child: Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.download),
      ],
    ),
  ),
);


}

Widget _buildTile({
required String label,
required IconData icon,
required Color color,
required VoidCallback onTap,
bool isSecure = false,
bool badgeVisible = false,
}) {
return GestureDetector(
onTap: onTap,
child: Badge(
smallSize: 15,
largeSize: 15,
padding: const EdgeInsets.all(2),
offset: const Offset(2, -2),
alignment: Alignment.topRight,
isLabelVisible: badgeVisible,
label: const Text(""),
child: Container(
width: double.infinity,
constraints: const BoxConstraints(minHeight: 120, maxHeight: 120),
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(12.0),
),
padding: const EdgeInsets.all(6),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
mainAxisAlignment: MainAxisAlignment.start,
children: [
isSecure
? const Padding(
padding: EdgeInsets.only(right: 4.0, top: 4),
child: Align(
alignment: Alignment.topRight,
child: Icon(
Icons.lock,
size: 16.0,
color: Colors.white,
),
),
)
: const SizedBox(height: 20),
Column(
mainAxisAlignment: MainAxisAlignment.center,
spacing: 10,
children: [
Icon(icon, size: 32.0, color: Colors.white),
FittedBox(
fit: BoxFit.cover,
child: Text(
label,
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 14, color: Colors.white),
),
),
],
),
],
),
),
),
);
}
}
