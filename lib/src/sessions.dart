import 'client.dart';
import 'models.dart';

/// The `/v1/agents/sessions` surface.
///
/// A session is one live agent invocation. Sessions linked by `parentSessionId`
/// form the subagent tree; `rootSessionId` is the shared key.
class SessionsService {
  SessionsService(this._client);

  final HanzoCloud _client;

  /// Register a live session. Omit [parentSessionId] for a root.
  Future<Session> register({
    required String agent,
    String? actor,
    String? title,
    String? status,
    String? parentSessionId,
    String? taskWorkflowId,
    String? taskRunId,
  }) async {
    final res =
        await _client.send('/v1/agents/sessions', method: 'POST', body: {
      'agent': agent,
      if (actor != null) 'actor': actor,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (parentSessionId != null) 'parentSessionId': parentSessionId,
      if (taskWorkflowId != null) 'taskWorkflowId': taskWorkflowId,
      if (taskRunId != null) 'taskRunId': taskRunId,
    });
    return Session.fromJson((res as Map).cast<String, dynamic>());
  }

  /// List the org's live sessions, newest first.
  Future<List<Session>> list({
    String? root,
    String? parent,
    String? status,
    int? limit,
  }) async {
    final res = await _client.send('/v1/agents/sessions', query: {
      if (root != null) 'root': root,
      if (parent != null) 'parent': parent,
      if (status != null) 'status': status,
      if (limit != null) 'limit': limit,
    });
    final sessions = (res is Map ? res['sessions'] : null) as List? ?? const [];
    return sessions
        .map((e) => Session.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Session detail — the session, its direct children, and recent events.
  Future<SessionDetail> get(String id) async {
    final res =
        await _client.send('/v1/agents/sessions/${Uri.encodeComponent(id)}');
    return SessionDetail.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Update a session's status and/or title (terminal sessions are monotonic).
  Future<Session> patch(String id, {String? status, String? title}) async {
    final res = await _client.send(
      '/v1/agents/sessions/${Uri.encodeComponent(id)}',
      method: 'PATCH',
      body: {
        if (status != null) 'status': status,
        if (title != null) 'title': title,
      },
    );
    return Session.fromJson((res as Map).cast<String, dynamic>());
  }

  /// The full subagent-flow graph rooted at this session's tree.
  Future<TreeNode> tree(String id) async {
    final res = await _client
        .send('/v1/agents/sessions/${Uri.encodeComponent(id)}/tree');
    return TreeNode.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Append one event to a session's ordered log.
  Future<SessionEvent> appendEvent(
    String id, {
    required String kind,
    String? actor,
    Map<String, dynamic>? payload,
  }) async {
    final res = await _client.send(
      '/v1/agents/sessions/${Uri.encodeComponent(id)}/events',
      method: 'POST',
      body: {
        'kind': kind,
        if (actor != null) 'actor': actor,
        if (payload != null) 'payload': payload,
      },
    );
    return SessionEvent.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Pause a live session.
  Future<ControlResult> pause(String id,
          {String? message, Map<String, dynamic>? payload}) =>
      _control(id, 'pause', message, payload);

  /// Resume a paused session.
  Future<ControlResult> resume(String id,
          {String? message, Map<String, dynamic>? payload}) =>
      _control(id, 'resume', message, payload);

  /// Stop a session.
  Future<ControlResult> stop(String id,
          {String? message, Map<String, dynamic>? payload}) =>
      _control(id, 'stop', message, payload);

  /// Send a steering message to a live session (requires [message] or [payload]).
  Future<ControlResult> message(String id,
          {String? message, Map<String, dynamic>? payload}) =>
      _control(id, 'message', message, payload);

  Future<ControlResult> _control(
    String id,
    String command,
    String? message,
    Map<String, dynamic>? payload,
  ) async {
    final res = await _client.send(
      '/v1/agents/sessions/${Uri.encodeComponent(id)}/$command',
      method: 'POST',
      body: (message == null && payload == null)
          ? null
          : {
              if (message != null) 'message': message,
              if (payload != null) 'payload': payload,
            },
    );
    return ControlResult.fromJson((res as Map).cast<String, dynamic>());
  }
}
