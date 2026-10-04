import 'package:flutter/material.dart';

import '../../domain/services/device_capability_service.dart';

class CapabilityPermissionPrompt {
  CapabilityPermissionPrompt._();

  static final DeviceCapabilityService _service = DeviceCapabilityService();

  static Future<bool> ensure(
    BuildContext context,
    DeviceCapability capability, {
    DeviceCapabilityService? service,
  }) async {
    final permissionService = service ?? _service;
    var state = await permissionService.status(capability);
    if (!context.mounted) return false;
    if (state == CapabilityState.granted) return true;

    if (state == CapabilityState.denied) {
      final accept = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            capability == DeviceCapability.microphone
                ? 'Usar el micrófono'
                : 'Activar notificaciones',
          ),
          content: Text(
            capability == DeviceCapability.microphone
                ? 'WarmiBot escucha solo cuando pulsas el botón de voz. '
                      'Convierte lo que dices en texto para crear comandos y '
                      'recordatorios. Si no autorizas, puedes escribirlos.'
                : 'WarmiBot enviará una alerta local cuando llegue la hora '
                      'de un recordatorio. Si no autorizas, el registro se '
                      'guardará y sincronizará igualmente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (accept != true || !context.mounted) return false;
      state = await permissionService.request(capability);
      if (!context.mounted) return false;
    }

    if (state == CapabilityState.granted) return true;
    if (state == CapabilityState.permanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Permiso bloqueado'),
          content: Text(
            capability == DeviceCapability.microphone
                ? 'El permiso del micrófono se bloqueó. Puedes habilitarlo '
                      'en Ajustes de la aplicación o seguir escribiendo.'
                : 'El permiso de notificaciones se bloqueó. Puedes '
                      'habilitarlo en Ajustes; el recordatorio seguirá '
                      'guardado aunque no recibas una alerta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Seguir sin permiso'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await permissionService.openSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        ),
      );
      return false;
    }

    final message = switch (state) {
      CapabilityState.denied =>
        capability == DeviceCapability.microphone
            ? 'Sin permiso de micrófono. Puedes escribir tu mensaje.'
            : 'Sin permiso de notificaciones. El recordatorio se guarda sin alerta.',
      CapabilityState.restricted =>
        'El sistema restringe esta capacidad. Puedes seguir usando la aplicación.',
      CapabilityState.unavailable =>
        'Esta capacidad no está disponible en el dispositivo.',
      _ => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}
