import 'client.dart';
import 'models.dart';

/// The `/v1/cloud/*-machine(s)` surface — a worked example of the legacy
/// `/v1/cloud/*` platform CRUD.
///
/// Mutations return the [CloudResponse] envelope; reads return the object
/// directly. Every other `/v1/cloud/*` resource (nodes, pods, containers,
/// providers, connections, …) follows the same shape and is reachable via
/// [HanzoCloud.send].
class MachinesService {
  MachinesService(this._client);

  final HanzoCloud _client;

  /// List machines (paginated).
  Future<List<Machine>> list({int pageSize = 100, int page = 1}) async {
    final res = await _client.send('/v1/cloud/get-machines',
        query: {'pageSize': pageSize, 'p': page});
    if (res is List) {
      return res
          .map((e) => Machine.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    // Casdoor-style envelope: the page rides in `data`.
    final data = res is Map ? res['data'] : null;
    if (data is List) {
      return data
          .map((e) => Machine.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  /// Get one machine by its `owner/name` id.
  Future<Machine> get(String id) async {
    final res = await _client.send('/v1/cloud/get-machine', query: {'id': id});
    return Machine.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Create a machine.
  Future<CloudResponse> add(Machine machine) async {
    final res = await _client.send('/v1/cloud/add-machine',
        method: 'POST', body: machine.toJson());
    return CloudResponse.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Update a machine by its `owner/name` id.
  Future<CloudResponse> update(String id, Machine machine) async {
    final res = await _client.send('/v1/cloud/update-machine',
        method: 'POST', query: {'id': id}, body: machine.toJson());
    return CloudResponse.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Delete a machine.
  Future<CloudResponse> delete(Machine machine) async {
    final res = await _client.send('/v1/cloud/delete-machine',
        method: 'POST', body: machine.toJson());
    return CloudResponse.fromJson((res as Map).cast<String, dynamic>());
  }
}
