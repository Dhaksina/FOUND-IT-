import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../providers/posts_provider.dart';
import '../providers/community_provider.dart';
import '../providers/navigation_provider.dart';
import 'details_screen.dart';
import 'community_board_screen.dart';
import 'settings_screen.dart';
import 'widgets/post_card.dart';
import 'widgets/custom_image.dart';
import 'widgets/community_join_sheet.dart';
import 'widgets/create_community_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isGridView = false;
  String _selectedType = 'found'; // 'found' or 'lost'
  String _selectedCategory = 'All'; // 'All' or specific categories

  final List<String> _categories = [
    'All',
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

  @override
  void initState() {
    super.initState();
  }

  // ── Community helpers ──────────────────────────────────────────────────────
  Community? _pendingBoardCommunity;

  Future<void> _joinCommunity(Community community) async {
    final joined = await CommunityJoinSheet.show(context, community);
    if (joined && mounted) {
      _showMatchNotification(community);
      // Defer the push to the very next frame after all pops have settled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CommunityBoardScreen(community: community),
          ),
        );
      });
    }
  }

  void _showMatchNotification(Community community) {
    // Simulate a "possible match" check after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final itemExamples = {
        'campus': 'College ID Card',
        'event':  'Event Wristband',
      };
      final itemName = itemExamples[
        community.type == CommunityType.campus ? 'campus' : 'event'
      ] ?? 'item';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: community.accentColor,
          content: Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Possible Match Found!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Possible match found for your $itemName in ${community.shortName} board.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showCommunitySelectionSheet(BuildContext context, List<PostModel> allPosts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  _CommunityStrip(
                    allPosts: allPosts,
                    onJoin: (community) async {
                      Navigator.pop(context); // close sheet
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _joinCommunity(community);
                    },
                    onEnterBoard: (community) async {
                      Navigator.pop(context); // close sheet
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                          builder: (_) => CommunityBoardScreen(community: community),
                        ));
                      }
                    },
                    onLeave: () {
                      ref.read(communityProvider.notifier).leave();
                      Navigator.pop(context);
                    },
                    onHide: null,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('About TecFind'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TecFind is a localized community platform designed to connect people who have lost items with those who have found them.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our mission is to bring transparency, speed, and safety to item recovery through identity verification, geographical mapping, and automated law enforcement routing.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Need help? Contact our Support Team:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@tecfind.com',
                    query: 'subject=TecFind App Support Request',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open email client. Please email support@tecfind.com')),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'support@tecfind.com',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We take your privacy seriously. Here is a summary of how we handle your data:',
                style: TextStyle(fontWeight: FontWeight.bold, height: 1.4),
              ),
              SizedBox(height: 12),
              Text('• Contact Information: Your phone number or email is strictly hidden from unverified users to prevent scams or harassment.', style: TextStyle(height: 1.4)),
              SizedBox(height: 8),
              Text('• Location Data: Coordinates are used solely to place items on the map. We do not track your real-time background location.', style: TextStyle(height: 1.4)),
              SizedBox(height: 8),
              Text('• ID Verification: Government IDs uploaded for contact unlock are processed locally for status approval and are never stored or shared with third parties.', style: TextStyle(height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showHowToUseDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('How to use TecFind'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepItem(
                context,
                icon: Icons.search_rounded,
                title: '1. Search or Browse',
                description: 'Browse the feed or inspect the map to find matching lost/found items near you.',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context,
                icon: Icons.add_circle_outline_rounded,
                title: '2. Report an Item',
                description: 'Go to the "Post" tab, upload an image, select a category, pick the location and add contact info.',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context,
                icon: Icons.verified_user_outlined,
                title: '3. Identity Verification',
                description: 'To protect finder safety, verify your Government ID under Settings to view full finder contact details.',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context,
                icon: Icons.contact_phone_outlined,
                title: '4. Contact Finders',
                description: 'Once verified, use direct calling or one-click WhatsApp to coordinate safe recovery.',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                context,
                icon: Icons.gavel_rounded,
                title: '5. High-Value Items',
                description: 'For items valued above Rs. 10,000, view suggested nearest police stations to arrange a secure handover.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, {required IconData icon, required String title, required String description}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(height: 1.3, color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWriteToUsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.read(authProvider);

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: authState.email ?? '');
    final nameController = TextEditingController(text: authState.displayName ?? '');
    final messageController = TextEditingController();

    bool isSending = false;
    bool isSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isSuccess) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Message Sent!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for writing to us. Our support team will respond to you within 24 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Write to us'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Have a question or feedback? Drop us a line below and we\'ll get right back to you.',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    if (!authState.isLoggedIn) ...[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.message_outlined),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Or contact us directly at support@tecfind.com',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isSending = true;
                          });
                          // Simulate API call
                          await Future.delayed(const Duration(seconds: 2));
                          setState(() {
                            isSending = false;
                            isSuccess = true;
                          });
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPoliceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_police_outlined, color: Colors.teal),
            SizedBox(width: 8),
            Text('Police Collaboration'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To prevent illegal trade and comply with local regulations, items reported with a value above Rs. 10,000 require police intervention.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Our app automatically queries local coordinates to find the nearest police station precinct name and address. You are advised to surrender high-value items directly to the displayed police station.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDashboard(BuildContext context, List<PostModel> allPosts) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Calculations
    final totalLost = allPosts.where((p) => p.type == 'lost').length;
    final totalFound = allPosts.where((p) => p.type == 'found').length;
    final totalReturned = allPosts.where((p) => p.status == 'returned').length;
    
    final recoveryRate = (totalLost + totalFound) > 0 
        ? ((totalReturned / (totalLost + totalFound)) * 100).toStringAsFixed(1)
        : '0.0';

    // Sort recent activity (latest first)
    final recentActivity = List<PostModel>.from(allPosts);
    recentActivity.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestActivities = recentActivity.take(5).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: size.height * 0.80,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Analytics',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Real-time lost & found statistics',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item Recovery Rate',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Percentage of reported items successfully returned to owners.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 64,
                                    width: 64,
                                    child: CircularProgressIndicator(
                                      value: (totalLost + totalFound) > 0 
                                          ? (totalReturned / (totalLost + totalFound))
                                          : 0.0,
                                      strokeWidth: 8,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '$recoveryRate%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Lost',
                              value: totalLost.toString(),
                              icon: Icons.campaign_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Found',
                              value: totalFound.toString(),
                              icon: Icons.search_rounded,
                              color: const Color(0xFF06B6D4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Returned Items',
                              value: totalReturned.toString(),
                              icon: Icons.volunteer_activism_rounded,
                              color: const Color(0xFF10B981),
                              isFullWidth: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Activity Timeline',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (latestActivities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No recent activity to show.',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: latestActivities.length,
                          itemBuilder: (context, index) {
                            final post = latestActivities[index];
                            return _buildTimelineItem(context, post);
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: isFullWidth ? 16 : 20.0),
        child: Row(
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, PostModel post) {
    final theme = Theme.of(context);

    IconData itemIcon;
    Color badgeColor;
    String actionText;

    if (post.status == 'returned') {
      itemIcon = Icons.check_circle_rounded;
      badgeColor = const Color(0xFF10B981);
      actionText = 'was successfully returned to its owner!';
    } else if (post.type == 'lost') {
      itemIcon = Icons.campaign_rounded;
      badgeColor = const Color(0xFFEF4444);
      actionText = 'reported missing in ${post.locationName}';
    } else {
      itemIcon = Icons.search_rounded;
      badgeColor = const Color(0xFF06B6D4);
      actionText = 'reported found in ${post.locationName}';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(itemIcon, size: 8, color: Colors.white),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomImage(
                          imageUrl: post.imageUrl,
                          category: post.category,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  _getRelativeTime(post.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              actionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildFeaturedSection(BuildContext context, List<PostModel> allPosts) {
    final theme = Theme.of(context);
    // Find active lost posts to feature
    final featuredPosts = allPosts
        .where((p) => p.type == 'lost' && p.status == 'active')
        .toList();

    if (featuredPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, color: theme.colorScheme.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'Urgent Lost Alerts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live Broadcast',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: featuredPosts.length,
            itemBuilder: (context, index) {
              final post = featuredPosts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsScreen(post: post),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.error.withOpacity(0.06),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Card Content Row
                        Row(
                          children: [
                            // Left image side
                            SizedBox(
                              width: 110,
                              height: double.infinity,
                              child: Stack(
                                children: [
                                  CustomImage(
                                    imageUrl: post.imageUrl,
                                    category: post.category,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  // Gradient Overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right Details Side
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'FEATURED ALERT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.error,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      post.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            post.locationName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.stars_rounded, size: 14, color: Colors.amber.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reward Eligible',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(postsNotifierProvider);
    final allPosts = postsAsync.value ?? [];
    final authState = ref.watch(authProvider);
    final activeCommunity = ref.watch(activeCommunityProvider);
    final communityState = ref.watch(communityProvider);
    final joinedCommunities = communityState.joined;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  authState.isLoggedIn && authState.displayName != null && authState.displayName!.isNotEmpty
                      ? authState.displayName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              accountName: Text(
                authState.isLoggedIn ? (authState.displayName ?? 'User') : 'Guest User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                authState.isLoggedIn
                    ? (authState.email ?? authState.phoneNumber ?? 'Logged in')
                    : 'Sign in under Settings to unlock all features',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _CommunityStrip(
                    allPosts: allPosts,
                    onJoin: (community) async {
                      Navigator.pop(context); // Close drawer
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _joinCommunity(community);
                    },
                    onEnterBoard: (community) async {
                      Navigator.pop(context); // Close drawer
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                          builder: (_) => CommunityBoardScreen(community: community),
                        ));
                      }
                    },
                    onLeave: () async {
                      ref.read(communityProvider.notifier).leave();
                      Navigator.pop(context); // Close the drawer
                    },
                    onHide: null,
                  ),
                  const Divider(height: 1),
                  if (joinedCommunities.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_added_rounded, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Joined Boards',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...joinedCommunities.map((comm) {
                      final isActive = activeCommunity?.id == comm.id;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: comm.accentColor.withOpacity(0.12),
                          child: Text(comm.emoji, style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(
                          comm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? theme.colorScheme.primary : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 16),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                ref.read(communityProvider.notifier).leaveAndRemove(comm);
                              },
                              tooltip: 'Leave Board',
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.pop(context); // Close drawer
                          await Future.delayed(const Duration(milliseconds: 300));
                          ref.read(communityProvider.notifier).selectCommunity(comm);
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                              builder: (_) => CommunityBoardScreen(community: comm),
                            ));
                          }
                        },
                      );
                    }).toList(),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('How to use', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showHowToUseDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rate_review_outlined),
                    title: const Text('Write to us', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showWriteToUsDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy & Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_police_outlined),
                    title: const Text('Police Station Finder', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showPoliceDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded),
                    title: const Text('Community Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAnalyticsDashboard(context, allPosts);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'TecFind v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 10),
              Text(
                'TecFind',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.groups_rounded),
                if (activeCommunity != null)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: activeCommunity.accentColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: activeCommunity != null ? activeCommunity.name : 'Select Community',
            onPressed: () => _showCommunitySelectionSheet(context, allPosts),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Community Board selector has been moved to App Bar actions (next to the refresh button)

          // Found vs Lost Segmented Controller (M3 Design)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment<String>(
                    value: 'found',
                    label: const Text('Found'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'lost',
                    label: const Text('Lost'),
                    icon: const Icon(Icons.campaign_rounded),
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

          // Scrollable Category Selection Chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
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
          
          Expanded(
            child: postsAsync.when(
              data: (allPosts) {
                final activeCommunity = ref.watch(activeCommunityProvider);
                final activeCommunities = ref.watch(activeCommunitiesProvider);
                // Filter posts by type, category, and active community
                final posts = allPosts.where((p) {
                  final matchesType     = p.type == _selectedType;
                  final matchesCategory = _selectedCategory == 'All' ||
                      p.category.toLowerCase() == _selectedCategory.toLowerCase();
                  
                  bool matchesCommunity = false;
                  if (activeCommunity == null) {
                    matchesCommunity = true;
                  } else {
                    // Check if it belongs to the active community
                    final belongsToActive = 
                        p.locationName.toLowerCase().contains(activeCommunity.shortName.toLowerCase()) ||
                        p.locationName.toLowerCase().contains(activeCommunity.name.toLowerCase()) ||
                        p.locationName.toLowerCase().contains(activeCommunity.id.toLowerCase()) ||
                        p.locationName.toLowerCase().contains(activeCommunity.shortName.toLowerCase().split(' ').first);
                    
                    if (belongsToActive) {
                      matchesCommunity = true;
                    } else {
                      // Check if it belongs to ANY OTHER active community
                      final belongsToOther = activeCommunities.any((comm) {
                        if (comm.id == activeCommunity.id) return false;
                        return p.locationName.toLowerCase().contains(comm.shortName.toLowerCase()) ||
                            p.locationName.toLowerCase().contains(comm.name.toLowerCase()) ||
                            p.locationName.toLowerCase().contains(comm.id.toLowerCase()) ||
                            p.locationName.toLowerCase().contains(comm.shortName.toLowerCase().split(' ').first);
                      });
                      // If it does not belong to any other community, it is a public post
                      if (!belongsToOther) {
                        matchesCommunity = true;
                      }
                    }
                  }
                  return matchesType && matchesCategory && matchesCommunity;
                }).toList();

                if (posts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref.read(postsNotifierProvider.notifier).fetchPosts(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildFeaturedSection(context, allPosts),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items found',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedCategory == 'All'
                                        ? (_selectedType == 'found'
                                            ? 'Active items posted by finders will show up here. Check back later or post a found item yourself!'
                                            : 'Active items posted by owners looking for their belongings will show up here.')
                                        : 'No items matching the "$_selectedCategory" category in this feed.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
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

                return RefreshIndicator(
                  onRefresh: () => ref.read(postsNotifierProvider.notifier).fetchPosts(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFeaturedSection(context, allPosts),
                      ),
                      _isGridView
                          ? SliverPadding(
                              padding: const EdgeInsets.all(12),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return PostCard(post: posts[index]);
                                  },
                                  childCount: posts.length,
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.all(12),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: PostCard(post: posts[index]),
                                    );
                                  },
                                  childCount: posts.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load posts',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: () => ref.read(postsNotifierProvider.notifier).fetchPosts(),
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
//  _CommunityStrip — horizontally scrollable community selector
// ══════════════════════════════════════════════════════════════════════════════

class _CommunityStrip extends ConsumerStatefulWidget {
  final List<PostModel> allPosts;
  final Future<void> Function(Community) onJoin;
  final void Function(Community) onEnterBoard;
  final VoidCallback onLeave;
  final VoidCallback? onHide;

  const _CommunityStrip({
    required this.allPosts,
    required this.onJoin,
    required this.onEnterBoard,
    required this.onLeave,
    this.onHide,
  });

  @override
  ConsumerState<_CommunityStrip> createState() => _CommunityStripState();
}

class _CommunityStripState extends ConsumerState<_CommunityStrip> {
  String _selectedTabType = 'campus';
  bool _initialized = false;

  List<Community> _getCommunitiesList() {
    return ref.read(activeCommunitiesProvider);
  }

  void _showJoinViaLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('Join via Link'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste the invite link of the college or event community below to join it instantly.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Invite Link',
                  hintText: 'tecfind://community/join?id=...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                // Parse community ID from link
                String communityId = text;
                if (text.contains('id=')) {
                  communityId = text.split('id=').last;
                } else if (text.contains('/')) {
                  communityId = text.split('/').last;
                }

                // Lookup community in the dynamic store
                final list = ref.read(activeCommunitiesProvider);
                final match = list.firstWhere(
                  (c) => c.id.toLowerCase() == communityId.toLowerCase(),
                  orElse: () => const Community(
                    id: '',
                    name: '',
                    shortName: '',
                    type: CommunityType.event,
                    emoji: '',
                    location: '',
                    memberCount: 0,
                    accentColor: Colors.grey,
                    description: '',
                  ),
                );

                if (match.id.isNotEmpty) {
                  Navigator.pop(dialogCtx); // Close dialog
                  // Wait for the dialog pop transition to fully complete
                  await Future.delayed(const Duration(milliseconds: 300));
                  widget.onJoin(match);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid link or community board not found.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Join Board'),
            ),
          ],
        );
      },
    );
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
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      widget.onJoin(c);
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


  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final communityState = ref.watch(communityProvider);
    final active     = communityState.selected;

    if (!_initialized) {
      if (active != null) {
        _selectedTabType = active.type == CommunityType.campus ? 'campus' : 'event';
      }
      _initialized = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active community is shown as a chip with cancel button.
          if (active != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.onEnterBoard(active);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: active.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active.accentColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(active.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            active.shortName,
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold,
                              color: active.accentColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onLeave,
                            child: Icon(Icons.cancel_rounded, size: 14, color: active.accentColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Campus vs Event Toggle ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
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
                selected: {_selectedTabType},
                onSelectionChanged: (Set<String> newVal) {
                  setState(() {
                    _selectedTabType = newVal.first;
                  });
                },
              ),
            ),
          ),

          // ── Select Campus Dropdown Trigger ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => _showSearchableCommunityPicker(context, _selectedTabType),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedTabType == 'campus' ? Icons.school_rounded : Icons.event_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        active != null && active.type.name == _selectedTabType
                            ? active.name
                            : (_selectedTabType == 'campus' ? 'Select the Campus' : 'Select the Event'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: active != null && active.type.name == _selectedTabType
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
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text(
                'Join via Invite Link',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _showJoinViaLinkDialog(context);
              },
            ),
          ),
          const SizedBox(height: 6),

          // ── Quick action row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(navigationProvider.notifier).navigateToPost(type: 'lost');
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 16),
                    label: const Text('Report Lost', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(navigationProvider.notifier).navigateToPost(type: 'found');
                    },
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text('Report Found', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

