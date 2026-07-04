# hanzoai

[![pub](https://img.shields.io/pub/v/hanzoai.svg)](https://pub.dev/packages/hanzoai)

The Dart client for the [Hanzo Cloud](https://hanzo.ai) `/v1/` platform API at
`api.hanzo.ai`. Auth is [Hanzo IAM](https://hanzo.id)-native: the client holds
the IAM-issued Bearer JWT (or an API key) and sends it on every request.

First-class services for **agents**, **agent sessions**, and **machines**, plus
a raw `send()` escape hatch that reaches the full `/v1/cloud/*` surface. Mirrors
the [`@hanzo/cloud`](https://github.com/hanzo-js/cloud) JavaScript client.

## Where it sits

Orthogonal, IAM-native clients — `hanzoai` is the platform control plane (create
an agent, run it, watch its sessions, provision its machine). It does not do
inference itself; pair it with the Hanzo AI inference surface for completions.

## Install

```yaml
dependencies:
  hanzoai: ^0.1.0
```

```dart
import 'package:hanzoai/hanzoai.dart';

final cloud = HanzoCloud(token: 'IAM_JWT'); // origin defaults to api.hanzo.ai
```

## Agents

```dart
final agent = await cloud.agents.create(
  name: 'researcher',
  model: 'zen-coder',
  instructions: 'You research and summarize.',
  tools: ['search', 'fetch'],
);

final run = await cloud.agents.run('researcher', input: 'Summarize RFC 8628.');
print('${run.status}: ${run.output}');

final agents = await cloud.agents.list();
final detail = await cloud.agents.get('researcher');
final history = await cloud.agents.runs('researcher', limit: 20);
```

A long-running agent carries a 5-field cron and is invoked by the scheduler:

```dart
await cloud.agents.create(
  name: 'nightly-digest',
  model: 'zen-coder',
  executionMode: 'long-running',
  schedule: '0 9 * * *',
);
```

## Agent sessions

```dart
final session = await cloud.sessions.register(agent: 'researcher');
await cloud.sessions.appendEvent(session.id, kind: 'log', payload: {'msg': 'started'});
await cloud.sessions.pause(session.id);
await cloud.sessions.resume(session.id);
await cloud.sessions.message(session.id, message: 'focus on section 3');

final tree = await cloud.sessions.tree(session.id);
```

## Machines

```dart
final machines = await cloud.machines.list(pageSize: 50);
final one = await cloud.machines.get('org/name');
await cloud.machines.add(Machine(name: 'gpu-1', region: 'sfo3'));
```

## The full surface

Every other `/v1/cloud/*` resource (nodes, pods, containers, providers,
connections, stores, vectors, workflows, …) is reachable through `send()`:

```dart
final providers = await cloud.send('/v1/cloud/get-providers');
```

## Auth

```dart
cloud.setToken(jwt);       // seed or replace the Bearer token
cloud.authStore.isValid;   // token present and, if a JWT, unexpired
cloud.signOut();           // clear it
```

Errors are thrown as `HanzoException` with `statusCode` and `message`.

## Develop

```sh
dart pub get
dart analyze --fatal-infos
dart test
```

## License

MIT © Hanzo AI, Inc. See [LICENSE](LICENSE).
