import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/domain/services/device_capability_service.dart';
import 'package:warmibot/presentation/widgets/capability_permission_prompt.dart';

class FakeCapabilityGateway implements CapabilityPermissionGateway {
  CapabilityState current;
  CapabilityState next;
  int requests = 0;
  int settings = 0;

  FakeCapabilityGateway(this.current, this.next);

  @override
  Future<CapabilityState> status(DeviceCapability capability) async => current;

  @override
  Future<CapabilityState> request(DeviceCapability capability) async {
    requests++;
    current = next;
    return next;
  }

  @override
  Future<bool> openSettings() async {
    settings++;
    return true;
  }
}

Widget testApp(DeviceCapabilityService service, DeviceCapability capability) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => CapabilityPermissionPrompt.ensure(
            context,
            capability,
            service: service,
          ),
          child: const Text('Probar permiso'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('explica antes de pedir micrófono', (tester) async {
    final gateway = FakeCapabilityGateway(
      CapabilityState.denied,
      CapabilityState.granted,
    );
    await tester.pumpWidget(
      testApp(
        DeviceCapabilityService(gateway: gateway),
        DeviceCapability.microphone,
      ),
    );
    await tester.tap(find.text('Probar permiso'));
    await tester.pumpAndSettle();
    expect(find.text('Usar el micrófono'), findsOneWidget);
    expect(gateway.requests, 0);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(gateway.requests, 1);
  });

  testWidgets('denegación permanente ofrece abrir ajustes', (tester) async {
    final gateway = FakeCapabilityGateway(
      CapabilityState.permanentlyDenied,
      CapabilityState.permanentlyDenied,
    );
    await tester.pumpWidget(
      testApp(
        DeviceCapabilityService(gateway: gateway),
        DeviceCapability.notifications,
      ),
    );
    await tester.tap(find.text('Probar permiso'));
    await tester.pumpAndSettle();
    expect(find.text('Permiso bloqueado'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(gateway.settings, 1);
    expect(gateway.requests, 0);
  });

  testWidgets('rechazo conserva alternativa sin permiso', (tester) async {
    final gateway = FakeCapabilityGateway(
      CapabilityState.denied,
      CapabilityState.denied,
    );
    await tester.pumpWidget(
      testApp(
        DeviceCapabilityService(gateway: gateway),
        DeviceCapability.microphone,
      ),
    );
    await tester.tap(find.text('Probar permiso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(gateway.requests, 0);
    expect(find.text('Probar permiso'), findsOneWidget);
  });
}
