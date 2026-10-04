import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// Las dos capacidades son opcionales: nunca bloquean la lectura o el envío.
enum DeviceCapability { microphone, notifications }

enum CapabilityState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

abstract class CapabilityPermissionGateway {
  Future<CapabilityState> status(DeviceCapability capability);
  Future<CapabilityState> request(DeviceCapability capability);
  Future<bool> openSettings();
}

class PluginCapabilityPermissionGateway implements CapabilityPermissionGateway {
  const PluginCapabilityPermissionGateway();

  Permission _permission(DeviceCapability capability) => switch (capability) {
    DeviceCapability.microphone => Permission.microphone,
    DeviceCapability.notifications => Permission.notification,
  };

  CapabilityState _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return CapabilityState.granted;
    }
    if (status.isPermanentlyDenied) return CapabilityState.permanentlyDenied;
    if (status.isRestricted) return CapabilityState.restricted;
    return CapabilityState.denied;
  }

  @override
  Future<CapabilityState> status(DeviceCapability capability) async {
    try {
      final primary = _map(await _permission(capability).status);
      if (primary != CapabilityState.granted) return primary;
      // El dictado en iOS requiere las dos autorizaciones por separado.
      if (capability == DeviceCapability.microphone && Platform.isIOS) {
        return _map(await Permission.speech.status);
      }
      return primary;
    } catch (_) {
      return CapabilityState.unavailable;
    }
  }

  @override
  Future<CapabilityState> request(DeviceCapability capability) async {
    try {
      final primary = _map(await _permission(capability).request());
      if (primary != CapabilityState.granted) return primary;
      if (capability == DeviceCapability.microphone && Platform.isIOS) {
        return _map(await Permission.speech.request());
      }
      return primary;
    } catch (_) {
      return CapabilityState.unavailable;
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}

class DeviceCapabilityService {
  DeviceCapabilityService({CapabilityPermissionGateway? gateway})
    : _gateway = gateway ?? const PluginCapabilityPermissionGateway();

  final CapabilityPermissionGateway _gateway;

  Future<CapabilityState> status(DeviceCapability capability) =>
      _gateway.status(capability);

  Future<CapabilityState> request(DeviceCapability capability) =>
      _gateway.request(capability);

  Future<bool> openSettings() => _gateway.openSettings();
}
