import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final int currentIndex;
  final String? pendingPostType; // 'found' or 'lost'

  const NavigationState({
    this.currentIndex = 0,
    this.pendingPostType,
  });

  NavigationState copyWith({
    int? currentIndex,
    String? pendingPostType,
    bool clearPendingPostType = false,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      pendingPostType: clearPendingPostType ? null : (pendingPostType ?? this.pendingPostType),
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() => const NavigationState();

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void navigateToPost({required String type}) {
    state = NavigationState(
      currentIndex: 2, // Post tab index
      pendingPostType: type,
    );
  }

  void clearPendingPostType() {
    state = state.copyWith(clearPendingPostType: true);
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(() => NavigationNotifier());
