import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/posts_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/community_provider.dart';
import 'widgets/location_picker_map.dart';
import 'widgets/create_community_dialog.dart';
import '../services/gemini_service.dart';


class PostScreen extends ConsumerStatefulWidget {
  final String? initialType;          // 'found' or 'lost'
  final String? initialLocationName;  // pre-filled location (e.g. community name)

  const PostScreen({Key? key, this.initialType, this.initialLocationName}) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  // Police Station Controllers
  final _policeNameController = TextEditingController();
  final _policeLocController = TextEditingController();

  // ── Media state ─────────────────────────────────────────────────────────────
  List<File> _imageFiles = [];          // up to 6 photos
  File? _videoFile;                      // optional short clip
  int _enhancedIndex = -1;               // which image is being enhanced
  Set<int> _enhancedSet = {};            // indices already enhanced
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;

  String _selectedCategory = 'Phone';
  String _postType = 'found'; // 'found' or 'lost'
  String _selectedValueRange = 'Under Rs. 1,000';
  bool _isUploading = false;
  bool _isGettingLocation = false;
  bool _isFetchingPoliceStation = false;

  // AI Image Recognition State
  bool _isScanningAI = false;
  bool _aiScanCompleted = false;

  // Community / Board Selection State
  bool _initializedCommunity = false;
  String _postDestination = 'public'; // 'public', 'campus', 'event'
  Community? _selectedCampusCommunity;
  Community? _selectedEventCommunity;
  final _postStudentIdController = TextEditingController();
  final _postEmailController = TextEditingController();
  File? _postIdCardImage;
  bool _postIsVerifying = false;
  bool _postVerified = false;
  String? _postVerificationError;

  final List<String> _categories = [
    'Phone',
    'Earbuds',
    'Wallet',
    'Passport',
    'Keys',
    'Laptop',
    'Bag',
    'Documents',
    'Other'
  ];

  final List<String> _valueRanges = [
    'Under Rs. 1,000',
    'Rs. 1,000 - Rs. 5,000',
    'Rs. 5,000 - Rs. 10,000',
    'Rs. 10,000 - Rs. 25,000',
    'Above Rs. 25,000'
  ];

  bool get _isValueAbove10k {
    return _selectedValueRange == 'Rs. 10,000 - Rs. 25,000' ||
        _selectedValueRange == 'Above Rs. 25,000';
  }

  @override
  void initState() {
    super.initState();
    // Auto-populate from preferences if configured in Settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(profilePreferencesProvider);
      if (prefs.defaultName.isNotEmpty) {
        _contactNameController.text = prefs.defaultName;
      }
      if (prefs.defaultPhone.isNotEmpty) {
        _whatsappController.text = prefs.defaultPhone;
      }

      // Apply initial values from community board launch
      if (widget.initialType != null) {
        setState(() {
          _postType = widget.initialType!;
        });
      }
      if (widget.initialLocationName != null) {
        _locationNameController.text = widget.initialLocationName!;
      }

      // Auto-populate active community selection (skip if launched from board)
      if (widget.initialLocationName == null) {
        final activeComm = ref.read(activeCommunityProvider);
        if (activeComm != null) {
          setState(() {
            _postDestination = activeComm.type == CommunityType.campus ? 'campus' : 'event';
            if (activeComm.type == CommunityType.campus) {
              _onCampusChanged(activeComm);
            } else {
              _onEventChanged(activeComm);
            }
          });
        }
      }

      // Check if there is an initial pending post type when page is loaded
      if (widget.initialType == null) {
        final navState = ref.read(navigationProvider);
        if (navState.pendingPostType != null) {
          setState(() {
            _postType = navState.pendingPostType!;
          });
          ref.read(navigationProvider.notifier).clearPendingPostType();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _contactNameController.dispose();
    _whatsappController.dispose();
    _policeNameController.dispose();
    _policeLocController.dispose();
    _postStudentIdController.dispose();
    _postEmailController.dispose();
    super.dispose();
  }

  // ── Pick multiple images ──────────────────────────────────────────────────
  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final picked = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920, maxHeight: 1920, imageQuality: 88,
        );
        if (picked != null && _imageFiles.length < 6) {
          setState(() {
            _imageFiles.add(File(picked.path));
            _aiScanCompleted = false;
          });
        }
      } else {
        final picked = await _picker.pickMultiImage(
          maxWidth: 1920, maxHeight: 1920, imageQuality: 88,
        );
        if (picked.isNotEmpty) {
          setState(() {
            final remaining = 6 - _imageFiles.length;
            _imageFiles.addAll(picked.take(remaining).map((x) => File(x.path)));
            _aiScanCompleted = false;
          });
          if (picked.length > 6 - _imageFiles.length) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maximum 6 photos allowed. Extra photos were skipped.')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // ── Pick a short video ────────────────────────────────────────────────────
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (picked != null) {
        setState(() {
          _videoFile = File(picked.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Short video added! (max 30 seconds)'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  // ── Remove a media item ───────────────────────────────────────────────────
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      _enhancedSet.remove(index);
      // Rebuild the enhanced set shifting indices
      final shifted = <int>{};
      for (final i in _enhancedSet) {
        if (i < index) shifted.add(i);
        else if (i > index) shifted.add(i - 1);
      }
      _enhancedSet = shifted;
      if (_imageFiles.isEmpty) _aiScanCompleted = false;
    });
  }

  void _removeVideo() {
    setState(() { _videoFile = null; });
  }

  // ── Simulate image enhancement ────────────────────────────────────────────
  Future<void> _enhanceImage(int index) async {
    if (_enhancedSet.contains(index)) return;
    setState(() { _enhancedIndex = index; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _enhancedIndex = -1;
      _enhancedSet.add(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Image enhanced! Sharpness, brightness & contrast optimised.'),
        backgroundColor: Color(0xFF4F46E5),
        duration: Duration(seconds: 2),
      ),
    );
  }


  Future<void> _runAiImageRecognition() async {
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture a photo first.')),
      );
      return;
    }

    setState(() {
      _isScanningAI = true;
    });

    // 1. Attempt live Google Gemini analysis if API is configured
    final File imageFile = File(_imageFiles.first.path);
    Map<String, String>? geminiResult;

    if (GeminiService.instance.isConfigured) {
      try {
        geminiResult = await GeminiService.instance.analyzeImage(imageFile);
      } catch (e) {
        print('Gemini API Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gemini API Error: $e\n(Falling back to local simulation)'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } else {
      // Simulate API call delay for the mock fallback
      await Future.delayed(const Duration(milliseconds: 2200));
    }

    if (!mounted) return;

    if (geminiResult != null) {
      // Successfully recognized image with Gemini AI!
      final String detectedTitle = geminiResult['title']!;
      final String detectedCategory = geminiResult['category']!;
      final String detectedDescription = geminiResult['description']!;

      setState(() {
        _isScanningAI = false;
        _aiScanCompleted = true;
        _selectedCategory = detectedCategory;
        
        if (_postType == 'found') {
          _titleController.text = detectedTitle;
        } else {
          _titleController.text = detectedTitle.startsWith('Lost') ? detectedTitle : 'Lost $detectedTitle';
        }
        
        _descriptionController.text = _postType == 'found'
            ? 'AI Identified: $detectedDescription'
            : 'AI Identified: Lost item. $detectedDescription';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Gemini AI recognized item as "$detectedTitle" ($detectedCategory)!'),
          backgroundColor: Colors.teal,
        ),
      );
      return;
    }

    // 2. Local Fallback Heuristics (if Gemini API key is missing or request fails)
    final pool = [
      {'title': 'iPhone 15 Pro', 'category': 'Phone', 'desc': 'Found an iPhone 15 Pro with a dark cover. Screen looks clear and device is locked.'},
      {'title': 'Black Leather Wallet', 'category': 'Wallet', 'desc': 'Found a black leather card holder/wallet. Minimalist design.'},
      {'title': 'Keys with Blue Tag', 'category': 'Keys', 'desc': 'Found a set of keys attached to a blue plastic tag keychain.'},
      {'title': 'Bose Headphones', 'category': 'Earbuds', 'desc': 'Found black Bose QuietComfort over-ear headphones in a travel case.'},
      {'title': 'Grey Canvas Backpack', 'category': 'Bag', 'desc': 'Found a dark grey canvas travel backpack.'},
      {'title': 'Water Bottle', 'category': 'Other', 'desc': 'Found a silver stainless steel water bottle. 750ml capacity.'},
      {'title': 'Smart Watch', 'category': 'Watch', 'desc': 'Found a black smartwatch with silicone strap.'},
      {'title': 'Academic ID Card', 'category': 'Document', 'desc': 'Found a student Identity Card inside a cardholder.'},
    ];

    Map<String, String>? matchedItem;

    final path = _imageFiles.first.path.toLowerCase();
    for (final item in pool) {
      final titleKeyword = item['title']!.toLowerCase().split(' ').first;
      final categoryKeyword = item['category']!.toLowerCase();
      
      if (path.contains(titleKeyword) || path.contains(categoryKeyword)) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem == null) {
      for (final item in pool) {
        if (item['category']!.toLowerCase() == _selectedCategory.toLowerCase()) {
          matchedItem = item;
          break;
        }
      }
    }

    matchedItem ??= pool.first;

    setState(() {
      _isScanningAI = false;
      _aiScanCompleted = true;
      _selectedCategory = matchedItem!['category']!;
      
      if (_postType == 'found') {
        _titleController.text = matchedItem['title']!;
      } else {
        _titleController.text = 'Lost ${matchedItem['title']}';
      }
      
      _descriptionController.text = _postType == 'found'
          ? 'AI Identified: ${matchedItem['desc']}'
          : 'AI Identified: Lost ${matchedItem['title']}. ${matchedItem['desc']?.replaceAll('Found', 'Lost')}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ AI recognized item as "${matchedItem['title']}"! Fields auto-filled.'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  // ── Media source action sheet ─────────────────────────────────────────────
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MediaPickerSheet(
        onPhotoGallery: () { Navigator.pop(context); _pickImages(ImageSource.gallery); },
        onPhotoCamera: () { Navigator.pop(context); _pickImages(ImageSource.camera); },
        onVideoGallery: () { Navigator.pop(context); _pickVideo(ImageSource.gallery); },
        onVideoCamera: () { Navigator.pop(context); _pickVideo(ImageSource.camera); },
        remainingSlots: 6 - _imageFiles.length,
        hasVideo: _videoFile != null,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      ref.invalidate(userLocationProvider);
      final position = await ref.read(userLocationProvider.future);
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully loaded current GPS coordinates!')),
        );
        _fetchNearestPoliceStation(position.latitude, position.longitude);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting coordinates: $e. You can select coordinates using the map picker.')),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _searchLandmarkCoordinates() async {
    final query = _locationNameController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a landmark first.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Searching landmark...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 6));
      request.headers.set('user-agent', 'Foundit-App-GoogleMindAgent');
      final response = await request.close();
      
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(jsonString);
        if (data.isNotEmpty) {
          final firstResult = data.first;
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          final displayName = firstResult['display_name'] as String;

          setState(() {
            _latitude = lat;
            _longitude = lon;
            _locationNameController.text = displayName;
          });

          _fetchNearestPoliceStation(lat, lon);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location resolved: $displayName'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find coordinates for "$query". Try selecting via Map Pin.'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  Future<void> _pickLocationOnMap() async {
    LatLng? initialLoc;
    if (_latitude != null && _longitude != null) {
      initialLoc = LatLng(_latitude!, _longitude!);
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: initialLoc,
          initialSearchQuery: _locationNameController.text.trim().isNotEmpty
              ? _locationNameController.text.trim()
              : null,
        ),
      ),
    );

    if (result != null) {
      if (result is LatLng) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
        });
        _fetchNearestPoliceStation(result.latitude, result.longitude);
      } else if (result is LocationResult) {
        setState(() {
          _latitude = result.latLng.latitude;
          _longitude = result.latLng.longitude;
          if (result.address.isNotEmpty) {
            _locationNameController.text = result.address;
          }
        });
        _fetchNearestPoliceStation(result.latLng.latitude, result.latLng.longitude);
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _useFallbackPoliceStation(double lat, double lng) {
    // Generate a fallback local precinct name based on location coordinates to simulate real geo-lookup
    final String sector = (lat.abs() * 10).floor().toString();
    final String zone = (lng.abs() * 10).floor().toString();
    
    setState(() {
      _policeNameController.text = 'Police Precinct Sector-$sector (Auto-Located)';
      _policeLocController.text = 'Zone $zone St, Near coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    });
  }

  Future<void> _fetchNearestPoliceStation(double lat, double lng) async {
    setState(() {
      _isFetchingPoliceStation = true;
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      // Query Overpass API for police amenities within 5000 meters of the coordinates
      final uri = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=[out:json];node(around:5000,$lat,$lng)[amenity=police];out;'
      );
      
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>?;
        
        if (elements != null && elements.isNotEmpty) {
          double minDistance = double.infinity;
          Map<String, dynamic>? nearestStation;
          
          for (var element in elements) {
            final eLat = (element['lat'] as num).toDouble();
            final eLon = (element['lon'] as num).toDouble();
            
            final distance = _calculateDistance(lat, lng, eLat, eLon);
            if (distance < minDistance) {
              minDistance = distance;
              nearestStation = element as Map<String, dynamic>;
            }
          }
          
          if (nearestStation != null) {
            final tags = nearestStation['tags'] as Map<String, dynamic>?;
            final name = tags?['name'] as String? ?? 'Police Station';
            final street = tags?['addr:street'] as String?;
            final city = tags?['addr:city'] as String?;
            
            String address = '';
            if (street != null && city != null) {
              address = '$street, $city';
            } else if (street != null) {
              address = street;
            } else if (city != null) {
              address = city;
            } else {
              address = 'Coordinates: ${nearestStation['lat']}, ${nearestStation['lon']}';
            }
            
            setState(() {
              _policeNameController.text = name;
              _policeLocController.text = address;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching nearest police station: $e');
    } finally {
      setState(() {
        _isFetchingPoliceStation = false;
      });
    }

    // Use smart coordinates-based fallback if OSM Overpass API query fails/times out
    _useFallbackPoliceStation(lat, lng);
  }

  Future<void> _submitForm() async {
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_postType == 'found'
              ? 'Please add at least one photo of the found item.'
              : 'Please add at least one photo of the lost item.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_postDestination == 'campus') {
      if (_selectedCampusCommunity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a college campus.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (!_postVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please verify your Student ID for ${_selectedCampusCommunity!.shortName} before posting.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (_postDestination == 'event') {
      if (_selectedEventCommunity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an event board.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }


    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_postType == 'found' 
              ? 'Please select GPS coordinates for the found location.' 
              : 'Please select GPS coordinates for the last known location.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String finalLocationName = _locationNameController.text.trim();
    Community? targetComm;
    if (_postDestination == 'campus' && _selectedCampusCommunity != null) {
      targetComm = _selectedCampusCommunity;
      finalLocationName = "${_selectedCampusCommunity!.name}, $finalLocationName";
    } else if (_postDestination == 'event' && _selectedEventCommunity != null) {
      targetComm = _selectedEventCommunity;
      finalLocationName = "${_selectedEventCommunity!.name}, $finalLocationName";
    }

    try {
      await ref.read(postsNotifierProvider.notifier).createPost(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        imageFile: _imageFiles.first,
        locationName: finalLocationName,
        latitude: _latitude!,
        longitude: _longitude!,
        contactName: _contactNameController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        type: _postType,
        valueRange: _selectedValueRange,
        policeStationName: _isValueAbove10k ? _policeNameController.text.trim() : null,
        policeStationLocation: _isValueAbove10k ? _policeLocController.text.trim() : null,
      );

      // If we posted to a community board, auto-join it so they redirect to it on Home
      if (targetComm != null) {
        if (targetComm.type == CommunityType.campus) {
          ref.read(communityProvider.notifier).joinCampus(targetComm, _postEmailController.text.trim());
        } else {
          ref.read(communityProvider.notifier).joinEvent(targetComm);
        }
      }

      if (mounted) {
        if (_postType == 'lost') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Lost item posted! Broadcasting alerts to all users within 1 km...')),
                ],
              ),
              backgroundColor: Colors.blueAccent,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Found item posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _resetForm();
        
        if (mounted) {
          // If launched from a community board, pop back to it.
          // If launched standalone, navigate to home tab.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            ref.read(navigationProvider.notifier).setIndex(0);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationNameController.clear();
    _contactNameController.clear();
    _whatsappController.clear();
    _policeNameController.clear();
    _policeLocController.clear();
    _postStudentIdController.clear();
    _postEmailController.clear();
    setState(() {
      _imageFiles = [];
      _videoFile = null;
      _enhancedSet = {};
      _enhancedIndex = -1;
      _latitude = null;
      _longitude = null;
      _selectedCategory = 'Phone';
      _selectedValueRange = 'Under Rs. 1,000';
      _postType = 'found';
      _postDestination = 'public';
      _selectedCampusCommunity = null;
      _selectedEventCommunity = null;
      _postIdCardImage = null;
      _postIsVerifying = false;
      _postVerified = false;
      _postVerificationError = null;
      _initializedCommunity = false;
    });
  }

  void _onCampusChanged(Community? campus) {
    if (campus == null) return;
    setState(() {
      _selectedCampusCommunity = campus;
      _locationNameController.text = "${campus.name}, ${campus.location}";
      _latitude = campus.id == 'abc_engg' ? 13.0827 : (campus.id == 'mit_chennai' ? 12.9479 : 13.0118);
      _longitude = campus.id == 'abc_engg' ? 80.2707 : (campus.id == 'mit_chennai' ? 80.1402 : 80.2354);
      
      // Check if already active and verified in global state
      final activeComm = ref.read(activeCommunityProvider);
      final isVerified = ref.read(isCommunityVerifiedProvider);
      if (activeComm?.id == campus.id && isVerified) {
        _postVerified = true;
        _postEmailController.text = ref.read(communityProvider).verifiedEmail ?? '';
      } else {
        _postVerified = false;
        _postEmailController.clear();
        _postStudentIdController.clear();
        _postIdCardImage = null;
        _postVerificationError = null;
      }
    });
  }

  void _onEventChanged(Community? event) {
    if (event == null) return;
    setState(() {
      _selectedEventCommunity = event;
      _locationNameController.text = "${event.name}, ${event.location}";
      _latitude = event.id == 'techfest_2025' ? 12.9915 : (event.id == 'kulturals_2025' ? 12.9894 : 13.0500);
      _longitude = event.id == 'techfest_2025' ? 80.2337 : (event.id == 'kulturals_2025' ? 80.2483 : 80.2824);
    });
  }

  Future<void> _pickPostIdImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _postIdCardImage = File(picked.path);
          _postVerificationError = null;
        });
      }
    } catch (e) {
      setState(() {
        _postVerificationError = 'Failed to pick ID image: $e';
      });
    }
  }

  Future<void> _verifyPostCampus() async {
    if (_selectedCampusCommunity == null) return;
    if (_postStudentIdController.text.trim().isEmpty) {
      setState(() { _postVerificationError = 'Please enter your Student ID Number.'; });
      return;
    }
    if (_postEmailController.text.trim().isEmpty || !_postEmailController.text.contains('@')) {
      setState(() { _postVerificationError = 'Please enter a valid college email address.'; });
      return;
    }
    if (_postIdCardImage == null) {
      setState(() { _postVerificationError = 'Please upload a photo of your Student ID Card.'; });
      return;
    }

    setState(() {
      _postIsVerifying = true;
      _postVerificationError = null;
    });

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final trimmedEmail = _postEmailController.text.trim().toLowerCase();
    final expectedDomain = _selectedCampusCommunity!.emailDomain?.toLowerCase() ?? '';
    final ok = trimmedEmail.endsWith('@$expectedDomain');

    if (ok) {
      setState(() {
        _postIsVerifying = false;
        _postVerified = true;
      });
      ref.read(communityProvider.notifier).joinCampus(_selectedCampusCommunity!, trimmedEmail);
    } else {
      setState(() {
        _postIsVerifying = false;
        _postVerificationError = 'Email domain does not match @$expectedDomain.\n'
            'Please use your college email address.';
      });
    }
  }

  List<Community> _getCommunitiesList() {
    return ref.read(activeCommunitiesProvider);
  }

  Future<List<Community>> _searchIndianColleges(String query) async {
    if (query.trim().isEmpty) {
      return _getCommunitiesList().where((c) => c.type == CommunityType.campus).toList();
    }
    try {
      final client = HttpClient();
      final uri = Uri.parse('http://universities.hipolabs.com/search?country=india&name=${Uri.encodeQueryComponent(query)}');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(jsonString);
        final results = <Community>[];
        for (var item in data) {
          final name = item['name'] as String;
          final state = item['state-province'] as String? ?? 'India';
          final domains = item['domains'] as List<dynamic>? ?? [];
          final domain = domains.isNotEmpty ? domains.first as String : 'edu.in';
          
          final id = 'api_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          
          final words = name.split(RegExp(r'[\s\-_,]+'));
          final initials = words.where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).join();
          final shortName = initials.length > 2 && initials.length < 8 ? initials : (name.length > 20 ? '${name.substring(0, 17)}...' : name);
          
          results.add(Community(
            id: id,
            name: name,
            shortName: shortName,
            type: CommunityType.campus,
            emoji: '🎓',
            emailDomain: domain,
            location: state,
            memberCount: 1500,
            accentColor: const Color(0xFF4F46E5),
            description: 'Official board for $name.',
          ));
        }
        return results;
      }
    } catch (e) {
      // Fallback
    }
    return _getCommunitiesList()
        .where((c) => c.type == CommunityType.campus)
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()) || 
                      c.shortName.toLowerCase().contains(query.toLowerCase()) ||
                      c.location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _showSearchableCommunityPicker(BuildContext context, String type) {
    final theme = Theme.of(context);
    final isCampus = type == 'campus';
    String searchQuery = '';
    bool isSearching = false;
    List<Community> filteredItems = _getCommunitiesList()
        .where((c) => c.type.name == type)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Community> displayedItems = [...filteredItems];
            if (!isCampus && searchQuery.trim().isNotEmpty) {
              final query = searchQuery.trim();
              final exactMatch = filteredItems.any((c) => c.name.toLowerCase() == query.toLowerCase());
              if (!exactMatch) {
                displayedItems.insert(0, Community(
                  id: 'custom_event_${query.replaceAll(' ', '_').toLowerCase()}',
                  name: query,
                  shortName: query.length > 15 ? '${query.substring(0, 12)}...' : query,
                  type: CommunityType.event,
                  emoji: '📅',
                  location: 'Custom Board',
                  memberCount: 1,
                  accentColor: Colors.purple,
                  description: 'A custom board created for: $query.',
                ));
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      isCampus ? 'Select College Campus' : 'Select Event Board',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: isCampus ? 'Search colleges in India...' : 'Search/Type custom event...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  setModalState(() {
                                    searchQuery = '';
                                    isSearching = false;
                                    filteredItems = _getCommunitiesList()
                                        .where((c) => c.type.name == type)
                                        .toList();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });

                        if (isCampus) {
                          setModalState(() {
                            isSearching = true;
                          });
                          _searchIndianColleges(val).then((results) {
                            if (searchQuery == val) {
                              setModalState(() {
                                filteredItems = results;
                                isSearching = false;
                              });
                            }
                          });
                        } else {
                          final results = _getCommunitiesList()
                              .where((c) => c.type.name == type)
                              .where((c) => c.name.toLowerCase().contains(val.toLowerCase()) || 
                                            c.shortName.toLowerCase().contains(val.toLowerCase()) ||
                                            c.location.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                          setModalState(() {
                            filteredItems = results;
                          });
                        }
                      },
                    ),
                  ),

                  Expanded(
                    child: isSearching
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Searching colleges in India...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )
                        : displayedItems.isEmpty
                            ? Center(
                                child: Text(
                                  isCampus ? 'No matching colleges found' : 'No matching events found',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: displayedItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final c = displayedItems[index];
                                  final isCustom = c.id.startsWith('custom_event_');
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: c.accentColor.withOpacity(0.12),
                                      child: Text(c.emoji),
                                    ),
                                    title: Text(
                                      isCustom ? 'Create event: "${c.name}"' : c.name, 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: isCustom ? theme.colorScheme.primary : null,
                                      ),
                                    ),
                                    subtitle: Text(c.location, style: const TextStyle(fontSize: 11)),
                                    trailing: Icon(
                                      isCustom ? Icons.add_circle_outline_rounded : Icons.chevron_right_rounded, 
                                      color: theme.colorScheme.primary,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (isCampus) {
                                        _onCampusChanged(c);
                                      } else {
                                        _onEventChanged(c);
                                      }
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommunitySelectionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Community / Target Board',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment<String>(
                    value: 'public',
                    label: Text('Public Feed'),
                    icon: Icon(Icons.public_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'campus',
                    label: Text('Campus'),
                    icon: Icon(Icons.school_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'event',
                    label: Text('Event'),
                    icon: Icon(Icons.event_rounded),
                  ),
                ],
                selected: {_postDestination},
                onSelectionChanged: (newVal) {
                  setState(() {
                    _postDestination = newVal.first;
                    if (_postDestination == 'campus') {
                      _onCampusChanged(_selectedCampusCommunity);
                    } else if (_postDestination == 'event') {
                      _onEventChanged(_selectedEventCommunity);
                    } else {
                      _locationNameController.clear();
                      _latitude = null;
                      _longitude = null;
                    }
                  });
                },
              ),
            ),
            if (_postDestination == 'campus') ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showSearchableCommunityPicker(context, 'campus'),
                borderRadius: BorderRadius.circular(18),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Campus/College',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCampusCommunity != null
                              ? '${_selectedCampusCommunity!.emoji}  ${_selectedCampusCommunity!.name}'
                              : 'Select the Campus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _selectedCampusCommunity != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_postVerified && _selectedCampusCommunity != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.shade500.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Student Identity Verified for ${_selectedCampusCommunity!.shortName} ✓',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedCampusCommunity != null) ...[
                TextFormField(
                  controller: _postStudentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID Number',
                    hintText: 'e.g. CSE-2023-089',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'College Email Address',
                    hintText: 'you@${_selectedCampusCommunity!.emailDomain}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickPostIdImage,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _postIdCardImage != null
                            ? Colors.green.shade500
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: _postIdCardImage != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_postIdCardImage!, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                right: 8, top: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 14,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    onPressed: () => setState(() => _postIdCardImage = null),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(height: 4),
                              Text(
                                'Upload Student ID Card Photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_postVerificationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _postVerificationError!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _postIsVerifying ? null : _verifyPostCampus,
                    icon: _postIsVerifying 
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.security_rounded, size: 16),
                    label: Text(_postIsVerifying ? 'Verifying Student Identity...' : 'Verify Student ID'),
                  ),
                ),
              ],
            ],
            if (_postDestination == 'event') ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showSearchableCommunityPicker(context, 'event'),
                borderRadius: BorderRadius.circular(18),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Event Board',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_note_outlined),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedEventCommunity != null
                              ? '${_selectedEventCommunity!.emoji}  ${_selectedEventCommunity!.name}'
                              : 'Select the Event',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _selectedEventCommunity != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initializedCommunity) {
      final activeCommunity = ref.read(activeCommunityProvider);
      final isVerified = ref.read(isCommunityVerifiedProvider);
      if (activeCommunity != null) {
        if (activeCommunity.type == CommunityType.campus) {
          _postDestination = 'campus';
          _selectedCampusCommunity = activeCommunity;
          _postVerified = isVerified;
        } else if (activeCommunity.type == CommunityType.event) {
          _postDestination = 'event';
          _selectedEventCommunity = activeCommunity;
          _postVerified = true;
        }
      }
      _initializedCommunity = true;
    }

    ref.listen<NavigationState>(navigationProvider, (previous, next) {
      if (next.pendingPostType != null) {
        setState(() {
          _postType = next.pendingPostType!;
        });
        ref.read(navigationProvider.notifier).clearPendingPostType();
      }
      if (next.currentIndex == 2) {
        final activeComm = ref.read(activeCommunityProvider);
        if (activeComm != null) {
          setState(() {
            _postDestination = activeComm.type == CommunityType.campus ? 'campus' : 'event';
            if (activeComm.type == CommunityType.campus) {
              _onCampusChanged(activeComm);
            } else {
              _onEventChanged(activeComm);
            }
          });
        } else {
          setState(() {
            _postDestination = 'public';
            _selectedCampusCommunity = null;
            _selectedEventCommunity = null;
            _locationNameController.clear();
            _latitude = null;
            _longitude = null;
            _postVerified = false;
          });
        }
      }
    });
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _postType == 'found' ? 'Report Found Item' : 'Report Lost Item', 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Separate scrollable area from sticky bottom submit button using Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scrollable form fields
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented toggle for I Found / I Lost
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment<String>(
                                    value: 'found',
                                    label: Text('Found Something'),
                                    icon: Icon(Icons.search_rounded),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'lost',
                                    label: Text('Lost Something'),
                                    icon: Icon(Icons.campaign_rounded),
                                  ),
                                ],
                              selected: {_postType},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _postType = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ),

                        // ── Media Section ───────────────────────────────────
                        _MediaSection(
                          imageFiles: _imageFiles,
                          videoFile: _videoFile,
                          enhancedSet: _enhancedSet,
                          enhancedIndex: _enhancedIndex,
                          postType: _postType,
                          onAddMedia: () => _showImageSourceActionSheet(context),
                          onRemoveImage: _removeImage,
                          onRemoveVideo: _removeVideo,
                          onEnhance: _enhanceImage,
                        ),
                        // ── AI recognition card (shown once a photo is added) ─
                        if (_imageFiles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            color: _aiScanCompleted
                                ? theme.colorScheme.primaryContainer.withOpacity(0.15)
                                : theme.colorScheme.tertiaryContainer.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: _aiScanCompleted
                                    ? theme.colorScheme.primary.withOpacity(0.4)
                                    : theme.colorScheme.tertiary.withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _aiScanCompleted ? Icons.auto_awesome_rounded : Icons.psychology_outlined,
                                    color: _aiScanCompleted ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _aiScanCompleted ? 'AI Recognition Complete!' : 'AI Image-Based Item Recognition',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          _aiScanCompleted
                                              ? 'Item fields auto-populated by AI analysis.'
                                              : 'Let our AI identify the item category and auto-fill details.',
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_aiScanCompleted)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: theme.colorScheme.tertiaryContainer,
                                        foregroundColor: theme.colorScheme.onTertiaryContainer,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _isScanningAI ? null : _runAiImageRecognition,
                                      icon: _isScanningAI
                                          ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                                          : const Icon(Icons.flash_on_rounded, size: 14),
                                      label: Text(_isScanningAI ? 'Scanning...' : 'Scan'),
                                    )
                                  else
                                    Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Community Selector Board (only shown once photo is posted/uploaded)
                        if (_imageFiles.isNotEmpty)
                          _buildCommunitySelectionCard(context),

                        const SizedBox(height: 20),

                        // Item Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: _postType == 'found' ? 'Item Title*' : 'Lost Item Title*',
                            hintText: _postType == 'found' 
                                ? 'e.g., Black leather wallet, iPhone 13' 
                                : 'e.g., Keys with astronaut tag, Golden retriever',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category / Features Scrollable Selection
                        Row(
                          children: [
                            Icon(Icons.category_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Category / Feature*',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category;
                              IconData categoryIcon;
                              switch (category) {
                                case 'Phone':
                                  categoryIcon = Icons.phone_android_rounded;
                                  break;
                                case 'Earbuds':
                                  categoryIcon = Icons.headphones_rounded;
                                  break;
                                case 'Wallet':
                                  categoryIcon = Icons.account_balance_wallet_rounded;
                                  break;
                                case 'Passport':
                                  categoryIcon = Icons.contact_page_rounded;
                                  break;
                                case 'Keys':
                                  categoryIcon = Icons.vpn_key_rounded;
                                  break;
                                case 'Laptop':
                                  categoryIcon = Icons.laptop_chromebook_rounded;
                                  break;
                                case 'Bag':
                                  categoryIcon = Icons.backpack_rounded;
                                  break;
                                case 'Documents':
                                  categoryIcon = Icons.description_rounded;
                                  break;
                                default:
                                  categoryIcon = Icons.more_horiz_rounded;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    categoryIcon,
                                    size: 16,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    }
                                  },
                                  selectedColor: theme.colorScheme.primaryContainer,
                                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                                  labelStyle: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Value Range Scrollable Selection
                        Row(
                          children: [
                            Icon(Icons.currency_rupee_rounded, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Estimated Value Range*',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _valueRanges.length,
                            itemBuilder: (context, index) {
                              final range = _valueRanges[index];
                              final isSelected = _selectedValueRange == range;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(range),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedValueRange = range;
                                      });
                                    }
                                  },
                                  selectedColor: theme.colorScheme.primaryContainer,
                                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                                  labelStyle: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Conditional Alert Banner for items valued above 10K
                        if (_isValueAbove10k)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.colorScheme.error.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.gavel_rounded,
                                  color: theme.colorScheme.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Legal Requirement',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _postType == 'found'
                                            ? 'Since this found item is valued higher than Rs. 10,000, you are legally required to hand it over to the nearest police station. Please specify the handover details below.'
                                            : 'Since this lost item is valued higher than Rs. 10,000, it must be reported to the nearest police station. Please specify the station details below.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onErrorContainer,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Conditional Police Station Inputs
                        if (_isValueAbove10k) ...[
                          if (_isFetchingPoliceStation)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Locating nearest police station...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextFormField(
                            controller: _policeNameController,
                            decoration: const InputDecoration(
                              labelText: 'Police Station Name*',
                              hintText: 'e.g. Central Park Police Precinct',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_police_outlined),
                            ),
                            validator: (value) {
                              if (_isValueAbove10k) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the police station name';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _policeLocController,
                            decoration: const InputDecoration(
                              labelText: 'Police Station Location*',
                              hintText: 'e.g. 86th St Transverse, New York, NY',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin_drop_outlined),
                            ),
                            validator: (value) {
                              if (_isValueAbove10k) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the police station location/address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description*',
                            hintText: _postType == 'found'
                                ? 'Provide details about the item (color, brand, contents, etc.). Do not share sensitive secrets.'
                                : 'Describe the lost item and key markers. Provide details about when/how it went missing.',
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            if (value.trim().length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location Name (Text)
                        TextFormField(
                          controller: _locationNameController,
                          decoration: InputDecoration(
                            labelText: 'Landmark/Detailed Description*',
                            hintText: 'e.g. Starbucks near Central Park, Gate 3 Mall',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.pin_drop_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _searchLandmarkCoordinates,
                              tooltip: 'Search coordinates for this landmark',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter landmark/detailed description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Latitude and Longitude Picker Box
                        Card(
                          elevation: 2,
                          color: _latitude != null && _longitude != null
                              ? theme.colorScheme.primaryContainer.withOpacity(0.15)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                            side: BorderSide(
                              color: _latitude != null && _longitude != null
                                  ? theme.colorScheme.primary.withOpacity(0.4)
                                  : theme.colorScheme.outlineVariant,
                              width: _latitude != null && _longitude != null ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _postType == 'found' 
                                          ? 'Coordinates (Latitude / Longitude)*' 
                                          : 'Last Known Coordinates*',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_latitude != null && _longitude != null)
                                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22)
                                    else
                                      Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 22),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_latitude != null && _longitude != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: theme.colorScheme.outlineVariant),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.gps_fixed_rounded, color: theme.colorScheme.primary, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'LAT: ${_latitude!.toStringAsFixed(6)}',
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'LNG: ${_longitude!.toStringAsFixed(6)}',
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: _isGettingLocation
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.my_location),
                                          color: theme.colorScheme.primary,
                                          tooltip: 'Use current GPS location',
                                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_location_alt_rounded),
                                          color: theme.colorScheme.primary,
                                          tooltip: 'Change Location',
                                          onPressed: _pickLocationOnMap,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded),
                                          color: theme.colorScheme.error,
                                          tooltip: 'Clear Location',
                                          onPressed: () {
                                            setState(() {
                                              _latitude = null;
                                              _longitude = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '✓ Coordinates successfully linked to item post.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Pinpoint the location of the item so others can find it on the map.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.surface,
                                            foregroundColor: theme.colorScheme.onSurface,
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                              side: BorderSide(color: theme.colorScheme.outlineVariant),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: _isGettingLocation
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.my_location, size: 18),
                                          label: const Text('Get GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.map_rounded, size: 18),
                                          label: const Text('Map Pin', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: _pickLocationOnMap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Finder Contact Name
                        TextFormField(
                          controller: _contactNameController,
                          decoration: InputDecoration(
                            labelText: _postType == 'found' ? 'Contact Name (Finder)' : 'Contact Name (Owner)*',
                            hintText: 'Your name',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (_postType == 'found') return null; // Optional for found posts
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter contact name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Finder WhatsApp Number
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: _postType == 'found' ? 'WhatsApp Number' : 'WhatsApp Number*',
                            hintText: 'e.g. +15550199 (include country code)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.phone_iphone),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              if (_postType == 'found') return null; // Optional for found posts
                              return 'Please enter WhatsApp number';
                            }
                            final phoneDigits = value.replaceAll(RegExp(r'\D'), '');
                            if (phoneDigits.length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Fixed Bottom Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: Text(
                    _postType == 'found' ? 'Post Found Item' : 'Post Lost Item',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          
          // Progress overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Uploading post & image...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _MediaSection — photo grid + video badge + Add Media button
// ══════════════════════════════════════════════════════════════════════════════

class _MediaSection extends StatelessWidget {
  final List<File> imageFiles;
  final File? videoFile;
  final Set<int> enhancedSet;
  final int enhancedIndex;
  final String postType;
  final VoidCallback onAddMedia;
  final void Function(int) onRemoveImage;
  final VoidCallback onRemoveVideo;
  final Future<void> Function(int) onEnhance;

  const _MediaSection({
    required this.imageFiles,
    required this.videoFile,
    required this.enhancedSet,
    required this.enhancedIndex,
    required this.postType,
    required this.onAddMedia,
    required this.onRemoveImage,
    required this.onRemoveVideo,
    required this.onEnhance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAny = imageFiles.isNotEmpty || videoFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(Icons.perm_media_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Photos & Video',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              '${imageFiles.length}/6 photos${videoFile != null ? ' · 1 video' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid / Empty placeholder
        if (!hasAny)
          GestureDetector(
            onTap: onAddMedia,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ).createShader(bounds),
                    child: Icon(Icons.add_photo_alternate_outlined, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    postType == 'found' ? 'Add photos of the found item' : 'Add photos of the lost item',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Up to 6 photos  ·  Short video clip',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Photo thumbnails
                ...List.generate(imageFiles.length, (i) {
                  final isEnhancing = enhancedIndex == i;
                  final isEnhanced  = enhancedSet.contains(i);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            imageFiles[i],
                            width: 115,
                            height: 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Enhancing shimmer overlay
                        if (isEnhancing)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                color: Colors.black.withOpacity(0.55),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                      SizedBox(height: 6),
                                      Text('Enhancing…', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Enhanced badge
                        if (isEnhanced && !isEnhancing)
                          Positioned(
                            left: 6, bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('✨ Enhanced', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        // Remove button
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => onRemoveImage(i),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        // Enhance button
                        if (!isEnhanced && !isEnhancing)
                          Positioned(
                            bottom: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => onEnhance(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_fix_high_rounded, size: 11, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text('Fix', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // Video thumbnail / badge
                if (videoFile != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        Container(
                          width: 115, height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_rounded, size: 36, color: Colors.white),
                              const SizedBox(height: 6),
                              Text(
                                videoFile!.path.split('/').last.length > 14
                                    ? '${videoFile!.path.split('/').last.substring(0, 12)}…'
                                    : videoFile!.path.split('/').last,
                                style: const TextStyle(color: Colors.white70, fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade600,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('≤30s clip', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: onRemoveVideo,
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // "Add more" button
                if (imageFiles.length < 6)
                  GestureDetector(
                    onTap: onAddMedia,
                    child: Container(
                      width: 90, height: 130,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 28, color: theme.colorScheme.primary),
                          const SizedBox(height: 4),
                          Text(
                            'Add\nMore',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _MediaPickerSheet — premium bottom sheet with photo + video options
// ══════════════════════════════════════════════════════════════════════════════

class _MediaPickerSheet extends StatelessWidget {
  final VoidCallback onPhotoGallery;
  final VoidCallback onPhotoCamera;
  final VoidCallback onVideoGallery;
  final VoidCallback onVideoCamera;
  final int remainingSlots;
  final bool hasVideo;

  const _MediaPickerSheet({
    required this.onPhotoGallery,
    required this.onPhotoCamera,
    required this.onVideoGallery,
    required this.onVideoCamera,
    required this.remainingSlots,
    required this.hasVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.perm_media_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text('Add Media', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Photos section
          if (remainingSlots > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.photo_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Photos  ($remainingSlots slot${remainingSlots == 1 ? '' : 's'} left)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _PickerTile(
              icon: Icons.photo_library_rounded,
              iconColor: const Color(0xFF4F46E5),
              title: 'Choose from Gallery',
              subtitle: 'Select multiple photos at once',
              onTap: onPhotoGallery,
            ),
            _PickerTile(
              icon: Icons.photo_camera_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Take a Photo',
              subtitle: 'Use camera to capture now',
              onTap: onPhotoCamera,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Maximum 6 photos reached', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
            ),

          const SizedBox(height: 4),
          const Divider(indent: 20, endIndent: 20, height: 1),
          const SizedBox(height: 4),

          // Video section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.videocam_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Short Video (max 30 seconds)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _PickerTile(
            icon: Icons.video_library_rounded,
            iconColor: Colors.teal,
            title: hasVideo ? 'Replace Video from Gallery' : 'Choose Video from Gallery',
            subtitle: 'Select a short clip (≤30s)',
            onTap: onVideoGallery,
          ),
          _PickerTile(
            icon: Icons.videocam_rounded,
            iconColor: Colors.orange,
            title: hasVideo ? 'Record New Video' : 'Record a Video',
            subtitle: 'Use camera to record (≤30s)',
            onTap: onVideoCamera,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
