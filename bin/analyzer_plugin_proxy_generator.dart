import 'package:analyzer_plugin_proxy_generator/analyzer_plugin_proxy_generator.dart';
import 'package:analyzer_plugin_proxy_generator/src/exceptions.dart';

void main(List<String> args) async {
  try {
    await generateProject(
      override: args.elementAtOrNull(0) == '--override',
    );
  } on PubspecYamlNotFoundException catch (_) {
    print(
        '"pubspec.yaml" not found in current directory. Ensure you are running this command with in a dart/flutter project.');
  }
}
