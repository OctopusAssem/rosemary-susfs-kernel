# SAFE-flash variant — why the other zip could hang

## The real cause of "flash hangs"
The AnyKernel3 zip with `do.modules=1` runs `do_modules()` **while the kernel is being replaced**.
That function:

1. `mkdir -p /data/adb/modules_update`
2. creates or copies `/data/adb/ksu/modules_update.img`
3. **mounts it read-write over `/data/adb/modules_update`**
4. copies the `ak3-helper` module into it
5. unmounts

It also can run `cp -f libksud.so /data/adb/ksud` (update-binary, when `/data/adb/ksud` is missing).

On this device `/data/adb/ksud` and `/data/adb/ksu/bin/ksu_susfs` are **the same inode**, and that inode
carries `S_IMMUTABLE`/`S_APPEND` in memory (VFS-level). Any operation that goes through that path
(`link()`, `unlink()`, `rename()`) returns `EPERM`, and a mount/copy loop over it can block the installer.

**It was never the kernel Image.** The v5 kernel itself flashes and boots fine.

## The SAFE zip
`rosemary-v5-SAFE-AnyKernel3.zip`

| | ALL-IN-ONE | SAFE |
|---|---|---|
| `do.modules` | 1 | **0** |
| writes `/data/adb` during flash | yes | **no** |
| kernel payload | v5 | v5 (identical) |
| modules bundled | yes | yes, as `payload/` |
| module install | at first boot | **after boot, one command** |

## Install
1. Flash the zip in your root manager (or recovery). It writes only to the boot partition, then reboot.
2. Copy the module payload over:
   ```
   adb push payload /data/local/tmp/modules-payload
   adb push setup-modules.sh /data/local/tmp/
   ```
3. Run it once as root:
   ```
   adb shell "su -c 'sh /data/local/tmp/setup-modules.sh'"
   ```
4. Reboot. Modules → **AlwaysStrong (tricky_store)** and **Simple Flag Secure**.

## What setup-modules.sh does
- copies `tricky_store` and `simple_flag_secure` into `/data/adb/modules`
- prunes all non-arm64-v8a binaries
- rebuilds tricky_store's native stack (`inject`, `supervisor`, `engine.conf`)
- seeds `/data/adb/tricky_store/{keybox.xml,target.txt}` (kept if already present)
- fixes ownership, modes and the `system_file` SELinux context
- removes `disable`/`remove` markers and touches `update`
- idempotent: re-running it skips installed modules

## Verify after boot
```
adb shell "su -c '/data/adb/ksu/bin/ksud feature list'"
adb shell "su -c '/data/adb/ksu/bin/ksu_susfs show enabled_features'"
```
