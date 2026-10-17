import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sarrazi_asso_clean/extensions/string_extensions.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ajouter_publication.dart';

class AlerteSignalementPage extends StatefulWidget {
  const AlerteSignalementPage({super.key});

  @override
  State<AlerteSignalementPage> createState() => _AlerteSignalementPageState();
}

class _AlerteSignalementPageState extends State<AlerteSignalementPage>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'https://www.association-sarrazi.fr/';

  int? _userId;
  bool _loadingUser = true;

  String _sort = 'recent';

  late TabController _tabController;
  int _currentTabIndex = 0;

  late Future<List<Publication>> _futureSignalements;
  late Future<List<AlerteItem>> _futureAlertes;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _initUserAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('user_id');

    setState(() {
      _userId = uid;
      _loadingUser = false;
      _futureSignalements = _fetchSignalements();
      _futureAlertes = _fetchAlertes();
    });
  }

  Future<void> _refreshSignalements() async {
    setState(() {
      _futureSignalements = _fetchSignalements();
    });
    await _futureSignalements;
  }

  Future<void> _refreshAlertes() async {
    setState(() {
      _futureAlertes = _fetchAlertes();
    });
    await _futureAlertes;
  }

  Uri _buildSignalementsUri() {
    final params = <String, String>{
      'type': 'signalement',
      'sort': _sort,
      'limit': '200',
      'offset': '0',
      'user_id': (_userId ?? 0).toString(),
    };

    return Uri.parse(
      '${baseUrl}publications_list.php',
    ).replace(queryParameters: params);
  }

  Future<List<Publication>> _fetchSignalements() async {
    final uri = _buildSignalementsUri();
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur publications_list.php');
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map)
          ? (decoded['error']?.toString() ?? 'Erreur inconnue')
          : 'Réponse JSON invalide';
      throw Exception(err);
    }

    final data = decoded['data'];
    if (data is! List) return [];

    return data
        .map((e) => Publication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlerteItem>> _fetchAlertes() async {
    final uri = Uri.parse('${baseUrl}news.php');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur news.php');
    }

    final decoded = json.decode(res.body);

    if (decoded is! List) {
      if (decoded is Map && decoded['error'] != null) {
        throw Exception(decoded['error'].toString());
      }
      throw Exception('Réponse JSON invalide pour news.php');
    }

    return decoded
        .map((e) => AlerteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ToggleLikeResult> _toggleLike(int publicationId) async {
    if (sharedPreferences.getInt('user_id') == null) {
      throw Exception("Vous devez être connecté pour liker.");
    }

    final uri = Uri.parse('${baseUrl}publications_like.php');
    final payload = {'user_id': _userId, 'publication_id': publicationId};

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur publications_like.php');
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map)
          ? (decoded['error']?.toString() ?? 'Erreur like')
          : 'Réponse JSON invalide';
      throw Exception(err);
    }

    return ToggleLikeResult(
      likedByMe: (decoded['liked_by_me'] ?? 0) == 1,
      likesCount: (decoded['likes_count'] ?? 0) is int
          ? decoded['likes_count']
          : int.tryParse('${decoded['likes_count']}') ?? 0,
      action: decoded['action']?.toString() ?? '',
    );
  }

  Future<void> _updateStatus(int publicationId, String newStatus) async {
    if (sharedPreferences.getInt('user_id') == null) {
      throw Exception("Vous devez être connecté.");
    }

    final uri = Uri.parse('${baseUrl}publications_update_status.php');
    final payload = {
      'user_id': _userId,
      'publication_id': publicationId,
      'statut': newStatus,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'HTTP ${res.statusCode} sur publications_update_status.php',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map)
          ? (decoded['error']?.toString() ?? 'Erreur update statut')
          : 'Réponse JSON invalide';
      throw Exception(err);
    }
  }

  Future<void> _openAddSignalement() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AjouterPublicationPage()),
    );

    if (ok == true) {
      await _refreshSignalements();
    }
  }

  Future<void> _openCommentaires(Publication publication) async {
    if (sharedPreferences.getInt('user_id') == null) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LoginBottomSheet(),
      );
    }
    if (!mounted) return;
    final userId = sharedPreferences.getInt('user_id');
    if (userId == null || userId <= 0) return;
    setState(() => _userId = userId);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _SignalementDiscussionPage(
          publication: publication,
          baseUrl: baseUrl,
        ),
      ),
    );
    if (mounted) await _refreshSignalements();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(e.toString()),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolu':
        return Colors.green;
      case 'en_cours':
        return Colors.orange;
      case 'nouveau':
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'resolu':
        return 'Résolu';
      case 'en_cours':
        return 'En cours';
      case 'nouveau':
      default:
        return 'Nouveau';
    }
  }

  Widget _buildAlertesBody() {
    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<AlerteItem>>(
      future: _futureAlertes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return _ErrorView(
            error: snap.error.toString(),
            onRetry: _refreshAlertes,
          );
        }

        final items = (snap.data ?? [])
            .where((x) => x.texte.trim().isNotEmpty)
            .toList();

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshAlertes,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Center(child: Text('Aucune alerte pour le moment')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshAlertes,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              var date = DateTime.tryParse(a.dateAjout) ?? DateTime.now();
              var color = Colors.blue[800];
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  spacing: 5,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: Container(height: 2, color: Colors.blue[800]),
                        ),
                        Icon(Icons.notifications, color: color),
                        Expanded(
                          child: Container(height: 2, color: Colors.blue[800]),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        spacing: 5,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat("EEEE", 'fr').format(date).capitalize(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat("dd", 'fr').format(date).capitalize(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),

                          Text(
                            DateFormat("MMMM", 'fr').format(date).capitalize(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat("yyyy", 'fr').format(date),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Card(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildTextWithLinks(a.texte),
                            Text(
                              'Par : ${a.nom.isEmpty ? "Administration" : a.nom} • ${_formatDate(a.dateAjout)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSignalementPhoto(String filename) {
    // Le PHP stocke uniquement le nom du fichier dans publications.photo.
    final photoUrl =
        '${baseUrl}uploads_signalements/${Uri.encodeComponent(filename)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        photoUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.contain,
        semanticLabel: 'Photo du signalement',
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          return SizedBox(
            height: 240,
            child: Center(
              child: CircularProgressIndicator(
                value: total != null && total > 0
                    ? loadingProgress.cumulativeBytesLoaded / total
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: double.infinity,
          height: 60,
          child: Center(
            child: Text(
              'Photo indisponible',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignalementsBody() {
    final canPost = _userId != null;

    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _FiltersBar(
          sort: _sort,
          onSortChanged: (v) {
            setState(() {
              _sort = v;
              _futureSignalements = _fetchSignalements();
            });
          },
        ),
        if (!canPost)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Text(
              "Lecture possible sans connexion. Connectez-vous pour publier, commenter, consulter les échanges, liker et changer le statut.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 6),
        Expanded(
          child: FutureBuilder<List<Publication>>(
            future: _futureSignalements,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return _ErrorView(
                  error: snap.error.toString(),
                  onRetry: _refreshSignalements,
                );
              }

              final items = snap.data ?? [];
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshSignalements,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 150),
                      Center(child: Text('Aucun signalement.')),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshSignalements,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: Card(
                        clipBehavior: Clip.hardEdge,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.orange,
                                    size: 30,
                                    weight: 600,
                                  ),
                                  Expanded(
                                    child: Text(
                                      p.titre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(
                                      'Signalement',
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    color: WidgetStatePropertyAll(Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      p.categorie.isEmpty
                                          ? 'Autre'
                                          : p.categorie,
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    color: WidgetStatePropertyAll(Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  if ((p.secteur ?? '').trim().isNotEmpty)
                                    Chip(
                                      label: Text(
                                        p.secteur!,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      color: WidgetStatePropertyAll(
                                        Colors.white,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  Chip(
                                    label: Text(
                                      _statusLabel(p.statut),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    color: WidgetStatePropertyAll(
                                      _statusColor(p.statut),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),

                                  if (p.urgence == 'urgent')
                                    Chip(
                                      label: Text(
                                        'URGENT',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      color: WidgetStatePropertyAll(
                                        Colors.white,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  if (p.urgence == 'faible')
                                    Chip(
                                      label: Text(
                                        'Faible',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      color: WidgetStatePropertyAll(
                                        Colors.white,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                ],
                              ),
                              buildTextWithLinks(p.description),
                              TextButton.icon(
                                onPressed: () => _openCommentaires(p),
                                icon: const Icon(Icons.forum_outlined),
                                label: Text(
                                  p.commentsCount == 0
                                      ? 'Commentaires et réponses'
                                      : 'Commentaires et réponses (${p.commentsCount})',
                                ),
                              ),
                              if ((p.photo ?? '').isNotEmpty)
                                _buildSignalementPhoto(p.photo!),
                              Text(
                                'Par : ${p.auteurNom.isEmpty ? "—" : p.auteurNom} • ${_formatDate(p.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _TrailingActions(
                                  publication: p,
                                  canInteract: canPost,
                                  currentUserId: _userId,
                                  onLike: () async {
                                    try {
                                      final r = await _toggleLike(p.id);
                                      setState(() {
                                        p.likesCount = r.likesCount;
                                        p.likedByMe = r.likedByMe;
                                      });
                                    } catch (e) {
                                      _showError(e);
                                    }
                                  },
                                  onChangeStatus: (newStatus) async {
                                    try {
                                      await _updateStatus(p.id, newStatus);
                                      setState(() {
                                        p.statut = newStatus;
                                      });
                                    } catch (e) {
                                      _showError(e);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatDate(String isoOrDateTime) {
    return DateFormat(
      "dd/MM/yyyy à HH:mm",
    ).format(DateTime.tryParse(isoOrDateTime) ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Alertes & Signalements',
      body: Column(
        spacing: 0,
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              indicatorColor: Colors.white,
              unselectedLabelColor: Colors.blue[800],
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Colors.blue[800]),
              dividerColor: Colors.blue[800],
              tabs: const [
                Tab(
                  text: 'Alertes',
                  icon: Icon(Icons.notifications),
                  height: 55,
                ),
                Tab(
                  text: 'Signalements',
                  icon: Icon(Icons.report_problem),
                  height: 55,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAlertesBody(), _buildSignalementsBody()],
            ),
          ),
        ],
      ),
      floatingButton: _currentTabIndex == 1
          ? FloatingActionButton(
              onPressed: () async => await _ajouterAnnonce(),
              shape: const CircleBorder(),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _ajouterAnnonce() async {
    if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
      await showModalBottomSheet(
        context: context,
        builder: (context) => const LoginBottomSheet(),
        isScrollControlled: true,
      );
      setState(() {
        _userId = sharedPreferences.getInt('user_id');
      });
    }

    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
      if (!context.mounted) return;
      await _openAddSignalement();
    }
  }
}

class _FiltersBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;

  const _FiltersBar({required this.sort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: DropdownButton<String>(
        value: sort,
        onChanged: (v) => v == null ? null : onSortChanged(v),
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: 'recent', child: Text('Tri : Récent')),
          DropdownMenuItem(value: 'likes', child: Text('Tri : Likes')),
          DropdownMenuItem(value: 'status', child: Text('Tri : Statut')),
        ],
      ),
    );
  }
}

class _TrailingActions extends StatelessWidget {
  final Publication publication;
  final bool canInteract;
  final int? currentUserId;
  final Future<void> Function() onLike;
  final Future<void> Function(String newStatus) onChangeStatus;

  const _TrailingActions({
    required this.publication,
    required this.canInteract,
    required this.currentUserId,
    required this.onLike,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthor =
        (currentUserId != null && currentUserId == publication.userId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        InkWell(
          onTap: canInteract ? () => onLike() : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  publication.likedByMe
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 25,
                  color: publication.likedByMe
                      ? Colors.blue[800]
                      : Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  '${publication.likesCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: publication.likedByMe
                        ? Colors.blue[800]
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: isAuthor
              ? 'Changer statut'
              : "Statut (seul l'auteur peut modifier)",
          enabled: canInteract && isAuthor,
          onSelected: (v) => onChangeStatus(v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'nouveau', child: Text('Nouveau')),
            PopupMenuItem(value: 'en_cours', child: Text('En cours')),
            PopupMenuItem(value: 'resolu', child: Text('Résolu')),
          ],
          child: Icon(Icons.more_vert, size: 25),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur: $error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildTextWithLinks(String text) {
  final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
  final spans = <TextSpan>[];

  int start = 0;

  for (final match in urlRegex.allMatches(text)) {
    if (match.start > start) {
      spans.add(
        TextSpan(
          text: text.substring(start, match.start),
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      );
    }

    final url = match.group(0)!;

    spans.add(
      TextSpan(
        text: url,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);

            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {
              debugPrint("Erreur ouverture URL : $e");
            }
          },
      ),
    );

    start = match.end;
  }

  if (start < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(start),
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  return RichText(
    text: TextSpan(
      children: spans,
      style: GoogleFonts.poppins().copyWith(fontSize: 15),
    ),
  );
}

class AlerteItem {
  final int id;
  final String texte;
  final String nature;
  final String nom;
  final String dateAjout;

  AlerteItem({
    required this.id,
    required this.texte,
    required this.nature,
    required this.nom,
    required this.dateAjout,
  });

  factory AlerteItem.fromJson(Map<String, dynamic> j) {
    return AlerteItem(
      id: _asInt(j['id']),
      texte: (j['texte'] ?? '').toString(),
      nature: (j['nature'] ?? '').toString(),
      nom: (j['nom'] ?? '').toString(),
      dateAjout: (j['date_ajout'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class Publication {
  final int id;
  final String type;
  final String titre;
  final String description;
  final String categorie;
  final String? secteur;
  final String? photo;

  String statut;
  final String urgence;

  final int userId;
  final String auteurNom;
  final String createdAt;
  final String? updatedAt;

  int likesCount;
  bool likedByMe;
  final int commentsCount;

  Publication({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.secteur,
    this.photo,
    required this.statut,
    required this.urgence,
    required this.userId,
    required this.auteurNom,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.likedByMe,
    this.commentsCount = 0,
  });

  factory Publication.fromJson(Map<String, dynamic> j) {
    return Publication(
      id: _asInt(j['id']),
      type: (j['type'] ?? 'signalement').toString(),
      titre: (j['titre'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      categorie: (j['categorie'] ?? '').toString(),
      secteur: (j['secteur'] == null) ? null : j['secteur'].toString(),
      photo: j['photo']?.toString().trim(),
      statut: (j['statut'] ?? 'nouveau').toString(),
      urgence: (j['urgence'] ?? 'normal').toString(),
      userId: _asInt(j['user_id']),
      auteurNom: (j['auteur_nom'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
      updatedAt: j['updated_at']?.toString(),
      likesCount: _asInt(j['likes_count']),
      likedByMe: _asInt(j['liked_by_me']) == 1,
      commentsCount: _asInt(j['comments_count']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ToggleLikeResult {
  final bool likedByMe;
  final int likesCount;
  final String action;

  ToggleLikeResult({
    required this.likedByMe,
    required this.likesCount,
    required this.action,
  });
}

class _SignalementDiscussionPage extends StatefulWidget {
  final Publication publication;
  final String baseUrl;
  const _SignalementDiscussionPage({
    required this.publication,
    required this.baseUrl,
  });

  @override
  State<_SignalementDiscussionPage> createState() =>
      _SignalementDiscussionPageState();
}

class _SignalementDiscussionPageState
    extends State<_SignalementDiscussionPage> {
  final _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  Map<String, dynamic>? _replyTo;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _userId() {
    final id = sharedPreferences.getInt('user_id');
    if (id == null || id <= 0)
      throw Exception('Connectez-vous pour consulter ou envoyer un message.');
    return id;
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception(
        'Réponse du serveur invalide (HTTP ${response.statusCode}).',
      );
    }
    if (body is! Map<String, dynamic>)
      throw Exception('Réponse du serveur invalide.');
    if (body['success'] != true || response.statusCode != 200) {
      throw Exception(
        body['error']?.toString() ??
            'Erreur serveur (HTTP ${response.statusCode}).',
      );
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final uri = Uri.parse('${widget.baseUrl}publications_comments_list.php')
        .replace(
          queryParameters: {
            'publication_id': widget.publication.id.toString(),
            'user_id': _userId().toString(),
            't': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    final data = _decode(response)['data'];
    if (data is! List) throw Exception('Liste de commentaires invalide.');
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = _load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // L'erreur et le bouton Réessayer sont affichés par FutureBuilder.
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty || text.runes.length > 5000) {
      setState(() => _sendError = 'Saisissez entre 1 et 5 000 caractères.');
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}publications_comments_add.php'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'publication_id': widget.publication.id,
          'user_id': _userId(),
          'commentaire': text,
          'parent_id': _replyTo?['id'],
        }),
      );
      final result = _decode(response);
      if (!mounted) return;
      _controller.clear();
      setState(() => _replyTo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['notification_sent'] == false
                ? 'Message publié. La notification n’a pas pu être envoyée.'
                : 'Message publié.',
          ),
        ),
      );
      await _refresh();
    } catch (e) {
      if (mounted)
        setState(
          () => _sendError =
              '$e\nSi l’envoi a été interrompu, actualisez la discussion avant de réessayer pour éviter un doublon.',
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _message(Map<String, dynamic> message, {bool reply = false}) {
    final name = message['auteur_nom']?.toString() ?? '';
    final date = DateTime.tryParse(message['date_creation']?.toString() ?? '');
    return Padding(
      padding: EdgeInsets.only(left: reply ? 24 : 0, bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Utilisateur' : name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (date != null)
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(date),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              const SizedBox(height: 8),
              Text(message['commentaire']?.toString() ?? ''),
              if (!reply)
                TextButton.icon(
                  onPressed: _sending
                      ? null
                      : () => setState(() {
                          _replyTo = message;
                          _sendError = null;
                        }),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Répondre'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commentaires'),
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _sending ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.publication.titre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return _ErrorView(
                        error: '${snapshot.error}',
                        onRetry: _refresh,
                      );
                    final messages = snapshot.data ?? [];
                    final roots = messages
                        .where((m) => m['parent_id'] == null)
                        .toList();
                    final replies = <String, List<Map<String, dynamic>>>{};
                    for (final message in messages) {
                      if (message['parent_id'] != null) {
                        replies
                            .putIfAbsent('${message['parent_id']}', () => [])
                            .add(message);
                      }
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Text(
                            '${messages.length} message${messages.length == 1 ? '' : 's'}',
                          ),
                          const SizedBox(height: 12),
                          if (messages.isEmpty)
                            const Text(
                              'Aucun commentaire. Vous pouvez commencer la discussion.',
                            ),
                          for (final root in roots) ...[
                            _message(root),
                            for (final reply
                                in replies['${root['id']}'] ??
                                    <Map<String, dynamic>>[])
                              _message(reply, reply: true),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_replyTo != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Réponse à ${_replyTo!['auteur_nom']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Annuler la réponse',
                            onPressed: _sending
                                ? null
                                : () => setState(() => _replyTo = null),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 5000,
                      decoration: InputDecoration(
                        hintText: _replyTo == null
                            ? 'Votre commentaire…'
                            : 'Votre réponse…',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_sendError != null)
                      Text(
                        _sendError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_sending ? 'Envoi en cours…' : 'Publier'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
