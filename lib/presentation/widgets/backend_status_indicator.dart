import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/services/backend_api_service.dart';

class BackendStatusIndicator extends StatefulWidget {
  final BackendApiService? service;

  const BackendStatusIndicator({super.key, this.service});

  @override
  State<BackendStatusIndicator> createState() => _BackendStatusIndicatorState();
}

class _BackendStatusIndicatorState extends State<BackendStatusIndicator> {
  late final BackendApiService _service;
  late final bool _ownsService;
  BackendHealth? _health;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? BackendApiService();
    _check();
  }

  Future<void> _check() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final health = await _service.checkHealth();
      if (!mounted) return;
      setState(() => _health = health);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _health = null;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    if (_ownsService) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _health?.isHealthy == true;
    final color = _loading
        ? AppColors.textMuted
        : connected
            ? AppColors.accentGreen
            : Colors.orangeAccent;
    final label = _loading
        ? 'Verificando API'
        : connected
            ? 'Backend conectado'
            : 'Backend sin conexión';
    final details = connected
        ? '${_health!.endpoint} (${_health!.environment})'
        : _error ?? 'Toca para reintentar';

    return Semantics(
      button: true,
      label: label,
      hint: 'Toca para comprobar nuevamente la conexión',
      child: Tooltip(
        message: details,
        child: InkWell(
          key: const Key('backend-status-indicator'),
          borderRadius: BorderRadius.circular(20),
          onTap: _loading ? null : _check,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: color,
                    ),
                  )
                else
                  Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 5),
                Text(
                  _loading
                      ? 'API...'
                      : connected
                          ? 'API conectada'
                          : 'API sin conexión',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
