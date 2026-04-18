import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:arrendaoco/theme/tema.dart';
import 'package:arrendaoco/theme/app_gradients.dart';
import 'package:shimmer/shimmer.dart';

class StunningTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isPassword;
  final List<TextInputFormatter>? inputFormatters;

  const StunningTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isPassword = false,
    this.inputFormatters,
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
                  ? MiTema.celeste.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
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
          inputFormatters: widget.inputFormatters,
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
                color: (widget.backgroundColor ?? MiTema.azul).withValues(
                  alpha: 0.4,
                ),
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

class StunningCard extends StatefulWidget {
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
  State<StunningCard> createState() => _StunningCardState();
}

class _StunningCardState extends State<StunningCard>
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
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: MiTema.celeste.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(24.0),
              child: widget.child,
            ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              color: MiTema.celeste.withValues(alpha: 0.1),
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
                    color: MiTema.vino.withValues(alpha: 0.3),
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

class StunningShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const StunningShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class StunningShimmerCard extends StatelessWidget {
  final bool isGrid;

  const StunningShimmerCard({super.key, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return StunningCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flexible Image placeholder
            const Expanded(
              child: StunningShimmer(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  StunningShimmer(width: 100, height: 14),
                  SizedBox(height: 8),
                  StunningShimmer(width: 60, height: 14),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StunningCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const StunningShimmer(
            width: double.infinity,
            height: 220,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price placeholders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    StunningShimmer(width: 150, height: 20),
                    StunningShimmer(width: 80, height: 20),
                  ],
                ),
                const SizedBox(height: 8),
                // Address placeholder
                const StunningShimmer(width: 200, height: 14),
                const SizedBox(height: 12),
                // Features chips placeholders
                Row(
                  children: const [
                    StunningShimmer(width: 60, height: 24, borderRadius: 12),
                    SizedBox(width: 12),
                    StunningShimmer(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StunningDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const StunningDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.validator,
  });

  @override
  State<StunningDropdown<T>> createState() => _StunningDropdownState<T>();
}

class _StunningDropdownState<T> extends State<StunningDropdown<T>>
    with SingleTickerProviderStateMixin {
  final bool _isFocused = false; // Simulado para dropdown
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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
                  ? MiTema.celeste.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isFocused ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Listener(
          onPointerDown: (_) => _controller.forward(),
          onPointerUp: (_) => _controller.reverse(),
          child: DropdownButtonFormField<T>(
            isExpanded: true,
            value: widget.value,
            items: widget.items,
            onChanged: (v) {
              widget.onChanged(v);
              _controller.reverse();
            },
            validator: widget.validator,
            icon: Icon(Icons.arrow_drop_down_rounded, color: MiTema.celeste),
            style: TextStyle(
              color: MiTema.azul,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(widget.icon, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, // Reduced from 20
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class StunningPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  StunningPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      );
}
