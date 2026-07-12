// ============================================================
// WarmiBot — Botón de Voz (micrófono central)
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/assistant_state.dart';

class VoiceButton extends StatefulWidget {
  final AvatarState avatarState;
  final VoidCallback onTap;
  final double size;

  const VoiceButton({
    super.key,
    required this.avatarState,
    required this.onTap,
    this.size = 72,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(VoiceButton old) {
    super.didUpdateWidget(old);
    if (widget.avatarState == AvatarState.listening) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop(); _ctrl.reset();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  bool get _isListening => widget.avatarState == AvatarState.listening;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Transform.scale(scale: _anim.value, child: child),
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: _isListening
                  ? [AppColors.neonGreen, AppColors.primaryGreen]
                  : [AppColors.primaryGreen, AppColors.primaryGreenDark],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isListening ? AppColors.neonGreen : AppColors.primaryGreen)
                    .withValues(alpha: 0.6),
                blurRadius: _isListening ? 24 : 12,
                spreadRadius: _isListening ? 4 : 2,
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color:  Colors.white,
            size:   widget.size * 0.42,
          ),
        ),
      ),
    );
  }
}
