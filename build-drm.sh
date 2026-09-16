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

# Cromite applies its normal patch stack first. The workflow removes the
# specific DRM-disabling patch from the patch list before this script runs.
git -C chromium/src config user.email "cromite-drm-build@example.invalid"
git -C chromium/src config user.name "Cromite DRM Build"
bash "$WORKSPACE/cromite/tools/images/cromite-source/apply-cromite-patches.sh"

cd "$WORKSPACE/chromium/src"

# Explicitly keep Chromium's Android Widevine/MediaDrm registration enabled.
# No proprietary CDM, key, certificate, or license bypass is added here.
ARGS="target_os = \"android\" target_cpu = \"arm64\" $(cat ../../cromite/build/cromite.gn_args)"
ARGS="$ARGS chrome_public_manifest_package = \"org.cromite.cromite\""
ARGS="$ARGS enable_widevine = true"

rm -rf out/arm64_drm
gn gen --args="$ARGS" out/arm64_drm

"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_bundle --offline
"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_apk --offline

APK="out/arm64_drm/apks/ChromePublic.apk"
test -f "$APK"
mkdir -p /output
cp "$APK" /output/Cromite-DRM-Android-ARM64.apk
printf '%s\n' "org.cromite.cromite" > /output/Cromite-DRM-package.txt
printf '%s\n' "Android ARM64 + MediaDrm/Widevine registration" > /output/Cromite-DRM-status.txt
cat ../../cromite/build/RELEASE > /output/Cromite-DRM-version.txt
printf '%s\n' "$(git rev-parse HEAD)" > /output/Cromite-DRM-source-revision.txt
