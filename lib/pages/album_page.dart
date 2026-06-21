import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'photo_viewer_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class AlbumPage extends StatefulWidget {
  final int albumId;
  final String titreAlbum;

  const AlbumPage({super.key, required this.albumId, required this.titreAlbum});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> photos = [];

  Future<void> chargerPhotos() async {
    final url =
        'https://www.association-sarrazi.fr/photos_album.php?id=${widget.albumId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur inconnue');
      }

      setState(() {
        photos = data['photos'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Impossible de charger les photos.';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    chargerPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: widget.titreAlbum, body: _buildBody());
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

    if (photos.isEmpty) {
      return const Center(
        child: Text(
          'Aucune photo disponible dans cet album.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final imageUrl = photo['url'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoViewerPage(
                  photos: photos,
                  initialIndex: index,
                  titreAlbum: widget.titreAlbum,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 40),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
