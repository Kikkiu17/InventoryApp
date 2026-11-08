import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? inventoryId;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.inventoryId,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;
  bool _showOverlays = true;

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

  Widget _buildImage(BuildContext context, String imagePath) {
    final ds = Provider.of<DataService>(context, listen: false);
    Widget image;

    if (imagePath.startsWith('/')) {
      image = Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      image = Image.network(
        imagePath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      // Controlla prima se il file è già presente nella cache locale
      final localPath = ds.getLocalAttachmentPathSync(imagePath, widget.inventoryId);
      final localFile = File(localPath);
      if (localFile.existsSync()) {
        image = Image.file(
          localFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } else if (ds.mode == StorageMode.remote && ds.serverConnected) {
        final url = ds.getAttachmentUrl(imagePath, widget.inventoryId);
        image = Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } else {
        image = Image.file(
          localFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    }

    return image;
  }

  static Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 64),
          SizedBox(height: 8),
          Text(
            'Impossibile caricare l\'immagine',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Nessuna immagine', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Vista a schermo intero con PageView
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _isZoomed = false;
                  });
                },
                itemBuilder: (context, index) {
                  final imagePath = widget.images[index];
                  return _ZoomableImagePage(
                    key: ValueKey(imagePath),
                    imageWidget: _buildImage(context, imagePath),
                    onZoomChanged: (zoomed) {
                      if (_isZoomed != zoomed) {
                        setState(() {
                          _isZoomed = zoomed;
                        });
                      }
                    },
                    onTap: () {
                      setState(() {
                        _showOverlays = !_showOverlays;
                      });
                    },
                  );
                },
              ),
            ),

            // Barra superiore in sovrimpressione con freccia indietro, contatore e pulsante chiudi
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showOverlays ? 0 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showOverlays ? 1.0 : 0.0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black87,
                        Colors.black45,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentIndex + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImagePage extends StatefulWidget {
  final Widget imageWidget;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onTap;

  const _ZoomableImagePage({
    super.key,
    required this.imageWidget,
    required this.onZoomChanged,
    required this.onTap,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
        _checkZoomStatus();
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _checkZoomStatus() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.02;
    if (_isZoomed != isZoomed) {
      _isZoomed = isZoomed;
      widget.onZoomChanged(isZoomed);
    }
  }

  void _handleDoubleTap(Size viewportSize) {
    if (_animController.isAnimating) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    Matrix4 targetMatrix;

    if (currentScale > 1.05) {
      // Torna alla scala normale 1.0x
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom al 2.5x sul punto toccato
      const targetScale = 2.5;
      final position = _doubleTapDetails?.localPosition ??
          Offset(viewportSize.width / 2, viewportSize.height / 2);

      final W = viewportSize.width;
      final H = viewportSize.height;

      double tx = (W / 2) - (position.dx * targetScale);
      double ty = (H / 2) - (position.dy * targetScale);

      // Limita la traslazione ai bordi del viewport
      tx = tx.clamp(-W * (targetScale - 1), 0.0);
      ty = ty.clamp(-H * (targetScale - 1), 0.0);

      targetMatrix = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(targetScale);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTapDown: (details) {
            _doubleTapDetails = details;
          },
          onDoubleTap: () => _handleDoubleTap(viewportSize),
          child: SizedBox.expand(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              panAxis: PanAxis.free,
              clipBehavior: Clip.none,
              onInteractionStart: (details) {
                if (_animController.isAnimating) {
                  _animController.stop();
                }
              },
              onInteractionUpdate: (details) {
                _checkZoomStatus();
              },
              onInteractionEnd: (details) {
                _checkZoomStatus();
              },
              child: SizedBox(
                width: viewportSize.width,
                height: viewportSize.height,
                child: Center(
                  child: widget.imageWidget,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
