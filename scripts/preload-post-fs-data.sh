#!/system/bin/sh
# ak3-helper post-fs-data: preload the modules bundled in this zip.
# Runs on every boot; installs once into /data/adb/modules then does nothing.
MODDIR=${0%/*}
SRCROOT="$MODDIR/system/lib/modules"

install_tricky_store() {
  local src="$SRCROOT/tricky_store" dst="/data/adb/modules/tricky_store" arch

  [ -d "$src" ] || return 0
  [ -f "$src/module.prop" ] || return 0
  [ -d "$dst" ] && return 0

  rm -rf "$dst"
  mkdir -p "$dst"
  cp -rf "$src/." "$dst/"

  case "$(getprop ro.product.cpu.abi)" in
    arm64-v8a)   arch=arm64-v8a ;;
    armeabi-v7a) arch=armeabi-v7a ;;
    x86_64)      arch=x86_64 ;;
    x86)         arch=x86 ;;
    *)           arch=arm64-v8a ;;
  esac

  for a in arm64-v8a armeabi-v7a x86 x86_64; do
    [ "$a" = "$arch" ] && continue
    rm -rf "$dst/bin/$a" "$dst/lib/$a" "$dst/zygisk/$a.so"
  done
  rm -rf "$dst/lib/x86" "$dst/lib/x86_64" "$dst/bin/x86" "$dst/bin/x86_64"

  # TEESimulator-RS native stack
  [ -f "$src/lib/$arch/libinject.so" ]     && cp -f "$src/lib/$arch/libinject.so"     "$dst/inject"
  [ -f "$src/lib/$arch/libsupervisor.so" ] && cp -f "$src/lib/$arch/libsupervisor.so" "$dst/supervisor"

  chmod 755 "$dst"/*.sh "$dst/daemon" "$dst/inject" "$dst/supervisor" 2>/dev/null
  [ -d "$dst/bin/$arch" ] && chmod 755 "$dst/bin/$arch"/* 2>/dev/null

  [ -f "$dst/engine.conf" ] || printf 'ENGINE=tee\nATEST=1\n' > "$dst/engine.conf" 2>/dev/null

  mkdir -p /data/adb/tricky_store 2>/dev/null
  if [ ! -f /data/adb/tricky_store/keybox.xml ] && [ -f "$src/keybox.xml" ]; then
    cp -f "$src/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
    chmod 600 /data/adb/tricky_store/keybox.xml 2>/dev/null
  fi
  [ -f "$src/target.txt" ] && [ ! -f /data/adb/tricky_store/target.txt ] && \
    cp -f "$src/target.txt" /data/adb/tricky_store/target.txt 2>/dev/null

  touch "$dst/update"
  chown -R 0:0 "$dst" 2>/dev/null
  chmod 755 "$dst" 2>/dev/null
  /system/bin/chcon -hR "u:object_r:system_file:s0" "$dst" 2>/dev/null
  [ -d /data/adb/modules_update ] && touch /data/adb/ksu/update 2>/dev/null
  return 0
}

install_simple_flag_secure() {
  local src="$SRCROOT/simple_flag_secure" dst="/data/adb/modules/simple_flag_secure"

  [ -d "$src" ] || return 0
  [ -f "$src/module.prop" ] || return 0
  [ -d "$dst" ] && return 0

  rm -rf "$dst"
  mkdir -p "$dst"
  cp -rf "$src/." "$dst/"

  chmod 755 "$dst"/*.sh 2>/dev/null
  [ -f "$dst/system/bin/sfs.jar" ] && chmod 644 "$dst/system/bin/sfs.jar" 2>/dev/null

  # Unlock the module for the root manager on next boot
  touch "$dst/update"
  [ -f "$dst/disable" ] && rm -f "$dst/disable"
  [ -f "$dst/remove" ]  && rm -f "$dst/remove"

  chown -R 0:0 "$dst" 2>/dev/null
  chmod 755 "$dst" 2>/dev/null
  /system/bin/chcon -hR "u:object_r:system_file:s0" "$dst" 2>/dev/null
  [ -d /data/adb/modules_update ] && touch /data/adb/ksu/update 2>/dev/null
  return 0
}

mkdir -p /data/adb/modules 2>/dev/null
install_tricky_store
install_simple_flag_secure

exit 0
