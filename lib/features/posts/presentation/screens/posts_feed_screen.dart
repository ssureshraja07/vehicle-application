import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/theme/app_theme.dart';
import '../../../posts/data/repositories/driver_posts_repository_impl.dart';
import '../../../posts/domain/entities/driver_post_entity.dart';
import '../../../posts/domain/repositories/driver_posts_repository.dart';
import '../../../vehicles/data/repositories/vehicle_repository_impl.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});
  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  final DriverPostsRepository _repo = DriverPostsRepositoryImpl();
  final VehicleRepository _vehicleRepo = VehicleRepositoryImpl();
  final TextEditingController _searchCtrl = TextEditingController();
  List<DriverPostEntity> _posts = [];
  List<DriverPostEntity> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedCity = 'ALL';
  int? _myUserId;

  static const _cities = [
    'ALL',
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Hyderabad',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Thoothukudi',
    'Coimbatore',
    'Madurai',
    'Trichy',
  ];

  @override
  void initState() {
    super.initState();
    _initUser();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myUserId = prefs.getInt('user_id'));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _repo.getDriverPosts(city: _selectedCity);
      setState(() {
        _posts = posts;
        _applyFilter();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_posts)
          : _posts
                .where(
                  (p) =>
                      p.ownerName.toLowerCase().contains(q) ||
                      p.ownerCity.toLowerCase().contains(q) ||
                      p.vehicleType.toLowerCase().contains(q) ||
                      p.vehicleNumber.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _sendRequest(DriverPostEntity post) async {
    try {
      await _vehicleRepo.sendRequest(post.vehicleId);
      _showSnack('Request sent to ${post.ownerName}! ✅');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _deletePost(DriverPostEntity post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Post'),
        content: const Text('Remove this post from the feed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deletePost(post.postId);
      _showSnack('Post removed');
      _load();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCityPicker(
    BuildContext ctx,
    bool isDark,
    Color cardBg,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Filter by City',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.8,
                children: _cities.map((city) {
                  final selected = _selectedCity == city;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFEEF2FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ───────────────────────────────────────────────────
            Container(
              color: cardBg,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TruckMate brand header
                  Row(
                    children: [
                      Text(
                        'Truck',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const Text(
                        'Mate',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _load,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: textColor,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search bar (70%) + Filter button (30%)
                  Row(
                    children: [
                      // Search field — 70%
                      Expanded(
                        flex: 7,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Search vehicle, owner...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Filter button — 30%
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => _showCityPicker(
                            context,
                            isDark,
                            cardBg,
                            textColor,
                          ),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _selectedCity == 'ALL'
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.shade100)
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedCity == 'ALL'
                                    ? Colors.transparent
                                    : AppTheme.primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: _selectedCity == 'ALL'
                                      ? (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600)
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _selectedCity == 'ALL'
                                        ? 'Filter'
                                        : _selectedCity,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedCity == 'ALL'
                                          ? (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600)
                                          : AppTheme.primaryColor,
                                    ),
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
            ),

            // ── Feed ─────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 52,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vehicle owners post here to find drivers',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 0),
                        itemBuilder: (_, i) => _PostCard(
                          post: _filtered[i],
                          isDark: isDark,
                          cardBg: cardBg,
                          textColor: textColor,
                          isOwn:
                              _myUserId != null &&
                              _filtered[i].ownerId == _myUserId,
                          onSendRequest: () => _sendRequest(_filtered[i]),
                          onDelete: () => _deletePost(_filtered[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instagram-style Post Card ────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final DriverPostEntity post;
  final bool isDark, isOwn;
  final Color cardBg, textColor;
  final VoidCallback onSendRequest, onDelete;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.isOwn,
    required this.cardBg,
    required this.textColor,
    required this.onSendRequest,
    required this.onDelete,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final hasImage = p.vehicleImage != null && p.vehicleImage!.isNotEmpty;

    return Container(
      color: widget.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post Header (like Instagram) ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.ownerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: widget.textColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: widget.isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            p.ownerCity,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Vehicle type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.vehicleType.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (widget.isOwn) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Vehicle Image with overlaid type + number bars ───────────
          Stack(
            children: [
              // Full-body image
              hasImage
                  ? Image.network(
                      p.vehicleImage!,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _noImagePlaceholder(p, widget.isDark),
                    )
                  : _noImagePlaceholder(p, widget.isDark),

              // TOP gradient bar — vehicle body type
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    p.vehicleType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // BOTTOM gradient bar — vehicle number
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.vehicleNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Action Row — time only ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  _timeAgo(p.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // ── CTA Button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: widget.isOwn
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Remove Post',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onSendRequest,
                      icon: const Icon(
                        Icons.handshake_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Send Request',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
          ),

          // Thin divider between posts
          Divider(
            height: 1,
            thickness: 0.5,
            color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _noImagePlaceholder(DriverPostEntity p, bool isDark) {
    return Container(
      width: double.infinity,
      height: 320,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFEEF2FF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_rounded,
            size: 72,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            p.vehicleType.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
