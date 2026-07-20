// ============================================================
// WarmiBot — Barra de Input inferior
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/assistant_state.dart';
import 'voice_button.dart';

class InputBar extends StatefulWidget {
  final AvatarState avatarState;
  final void Function(String) onSubmit;
  final VoidCallback onVoiceTap;

  const InputBar({
    super.key,
    required this.avatarState,
    required this.onSubmit,
    required this.onVoiceTap,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _ctrl.clear();
    _focus.unfocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
            top: BorderSide(
                color: AppColors.primaryGreen.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // ── Campo de texto ─────────────────────────────────────────────
          Expanded(
            child: TextField(
              controller:  _ctrl,
              focusNode:   _focus,
              textInputAction: TextInputAction.send,
              onSubmitted:     (_) => _submit(),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText:     'Escribe o habla...',
                isDense:      true,
                border:       OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                suffixIcon: _hasText
                    ? IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: AppColors.accentGreen),
                        onPressed: _submit,
                      )
                    : const Icon(Icons.graphic_eq,
                        color: AppColors.textMuted, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Botón de voz ───────────────────────────────────────────────
          VoiceButton(
            avatarState: widget.avatarState,
            onTap:       widget.onVoiceTap,
            size:        48,
          ),
        ]),
      ),
    );
  }
}
