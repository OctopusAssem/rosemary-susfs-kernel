#!/system/bin/sh
# ---------------------------------------------------------------------------
# rosemary v5 SAFE-flash companion script
#
# Installs the modules bundled in this zip WITHOUT touching /data/adb during
# the flash. Run this ONCE from a root shell after booting the new kernel.
#
# Usage:   su -c 'sh /sdcard/setup-modules.sh'
# or:      su -c 'sh /data/local/tmp/setup-modules.sh'
#
# Why after boot and not at flash time?
#   AnyKernel3's do.modules() writes into /data/adb while the kernel is being
#   replaced: it mounts /data/adb/ksu/modules_update.img over
#   /data/adb/modules_update and copies files there. On a device whose
#   /data/adb/ksud inode is flagged immutable/append-only (the ReSukiSU
#   SUSFS hardlink case) that whole path is fragile and can hang the
#   installer. Doing the module copy after a normal boot avoids it entirely.
# ---------------------------------------------------------------------------

set -u

DATA_DIR="/data/adb"
MODS_DIR="$DATA_DIR/modules"

say() { echo "[setup-modules] $*"; }

need_root() {
  if [ "$(id -u)" != "0" ]; then
    say "ERROR: run this as root (su -c 'sh $0')"
    exit 1
  fi
}

# Where did we put the module payloads?
# Look next to this script, then in the usual payload folders.
find_payload() {
  for base in \
      "$(dirname "$0")/modules-payload" \
      "$(dirname "$0")/payload" \
      "/data/local/tmp/modules-payload" \
      "/sdcard/modules-payload" \
      "/sdcard/Download/modules-payload"; do
    if [ -d "$base/tricky_store" ] || [ -d "$base/simple_flag_secure" ]; then
      echo "$base"
      return 0
    fi
  done
  return 1
}

copy_module() {
  local src="$1" dst="$2" name="$3" arch

  [ -d "$src" ] || { say "$name: source missing, skipped"; return 0; }
  [ -f "$src/module.prop" ] || { say "$name: no module.prop, skipped"; return 0; }

  if [ -d "$dst" ]; then
    say "$name: already installed, skipped"
    return 0
  fi

  say "$name: installing -> $dst"
  rm -rf "$dst"
  mkdir -p "$dst"

  # ---- copy with busybox/toybox safe flags ---------------------------------
  # Avoid preserving ownership from the payload (it came from a FAT/sdcard fs).
  cp -a "$src/." "$dst/" 2>/dev/null || cp -r "$src/." "$dst/"

  # ---- prune other ABIs -----------------------------------------------------
  case "$(getprop ro.product.cpu.abi 2>/dev/null)" in
    arm64-v8a)   arch=arm64-v8a ;;
    armeabi-v7a) arch=armeabi-v7a ;;
    x86_64)      arch=x86_64 ;;
    x86)         arch=x86 ;;
    *)           arch=arm64-v8a ;;
  esac
  for a in arm64-v8a armeabi-v7a x86 x86_64; do
    [ "$a" = "$arch" ] && continue
    rm -rf "$dst/bin/$a" "$dst/lib/$a" "$dst/zygisk/$a.so" 2>/dev/null
  done
  rm -rf "$dst/lib/x86" "$dst/lib/x86_64" "$dst/bin/x86" "$dst/bin/x86_64" 2>/dev/null

  # ---- AlwaysStrong: rebuild the TEESimulator-RS native stack ---------------
  if [ "$name" = "tricky_store" ]; then
    [ -f "$src/lib/$arch/libinject.so" ]     && cp -f "$src/lib/$arch/libinject.so"     "$dst/inject"
    [ -f "$src/lib/$arch/libsupervisor.so" ] && cp -f "$src/lib/$arch/libsupervisor.so" "$dst/supervisor"
    [ -f "$dst/engine.conf" ] || printf 'ENGINE=tee\nATEST=1\n' > "$dst/engine.conf"

    mkdir -p "$DATA_DIR/tricky_store" 2>/dev/null
    if [ ! -f "$DATA_DIR/tricky_store/keybox.xml" ] && [ -f "$src/keybox.xml" ]; then
      cp -f "$src/keybox.xml" "$DATA_DIR/tricky_store/keybox.xml"
      chmod 600 "$DATA_DIR/tricky_store/keybox.xml" 2>/dev/null
    fi
    if [ ! -f "$DATA_DIR/tricky_store/target.txt" ] && [ -f "$src/target.txt" ]; then
      cp -f "$src/target.txt" "$DATA_DIR/tricky_store/target.txt"
    fi
  fi

  # ---- Make sure the module is not disabled/removed -------------------------
  rm -f "$dst/disable" "$dst/remove" 2>/dev/null

  # ---- permissions ----------------------------------------------------------
  chmod 755 "$dst" 2>/dev/null
  chmod 755 "$dst"/*.sh "$dst/daemon" "$dst/inject" "$dst/supervisor" 2>/dev/null
  [ -d "$dst/bin/$arch" ] && chmod 755 "$dst/bin/$arch"/* 2>/dev/null

  chown -R 0:0 "$dst" 2>/dev/null
  chown -R 0:0 "$DATA_DIR/tricky_store" 2>/dev/null

  # ---- SELinux labels -------------------------------------------------------
  chcon -hR "u:object_r:system_file:s0" "$dst" 2>/dev/null

  # ---- Let the root manager see it ------------------------------------------
  # KernelSU/ReSukiSU picks up modules present at boot; touch update marks it
  # as freshly installed so the manager refreshes its list.
  touch "$dst/update" 2>/dev/null
  say "$name: done"
}

need_root

say "kernel: $(uname -r)"
say "root manager: $( [ -d "$DATA_DIR/ksu" ] && echo KernelSU/ReSukiSU || echo unknown )"

if ! PAYLOAD="$(find_payload)"; then
  say ""
  say "Could not find the module payload folder."
  say "Copy the folder 'modules-payload' from the zip next to this script, then re-run."
  say "Looked for: modules-payload/ payload/ in script dir, /data/local/tmp, /sdcard, /sdcard/Download"
  exit 1
fi

say "payload: $PAYLOAD"
say ""

mkdir -p "$MODS_DIR" 2>/dev/null

copy_module "$PAYLOAD/tricky_store"       "$MODS_DIR/tricky_store"       tricky_store
copy_module "$PAYLOAD/simple_flag_secure" "$MODS_DIR/simple_flag_secure" simple_flag_secure

say ""
say "All done. REBOOT the device now, then open your root manager -> Modules."
say "You should see: AlwaysStrong (tricky_store) and Simple Flag Secure."
exit 0
