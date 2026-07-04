import 'package:hanzoai/hanzoai.dart';

/// Minimal end-to-end shape: create an agent, run it, watch its sessions.
///
/// Run against a real deployment with a Hanzo IAM token:
///   HANZO_TOKEN=... dart run example/hanzoai_example.dart
Future<void> main() async {
  final cloud = HanzoCloud(token: const String.fromEnvironment('HANZO_TOKEN'));

  final agent = await cloud.agents.create(
    name: 'researcher',
    model: 'zen-coder',
    instructions: 'You research and summarize.',
    tools: ['search', 'fetch'],
  );
  print('created ${agent.name} (${agent.id})');

  final run = await cloud.agents.run(agent.name, input: 'Summarize RFC 8628.');
  print('run ${run.status}: ${run.output}');

  final sessions = await cloud.sessions.list(status: 'running');
  print('${sessions.length} running session(s)');

  cloud.close();
}
