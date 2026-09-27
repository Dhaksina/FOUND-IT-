import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/posts_provider.dart';
import '../providers/map_focus_provider.dart';
import '../models/post_model.dart';
import 'details_screen.dart';
import 'widgets/custom_image.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  PostModel? _selectedPost;
  bool _isFirstLoad = true;

  void _onMarkerTapped(PostModel post) {
    setState(() {
      _selectedPost = post;
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(post.latitude, post.longitude), zoom: 15),
        ),
      );
    }
  }

  Future<void> _openGoogleMaps(BuildContext context, PostModel post) async {
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

  Future<void> _openAppleMaps(BuildContext context, PostModel post) async {
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

  void _showDirectionsOptions(BuildContext context, PostModel post) {
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
                  'Get Directions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_rounded, color: Colors.green),
                title: const Text('Open in Google Maps'),
                subtitle: const Text('Get directions using Google Maps app'),
                onTap: () {
                  Navigator.pop(context);
                  _openGoogleMaps(context, post);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.compass_calibration_rounded, color: Colors.blue),
                title: const Text('Open in Apple Maps'),
                subtitle: const Text('Get directions using Apple Maps app'),
                onTap: () {
                  Navigator.pop(context);
                  _openAppleMaps(context, post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(postsNotifierProvider);

    // Listen to focus provider for active panning when the screen is already active
    ref.listen<PostModel?>(focusedPostProvider, (previous, next) {
      if (next != null) {
        final loc = LatLng(next.latitude, next.longitude);
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: loc, zoom: 15),
            ),
          );
        }
        setState(() {
          _selectedPost = next;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(focusedPostProvider.notifier).setPost(null);
        });
      }
    });

    // Check synchronous focus state on first load build
    LatLng initialCenter = const LatLng(11.1271, 78.6569); // Default Tamil Nadu
    double initialZoom = 7.0;

    if (_isFirstLoad) {
      final focusedPost = ref.read(focusedPostProvider);
      if (focusedPost != null) {
        initialCenter = LatLng(focusedPost.latitude, focusedPost.longitude);
        initialZoom = 15.0;
        _selectedPost = focusedPost;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(focusedPostProvider.notifier).setPost(null);
        });
      }
      _isFirstLoad = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              try {
                final position = await Geolocator.getCurrentPosition();
                final userLatLng = LatLng(position.latitude, position.longitude);
                if (_mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: userLatLng, zoom: 15),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to query current location.')),
                );
              }
            },
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          final googleMarkers = posts.map((post) {
            return Marker(
              markerId: MarkerId(post.id),
              position: LatLng(post.latitude, post.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                post.type == 'found' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
              ),
              onTap: () => _onMarkerTapped(post),
            );
          }).toSet();

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialCenter,
                  zoom: initialZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (_) {
                  setState(() {
                    _selectedPost = null;
                  });
                },
                markers: googleMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Selected Item Detail Card Overlay at the bottom
              if (_selectedPost != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      key: ValueKey(_selectedPost!.id),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(post: _selectedPost!),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomImage(
                                  imageUrl: _selectedPost!.imageUrl,
                                  category: _selectedPost!.category,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title, Location, Action
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _selectedPost!.category,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _selectedPost!.type == 'found'
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _selectedPost!.type == 'found' ? 'Found' : 'Lost',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: _selectedPost!.type == 'found'
                                                  ? Colors.green.shade900
                                                  : Colors.orange.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedPost!.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedPost!.locationName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.directions_rounded, size: 14),
                                          label: const Text(
                                            'Get Directions',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () {
                                            _showDirectionsOptions(context, _selectedPost!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading map markers: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
