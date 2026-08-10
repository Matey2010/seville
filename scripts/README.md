# Make automation

This directory's Makefile owns macOS project automation, graph inspection, and
explicit migration utilities.

Production parsing and reconciliation remain owned by the backend rather than
living only in scripts. Git and Markdown directories are source adapters;
Neo4j is the canonical database. There is no SQL persistence or planned
Neo4j-to-Markdown export path.

Run `make -C scripts` from the repository root to see the available targets.
The stable local backend commands are:

```sh
make -C scripts start
make -C scripts status
make -C scripts stop
```

## Custom SVG fonts

Build the custom Sevifont TTF, OTF, and Dart API from its SVG/JSON sources:

```sh
make -C scripts buildFont
```

Use `make -C scripts checkFont` for read-only SVG and metric validation. The
compiler contract and manifest customization fields are documented in
[`fonts/README.md`](fonts/README.md). FontForge is the local compiler; IcoMoon
is retained only as an optional migration base until every legacy glyph has a
manifest-owned SVG source.

Legacy source migration tools live below `scripts/migrations/` so they cannot
be confused with normal process control. The documented Obsidian/Markdown
importer is described in [`migrations/obsidian/`](migrations/obsidian/) and runs
with `make -C scripts migrate-obsidian`. It is manual and is never invoked by
Seville startup.

`make -C scripts interface` verifies the complete dependency chain before
starting Flutter. For a localhost Neo4j URI it starts the bundled Neo4j
Community container, starts the Go API, waits for `/healthz`, and only then
hands control to the supported macOS client. A remote `SEVILLE_NEO4J_URI` skips
Docker.

## Default launcher icon

Set the shared launcher icon from the repository root with:

```sh
make -C scripts setDefaultIcon path=./frontend/seville7/assets/legal/mascot-ska.png
```

That source is assigned to both macOS build variants. To distinguish the
development application in the Dock, provide two sources instead:

```sh
make -C scripts setDefaultIcon \
  debug_path=./frontend/seville7/assets/legal/mascot-ska-debug.pdf \
  production_path=./frontend/seville7/assets/legal/mascot-ska.png
```

`set-default-icon` is the equivalent kebab-case target, and `ICON_PATH` is an
equivalent variable name:

```sh
make -C scripts set-default-icon ICON_PATH=./frontend/seville7/assets/legal/mascot-ska.png
```

GNU Make does not allow project-defined options such as `--setDefaultIcon` or
`--path:...`; unknown double-dash arguments are parsed as Make's own options.
The target and `name=value` forms above are the Make-native interface.

The launcher-icon ownership and execution hierarchy is:

```text
scripts/Makefile: setDefaultIcon(path=...)
  ├─ Make path configuration
  │    ├─ resolves and validates the source file(s)
  │    └─ persists Flutter-relative Debug and production paths
  │       in macos_launcher_icons.yaml
  └─ Make-owned macOS image generator
       tool/generate_macos_icons.swift (ImageIO + AppKit + CoreGraphics)
         ├─ decodes raster, first-page PDF, or SVG input
         ├─ aspect-fits it into a transparent 1024x1024 master
         ├─ writes AppIcon-Debug.appiconset for Xcode Debug
         └─ writes AppIcon.appiconset for Xcode Profile/Release
```

So “Make → Flutter set icons with the path parameter” is close, but neither
Flutter nor Dart participates in macOS icon generation. Make consumes its own
parameter, writes durable configuration, and invokes the small native image
tool. This avoids Flutter package resolution and native build hooks entirely.
Xcode selects `AppIcon-Debug` only for Debug and `AppIcon` for Profile and
Release. Debug uses the distinct `io.github.matey2010.seville.debug` bundle
identifier, while Profile and Release retain `io.github.matey2010.seville`, so
macOS cannot reuse the production application's cached icon for Debug.
`make -C scripts interface` refreshes either catalog when its source,
configuration, or generator changes. After regenerating a catalog, Make removes
only its affected generated application bundle: Debug removes
`build/macos/Build/Products/Debug/seville.app`, while production removes the
Profile and Release equivalents. Flutter rebuilds that disposable bundle on
the next run, preventing an old compiled `.icns` from surviving an icon-source
change. Unchanged icon inputs leave existing bundles untouched. At launch,
`AppDelegate` reads
`CFBundleIconFile` from the built application and reloads that exact `.icns` as
the running application image. This refreshes macOS's bundle-identifier-based
icon cache without hardcoding or overriding Xcode's build-specific selection.

The source must exist inside `frontend/seville7/`. The tool accepts a repository-
relative path, a Flutter-relative path, or an absolute path and stores one
portable Flutter-relative value. PNG and other ImageIO-supported raster formats
are accepted, as is PDF; only the first PDF page is used. SVG uses macOS's
native AppKit SVG representation, preserving its view box, transforms, masks,
and embedded images when rasterizing the 1024x1024 master. Smaller icons are
always derived from that normalized master. Paths containing spaces must quote
the complete Make assignment, for example:

```sh
make -C scripts setDefaultIcon \
  path=./frontend/seville7/assets/icons/svg/seville8.min.svg
```

Do not edit generated catalog files by hand; change their configured source
through Make instead.

## Application display name

Set one user-facing name for Debug, Profile, and Release from the repository
root with:

```sh
make -C scripts setAppName name='Seville 7'
```

To distinguish the development application, pass both names instead:

```sh
make -C scripts setAppName \
  debug_name='Seville 7 Dev' \
  production_name='Seville 7'
```

`set-app-name` is the equivalent kebab-case target, and `APP_NAME` is an
equivalent shared-name variable. The transaction is:

```text
scripts/Makefile: setAppName(name=...)
  ├─ validates and persists Debug/production names
  │    in macos_app_names.yaml
  ├─ invokes rename_app's mac compatibility command
  └─ generates macos/Runner/Configs/AppName.xcconfig
       ├─ Debug resolves SEVILLE_DEBUG_APP_NAME
       └─ Profile/Release resolve SEVILLE_PRODUCTION_APP_NAME
```

`rename_app` is retained as the standard Flutter renaming dependency and CLI,
but version 1.6.6 does not yet wire its advertised `mac` argument to a macOS
project edit. The Make transaction therefore completes that missing macOS step
explicitly. `CFBundleDisplayName` and `CFBundleName` consume the generated build
setting; the native runner applies it to the application menu and main window.
The stable Xcode product remains `seville.app`, so name changes do not break the
existing scheme, bundle checks, or icon transaction.

`make -C scripts interface` refreshes the generated name configuration before
launch. A changed Debug name removes only the disposable Debug application
bundle; a changed production name removes only Profile and Release bundles.
Flutter recreates the affected bundle on the next owner-run launch. Names may
contain spaces but not quotes, backslashes, `#`, or `$`, because those
characters have special meaning in YAML or Xcode configuration files.

`flutter_launcher_icons` remains installed for future non-macOS asset work, but
its `macos.generate` setting is deliberately disabled. Its input is the
Make-generated production 1024px PNG, so PDF input never leaks into a package
that expects a raster image. Refresh the currently unimplemented Android and
iOS assets explicitly with:

```sh
make -C scripts generate-platform-icons
```

That target runs `flutter_launcher_icons` only after Make has refreshed macOS,
then applies the narrow normalization required for the package's current iOS
Xcode-setting rewrite. `flutter_launcher_icons:generate` creates a configuration
template; it is not the icon-generation entry point.
