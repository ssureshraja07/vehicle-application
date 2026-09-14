import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truck_mate/core/theme/app_theme.dart';
import 'package:truck_mate/features/auth/presentation/screens/login_screen.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../vehicles/data/repositories/vehicle_repository_impl.dart';
import '../../../vehicles/data/repositories/driver_repository_impl.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';
import '../../../vehicles/domain/entities/vehicle_entity.dart';
import '../../../vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../../vehicles/presentation/screens/driver_management_screen.dart';
import '../../../posts/data/repositories/driver_posts_repository_impl.dart';
import '../../../posts/domain/repositories/driver_posts_repository.dart';

const _roles = ['OWNER', 'DRIVER', 'MECHANIC'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  final AuthRepository _authRepo = AuthRepositoryImpl();
  final VehicleRepository _vehicleRepo = VehicleRepositoryImpl();
  final DriverRepositoryImpl _driverRepo = DriverRepositoryImpl();
  final DriverPostsRepository _postsRepo = DriverPostsRepositoryImpl();

  ProfileEntity? _profile;
  List<VehicleEntity> _vehicles = [];
  /// vehicleId -> driver name (null means no driver)
  Map<int, String?> _vehicleDriverName = {};
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedRole = 'OWNER';
  XFile? _newImage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _profileRepo.getProfile(),
        _vehicleRepo.getMyVehicles(),
      ]);
      final p = results[0] as ProfileEntity;
      final v = results[1] as List<VehicleEntity>;
      _profile = p;
      _vehicles = v;
      _nameCtrl.text = p.name ?? '';
      _ageCtrl.text = p.age?.toString() ?? '';
      _cityCtrl.text = p.city ?? '';
      _selectedRole = p.role ?? 'OWNER';

      // Fetch driver name for each vehicle (null if no driver)
      final driverChecks = await Future.wait(
        v.map((vehicle) async {
          try {
            final driver = await _driverRepo.getDriver(vehicle.id);
            return MapEntry(vehicle.id, driver.driverName);
          } catch (_) {
            return MapEntry<int, String?>(vehicle.id, null);
          }
        }),
      );
      _vehicleDriverName = Map.fromEntries(driverChecks);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
      _showSnack('Name and city are required', isError: true);
      return;
    }
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 18 || age > 100) {
      _showSnack('Enter a valid age (18–100)', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _profileRepo.updateProfile(
        name: _nameCtrl.text.trim(),
        age: age,
        role: _selectedRole,
        city: _cityCtrl.text.trim(),
        profileImage: _newImage != null ? File(_newImage!.path) : null,
      );
      setState(() {
        _profile = updated;
        _editing = false;
        _newImage = null;
      });
      _showSnack('Profile updated!');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authRepo.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false);
  }

  Future<void> _postForDriver(VehicleEntity v) async {
    try {
      await _postsRepo.postForDriver(v.id);
      _showSnack('🎉 Posted! Drivers can now see your vehicle.');
      _loadAll();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('already')) {
        _showSnack('Already posted for this vehicle!', isError: true);
      } else {
        _showSnack(msg, isError: true);
      }
    }
  }

  Future<void> _deleteVehicle(VehicleEntity v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Delete ${v.vehicleNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _vehicleRepo.deleteVehicle(v.id);
      _showSnack('Vehicle deleted');
      _loadAll();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFEEF2FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
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
          ],
        ),
        actions: [
          // Notification icon (was settings)
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          // Settings icon (was logout)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadAll,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _editing
                  ? _buildEditView(isDark, textColor, cardBg, bg)
                  : _buildProfileView(isDark, textColor, cardBg, bg),
    );
  }

  // ─── VIEW MODE ────────────────────────────────────────────────────────────
  Widget _buildProfileView(
      bool isDark, Color textColor, Color cardBg, Color bg) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header Card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Instagram-style: Avatar left, Stats right ────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () async {
                        final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery, imageQuality: 70);
                        if (img != null) setState(() => _newImage = img);
                      },
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: _newImage != null
                            ? FileImage(File(_newImage!.path))
                            : (_profile?.profileImage != null
                                ? NetworkImage(_profile!.profileImage!)
                                    as ImageProvider
                                : null),
                        child: (_newImage == null &&
                                _profile?.profileImage == null)
                            ? Text(
                                (_profile?.name?.isNotEmpty == true
                                        ? _profile!.name![0]
                                        : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Name + Stats (right side)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_profile?.name ?? 'No Name').toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Stats row
                          Row(
                            children: [
                              _statItem('Vehicles',
                                  _vehicles.length.toString(), textColor, isDark),
                              const SizedBox(width: 28),
                              _statItem('Posts', '—', textColor, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // City with location pin
                if (_profile?.city != null && _profile!.city!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _profile!.city!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Edit Profile & Share Profile buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _editing = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Share Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── My Vehicles Section ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Vehicles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddVehicleScreen()),
                    );
                    _loadAll();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Vehicle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (_vehicles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 56,
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No vehicles added yet',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── 2×2 Instagram-style grid ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.85,
                ),
                itemCount: _vehicles.length,
                itemBuilder: (_, i) {
                  final v = _vehicles[i];
                  final driverName = _vehicleDriverName[v.id];
                  return _buildVehicleGridTile(
                      v, isDark, textColor, cardBg, driverName);
                },
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color textColor, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 2×2 grid tile — compact square card.
  /// • Full image cover
  /// • Vehicle type at TOP, number at BOTTOM (gradient overlay)
  /// • Driver avatar (with initials) OR gold ➕ in TOP-RIGHT corner
  /// • Tapping the card opens the options bottom sheet
  Widget _buildVehicleGridTile(VehicleEntity v, bool isDark, Color textColor,
      Color cardBg, String? driverName) {
    final hasDriver = driverName != null;
    final hasImage = v.vehicleImage != null && v.vehicleImage!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showVehicleOptions(v, hasDriver),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image / fallback ───────────────────────
            hasImage
                ? Image.network(
                    v.vehicleImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gridFallback(v, isDark),
                  )
                : _gridFallback(v, isDark),

            // ── TOP gradient bar — vehicle body type ──────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 36, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  v.vehicleType.replaceAll('_', ' ').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            // ── BOTTOM gradient bar — vehicle number ──────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  v.vehicleNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // ── Driver avatar / gold + in TOP-RIGHT ───────────────
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _showVehicleOptions(v, hasDriver),
                child: hasDriver
                    // Circular avatar with driver initials
                    ? Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade600,
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            driverName.isNotEmpty
                                ? driverName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    // Gold + circle (no driver)
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFB300),
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet shown when owner taps a vehicle tile.
  void _showVehicleOptions(VehicleEntity v, bool hasDriver) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Vehicle info header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        size: 22, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.vehicleNumber,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: textColor)),
                      Text(v.vehicleType.replaceAll('_', ' '),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Option 1 — Add / Update Driver
              _sheetOption(
                icon: Icons.person_add_alt_1_rounded,
                label: hasDriver ? 'Update Driver' : 'Add Driver',
                color: const Color(0xFF1565C0),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DriverManagementScreen(vehicleId: v.id)),
                  );
                  _loadAll();
                },
              ),

              // Option 2 — Post Vehicle for Driver (only if no driver)
              if (!hasDriver) ...[
                const SizedBox(height: 4),
                _sheetOption(
                  icon: Icons.campaign_rounded,
                  label: 'Post Vehicle for Driver',
                  color: const Color(0xFF0F9D58),
                  onTap: () {
                    Navigator.pop(context);
                    _postForDriver(v);
                  },
                ),
              ],

              const SizedBox(height: 4),
              // Option 3 — Delete
              _sheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Vehicle',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _deleteVehicle(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _gridFallback(VehicleEntity v, bool isDark) {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFEEF2FF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded,
              size: 42,
              color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              v.vehicleType.replaceAll('_', ' '),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIT MODE ────────────────────────────────────────────────────────────
  Widget _buildEditView(
      bool isDark, Color textColor, Color cardBg, Color bg) {
    final border = isDark ? Colors.white12 : const Color(0xFFD1D5DB);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Center(
            child: GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 70);
                if (img != null) setState(() => _newImage = img);
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                    backgroundImage: _newImage != null
                        ? FileImage(File(_newImage!.path))
                        : (_profile?.profileImage != null
                            ? NetworkImage(_profile!.profileImage!)
                                as ImageProvider
                            : null),
                    child: (_newImage == null &&
                            _profile?.profileImage == null)
                        ? Text(
                            (_profile?.name?.isNotEmpty == true
                                    ? _profile!.name![0]
                                    : '?')
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Form Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _field('Name', _nameCtrl, textColor, border, isDark),
                const SizedBox(height: 12),
                _field('Age', _ageCtrl, textColor, border, isDark,
                    inputType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  dropdownColor: cardBg,
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border)),
                  ),
                  items: _roles
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 12),
                _field('City', _cityCtrl, textColor, border, isDark),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _newImage = null;
                    if (_profile != null) {
                      _nameCtrl.text = _profile!.name ?? '';
                      _ageCtrl.text = _profile!.age?.toString() ?? '';
                      _cityCtrl.text = _profile!.city ?? '';
                      _selectedRole = _profile!.role ?? 'OWNER';
                    }
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    Color textColor,
    Color border,
    bool isDark, {
    TextInputType? inputType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
    );
  }
}
