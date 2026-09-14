import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:truck_mate/core/theme/app_theme.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../../posts/data/repositories/driver_posts_repository_impl.dart';
import '../../../posts/domain/repositories/driver_posts_repository.dart';

class DriverManagementScreen extends StatefulWidget {
  final int vehicleId;
  const DriverManagementScreen({super.key, required this.vehicleId});
  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final DriverRepository _repo = DriverRepositoryImpl();
  final DriverPostsRepository _postsRepo = DriverPostsRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  DriverEntity? _driver;
  bool _loading = true;
  bool _saving = false;
  bool _posting = false;
  bool _hasDriver = false;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDriver() async {
    setState(() => _loading = true);
    try {
      final driver = await _repo.getDriver(widget.vehicleId);
      _driver = driver;
      _hasDriver = true;
      _nameCtrl.text = driver.driverName;
      _ageCtrl.text = driver.driverAge.toString();
      _cityCtrl.text = driver.driverCity;
    } catch (_) {
      _hasDriver = false;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final age = int.parse(_ageCtrl.text.trim());
      final city = _cityCtrl.text.trim();

      DriverEntity result;
      if (_hasDriver) {
        result = await _repo.updateDriver(
            vehicleId: widget.vehicleId,
            driverName: name,
            driverAge: age,
            driverCity: city);
      } else {
        result = await _repo.addDriver(
            vehicleId: widget.vehicleId,
            driverName: name,
            driverAge: age,
            driverCity: city);
      }
      setState(() { _driver = result; _hasDriver = true; });
      _showSnack(_hasDriver ? 'Driver updated!' : 'Driver added!');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Driver'),
        content: const Text('Are you sure you want to remove this driver?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteDriver(widget.vehicleId);
      setState(() { _driver = null; _hasDriver = false; _nameCtrl.clear(); _ageCtrl.clear(); _cityCtrl.clear(); });
      _showSnack('Driver removed');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _saving = false);
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

  Future<void> _postForDriver() async {
    setState(() => _posting = true);
    try {
      await _postsRepo.postForDriver(widget.vehicleId);
      if (!mounted) return;
      _showSnack('🎉 Posted! Drivers can now see your vehicle.');
      // Navigate back to Home tab (index 0)
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('already') ||
          msg.contains('driver')) {
        _showSnack('This vehicle already has a driver or is already posted.',
            isError: true);
      } else {
        _showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFF0F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final border = isDark ? Colors.white12 : const Color(0xFFD1D5DB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text('Manage Driver',
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasDriver)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_hasDriver) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'No driver assigned yet. Fill in the details below to add one.',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildField('Driver Name', _nameCtrl, textColor, border, cardBg, isDark,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null),
                  const SizedBox(height: 14),
                  _buildField('Age', _ageCtrl, textColor, border, cardBg, isDark,
                      inputType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null) return 'Enter valid age';
                        if (n < 18 || n > 100) return 'Age must be 18–100';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  _buildField('City', _cityCtrl, textColor, border, cardBg, isDark,
                      validator: (v) => v == null || v.trim().isEmpty ? 'City required' : null),
                  const SizedBox(height: 28),
                  // Save / Update Driver button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _hasDriver ? 'Update Driver' : 'Add Driver',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                  // Post Vehicle for Driver button — only if NO driver assigned yet
                  if (!_hasDriver) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_posting || _saving) ? null : _postForDriver,
                        icon: _posting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.campaign_rounded,
                                size: 20, color: Colors.white),
                        label: const Text(
                          'Post Vehicle for Driver',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    Color textColor,
    Color border,
    Color cardBg,
    bool isDark, {
    TextInputType? inputType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, color: textColor),
          validator: validator,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2)),
          ),
        ),
      ],
    );
  }
}
