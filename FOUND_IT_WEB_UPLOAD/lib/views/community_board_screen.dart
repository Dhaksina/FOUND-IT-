import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/posts_provider.dart';
import '../providers/community_provider.dart';
import 'details_screen.dart';
import 'post_screen.dart';
import 'widgets/post_card.dart';

class CommunityBoardScreen extends ConsumerStatefulWidget {
  final Community community;

  const CommunityBoardScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends ConsumerState<CommunityBoardScreen> {
  String _selectedType = 'found'; // 'found' or 'lost'
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Electronics',
    'Documents',
    'Keys',
    'Wallets',
    'Bags',
    'Clothing',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(postsNotifierProvider);
    final isCampus = widget.community.type == CommunityType.campus;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.community.emoji} ${widget.community.shortName} Board',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Copy Invite Link',
            onPressed: () {
              final inviteLink = 'tecfind://community/join?id=${widget.community.id}';
              Clipboard.setData(ClipboardData(text: inviteLink));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: const Text('Invite link copied!'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Community Header Card ──
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            color: widget.community.accentColor.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: widget.community.accentColor.withOpacity(0.12),
                        child: Text(widget.community.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.community.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.community.location,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.community.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.community.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.community.accentColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isCampus ? Icons.school_rounded : Icons.event_rounded, size: 12, color: widget.community.accentColor),
                            const SizedBox(width: 4),
                            Text(
                              isCampus ? 'CAMPUS BOARD' : 'EVENT BOARD',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: widget.community.accentColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.community.memberCount} members',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Found / Lost Toggle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SegmentedButton<String>(
              style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              segments: const [
                ButtonSegment<String>(value: 'found', label: Text('Found'), icon: Icon(Icons.search_rounded)),
                ButtonSegment<String>(value: 'lost', label: Text('Lost'), icon: Icon(Icons.campaign_rounded)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSel) => setState(() => _selectedType = newSel.first),
            ),
          ),

          // ── Category Chips ──
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ── Posts List ──
          Expanded(
            child: postsAsync.when(
              data: (allPosts) {
                final filtered = allPosts.where((p) {
                  final matchesType = p.type == _selectedType;
                  final matchesCategory = _selectedCategory == 'All' ||
                      p.category.toLowerCase() == _selectedCategory.toLowerCase();
                  final matchesBoard =
                      p.locationName.toLowerCase().contains(widget.community.shortName.toLowerCase()) ||
                      p.locationName.toLowerCase().contains(widget.community.name.toLowerCase()) ||
                      p.locationName.toLowerCase().contains(widget.community.id.toLowerCase());
                  return matchesType && matchesCategory && matchesBoard;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No items reported yet',
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline)),
                        const SizedBox(height: 4),
                        Text('Be the first to report a lost or found item here!',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final post = filtered[idx];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailsScreen(post: post)),
                      ),
                      child: PostCard(post: post),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.community.accentColor,
        onPressed: () => _showPostTypeSelector(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPostTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What would you like to post?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _navigateToPostScreen('found');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Found Something',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _navigateToPostScreen('lost');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.help_outline_rounded, color: Colors.orange.shade700, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Lost Something',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPostScreen(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostScreen(
          initialType: type,
          initialLocationName: widget.community.name,
        ),
      ),
    ).then((_) {
      // Refresh posts when returning from PostScreen
      ref.read(postsNotifierProvider.notifier).fetchPosts();
    });
  }
}
