import 'dart:convert';

import 'package:hanzoai/hanzoai.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Builds an unsigned JWT with the given payload (for local exp checks).
String jwt(Map<String, dynamic> payload) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'none'})}.${seg(payload)}.sig';
}

HanzoCloud clientWith(
  Future<http.Response> Function(http.Request request) handler, {
  String? token,
  AuthStore? authStore,
}) {
  return HanzoCloud(
    token: token,
    authStore: authStore,
    httpClientFactory: () => MockClient((r) => handler(r)),
  );
}

void main() {
  group('jwt / token validity', () {
    test('decodes payload', () {
      expect(getTokenPayload(jwt({'id': 'u1', 'exp': 9999999999}))['id'], 'u1');
    });

    test('opaque api key is valid, empty is not', () {
      expect(isTokenValid(''), isFalse);
      expect(isTokenValid('opaque-api-key'), isTrue);
    });

    test('jwt exp respected', () {
      expect(isTokenValid(jwt({'exp': 9999999999})), isTrue);
      expect(isTokenValid(jwt({'exp': 1})), isFalse);
    });
  });

  group('MemoryAuthStore', () {
    test('isValid tracks token', () {
      final store = MemoryAuthStore();
      expect(store.isValid, isFalse);
      store.save(jwt({'exp': 9999999999}));
      expect(store.isValid, isTrue);
      store.save(jwt({'exp': 1}));
      expect(store.isValid, isFalse);
    });

    test('onChange fires and unsubscribes', () {
      final store = MemoryAuthStore();
      final seen = <String>[];
      final off = store.onChange(seen.add);
      store.save('a');
      off();
      store.save('b');
      expect(seen, ['a']);
    });
  });

  group('construction', () {
    test('defaults to api.hanzo.ai and strips trailing slash', () {
      final c = clientWith((_) async => http.Response('{}', 200));
      expect(c.baseUrl, 'https://api.hanzo.ai');
      final c2 = HanzoCloud(baseUrl: 'https://example.test/');
      expect(c2.baseUrl, 'https://example.test');
    });

    test('token seeds the auth store', () {
      final c = clientWith((_) async => http.Response('{}', 200), token: 'tok');
      expect(c.authStore.token, 'tok');
    });
  });

  group('bearer auth', () {
    test('adds Authorization: Bearer <token>', () async {
      String? seenAuth;
      final c = clientWith((r) async {
        seenAuth = r.headers['Authorization'];
        return http.Response('{}', 200);
      }, token: jwt({'exp': 9999999999}));
      await c.health();
      expect(seenAuth, startsWith('Bearer '));
      expect(seenAuth, 'Bearer ${c.authStore.token}');
    });

    test('no header after signOut', () async {
      String? seenAuth;
      final c = clientWith((r) async {
        seenAuth = r.headers['Authorization'];
        return http.Response('{}', 200);
      }, token: 'tok');
      c.signOut();
      await c.health();
      expect(seenAuth, isNull);
    });
  });

  group('agents', () {
    test('list unwraps { agents }', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents');
        return http.Response(
            jsonEncode({
              'agents': [
                {
                  'id': 'agent_1',
                  'name': 'a',
                  'tools': ['search']
                }
              ]
            }),
            200);
      });
      final agents = await c.agents.list();
      expect(agents.single.id, 'agent_1');
      expect(agents.single.tools, ['search']);
    });

    test('create posts cleaned body', () async {
      final c = clientWith((r) async {
        expect(r.method, 'POST');
        final body = jsonDecode(r.body) as Map;
        expect(body['model'], 'zen-coder');
        expect(body.containsKey('description'), isFalse); // null stripped
        return http.Response(jsonEncode({'id': 'agent_2', 'name': 'w'}), 201);
      });
      final agent = await c.agents.create(name: 'w', model: 'zen-coder');
      expect(agent.id, 'agent_2');
    });

    test('get encodes ref and parses detail', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents/has%20space');
        return http.Response(
            jsonEncode({'id': 'agent_2', 'instructions': 'hi'}), 200);
      });
      final detail = await c.agents.get('has space');
      expect(detail.instructions, 'hi');
    });

    test('run returns a Run', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents/w/run');
        expect(jsonDecode(r.body)['input'], 'go');
        return http.Response(
            jsonEncode({'id': 'run_1', 'status': 'ok', 'output': 'done'}), 200);
      });
      final run = await c.agents.run('w', input: 'go');
      expect(run.status, 'ok');
      expect(run.output, 'done');
    });

    test('runs applies limit and unwraps', () async {
      final c = clientWith((r) async {
        expect(r.url.queryParameters['limit'], '5');
        return http.Response(
            jsonEncode({
              'runs': [
                {'id': 'run_1'},
                {'id': 'run_2'}
              ]
            }),
            200);
      });
      final runs = await c.agents.runs('w', limit: 5);
      expect(runs.length, 2);
    });

    test('delete sends DELETE', () async {
      var called = false;
      final c = clientWith((r) async {
        called = r.method == 'DELETE';
        return http.Response('', 204);
      });
      await c.agents.delete('w');
      expect(called, isTrue);
    });
  });

  group('sessions', () {
    test('register posts agent', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents/sessions');
        expect(jsonDecode(r.body)['agent'], 'w');
        return http.Response(
            jsonEncode({'id': 'sess_1', 'status': 'running'}), 201);
      });
      final s = await c.sessions.register(agent: 'w');
      expect(s.id, 'sess_1');
    });

    test('list applies filters', () async {
      late Uri seen;
      final c = clientWith((r) async {
        seen = r.url;
        return http.Response(jsonEncode({'sessions': <Object>[]}), 200);
      });
      await c.sessions.list(status: 'running', root: 'sess_1', limit: 50);
      expect(seen.queryParameters['status'], 'running');
      expect(seen.queryParameters['root'], 'sess_1');
      expect(seen.queryParameters['limit'], '50');
    });

    test('pause hits control path and parses result', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents/sessions/sess_1/pause');
        return http.Response(
            jsonEncode({'command': 'pause', 'forwarded': true}), 200);
      });
      final res = await c.sessions.pause('sess_1');
      expect(res.command, 'pause');
      expect(res.forwarded, isTrue);
    });

    test('tree parses recursive nodes', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/agents/sessions/sess_1/tree');
        return http.Response(
            jsonEncode({
              'session': {'id': 'sess_1'},
              'children': [
                {
                  'session': {'id': 'sess_2'},
                  'children': <Object>[]
                }
              ]
            }),
            200);
      });
      final tree = await c.sessions.tree('sess_1');
      expect(tree.session.id, 'sess_1');
      expect(tree.children.single.session.id, 'sess_2');
    });
  });

  group('machines', () {
    test('list sends pageSize + p and parses list', () async {
      late Uri seen;
      final c = clientWith((r) async {
        seen = r.url;
        return http.Response(
            jsonEncode([
              {'id': 'org/m1', 'name': 'm1'}
            ]),
            200);
      });
      final machines = await c.machines.list(pageSize: 20, page: 2);
      expect(seen.queryParameters['pageSize'], '20');
      expect(seen.queryParameters['p'], '2');
      expect(machines.single.name, 'm1');
    });

    test('add returns CloudResponse envelope', () async {
      final c = clientWith((r) async {
        expect(r.url.path, '/v1/cloud/add-machine');
        expect(jsonDecode(r.body)['name'], 'm2');
        return http.Response(jsonEncode({'status': 'ok', 'msg': ''}), 200);
      });
      final res = await c.machines.add(Machine(name: 'm2', region: 'sfo3'));
      expect(res.ok, isTrue);
    });
  });

  group('errors', () {
    test('non-2xx throws HanzoException with status + message', () async {
      final c = clientWith((r) async =>
          http.Response(jsonEncode({'message': 'Insufficient credit'}), 402));
      expect(
        () => c.agents.run('w'),
        throwsA(isA<HanzoException>()
            .having((e) => e.statusCode, 'statusCode', 402)
            .having((e) => e.message, 'message', 'Insufficient credit')),
      );
    });
  });
}
