import 'package:flutter/material.dart';

class CoverArt extends StatefulWidget {
  const CoverArt({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<CoverArt> createState() => _CoverArtState();
}

class _CoverArtState extends State<CoverArt> {
  bool isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        widget.url,
        frameBuilder: (_, child, frame, __) {
          isLoaded = frame != null;
          return child;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (isLoaded && loadingProgress == null) return child;

          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Placeholder();
        },
      ),
    );
  }
}
