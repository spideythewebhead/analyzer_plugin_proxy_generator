import 'dart:io';

import 'package:analyzer_plugin_proxy_generator/src/exceptions.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Generates the analyzer_plugin_proxy project
///
/// If [override] is true it deletes the analyzer_plugin_proxy folder
Future<void> generateProject({
  bool override = false,
}) async {
  const LocalFileSystem fs = LocalFileSystem();
  final Directory projectDirectory = fs.currentDirectory;

  if (!projectDirectory.childFile('pubspec.yaml').existsSync()) {
    throw const PubspecYamlNotFoundException();
  }

  final Directory analyzerPluginProxyDirectory = projectDirectory
      .childDirectory('packages')
      .childDirectory('analyzer_plugin_proxy');

  if (override) {
    try {
      analyzerPluginProxyDirectory.deleteSync(recursive: true);
    } catch (_) {}
  } else if (analyzerPluginProxyDirectory.existsSync()) {
    throw Exception();
  }

  print('''

Creating analyzer plugin proxy project at "packages/analyzer_plugin_proxy"
''');

  analyzerPluginProxyDirectory.createSync(recursive: true);

  analyzerPluginProxyDirectory.childFile('pubspec.yaml').writeAsStringSync('''
name: analyzer_plugin_proxy
description: Analyzer plugin proxy.
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  analyzer: ">=4.0.0 <6.0.0"
  analyzer_plugin: ">=0.10.0 <1.0.0"

  # TODO: Add your analyzer plugin dependencies

dev_dependencies:
  lints: ^2.0.0
  test: ^1.21.0
''');

  analyzerPluginProxyDirectory
      .childFile('analysis_options.yaml')
      .writeAsStringSync('''
include: package:lints/recommended.yaml
''');

  analyzerPluginProxyDirectory.childDirectory('lib')
    ..createSync(recursive: true)
    ..childFile('analyzer_plugin_proxy.dart').writeAsStringSync('''
export 'src/analyzer_plugin_proxy_starter.dart';
''');

  analyzerPluginProxyDirectory.childDirectory('lib').childDirectory('src')
    ..createSync(recursive: true)
    ..childFile('analyzer_plugin.dart').writeAsStringSync('''
import 'package:analyzer/dart/analysis/analysis_context.dart' as analyzer;
import 'package:analyzer/file_system/file_system.dart' as analyzer;
import 'package:analyzer_plugin/plugin/assist_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';

typedef AssistContributorsBuilderCallback = List<AssistContributor> Function(String path);

class AnalyzerPluginProxy extends ServerPlugin with AssistsMixin, DartAssistsMixin {
  AnalyzerPluginProxy(
    final analyzer.ResourceProvider resourceProvider, {
    required final AssistContributorsBuilderCallback assistContributorsBuilder,
  })  : _assistContributorsBuilder = assistContributorsBuilder,
        super(resourceProvider: resourceProvider);

  final AssistContributorsBuilderCallback _assistContributorsBuilder;

  @override
  List<String> get fileGlobsToAnalyze => const <String>['*.dart'];

  @override
  String get name => 'analyzer_plugin_proxy';
  String get displayName => '\$name v\$version';

  @override
  String get contactInfo => '';

  @override
  String get version => '1.0.0';

  @override
  Future<void> analyzeFile({
    required analyzer.AnalysisContext analysisContext,
    required String path,
  }) async {}

  @override
  List<AssistContributor> getAssistContributors(String path) => _assistContributorsBuilder(path);
}
''');

  analyzerPluginProxyDirectory.childDirectory('lib').childDirectory('src')
    ..createSync(recursive: true)
    ..childFile('analyzer_plugin_proxy_starter.dart').writeAsStringSync('''
// ignore_for_file: implementation_imports

import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:analyzer_plugin_proxy/src/analyzer_plugin.dart';

// TODO: IMPORT ASSIST CONTRIBUTORS

void start(Iterable<String> args, SendPort sendPort) {
  ServerPluginStarter(AnalyzerPluginProxy(
    PhysicalResourceProvider.INSTANCE,
    assistContributorsBuilder: (String path) {
      // TODO: ADD ASSIST CONTRIBUTORS
      return [];
    },
  )).start(sendPort);
}
''');

  analyzerPluginProxyDirectory
      .childDirectory('tools')
      .childDirectory('analyzer_plugin')
      .childDirectory('bin')
    ..createSync(recursive: true)
    ..childFile('plugin.dart').writeAsStringSync('''
import 'dart:isolate';

import 'package:analyzer_plugin_proxy/analyzer_plugin_proxy.dart';

void main(List<String> args, SendPort sendPort) {
  start(args, sendPort);
}
''');

  analyzerPluginProxyDirectory
      .childDirectory('tools')
      .childDirectory('analyzer_plugin')
    ..createSync(recursive: true)
    ..childFile('pubspec.yaml').writeAsStringSync('''
name: analyzer_plugin_proxy_loader
version: 0.0.1
publish_to: "none"

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  analyzer_plugin_proxy:
    path: ${analyzerPluginProxyDirectory.absolute.path}
''');

  print('''
Running "dart pub get"
''');

  Process.runSync(
    'dart',
    <String>['pub', 'get'],
    runInShell: false,
    workingDirectory: analyzerPluginProxyDirectory.path,
  );

  final YamlEditor pubspecEditor =
      YamlEditor(projectDirectory.childFile('pubspec.yaml').readAsStringSync());

  final Map<dynamic, dynamic> dependencies = <dynamic, dynamic>{
    ...pubspecEditor.parseAt(<String>['dependencies']) as YamlMap
  };
  dependencies.remove('analyzer_plugin_proxy');
  pubspecEditor.update(<String>['dependencies'], dependencies);

  final Map<dynamic, dynamic> devDependencies = <dynamic, dynamic>{
    ...pubspecEditor.parseAt(<String>['dev_dependencies']) as YamlMap,
    'analyzer_plugin_proxy': <String, String>{
      'path': 'packages/analyzer_plugin_proxy',
    }
  };
  pubspecEditor.update(<String>['dev_dependencies'], devDependencies);

  projectDirectory
      .childFile('pubspec.yaml')
      .writeAsStringSync(pubspecEditor.toString());

  Process.runSync(
    'dart',
    <String>['pub', 'get'],
    runInShell: false,
    workingDirectory: projectDirectory.path,
  );

  print('''
Next steps:

1. Update packages/analyzer_plugin_proxy/pubspec.yaml with your analyzer plugins

2. Update packages/analyzer_plugin_proxy/lib/src/analyzer_plugin_proxy_starter.dart

  1. Import contributors
  2. Add contributors at "assistContributorsBuilder" callback

3. Register the plugin in analysis_options.yaml

  analyzer:
    plugins:
      - analyzer_plugin_proxy
''');
}
