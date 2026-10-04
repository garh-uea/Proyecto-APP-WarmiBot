// ============================================================
// WarmiBot — Avatar animado con estados visuales
// Basado en el diseño amazónico de la imagen de referencia
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/assistant_state.dart';

class WarmiAvatar extends StatefulWidget {
  final AvatarState avatarState;
  final double soundLevel;
  final double size;

  const WarmiAvatar({
    super.key,
    required this.avatarState,
    this.soundLevel = 0.0,
    this.size = 200,
  });

  @override
  State<WarmiAvatar> createState() => _WarmiAvatarState();
}

class _WarmiAvatarState extends State<WarmiAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _idleCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _waveAnim;
  late Animation<double> _idleAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim = Tween(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _waveAnim = Tween(begin: 0.0, end: 1.0).animate(_waveCtrl);

    _idleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _idleAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));

    _idleCtrl.repeat(reverse: true);
    _updateAnimations();
  }

  @override
  void didUpdateWidget(WarmiAvatar old) {
    super.didUpdateWidget(old);
    if (old.avatarState != widget.avatarState) _updateAnimations();
  }

  void _updateAnimations() {
    switch (widget.avatarState) {
      case AvatarState.listening:
        _pulseCtrl.repeat(reverse: true);
        _waveCtrl.repeat();
        break;
      case AvatarState.thinking:
        _pulseCtrl.repeat(reverse: true);
        _waveCtrl.stop();
        break;
      case AvatarState.speaking:
        _pulseCtrl.repeat(reverse: true);
        _waveCtrl.repeat();
        break;
      case AvatarState.idle:
      case AvatarState.error:
        _pulseCtrl.stop();
        _pulseCtrl.reset();
        _waveCtrl.stop();
        _waveCtrl.reset();
        break;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        // ── Anillos de onda (escucha / habla) ────────────────────────────
        if (widget.avatarState == AvatarState.listening ||
            widget.avatarState == AvatarState.speaking)
          ..._buildWaveRings(),

        // ── Glow exterior verde neón ──────────────────────────────────────
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (message, index) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: widget.size * 0.88,
              height: widget.size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withValues(alpha: 0.55),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Avatar principal ──────────────────────────────────────────────
        AnimatedBuilder(
          animation: _idleAnim,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _idleAnim.value * 4 - 2),
            child: child,
          ),
          child: Container(
            width: widget.size * 0.82,
            height: widget.size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.avatarGradient,
              ),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.6),
                width: 2.5,
              ),
            ),
            child: ClipOval(
              child: _avatarContent(),
            ),
          ),
        ),

        // ── Indicador de estado (texto pequeño) ──────────────────────────
        Positioned(
          bottom: 6,
          child: _StateChip(avatarState: widget.avatarState),
        ),
      ]),
    );
  }

  // Retrato amazónico compartido por los distintos estados del asistente.
  Widget _avatarContent() {
    return Image.asset(
      'assets/images/warmibot_fondo.png',
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.42),
      semanticLabel: 'Retrato ilustrado de WarmiBot, asistente amazónica',
      filterQuality: FilterQuality.high,
    );
  }

  List<Widget> _buildWaveRings() {
    return List.generate(3, (i) {
      return AnimatedBuilder(
        animation: _waveAnim,
        builder: (context, child) {
          final progress = (_waveAnim.value + i * 0.33) % 1.0;
          return Opacity(
            opacity: (1.0 - progress) * 0.5,
            child: Container(
              width: widget.size * (0.7 + progress * 0.6),
              height: widget.size * (0.7 + progress * 0.6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _glowColor,
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Color get _glowColor {
    switch (widget.avatarState) {
      case AvatarState.listening:
        return AppColors.neonGreen;
      case AvatarState.thinking:
        return AppColors.accentTeal;
      case AvatarState.speaking:
        return AppColors.accentGreen;
      case AvatarState.error:
        return AppColors.accentCoral;
      case AvatarState.idle:
        return AppColors.primaryGreen;
    }
  }
}

class _StateChip extends StatelessWidget {
  final AvatarState avatarState;
  const _StateChip({required this.avatarState});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (avatarState) {
      AvatarState.listening => ('Escuchando...', AppColors.neonGreen),
      AvatarState.thinking => ('Pensando...', AppColors.accentTeal),
      AvatarState.speaking => ('Hablando...', AppColors.accentGreen),
      AvatarState.error => ('Error', AppColors.accentCoral),
      AvatarState.idle => ('WarmiBot', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
