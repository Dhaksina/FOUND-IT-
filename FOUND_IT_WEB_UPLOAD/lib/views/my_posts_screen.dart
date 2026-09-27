import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/post_model.dart';
import '../providers/navigation_provider.dart';
import 'widgets/post_card.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  late Future<List<PostModel>> _myPostsFuture;
  String _selectedType = 'found'; // 'found' or 'lost'

  @override
  void initState() {
    super.initState();
    _refreshMyPosts();
  }

  void _refreshMyPosts() {
    setState(() {
      _myPostsFuture = FirebaseService.instance.getMyPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Refresh posts when navigating to this tab (index 4)
    ref.listen<NavigationState>(navigationProvider, (previous, next) {
      if (next.currentIndex == 4) {
        _refreshMyPosts();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Posts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Segmented Controller for Found vs Lost Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment<String>(
                    value: 'found',
                    label: Text('Found Items'),
                    icon: Icon(Icons.search_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'lost',
                    label: Text('Lost Items'),
                    icon: Icon(Icons.campaign_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshMyPosts();
                await _myPostsFuture;
              },
              child: FutureBuilder<List<PostModel>>(
                future: _myPostsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading posts: ${snapshot.error}'),
                    );
                  }

                  final allPosts = snapshot.data ?? [];
                  final posts = allPosts.where((p) => p.type == _selectedType).toList();

                  if (posts.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _selectedType == 'found' ? Icons.search_rounded : Icons.campaign_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedType == 'found' ? 'No Found Items' : 'No Lost Items',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedType == 'found'
                                  ? 'You haven\'t posted any found items yet.'
                                  : 'You haven\'t posted any lost items yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // Switch to Post tab (index 2)
                                ref.read(navigationProvider.notifier).setIndex(2);
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create a Post'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: PostCard(post: post),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
