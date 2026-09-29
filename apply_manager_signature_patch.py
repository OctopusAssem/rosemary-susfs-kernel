#!/usr/bin/env python3
"""Register a custom (spoofed) manager signature in ReSukiSU/ReSukiSU and stop
the kernel from marking /data/adb/ksud read-only."""
import os, sys

KSU  = sys.argv[1]
SIZE = "0x33a"
HASH = "eac9123b4d9093377df677052ab3a6ecea7d99d81a58d5cf8853998bc443050d"
MARK = "EXPECTED_HASH_CUSTOM_MANAGER"

# 1) add the certificate to the static manager-signature table
p = os.path.join(KSU, "manager", "manager_sign.h")
s = open(p).read()
if MARK not in s:
    ins = ("\n// Custom / spoofed hidden manager (System Update)\n"
           f"#define EXPECTED_SIZE_CUSTOM_MANAGER {SIZE}\n"
           f'#define {MARK} "{HASH}"\n\n')
    s = s[:s.index("typedef struct {")] + ins + s[s.index("typedef struct {"):]
    open(p, "w").write(s)

p = os.path.join(KSU, "manager", "apk_sign.c")
s = open(p).read()
if MARK not in s:
    anchor = "static apk_sign_key_t apk_sign_keys[] = {"
    i = s.index(anchor) + len(anchor)
    s = s[:i] + (f"\n    {{ EXPECTED_SIZE_CUSTOM_MANAGER, {MARK} }},"
                 " // Custom / spoofed manager (System Update)") + s[i:]
    open(p, "w").write(s)

# 2) never flag /data/adb/ksud immutable (that flag blocks hard_link/unlink,
#    which is what broke `susfs config enable` and module installs)
p = os.path.join(KSU, "hook", "setuid_hook.c")
s = open(p).read()
if 'ksu_set_file_immutable("/data/adb/ksud", true);' in s:
    s = s.replace('ksu_set_file_immutable("/data/adb/ksud", true);',
                  'ksu_set_file_immutable("/data/adb/ksud", false);')
    open(p, "w").write(s)

# verify
h = open(os.path.join(KSU, "manager", "manager_sign.h")).read()
c = open(os.path.join(KSU, "manager", "apk_sign.c")).read()
k = open(os.path.join(KSU, "hook", "setuid_hook.c")).read()
assert MARK in h and MARK in c, "signature entry missing"
assert "EXPECTED_SIZE_CUSTOM_MANAGER, " + MARK in c, "apk_sign_keys entry missing"
assert 'ksu_set_file_immutable("/data/adb/ksud", true);' not in k, "lock still present"
print("[+] manager signature patch applied and verified")
