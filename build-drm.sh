#!/usr/bin/env bash
set -euo pipefail

export WORKSPACE=/home/lg/working_dir
export HOME=/home/lg/working_dir
export TARGET_ISDEBUG=true
export TARGET_OS=android
export DEPOT_TOOLS=/home/lg/depot_tools
export DEPOT_TOOLS_UPDATE=0

APP_NAME="Nexa Browser"
PACKAGE_NAME="com.nexa.browser"

if [ ! -d "$DEPOT_TOOLS/.git" ]; then
  rm -rf "$DEPOT_TOOLS"
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS"
fi

export PATH="$WORKSPACE/chromium/src/buildtools/linux64:$DEPOT_TOOLS:$WORKSPACE/chromium/src/third_party/llvm-build/Release+Asserts/bin:/usr/local/go/bin:/home/lg/mtool/bin:$PATH"

if [ ! -f "$DEPOT_TOOLS/python3_bin_reldir.txt" ]; then
  if [ -x "$DEPOT_TOOLS/bootstrap_python3" ]; then
    source "$DEPOT_TOOLS/bootstrap_python3"
    bootstrap_python3
  elif [ -x "$DEPOT_TOOLS/ensure_bootstrap" ]; then
    "$DEPOT_TOOLS/ensure_bootstrap"
  elif [ -x "$DEPOT_TOOLS/update_depot_tools" ]; then
    "$DEPOT_TOOLS/update_depot_tools"
  else
    echo "No supported depot_tools Python bootstrap entry point found" >&2
    find "$DEPOT_TOOLS" -maxdepth 2 -type f \( -name 'bootstrap_python3' -o -name 'ensure_bootstrap' -o -name 'update_depot_tools' \) -print >&2
    exit 1
  fi
fi

PYTHON3="$DEPOT_TOOLS/python-bin/python3"
VPYTHON3="$DEPOT_TOOLS/vpython3"
test -x "$PYTHON3"
test -x "$VPYTHON3"
"$PYTHON3" --version
which -a gn
gn --version

cd "$WORKSPACE"
git -C chromium/src config user.email "drm-build@example.invalid"
git -C chromium/src config user.name "Nexa Browser Build"
bash "$WORKSPACE/cromite/tools/images/cromite-source/apply-cromite-patches.sh"

# Apply project-owned branding after Cromite patches. This keeps the branding
# layer isolated from upstream Chromium/Cromite and makes future rebases safer.
bash "$WORKSPACE/cromite/branding/apply-branding.sh" "$WORKSPACE/chromium/src"

cd "$WORKSPACE/chromium/src"

CLANG_STAMP_DIR="third_party/llvm-build/Release+Asserts"
CLANG_STAMP="$CLANG_STAMP_DIR/cr_build_revision"
test -x "$CLANG_STAMP_DIR/bin/clang"

# Chromium's GN consistency check requires cr_build_revision to match the
# revision declared by tools/clang/scripts/update.py. The Docker image already
# contains the clang binary, so derive the stamp from Chromium itself instead
# of parsing PACKAGE_VERSION (which is an expression, not a literal).
EXPECTED_CLANG_REVISION="$($PYTHON3 tools/clang/scripts/update.py --print-revision)"
EXPECTED_CLANG_REVISION="$(printf '%s' "$EXPECTED_CLANG_REVISION" | tr -d '\r\n')"
test -n "$EXPECTED_CLANG_REVISION"

CURRENT_CLANG_REVISION=""
if [ -s "$CLANG_STAMP" ]; then
  CURRENT_CLANG_REVISION="$(cut -d',' -f1 < "$CLANG_STAMP" | tr -d '\r\n')"
fi

if [ "$CURRENT_CLANG_REVISION" != "$EXPECTED_CLANG_REVISION" ]; then
  mkdir -p "$CLANG_STAMP_DIR"
  printf '%s,linux\n' "$EXPECTED_CLANG_REVISION" > "$CLANG_STAMP"
fi

echo "Using Chromium clang stamp: $(cat "$CLANG_STAMP")"

if git grep -n "SET_CROMITE_FEATURE_DISABLED(kMediaDrmPreprovisioning)" -- .; then
  echo "DRM disabling patch is still present" >&2
  exit 1
fi

rm -rf out/arm64_drm
gn gen --args="target_os = \"android\" target_cpu = \"arm64\" chrome_public_manifest_package = \"$PACKAGE_NAME\" $(cat ../../cromite/build/cromite.gn_args)" out/arm64_drm

"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_bundle --offline
"$VPYTHON3" "$DEPOT_TOOLS/siso.py" ninja -C out/arm64_drm chrome_public_apk --offline

APK="out/arm64_drm/apks/ChromePublic.apk"
test -f "$APK"
cp "$APK" "/output/NexaBrowser-ARM64-debug.apk"
printf '%s\n' "$APP_NAME" > /output/NexaBrowser-name.txt
printf '%s\n' "$PACKAGE_NAME" > /output/NexaBrowser-package.txt
cp ../../cromite/build/RELEASE /output/NexaBrowser-version.txt
git rev-parse HEAD > /output/NexaBrowser-source-revision.txt
