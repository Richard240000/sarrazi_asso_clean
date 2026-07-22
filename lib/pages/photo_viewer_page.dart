import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;
  final String titreAlbum;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.titreAlbum,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${currentIndex + 1}/${widget.photos.length}'),
        backgroundColor: Colors.black,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = widget.photos[index]['url'];

          return PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 60),
            ),
          );
        },
      ),
    );
  }
}
