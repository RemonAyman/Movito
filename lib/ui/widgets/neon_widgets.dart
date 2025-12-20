import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class NeonTitle extends StatelessWidget {
  final String title;
  const NeonTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
          shadows: [
            Shadow(
              color: AppColors.neonGlow.withValues(alpha: 0.9),
              blurRadius: 45,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class NeonBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;

  const NeonBox({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neonGlow, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGlow.withValues(alpha: 0.6),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeonInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool isPassword;

  const NeonInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeonBox(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 17),
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, color: AppColors.neonGlow),
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFFBCAFFF), fontSize: 17),
          ),
        ),
      ),
    );
  }
}

class NeonPassword extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;

  const NeonPassword({
    super.key,
    required this.controller,
    required this.placeholder,
  });

  @override
  State<NeonPassword> createState() => _NeonPasswordState();
}

class _NeonPasswordState extends State<NeonPassword> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return NeonBox(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 17),
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.lock, color: AppColors.neonGlow),
            hintText: widget.placeholder,
            hintStyle: const TextStyle(color: Color(0xFFBCAFFF), fontSize: 17),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.neonGlow,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onClick;
  final bool loading;
  final bool enabled;

  const NeonButton({
    super.key,
    required this.text,
    required this.onClick,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !loading ? onClick : null,
      child: NeonBox(
        height: 65,
        width: double.infinity,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.textColor,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
