import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/posts_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';
import '../models/post_model.dart';
import 'details_screen.dart'; // To reuse IdVerificationSheet
import 'widgets/custom_image.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _nearbyAlerts = true;
  bool _matchAlerts = true;
  bool _priorityAlerts = true;

  Widget _buildSafetyTip(BuildContext context, {required String title, required String desc}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final verification = ref.watch(idVerificationProvider);
    final authState = ref.watch(authProvider);

    Widget buildProfileHeader() {
      if (authState.isLoggedIn) {
        return Card(
          elevation: 4,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.secondaryContainer.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    (authState.displayName != null && authState.displayName!.isNotEmpty)
                        ? authState.displayName![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.displayName ?? 'User',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (authState.email != null)
                        Row(
                          children: [
                            Icon(Icons.mail_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                authState.email!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (authState.phoneNumber != null)
                        Row(
                          children: [
                            Icon(Icons.phone_android_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                authState.phoneNumber!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  tooltip: 'Log Out',
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully.'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        return Card(
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.2),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 32,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Full Features',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in or register to contact owners directly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => const _AuthSheet(),
                    );
                  },
                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildProfileHeader(),
            const SizedBox(height: 24),



            // 2. ID Verification Section
            Text(
              'Identity Verification',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: verification.isVerified 
                  ? Colors.green.shade50.withOpacity(0.3) 
                  : theme.colorScheme.errorContainer.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: verification.isVerified ? Colors.green.shade300 : theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          verification.isVerified ? Icons.verified_rounded : Icons.shield_outlined,
                          color: verification.isVerified ? Colors.green.shade600 : theme.colorScheme.error,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            verification.isVerified ? 'Government ID Verified' : 'ID Verification Pending',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: verification.isVerified ? Colors.green.shade800 : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verification.isVerified
                          ? 'Your identity has been verified via your uploaded ${verification.idType}. You have full access to call or message item owners.'
                          : 'To contact finders or owners, you must verify your identity to prevent scams and harassment. Uploading any government document unlocks all contacts.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (verification.isVerified)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Reset Verification / Remove ID'),
                        onPressed: () {
                          ref.read(idVerificationProvider.notifier).clearVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification cleared successfully.')),
                          );
                        },
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Verify ID Now', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ),
            ),
            const SizedBox(height: 24),



            // ── Language & Region Section ──────────────────────────────────
            Text(
              tr(ref.watch(languageCodeProvider), 'language'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _LanguageSelectorCard(),
            const SizedBox(height: 24),

            // 4. Notifications & Alerts Section
            Text(
              'Notifications & Alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                    title: const Text('Nearby Item Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Notify when items are found near my current location'),
                    value: _nearbyAlerts,
                    onChanged: (bool value) {
                      setState(() {
                        _nearbyAlerts = value;
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: Icon(Icons.compare_arrows_rounded, color: theme.colorScheme.primary),
                    title: const Text('Instant Match Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Notify if a found item matches my lost report description'),
                    value: _matchAlerts,
                    onChanged: (bool value) {
                      setState(() {
                        _matchAlerts = value;
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: Icon(Icons.emergency_share_rounded, color: theme.colorScheme.error),
                    title: const Text('Priority Emergency Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('High-priority notification for highly critical lost items nearby (e.g. Passports, Pets)'),
                    value: _priorityAlerts,
                    onChanged: (bool value) {
                      setState(() {
                        _priorityAlerts = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.notification_important_rounded),
              label: const Text('Simulate Priority Alert Notification', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _simulatePriorityAlertNotification(context);
              },
            ),
            const SizedBox(height: 24),

            // 5. Safety & Trust Guidelines
            Text(
              'Safety & Security Center',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ExpansionTile(
                leading: Icon(Icons.gavel_rounded, color: theme.colorScheme.primary),
                title: const Text('Anti-Scam Safety Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Guidelines to follow when claiming lost items'),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                collapsedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSafetyTip(
                          context,
                          title: 'Meet in Public Locations',
                          desc: 'Always arrange handover in highly populated public areas, such as police stations or shopping malls.',
                        ),
                        const SizedBox(height: 12),
                        _buildSafetyTip(
                          context,
                          title: 'Verify Ownership',
                          desc: 'Ask for specific identification marks or serial numbers before releasing a found item.',
                        ),
                        const SizedBox(height: 12),
                        _buildSafetyTip(
                          context,
                          title: 'No Advanced Payments',
                          desc: 'Never pay any finder fee or shipping charges in advance to prevent online advance-fee scams.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _simulatePriorityAlertNotification(BuildContext context) {
    // Find the latest posts if possible, or use a mock post
    PostModel? samplePost;
    try {
      final posts = ref.read(postsNotifierProvider).value;
      if (posts != null && posts.isNotEmpty) {
        // Try to find a lost post or just take the first one
        samplePost = posts.firstWhere(
          (p) => p.type == 'lost',
          orElse: () => posts.first,
        );
      }
    } catch (_) {}

    // Fallback Mock Post if none exist
    samplePost ??= PostModel(
      id: 'mock-priority-alert',
      title: 'Cooper (Golden Retriever)',
      description: 'Lost Golden Retriever near Central Park. Wearing a red collar. Friendly but scared.',
      type: 'lost',
      category: 'Pets',
      locationName: 'Central Park, NY',
      latitude: 40.785091,
      longitude: -73.968285,
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&q=80&w=300',
      status: 'active',
      createdAt: DateTime.now(),
      contactName: 'Alex Smith',
      whatsappNumber: '+15550199',
      valueRange: 'Priceless / Emotional Value',
    );

    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _NotificationBannerWidget(
          post: samplePost!,
          onClose: () {
            overlayEntry.remove();
          },
          onView: () {
            overlayEntry.remove();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(post: samplePost!),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Language Selector Card
// ══════════════════════════════════════════════════════════════════════════════

class _LanguageSelectorCard extends ConsumerWidget {
  const _LanguageSelectorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme        = Theme.of(context);
    final currentCode  = ref.watch(languageCodeProvider);
    final currentLang  = supportedLanguages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => supportedLanguages.first,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.translate_rounded),
        ),
        title: Text(
          tr(currentCode, 'select_language'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(currentLang.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '${currentLang.name}  ·  ${currentLang.englishName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _LanguagePickerSheet(currentCode: currentCode),
          );
        },
      ),
    );
  }
}

// ── Language Picker Bottom Sheet ──────────────────────────────────────────────
class _LanguagePickerSheet extends ConsumerWidget {
  final String currentCode;
  const _LanguagePickerSheet({required this.currentCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(currentCode, 'select_language'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${supportedLanguages.length} languages available',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Language list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: supportedLanguages.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final lang       = supportedLanguages[index];
              final isSelected = lang.code == currentCode;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                title: Text(
                  lang.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                subtitle: Text(
                  lang.englishName,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      )
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(lang.code);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            'Language changed to ${lang.englishName}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _NotificationBannerWidget extends StatefulWidget {

  final PostModel post;
  final VoidCallback onClose;
  final VoidCallback onView;

  const _NotificationBannerWidget({
    Key? key,
    required this.post,
    required this.onClose,
    required this.onView,
  }) : super(key: key);

  @override
  __NotificationBannerWidgetState createState() => __NotificationBannerWidgetState();
}

class __NotificationBannerWidgetState extends State<_NotificationBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 6), () {
      _slideOut();
    });
  }

  void _slideOut() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onClose();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withOpacity(0.03),
                  BlendMode.srcOver,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TecFind',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'now',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 PRIORITY ALERT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.error,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.post.title} ${widget.post.type == 'lost' ? 'missing' : 'found'} nearby!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.post.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomImage(
                              imageUrl: widget.post.imageUrl,
                              category: widget.post.category,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _slideOut,
                            child: Text(
                              'Dismiss',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: widget.onView,
                            child: const Text(
                              'View Post',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet({Key? key}) : super(key: key);

  @override
  _AuthSheetState createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  String _authMethod = 'email'; // 'email' or 'phone'
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); 
  final _otpController = TextEditingController(); 

  // Fake listing report form controllers
  final _fakeListingTitleController = TextEditingController();
  final _fakeListingDescController = TextEditingController();
  final _fakeListingEmailController = TextEditingController();
  String _selectedFakeReason = 'Fake / Suspicious Post';
  bool _isSubmittingFakeReport = false;
  bool _fakeReportSuccess = false;

  bool _obscurePassword = true;
  bool _isLoading = false;

  // OTP Verification state
  bool _otpSent = false;
  int _otpCountdown = 0;
  Timer? _otpTimer;
  bool _isSendingOtp = false;
  bool _isReportingFake = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _fakeListingTitleController.dispose();
    _fakeListingDescController.dispose();
    _fakeListingEmailController.dispose();
    super.dispose();
  }

  void _startOtpCountdown() {
    setState(() {
      _otpCountdown = 30;
    });
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() {
          _otpCountdown--;
        });
      } else {
        _otpTimer?.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number first')),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    String formattedPhone = _phoneController.text.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$formattedPhone';
    }

    final auth = ref.read(authProvider.notifier).firebaseAuthInstance;
    if (auth != null) {
      try {
        await auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await ref.read(authProvider.notifier).signInWithPhoneCredential(credential, 'User');
            if (mounted) {
              setState(() {
                _isSendingOtp = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed in successfully via auto-verification!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                _isSendingOtp = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification failed: ${e.message}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _isSendingOtp = false;
                _otpSent = true;
              });
              _startOtpCountdown();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('OTP sent successfully to $formattedPhone! Enter code below.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (mounted) {
              _verificationId = verificationId;
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to request OTP: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // Simulate OTP dispatch (mock fallback)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
      });

      _startOtpCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP code 123456 sent successfully to $formattedPhone! (Mock Mode)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isSignUp = _tabController.index == 1;

    // For Phone Authentication (Sign In & Sign Up), verify OTP first
    if (_authMethod == 'phone') {
      if (!_otpSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please click "Send OTP" first.'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
      final auth = ref.read(authProvider.notifier).firebaseAuthInstance;
      if (auth == null && _otpController.text.trim() != '123456') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP code. Please enter 123456 to verify.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final name = isSignUp 
        ? _nameController.text.trim() 
        : (_authMethod == 'email' ? _emailController.text.split('@')[0] : 'User');
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final currentPrefs = ref.read(profilePreferencesProvider);

    try {
      if (_authMethod == 'email') {
        if (isSignUp) {
          await ref.read(authProvider.notifier).registerWithEmail(email, password, name);
        } else {
          await ref.read(authProvider.notifier).loginWithEmail(email, password);
        }
        // Autofill default profile preferences
        ref.read(profilePreferencesProvider.notifier).savePreferences(name, currentPrefs.defaultPhone);
      } else {
        final auth = ref.read(authProvider.notifier).firebaseAuthInstance;
        if (auth != null && _verificationId != null) {
          final credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _otpController.text.trim(),
          );
          await ref.read(authProvider.notifier).signInWithPhoneCredential(credential, name);
        } else {
          // Mock/Simulated verification countdown first
          await Future.delayed(const Duration(milliseconds: 1500));
          await ref.read(authProvider.notifier).loginWithPhone(phone, name);
        }
        // Autofill default profile preferences
        ref.read(profilePreferencesProvider.notifier).savePreferences(name, phone);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Strip out the bracketed Firebase code if present (e.g. [firebase_auth/email-already-in-use] ...)
        String errorMessage = e.toString();
        if (errorMessage.contains('] ')) {
          errorMessage = errorMessage.split('] ').last;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $errorMessage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSignUp ? 'Registration successful!' : 'Signed in successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFakeListingForm(ThemeData theme) {
    final reportFormKey = GlobalKey<FormState>();

    if (_fakeReportSuccess) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 64),
          const SizedBox(height: 16),
          Text(
            'Report Submitted Successfully',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for reporting. Our security team will review the listing and take down fraudulent posts within 12 hours.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _fakeReportSuccess = false;
                _isReportingFake = false;
                _fakeListingTitleController.clear();
                _fakeListingDescController.clear();
                _fakeListingEmailController.clear();
              });
            },
            child: const Text('Back to Login'),
          ),
        ],
      );
    }

    return Form(
      key: reportFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isReportingFake = false;
                  });
                },
              ),
              Text(
                'Report Suspicious Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Keep TecFind safe. Report listing fraud, reward scams, fake item postings, or contact issues.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.3),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fakeListingTitleController,
            decoration: const InputDecoration(
              labelText: 'Suspicious Listing Title / Item Name',
              prefixIcon: Icon(Icons.title_rounded),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the title or item name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedFakeReason,
            decoration: const InputDecoration(
              labelText: 'Reason for Report',
              prefixIcon: Icon(Icons.warning_amber_rounded),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Fake / Suspicious Post', child: Text('Fake / Suspicious Post')),
              DropdownMenuItem(value: 'Scammer (Demanded money/delivery fee)', child: Text('Scammer (Demands cash upfront)')),
              DropdownMenuItem(value: 'Inappropriate Content/Photos', child: Text('Inappropriate Content/Photos')),
              DropdownMenuItem(value: 'Reward Scam / Blackmail', child: Text('Reward Scam / Blackmail')),
              DropdownMenuItem(value: 'Other Fraud', child: Text('Other Fraud')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedFakeReason = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fakeListingDescController,
            decoration: const InputDecoration(
              labelText: 'Additional Details (Optional)',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Icon(Icons.description_outlined),
              ),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fakeListingEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Your Contact Email (Optional)',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            onPressed: _isSubmittingFakeReport
                ? null
                : () async {
                    if (reportFormKey.currentState!.validate()) {
                      setState(() {
                        _isSubmittingFakeReport = true;
                      });
                      await Future.delayed(const Duration(seconds: 2));
                      setState(() {
                        _isSubmittingFakeReport = false;
                        _fakeReportSuccess = true;
                      });
                    }
                  },
            child: _isSubmittingFakeReport
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignUp = _tabController.index == 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isReportingFake) ...[
                _buildFakeListingForm(theme),
              ] else if (_isLoading) ...[
                const SizedBox(height: 40),
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Authenticating securely...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ] else ...[
                Text(
                  isSignUp ? 'Create Account' : 'Welcome Back',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isSignUp 
                      ? 'Register to publish and claim found items' 
                      : 'Sign in to access contacts and manage your reports',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary,
                    ),
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.mail_outline_rounded,
                          size: 18,
                          color: _authMethod == 'email' 
                              ? theme.colorScheme.onPrimary 
                              : theme.colorScheme.primary,
                        ),
                        label: const Text('Gmail / Email'),
                        selected: _authMethod == 'email',
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: _authMethod == 'email' 
                              ? theme.colorScheme.onPrimary 
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _authMethod = 'email';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.phone_iphone_rounded,
                          size: 18,
                          color: _authMethod == 'phone' 
                              ? theme.colorScheme.onPrimary 
                              : theme.colorScheme.primary,
                        ),
                        label: const Text('Phone Number'),
                        selected: _authMethod == 'phone',
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: _authMethod == 'phone' 
                              ? theme.colorScheme.onPrimary 
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _authMethod = 'phone';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_authMethod == 'email') ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Gmail / Email Address',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                            hintText: 'user@gmail.com',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                  setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_iphone_rounded),
                            hintText: 'e.g. +919988776655',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            final digits = value.replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (!_otpSent) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            icon: _isSendingOtp
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_to_mobile_rounded, size: 18),
                            label: Text(_isSendingOtp ? 'Sending OTP...' : 'Send Verification OTP'),
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '6-Digit Verification OTP',
                              prefixIcon: Icon(Icons.pin_rounded),
                              hintText: 'Enter 123456',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the OTP code';
                              }
                              if (value.trim().length != 6) {
                                  return 'OTP must be exactly 6 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _otpCountdown > 0
                                    ? 'Resend OTP in ${_otpCountdown}s'
                                    : 'Didn\'t receive code?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_otpCountdown == 0)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _sendOtp,
                                  child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _submit,
                        child: Text(
                          isSignUp ? 'Register & Sign In' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: Icon(Icons.report_gmailerrorred_rounded, color: theme.colorScheme.error),
                        label: Text(
                          'Report a Suspicious / Fake Listing Anonymously',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isReportingFake = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
