import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import '../widgets/app_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Employee? _employee;
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
    if (!emp.isNameSet && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final session = context.read<Session>();
      final updated = await EdmateService(session.api).updateProfile(
        // Only sent (and only ever accepted by the server) while the name
        // hasn't been set yet -- see profile_update.php's write-once gate.
        firstName: !emp.isNameSet && _firstNameCtrl.text.trim().isNotEmpty ? _firstNameCtrl.text.trim() : null,
        lastName: !emp.isNameSet && _lastNameCtrl.text.trim().isNotEmpty ? _lastNameCtrl.text.trim() : null,
        middleInitial: !emp.isNameSet ? _middleInitialCtrl.text.trim() : null,
        salary: !emp.isSalarySet && _salaryCtrl.text.trim().isNotEmpty ? _salaryCtrl.text.trim() : null,
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
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 26),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3B82F6), Color(0xFF5B9BF8)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white,
                                backgroundImage: resolveServerUrl(emp?.photoUrl) != null
                                    ? NetworkImage(resolveServerUrl(emp?.photoUrl)!)
                                    : null,
                                child: resolveServerUrl(emp?.photoUrl) == null
                                    ? Text(
                                        emp != null && emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 14),
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
                        const SizedBox(height: 22),
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
                        if (emp != null && !emp.isNameSet) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFE0A3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB8860B)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Please enter your name details below. This is a one-time setup needed before you can apply for leave.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF6B4E00)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
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
                        ] else if (emp != null) ...[
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF3B82F6)),
                              title: const Text('Full Name'),
                              subtitle: Text('${emp.firstName} ${emp.middleInitial.isNotEmpty ? '${emp.middleInitial}. ' : ''}${emp.lastName}'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (emp != null && !emp.isSalarySet) ...[
                          TextFormField(
                            controller: _salaryCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Monthly Salary (₱)',
                              helperText: 'One-time setup, needed for official leave forms.',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else if (emp != null && emp.salary != null) ...[
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.payments_outlined, color: Color(0xFF3B82F6)),
                              title: const Text('Monthly Salary'),
                              subtitle: Text('₱${emp.salary!.toStringAsFixed(2)}'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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
    );
  }
}
