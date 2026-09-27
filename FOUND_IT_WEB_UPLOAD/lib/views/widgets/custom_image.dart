import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final String? category;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const CustomImage({
    Key? key,
    required this.imageUrl,
    this.category,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  String _getFallbackImageUrl(String? cat) {
    if (cat == null) {
      return 'https://images.unsplash.com/photo-1540553016722-983e48a2cd10?w=800&auto=format&fit=crop&q=60';
    }
    switch (cat.toLowerCase()) {
      case 'phone':
        return 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=60';
      case 'earbuds':
      case 'headphones':
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=60';
      case 'wallet':
        return 'https://images.unsplash.com/photo-1627124765135-56c67c513e3c?w=800&auto=format&fit=crop&q=60';
      case 'keys':
        return 'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=800&auto=format&fit=crop&q=60';
      case 'laptop':
        return 'https://images.unsplash.com/photo-1496181130204-7552cc1454b4?w=800&auto=format&fit=crop&q=60';
      case 'bag':
      case 'backpack':
        return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&auto=format&fit=crop&q=60';
      case 'passport':
        return 'https://images.unsplash.com/photo-1544027993-37dbfe43562a?w=800&auto=format&fit=crop&q=60';
      case 'document':
      case 'documents':
        return 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=800&auto=format&fit=crop&q=60';
      default:
        return 'https://images.unsplash.com/photo-1540553016722-983e48a2cd10?w=800&auto=format&fit=crop&q=60';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle local file stored in app documents directory
    if (imageUrl.startsWith('local_file://')) {
      final filename = imageUrl.replaceFirst('local_file://', '');
      if (kIsWeb) {
        return Image.network(
          _getFallbackImageUrl(category),
          fit: fit,
          width: width,
          height: height,
        );
      }
      return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final file = File('${snapshot.data!.path}/$filename');
            if (file.existsSync()) {
              return Image.file(
                file,
                fit: fit,
                width: width,
                height: height,
                errorBuilder: errorBuilder ?? (context, error, stackTrace) {
                  return Image.network(
                    _getFallbackImageUrl(category),
                    fit: fit,
                    width: width,
                    height: height,
                  );
                },
              );
            }
          }
          return Image.network(
            _getFallbackImageUrl(category),
            fit: fit,
            width: width,
            height: height,
          );
        },
      );
    }

    final isNetwork = imageUrl.startsWith('http://') || 
                      imageUrl.startsWith('https://') || 
                      imageUrl.startsWith('blob:') || 
                      imageUrl.startsWith('data:');

    if (isNetwork) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) {
          final fallbackUrl = _getFallbackImageUrl(category);
          if (fallbackUrl != imageUrl) {
            return Image.network(
              fallbackUrl,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (context, e, s) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Container(
            color: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.image_not_supported_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
        loadingBuilder: loadingBuilder,
      );
    } else {
      if (kIsWeb) {
        return Image.network(
          _getFallbackImageUrl(category),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, e, s) => Container(
            color: theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.image_not_supported_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      } else {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: errorBuilder ?? (context, error, stackTrace) {
              return Image.network(
                _getFallbackImageUrl(category),
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, e, s) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          );
        } else {
          return Image.network(
            _getFallbackImageUrl(category),
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, e, s) => Container(
              color: theme.colorScheme.surfaceVariant,
              child: Icon(
                Icons.image_not_supported_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
      }
    }
  }
}


