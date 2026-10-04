import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class TestHttpResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, List<String>> headers;

  const TestHttpResponse(
    this.statusCode,
    this.data, {
    this.headers = const {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  });
}

class CallbackHttpAdapter implements HttpClientAdapter {
  final Future<TestHttpResponse> Function(RequestOptions request) callback;

  CallbackHttpAdapter(this.callback);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await callback(options);
    final body = response.data is String
        ? response.data as String
        : jsonEncode(response.data);
    return ResponseBody.fromString(
      body,
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio testDio(
  Future<TestHttpResponse> Function(RequestOptions request) callback,
) {
  final dio = Dio();
  dio.httpClientAdapter = CallbackHttpAdapter(callback);
  return dio;
}
