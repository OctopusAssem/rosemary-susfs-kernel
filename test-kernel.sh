#!/usr/bin/env bash
# ============================================================
#  ReSukiSU + SUSFS quick test  -  Redmi Note 10S (rosemary)
#  Run inside WSL after connecting the phone with adb.
#  Usage:  bash test-kernel.sh
# ============================================================
set -u

KSUD=/data/adb/ksu/bin/ksud

hr(){ printf '\n\033[1;36m========== %s ==========\033[0m\n' "$1"; }
run(){ adb shell "$1"; }

# --- 0. adb sanity ------------------------------------------------
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not installed. Run:  sudo apt update && sudo apt install -y android-tools-adb"
  exit 1
fi
if ! adb devices | grep -qw device; then
  echo "No phone detected."
  echo "Wireless:  adb pair <IP:PAIR_PORT>   then   adb connect <IP:PORT>"
  echo "Check with: adb devices"
  exit 1
fi

# --- 1. device / kernel ------------------------------------------
hr "DEVICE"
run 'getprop ro.product.model'
run 'getprop ro.build.version.release'
run 'uname -a'

# --- 2. root -----------------------------------------------------
hr "ROOT (su)"
run "su -c 'id'"

# --- 3. find ksud ------------------------------------------------
hr "KSUD BINARY"
run "su -c 'ls -l $KSUD /data/adb/ksud 2>/dev/null'"

# --- 4. ReSukiSU / KernelSU versions -----------------------------
hr "KSUD VERSION"
run "su -c '$KSUD -V'"

# --- 5. SUSFS identity -------------------------------------------
hr "SUSFS VERSION"
run "su -c '$KSUD susfs show version'"
hr "SUSFS VARIANT"
run "su -c '$KSUD susfs show variant'"

# --- 6. SUSFS enabled features (the important one) ---------------
hr "SUSFS ENABLED FEATURES"
run "su -c '$KSUD susfs show enabled_features'"

# --- 7. boot slot / kernel uname from boot image -----------------
hr "SLOT INFO"
run "su -c '$KSUD susfs slot_info'"

# --- 8. SELinux mode ---------------------------------------------
hr "SELINUX"
run 'getenforce'

# --- 9. persisted SUSFS config (JSON) ----------------------------
hr "SUSFS CONFIG"
run "su -c '$KSUD susfs config list_all'"

# --- 10. modules -------------------------------------------------
hr "KSU MODULES"
run "su -c 'ls -1 /data/adb/modules 2>/dev/null'"

# --- 11. live SUSFS log (last lines) -----------------------------
hr "SUSFS KERNEL LOG (tail)"
run "su -c 'dmesg | grep -i susfs | tail -n 20'"

echo
echo "Done."
