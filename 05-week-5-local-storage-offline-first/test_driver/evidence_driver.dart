import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

const package = 'com.example.offline_notes';
final adb =
    Platform.environment['ADB_PATH'] ??
    '${Platform.environment['LOCALAPPDATA']}/Android/Sdk/platform-tools/adb.exe';

Future<ProcessResult> command(List<String> args, {bool binary = false}) =>
    Process.run(adb, [
      '-s',
      'emulator-5554',
      ...args,
    ], stdoutEncoding: binary ? null : utf8);

Future<void> airplane(bool enabled) async {
  await command([
    'shell',
    'cmd',
    'connectivity',
    'airplane-mode',
    enabled ? 'enable' : 'disable',
  ]);
  await command(['shell', 'svc', 'wifi', enabled ? 'disable' : 'enable']);
  await Future<void>.delayed(const Duration(seconds: 3));
  final state = await command([
    'shell',
    'settings',
    'get',
    'global',
    'airplane_mode_on',
  ]);
  if (state.stdout.toString().trim() != (enabled ? '1' : '0')) {
    throw StateError('Airplane setting failed');
  }
}

Future<void> watchRequests() async {
  String? previous;
  while (true) {
    final result = await command([
      'shell',
      'run-as',
      package,
      'cat',
      'code_cache/evidence-request',
    ]);
    final request = result.stdout.toString().trim();
    if (result.exitCode == 0 && request.isNotEmpty && request != previous) {
      stdout.writeln('Evidence request: $request');
      if (request == 'offline' || request == 'online') {
        await airplane(request == 'offline');
      } else if (request.startsWith('capture:')) {
        final name = request.substring(8);
        final shot = await command([
          'exec-out',
          'screencap',
          '-p',
        ], binary: true);
        if (shot.exitCode != 0) throw StateError('Screenshot failed');
        await Directory('screenshots').create(recursive: true);
        await File(
          'screenshots/$name.png',
        ).writeAsBytes(shot.stdout as List<int>);
        final state = await command([
          'shell',
          'settings',
          'get',
          'global',
          'airplane_mode_on',
        ]);
        await File(
          'screenshots/$name.txt',
        ).writeAsString('airplane_mode_on=${state.stdout.toString().trim()}\n');
      }
      await Directory('build').create(recursive: true);
      await File('build/evidence-ack').writeAsString(request);
      await command([
        'push',
        'build/evidence-ack',
        '/data/local/tmp/evidence-ack',
      ]);
      final ackResult = await command([
        'shell',
        'run-as',
        package,
        'cp',
        '/data/local/tmp/evidence-ack',
        'code_cache/evidence-ack',
      ]);
      if (ackResult.exitCode != 0) {
        throw StateError('ACK write failed: ${ackResult.stderr}');
      }
      previous = request;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

Future<void> main() async {
  unawaited(watchRequests());
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      await airplane(false);
      await writeResponseData(data);
    },
  );
}
