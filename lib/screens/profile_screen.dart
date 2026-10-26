import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Employee? _employee;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleInitialCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleInitialCtrl.dispose();
    _salaryCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final emp = await EdmateService(session.api).profile();
      if (mounted) {
        setState(() {
          _employee = emp;
          _firstNameCtrl.text = emp.firstName;
          _lastNameCtrl.text = emp.lastName;
          _middleInitialCtrl.text = emp.middleInitial;
          _salaryCtrl.text = emp.salary != null ? emp.salary!.toStringAsFixed(2) : '';
          _contactCtrl.text = emp.contactNumber;
          _emailCtrl.text = emp.email;
          _addressCtrl.text = emp.address;
          _dob = emp.dateOfBirth;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Lets the employee tap their avatar to replace their profile photo,
  /// from either the camera or the gallery, then uploads it via
  /// profile_update.php's multipart "photo" field (see edmate_service.dart)
  /// and refreshes both this screen and the shared Session with the
  /// resulting photoUrl.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Update Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF3B82F6)),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF3B82F6)),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(source == ImageSource.camera ? 'Could not open the camera.' : 'Could not open the gallery.')),
        );
      }
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final session = context.read<Session>();
      final updated = await EdmateService(session.api).updateProfilePhoto(picked.path);
      session.updateEmployee(updated);
      if (mounted) {
        setState(() => _employee = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final emp = _employee;
    if (emp == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final session = context.read<Session>();
      final updated = await EdmateService(session.api).updateProfile(
        // Freely editable now (no write-once lock) per the employee's own
        // request — see profile_update.php's updated comment for why.
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleInitial: _middleInitialCtrl.text.trim(),
        salary: _salaryCtrl.text.trim().isNotEmpty ? _salaryCtrl.text.trim() : null,
        contactNumber: _contactCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        dateOfBirth: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
      );
      session.updateEmployee(updated);
      if (mounted) {
        setState(() => _employee = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final emp = _employee;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickPhoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: resolveServerUrl(emp?.photoUrl) != null
                            ? NetworkImage(resolveServerUrl(emp?.photoUrl)!)
                            : null,
                        child: resolveServerUrl(emp?.photoUrl) == null
                            ? Text(
                                emp != null && emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                              )
                            : null,
                      ),
                      if (_uploadingPhoto)
                        const Positioned.fill(
                          child: CircleAvatar(
                            backgroundColor: Colors.black38,
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emp?.name ?? '',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  emp?.designation ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            children: [
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.apartment_outlined, color: Color(0xFF3B82F6)),
                                title: const Text('Department'),
                                subtitle: Text(emp?.department ?? '-'),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.badge_outlined, color: Color(0xFF3B82F6)),
                                title: const Text('Classification'),
                                subtitle: Text(emp?.classification ?? '-'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _firstNameCtrl,
                                decoration: const InputDecoration(labelText: 'First Name'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _lastNameCtrl,
                                decoration: const InputDecoration(labelText: 'Last Name'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _middleInitialCtrl,
                                maxLength: 5,
                                decoration: const InputDecoration(labelText: 'M.I.', counterText: ''),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _salaryCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Monthly Salary (₱)',
                            helperText: 'Used for official leave forms.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.call_outlined)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDob,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_outlined)),
                            child: Text(_dob != null ? DateFormat.yMMMd().format(_dob!) : 'Not set'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined)),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () => session.logout(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Log Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: 0.55,
                          child: Column(
                            children: const [
                              AppLogo(size: 30),
                              SizedBox(height: 6),
                              Text(
                                AppConfig.appFullName,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
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
}
