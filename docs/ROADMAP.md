# Custom Chromium Browser roadmap

## v0.1 — Foundation
- Chromium engine through the current Cromite source tree.
- Cromite privacy/security patches remain enabled.
- Android ARM64 build pipeline.
- Legitimate Android MediaDrm path restored; no bundled Widevine binaries, keys, certificates, or license bypass.
- Project configuration kept separate from upstream source.

## v0.2 — Browser identity
- Replace Chromium/Cromite product branding with the project's own name and icon.
- Define package/application identifiers.
- Add reproducible version metadata.

## v0.3 — Privacy controls
- First-party privacy settings UI.
- Clear defaults for tracking protection, site permissions, and telemetry.
- Per-site privacy controls.

## v0.4 — Browser features
- Downloads manager improvements.
- Tab/window management improvements.
- Permission controls and settings refinements.

## v0.5 — Validation
- Automated build checks.
- Smoke tests for normal browsing, downloads, media playback, and DRM where the device/provider supports it.
- Release artifacts and checksums.

## Rule for future changes
Each feature should be implemented as a small, reviewable patch and tested before the next feature is added. Upstream Chromium/Cromite updates should remain easy to rebase onto.
