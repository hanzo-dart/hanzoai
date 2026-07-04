/// Typed domain models for the Hanzo Cloud API.
///
/// Each class mirrors a schema in the OpenAPI spec (`agents.*`,
/// `object.Machine`, `controllers.Response`). Fields absent from a response
/// take their zero value; `fromJson` never throws on a well-formed map.
library;

String _s(dynamic v) => v?.toString() ?? '';
int _i(dynamic v) => v is int
    ? v
    : v is num
        ? v.toInt()
        : v is String
            ? int.tryParse(v) ?? 0
            : 0;
bool _b(dynamic v) => v == true;
List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];
Map<String, dynamic> _map(dynamic v) =>
    v is Map ? v.map((k, value) => MapEntry(k.toString(), value)) : const {};

/// A per-org autonomous agent — a model, instructions, and tool names.
class Agent {
  Agent({
    this.id = '',
    this.name = '',
    this.model = '',
    this.description = '',
    this.tools = const [],
    this.status = '',
    this.executionMode = '',
    this.schedule = '',
    this.computeRef = '',
    this.serviceAccountId = '',
    this.runs = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: _s(json['id']),
        name: _s(json['name']),
        model: _s(json['model']),
        description: _s(json['description']),
        tools: _strList(json['tools']),
        status: _s(json['status']),
        executionMode: _s(json['executionMode']),
        schedule: _s(json['schedule']),
        computeRef: _s(json['computeRef']),
        serviceAccountId: _s(json['serviceAccountId']),
        runs: _i(json['runs']),
        createdAt: _s(json['createdAt']),
        updatedAt: _s(json['updatedAt']),
      );

  final String id;
  final String name;
  final String model;
  final String description;
  final List<String> tools;
  final String status;

  /// `one-shot` or `long-running`.
  final String executionMode;

  /// 5-field cron; set only when [executionMode] is `long-running`.
  final String schedule;
  final String computeRef;
  final String serviceAccountId;
  final int runs;
  final String createdAt;
  final String updatedAt;
}

/// An [Agent] plus its instructions and recent runs.
class AgentDetail extends Agent {
  AgentDetail({
    super.id,
    super.name,
    super.model,
    super.description,
    super.tools,
    super.status,
    super.executionMode,
    super.schedule,
    super.computeRef,
    super.serviceAccountId,
    super.runs,
    super.createdAt,
    super.updatedAt,
    this.instructions = '',
    this.recentRuns = const [],
  });

  factory AgentDetail.fromJson(Map<String, dynamic> json) {
    final base = Agent.fromJson(json);
    return AgentDetail(
      id: base.id,
      name: base.name,
      model: base.model,
      description: base.description,
      tools: base.tools,
      status: base.status,
      executionMode: base.executionMode,
      schedule: base.schedule,
      computeRef: base.computeRef,
      serviceAccountId: base.serviceAccountId,
      runs: base.runs,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      instructions: _s(json['instructions']),
      recentRuns: (json['recentRuns'] as List? ?? const [])
          .map((e) => Run.fromJson(_map(e)))
          .toList(),
    );
  }

  final String instructions;
  final List<Run> recentRuns;
}

/// One execution of an agent.
class Run {
  Run({
    this.id = '',
    this.status = '',
    this.model = '',
    this.input = '',
    this.output = '',
    this.error = '',
    this.durationMs = 0,
    this.createdAt = '',
  });

  factory Run.fromJson(Map<String, dynamic> json) => Run(
        id: _s(json['id']),
        status: _s(json['status']),
        model: _s(json['model']),
        input: _s(json['input']),
        output: _s(json['output']),
        error: _s(json['error']),
        durationMs: _i(json['durationMs']),
        createdAt: _s(json['createdAt']),
      );

  final String id;

  /// `ok` or `error`.
  final String status;
  final String model;
  final String input;
  final String output;
  final String error;
  final int durationMs;
  final String createdAt;
}

/// One entry in the org-wide agent activity feed.
class Activity {
  Activity({
    this.id = '',
    this.kind = '',
    this.agent = '',
    this.message = '',
    this.at = '',
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: _s(json['id']),
        kind: _s(json['kind']),
        agent: _s(json['agent']),
        message: _s(json['message']),
        at: _s(json['at']),
      );

  final String id;

  /// `invoked`, `failed`, `created`, or `updated`.
  final String kind;
  final String agent;
  final String message;
  final String at;
}

/// A live agent-session — a node of the subagent tree.
class Session {
  Session({
    this.id = '',
    this.agent = '',
    this.actor = '',
    this.status = '',
    this.parentSessionId = '',
    this.rootSessionId = '',
    this.title = '',
    this.taskWorkflowId = '',
    this.taskRunId = '',
    this.events = 0,
    this.children = 0,
    this.startedAt = '',
    this.endedAt = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: _s(json['id']),
        agent: _s(json['agent']),
        actor: _s(json['actor']),
        status: _s(json['status']),
        parentSessionId: _s(json['parentSessionId']),
        rootSessionId: _s(json['rootSessionId']),
        title: _s(json['title']),
        taskWorkflowId: _s(json['taskWorkflowId']),
        taskRunId: _s(json['taskRunId']),
        events: _i(json['events']),
        children: _i(json['children']),
        startedAt: _s(json['startedAt']),
        endedAt: _s(json['endedAt']),
        createdAt: _s(json['createdAt']),
        updatedAt: _s(json['updatedAt']),
      );

  final String id;
  final String agent;
  final String actor;

  /// `running`, `paused`, `done`, or `error`.
  final String status;

  /// Empty for a root (the outer agent).
  final String parentSessionId;

  /// The tree key; equals [id] for a root.
  final String rootSessionId;
  final String title;
  final String taskWorkflowId;
  final String taskRunId;
  final int events;
  final int children;
  final String startedAt;
  final String endedAt;
  final String createdAt;
  final String updatedAt;
}

/// A [Session] plus its direct children and recent events.
class SessionDetail extends Session {
  SessionDetail({
    super.id,
    super.agent,
    super.actor,
    super.status,
    super.parentSessionId,
    super.rootSessionId,
    super.title,
    super.taskWorkflowId,
    super.taskRunId,
    super.events,
    super.children,
    super.startedAt,
    super.endedAt,
    super.createdAt,
    super.updatedAt,
    this.childSessions = const [],
    this.recentEvents = const [],
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    final base = Session.fromJson(json);
    return SessionDetail(
      id: base.id,
      agent: base.agent,
      actor: base.actor,
      status: base.status,
      parentSessionId: base.parentSessionId,
      rootSessionId: base.rootSessionId,
      title: base.title,
      taskWorkflowId: base.taskWorkflowId,
      taskRunId: base.taskRunId,
      events: base.events,
      children: base.children,
      startedAt: base.startedAt,
      endedAt: base.endedAt,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      childSessions: (json['childSessions'] as List? ?? const [])
          .map((e) => Session.fromJson(_map(e)))
          .toList(),
      recentEvents: (json['recentEvents'] as List? ?? const [])
          .map((e) => SessionEvent.fromJson(_map(e)))
          .toList(),
    );
  }

  final List<Session> childSessions;
  final List<SessionEvent> recentEvents;
}

/// One entry in a session's ordered event log.
class SessionEvent {
  SessionEvent({
    this.id = '',
    this.sessionId = '',
    this.seq = 0,
    this.kind = '',
    this.actor = '',
    this.payload = const {},
    this.createdAt = '',
  });

  factory SessionEvent.fromJson(Map<String, dynamic> json) => SessionEvent(
        id: _s(json['id']),
        sessionId: _s(json['sessionId']),
        seq: _i(json['seq']),
        kind: _s(json['kind']),
        actor: _s(json['actor']),
        payload: _map(json['payload']),
        createdAt: _s(json['createdAt']),
      );

  final String id;
  final String sessionId;

  /// Monotonic per session.
  final int seq;

  /// `message`, `tool-call`, `spawn`, `log`, `status`, or `control`.
  final String kind;
  final String actor;
  final Map<String, dynamic> payload;
  final String createdAt;
}

/// One node of the recursive subagent-flow graph.
class TreeNode {
  TreeNode({Session? session, this.children = const []})
      : session = session ?? Session();

  factory TreeNode.fromJson(Map<String, dynamic> json) => TreeNode(
        session: Session.fromJson(_map(json['session'])),
        children: (json['children'] as List? ?? const [])
            .map((e) => TreeNode.fromJson(_map(e)))
            .toList(),
      );

  final Session session;
  final List<TreeNode> children;
}

/// The result of a session control command (pause/resume/stop/message).
class ControlResult {
  ControlResult({this.command = '', this.event, this.forwarded = false});

  factory ControlResult.fromJson(Map<String, dynamic> json) => ControlResult(
        command: _s(json['command']),
        event: json['event'] is Map
            ? SessionEvent.fromJson(_map(json['event']))
            : null,
        forwarded: _b(json['forwarded']),
      );

  /// `pause`, `resume`, `stop`, or `message`.
  final String command;
  final SessionEvent? event;

  /// True when the command reached the hanzoai/tasks engine.
  final bool forwarded;
}

/// A provisioned compute machine.
class Machine {
  Machine({
    this.id = '',
    this.name = '',
    this.owner = '',
    this.displayName = '',
    this.category = '',
    this.type = '',
    this.provider = '',
    this.region = '',
    this.zone = '',
    this.image = '',
    this.os = '',
    this.size = '',
    this.cpuSize = '',
    this.memSize = '',
    this.state = '',
    this.tag = '',
    this.publicIp = '',
    this.privateIp = '',
    this.remoteProtocol = '',
    this.remotePort = 0,
    this.remoteUsername = '',
    this.createdTime = '',
    this.updatedTime = '',
    this.expireTime = '',
  });

  factory Machine.fromJson(Map<String, dynamic> json) => Machine(
        id: _s(json['id']),
        name: _s(json['name']),
        owner: _s(json['owner']),
        displayName: _s(json['displayName']),
        category: _s(json['category']),
        type: _s(json['type']),
        provider: _s(json['provider']),
        region: _s(json['region']),
        zone: _s(json['zone']),
        image: _s(json['image']),
        os: _s(json['os']),
        size: _s(json['size']),
        cpuSize: _s(json['cpuSize']),
        memSize: _s(json['memSize']),
        state: _s(json['state']),
        tag: _s(json['tag']),
        publicIp: _s(json['publicIp']),
        privateIp: _s(json['privateIp']),
        remoteProtocol: _s(json['remoteProtocol']),
        remotePort: _i(json['remotePort']),
        remoteUsername: _s(json['remoteUsername']),
        createdTime: _s(json['createdTime']),
        updatedTime: _s(json['updatedTime']),
        expireTime: _s(json['expireTime']),
      );

  /// Serialize back to the wire shape (non-empty fields only).
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'name': name,
      'owner': owner,
      'displayName': displayName,
      'category': category,
      'type': type,
      'provider': provider,
      'region': region,
      'zone': zone,
      'image': image,
      'os': os,
      'size': size,
      'cpuSize': cpuSize,
      'memSize': memSize,
      'state': state,
      'tag': tag,
      'publicIp': publicIp,
      'privateIp': privateIp,
      'remoteProtocol': remoteProtocol,
      'remotePort': remotePort,
      'remoteUsername': remoteUsername,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'expireTime': expireTime,
    };
    m.removeWhere((k, v) => v == '' || v == 0);
    return m;
  }

  final String id;
  final String name;
  final String owner;
  final String displayName;
  final String category;
  final String type;
  final String provider;
  final String region;
  final String zone;
  final String image;
  final String os;
  final String size;
  final String cpuSize;
  final String memSize;
  final String state;
  final String tag;
  final String publicIp;
  final String privateIp;
  final String remoteProtocol;
  final int remotePort;
  final String remoteUsername;
  final String createdTime;
  final String updatedTime;
  final String expireTime;
}

/// The `{ status, msg, data, data2 }` envelope returned by the legacy
/// `/v1/cloud/*` (Casdoor-style) endpoints.
class CloudResponse {
  CloudResponse({
    this.status = '',
    this.msg = '',
    this.data,
    this.data2,
  });

  factory CloudResponse.fromJson(Map<String, dynamic> json) => CloudResponse(
        status: _s(json['status']),
        msg: _s(json['msg']),
        data: json['data'],
        data2: json['data2'],
      );

  final String status;
  final String msg;
  final dynamic data;
  final dynamic data2;

  /// Whether the server reported success.
  bool get ok => status == 'ok';
}
