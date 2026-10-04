import 'dart:io';

import 'package:dio/dio.dart';

enum ApiFailureFamily { connectivity, timeout, server, validation }

class ApiFailure implements Exception {
  final ApiFailureFamily family;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final Map<String, dynamic>? payload;

  const ApiFailure({
    required this.family,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.payload,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

class ApiFailureMapper {
  ApiFailureMapper._();

  static ApiFailure fromDio(DioException error) {
    final status = error.response?.statusCode;
    final payload = _payload(error.response?.data);
    final fields = _fieldErrors(payload);

    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    }.contains(error.type)) {
      return ApiFailure(
        family: ApiFailureFamily.timeout,
        message: 'La solicitud tardó demasiado. Inténtalo nuevamente.',
        statusCode: status,
        payload: payload,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException ||
        (error.type == DioExceptionType.unknown && status == null)) {
      return const ApiFailure(
        family: ApiFailureFamily.connectivity,
        message: 'Sin conexión. Revisa tu red y vuelve a intentarlo.',
      );
    }

    if (status != null && status >= 500) {
      return ApiFailure(
        family: ApiFailureFamily.server,
        message:
            'El servidor no pudo completar la solicitud. Inténtalo más tarde.',
        statusCode: status,
        payload: payload,
      );
    }

    return ApiFailure(
      family: ApiFailureFamily.validation,
      message: _messageForStatus(status, payload, fields),
      statusCode: status,
      fieldErrors: fields,
      payload: payload,
    );
  }

  static String _messageForStatus(
    int? status,
    Map<String, dynamic>? payload,
    Map<String, String> fields,
  ) {
    if (status == 401) {
      return 'La sesión expiró o las credenciales no son válidas.';
    }
    if (status == 403) {
      return 'Tu sesión es válida, pero no tienes permiso para esta acción.';
    }
    if (status == 409) {
      return _detail(payload) ?? 'El registro cambió en el servidor.';
    }
    if (status == 422) {
      return fields.isEmpty
          ? 'Revisa los datos enviados.'
          : 'Revisa los campos indicados: ${fields.keys.join(', ')}.';
    }
    return _detail(payload) ?? 'No fue posible completar la solicitud.';
  }

  static Map<String, dynamic>? _payload(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static String? _detail(Map<String, dynamic>? payload) {
    final detail = payload?['detail'];
    if (detail is String) return detail;
    if (detail is Map) return detail['message']?.toString();
    return null;
  }

  static Map<String, String> _fieldErrors(Map<String, dynamic>? payload) {
    final detail = payload?['detail'];
    if (detail is! List) return const {};
    final result = <String, String>{};
    for (final item in detail) {
      if (item is! Map) continue;
      final location = item['loc'];
      final field = location is List && location.isNotEmpty
          ? location.last.toString()
          : 'datos';
      result[field] = _domainFieldMessage(
        item['msg']?.toString() ?? 'Valor inválido',
      );
    }
    return result;
  }

  static String _domainFieldMessage(String message) {
    final minimumLength = RegExp(r'at least (\d+) characters').firstMatch(message);
    if (minimumLength != null) {
      return 'Debe tener al menos ${minimumLength.group(1)} caracteres.';
    }
    final minimumValue =
        RegExp(r'greater than or equal to (-?\d+)').firstMatch(message);
    if (minimumValue != null) {
      return 'Debe ser mayor o igual a ${minimumValue.group(1)}.';
    }
    if (message.toLowerCase().contains('field required')) {
      return 'Este campo es obligatorio.';
    }
    return message;
  }
}
