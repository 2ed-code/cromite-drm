# Cromite DRM build

This repository builds an ARM64 debug APK from the current Cromite release while restoring Chromium's normal Android MediaDrm preprovisioning path.

The build does **not** bundle Widevine binaries, keys, certificates, or bypass license checks. It relies on the Android device's legitimate DRM implementation.

The workflow targets Cromite `153.0.8010.37` and removes only Cromite's `Disable-DRM-media-origin-IDs-preprovisioning.patch` from the patch list before applying the remaining Cromite patches.

The generated APK is intended for Android ARM64 devices. DRM playback still depends on the device having a compatible licensed DRM provider and on the website accepting the browser/device combination.
