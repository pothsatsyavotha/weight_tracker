import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/palette.dart';
import 'app_text_field.dart';

/// Returns true when a user was created.
Future<bool?> showCreateUserDialog(BuildContext context, AuthService auth) =>
    showDialog<bool>(context: context, builder: (_) => _CreateUserDialog(auth: auth));

/// Returns true when the password was changed.
Future<bool?> showResetPasswordDialog(
    BuildContext context, AuthService auth, String username) =>
    showDialog<bool>(
        context: context,
        builder: (_) => _ResetPasswordDialog(auth: auth, username: username));

class _CreateUserDialog extends StatefulWidget {
  final AuthService auth;
  const _CreateUserDialog({required this.auth});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _admin = false;
  bool _hide = true;
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.auth.createUser(
          _user.text, _pass.text, _admin ? UserRole.admin : UserRole.user);
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Add user'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                  controller: _user,
                  label: 'Username',
                  icon: Icons.person_outline,
                  autofocus: true),
              const SizedBox(height: 12),
              AppTextField(
                controller: _pass,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: _hide,
                trailing: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
                onSubmitted: (_) => _create(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Admin'),
                value: _admin,
                activeColor: kPurple,
                onChanged: (v) => setState(() => _admin = v),
              ),
              if (_err != null)
                Text(_err!,
                    style: const TextStyle(
                        color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _create,
          style: FilledButton.styleFrom(backgroundColor: kPurple),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final AuthService auth;
  final String username;
  const _ResetPasswordDialog({required this.auth, required this.username});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.auth.resetPassword(widget.username, _pass.text);
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('New password for ${widget.username}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _pass,
              label: 'New password',
              icon: Icons.lock_reset,
              obscure: _hide,
              autofocus: true,
              trailing: IconButton(
                icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(() => _hide = !_hide),
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: const TextStyle(
                      color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: kPurple),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
