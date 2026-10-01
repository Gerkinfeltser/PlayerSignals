# PlayerSignals (for SkyrimNet)

A planned JSON-configurable communication wheel for SkyrimNet. Select a nonverbal intent such as agreement, greeting, or thanks; SkyrimNet narrates the chosen roleplay action so nearby NPCs can react. No animation playback is required.

## Status

Implementation specification complete; the feature is not yet implemented or runtime-verified.

See [the plan and specification](docs/plans/player-signals.md) for API contracts, the default 25-intent layout, implementation steps, and verification gates.

## Repository Layout

```text
PlayerSignals/             Mod root; symlink this folder into MO2 for testing
PlayerSignals_spriggit/     Planned authored plugin records (outside the mod root)
docs/plans/                Plan and implementation specification
```

The `PlayerSignals/` folder currently contains only a Git directory marker. No ESP, scripts, configuration, or triggers have been built yet.

## Planned Dependencies

- SKSE
- UIExtensions
- JContainers
- SkyrimNet with the specified mod-event trigger support

Default opening key: Right Alt, configurable through JSON. No MCM layout configuration.

Do not symlink the repository root as the mod: documentation and authoring/build files stay outside `PlayerSignals/`.
