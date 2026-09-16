#!/usr/bin/env bash
set -euo pipefail

export WORKSPACE=/home/lg/working_dir
export HOME=/home/lg/working_dir
export TARGET_ISDEBUG=true
export TARGET_OS=android
export DEPOT_TOOLS=/home/lg/depot_tools
export DEPOT_TOOLS_UPDATE=0

if [ ! -d "$DEPOT_TOOLS/.git" ]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS"
fi

export PATH="$WORKSPACE/chromium/src/buildtools/linux64:$DEPOT_TOOLS:$WORKSPACE/chromium/src/third_party/llvm-build/Release+Asserts/bin:$PATH"

if [ ! -f "$DEPOT_TOOLS/python3_bin_reldir.txt" ]; then
  if [ -x "$DEPOT_TOOLS/bootstrap_python3" ]; then
    source "$DEPOT_TOOLS/bootstrap_python3"
    bootstrap_python3
  elif [ -x "$DEPOT_TOOLS/ensure_bootstrap" ]; then
    "$DEPOT_TOOLS/ensure_bootstrap"
  else
    "$DEPOT_TOOLS/update_depot_tools"
  fi
fi

PYTHON3="$DEPOT_TOOLS/python-bin/python3"
VPYTHON3="$DEPOT_TOOLS/vpython3"
test -x "$PYTHON3"
test -x "$VPYTHON3"

cd "$WORKSPACE"

# The workflow mounts the Cromite checkout directly at chromium/src/cromite.
# Cromite's patch helper is shipped by the build image at the workspace root.
# Do not use a nested tools/images/cromite-source path: that path does not exist
# in the current Cromite container layout.
PATCH_HELPER=""
for candidate in \
  "$WORKSPACE/apply-cromite-patches.sh" \
  "$WORKSPACE/chromium/src/cromite/tools/apply-all-patch.sh"; do
  if [ -f "$candidate" ]; then
    PATCH_HELPER="$candidate"
    break
  fi
done

test -n "$PATCH_HELPER"
git -C chromium/src config user.email "cromite-drm-build@example.invalid"
git -C chromium/src config user.name "Cromite DRM Build"
bash "$PATCH_HELPER"

cd "$WORKSPACE/chromium/src"

# Android Chromium uses the device's Android MediaDrm implementation for
# Widevine. We do not bundle, copy, or bypass any proprietary Widevine CDM,
# certificate, key, or license. Normal Android external-intent handling is
# intentionally left untouched; this project does not add an external-app
# blocker.
ARGS="target_os = \"android\" target_cpu = \"arm64\" $(cat ../../cromite/build/cromite.gn_args)"
ARGS="$ARGS chrome_public_manifest_package = \"org.cromite.cromite\""
ARGS="$ARGS enable_widevine = true"
ARGS="$ARGS enable_platform_aac_audio = true"
ARGS="$ARGS enable_platform_h264_video = true"
ARGS="$ARGS proprietary_codecs = true"
ARGS="$ARGS ffmpeg_branding = \"Chrome\""

rm -rf out/arm64_drm
gn gen --args="$ARGS" out/arm64_drm

# Build-time invariants: fail instead of producing an APK if the important
# DRM/media configuration was not accepted by GN.
gn args out/arm64_drm --list > /tmp/cromite-drm-gn-args.txt
for required in \
  'enable_widevine = true' \
  'enable_platform_aac_audio = true' \
  'enable_platform_h264_video = true' \
  'proprietary_codecs = true' \
  'ffmpeg_branding = "Chrome"'; do
  grep -F "$required" /tmp/cromite-drm-gn-args.txt >/dev/null
done

# The disabling Cromite patch must never be present after patch application.
! grep -R "Disable-DRM-media-origin-IDs-preprovisioning" \
  "$WORKSPACE/chromium/src/cromite/build/cromite_patches_list.txt" >/dev/null 2>&1

"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_bundle --offline
"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_apk --offline

APK="out/arm64_drm/apks/ChromePublic.apk"
test -s "$APK"

mkdir -p /output
cp "$APK" /output/Cromite-DRM-Android-ARM64.apk
printf '%s\n' "org.cromite.cromite" > /output/Cromite-DRM-package.txt
printf '%s\n' "Android ARM64 + Android MediaDrm/Widevine + H.264/AAC" > /output/Cromite-DRM-status.txt
cat ../../cromite/build/RELEASE > /output/Cromite-DRM-version.txt
printf '%s\n' "$(git rev-parse HEAD)" > /output/Cromite-DRM-source-revision.txt
