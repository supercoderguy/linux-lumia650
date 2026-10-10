#!/usr/bin/env python3
"""Inspect and extract partitions from Windows Phone FFU images.

Read-only: never writes to the FFU. Format follows WPinternals' Models/FFU.cs.

  ffutool.py info    <ffu>                      header, manifest and partition table
  ffutool.py extract <ffu> <partition> <out.img>  write one partition as a raw image
"""
import struct
import sys
import uuid

SECTOR = 512


class FFU:
    def __init__(self, path):
        self.f = open(path, "rb")

        sec = self.f.read(0x20)
        if sec[4:16] != b"SignedImage ":
            raise ValueError("not an FFU (missing SignedImage signature)")
        sec_size, = struct.unpack_from("<I", sec, 0x00)
        self.chunk_size = struct.unpack_from("<I", sec, 0x10)[0] * 1024
        catalog_size, hash_size = struct.unpack_from("<II", sec, 0x18)
        security_len = self._round(sec_size + catalog_size + hash_size)

        self.f.seek(security_len)
        img = self.f.read(0x1C)
        if img[4:16] != b"ImageFlash  ":
            raise ValueError("missing ImageFlash header")
        img_size, manifest_size = struct.unpack_from("<I", img, 0)[0], struct.unpack_from("<I", img, 0x10)[0]
        self.f.seek(security_len + img_size)
        self.manifest = self.f.read(manifest_size).decode("ascii", "replace")
        image_len = self._round(img_size + manifest_size)

        store_off = security_len + image_len
        self.f.seek(store_off)
        store = self.f.read(248)
        self.platform_id = store[0x0C:0x0C + 192].split(b"\0")[0].decode().strip()
        self.block_size, = struct.unpack_from("<I", store, 204)
        wd_count, wd_len = struct.unpack_from("<iI", store, 208)
        vd_len, = struct.unpack_from("<I", store, 220)
        store_len = self._round(248 + wd_len + vd_len)

        self.f.seek(store_off)
        store = self.f.read(store_len)
        self.payload_off = store_off + store_len

        # Map disk chunk index -> FFU chunk index (from-start locations only;
        # from-end ones hold the backup GPT).
        self.chunks = {}
        off = 248 + vd_len
        ffu_idx = 0
        for _ in range(wd_count):
            loc_count, chunk_count = struct.unpack_from("<Ii", store, off)
            for j in range(loc_count):
                method, disk_idx = struct.unpack_from("<ii", store, off + 8 + j * 8)
                if method == 0:
                    for k in range(chunk_count):
                        self.chunks[disk_idx + k] = ffu_idx + k
            off += 8 + loc_count * 8
            ffu_idx += chunk_count

        self.partitions = self._read_gpt()

    def _round(self, n):
        return (n + self.chunk_size - 1) // self.chunk_size * self.chunk_size

    def read_sectors(self, first, count):
        """Read disk sectors; chunks absent from the FFU read as zeros."""
        out = bytearray()
        per_chunk = self.chunk_size // SECTOR
        sector = first
        end = first + count
        while sector < end:
            chunk, within = divmod(sector, per_chunk)
            n = min(per_chunk - within, end - sector)
            if chunk in self.chunks:
                self.f.seek(self.payload_off + self.chunks[chunk] * self.chunk_size + within * SECTOR)
                out += self.f.read(n * SECTOR)
            else:
                out += bytes(n * SECTOR)
            sector += n
        return bytes(out)

    def _read_gpt(self):
        hdr = self.read_sectors(1, 1)
        if hdr[:8] != b"EFI PART":
            raise ValueError("no GPT at sector 1")
        entries_lba, num, entry_size = struct.unpack_from("<QII", hdr, 72)
        raw = self.read_sectors(entries_lba, (num * entry_size + SECTOR - 1) // SECTOR)
        parts = []
        for i in range(num):
            e = raw[i * entry_size:(i + 1) * entry_size]
            if e[:16] == bytes(16):
                continue
            first, last = struct.unpack_from("<QQ", e, 32)
            name = e[56:128].decode("utf-16-le").split("\0")[0]
            parts.append((name, first, last, uuid.UUID(bytes_le=e[:16])))
        return parts

    def partition(self, name):
        for p in self.partitions:
            if p[0].lower() == name.lower():
                return p
        raise KeyError(name)


def main(argv):
    if len(argv) < 3 or argv[1] not in ("info", "extract"):
        sys.exit(__doc__)
    ffu = FFU(argv[2])
    if argv[1] == "info":
        print(f"Platform ID : {ffu.platform_id}")
        print(f"Chunk size  : {ffu.chunk_size:#x}")
        print("Manifest    :")
        for line in ffu.manifest.splitlines():
            if line.strip():
                print("   ", line.strip())
        print(f"{'Partition':<22}{'First':>12}{'Last':>12}{'Size':>12}  Present")
        for name, first, last, _ in ffu.partitions:
            size = (last - first + 1) * SECTOR
            per = ffu.chunk_size // SECTOR
            present = any(c in ffu.chunks for c in range(first // per, last // per + 1))
            print(f"{name:<22}{first:>12}{last:>12}{size // 1024:>10}KB  {'yes' if present else '-'}")
    else:
        if len(argv) != 5:
            sys.exit(__doc__)
        name, first, last, _ = ffu.partition(argv[3])
        with open(argv[4], "wb") as out:
            step = 0x4000
            for s in range(first, last + 1, step):
                out.write(ffu.read_sectors(s, min(step, last + 1 - s)))
        print(f"wrote {name} ({(last - first + 1) * SECTOR} bytes) to {argv[4]}")


if __name__ == "__main__":
    main(sys.argv)
