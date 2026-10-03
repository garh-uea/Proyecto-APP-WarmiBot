import '../../domain/services/backend_api_service.dart';

abstract interface class RemindersRemoteDataSource {
  Future<List<BackendReminder>> listReminders();
  Future<BackendReminder> synchronize(Map<String, dynamic> payload);
}

class ApiRemindersRemoteDataSource implements RemindersRemoteDataSource {
  final BackendApiService _api;

  ApiRemindersRemoteDataSource({BackendApiService? api})
      : _api = api ?? BackendApiService();

  @override
  Future<List<BackendReminder>> listReminders() => _api.listReminders();

  @override
  Future<BackendReminder> synchronize(Map<String, dynamic> payload) =>
      _api.syncReminder(payload: payload);
}
