import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/notion_service.dart';
import '../theme/palette.dart';
import '../utils/bmi.dart';
import '../utils/format.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/app_background.dart';
import '../widgets/bouncy.dart';
import '../widgets/error_box.dart';
import '../widgets/pulse_loader.dart';

/// Admin only: see all users, change roles, delete accounts.
class AdminScreen extends StatefulWidget {
  final AuthService auth;
  const AdminScreen({super.key, required this.auth});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _service = NotionService();
  final Map<String, double> _latest = {}; // username -> latest weight
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
      final all = await _service.fetchAll(); // oldest first, every user
      _latest.clear();
      for (final e in all) {
        if (e.user != null) _latest[e.user!] = e.weight;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? kGreen : kInk,
        content: Text(msg),
      ));
  }

  Future<void> _setRole(AppUser u, UserRole role) async {
    try {
      await widget.auth.setRole(u.username, role);
    } on AuthException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _create() async {
    final ok = await showCreateUserDialog(context, widget.auth);
    if (ok == true) _snack('User created', ok: true);
  }

  Future<void> _resetPassword(AppUser u) async {
    final ok = await showResetPasswordDialog(context, widget.auth, u.username);
    if (ok == true) _snack('Password updated for ${u.username}', ok: true);
  }

  Future<void> _delete(AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
            'Remove "${u.username}" from this device. Their weight rows stay in Notion.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.auth.deleteUser(u.username);
    } on AuthException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (r) => kMainGradient.createShader(r),
            child: const Text('Admin',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
          ),
        ),
        body: _loading
            ? const Center(child: PulseLoader())
            : _error != null
            ? Center(child: ErrorBox(message: _error!, onRetry: _load))
            : RefreshIndicator(
          color: kPurple,
          onRefresh: _load,
          child: ListenableBuilder(
            listenable: widget.auth,
            builder: (context, _) {
              final users = widget.auth.users;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${users.length} user${users.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kInk)),
                      ),
                      Bouncy(
                        onTap: _create,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: kMainGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_alt_1,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Add user',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final u in users) _userCard(u),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _userCard(AppUser u) {
    final isMe = u.username == widget.auth.current?.username;
    final isAdmin = u.role == UserRole.admin;
    final p = u.profile;
    final w = _latest[u.username] ?? p?.currentWeight;

    String summary = 'No goal set';
    Color accent = Colors.grey;
    if (p != null && w != null) {
      final bmi = bmiOf(w, p.heightCm);
      final cat = bmiCategory(bmi);
      accent = cat == 'Normal' ? kGreen : (cat == 'Underweight' ? kBlue : kOrange);
      summary = '${fmt(w)} kg · BMI ${bmi.toStringAsFixed(1)} ($cat) · goal ${fmt(p.goalWeight)} kg';
    } else if (w != null) {
      summary = '${fmt(w)} kg · no goal set';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: accent, width: 5)),
        boxShadow: [
          BoxShadow(
              color: kPurple.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(u.username + (isMe ? ' (you)' : ''),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isAdmin ? kPurple : kBlue).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isAdmin ? 'Admin' : 'User',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isAdmin ? kPurple : kBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(summary,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'password') _resetPassword(u);
              if (v == 'role') _setRole(u, isAdmin ? UserRole.user : UserRole.admin);
              if (v == 'delete') _delete(u);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'password', child: Text('Reset password')),
              if (!isMe)
                PopupMenuItem(
                    value: 'role',
                    child: Text(isAdmin ? 'Make normal user' : 'Make admin')),
              if (!isMe)
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
