import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/theme/app_theme.dart';
import '../../data/repositories/user_search_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_search_repository.dart';

// ─── Category model ───────────────────────────────────────────────────────────
enum SearchCategory { owner, driver, mechanic }

extension SearchCategoryX on SearchCategory {
  String get label {
    switch (this) {
      case SearchCategory.owner:
        return 'Owner';
      case SearchCategory.driver:
        return 'Driver';
      case SearchCategory.mechanic:
        return 'Mechanic';
    }
  }

  String get roleParam {
    switch (this) {
      case SearchCategory.owner:
        return 'OWNER';
      case SearchCategory.driver:
        return 'DRIVER';
      case SearchCategory.mechanic:
        return 'MECHANIC';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchCategory.owner:
        return Icons.business_center_rounded;
      case SearchCategory.driver:
        return Icons.person_pin_circle_rounded;
      case SearchCategory.mechanic:
        return Icons.build_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SearchCategory.owner:
        return const Color(0xFF1565C0);
      case SearchCategory.driver:
        return const Color(0xFF0F9D58);
      case SearchCategory.mechanic:
        return const Color(0xFFE65100);
    }
  }
}

// ─── Cities list ──────────────────────────────────────────────────────────────
const _cities = [
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

// ─── Screen ───────────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  SearchCategory? _selected;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final UserSearchRepository _userRepo = UserSearchRepositoryImpl();
  final TextEditingController _searchCtrl = TextEditingController();

  List<UserEntity> _users = [];
  List<UserEntity> _filteredUsers = [];

  bool _loading = false;
  String? _error;
  String _selectedCity = 'ALL';
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadUser();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myUserId = prefs.getInt('user_id'));
  }

  void _selectCategory(SearchCategory cat) {
    setState(() {
      _selected = cat;
      _selectedCity = 'ALL';
      _searchCtrl.clear();
      _users = [];
      _filteredUsers = [];
      _error = null;
    });
    _animCtrl.forward(from: 0);
    _loadResults(cat);
  }

  Future<void> _loadResults(SearchCategory cat) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // All three roles (OWNER, DRIVER, MECHANIC) → GET /api/v1/users?role=
      final users = await _userRepo.getUsersByRole(cat.roleParam);
      setState(() {
        _users = users;
        _applyFilter();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) {
        final matchCity = _selectedCity == 'ALL' || u.city == _selectedCity;
        final matchSearch = q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.city.toLowerCase().contains(q) ||
            u.phoneNumber.toLowerCase().contains(q);
        return matchCity && matchSearch;
      }).toList();
    });
  }

  void _onCityChanged(String city) {
    setState(() => _selectedCity = city);
    // City filter is always applied locally (users are pre-loaded)
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFEEF2FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (_selected != null)
                    GestureDetector(
                      onTap: () {
                        setState(() => _selected = null);
                        _animCtrl.reverse();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: textColor),
                      ),
                    ),
                  Text(
                    'Truck',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      fontSize: 22,
                    ),
                  ),
                  const Text(
                    'Mate',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      fontSize: 22,
                    ),
                  ),
                  if (_selected != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selected!.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_selected!.icon,
                              size: 13, color: _selected!.color),
                          const SizedBox(width: 5),
                          Text(
                            _selected!.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selected!.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: _selected == null
                  ? _buildCategoryGrid(isDark, textColor, cardBg)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildResultsView(
                          isDark, textColor, cardBg, bg),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Landing ──────────────────────────────────────────────────────
  Widget _buildCategoryGrid(bool isDark, Color textColor, Color cardBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you\nlooking for?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a category to explore',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // 3 category tiles in a horizontal row
          Row(
            children: SearchCategory.values
                .map((cat) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _buildCategoryTile(cat, isDark, cardBg),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),

          // Tip banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a category then filter by city or search by name.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      height: 1.4,
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

  Widget _buildCategoryTile(
      SearchCategory cat, bool isDark, Color cardBg) {
    return GestureDetector(
      onTap: () => _selectCategory(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cat.color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: cat.color.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cat.color.withValues(alpha: 0.10),
              ),
              child: Icon(cat.icon, size: 25, color: cat.color),
            ),
            const SizedBox(height: 12),
            Text(
              cat.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results View ──────────────────────────────────────────────────────────
  Widget _buildResultsView(
      bool isDark, Color textColor, Color cardBg, Color bg) {
    final bool isEmpty = _filteredUsers.isEmpty;

    return Column(
      children: [
        // ── Search bar + city chips ───────────────────────────────
        Container(
          color: cardBg,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText:
                        'Search ${_selected?.label.toLowerCase() ?? ''}s by name or city…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppTheme.primaryColor, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                            child: Icon(Icons.close_rounded,
                                color: Colors.grey.shade500, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // City chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cities.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final city = _cities[i];
                    final active = city == _selectedCity;
                    final activeColor =
                        _selected?.color ?? AppTheme.primaryColor;
                    return GestureDetector(
                      onTap: () => _onCityChanged(city),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? activeColor
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? activeColor
                                : isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Result count bar ────────────────────────────────────
        if (!_loading && _error == null && !isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              '${_filteredUsers.length} ${_selected!.label.toLowerCase()}${_filteredUsers.length == 1 ? '' : 's'} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selected!.color,
              ),
            ),
          ),

        // ── List ─────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: _selected?.color ?? AppTheme.primaryColor))
              : _error != null
                  ? _errorState(_error!, textColor, isDark)
                  : isEmpty
                      ? _emptyState(_selected!, isDark, textColor)
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildUserCard(
                              _filteredUsers[i],
                              isDark,
                              textColor,
                              cardBg),
                        ),
        ),
      ],
    );
  }



  // ── User card (Owner / Mechanic) ──────────────────────────────────────────
  Widget _buildUserCard(
      UserEntity u, bool isDark, Color textColor, Color cardBg) {
    final isMe = _myUserId != null && u.id == _myUserId;
    final cat = _selected!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cat.color.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: cat.color.withValues(alpha: 0.12), width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar with role-dot badge
          Stack(
            children: [
              u.profileImage != null && u.profileImage!.isNotEmpty
                  ? CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(u.profileImage!),
                      onBackgroundImageError: (_, _) {},
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: cat.color.withValues(alpha: 0.13),
                      child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: cat.color),
                      ),
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                  child: Icon(cat.icon, size: 8, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        u.name.isNotEmpty ? u.name : 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('You',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cat.color)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      u.city.isNotEmpty ? u.city : 'City not set',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (u.age != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.cake_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text('${u.age} yrs',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cat.color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          if (!isMe)
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.message_rounded,
                    size: 18, color: cat.color),
              ),
            ),
        ],
      ),
    );
  }



  Widget _emptyState(SearchCategory cat, bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cat.color.withValues(alpha: 0.08),
            ),
            child: Icon(cat.icon, size: 36, color: cat.color),
          ),
          const SizedBox(height: 16),
          Text('No ${cat.label.toLowerCase()}s found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 8),
          Text('Try a different city or search term',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _errorState(String err, Color textColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Could not load results',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textColor)),
          const SizedBox(height: 8),
          Text(err,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadResults(_selected!),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, elevation: 0),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
