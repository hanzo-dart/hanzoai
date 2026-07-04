import 'client.dart';
import 'models.dart';

/// The `/v1/agents` surface.
///
/// Agents are per-org autonomous units (a model + instructions + tool names).
/// A one-shot agent runs when passed to [run]; a long-running agent additionally
/// carries a 5-field cron `schedule` and is invoked by the scheduler.
class AgentsService {
  AgentsService(this._client);

  final HanzoCloud _client;

  /// List the org's agents, most-recently-updated first.
  Future<List<Agent>> list() async {
    final res = await _client.send('/v1/agents');
    final agents = (res is Map ? res['agents'] : null) as List? ?? const [];
    return agents
        .map((e) => Agent.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Create an agent.
  Future<Agent> create({
    required String name,
    required String model,
    String? instructions,
    String? description,
    List<String>? tools,
    String? executionMode,
    String? schedule,
    String? computeRef,
    String? serviceAccountId,
  }) async {
    final res = await _client.send('/v1/agents',
        method: 'POST',
        body: _clean({
          'name': name,
          'model': model,
          'instructions': instructions,
          'description': description,
          'tools': tools,
          'executionMode': executionMode,
          'schedule': schedule,
          'computeRef': computeRef,
          'serviceAccountId': serviceAccountId,
        }));
    return Agent.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Get an agent by its public id (`agent_...`) or org-unique name.
  Future<AgentDetail> get(String ref) async {
    final res = await _client.send('/v1/agents/${Uri.encodeComponent(ref)}');
    return AgentDetail.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Update an agent's mutable fields (partial).
  Future<Agent> update(
    String ref, {
    String? model,
    String? instructions,
    String? description,
    List<String>? tools,
    String? executionMode,
    String? schedule,
    String? computeRef,
    String? serviceAccountId,
  }) async {
    final res = await _client.send(
      '/v1/agents/${Uri.encodeComponent(ref)}',
      method: 'PATCH',
      body: _clean({
        'model': model,
        'instructions': instructions,
        'description': description,
        'tools': tools,
        'executionMode': executionMode,
        'schedule': schedule,
        'computeRef': computeRef,
        'serviceAccountId': serviceAccountId,
      }),
    );
    return Agent.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Delete an agent and its run history.
  Future<void> delete(String ref) =>
      _client.send('/v1/agents/${Uri.encodeComponent(ref)}', method: 'DELETE');

  /// Run the agent once and return the completed run.
  Future<Run> run(String ref, {String? input}) async {
    final res = await _client.send(
      '/v1/agents/${Uri.encodeComponent(ref)}/run',
      method: 'POST',
      body: input == null ? null : {'input': input},
    );
    return Run.fromJson((res as Map).cast<String, dynamic>());
  }

  /// The agent's run history, newest first.
  Future<List<Run>> runs(String ref, {int? limit}) async {
    final res = await _client.send(
      '/v1/agents/${Uri.encodeComponent(ref)}/runs',
      query: {if (limit != null) 'limit': limit},
    );
    final runs = (res is Map ? res['runs'] : null) as List? ?? const [];
    return runs
        .map((e) => Run.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Invocations-over-time metrics for the org's Agents dashboard.
  ///
  /// [range] is one of `24H`, `7D`, `30D`. Returns the raw metrics map.
  Future<Map<String, dynamic>> metrics({String? range}) async {
    final res = await _client.send(
      '/v1/agents/metrics',
      query: {if (range != null) 'range': range},
    );
    return res is Map ? res.cast<String, dynamic>() : <String, dynamic>{};
  }

  /// The org-wide recent-activity feed, newest first.
  Future<List<Activity>> activity() async {
    final res = await _client.send('/v1/agents/activity');
    final activity = (res is Map ? res['activity'] : null) as List? ?? const [];
    return activity
        .map((e) => Activity.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

Map<String, dynamic> _clean(Map<String, dynamic> m) {
  m.removeWhere((_, v) => v == null);
  return m;
}
