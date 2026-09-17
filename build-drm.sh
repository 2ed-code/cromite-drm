#!/usr/bin/env bash
set -euo pipefail

export WORKSPACE=/home/lg/working_dir
export HOME=/home/lg/working_dir
export TARGET_ISDEBUG=true
export TARGET_OS=android
export DEPOT_TOOLS=/home/lg/depot_tools
export DEPOT_TOOLS_UPDATE=0
export GIT_TERMINAL_PROMPT=0

# The uazo/chromium image does not guarantee a usable depot_tools checkout.
# Create a clean checkout and retry because the build container is created on
# a fresh GitHub runner and transient git transport failures are possible.
if [ ! -x "$DEPOT_TOOLS/python-bin/python3" ] || [ ! -x "$DEPOT_TOOLS/vpython3" ]; then
  rm -rf "$DEPOT_TOOLS"
  for attempt in 1 2 3; do
    echo "[build] cloning depot_tools (attempt $attempt/3)"
    if git -c http.version=HTTP/1.1 clone --depth 1 \
      https://chromium.googlesource.com/chromium/tools/depot_tools.git \
      "$DEPOT_TOOLS"; then
      break
    fi
    rm -rf "$DEPOT_TOOLS"
    if [ "$attempt" -lt 3 ]; then
      sleep 5
    fi
  done
fi

test -x "$DEPOT_TOOLS/python-bin/python3" || {
  echo "[build] depot_tools bootstrap files are missing after clone" >&2
  exit 1
}

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

# The workflow mounts the Cromite checkout at chromium/src/cromite.
# Use the patch helper shipped inside that checkout.
PATCH_HELPER="$WORKSPACE/chromium/src/cromite/tools/images/cromite-source/apply-cromite-patches.sh"
test -f "$PATCH_HELPER"

git -C chromium/src config user.email "cromite-drm-build@example.invalid"
git -C chromium/src config user.name "Cromite DRM Build"
bash "$PATCH_HELPER"

cd "$WORKSPACE/chromium/src"

# Android Chromium uses the device's Android MediaDrm implementation for
# Widevine. We do not bundle, copy, or bypass any proprietary Widevine CDM,
# certificate, key, or license. Normal Chromium external-intent handling is
# intentionally restored by omitting Cromite's external-intent blocking patch.
ARGS="target_os = \"android\" target_cpu = \"arm64\" $(cat ../../cromite/build/cromite.gn_args)"
ARGS="$ARGS chrome_public_manifest_package = \"org.cromite.cromite\""
ARGS="$ARGS enable_widevine = true"
ARGS="$ARGS enable_platform_aac_audio = true"
ARGS="$ARGS enable_platform_h264_video = true"
ARGS="$ARGS proprietary_codecs = true"
ARGS="$ARGS ffmpeg_branding = \"Chrome\""

rm -rf out/arm64_drm
gn gen --args="$ARGS" out/arm64_drm

gn args out/arm64_drm --list > /tmp/cromite-drm-gn-args.txt
for required in \
  'enable_widevine = true' \
  'enable_platform_aac_audio = true' \
  'enable_platform_h264_video = true' \
  'proprietary_codecs = true' \
  'ffmpeg_branding = "Chrome"'; do
  grep -F "$required" /tmp/cromite-drm-gn-args.txt >/dev/null
done

# These blockers must never be in the patch stack used for this build.
! grep -E \
  '^(Add-flag-to-disable-external-intent-requests|Block-Intents-While-Locked|Disable-DRM-media-origin-IDs-preprovisioning)\.patch$' \
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
