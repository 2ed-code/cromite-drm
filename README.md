# Cromite DRM

A Cromite-based Android ARM64 build with the normal Android `MediaDrm` path enabled.

## What this build does

- Uses the upstream Cromite source at build time.
- Removes Cromite's patch that disables Android DRM media pre-provisioning.
- Builds ARM64 Android `ChromePublic.apk`.
- Uses the device's Android DRM implementation when the device and content provider support it.
- Does **not** bundle Widevine binaries, private keys, certificates, or bypass DRM/license checks.
- Keeps Cromite's other privacy/security patches unless they conflict with the DRM restoration.

## Build output

GitHub Actions publishes the resulting APK as an artifact named `Cromite-DRM-Android-ARM64`.

## Important

DRM support is device/provider dependent. Enabling the Android `MediaDrm` path does not guarantee that every protected service will work on every device.
