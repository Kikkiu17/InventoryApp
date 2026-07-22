import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imagePath = widget.images[index];
          Widget imgWidget;

          if (imagePath.startsWith('/')) {
            imgWidget = Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            );
          } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
            imgWidget = Image.network(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            );
          } else {
            if (ds.mode == StorageMode.remote && ds.serverConnected) {
              final url = ds.getAttachmentUrl(imagePath);
              imgWidget = Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              );
            } else {
              final localPath = ds.getLocalAttachmentPathSync(imagePath);
              imgWidget = Image.file(
                File(localPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              );
            }
          }

          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'comp_image_$imagePath',
                child: imgWidget,
              ),
            ),
          );
        },
      ),
    );
  }
}
