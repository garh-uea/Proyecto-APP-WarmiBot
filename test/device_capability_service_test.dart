import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/domain/services/device_capability_service.dart';

class FakePermissionGateway implements CapabilityPermissionGateway {
  CapabilityState current;
  CapabilityState requested;
  int requestCount = 0;
  int settingsCount = 0;

  FakePermissionGateway(this.current, this.requested);

  @override
  Future<CapabilityState> status(DeviceCapability capability) async => current;

  @override
  Future<CapabilityState> request(DeviceCapability capability) async {
    requestCount++;
    current = requested;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsCount++;
    return true;
  }
}

void main() {
  test('distingue permiso concedido y permite usar la capacidad', () async {
    final gateway = FakePermissionGateway(
      CapabilityState.granted,
      CapabilityState.granted,
    );
    final service = DeviceCapabilityService(gateway: gateway);
    expect(
      await service.status(DeviceCapability.microphone),
      CapabilityState.granted,
    );
    expect(gateway.requestCount, 0);
  });

  test('distingue denegación recuperable y concesión posterior', () async {
    final gateway = FakePermissionGateway(
      CapabilityState.denied,
      CapabilityState.granted,
    );
    final service = DeviceCapabilityService(gateway: gateway);
    expect(
      await service.status(DeviceCapability.notifications),
      CapabilityState.denied,
    );
    expect(
      await service.request(DeviceCapability.notifications),
      CapabilityState.granted,
    );
    expect(gateway.requestCount, 1);
  });

  test('denegación permanente conserva acceso a ajustes', () async {
    final gateway = FakePermissionGateway(
      CapabilityState.permanentlyDenied,
      CapabilityState.permanentlyDenied,
    );
    final service = DeviceCapabilityService(gateway: gateway);
    expect(
      await service.status(DeviceCapability.microphone),
      CapabilityState.permanentlyDenied,
    );
    expect(await service.openSettings(), isTrue);
    expect(gateway.requestCount, 0);
    expect(gateway.settingsCount, 1);
  });

  test(
    'restricción e indisponibilidad no se confunden con denegación',
    () async {
      final restricted = DeviceCapabilityService(
        gateway: FakePermissionGateway(
          CapabilityState.restricted,
          CapabilityState.restricted,
        ),
      );
      final unavailable = DeviceCapabilityService(
        gateway: FakePermissionGateway(
          CapabilityState.unavailable,
          CapabilityState.unavailable,
        ),
      );
      expect(
        await restricted.status(DeviceCapability.microphone),
        CapabilityState.restricted,
      );
      expect(
        await unavailable.status(DeviceCapability.notifications),
        CapabilityState.unavailable,
      );
    },
  );
}
