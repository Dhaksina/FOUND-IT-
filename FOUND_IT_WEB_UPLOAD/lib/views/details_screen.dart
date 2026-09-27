import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../providers/posts_provider.dart';
import '../providers/map_focus_provider.dart';
import '../providers/navigation_provider.dart';
import 'chat_screen.dart';
import 'widgets/custom_image.dart';
import '../services/firebase_service.dart';

class DetailsScreen extends ConsumerWidget {
  final PostModel post;

  const DetailsScreen({Key? key, required this.post}) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${post.latitude},${post.longitude}';
    try {
      final googleUri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(googleUri)) {
        await launchUrl(googleUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  Future<void> _openAppleMaps(BuildContext context) async {
    final appleMapsUrl = 'https://maps.apple.com/?q=${post.latitude},${post.longitude}';
    try {
      final appleUri = Uri.parse(appleMapsUrl);
      if (await canLaunchUrl(appleUri)) {
        await launchUrl(appleUri, mode: LaunchMode.externalApplication);
      } else {
        final googleUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${post.latitude},${post.longitude}');
        await launchUrl(googleUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Apple Maps.')),
        );
      }
    }
  }

  Future<void> _openWebBrowser(BuildContext context) async {
    final webUrl = 'https://www.openstreetmap.org/?mlat=${post.latitude}&mlon=${post.longitude}#map=16/${post.latitude}/${post.longitude}';
    try {
      final uri = Uri.parse(webUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Web Browser.')),
        );
      }
    }
  }

  void _showMapOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Map Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.map, color: theme.colorScheme.primary),
                title: const Text('Show in App Map'),
                subtitle: const Text('View and interact with this item on the main map tab'),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  ref.read(focusedPostProvider.notifier).setPost(post);
                  ref.read(navigationProvider.notifier).setIndex(1);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: Colors.green),
                title: const Text('Open in Google Maps'),
                subtitle: const Text('Get directions or explore via Google Maps'),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  _openGoogleMaps(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.compass_calibration_rounded, color: Colors.blue),
                title: const Text('Open in Apple Maps'),
                subtitle: const Text('Navigate using Apple Maps app'),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  _openAppleMaps(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    // Clean the phone number (remove any non-digits)
    final cleanPhone = post.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final message = post.type == 'found'
        ? 'Hello ${post.contactName}, I saw your post on TecFind for the found item: "${post.title}" and would like to connect.'
        : 'Hello ${post.contactName}, I saw your post on TecFind for the lost item: "${post.title}" and would like to connect.';
    final encodedMessage = Uri.encodeComponent(message);
    
    // Use the universal wa.me link
    final url = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try launching directly if canLaunchUrl fails
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp. Phone number: ${post.whatsappNumber}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final cleanPhone = post.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final url = 'tel:$cleanPhone';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make a phone call. Phone number: ${post.whatsappNumber}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _confirmMarkAsReturned(BuildContext context, WidgetRef ref) {
    final titleText = post.type == 'found' ? 'Mark as Returned?' : 'Mark as Resolved?';
    final contentText = post.type == 'found'
        ? 'This will mark the item as returned to its owner. It will no longer appear on the Home Screen or Map Screen.'
        : 'This will mark the item as resolved (found). It will no longer appear on the Home Screen or Map Screen.';
    final confirmButtonText = post.type == 'found' ? 'Mark Returned' : 'Mark Resolved';
    final successText = post.type == 'found'
        ? 'Item marked as returned successfully!'
        : 'Item marked as resolved successfully!';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titleText),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await ref.read(postsNotifierProvider.notifier).markAsReturned(post.id);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading indicator
                  Navigator.pop(context); // Go back to Home Screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(successText),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(confirmButtonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final verificationState = ref.watch(idVerificationProvider);
    final isVerified = verificationState.isVerified;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Hero Image App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image-${post.id}',
                child: CustomImage(
                  imageUrl: post.imageUrl,
                  category: post.category,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 80,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(
                                avatar: Icon(Icons.tag, size: 16, color: theme.colorScheme.onPrimaryContainer),
                                label: Text(post.category),
                                backgroundColor: theme.colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                avatar: Icon(
                                  post.type == 'found' ? Icons.search_rounded : Icons.campaign_rounded,
                                  size: 16,
                                  color: post.type == 'found' ? Colors.green.shade900 : Colors.orange.shade900,
                                ),
                                label: Text(post.type == 'found' ? 'Found' : 'Lost'),
                                backgroundColor: post.type == 'found' ? Colors.green.shade100 : Colors.orange.shade100,
                                labelStyle: TextStyle(
                                  color: post.type == 'found' ? Colors.green.shade900 : Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                avatar: Icon(Icons.currency_rupee_rounded, size: 16, color: theme.colorScheme.onSecondaryContainer),
                                label: Text(post.valueRange),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(post.createdAt),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      post.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description Block
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),

                    // Police Station Handover Panel (conditional)
                    if (post.policeStationName != null && post.policeStationName!.isNotEmpty) ...[
                      const Divider(height: 32),
                      Row(
                        children: [
                          Icon(Icons.local_police, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            post.type == 'found' ? 'Police Handover Details' : 'Police Station Report',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.errorContainer.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.error.withOpacity(0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.gavel_rounded, size: 18, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Precinct / Station Name',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.policeStationName!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.pin_drop_rounded, size: 18, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Precinct Location',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.policeStationLocation ?? 'Not specified',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                post.type == 'found'
                                    ? 'This found item has been handed over to the police precinct for safekeeping. Owners must contact the precinct directly to retrieve it.'
                                    : 'This lost item has been reported to this police station.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 32),
                    
                    // Location Block
                    Text(
                      post.type == 'found' ? 'Location Found' : 'Last Seen Location',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.locationName,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Static / Mini Map View (Tapping opens external maps app)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _showMapOptions(context, ref),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 180,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(post.latitude, post.longitude),
                                  zoom: 15,
                                ),
                                zoomGesturesEnabled: false,
                                scrollGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                myLocationEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('preview'),
                                    position: LatLng(post.latitude, post.longitude),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      post.type == 'found' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
                                    ),
                                  ),
                                },
                              ),
                            ),
                            // Floating badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Open in Maps',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    
                    // Finder Details
                    Text(
                      post.type == 'found' ? 'Finder Information' : 'Owner Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              child: Text(post.contactName.isNotEmpty
                                  ? post.contactName.substring(0, 1).toUpperCase()
                                  : '?'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.contactName.isNotEmpty ? post.contactName : 'Anonymous',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      post.whatsappNumber,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
 
                    // Actions Row
                    // Actions Block
                    if (isVerified)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366), // WhatsApp color
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  label: const Text(
                                    'WhatsApp',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  onPressed: () => _launchWhatsApp(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: theme.colorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.phone_rounded),
                                  label: const Text(
                                    'Phone Call',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  onPressed: () => _makePhoneCall(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.security_rounded),
                            label: const Text(
                              'Secure In-App Chat',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SecureChatScreen(post: post),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text(
                              'Secure In-App Chat',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SecureChatScreen(post: post),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.7)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text(
                              'Verify ID for Direct WhatsApp/Call',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => IdVerificationSheet(
                                  onVerified: (idType, imagePath) async {
                                    await ref.read(idVerificationProvider.notifier).verifyId(idType, imagePath);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                     
                    // Mark as Returned / Resolved Button (Only visible to the post owner/creator)
                    FutureBuilder<bool>(
                      future: FirebaseService.instance.isPostOwner(post),
                      builder: (context, snapshot) {
                        final isOwner = snapshot.data ?? false;
                        if (!isOwner) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                                      foregroundColor: theme.colorScheme.error,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: Text(post.type == 'found' ? 'Mark as Returned' : 'Mark as Resolved'),
                                    onPressed: () => _confirmMarkAsReturned(context, ref),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class IdVerificationSheet extends StatefulWidget {
  final Future<void> Function(String type, String path) onVerified;

  const IdVerificationSheet({Key? key, required this.onVerified}) : super(key: key);

  @override
  _IdVerificationSheetState createState() => _IdVerificationSheetState();
}

class _IdVerificationSheetState extends State<IdVerificationSheet> {
  final ImagePicker _picker = ImagePicker();
  String _selectedIdType = 'Aadhaar Card';
  File? _idImageFile;
  bool _isVerifying = false;
  bool _isSuccess = false;

  final List<String> _idTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Driving License',
    'Passport',
    'Voter ID'
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _idImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_idImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of your Government ID'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await widget.onVerified(_selectedIdType, _idImageFile!.path);
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload and verify ID: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        height: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Identity Verified!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlocking contact information...',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isVerifying) {
      return Container(
        padding: const EdgeInsets.all(24),
        height: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 4),
            const SizedBox(height: 24),
            Text(
              'Scanning Government ID...',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifying document authenticity and matching records...',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Verify Government ID',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'To ensure security and prevent fraud, please upload any official government ID (Aadhaar, PAN, License, etc.). Once submitted, contact details will unlock.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // ID Type Selection Dropdown
            DropdownButtonFormField<String>(
              value: _selectedIdType,
              decoration: const InputDecoration(
                labelText: 'Select ID Type*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: _idTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedIdType = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Image Upload Box
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Camera'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Gallery'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _idImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(
                              _idImageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                radius: 18,
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload original ID image',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Make sure text is clearly readable',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submit,
              child: const Text(
                'Verify & Unlock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
