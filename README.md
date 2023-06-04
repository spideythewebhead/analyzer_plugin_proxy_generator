# Analyzer plugin proxy generator

A CLI tool to generate a proxy for multiple analyzer plugins.

## Why

As mentioned on this [github issue](https://github.com/flutter/flutter/issues/121836#issuecomment-1494924303) only 1 plugin can be enabled per `analysis_options.yaml` file.

This approach is more like a workaround for this problem until the dart team provides official support for this.

## How to run

1. Install `analyzer_plugin_proxy_generator` as a development dependency.

```yaml
dev_dependencies:
  analyzer_plugin_proxy_generator: any
```

1. Run `dart run analyzer_plugin_proxy_generator [--override]` from the root of the project

   1. `--override` will override the existing packages/analyzer_plugin_proxy.
   1. A new package named `analyzer_plugin_proxy` will be created under `packages` folder.

1. If the command runs successfully it will update your `pubspec.yaml` and you will be prompted with a few more steps to follow.

---

## Notes

As this is mostly created for personally usage I've kept it very simple.
If you want to enhance this tool or improve it, PRs or issues are welcomed.
