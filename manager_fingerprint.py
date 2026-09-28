#!/usr/bin/env python3
"""
Compute the ReSukiSU / KernelSU "dynamic manager" fingerprint of a signed APK.

The kernel compares  (cert_size, sha256(cert_der))  of the first certificate
found in the APK Signature Scheme v2 block.

    usage:  python3 manager_fingerprint.py signed_v2.apk
"""
import hashlib
import struct
import sys

V2_ID = 0x7109871A
MAGIC = b"APK Sig Block 42"


def read_u32(buf, off):
    return struct.unpack_from("<I", buf, off)[0]


def read_u64(buf, off):
    return struct.unpack_from("<Q", buf, off)[0]


def find_signing_block(data):
    # Locate the End Of Central Directory record.
    eocd = data.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise ValueError("EOCD not found - not a zip/apk?")
    cd_offset = read_u32(data, eocd + 16)

    if data[cd_offset - 16:cd_offset] != MAGIC:
        raise ValueError("APK Signing Block magic not found (unsigned APK?)")
    block_size = read_u64(data, cd_offset - 24)
    block_start = cd_offset - block_size - 8
    if read_u64(data, block_start) != block_size:
        raise ValueError("APK Signing Block size mismatch")

    pos = block_start + 8
    end = cd_offset - 24
    while pos < end:
        pair_len = read_u64(data, pos)
        pair_id = read_u32(data, pos + 8)
        value = data[pos + 12:pos + 8 + pair_len]
        if pair_id == V2_ID:
            return value
        pos += 8 + pair_len
    raise ValueError("v2 signature block not found "
                     "(APK must be signed with v2, v1 only is not enough)")


def first_certificate(v2_block):
    signers_len = read_u32(v2_block, 0)
    signer_len = read_u32(v2_block, 4)
    signer = v2_block[8:8 + signer_len]

    signed_data_len = read_u32(signer, 0)
    signed_data = signer[4:4 + signed_data_len]

    digests_len = read_u32(signed_data, 0)
    off = 4 + digests_len

    certs_len = read_u32(signed_data, off)
    off += 4
    if certs_len == 0:
        raise ValueError("no certificate in v2 block")

    cert_len = read_u32(signed_data, off)
    off += 4
    return signed_data[off:off + cert_len]


def main(path):
    data = open(path, "rb").read()
    v2 = find_signing_block(data)
    cert = first_certificate(v2)
    digest = hashlib.sha256(cert).hexdigest()

    print("certificate size : %d" % len(cert))
    print("sha256(cert DER) : %s" % digest)
    print()
    print("register it with:")
    print("  adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager set %d %s'"
          % (len(cert), digest))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
