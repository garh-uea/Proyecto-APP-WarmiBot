import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/backend_api_service.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/backend_status_indicator.dart';

class SessionLoadingPage extends StatelessWidget {
  const SessionLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          liveRegion: true,
          label: 'Comprobando sesión',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class ApiStatusPage extends StatelessWidget {
  const ApiStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de la API')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_heart_outlined, size: 64),
              const SizedBox(height: 16),
              Text('Comprobación pública',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Esta pantalla consume GET /health y no requiere iniciar sesión.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const BackendStatusIndicator(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ir al acceso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso restringido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_outlined, size: 64),
              const SizedBox(height: 16),
              Text('HTTP 403: sesión válida, permiso insuficiente',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                auth.message ??
                    'Tu cuenta permanece iniciada, pero no tiene el rol requerido.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  context.read<AuthCubit>().clearForbidden();
                  context.go('/inicio');
                },
                child: const Text('Volver a Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProtectedResourcePage extends StatefulWidget {
  final String title;
  final String endpoint;
  final String resourceId;

  const ProtectedResourcePage({
    super.key,
    required this.title,
    required this.endpoint,
    required this.resourceId,
  });

  @override
  State<ProtectedResourcePage> createState() => _ProtectedResourcePageState();
}

class _ProtectedResourcePageState extends State<ProtectedResourcePage> {
  final _api = BackendApiService();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = context.read<AuthCubit>().state.session?.accessToken;
    if (token == null) return;
    try {
      final data = await _api.getProtectedObject(widget.endpoint, token);
      if (mounted) setState(() => _data = data);
    } on BackendApiException catch (error) {
      if (!mounted) return;
      await context.read<AuthCubit>().handleProtectedFailure(error);
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded, size: 56),
              const SizedBox(height: 16),
              Text('Recurso ${widget.resourceId}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('GET ${widget.endpoint}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (_loading)
                const CircularProgressIndicator()
              else if (_error != null) ...[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ] else
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_data),
                  textAlign: TextAlign.left,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico administrativo')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ruta exclusiva para el rol administrador. Consume los endpoints de /api/v1/diagnostics cuando el diagnóstico está habilitado.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
