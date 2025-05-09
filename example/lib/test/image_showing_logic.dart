import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageGalleryPage extends StatefulWidget {
  final List<String> images;

  const ImageGalleryPage({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _shareImage(String imagePath) async {
    try {
      final result = await ImageGallerySaverPlus.saveFile(imagePath);
    } catch (e) {
      print('Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share image: $e')),
      );
    }
  }

  void _deleteImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Image'),
        content: Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Delete the file
              try {
                final file = File(widget.images[index]);
                if (file.existsSync()) {
                  file.deleteSync();
                }

                setState(() {
                  final images = List<String>.from(widget.images);
                  images.removeAt(index);

                  // If no more images, go back
                  if (images.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }

                  // Update current index if needed
                  if (index == _currentIndex && index > 0) {
                    _currentIndex--;
                  }

                  // Reload gallery with updated images
                  if (mounted) {
                    _pageController.jumpToPage(_currentIndex);
                  }
                });
              } catch (e) {
                print('Error deleting image: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not delete image: $e')),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Image Gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.images[index])),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes:
                      PhotoViewHeroAttributes(tag: widget.images[index]),
                );
              },
              itemCount: widget.images.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                ),
              ),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),

            // Controls overlay (conditionally shown)
            if (_showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Column(
                    children: [
                      // Top bar with back button and image info
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon:
                                    Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                '${_currentIndex + 1} / ${widget.images.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Container(width: 48),
                            ],
                          ),
                        ),
                      ),

                      Spacer(),

                      // Bottom action bar
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.share, color: Colors.white),
                                onPressed: () =>
                                    _shareImage(widget.images[_currentIndex]),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () => _deleteImage(_currentIndex),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () {
                                  // Optional: Add photo editing functionality here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Edit feature coming soon')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
