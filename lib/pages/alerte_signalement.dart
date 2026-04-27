import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

import 'ajouter_publication.dart';

class AlerteSignalementPage extends StatefulWidget {
  const AlerteSignalementPage({super.key});

  @override
  State<AlerteSignalementPage> createState() => _AlerteSignalementPageState();
}

class _AlerteSignalementPageState extends State<AlerteSignalementPage> with SingleTickerProviderStateMixin {
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
    final params = <String, String>{'type': 'signalement', 'sort': _sort, 'limit': '200', 'offset': '0', 'user_id': (_userId ?? 0).toString()};

    return Uri.parse('${baseUrl}publications_list.php').replace(queryParameters: params);
  }

  Future<List<Publication>> _fetchSignalements() async {
    final uri = _buildSignalementsUri();
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur publications_list.php');
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map) ? (decoded['error']?.toString() ?? 'Erreur inconnue') : 'Réponse JSON invalide';
      throw Exception(err);
    }

    final data = decoded['data'];
    if (data is! List) return [];

    return data.map((e) => Publication.fromJson(e as Map<String, dynamic>)).toList();
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

    return decoded.map((e) => AlerteItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ToggleLikeResult> _toggleLike(int publicationId) async {
    if (sharedPreferences.getInt('user_id') == null) {
      throw Exception("Vous devez être connecté pour liker.");
    }

    final uri = Uri.parse('${baseUrl}publications_like.php');
    final payload = {'user_id': _userId, 'publication_id': publicationId};

    final res = await http.post(uri, headers: {'Content-Type': 'application/json; charset=utf-8'}, body: jsonEncode(payload));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur publications_like.php');
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map) ? (decoded['error']?.toString() ?? 'Erreur like') : 'Réponse JSON invalide';
      throw Exception(err);
    }

    return ToggleLikeResult(
      likedByMe: (decoded['liked_by_me'] ?? 0) == 1,
      likesCount: (decoded['likes_count'] ?? 0) is int ? decoded['likes_count'] : int.tryParse('${decoded['likes_count']}') ?? 0,
      action: decoded['action']?.toString() ?? '',
    );
  }

  Future<void> _updateStatus(int publicationId, String newStatus) async {
    if (sharedPreferences.getInt('user_id') == null) {
      throw Exception("Vous devez être connecté.");
    }

    final uri = Uri.parse('${baseUrl}publications_update_status.php');
    final payload = {'user_id': _userId, 'publication_id': publicationId, 'statut': newStatus};

    final res = await http.post(uri, headers: {'Content-Type': 'application/json; charset=utf-8'}, body: jsonEncode(payload));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} sur publications_update_status.php');
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      final err = (decoded is Map) ? (decoded['error']?.toString() ?? 'Erreur update statut') : 'Réponse JSON invalide';
      throw Exception(err);
    }
  }

  Future<void> _openAddSignalement() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AjouterPublicationPage()));

    if (ok == true) {
      await _refreshSignalements();
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
          return _ErrorView(error: snap.error.toString(), onRetry: _refreshAlertes);
        }

        final items = snap.data ?? [];
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

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.notifications_active)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(a.nature.isNotEmpty ? a.nature : 'Alerte', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (a.texte.trim().isNotEmpty) Text(a.texte, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 10),
                        Text('Par : ${a.nom.isEmpty ? "Administration" : a.nom} • ${_formatDate(a.dateAjout)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
            padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text("Lecture possible sans connexion. Connectez-vous pour publier, liker et changer le statut.", style: TextStyle(fontSize: 12, color: Colors.black54)),
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
                return _ErrorView(error: snap.error.toString(), onRetry: _refreshSignalements);
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
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(child: Icon(Icons.report_problem)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      p.titre,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  const Chip(label: Text('Signalement'), visualDensity: VisualDensity.compact),
                                  Chip(label: Text(p.categorie.isEmpty ? 'Autre' : p.categorie), visualDensity: VisualDensity.compact),
                                  if ((p.secteur ?? '').trim().isNotEmpty) Chip(label: Text(p.secteur!), visualDensity: VisualDensity.compact),
                                  Chip(
                                    label: Text(_statusLabel(p.statut)),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(color: _statusColor(p.statut)),
                                  ),
                                  if (p.urgence == 'urgent') const Chip(label: Text('URGENT'), visualDensity: VisualDensity.compact),
                                  if (p.urgence == 'faible') const Chip(label: Text('Faible'), visualDensity: VisualDensity.compact),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(p.description, maxLines: 4, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 10),
                              Text('Par : ${p.auteurNom.isEmpty ? "—" : p.auteurNom} • ${_formatDate(p.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 6),
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
    if (isoOrDateTime.trim().isEmpty) return '';
    if (isoOrDateTime.length >= 16) {
      return isoOrDateTime.substring(0, 16).replaceFirst('T', ' ');
    }
    return isoOrDateTime;
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _userId != null;

    return BasePage(
      title: 'Alertes & Signalements',
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              indicatorColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Alertes', icon: Icon(Icons.notifications)),
                Tab(text: 'Signalements', icon: Icon(Icons.report_problem)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [_buildAlertesBody(), _buildSignalementsBody()]),
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
      await showModalBottomSheet(context: context, builder: (context) => const LoginBottomSheet(), isScrollControlled: true);
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: sort,
            onChanged: (v) => v == null ? null : onSortChanged(v),
            items: const [
              DropdownMenuItem(value: 'recent', child: Text('Tri : Récent')),
              DropdownMenuItem(value: 'likes', child: Text('Tri : Likes')),
              DropdownMenuItem(value: 'status', child: Text('Tri : Statut')),
            ],
          ),
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

  const _TrailingActions({required this.publication, required this.canInteract, required this.currentUserId, required this.onLike, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final isAuthor = (currentUserId != null && currentUserId == publication.userId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: canInteract ? () => onLike() : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(publication.likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20),
                const SizedBox(width: 4),
                Text('${publication.likesCount}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: isAuthor ? 'Changer statut' : "Statut (seul l'auteur peut modifier)",
          enabled: canInteract && isAuthor,
          onSelected: (v) => onChangeStatus(v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'nouveau', child: Text('Nouveau')),
            PopupMenuItem(value: 'en_cours', child: Text('En cours')),
            PopupMenuItem(value: 'resolu', child: Text('Résolu')),
          ],
          child: const Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6), child: Icon(Icons.more_vert, size: 20)),
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
            ElevatedButton(onPressed: () => onRetry(), child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class AlerteItem {
  final int id;
  final String texte;
  final String nature;
  final String nom;
  final String dateAjout;

  AlerteItem({required this.id, required this.texte, required this.nature, required this.nom, required this.dateAjout});

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

  String statut;
  final String urgence;

  final int userId;
  final String auteurNom;
  final String createdAt;
  final String? updatedAt;

  int likesCount;
  bool likedByMe;

  Publication({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.secteur,
    required this.statut,
    required this.urgence,
    required this.userId,
    required this.auteurNom,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.likedByMe,
  });

  factory Publication.fromJson(Map<String, dynamic> j) {
    return Publication(
      id: _asInt(j['id']),
      type: (j['type'] ?? 'signalement').toString(),
      titre: (j['titre'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      categorie: (j['categorie'] ?? '').toString(),
      secteur: (j['secteur'] == null) ? null : j['secteur'].toString(),
      statut: (j['statut'] ?? 'nouveau').toString(),
      urgence: (j['urgence'] ?? 'normal').toString(),
      userId: _asInt(j['user_id']),
      auteurNom: (j['auteur_nom'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
      updatedAt: j['updated_at']?.toString(),
      likesCount: _asInt(j['likes_count']),
      likedByMe: _asInt(j['liked_by_me']) == 1,
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

  ToggleLikeResult({required this.likedByMe, required this.likesCount, required this.action});
}
