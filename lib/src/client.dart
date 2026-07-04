import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'agents.dart';
import 'auth_store.dart';
import 'exception.dart';
import 'machines.dart';
import 'sessions.dart';

/// Default Hanzo Cloud API origin.
const String defaultCloudUrl = 'https://api.hanzo.ai';

/// The typed client for the Hanzo Cloud `/v1/` platform API.
///
/// ```dart
/// final cloud = HanzoCloud(token: 'IAM_JWT');
/// final agent = await cloud.agents.create(name: 'researcher', model: 'zen-coder');
/// final run = await cloud.agents.run('researcher', input: 'Summarize RFC 8628.');
/// ```
///
/// Auth is Hanzo IAM-native: [authStore] holds the IAM-issued Bearer JWT (or an
/// API key), sent as `Authorization: Bearer <token>` on every request.
class HanzoCloud {
  HanzoCloud({
    String baseUrl = defaultCloudUrl,
    String? token,
    AuthStore? authStore,
    this.lang = 'en-US',
    http.Client Function()? httpClientFactory,
  })  : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        authStore = authStore ?? MemoryAuthStore() {
    _httpClient = (httpClientFactory ?? http.Client.new)();
    if (token != null && token.isNotEmpty) {
      this.authStore.save(token);
    }
    agents = AgentsService(this);
    sessions = SessionsService(this);
    machines = MachinesService(this);
  }

  /// The Hanzo Cloud origin (e.g. `https://api.hanzo.ai`).
  final String baseUrl;

  /// Holds the current Hanzo IAM Bearer token.
  final AuthStore authStore;

  /// `Accept-Language` header sent with every request.
  String lang;

  /// The `/v1/agents` surface.
  late final AgentsService agents;

  /// The `/v1/agents/sessions` surface.
  late final SessionsService sessions;

  /// The `/v1/cloud/*-machine(s)` surface.
  late final MachinesService machines;

  late final http.Client _httpClient;

  /// Seed or replace the Bearer token.
  void setToken(String token) => authStore.save(token);

  /// Clear the Bearer token.
  void signOut() => authStore.clear();

  /// Liveness probe (`GET /health`).
  Future<Map<String, dynamic>> health() async {
    final result = await send('/health');
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  /// Sends a request to the Hanzo Cloud API and returns the decoded JSON body.
  ///
  /// Adds `Authorization: Bearer <token>` when a valid session exists. Throws
  /// [HanzoException] on non-2xx responses.
  Future<dynamic> send(
    String path, {
    String method = 'GET',
    Map<String, String> headers = const {},
    Map<String, dynamic> query = const {},
    Object? body,
  }) async {
    final url = _buildUrl(path, query);

    final request = http.Request(method, url);
    if (body != null) {
      request.body = jsonEncode(body);
      request.headers['Content-Type'] = 'application/json';
    }

    request.headers.addAll(headers);
    if (!request.headers.containsKey('Authorization') && authStore.isValid) {
      request.headers['Authorization'] = 'Bearer ${authStore.token}';
    }
    request.headers.putIfAbsent('Accept-Language', () => lang);

    http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request);
    } on http.ClientException catch (e) {
      throw HanzoException(url: url, originalError: e, isAbort: true);
    } catch (e) {
      throw HanzoException(url: url, originalError: e);
    }

    final responseBody = await streamed.stream.bytesToString();
    dynamic data;
    if (responseBody.isNotEmpty) {
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }
    }

    if (streamed.statusCode >= 400) {
      throw HanzoException(
        url: url,
        statusCode: streamed.statusCode,
        response: data is Map<String, dynamic> ? data : const {},
      );
    }

    return data;
  }

  /// Closes the underlying HTTP client.
  void close() => _httpClient.close();

  Uri _buildUrl(String path, Map<String, dynamic> query) {
    final normalizedQuery = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) {
        return;
      }
      normalizedQuery[key] = value is Iterable
          ? value.map((v) => v.toString()).toList()
          : value.toString();
    });

    final uri = Uri.parse('$baseUrl$path');
    if (normalizedQuery.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParametersAll,
      ...normalizedQuery,
    });
  }
}
