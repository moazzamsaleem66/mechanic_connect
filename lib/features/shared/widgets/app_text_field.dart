import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.hintText,
    this.controller,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputType,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final Widget? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? textInputType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: textInputType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
