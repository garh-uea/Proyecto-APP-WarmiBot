import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/presentation/bloc/assistant_bloc.dart';
import 'package:warmibot/presentation/bloc/assistant_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inicio restaura el menú sin borrar el historial', () async {
    final bloc = AssistantBloc();
    addTearDown(bloc.close);

    bloc.add(const ProcessTextCommand('hola'));
    await bloc.stream.firstWhere(
      (state) => !state.isProcessing && state.messages.length == 2,
    );
    expect(bloc.state.showHomeMenu, isFalse);

    bloc.add(const ShowHomeMenu());
    await bloc.stream.firstWhere((state) => state.showHomeMenu);

    expect(bloc.state.messages, hasLength(2));
    expect(bloc.state.showHomeMenu, isTrue);
  });

  test('limpiar historial termina en estado vacío y utilizable', () async {
    final bloc = AssistantBloc();
    addTearDown(bloc.close);

    bloc.add(const ProcessTextCommand('hola'));
    await bloc.stream.firstWhere(
      (state) => !state.isProcessing && state.messages.length == 2,
    );
    bloc.add(const ClearChat());
    await bloc.stream.firstWhere((state) => state.messages.isEmpty);

    expect(bloc.state.isProcessing, isFalse);
    expect(bloc.state.errorMessage, isNull);
    expect(bloc.state.showHomeMenu, isTrue);
  });
}
