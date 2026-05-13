import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Small fixed-size thumbnail (menu rows, checkout, etc.).
class DishImageBox extends StatelessWidget {
  const DishImageBox({
    super.key,
    required this.width,
    required this.height,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final double width;
  final double height;
  final String? imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget core = _core();
    if (borderRadius != null) {
      core = ClipRRect(borderRadius: borderRadius!, child: core);
    }
    return SizedBox(width: width, height: height, child: core);
  }

  Widget _core() {
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        key: ValueKey(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
        // Web: default fetch() is CORS-blocked for many static hosts; <img> is not.
        webHtmlElementStrategy: kIsWeb
            ? WebHtmlElementStrategy.prefer
            : WebHtmlElementStrategy.never,
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE9E4DF),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        size: (width < height ? width : height) * 0.38,
        color: const Color(0xFF7D6D5B),
      ),
    );
  }
}

/// Fills a bounded parent (e.g. [SizedBox] with fixed height). Uses finite
/// layout constraints so images keep aspect ratio (important for web `<img>`).
class DishImageCover extends StatelessWidget {
  const DishImageCover({
    super.key,
    this.imageUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.backgroundColor = const Color(0xFFE9E4DF),
  });

  final String? imageUrl;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget core = LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        return ColoredBox(
          color: backgroundColor,
          child: Center(
            child: _imageOrPlaceholder(w, h),
          ),
        );
      },
    );
    if (borderRadius != null) {
      core = ClipRRect(borderRadius: borderRadius!, child: core);
    }
    return core;
  }

  Widget _imageOrPlaceholder(double w, double h) {
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        key: ValueKey(url),
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholderIcon(w, h),
        webHtmlElementStrategy: kIsWeb
            ? WebHtmlElementStrategy.prefer
            : WebHtmlElementStrategy.never,
      );
    }
    return _placeholderIcon(w, h);
  }

  Widget _placeholderIcon(double w, double h) {
    final double s = (w < h ? w : h) * 0.22;
    return Icon(
      Icons.restaurant_rounded,
      size: s.clamp(28, 56),
      color: const Color(0xFF7D6D5B),
    );
  }
}
