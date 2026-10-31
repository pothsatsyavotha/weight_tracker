import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/palette.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;
  String? _err;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      if (_register) {
        await widget.auth.register(_user.text, _pass.text);
      } else {
        await widget.auth.login(_user.text, _pass.text);
      }
      // On success AuthService notifies and the app swaps to the tracker.
    } on AuthException catch (e) {
      if (mounted) setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: kMainGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: kPurple.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.monitor_weight_outlined,
                            color: Colors.white, size: 42),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (r) => kMainGradient.createShader(r),
                        child: Text(_register ? 'Create account' : 'Welcome back',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _user,
                      label: 'Username',
                      icon: Icons.person_outline,
                      autofocus: true,
                      onChanged: (_) => setState(() => _err = null),
                    ),
                    const SizedBox(height: 14),
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
                      onChanged: (_) => setState(() => _err = null),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_err != null) ...[
                      const SizedBox(height: 12),
                      Text(_err!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 22),
                    GradientButton(
                      label: _register ? 'Register' : 'Log in',
                      busy: _busy,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() {
                        _register = !_register;
                        _err = null;
                      }),
                      child: Text(
                        _register
                            ? 'Already have an account? Log in'
                            : "Don't have an account? Register",
                        style: const TextStyle(
                            color: kPurple, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_register)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'The first account created becomes the admin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
