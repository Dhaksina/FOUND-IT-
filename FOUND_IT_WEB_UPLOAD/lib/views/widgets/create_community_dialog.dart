import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/community_provider.dart';

class CreateCommunityDialog extends ConsumerStatefulWidget {
  final CommunityType initialType;

  const CreateCommunityDialog({super.key, required this.initialType});

  static Future<Community?> show(BuildContext context, CommunityType initialType) {
    return showDialog<Community>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateCommunityDialog(initialType: initialType),
    );
  }

  @override
  ConsumerState<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends ConsumerState<CreateCommunityDialog> {
  final _formKey = GlobalKey<FormState>();
  late CommunityType _type;

  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emojiController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailDomainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _emojiController.text = _type == CommunityType.campus ? '🏫' : '🎫';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _locationController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();
    _emailDomainController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final shortName = _shortNameController.text.trim();
    final location = _locationController.text.trim();
    final emoji = _emojiController.text.trim();
    final description = _descriptionController.text.trim();
    final domain = _type == CommunityType.campus ? _emailDomainController.text.trim() : null;

    final id = 'custom_${_type.name}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    final newCommunity = Community(
      id: id,
      name: name,
      shortName: shortName,
      type: _type,
      emoji: emoji.isNotEmpty ? emoji : (_type == CommunityType.campus ? '🏫' : '🎫'),
      emailDomain: domain,
      location: location,
      memberCount: 1,
      accentColor: _type == CommunityType.campus ? Colors.indigo : Colors.deepOrange,
      description: description.isNotEmpty ? description : 'Board for $name.',
    );

    // 1. Add to communities list provider
    ref.read(communitiesListProvider.notifier).addCommunity(newCommunity);

    // 2. Return the newly created community
    Navigator.pop(context, newCommunity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCampus = _type == CommunityType.campus;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isCampus ? 'Create College Board' : 'Create Event Board',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Toggle Type
                SegmentedButton<CommunityType>(
                  segments: const [
                    ButtonSegment(value: CommunityType.campus, label: Text('College Campus'), icon: Icon(Icons.school)),
                    ButtonSegment(value: CommunityType.event, label: Text('Event / Fest'), icon: Icon(Icons.event)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      _emojiController.text = _type == CommunityType.campus ? '🏫' : '🎫';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isCampus ? 'College / University Name*' : 'Event / Fest Name*',
                    hintText: isCampus ? 'e.g. Madras Medical College' : 'e.g. Techfest Hacker Camp',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Short Name and Emoji Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _shortNameController,
                        decoration: const InputDecoration(
                          labelText: 'Short Name*',
                          hintText: 'e.g. MMC',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _emojiController,
                        decoration: const InputDecoration(
                          labelText: 'Emoji',
                          hintText: '🏫',
                          border: OutlineInputBorder(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location input
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / State*',
                    hintText: 'e.g. Chennai, Tamil Nadu',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email Domain input (only for campus)
                if (isCampus) ...[
                  TextFormField(
                    controller: _emailDomainController,
                    decoration: const InputDecoration(
                      labelText: 'Official Email Domain*',
                      hintText: 'e.g. mmc.tn.gov.in',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required for student email verification';
                      }
                      if (!val.contains('.') || val.startsWith('.')) {
                        return 'Please enter a valid domain (e.g. mmc.edu)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Description input
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about this board...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _submit,
                      child: const Text('Create & Select'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
