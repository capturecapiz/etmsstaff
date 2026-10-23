import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final emp = await EdmateService(session.api).profile();
      if (mounted) setState(() => _employee = emp);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
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
                            backgroundImage: _employee?.photoUrl != null ? NetworkImage(_employee!.photoUrl!) : null,
                            child: _employee?.photoUrl == null
                                ? Text(
                                    _employee != null && _employee!.name.isNotEmpty ? _employee!.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _employee?.name ?? '',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _employee?.designation ?? '',
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
                            subtitle: Text(_employee?.department ?? '-'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined, color: Color(0xFF3B82F6)),
                            title: const Text('Classification'),
                            subtitle: Text(_employee?.classification ?? '-'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            'PTCAO Employee Task Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
