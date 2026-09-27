import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'post_screen.dart';
import 'search_screen.dart';
import 'my_posts_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // Track which screens have been visited and loaded to prevent startup CPU spikes
  final List<bool> _loadedScreens = [true, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final currentIndex = navState.currentIndex;

    // Ensure the current index is marked as loaded
    if (!_loadedScreens[currentIndex]) {
      _loadedScreens[currentIndex] = true;
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: List.generate(5, (index) {
          if (!_loadedScreens[index]) {
            return const SizedBox.shrink();
          }
          switch (index) {
            case 0:
              return const HomeScreen();
            case 1:
              return const ChatListScreen();
            case 2:
              return const PostScreen();
            case 3:
              return const SearchScreen();
            case 4:
              return const MyPostsScreen();
            default:
              return const SizedBox.shrink();
          }
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined),
            selectedIcon: Icon(Icons.assignment_ind),
            label: 'My Posts',
          ),
        ],
      ),
    );
  }
}
