import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';

class StunningTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isPassword;

  const StunningTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isPassword = false,
  });

  @override
  State<StunningTextField> createState() => _StunningTextFieldState();
}

class _StunningTextFieldState extends State<StunningTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? MiTema.celeste.withOpacity(0.4)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isFocused ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          obscureText: _isObscured,
          style: TextStyle(color: MiTema.azul, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _isFocused ? MiTema.celeste : Colors.grey[600],
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? MiTema.celeste : Colors.grey[400],
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: _isFocused ? MiTema.celeste : Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class StunningButton extends StatefulWidget {
  final VoidCallback? onPressed; // Cambiado a nullable para soportar disable
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSmall;

  const StunningButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isSmall = false,
  });

  @override
  State<StunningButton> createState() => _StunningButtonState();
}

class _StunningButtonState extends State<StunningButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isSmall ? null : double.infinity, // Ajuste para isSmall
          decoration: BoxDecoration(
            gradient: widget.backgroundColor == null
                ? AppGradients.primaryGradient
                : null,
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.backgroundColor ?? MiTema.azul).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            vertical: widget.isSmall ? 8 : 16,
            horizontal: widget.isSmall ? 16 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.isSmall ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.textColor ?? Colors.white,
                  size: widget.isSmall ? 18 : 24,
                ),
                SizedBox(width: widget.isSmall ? 6 : 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor ?? Colors.white,
                  fontSize: widget.isSmall ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StunningCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const StunningCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: MiTema.celeste.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StunningSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const StunningSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Buscar...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: MiTema.azul),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: MiTema.celeste),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiTema.celeste.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tune_rounded, color: MiTema.celeste, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class StunningChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const StunningChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MiTema.vino : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: MiTema.vino.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
