import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';

class FocusedPostNotifier extends Notifier<PostModel?> {
  @override
  PostModel? build() => null;

  void setPost(PostModel? post) {
    state = post;
  }
}

/// Provider to hold a post that the user wants to center and select on the Map tab.
final focusedPostProvider = NotifierProvider<FocusedPostNotifier, PostModel?>(() {
  return FocusedPostNotifier();
});
