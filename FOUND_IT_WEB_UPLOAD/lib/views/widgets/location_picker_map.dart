import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final LatLng latLng;
  final String address;

  LocationResult({required this.latLng, required this.address});
}

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialSearchQuery;

  const LocationPickerMap({Key? key, this.initialLocation, this.initialSearchQuery}) : super(key: key);

  @override
  _LocationPickerMapState createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  LatLng _selectedLocation = const LatLng(20.5937, 78.9629); // Default India (All over India)
  GoogleMapController? _mapController;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<dynamic> _suggestions = [];
  String? _selectedAddress;

  LatLng? _pendingMapMoveTarget;

  static final List<String> _recentSearches = [];

  void _moveMap(LatLng loc, double zoom) {
    _pendingMapMoveTarget = loc;
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: zoom),
        ),
      );
      _pendingMapMoveTarget = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });

    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.trim().isNotEmpty) {
      _selectedLocation = const LatLng(20.5937, 78.9629);
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.text = widget.initialSearchQuery!;
        _searchAddress(widget.initialSearchQuery!);
      });
    } else if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _isLoading = false;
      _reverseGeocode(_selectedLocation.latitude, _selectedLocation.longitude).then((addr) {
        if (mounted && addr.isNotEmpty) {
          setState(() {
            _selectedAddress = addr;
            _searchController.text = addr;
          });
        }
      });
    } else {
      _selectedLocation = const LatLng(20.5937, 78.9629);
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged(String query) {
    _checkSpelling(query);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 3) {
        _fetchSuggestions(query);
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final client = HttpClient();
      final lat = _selectedLocation.latitude;
      final lon = _selectedLocation.longitude;
      final left = lon - 0.5;
      final right = lon + 0.5;
      final top = lat + 0.5;
      final bottom = lat - 0.5;
      final viewboxStr = '$left,$top,$right,$bottom';

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&format=json'
        '&limit=10'
        '&countrycodes=in'
        '&viewbox=$viewboxStr'
        '&bounded=0',
      );

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.set('user-agent', 'Foundit-App-GoogleMindAgent');
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(jsonString);
        if (mounted) {
          setState(() {
            _suggestions = data;
          });
        }
      }
    } catch (e) {
      print('Fetch suggestions error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addToRecent(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _suggestions = [];
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(query)}&format=json&limit=5');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.set('user-agent', 'Foundit-App-GoogleMindAgent');
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(jsonString);
        if (data.isNotEmpty) {
          final firstResult = data.first;
          final lat = double.parse(firstResult['lat']);
          final lon = double.parse(firstResult['lon']);
          final loc = LatLng(lat, lon);
          final displayName = firstResult['display_name'] as String;
          setState(() {
            _selectedLocation = loc;
            _selectedAddress = displayName;
            _searchController.text = displayName;
          });
          _moveMap(loc, 15);
          _addToRecent(displayName);
        }
      }
    } catch (e) {
      print('Geocoding search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      request.headers.set('user-agent', 'Foundit-App-GoogleMindAgent');
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(jsonString);
        return data['display_name'] as String? ?? '';
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return '';
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final loc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = loc;
      });

      _moveMap(loc, 15);

      _reverseGeocode(loc.latitude, loc.longitude).then((addr) {
        if (mounted && addr.isNotEmpty) {
          setState(() {
            _selectedAddress = addr;
            _searchController.text = addr;
          });
        }
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Widget _buildRecentSearches() {
    final list = _recentSearches;
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No recent searches.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Recent Searches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final query = list[index];
              return ListTile(
                leading: const Icon(Icons.location_on_outlined, size: 18),
                title: Text(query, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  _searchController.text = query;
                  _searchAddress(query);
                  _searchFocusNode.unfocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedSearches() {
    if (_isSearching && _suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No locations found.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.near_me_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Suggested Searches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final item = _suggestions[index];
              final displayName = item['display_name'] as String;
              return ListTile(
                leading: const Icon(Icons.location_on_outlined, size: 18),
                title: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  final lat = double.parse(item['lat']);
                  final lon = double.parse(item['lon']);
                  final loc = LatLng(lat, lon);
                  
                  setState(() {
                    _selectedLocation = loc;
                    _selectedAddress = displayName;
                    _searchController.text = displayName;
                    _suggestions = [];
                  });
                  
                  _moveMap(loc, 15);
                  _addToRecent(displayName);
                  _searchFocusNode.unfocus();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel and Go Back',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(
                context,
                LocationResult(
                  latLng: _selectedLocation,
                  address: _selectedAddress ?? 'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: (_selectedLocation.latitude == 20.5937 && _selectedLocation.longitude == 78.9629) ? 5 : 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_pendingMapMoveTarget != null) {
                      _moveMap(_pendingMapMoveTarget!, 15);
                    }
                  },
                  onTap: (latLng) async {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _selectedLocation = latLng;
                      _selectedAddress = 'Fetching address...';
                      _searchController.text = 'Fetching address...';
                    });
                    final addr = await _reverseGeocode(latLng.latitude, latLng.longitude);
                    if (mounted) {
                      setState(() {
                        _selectedAddress = addr.isNotEmpty ? addr : 'Selected Map Pin';
                        _searchController.text = _selectedAddress!;
                      });
                    }
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                ),
                
                // Search panel overlay (Suggestions and Recents)
                if (_isSearchFocused)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    bottom: 120, // Keep some space so they can see the map behind
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _searchController.text.trim().isEmpty
                            ? _buildRecentSearches()
                            : _buildSuggestedSearches(),
                      ),
                    ),
                  ),

                // Search bar overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search city, street, landmark...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchTextChanged('');
                                    },
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: _searchAddress,
                          onChanged: _onSearchTextChanged,
                        ),
                      ),
                      if (_spellingSuggestion != null && !_isSearchFocused)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                          child: InkWell(
                            onTap: () {
                              final suggestion = _spellingSuggestion!;
                              _searchController.text = suggestion;
                              setState(() {
                                _spellingSuggestion = null;
                              });
                              _searchAddress(suggestion);
                            },
                            child: Card(
                              color: theme.colorScheme.secondaryContainer,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.spellcheck_rounded,
                                      size: 16,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Did you mean: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    Text(
                                      _spellingSuggestion!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
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
                ),

                // Location info bottom card overlay (hidden when search is focused)
                if (!_isSearchFocused)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pin_drop, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Location',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      if (_selectedAddress != null && _selectedAddress!.isNotEmpty) ...[
                                        Text(
                                          _selectedAddress!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('My Location'),
                                  onPressed: _getCurrentLocation,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                      LocationResult(
                                        latLng: _selectedLocation,
                                        address: _selectedAddress ?? 'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                                      ),
                                    );
                                  },
                                  child: const Text('Confirm Location'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String? _spellingSuggestion;

  int _getLevenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  int _min3(int a, int b, int c) {
    int m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }

  static const List<String> _commonTamilNaduLocations = [
    'Pallikaranai',
    'Tambaram',
    'Medavakkam',
    'Velachery',
    'Adyar',
    'Guindy',
    'Thiruvanmiyur',
    'Sholinganallur',
    'Perungudi',
    'Nungambakkam',
    'T. Nagar',
    'Mylapore',
    'Chromepet',
    'Pallavaram',
    'Madipakkam',
    'Keelkattalai',
    'Kovilambakkam',
    'Selaiyur',
    'Perungalathur',
    'Vandalur',
    'Urapakkam',
    'Guduvanchery',
    'Chengalpattu',
    'Poonamallee',
    'Porur',
    'Valasaravakkam',
    'Saidapet',
    'Vadapalani',
    'Koyambedu',
    'Anna Nagar',
    'Ambattur',
    'Avadi',
    'Maduravoyal',
    'Red Hills',
    'Madhavaram',
    'Tiruvottiyur',
    'Chennai',
    'Madurai',
    'Coimbatore',
    'Salem',
    'Tiruchirappalli',
    'Tirunelveli',
    'Thanjavur',
    'Vellore',
    'Erode',
    'Thoothukudi',
    'Dindigul',
    'Karur',
    'Kodaikanal',
    'Kanyakumari',
    'Hosur',
    'Nagercoil',
    'Kanchipuram',
    'Tiruvannamalai',
    'Cuddalore',
    'Pudukkottai',
    'Nagapattinam',
  ];

  void _checkSpelling(String query) {
    if (query.trim().length < 3) {
      setState(() {
        _spellingSuggestion = null;
      });
      return;
    }

    final lowercaseQuery = query.trim().toLowerCase();
    String? bestMatch;
    int minDistance = 999;

    for (final loc in _commonTamilNaduLocations) {
      final lowercaseLoc = loc.toLowerCase();
      if (lowercaseQuery == lowercaseLoc) {
        setState(() {
          _spellingSuggestion = null;
        });
        return;
      }
      
      final dist = _getLevenshteinDistance(lowercaseQuery, lowercaseLoc);
      if (dist < minDistance) {
        minDistance = dist;
        bestMatch = loc;
      }
    }

    if (minDistance > 0 && minDistance <= 3 && bestMatch != null) {
      setState(() {
        _spellingSuggestion = bestMatch;
      });
    } else {
      setState(() {
        _spellingSuggestion = null;
      });
    }
  }
}