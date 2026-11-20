# Scripts

`scripts/Makefile` owns macOS process control, protobuf generation, Neo4j
backups, and macOS app icon and name settings. Run `make -C scripts` to list
the targets.

| Target | Purpose |
| --- | --- |
| `interface` | Owner only: start Neo4j (Docker, local URIs only), the Go API, wait for `/healthz`, then launch the macOS client |
| `start` / `stop` / `restart` / `status` / `logs` | Go API process control |
| `proto` | Regenerate Go and Dart protobuf code |
| `backup`, `backup-verify`, `backup-schedule`, … | Encrypted Neo4j backups; see [../docs/data-runbook.md](../docs/data-runbook.md#backups) |
| `setDefaultIcon path=…` (or `debug_path=… production_path=…`) | Generate the macOS icon catalogs from a raster, PDF, or SVG inside `frontend/obsivilian/` |
| `setAppName name=…` (or `debug_name=… production_name=…`) | Set the macOS display names |
| `generate-platform-icons` | Refresh the unused Android and iOS icons |

Icon and name settings persist in `macos_launcher_icons.yaml` and
`macos_app_names.yaml`. `interface` regenerates them when inputs change and
removes only the affected build bundle. Debug uses the bundle ID
`io.github.matey2010.obsivilian.debug` so its icon doesn't collide with the
production app's. Don't edit generated icon catalogs by hand.
