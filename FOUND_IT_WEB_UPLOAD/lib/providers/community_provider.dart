import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Community type ────────────────────────────────────────────────────────────
enum CommunityType { campus, event }

// ── Community model ───────────────────────────────────────────────────────────
class Community {
  final String id;
  final String name;           // Display name
  final String shortName;      // Short label for chips
  final CommunityType type;
  final String emoji;
  final String? emailDomain;   // e.g. 'abc.edu.in' — only for campus
  final String location;
  final int memberCount;
  final Color accentColor;
  final String description;
  final DateTime? createdAt;   // Expiration tracking

  const Community({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.emoji,
    this.emailDomain,
    required this.location,
    required this.memberCount,
    required this.accentColor,
    required this.description,
    this.createdAt,
  });

  Community copyWith({
    String? id,
    String? name,
    String? shortName,
    CommunityType? type,
    String? emoji,
    String? emailDomain,
    String? location,
    int? memberCount,
    Color? accentColor,
    String? description,
    DateTime? createdAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      emailDomain: emailDomain ?? this.emailDomain,
      location: location ?? this.location,
      memberCount: memberCount ?? this.memberCount,
      accentColor: accentColor ?? this.accentColor,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ── Seeded communities ────────────────────────────────────────────────────────
const List<Community> seedCommunities = [
  // ── Indian Colleges (Campuses) ──────────────────────────────────────────────
  Community(
    id: 'iit_madras',
    name: 'Indian Institute of Technology (IIT) Madras',
    shortName: 'IIT Madras',
    type: CommunityType.campus,
    emoji: '🎓',
    emailDomain: 'iitm.ac.in',
    location: 'Chennai, Tamil Nadu',
    memberCount: 9800,
    accentColor: Color(0xFF4F46E5),
    description: 'Official board for IIT Madras students, faculty, and research staff.',
  ),
  Community(
    id: 'iit_bombay',
    name: 'Indian Institute of Technology (IIT) Bombay',
    shortName: 'IIT Bombay',
    type: CommunityType.campus,
    emoji: '🏛️',
    emailDomain: 'iitb.ac.in',
    location: 'Mumbai, Maharashtra',
    memberCount: 11200,
    accentColor: Color(0xFF1E3A8A),
    description: 'Official board for IIT Bombay Powai campus members.',
  ),
  Community(
    id: 'iit_delhi',
    name: 'Indian Institute of Technology (IIT) Delhi',
    shortName: 'IIT Delhi',
    type: CommunityType.campus,
    emoji: '🏫',
    emailDomain: 'iitd.ac.in',
    location: 'New Delhi, Delhi',
    memberCount: 10400,
    accentColor: Color(0xFF0F766E),
    description: 'Official board for IIT Delhi Hauz Khas campus members.',
  ),
  Community(
    id: 'iit_kharagpur',
    name: 'Indian Institute of Technology (IIT) Kharagpur',
    shortName: 'IIT KGP',
    type: CommunityType.campus,
    emoji: '📚',
    emailDomain: 'iitkgp.ac.in',
    location: 'Kharagpur, West Bengal',
    memberCount: 12500,
    accentColor: Color(0xFFD97706),
    description: 'Board for the oldest IIT campus community at Kharagpur.',
  ),
  Community(
    id: 'bits_pilani',
    name: 'Birla Institute of Technology and Science (BITS) Pilani',
    shortName: 'BITS Pilani',
    type: CommunityType.campus,
    emoji: '💡',
    emailDomain: 'pilani.bits-pilani.ac.in',
    location: 'Pilani, Rajasthan',
    memberCount: 6800,
    accentColor: Color(0xFF2563EB),
    description: 'Community board for BITS Pilani students and alumni.',
  ),
  Community(
    id: 'nit_trichy',
    name: 'National Institute of Technology (NIT) Trichy',
    shortName: 'NIT Trichy',
    type: CommunityType.campus,
    emoji: '⚙️',
    emailDomain: 'nitt.edu',
    location: 'Tiruchirappalli, Tamil Nadu',
    memberCount: 7100,
    accentColor: Color(0xFF7C3AED),
    description: 'Official board for NIT Trichy engineering students.',
  ),
  Community(
    id: 'vit_vellore',
    name: 'Vellore Institute of Technology (VIT) Vellore',
    shortName: 'VIT Vellore',
    type: CommunityType.campus,
    emoji: '⚡',
    emailDomain: 'vit.ac.in',
    location: 'Vellore, Tamil Nadu',
    memberCount: 22000,
    accentColor: Color(0xFF059669),
    description: 'Official board for VIT Vellore campus members.',
  ),
  Community(
    id: 'srm_univ',
    name: 'SRM Institute of Science and Technology',
    shortName: 'SRM Kattankulathur',
    type: CommunityType.campus,
    emoji: '🏢',
    emailDomain: 'srmist.edu.in',
    location: 'Chennai, Tamil Nadu',
    memberCount: 18500,
    accentColor: Color(0xFFBE185D),
    description: 'Board for SRM Kattankulathur campus students.',
  ),
  Community(
    id: 'delhi_univ',
    name: 'University of Delhi',
    shortName: 'Delhi Univ',
    type: CommunityType.campus,
    emoji: '🖋️',
    emailDomain: 'du.ac.in',
    location: 'New Delhi, Delhi',
    memberCount: 45000,
    accentColor: Color(0xFF9333EA),
    description: 'North and South campus community board for DU.',
  ),
  Community(
    id: 'mit_manipal',
    name: 'Manipal Institute of Technology',
    shortName: 'MIT Manipal',
    type: CommunityType.campus,
    emoji: '🧬',
    emailDomain: 'manipal.edu',
    location: 'Manipal, Karnataka',
    memberCount: 9200,
    accentColor: Color(0xFFEA580C),
    description: 'Community board for Manipal academy students.',
  ),
  Community(
    id: 'psg_tech',
    name: 'PSG College of Technology',
    shortName: 'PSG Tech',
    type: CommunityType.campus,
    emoji: '🛠️',
    emailDomain: 'psgtech.ac.in',
    location: 'Coimbatore, Tamil Nadu',
    memberCount: 8200,
    accentColor: Color(0xFF0369A1),
    description: 'Official board for PSG Tech Coimbatore students.',
  ),
  Community(
    id: 'abc_engg',
    name: 'ABC Engineering College',
    shortName: 'ABC Engg',
    type: CommunityType.campus,
    emoji: '🏛️',
    emailDomain: 'abcengg.edu.in',
    location: 'Chennai, Tamil Nadu',
    memberCount: 2340,
    accentColor: Color(0xFF4F46E5),
    description: 'Campus board for ABC Engineering College students & staff.',
  ),
  Community(
    id: 'mit_chennai',
    name: 'MIT Campus Chennai',
    shortName: 'MIT Chennai',
    type: CommunityType.campus,
    emoji: '🎓',
    emailDomain: 'mitchennai.edu.in',
    location: 'Chennai, Tamil Nadu',
    memberCount: 5120,
    accentColor: Color(0xFF7C3AED),
    description: 'Lost & found board for MIT Chennai campus.',
  ),
  Community(
    id: 'anna_univ',
    name: 'Anna University',
    shortName: 'Anna Univ',
    type: CommunityType.campus,
    emoji: '📚',
    emailDomain: 'annauniv.edu',
    location: 'Chennai, Tamil Nadu',
    memberCount: 8900,
    accentColor: Color(0xFF65A30D),
    description: 'Community board for Anna University campus.',
  ),
  Community(
    id: 'iisc_bangalore',
    name: 'Indian Institute of Science (IISc)',
    shortName: 'IISc Bangalore',
    type: CommunityType.campus,
    emoji: '🔬',
    emailDomain: 'iisc.ac.in',
    location: 'Bengaluru, Karnataka',
    memberCount: 4200,
    accentColor: Color(0xFF0D9488),
    description: 'Official research campus board for IISc Bangalore.',
  ),
  Community(
    id: 'rvce_blr',
    name: 'RV College of Engineering',
    shortName: 'RVCE Bangalore',
    type: CommunityType.campus,
    emoji: '📐',
    emailDomain: 'rvce.edu.in',
    location: 'Bengaluru, Karnataka',
    memberCount: 5400,
    accentColor: Color(0xFF0284C7),
    description: 'Board for RVCE Bengaluru campus students.',
  ),
  Community(
    id: 'iiit_hyd',
    name: 'International Institute of Information Technology Hyderabad',
    shortName: 'IIIT Hyderabad',
    type: CommunityType.campus,
    emoji: '💻',
    emailDomain: 'iiit.ac.in',
    location: 'Hyderabad, Telangana',
    memberCount: 3100,
    accentColor: Color(0xFF4F46E5),
    description: 'Official campus board for IIIT Hyderabad.',
  ),
  Community(
    id: 'loyola_chn',
    name: 'Loyola College Chennai',
    shortName: 'Loyola College',
    type: CommunityType.campus,
    emoji: '🔔',
    emailDomain: 'loyolacollege.edu',
    location: 'Chennai, Tamil Nadu',
    memberCount: 7800,
    accentColor: Color(0xFFB45309),
    description: 'Official board for Loyola College Chennai campus.',
  ),
  Community(
    id: 'christ_univ',
    name: 'Christ University',
    shortName: 'Christ Bangalore',
    type: CommunityType.campus,
    emoji: '🕊️',
    emailDomain: 'christuniversity.in',
    location: 'Bengaluru, Karnataka',
    memberCount: 16000,
    accentColor: Color(0xFF0891B2),
    description: 'Official board for Christ University campus members.',
  ),

  // ── Events ──────────────────────────────────────────────────────────────────
  Community(
    id: 'techfest_2025',
    name: 'TechFest 2025',
    shortName: 'TechFest',
    type: CommunityType.event,
    emoji: '🚀',
    emailDomain: null,
    location: 'IIT Madras, Chennai',
    memberCount: 3400,
    accentColor: Color(0xFFFF6B6B),
    description: 'Lost & found for TechFest 2025 attendees.',
  ),
  Community(
    id: 'kulturals_2025',
    name: 'Kulturals Fest 2025',
    shortName: 'Kulturals',
    type: CommunityType.event,
    emoji: '🎭',
    emailDomain: null,
    location: 'Tidel Park, Chennai',
    memberCount: 1800,
    accentColor: Color(0xFFFFB347),
    description: 'Board for Kulturals cultural fest participants.',
  ),
  Community(
    id: 'marathon_2025',
    name: 'Chennai Marathon 2025',
    shortName: 'Marathon',
    type: CommunityType.event,
    emoji: '🏃',
    emailDomain: null,
    location: 'Marina Beach, Chennai',
    memberCount: 6200,
    accentColor: Color(0xFF9B59B6),
    description: 'Items lost/found during the Chennai Marathon.',
  ),
];

// ── State ─────────────────────────────────────────────────────────────────────
class CommunityState {
  final Community? selected;
  final bool isVerified;
  final String? verifiedEmail;
  final List<Community> joined;

  const CommunityState({
    this.selected,
    this.isVerified = false,
    this.verifiedEmail,
    this.joined = const [],
  });

  CommunityState copyWith({
    Community? selected,
    bool? isVerified,
    String? verifiedEmail,
    List<Community>? joined,
    bool clearSelected = false,
  }) {
    return CommunityState(
      selected: clearSelected ? null : (selected ?? this.selected),
      isVerified: isVerified ?? this.isVerified,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      joined: joined ?? this.joined,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class CommunityNotifier extends Notifier<CommunityState> {
  @override
  CommunityState build() => const CommunityState();

  /// Join an event community — no verification required.
  void joinEvent(Community community) {
    final list = List<Community>.from(state.joined);
    if (!list.any((c) => c.id == community.id)) {
      list.add(community);
    }
    state = CommunityState(
      selected: community,
      isVerified: true,
      verifiedEmail: null,
      joined: list,
    );
  }

  /// Join a campus community after email domain verification.
  void joinCampus(Community community, String email) {
    final list = List<Community>.from(state.joined);
    if (!list.any((c) => c.id == community.id)) {
      list.add(community);
    }
    state = CommunityState(
      selected: community,
      isVerified: true,
      verifiedEmail: email,
      joined: list,
    );
  }

  /// Select/switch to an already joined community.
  void selectCommunity(Community community) {
    state = state.copyWith(
      selected: community,
      isVerified: true,
    );
  }

  /// Leave the current community board.
  void leave() {
    state = state.copyWith(clearSelected: true, isVerified: false);
  }

  /// Leave and remove a community from the joined list entirely.
  void leaveAndRemove(Community community) {
    final list = List<Community>.from(state.joined)..removeWhere((c) => c.id == community.id);
    final isSelected = state.selected?.id == community.id;
    state = CommunityState(
      selected: isSelected ? null : state.selected,
      isVerified: isSelected ? false : state.isVerified,
      verifiedEmail: isSelected ? null : state.verifiedEmail,
      joined: list,
    );
  }

  /// Simulate email domain verification.
  /// Returns true if the email domain matches the community's expected domain.
  bool verifyEmail(Community community, String email) {
    final trimmed = email.trim().toLowerCase();
    final domain  = community.emailDomain?.toLowerCase() ?? '';
    if (domain.isEmpty) return true; // events need no verify
    return trimmed.endsWith('@$domain');
  }
}

final communityProvider =
    NotifierProvider<CommunityNotifier, CommunityState>(() => CommunityNotifier());

class CommunitiesListNotifier extends Notifier<List<Community>> {
  @override
  List<Community> build() {
    return List.from(seedCommunities);
  }

  void addCommunity(Community community) {
    final communityWithTime = community.copyWith(createdAt: DateTime.now());
    state = [...state, communityWithTime];
  }
}

final communitiesListProvider =
    NotifierProvider<CommunitiesListNotifier, List<Community>>(() => CommunitiesListNotifier());

/// Provider that returns only seed communities + user created communities that are less than 1 week old.
final activeCommunitiesProvider = Provider<List<Community>>((ref) {
  final list = ref.watch(communitiesListProvider);
  final now = DateTime.now();
  return list.where((comm) {
    if (comm.createdAt == null) return true; // Seed communities never expire
    final difference = now.difference(comm.createdAt!);
    return difference.inDays < 7; // Expire after 1 week (7 days)
  }).toList();
});

// Convenience selectors
final activeCommunityProvider = Provider<Community?>((ref) {
  return ref.watch(communityProvider).selected;
});

final isCommunityVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(communityProvider).isVerified;
});
