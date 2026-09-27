import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../details_screen.dart';
import 'custom_image.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'phone':
        return Icons.phone_android_rounded;
      case 'earbuds':
        return Icons.headphones_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'passport':
        return Icons.contact_mail_rounded;
      case 'keys':
        return Icons.vpn_key_rounded;
      case 'laptop':
        return Icons.laptop_chromebook_rounded;
      case 'bag':
        return Icons.backpack_rounded;
      case 'documents':
        return Icons.description_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getCategoryColor(BuildContext context, String category) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case 'phone':
        return theme.colorScheme.primaryContainer;
      case 'earbuds':
        return theme.colorScheme.secondaryContainer;
      case 'wallet':
        return theme.colorScheme.tertiaryContainer;
      case 'passport':
        return Colors.red.shade100;
      case 'keys':
        return Colors.amber.shade100;
      case 'laptop':
        return Colors.indigo.shade100;
      case 'bag':
        return Colors.orange.shade100;
      case 'documents':
        return Colors.teal.shade100;
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }

  Color _getCategoryTextColor(BuildContext context, String category) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case 'phone':
        return theme.colorScheme.onPrimaryContainer;
      case 'earbuds':
        return theme.colorScheme.onSecondaryContainer;
      case 'wallet':
        return theme.colorScheme.onTertiaryContainer;
      case 'passport':
        return Colors.red.shade900;
      case 'keys':
        return Colors.amber.shade900;
      case 'laptop':
        return Colors.indigo.shade900;
      case 'bag':
        return Colors.orange.shade900;
      case 'documents':
        return Colors.teal.shade900;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Category Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.4,
                  child: CustomImage(
                    imageUrl: post.imageUrl,
                    category: post.category,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                 Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(context, post.category),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(post.category),
                          size: 14,
                          color: _getCategoryTextColor(context, post.category),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _getCategoryTextColor(context, post.category),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.type == 'found' ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.type == 'found' ? Icons.search_rounded : Icons.campaign_rounded,
                          size: 14,
                          color: post.type == 'found' ? Colors.green.shade900 : Colors.orange.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.type == 'found' ? 'Found' : 'Lost',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: post.type == 'found' ? Colors.green.shade900 : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Details Block
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _timeAgo(post.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (post.policeStationName != null && post.policeStationName!.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_police, size: 8, color: Colors.blue.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'POLICE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200, width: 0.5),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
