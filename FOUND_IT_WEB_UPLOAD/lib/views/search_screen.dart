import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/posts_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/location_picker_map.dart';


// ─── item categories ─────────────────────────────────────────────────────────
const List<String> _categories = [
  'All', 'Phone', 'Earbuds', 'Wallet', 'Passport',
  'Keys', 'Laptop', 'Bag', 'Documents', 'Pets', 'Jewellery', 'Other',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();

  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameCtrl.text     = ref.read(searchQueryProvider);
      _locationCtrl.text = ref.read(searchLocationProvider).name;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    _nameCtrl.clear();
    _locationCtrl.clear();
    ref.read(searchQueryProvider.notifier).updateQuery('');
    ref.read(searchCategoryProvider.notifier).updateCategory('All');
    ref.read(searchLocationProvider.notifier).updateLocation('');
    ref.read(searchDateProvider.notifier).updateDate('Anytime');
  }

  bool _hasActiveFilters(String query, String category, String location, String dateFilter) =>
      query.isNotEmpty || category != 'All' || location.isNotEmpty || dateFilter != 'Anytime';

  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final query         = ref.watch(searchQueryProvider);
    final selectedCat   = ref.watch(searchCategoryProvider);
    final selectedLoc   = ref.watch(searchLocationProvider);
    final selectedDate  = ref.watch(searchDateProvider);
    final searchResults = ref.watch(searchedPostsProvider);
    final hasFilters    = _hasActiveFilters(query, selectedCat, selectedLoc.name, selectedDate);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ).createShader(bounds),
          child: const Text(
            'Smart Search',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
          ),
        ),
        actions: [
          if (hasFilters)
            TextButton.icon(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _clearAll,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.title_rounded, size: 20),           text: 'Name'),
            Tab(icon: Icon(Icons.category_rounded, size: 20),        text: 'Category'),
            Tab(icon: Icon(Icons.location_on_rounded, size: 20),     text: 'Location'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 20),  text: 'Date'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active filter chips
          if (hasFilters)
            _ActiveFilterBar(
              query: query,
              category: selectedCat,
              location: selectedLoc.name,
              dateFilter: selectedDate,
              onRemoveQuery:    () { _nameCtrl.clear(); ref.read(searchQueryProvider.notifier).updateQuery(''); },
              onRemoveCategory: () => ref.read(searchCategoryProvider.notifier).updateCategory('All'),
              onRemoveLocation: () { _locationCtrl.clear(); ref.read(searchLocationProvider.notifier).updateLocation(''); },
              onRemoveDate:     () => ref.read(searchDateProvider.notifier).updateDate('Anytime'),
            ),

          // Tab panels
          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Name
                _NameTab(
                  controller: _nameCtrl,
                  recentSearches: _recentSearches,
                  currentQuery: query,
                  onQueryChanged: (v) => ref.read(searchQueryProvider.notifier).updateQuery(v),
                  onRecentTap: (v) { _nameCtrl.text = v; ref.read(searchQueryProvider.notifier).updateQuery(v); },
                  onSubmit: (v) {
                    if (v.isNotEmpty && !_recentSearches.contains(v)) {
                      setState(() {
                        _recentSearches.insert(0, v);
                        if (_recentSearches.length > 6) _recentSearches.removeLast();
                      });
                    }
                  },
                ),
                // Category
                _CategoryTab(
                  selectedCategory: selectedCat,
                  onSelect: (c) => ref.read(searchCategoryProvider.notifier).updateCategory(c),
                ),
                // Location
                _LocationTab(
                  controller: _locationCtrl,
                ),
                // Date
                _DateTab(
                  selectedDate: selectedDate,
                  onSelect: (d) => ref.read(searchDateProvider.notifier).updateDate(d),
                ),
              ],
            ),
          ),

          // Result count banner
          if (hasFilters)
            searchResults.maybeWhen(
              data: (posts) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                child: Text(
                  '${posts.length} result${posts.length == 1 ? '' : 's'} found',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),

          // Results list
          Expanded(
            child: searchResults.when(
              data: (posts) {
                if (!hasFilters) return _EmptyHint();
                if (posts.isEmpty) return _NoResults();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PostCard(post: posts[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Search error',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center),
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

// ─── Active filter bar ────────────────────────────────────────────────────────
class _ActiveFilterBar extends StatelessWidget {
  final String query, category, location, dateFilter;
  final VoidCallback onRemoveQuery, onRemoveCategory, onRemoveLocation, onRemoveDate;

  const _ActiveFilterBar({
    required this.query, required this.category,
    required this.location, required this.dateFilter,
    required this.onRemoveQuery, required this.onRemoveCategory,
    required this.onRemoveLocation, required this.onRemoveDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: theme.colorScheme.primaryContainer.withOpacity(0.15),
      child: Wrap(
        spacing: 8, runSpacing: 4,
        children: [
          if (query.isNotEmpty)            _Badge(Icons.title_rounded,          query,      const Color(0xFF4F46E5), onRemoveQuery),
          if (category != 'All')           _Badge(Icons.category_rounded,       category,   const Color(0xFF7C3AED), onRemoveCategory),
          if (location.isNotEmpty)         _Badge(Icons.location_on_rounded,    location,   const Color(0xFF06B6D4), onRemoveLocation),
          if (dateFilter != 'Anytime')     _Badge(Icons.calendar_month_rounded, dateFilter, const Color(0xFFCBD5E1), onRemoveDate),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onRemove;
  const _Badge(this.icon, this.label, this.color, this.onRemove);

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 14, color: color),
    label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    deleteIcon: Icon(Icons.close_rounded, size: 14, color: color),
    onDeleted: onRemove,
    backgroundColor: color.withOpacity(0.10),
    side: BorderSide(color: color.withOpacity(0.25)),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// ─── Name tab ─────────────────────────────────────────────────────────────────
class _NameTab extends StatelessWidget {
  final TextEditingController controller;
  final List<String> recentSearches;
  final String currentQuery;
  final ValueChanged<String> onQueryChanged, onRecentTap, onSubmit;

  const _NameTab({
    required this.controller, required this.recentSearches,
    required this.currentQuery, required this.onQueryChanged,
    required this.onRecentTap,  required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            controller: controller,
            hintText: 'e.g. Black Wallet, iPhone 14…',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (currentQuery.isNotEmpty)
                IconButton(icon: const Icon(Icons.clear), onPressed: () { controller.clear(); onQueryChanged(''); }),
            ],
            onChanged: onQueryChanged,
            onSubmitted: onSubmit,
            elevation: WidgetStateProperty.all(1.0),
          ),
          if (recentSearches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.history_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Recent', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: recentSearches.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                padding: EdgeInsets.zero,
                onPressed: () => onRecentTap(s),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Category tab ─────────────────────────────────────────────────────────────
class _CategoryTab extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelect;
  const _CategoryTab({required this.selectedCategory, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isSelected = selectedCategory == cat;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}




// ─── Location tab ─────────────────────────────────────────────────────────────
class _LocationTab extends ConsumerWidget {
  final TextEditingController controller;
  const _LocationTab({required this.controller});

  static const List<String> _suggestions = [
    'Airport', 'Mall', 'Train Station', 'Bus Stop', 'Park',
    'Market', 'Hospital', 'Library', 'School', 'Restaurant',
  ];

  Future<void> _selectOnMap(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerMap(),
      ),
    );
    if (result != null && result is LocationResult) {
      controller.text = result.address;
      ref.read(searchLocationProvider.notifier).updateLocation(
        result.address,
        latitude: result.latLng.latitude,
        longitude: result.latLng.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: controller,
                  hintText: 'Area, landmark or city…',
                  leading: const Icon(Icons.location_on_rounded),
                  trailing: [
                    if (controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          ref.read(searchLocationProvider.notifier).updateLocation('');
                        },
                      ),
                  ],
                  onChanged: (val) {
                    ref.read(searchLocationProvider.notifier).updateLocation(val);
                  },
                  elevation: WidgetStateProperty.all(1.0),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.map_rounded),
                tooltip: 'Select on Map',
                onPressed: () => _selectOnMap(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Quick locations:', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: _suggestions.map((s) => ActionChip(
              avatar: const Icon(Icons.place_outlined, size: 14),
              label: Text(s, style: const TextStyle(fontSize: 12)),
              padding: EdgeInsets.zero,
              onPressed: () {
                controller.text = s;
                ref.read(searchLocationProvider.notifier).updateLocation(s);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state helpers ──────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 72,
              color: theme.colorScheme.outline.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text('Search by Name, Category, Colour or Location',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Use the tabs above. Combine filters for precise results.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_in_page_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No items match your filters',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Try fewer filters or broaden your search terms.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

// ─── Date tab ─────────────────────────────────────────────────────────────────
class _DateTab extends StatelessWidget {
  final String selectedDate;
  final ValueChanged<String> onSelect;
  const _DateTab({required this.selectedDate, required this.onSelect});

  static const List<String> _dateOptions = [
    'Anytime', 'Lost today', 'Last 3 days', 'Last week', 'Last month',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _dateOptions.length,
      itemBuilder: (context, index) {
        final opt = _dateOptions[index];
        final isSelected = selectedDate == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FilterChip(
            label: Text(opt),
            selected: isSelected,
            onSelected: (_) => onSelect(opt),
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
