import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'album_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class PhotothequePage extends StatefulWidget {
  const PhotothequePage({super.key});

  @override
  State<PhotothequePage> createState() => _PhotothequePageState();
}

class _PhotothequePageState extends State<PhotothequePage> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> albums = [];

  static const String albumsUrl =
      'https://www.association-sarrazi.fr/photo_albums.php';

  @override
  void initState() {
    super.initState();
    chargerAlbums();
  }

  Future<void> chargerAlbums() async {
    try {
      final response = await http.get(Uri.parse(albumsUrl));

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur inconnue');
      }

      setState(() {
        albums = data['albums'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Impossible de charger la photothèque.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: 'Photothèque', body: _buildBody());
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    if (albums.isEmpty) {
      return const Center(
        child: Text(
          'Aucun album photo disponible.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.photo_library, size: 36),
            title: Text(
              album['titre'] ?? 'Album photo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumPage(
                    albumId: int.parse(album['id'].toString()),
                    titreAlbum: album['titre'] ?? 'Album photo',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
