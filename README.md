# Custom Chromium Browser

Initial foundation for a new Chromium-based browser built incrementally from Chromium + Cromite.

## v0.1 foundation

- **Engine:** Chromium.
- **Privacy base:** Cromite patches/features.
- **Platform:** Android ARM64 (`arm64-v8a`) for the first build.
- **DRM:** uses the device's legitimate Android MediaDrm implementation; this project does **not** bundle Widevine binaries, keys, certificates, or bypass license checks.
- **Telemetry:** project default is disabled at the configuration level; each future telemetry-related change must be explicit and reviewable.
- **Architecture:** project configuration and future patches are kept separate from the upstream source tree so updates are easier to rebase.

## Build

The GitHub Actions workflow builds the current pinned Cromite/Chromium base and publishes an ARM64 debug APK as an artifact.

This first version is intentionally a foundation rather than a fully rebranded browser. The next step is browser identity/branding, followed by privacy controls and other features one at a time.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the incremental plan.

## DRM scope

DRM support is limited to the normal Android DRM stack available on the device and whatever compatibility/licensing the website and device provide. No DRM protection is bypassed.
