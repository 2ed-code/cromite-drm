# Nexa Browser

Nexa Browser is a Chromium-based Android browser built incrementally from Chromium + Cromite, with project-owned branding and privacy features added as separate, reviewable changes.

## v0.2 — branding foundation

- **Engine:** Chromium.
- **Privacy base:** Cromite patches/features.
- **App name:** `Nexa Browser`.
- **Android package:** `com.nexa.browser`.
- **Launcher icon:** project-owned dark adaptive/vector icon.
- **Platform:** Android ARM64 (`arm64-v8a`) for the first build.
- **DRM:** uses the device's legitimate Android MediaDrm implementation; this project does **not** bundle Widevine binaries, keys, certificates, or bypass license checks.
- **Telemetry:** project default is disabled at the configuration level; each future telemetry-related change must be explicit and reviewable.
- **Architecture:** project configuration and future patches are kept separate from the upstream source tree so updates are easier to rebase.

## Build

The GitHub Actions workflow builds the pinned Cromite/Chromium base, applies the Nexa branding layer, and publishes an ARM64 debug APK as an artifact named `NexaBrowser-v0.2-Android-ARM64`.

Branding is applied at build time by `branding/apply-branding.sh`. The upstream source tree remains disposable, which lets us add or remove individual features without turning the project into an unmaintainable Chromium fork.

## Roadmap

1. **Branding** — name, package ID, launcher icon. **Done.**
2. **Privacy controls** — add the privacy features one at a time with isolated patches.
3. **Ad/tracker blocking controls** — configurable and testable.
4. **Per-site permissions and privacy settings.**
5. **UI customization.**
6. **DRM compatibility testing and build hardening.**
7. **Release signing and reproducible release builds.**

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the incremental plan.

## DRM scope

DRM support is limited to the normal Android DRM stack available on the device and whatever compatibility/licensing the website and device provide. No DRM protection is bypassed.
