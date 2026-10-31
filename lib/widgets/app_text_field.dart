import 'package:flutter/material.dart';

import '../theme/palette.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixIcon: trailing,
        prefixIcon: Icon(icon, color: kPurple),
        filled: true,
        fillColor: kPurple.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kPurple, width: 2)),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
