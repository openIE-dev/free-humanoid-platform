#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Free Humanoid Platform & OpenIE Contributors
"""emit_wai_commons.py — Tri-license-aware Canonical OpenIE Artifact emitter,
UDD WAI1 envelope builder, and Commons Scholar bundle generator for the
Free Humanoid Platform (OpenLoco Morphology #17).

Tri-License Posture:
  - CC0-1.0       (`LICENSE-DATA`):     `descriptor/`, `datasets/`, `prior-art/`, BOM CSVs
  - Apache-2.0    (`LICENSE-SOFTWARE`): `firmware/`, `control/`, `sim/`
  - CERN-OHL-S-2.0 (`LICENSE-HARDWARE`): `actuators/`, `chassis/`, `electronics/` + Morphology #17 umbrella
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)

try:
    import blake3 as _native_blake3  # type: ignore[import-not-found]
except ImportError:
    _native_blake3 = None

try:
    import compression.zstd as _stdlib_zstd
except ImportError:
    _stdlib_zstd = None

try:
    import zstandard as _ext_zstd  # type: ignore[import-not-found]
except ImportError:
    _ext_zstd = None

WAI1_MAGIC = b"WAI1"
MANIFEST_MAX_LEN = 1 << 27
MANIFEST_MAX_DEPTH = 127
MANIFEST_MAX_VALUES = 1 << 22
TEXT_DECODED_MAX_LEN = 1 << 27
TEXT_WINDOW_MAX_LEN = 1 << 27
ZSTD_MAGIC_LE = 0xFD2FB528
ZSTD_SKIPPABLE_MASK = 0xFFFFFFF0
ZSTD_SKIPPABLE_MAGIC = 0x184D2A50

JWP_OBJECT_DOMAIN = b"moq-jwp:object\x01"
JWP_LEAF_DOMAIN = b"moq-jwp:merkle-leaf\x01"
JWP_GROUP_SIGN_DOMAIN = b"moq-jwp:group-sign\x01"
JWP_RECEIPT_LINK_DOMAIN = b"moq-jwp:receipt-link\x01"

OPENIE_ARTIFACT_SIGN_DOMAIN = b"openie:artifact:v1"
OPENIE_RELEASE_SIGN_DOMAIN = b"openie:wai-release-receipt:v1"

PLATFORM_SLUG = "free-humanoid-platform"
PLATFORM_TITLE = "Free Humanoid Platform (OpenLoco Morphology #17)"
PLATFORM_REPO_URL = "https://github.com/openIE-dev/free-humanoid-platform"
DEFAULT_COMMONS_URL = "https://scholar.askdavidc.ai"
DEFAULT_SIGNER_ID = "openie:free-humanoid-platform:release-signer-v1"
DETERMINISTIC_SIGNER_DOMAIN = (
    b"openie:free-humanoid-platform:ed25519-release-signer:v1\x00"
    b"repo=github.com/openIE-dev/free-humanoid-platform\x00tri-license=CC0-1.0+Apache-2.0+CERN-OHL-S-2.0"
)

ALLOWED_TRI_LICENSES = {"CC0-1.0", "Apache-2.0", "CERN-OHL-S-2.0"}

# Deterministic subsystem manifest for tri-license artifact emission
SUBSYSTEM_SPECS: tuple[dict[str, Any], ...] = (
    {
        "id": "descriptor",
        "title": "Unified Descriptor Document (OpenLoco Morphology #17 — 33-DoF Bipedal Humanoid)",
        "prefix": "humanoid_morphology",
        "kind": "humanoid_morphology",
        "license": "CC0-1.0",
        "license_file": "LICENSE-DATA",
        "rung": "R6",
        "rung_label": "Compiled Descriptor",
        "paths": ("descriptor/free-humanoid.udd.json", "descriptor/README.md"),
        "primary_file": "descriptor/free-humanoid.udd.json",
    },
    {
        "id": "datasets",
        "title": "Free Humanoid Datasets & Calibration Traces Subsystem",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CC0-1.0",
        "license_file": "LICENSE-DATA",
        "rung": "R6",
        "rung_label": "Compiled Descriptor",
        "paths": ("datasets/README.md",),
        "primary_file": "datasets/README.md",
    },
    {
        "id": "prior-art",
        "title": "Free Humanoid Prior-Art Shield & Lineage Anchors",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CC0-1.0",
        "license_file": "LICENSE-DATA",
        "rung": "R6",
        "rung_label": "Compiled Descriptor",
        "paths": ("prior-art/INDEX.md",),
        "primary_file": "prior-art/INDEX.md",
    },
    {
        "id": "chassis-bom",
        "title": "Free Humanoid Hand v0.1 & Leg v0.1 Bills of Materials (BOM)",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CC0-1.0",
        "license_file": "LICENSE-DATA",
        "rung": "R6",
        "rung_label": "Compiled Descriptor",
        "paths": ("chassis/hand-v0.1-BOM.csv", "chassis/leg-v0.1-BOM.csv"),
        "primary_file": "chassis/hand-v0.1-BOM.csv",
    },
    {
        "id": "firmware",
        "title": "Free Humanoid Real-Time Actuator & Bus Firmware Subsystem",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "Apache-2.0",
        "license_file": "LICENSE-SOFTWARE",
        "rung": "R7",
        "rung_label": "Executable Controller",
        "paths": ("firmware/README.md",),
        "primary_file": "firmware/README.md",
    },
    {
        "id": "control",
        "title": "Free Humanoid Whole-Body Control & MathGround Simplex Supervisor",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "Apache-2.0",
        "license_file": "LICENSE-SOFTWARE",
        "rung": "R7",
        "rung_label": "Executable Controller",
        "paths": ("control/README.md",),
        "primary_file": "control/README.md",
    },
    {
        "id": "sim",
        "title": "Free Humanoid MuJoCo / Rigid-Body Simulation Harness",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "Apache-2.0",
        "license_file": "LICENSE-SOFTWARE",
        "rung": "R7",
        "rung_label": "Executable Controller",
        "paths": ("sim/README.md",),
        "primary_file": "sim/README.md",
    },
    {
        "id": "actuators",
        "title": "Free Humanoid Hybrid Actuator Architecture (Cycloidal / QDD / Harmonic / Tendon)",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CERN-OHL-S-2.0",
        "license_file": "LICENSE-HARDWARE",
        "rung": "R8",
        "rung_label": "Physical Hardware",
        "paths": ("actuators/README.md",),
        "primary_file": "actuators/README.md",
    },
    {
        "id": "chassis",
        "title": "Free Humanoid Parametric OpenSCAD Chassis, Hand v0.1 & Leg v0.1 Structural CAD",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CERN-OHL-S-2.0",
        "license_file": "LICENSE-HARDWARE",
        "rung": "R8",
        "rung_label": "Physical Hardware",
        "paths": ("chassis/README.md", "chassis/cad"),
        "primary_file": "chassis/README.md",
    },
    {
        "id": "electronics",
        "title": "Free Humanoid Power Distribution, CAN-FD Bus & Sensing Electronics",
        "prefix": "hardware_subsystem",
        "kind": "hardware_subsystem",
        "license": "CERN-OHL-S-2.0",
        "license_file": "LICENSE-HARDWARE",
        "rung": "R8",
        "rung_label": "Physical Hardware",
        "paths": ("electronics/README.md",),
        "primary_file": "electronics/README.md",
    },
)

_B3_IV = (
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
    0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
)
_B3_CHUNK_START = 1
_B3_CHUNK_END = 2
_B3_PARENT = 4
_B3_ROOT = 8


def _b3_compress8(
    cv: tuple[int, ...], m: tuple[int, ...], counter: int, blen: int, flags: int
) -> tuple[int, int, int, int, int, int, int, int]:
    M = 0xFFFFFFFF
    s0, s1, s2, s3, s4, s5, s6, s7 = cv
    s8, s9, s10, s11 = 0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A
    s12, s13, s14, s15 = counter & M, (counter >> 32) & M, blen, flags
    m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15 = m
    for r in range(7):
        s0 = (s0 + s4 + m0) & M; x = s12 ^ s0; s12 = ((x >> 16) | (x << 16)) & M
        s8 = (s8 + s12) & M; x = s4 ^ s8; s4 = ((x >> 12) | (x << 20)) & M
        s0 = (s0 + s4 + m1) & M; x = s12 ^ s0; s12 = ((x >> 8) | (x << 24)) & M
        s8 = (s8 + s12) & M; x = s4 ^ s8; s4 = ((x >> 7) | (x << 25)) & M

        s1 = (s1 + s5 + m2) & M; x = s13 ^ s1; s13 = ((x >> 16) | (x << 16)) & M
        s9 = (s9 + s13) & M; x = s5 ^ s9; s5 = ((x >> 12) | (x << 20)) & M
        s1 = (s1 + s5 + m3) & M; x = s13 ^ s1; s13 = ((x >> 8) | (x << 24)) & M
        s9 = (s9 + s13) & M; x = s5 ^ s9; s5 = ((x >> 7) | (x << 25)) & M

        s2 = (s2 + s6 + m4) & M; x = s14 ^ s2; s14 = ((x >> 16) | (x << 16)) & M
        s10 = (s10 + s14) & M; x = s6 ^ s10; s6 = ((x >> 12) | (x << 20)) & M
        s2 = (s2 + s6 + m5) & M; x = s14 ^ s2; s14 = ((x >> 8) | (x << 24)) & M
        s10 = (s10 + s14) & M; x = s6 ^ s10; s6 = ((x >> 7) | (x << 25)) & M

        s3 = (s3 + s7 + m6) & M; x = s15 ^ s3; s15 = ((x >> 16) | (x << 16)) & M
        s11 = (s11 + s15) & M; x = s7 ^ s11; s7 = ((x >> 12) | (x << 20)) & M
        s3 = (s3 + s7 + m7) & M; x = s15 ^ s3; s15 = ((x >> 8) | (x << 24)) & M
        s11 = (s11 + s15) & M; x = s7 ^ s11; s7 = ((x >> 7) | (x << 25)) & M

        s0 = (s0 + s5 + m8) & M; x = s15 ^ s0; s15 = ((x >> 16) | (x << 16)) & M
        s10 = (s10 + s15) & M; x = s5 ^ s10; s5 = ((x >> 12) | (x << 20)) & M
        s0 = (s0 + s5 + m9) & M; x = s15 ^ s0; s15 = ((x >> 8) | (x << 24)) & M
        s10 = (s10 + s15) & M; x = s5 ^ s10; s5 = ((x >> 7) | (x << 25)) & M

        s1 = (s1 + s6 + m10) & M; x = s12 ^ s1; s12 = ((x >> 16) | (x << 16)) & M
        s11 = (s11 + s12) & M; x = s6 ^ s11; s6 = ((x >> 12) | (x << 20)) & M
        s1 = (s1 + s6 + m11) & M; x = s12 ^ s1; s12 = ((x >> 8) | (x << 24)) & M
        s11 = (s11 + s12) & M; x = s6 ^ s11; s6 = ((x >> 7) | (x << 25)) & M

        s2 = (s2 + s7 + m12) & M; x = s13 ^ s2; s13 = ((x >> 16) | (x << 16)) & M
        s8 = (s8 + s13) & M; x = s7 ^ s8; s7 = ((x >> 12) | (x << 20)) & M
        s2 = (s2 + s7 + m13) & M; x = s13 ^ s2; s13 = ((x >> 8) | (x << 24)) & M
        s8 = (s8 + s13) & M; x = s7 ^ s8; s7 = ((x >> 7) | (x << 25)) & M

        s3 = (s3 + s4 + m14) & M; x = s14 ^ s3; s14 = ((x >> 16) | (x << 16)) & M
        s9 = (s9 + s14) & M; x = s4 ^ s9; s4 = ((x >> 12) | (x << 20)) & M
        s3 = (s3 + s4 + m15) & M; x = s14 ^ s3; s14 = ((x >> 8) | (x << 24)) & M
        s9 = (s9 + s14) & M; x = s4 ^ s9; s4 = ((x >> 7) | (x << 25)) & M

        if r < 6:
            m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15 = (
                m2, m6, m3, m10, m7, m0, m4, m13, m1, m11, m12, m5, m9, m14, m15, m8,
            )
    return (s0 ^ s8, s1 ^ s9, s2 ^ s10, s3 ^ s11, s4 ^ s12, s5 ^ s13, s6 ^ s14, s7 ^ s15)


def _b3_words(block: bytes) -> tuple[int, ...]:
    if len(block) < 64:
        block = block + b"\x00" * (64 - len(block))
    return struct.unpack("<16I", block)


def _b3_chunk_output(chunk: bytes, counter: int) -> tuple[tuple[int, ...], tuple[int, ...], int, int, int]:
    if not chunk:
        return (_B3_IV, (0,) * 16, counter, 0, _B3_CHUNK_START | _B3_CHUNK_END)
    n_len = len(chunk)
    cv: tuple[int, ...] = _B3_IV
    off = 0
    first = True
    while n_len - off > 64:
        cv = _b3_compress8(cv, struct.unpack_from("<16I", chunk, off), counter, 64, _B3_CHUNK_START if first else 0)
        first = False
        off += 64
    last = chunk[off:]
    return (cv, _b3_words(last), counter, len(last), _B3_CHUNK_END | (_B3_CHUNK_START if first else 0))


def _blake3_pure(data: bytes) -> bytes:
    mv = memoryview(data)
    total_len = len(mv)
    stack: list[tuple[int, ...]] = []
    n_chunks = (total_len - 1) // 1024 + 1 if total_len > 0 else 1
    for idx in range(n_chunks - 1):
        ch = bytes(mv[idx * 1024 : (idx + 1) * 1024])
        cv_in, w, c, bl, f = _b3_chunk_output(ch, idx)
        cv = _b3_compress8(cv_in, w, c, bl, f)
        total = idx + 1
        while (total & 1) == 0:
            cv = _b3_compress8(_B3_IV, stack.pop() + cv, 0, 64, _B3_PARENT)
            total >>= 1
        stack.append(cv)
    last_chunk = bytes(mv[(n_chunks - 1) * 1024 :]) if total_len > 0 else b""
    out = _b3_chunk_output(last_chunk, n_chunks - 1)
    while stack:
        cv_in, w, c, bl, f = out
        right_cv = _b3_compress8(cv_in, w, c, bl, f)
        out = (_B3_IV, stack.pop() + right_cv, 0, 64, _B3_PARENT)
    cv_in, w, c, bl, f = out
    return struct.pack("<8I", *_b3_compress8(cv_in, w, c, bl, f | _B3_ROOT))


def blake3_bytes(data: bytes) -> bytes:
    if _native_blake3 is not None:
        return _native_blake3.blake3(data).digest()
    return _blake3_pure(data)


def blake3_hex(data: bytes) -> str:
    return blake3_bytes(data).hex()


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def self_test_blake3() -> None:
    assert _blake3_pure(b"").hex() == "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"
    assert _blake3_pure(b"abc").hex() == "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"


def parse_zstd_frame_limits(payload: bytes) -> tuple[int, int | None]:
    if len(payload) < 5:
        raise ValueError("zstd_malformed: payload shorter than RFC 8878 frame header")
    (magic,) = struct.unpack_from("<I", payload, 0)
    if (magic & ZSTD_SKIPPABLE_MASK) == ZSTD_SKIPPABLE_MAGIC:
        raise ValueError("zstd_malformed: skippable frame at start of WAI zstd payload")
    if magic != ZSTD_MAGIC_LE:
        raise ValueError(f"zstd_malformed: bad magic 0x{magic:08x}")
    fhd = payload[4]
    fcs_flag = (fhd >> 6) & 0x03
    single_segment = (fhd >> 5) & 0x01
    if (fhd >> 3) & 0x01:
        raise ValueError("zstd_malformed: reserved bit set in Frame_Header_Descriptor")
    pos = 5
    window_size: int | None = None
    if not single_segment:
        if pos >= len(payload):
            raise ValueError("zstd_malformed: truncated Window_Descriptor")
        wd = payload[pos]
        pos += 1
        window_base = 1 << (10 + (wd >> 3))
        window_size = window_base + (window_base >> 3) * (wd & 0x07)
        if window_size > TEXT_WINDOW_MAX_LEN:
            raise ValueError(f"text_window_too_large: {window_size} > {TEXT_WINDOW_MAX_LEN}")
    pos += (0, 1, 2, 4)[fhd & 0x03]
    fcs_bytes = (1 if single_segment else 0, 2, 4, 8)[fcs_flag]
    declared_size: int | None = None
    if fcs_bytes > 0:
        if pos + fcs_bytes > len(payload):
            raise ValueError("zstd_malformed: truncated Frame_Content_Size")
        if fcs_bytes == 1:
            declared_size = payload[pos]
        elif fcs_bytes == 2:
            declared_size = struct.unpack_from("<H", payload, pos)[0] + 256
        elif fcs_bytes == 4:
            declared_size = struct.unpack_from("<I", payload, pos)[0]
        else:
            declared_size = struct.unpack_from("<Q", payload, pos)[0]
        if declared_size > TEXT_DECODED_MAX_LEN:
            raise ValueError(f"text_decoded_too_long: {declared_size} > {TEXT_DECODED_MAX_LEN}")
        if single_segment and declared_size > TEXT_WINDOW_MAX_LEN:
            raise ValueError(f"text_window_too_large: {declared_size} > {TEXT_WINDOW_MAX_LEN}")
    return (window_size or declared_size or 0, declared_size)


def zstd_compress_deterministic(data: bytes, level: int = 19) -> bytes:
    if len(data) > TEXT_DECODED_MAX_LEN:
        raise ValueError(f"text_decoded_too_long: {len(data)} > {TEXT_DECODED_MAX_LEN}")
    if _stdlib_zstd is not None:
        out = _stdlib_zstd.compress(data, level=level)
    elif _ext_zstd is not None:
        cctx = _ext_zstd.ZstdCompressor(level=level, write_content_size=True, write_checksum=True)
        out = cctx.compress(data)
    else:
        zstd_bin = shutil.which("zstd")
        if not zstd_bin:
            raise RuntimeError("No Zstandard encoder available")
        out = subprocess.run([zstd_bin, f"-{level}", "-q", "--check", "-c"], input=data, capture_output=True, check=True).stdout
    parse_zstd_frame_limits(out)
    return out


def zstd_decompress_checked(payload: bytes) -> bytes:
    parse_zstd_frame_limits(payload)
    if _stdlib_zstd is not None:
        out = _stdlib_zstd.decompress(payload)
    elif _ext_zstd is not None:
        dctx = _ext_zstd.ZstdDecompressor(max_window_size=TEXT_WINDOW_MAX_LEN)
        out = dctx.decompress(payload, max_output_size=TEXT_DECODED_MAX_LEN + 1)
    else:
        zstd_bin = shutil.which("zstd")
        if not zstd_bin:
            raise RuntimeError("No Zstandard decoder available")
        out = subprocess.run([zstd_bin, "-d", "-q", "-c"], input=payload, capture_output=True, check=True).stdout
    if len(out) > TEXT_DECODED_MAX_LEN:
        raise ValueError(f"text_decoded_too_long: {len(out)} > {TEXT_DECODED_MAX_LEN}")
    return out


def _count_json_values_and_depth(val: Any, depth: int = 1) -> tuple[int, int]:
    if isinstance(val, dict):
        total, max_d = 1, depth
        for child in val.values():
            c_cnt, c_d = _count_json_values_and_depth(child, depth + 1)
            total += c_cnt
            max_d = max(max_d, c_d)
        return total, max_d
    if isinstance(val, list):
        total, max_d = 1, depth
        for child in val:
            c_cnt, c_d = _count_json_values_and_depth(child, depth + 1)
            total += c_cnt
            max_d = max(max_d, c_d)
        return total, max_d
    return 1, depth


def _strict_manifest_parse(manifest_bytes: bytes) -> dict[str, Any]:
    if len(manifest_bytes) > MANIFEST_MAX_LEN:
        raise ValueError(f"manifest_too_large: {len(manifest_bytes)} > {MANIFEST_MAX_LEN}")
    raw_text = manifest_bytes.decode("utf-8")

    def no_duplicate_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        seen: dict[str, Any] = {}
        for k, v in pairs:
            if k in seen:
                raise ValueError(f"manifest_duplicate_member: {k!r}")
            seen[k] = v
        return seen

    def check_int_token(token: str) -> int:
        if token == "-0":
            raise ValueError("manifest_bad_integer: '-0' forbidden")
        return int(token)

    manifest = json.loads(raw_text, object_pairs_hook=no_duplicate_pairs, parse_int=check_int_token)
    if not isinstance(manifest, dict):
        raise ValueError("manifest_malformed: root must be object")
    val_count, max_depth = _count_json_values_and_depth(manifest, depth=1)
    if max_depth > MANIFEST_MAX_DEPTH:
        raise ValueError(f"manifest_too_deep: {max_depth} > {MANIFEST_MAX_DEPTH}")
    if val_count > MANIFEST_MAX_VALUES:
        raise ValueError(f"manifest_too_many_values: {val_count} > {MANIFEST_MAX_VALUES}")
    wai_ver = manifest.get("wai")
    if not isinstance(wai_ver, str) or "." not in wai_ver or wai_ver.split(".")[0] != "1":
        raise ValueError(f"manifest_unsupported_version: {wai_ver!r}")
    for req_str in ("media", "intent"):
        if not isinstance(manifest.get(req_str), str) or not manifest[req_str]:
            raise ValueError(f"manifest_malformed: missing {req_str}")
    mr = manifest.get("model_requirement")
    if not isinstance(mr, dict) or not isinstance(mr.get("capability"), str) or not mr["capability"]:
        raise ValueError("manifest_malformed: missing model_requirement.capability")
    cond = manifest.get("conditioning")
    if not isinstance(cond, dict) or not isinstance(cond.get("kind"), str) or not cond["kind"]:
        raise ValueError("manifest_malformed: missing conditioning.kind")
    return manifest


def build_wai1_envelope(manifest_obj: dict[str, Any], payload_bytes: bytes) -> bytes:
    manifest_bytes = json.dumps(manifest_obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    _strict_manifest_parse(manifest_bytes)
    if len(payload_bytes) > 0xFFFFFFFF:
        raise ValueError("payload_too_large")
    return WAI1_MAGIC + struct.pack("<I", len(manifest_bytes)) + manifest_bytes + struct.pack("<I", len(payload_bytes)) + payload_bytes


def parse_wai1_envelope(wai_bytes: bytes) -> tuple[dict[str, Any], bytes, bytes]:
    if len(wai_bytes) < 12 or wai_bytes[:4] != WAI1_MAGIC:
        raise ValueError("wai1_bad_magic_or_truncated")
    (man_len,) = struct.unpack_from("<I", wai_bytes, 4)
    if man_len > MANIFEST_MAX_LEN or 8 + man_len + 4 > len(wai_bytes):
        raise ValueError("wai1_manifest_bounds")
    manifest_raw = wai_bytes[8 : 8 + man_len]
    manifest = _strict_manifest_parse(manifest_raw)
    (payload_len,) = struct.unpack_from("<I", wai_bytes, 8 + man_len)
    payload_start = 12 + man_len
    if payload_start + payload_len != len(wai_bytes):
        raise ValueError("wai1_payload_len_mismatch")
    return manifest, manifest_raw, wai_bytes[payload_start:]


def load_or_derive_ed25519_signer(signing_key_arg: str | None = None) -> tuple[Ed25519PrivateKey, bytes, str, str]:
    raw_spec = signing_key_arg or os.environ.get("OPENIE_WAI_SIGNING_KEY", "").strip()
    signer_id = os.environ.get("OPENIE_WAI_SIGNER_ID", DEFAULT_SIGNER_ID).strip() or DEFAULT_SIGNER_ID
    if raw_spec:
        if re.fullmatch(r"[0-9a-fA-F]{64}", raw_spec):
            sk = Ed25519PrivateKey.from_private_bytes(bytes.fromhex(raw_spec))
            mode = "configured-seed"
        else:
            loaded = serialization.load_pem_private_key(Path(raw_spec).read_bytes(), password=None)
            if not isinstance(loaded, Ed25519PrivateKey):
                raise ValueError("Not an Ed25519 private key")
            sk = loaded
            mode = "configured-pem"
    else:
        sk = Ed25519PrivateKey.from_private_bytes(blake3_bytes(DETERMINISTIC_SIGNER_DOMAIN))
        mode = "deterministic-platform-v1"
    pk_bytes = sk.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    return sk, pk_bytes, signer_id, mode


def jwp_group_signing_payload(
    *,
    track_alias: int,
    group_id: int,
    root_hash_hex: str,
    leaf_count: int,
    joules_total: int,
    group_start: str,
    group_end: str,
    signer_pubkey_hex: str,
    signer_id: str,
) -> bytes:
    gs_b = group_start.encode("utf-8")
    ge_b = group_end.encode("utf-8")
    sid_b = signer_id.encode("utf-8")
    return (
        JWP_GROUP_SIGN_DOMAIN
        + track_alias.to_bytes(8, "big")
        + group_id.to_bytes(8, "big")
        + bytes.fromhex(root_hash_hex)
        + leaf_count.to_bytes(8, "big")
        + joules_total.to_bytes(8, "big")
        + len(gs_b).to_bytes(4, "big")
        + gs_b
        + len(ge_b).to_bytes(4, "big")
        + ge_b
        + bytes.fromhex(signer_pubkey_hex)
        + len(sid_b).to_bytes(4, "big")
        + sid_b
    )


def artifact_signing_payload(canonical_id: str, content_sha256: str, release_tarball_blake3: str) -> bytes:
    return (
        OPENIE_ARTIFACT_SIGN_DOMAIN
        + b"\x00"
        + canonical_id.encode("utf-8")
        + b"\x00"
        + content_sha256.encode("utf-8")
        + b"\x00"
        + release_tarball_blake3.encode("utf-8")
    )


def release_receipt_signing_payload(
    *,
    version: str,
    envelope_blake3: str,
    envelope_sha256: str,
    tarball_blake3: str,
    tarball_sha256: str,
    artifacts_blake3: str,
    artifacts_sha256: str,
    commons_blake3: str,
    commons_sha256: str,
) -> bytes:
    fields = (
        version,
        envelope_blake3,
        envelope_sha256,
        tarball_blake3,
        tarball_sha256,
        artifacts_blake3,
        artifacts_sha256,
        commons_blake3,
        commons_sha256,
    )
    return OPENIE_RELEASE_SIGN_DOMAIN + b"\x00" + "\x00".join(fields).encode("utf-8")


def derive_release_timestamp(version: str, override: str | None = None) -> str:
    if override:
        return override
    for q, md in ((".Q1", "01-01"), (".Q2", "04-01"), (".Q3", "07-01"), (".Q4", "10-01")):
        if version.endswith(q):
            return f"{version[:-3]}-{md}T00:00:00Z"
    if re.fullmatch(r"v?[0-9]{4}\.[0-9]{2}\.[0-9]{2}", version):
        return f"{version.lstrip('v').replace('.', '-')}T00:00:00Z"
    return "2026-01-01T00:00:00Z"


def make_energy_cost_record(reported_j: float | None, acquisition_class: str = "unmetered") -> dict[str, Any]:
    if reported_j is not None:
        if reported_j < 0:
            raise ValueError("reported_energy_j must be non-negative")
        return {
            "status": "reported_j",
            "reported_j": reported_j,
            "joules_micro": int(round(reported_j * 1_000_000)),
            "acquisition_class": acquisition_class if acquisition_class != "unmetered" else "Estimator",
            "note": "Explicitly reported energy measurement provided at build time.",
        }
    return {
        "status": "unmetered",
        "reported_j": None,
        "joules_micro": 0,
        "acquisition_class": "unmetered",
        "note": "Unmetered build host (joules_micro=0 is the WAI unmetered marker, never a claim of zero physical energy).",
    }


def collect_subsystem_files(repo_root: Path, rel_paths: tuple[str, ...]) -> list[tuple[str, bytes]]:
    collected: list[tuple[str, bytes]] = []
    for rp in rel_paths:
        target = repo_root / rp
        if not target.exists():
            raise ValueError(f"Missing required subsystem path: {target}")
        if target.is_file():
            collected.append((rp, target.read_bytes()))
        elif target.is_dir():
            for child in sorted(target.rglob("*")):
                if child.is_file():
                    rel_child = child.relative_to(repo_root).as_posix()
                    collected.append((rel_child, child.read_bytes()))
    collected.sort(key=lambda item: item[0])
    return collected


def validate_platform_repo(repo_root: Path) -> tuple[dict[str, Any], bytes]:
    for lic_file in ("LICENSE-DATA", "LICENSE-SOFTWARE", "LICENSE-HARDWARE", "ARCHITECTURE.md", "README.md"):
        if not (repo_root / lic_file).is_file():
            raise ValueError(f"Missing required root file: {lic_file}")

    udd_path = repo_root / "descriptor" / "free-humanoid.udd.json"
    if not udd_path.is_file():
        raise ValueError(f"Missing UDD descriptor: {udd_path}")
    udd_obj = json.loads(udd_path.read_text(encoding="utf-8"))
    if udd_obj.get("schema_version") != 1:
        raise ValueError("UDD schema_version must be 1")
    meta = udd_obj.get("meta") or {}
    if meta.get("morphology_family") != "humanoid_bipedal":
        raise ValueError("UDD meta.morphology_family must be 'humanoid_bipedal'")
    robot = udd_obj.get("robot") or {}
    for section in ("links", "joints", "actuator_slots", "modes"):
        if not isinstance(robot.get(section), list) or not robot[section]:
            raise ValueError(f"UDD robot.{section} must be a non-empty list")

    seen_licenses: set[str] = set()
    for spec in SUBSYSTEM_SPECS:
        if spec["license"] not in ALLOWED_TRI_LICENSES:
            raise ValueError(f"Invalid license {spec['license']} on {spec['id']}")
        seen_licenses.add(spec["license"])
        files = collect_subsystem_files(repo_root, spec["paths"])
        if not files:
            raise ValueError(f"Subsystem {spec['id']} resolved to 0 files")
    if seen_licenses != ALLOWED_TRI_LICENSES:
        raise ValueError(f"Tri-license coverage incomplete: {seen_licenses}")

    canonical_udd_bytes = (json.dumps(udd_obj, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")
    return udd_obj, canonical_udd_bytes


def build_canonical_artifacts(
    *,
    repo_root: Path,
    udd_obj: dict[str, Any],
    canonical_udd_bytes: bytes,
    version: str,
    release_timestamp: str,
    tarball_name: str,
    tarball_bytes_len: int,
    tarball_blake3: str,
    tarball_sha256: str,
    wai_filename: str,
    signer_sk: Ed25519PrivateKey,
    signer_pubkey_hex: str,
    signer_id: str,
    energy_record: dict[str, Any],
) -> tuple[list[dict[str, Any]], bytes]:
    timestamp_pointers = {
        "rfc3161_request": "request.tsq",
        "rfc3161_freetsa": "freetsa.tsr",
        "rfc3161_digicert": "digicert.tsr",
        "rfc3161_wai_receipt_request": "wai_receipt.tsq",
        "rfc3161_wai_receipt_freetsa": "wai_receipt.freetsa.tsr",
        "rfc3161_wai_receipt_digicert": "wai_receipt.digicert.tsr",
        "opentimestamps_tarball": f"{tarball_name}.ots",
        "opentimestamps_wai_receipt": "WAI_RECEIPT.json.ots",
        "wai_receipt": "WAI_RECEIPT.json",
    }
    interchange_envelope = {
        "format": "WAI1",
        "wai": "1.0",
        "media_type": "application/vnd.wai",
        "envelope_file": wai_filename,
        "capability": "wai.text.zstd",
        "fallback": None,
        "receipt_file": "WAI_RECEIPT.json",
    }

    records: list[dict[str, Any]] = []
    descriptor_cid: str | None = None
    subsystem_cids: list[str] = []

    robot = udd_obj["robot"]
    actuated_dofs = sum(1 for j in robot["joints"] if j.get("joint_type") != "fixed")

    for idx, spec in enumerate(SUBSYSTEM_SPECS):
        sid = spec["id"]
        files = collect_subsystem_files(repo_root, spec["paths"])
        file_digests = [
            {
                "path": rel_p,
                "bytes": len(fbytes),
                "blake3": blake3_hex(fbytes),
                "sha256": sha256_hex(fbytes),
            }
            for rel_p, fbytes in files
        ]
        if sid == "descriptor":
            payload_obj: dict[str, Any] = {
                "subsystem_id": sid,
                "morphology_number": 17,
                "morphology_name": udd_obj["meta"]["name"],
                "morphology_family": udd_obj["meta"]["morphology_family"],
                "actuated_dof_count": actuated_dofs,
                "link_count": len(robot["links"]),
                "joint_count": len(robot["joints"]),
                "actuator_slot_count": len(robot["actuator_slots"]),
                "mode_count": len(robot["modes"]),
                "corpus_anchors": udd_obj["meta"].get("corpus_anchors", []),
                "license_file": spec["license_file"],
                "files": file_digests,
                "udd_blake3": blake3_hex(canonical_udd_bytes),
                "udd_sha256": sha256_hex(canonical_udd_bytes),
            }
            content_bytes = canonical_udd_bytes
        else:
            payload_obj = {
                "subsystem_id": sid,
                "license": spec["license"],
                "license_file": spec["license_file"],
                "file_count": len(file_digests),
                "total_bytes": sum(d["bytes"] for d in file_digests),
                "files": file_digests,
            }
            content_bytes = json.dumps(payload_obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")

        c_b3 = blake3_hex(content_bytes)
        c_sha = sha256_hex(content_bytes)
        cid = f"blake3:{spec['prefix']}:{c_b3}"
        if sid == "descriptor":
            descriptor_cid = cid
        else:
            subsystem_cids.append(cid)

        parent_cids = [] if sid == "descriptor" else ([descriptor_cid] if descriptor_cid else [])
        parent_ids = [] if sid == "descriptor" else ["descriptor"]
        sig_hex = signer_sk.sign(artifact_signing_payload(cid, c_sha, tarball_blake3)).hex()

        modality_variants = [
            {"modality": "text/plain", "locator": d["path"]}
            for d in file_digests[:12]
        ] + [
            {"modality": "application/vnd.wai", "locator": f"{wai_filename}#subsystem={sid}"},
            {"modality": "application/gzip", "locator": f"{tarball_name}#{sid}"},
        ]

        records.append({
            "schema": "openie.artifact.canonical/v1",
            "artifact_kind": spec["kind"],
            "canonical_id": cid,
            "entry_id": sid,
            "entry_index": idx,
            "version": version,
            "released_at": release_timestamp,
            "title": spec["title"],
            "license": spec["license"],
            "license_file": spec["license_file"],
            "difficulty_rung": {
                "rung": spec["rung"],
                "label": spec["rung_label"],
                "rationale": f"OpenLoco Morphology #17 {sid} subsystem under {spec['license']} ({spec['license_file']})",
            },
            "energy_cost_j": energy_record,
            "verification_status": {
                "passed": True,
                "gate": "udd_schema_v1 + tri_license_spdx_gate",
                "schema_valid": True,
                "tri_license_verified": True,
                "human_in_gate": False,
            },
            "provenance_chain": {
                "content_blake3": c_b3,
                "content_sha256": c_sha,
                "release_tarball": tarball_name,
                "release_tarball_blake3": tarball_blake3,
                "release_tarball_sha256": tarball_sha256,
                "signature_scheme": "ed25519-rfc8032",
                "signing_domain": OPENIE_ARTIFACT_SIGN_DOMAIN.decode("ascii"),
                "signer_id": signer_id,
                "signer_pubkey_ed25519": signer_pubkey_hex,
                "signature_ed25519": sig_hex,
                "lineage_parents": parent_ids,
                "lineage_parent_canonical_ids": parent_cids,
                "lineage_children": [] if sid != "descriptor" else [s["id"] for s in SUBSYSTEM_SPECS if s["id"] != "descriptor"],
                "timestamp_pointers": timestamp_pointers,
            },
            "modality_variants": modality_variants,
            "interchange_envelope": interchange_envelope,
            "payload": payload_obj,
        })

    release_cid = f"blake3:humanoid_morphology:{tarball_blake3}"
    release_sig_hex = signer_sk.sign(artifact_signing_payload(release_cid, tarball_sha256, tarball_blake3)).hex()
    records.append({
        "schema": "openie.artifact.canonical/v1",
        "artifact_kind": "humanoid_morphology_release",
        "canonical_id": release_cid,
        "entry_id": f"platform-release-{version}",
        "entry_index": len(SUBSYSTEM_SPECS),
        "version": version,
        "released_at": release_timestamp,
        "title": f"{PLATFORM_TITLE} Release {version}",
        "license": "CERN-OHL-S-2.0",
        "license_file": "LICENSE-HARDWARE",
        "difficulty_rung": {
            "rung": "R8",
            "label": "Ecology",
            "rationale": "Tri-licensed OpenLoco Morphology #17 release bundle (CC0-1.0 + Apache-2.0 + CERN-OHL-S-2.0)",
        },
        "energy_cost_j": energy_record,
        "verification_status": {
            "passed": True,
            "gate": "udd_schema_v1 + tri_license_spdx_gate",
            "schema_valid": True,
            "tri_license_verified": True,
            "human_in_gate": False,
        },
        "provenance_chain": {
            "content_blake3": tarball_blake3,
            "content_sha256": tarball_sha256,
            "release_tarball": tarball_name,
            "release_tarball_blake3": tarball_blake3,
            "release_tarball_sha256": tarball_sha256,
            "signature_scheme": "ed25519-rfc8032",
            "signing_domain": OPENIE_ARTIFACT_SIGN_DOMAIN.decode("ascii"),
            "signer_id": signer_id,
            "signer_pubkey_ed25519": signer_pubkey_hex,
            "signature_ed25519": release_sig_hex,
            "lineage_parents": [s["id"] for s in SUBSYSTEM_SPECS],
            "lineage_parent_canonical_ids": ([descriptor_cid] if descriptor_cid else []) + subsystem_cids,
            "lineage_children": [],
            "timestamp_pointers": timestamp_pointers,
        },
        "modality_variants": [
            {"modality": "application/gzip", "locator": tarball_name},
            {"modality": "application/vnd.wai", "locator": wai_filename},
            {"modality": "application/x-ndjson", "locator": "artifacts.canonical.jsonl"},
            {"modality": "application/json", "locator": "WAI_RECEIPT.json"},
            {"modality": "application/json", "locator": "commons_ingest_bundle.json"},
        ],
        "interchange_envelope": interchange_envelope,
        "payload": {
            "version": version,
            "morphology_number": 17,
            "tarball_name": tarball_name,
            "tarball_bytes": tarball_bytes_len,
            "tri_license_spdx": ["CC0-1.0", "Apache-2.0", "CERN-OHL-S-2.0"],
            "subsystem_count": len(SUBSYSTEM_SPECS),
            "license_breakdown": {
                "CC0-1.0": [s["id"] for s in SUBSYSTEM_SPECS if s["license"] == "CC0-1.0"],
                "Apache-2.0": [s["id"] for s in SUBSYSTEM_SPECS if s["license"] == "Apache-2.0"],
                "CERN-OHL-S-2.0": [s["id"] for s in SUBSYSTEM_SPECS if s["license"] == "CERN-OHL-S-2.0"],
            },
            "repository": PLATFORM_REPO_URL,
        },
    })

    jsonl_bytes = "".join(json.dumps(r, ensure_ascii=False, separators=(",", ":")) + "\n" for r in records).encode("utf-8")
    return records, jsonl_bytes


def build_commons_ingest_bundle(
    *,
    udd_obj: dict[str, Any],
    canonical_records: list[dict[str, Any]],
    version: str,
    release_timestamp: str,
    wai_filename: str,
    wai_blake3: str,
    wai_sha256: str,
    tarball_name: str,
    tarball_blake3: str,
    tarball_sha256: str,
) -> tuple[dict[str, Any], bytes]:
    base_qids = ["wd:Q584593", "wd:Q159172", "wd:Q1156684"]
    entities = [
        {"id": "wd:Q584593", "label": "humanoid robot", "ty": "concept", "aliases": ["bipedal humanoid", "OpenLoco Morphology #17"]},
        {"id": "wd:Q159172", "label": "open-source hardware", "ty": "concept", "aliases": ["CERN-OHL-S-2.0"]},
        {"id": "wd:Q1156684", "label": "prior art", "ty": "legal_concept", "aliases": ["defensive publication"]},
        {"id": "wd:Q6938433", "label": "CC0", "ty": "license", "aliases": ["CC0-1.0"]},
    ]
    authors = [{"id": "author:free-humanoid-platform", "name": "Free Humanoid Platform Contributors"}]
    venues = [{"id": f"venue:{PLATFORM_SLUG}", "name": PLATFORM_TITLE}]

    works = []
    media_records = []
    idea_atoms = []
    bundle_media = []
    bundle_ideas = []
    native_atoms = []

    yyyymmdd = release_timestamp[:10].replace("-", "")
    year = int(release_timestamp[:4])

    for idx, rec in enumerate(canonical_records, start=1):
        eid = rec["entry_id"]
        wid = f"openie:platform:{eid}"
        mid = f"free_humanoid_platform:{eid}"
        lic = rec["license"]
        title = rec["title"]
        url = f"{PLATFORM_REPO_URL}/tree/main/{eid if eid != f'platform-release-{version}' else ''}".rstrip("/")
        summary = f"{title} [{lic}] — canonical_id {rec['canonical_id'][:40]}..."

        works.append({
            "id": wid,
            "title": title,
            "abstract": summary,
            "year": year,
            "language": "en",
            "author_ids": ["author:free-humanoid-platform"],
            "author_names": ["Free Humanoid Platform Contributors"],
            "venue_id": f"venue:{PLATFORM_SLUG}",
            "concept_ids": base_qids,
            "source": "commons",
        })
        bundle_media.append({
            "id": mid, "kind": "document", "platform": "free_humanoid_platform", "url": url,
            "title": title, "uploader": "Free Humanoid Platform Contributors",
            "upload_date": yyyymmdd, "duration_s": None, "native_language": "en",
            "license": lic, "work_id": wid,
        })
        media_records.append({
            "platform": "free_humanoid_platform", "id": mid, "url": url,
            "title": title, "uploader": "Free Humanoid Platform Contributors",
            "upload_date": yyyymmdd, "duration_s": None, "native_language": "en",
            "available_captions": None, "license": lic,
            "transcript_source": "verified_openie",
            "segments": [{"start": 1.0, "end": 1.0, "text": summary, "source": "verified_openie"}],
            "audio_path": None, "kind": "document",
        })
        bundle_ideas.append({
            "media_id": mid, "statement": summary, "kind": "claim",
            "speaker": "Free Humanoid Platform Contributors",
            "quote": summary, "t_start": 1.0, "t_end": 1.0, "channel": "metadata",
            "source": "verified_openie", "confidence": 1.0,
            "entities": [title, lic], "qids": base_qids, "lang": "en",
        })
        idea_atoms.append({
            "id": f"idea:free_humanoid_platform:{eid}",
            "canonical_id": rec["canonical_id"],
            "statement": summary, "quote": summary,
            "speaker": "Free Humanoid Platform Contributors",
            "channel_owner": "Free Humanoid Platform Contributors",
            "media_id": mid, "modality": "written", "media_kind": "document",
            "platform": "free_humanoid_platform", "title": title,
            "date": release_timestamp[:10], "lang": "en", "citation": url,
            "locator": f"artifacts.canonical.jsonl:{idx}", "t_start": 1.0,
            "source": "verified_openie",
            "entities": [{"id": q, "label": q} for q in base_qids],
        })
        native_atoms.append({
            "media_id": mid, "modality": "structure3d",
            "summary": f"OpenLoco #17 subsystem {eid} ({lic})",
            "locator_spec": f"udd:free_humanoid#{eid}", "t_start": 1.0, "t_end": 1.0,
            "channel": "geometry3d", "source": "d2_mesh_3d", "confidence": 1.0,
            "work_id": wid, "entities": [title, lic],
        })

    citations = [
        {
            "citing": f"openie:platform:{rec['entry_id']}",
            "cited": "openie:platform:descriptor",
            "predicate": "implements_udd_subsystem",
        }
        for rec in canonical_records
        if rec["entry_id"] != "descriptor"
    ]

    bundle_doc = {
        "schema": "openie.commons.ingest_bundle/v1",
        "version": version,
        "license": "CC0-1.0",
        "tri_license_spdx": ["CC0-1.0", "Apache-2.0", "CERN-OHL-S-2.0"],
        "generated_at": release_timestamp,
        "overview": (
            f"{PLATFORM_TITLE} release {version} packages the 33-DoF UDD descriptor in WAI1 container "
            f"{wai_filename} (BLAKE3 {wai_blake3[:16]}...) with {len(canonical_records)} tri-license-tagged canonical records."
        ),
        "wai_envelope": {
            "file": wai_filename, "blake3": wai_blake3, "sha256": wai_sha256,
            "tarball_file": tarball_name, "tarball_blake3": tarball_blake3, "tarball_sha256": tarball_sha256,
        },
        "summary": {
            "subsystems": len(SUBSYSTEM_SPECS),
            "canonical_records": len(canonical_records),
            "corpus_anchors": len(udd_obj["meta"].get("corpus_anchors", [])),
            "works": len(works),
            "citations": len(citations),
            "idea_atoms": len(idea_atoms),
        },
        "media_records": media_records,
        "idea_atoms": idea_atoms,
        "entities": entities,
        "authors": authors,
        "venues": venues,
        "works": works,
        "citations": citations,
        "media": bundle_media,
        "ideas": bundle_ideas,
        "native_atoms": native_atoms,
    }
    return bundle_doc, (json.dumps(bundle_doc, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def build_wai_receipt(
    *,
    version: str,
    release_timestamp: str,
    wai_filename: str,
    wai_bytes: bytes,
    decoded_bytes_len: int,
    decoded_blake3: str,
    decoded_sha256: str,
    tarball_name: str,
    tarball_bytes_len: int,
    tarball_blake3: str,
    tarball_sha256: str,
    artifacts_bytes_len: int,
    artifacts_blake3: str,
    artifacts_sha256: str,
    commons_bytes_len: int,
    commons_blake3: str,
    commons_sha256: str,
    canonical_record_count: int,
    signer_sk: Ed25519PrivateKey,
    signer_pubkey_hex: str,
    signer_id: str,
    signer_key_mode: str,
    energy_record: dict[str, Any],
) -> tuple[dict[str, Any], bytes]:
    env_b3 = blake3_hex(wai_bytes)
    env_sha = sha256_hex(wai_bytes)
    jwp_content_hash = blake3_hex(JWP_OBJECT_DOMAIN + wai_bytes)
    jwp_merkle_root = blake3_hex(JWP_LEAF_DOMAIN + bytes.fromhex(jwp_content_hash))
    joules_micro = int(energy_record.get("joules_micro") or 0)

    jwp_payload = jwp_group_signing_payload(
        track_alias=0, group_id=1, root_hash_hex=jwp_merkle_root, leaf_count=1,
        joules_total=joules_micro, group_start=release_timestamp, group_end=release_timestamp,
        signer_pubkey_hex=signer_pubkey_hex, signer_id=signer_id,
    )
    jwp_sig_bytes = signer_sk.sign(jwp_payload)
    jwp_receipt_link_hash = blake3_hex(JWP_RECEIPT_LINK_DOMAIN + jwp_payload + jwp_sig_bytes)

    jwp_group_receipt = {
        "kind": "group",
        "track_alias": 0,
        "group_id": 1,
        "root_hash": jwp_merkle_root,
        "leaf_count": 1,
        "joules_total": joules_micro,
        "group_start": release_timestamp,
        "group_end": release_timestamp,
        "signer_pubkey": signer_pubkey_hex,
        "signer_id": signer_id,
        "sig": jwp_sig_bytes.hex(),
        "parent_receipt_hash": None,
    }
    jwp_object_receipt = {
        "kind": "object",
        "track_alias": 0,
        "group_id": 1,
        "object_id": 0,
        "content_hash": jwp_content_hash,
        "joules_micro": joules_micro,
        "origin": signer_id,
        "merkle_proof": {"siblings": [], "direction_bits": 0, "leaf_index": 0},
    }

    rel_sig_hex = signer_sk.sign(
        release_receipt_signing_payload(
            version=version, envelope_blake3=env_b3, envelope_sha256=env_sha,
            tarball_blake3=tarball_blake3, tarball_sha256=tarball_sha256,
            artifacts_blake3=artifacts_blake3, artifacts_sha256=artifacts_sha256,
            commons_blake3=commons_blake3, commons_sha256=commons_sha256,
        )
    ).hex()

    receipt_doc: dict[str, Any] = {
        "schema": "openie.wai.receipt/v1",
        "version": version,
        "released_at": release_timestamp,
        "license": "CC0-1.0",
        "tri_license_spdx": ["CC0-1.0", "Apache-2.0", "CERN-OHL-S-2.0"],
        "platform": PLATFORM_SLUG,
        "morphology_number": 17,
        "canonical_records": canonical_record_count,
        "envelope": {
            "file": wai_filename, "format": "WAI1", "wai": "1.0",
            "capability": "wai.text.zstd", "fallback": None,
            "wrapped_document": "descriptor/free-humanoid.udd.json",
            "wrapped_license": "CC0-1.0",
            "bytes": len(wai_bytes), "blake3": env_b3, "sha256": env_sha,
            "jwp_content_hash_blake3": jwp_content_hash,
            "jwp_merkle_root_blake3": jwp_merkle_root,
            "jwp_receipt_link_blake3": jwp_receipt_link_hash,
            "decoded_bytes": decoded_bytes_len,
            "decoded_blake3": decoded_blake3,
            "decoded_sha256": decoded_sha256,
        },
        "artifacts": {
            tarball_name: {"bytes": tarball_bytes_len, "blake3": tarball_blake3, "sha256": tarball_sha256},
            "artifacts.canonical.jsonl": {"bytes": artifacts_bytes_len, "blake3": artifacts_blake3, "sha256": artifacts_sha256},
            wai_filename: {"bytes": len(wai_bytes), "blake3": env_b3, "sha256": env_sha},
            "commons_ingest_bundle.json": {"bytes": commons_bytes_len, "blake3": commons_blake3, "sha256": commons_sha256},
        },
        "energy_cost_j": energy_record,
        "signature": {
            "scheme": "ed25519-rfc8032",
            "signing_domain": OPENIE_RELEASE_SIGN_DOMAIN.decode("ascii"),
            "signer_id": signer_id,
            "key_mode": signer_key_mode,
            "signer_pubkey_ed25519": signer_pubkey_hex,
            "release_sig_ed25519": rel_sig_hex,
        },
        "jwp_group_receipt": jwp_group_receipt,
        "jwp_object_receipt": jwp_object_receipt,
        "offline_verify_command": f"python3 tools/emit_wai_commons.py --verify releases/{version}",
    }
    return receipt_doc, (json.dumps(receipt_doc, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def write_checksum_files(release_dir: Path, ordered_files: list[str]) -> None:
    sha_lines, b3_lines = [], []
    for fname in ordered_files:
        data = (release_dir / fname).read_bytes()
        sha_lines.append(f"{sha256_hex(data)}  {fname}\n")
        b3_lines.append(f"{blake3_hex(data)}  {fname}\n")
    (release_dir / "SHA256SUMS").write_text("".join(sha_lines), encoding="utf-8")
    (release_dir / "BLAKE3SUMS").write_text("".join(b3_lines), encoding="utf-8")


def verify_offline(target: Path, quiet: bool = False) -> dict[str, Any]:
    self_test_blake3()
    if target.is_dir():
        release_dir = target
        wai_candidates = sorted(release_dir.glob("free-humanoid-*.wai"))
        if not wai_candidates:
            raise ValueError(f"No free-humanoid-*.wai file found in {release_dir}")
        wai_path = wai_candidates[0]
    elif target.is_file():
        wai_path = target
        release_dir = target.parent
    else:
        raise ValueError(f"Verification target not found: {target}")

    wai_bytes = wai_path.read_bytes()
    manifest, manifest_raw, payload = parse_wai1_envelope(wai_bytes)
    cap = manifest["model_requirement"]["capability"]
    decoded = zstd_decompress_checked(payload) if cap == "wai.text.zstd" else payload
    decoded_udd = json.loads(decoded.decode("utf-8"))
    if decoded_udd.get("meta", {}).get("morphology_family") != "humanoid_bipedal":
        raise ValueError("Decoded WAI1 payload is not valid OpenLoco humanoid_bipedal UDD")
    dec_sha, dec_b3 = sha256_hex(decoded), blake3_hex(decoded)
    env_b3, env_sha = blake3_hex(wai_bytes), sha256_hex(wai_bytes)

    receipt_path = release_dir / "WAI_RECEIPT.json"
    verified_records = 0
    seen_licenses: set[str] = set()
    if receipt_path.exists():
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        env_meta = receipt["envelope"]
        if env_meta["blake3"] != env_b3 or env_meta["sha256"] != env_sha:
            raise ValueError("WAI_RECEIPT envelope hash mismatch")
        if env_meta["decoded_blake3"] != dec_b3 or env_meta["decoded_sha256"] != dec_sha:
            raise ValueError("WAI_RECEIPT decoded UDD hash mismatch")

        expected_jwp_obj = blake3_hex(JWP_OBJECT_DOMAIN + wai_bytes)
        expected_jwp_root = blake3_hex(JWP_LEAF_DOMAIN + bytes.fromhex(expected_jwp_obj))
        grp = receipt["jwp_group_receipt"]
        obj = receipt["jwp_object_receipt"]
        mp = obj.get("merkle_proof")
        if not isinstance(mp, dict) or mp.get("siblings") != [] or mp.get("direction_bits") != 0 or mp.get("leaf_index") != 0:
            raise ValueError("JWP object merkle_proof malformed")
        if obj["content_hash"] != expected_jwp_obj or grp["root_hash"] != expected_jwp_root:
            raise ValueError("JWP content/root hash mismatch")

        vk = Ed25519PublicKey.from_public_bytes(bytes.fromhex(receipt["signature"]["signer_pubkey_ed25519"]))
        jwp_pay = jwp_group_signing_payload(
            track_alias=int(grp["track_alias"]), group_id=int(grp["group_id"]),
            root_hash_hex=grp["root_hash"], leaf_count=int(grp["leaf_count"]),
            joules_total=int(grp["joules_total"]), group_start=grp["group_start"],
            group_end=grp["group_end"], signer_pubkey_hex=grp["signer_pubkey"],
            signer_id=grp["signer_id"],
        )
        try:
            vk.verify(bytes.fromhex(grp["sig"]), jwp_pay)
        except InvalidSignature as exc:
            raise ValueError("JWP group signature invalid") from exc

        art_table = receipt["artifacts"]
        for fname, meta in art_table.items():
            fbytes = (release_dir / fname).read_bytes()
            if len(fbytes) != meta["bytes"] or blake3_hex(fbytes) != meta["blake3"] or sha256_hex(fbytes) != meta["sha256"]:
                raise ValueError(f"Artifact digest mismatch for {fname}")

        version = receipt["version"]
        tarball_name = f"platform-{version}.tar.gz"
        rel_pay = release_receipt_signing_payload(
            version=version, envelope_blake3=env_b3, envelope_sha256=env_sha,
            tarball_blake3=art_table[tarball_name]["blake3"], tarball_sha256=art_table[tarball_name]["sha256"],
            artifacts_blake3=art_table["artifacts.canonical.jsonl"]["blake3"],
            artifacts_sha256=art_table["artifacts.canonical.jsonl"]["sha256"],
            commons_blake3=art_table["commons_ingest_bundle.json"]["blake3"],
            commons_sha256=art_table["commons_ingest_bundle.json"]["sha256"],
        )
        vk.verify(bytes.fromhex(receipt["signature"]["release_sig_ed25519"]), rel_pay)

        tar_b3 = art_table[tarball_name]["blake3"]
        canon_lines = (release_dir / "artifacts.canonical.jsonl").read_text(encoding="utf-8").splitlines()
        for lineno, line in enumerate(canon_lines, start=1):
            if not line.strip():
                continue
            rec = json.loads(line)
            lic = rec.get("license")
            if lic not in ALLOWED_TRI_LICENSES:
                raise ValueError(f"Record {lineno}: invalid license {lic!r}")
            seen_licenses.add(lic)
            if rec["verification_status"].get("human_in_gate") is not False:
                raise ValueError(f"Record {lineno}: human_in_gate must be false")
            prov = rec["provenance_chain"]
            cid = rec["canonical_id"]
            eid = rec["entry_id"]
            if eid == "descriptor":
                expected_b3, expected_sha = dec_b3, dec_sha
                expected_prefix = "humanoid_morphology"
            elif rec["artifact_kind"] == "humanoid_morphology_release":
                expected_b3, expected_sha = tar_b3, art_table[tarball_name]["sha256"]
                expected_prefix = "humanoid_morphology"
            else:
                pbytes = json.dumps(rec["payload"], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
                expected_b3, expected_sha = blake3_hex(pbytes), sha256_hex(pbytes)
                expected_prefix = "hardware_subsystem"
            if cid != f"blake3:{expected_prefix}:{expected_b3}":
                raise ValueError(f"Record {lineno} ({eid}): canonical_id mismatch")
            vk.verify(bytes.fromhex(prov["signature_ed25519"]), artifact_signing_payload(cid, expected_sha, tar_b3))
            verified_records += 1

        if seen_licenses != ALLOWED_TRI_LICENSES:
            raise ValueError(f"Tri-license set incomplete in canonical records: {seen_licenses}")

        for sums_name, fn in (("SHA256SUMS", sha256_hex), ("BLAKE3SUMS", blake3_hex)):
            sp = release_dir / sums_name
            if sp.exists():
                for line in sp.read_text(encoding="utf-8").splitlines():
                    if line.strip():
                        digest, fname = line.split("  ", 1)
                        if fn((release_dir / fname).read_bytes()) != digest:
                            raise ValueError(f"{sums_name} mismatch for {fname}")

    if not quiet:
        print(f"  PASS: WAI1 UDD header & SPEC §2 limits ({len(manifest_raw)} B manifest, {len(payload)} B payload)")
        print(f"  PASS: Envelope BLAKE3 `{env_b3}` -> {verified_records} tri-licensed signed records ({sorted(seen_licenses)})")
    return {"ok": True, "envelope_blake3": env_b3, "verified_records": verified_records}


def sync_commons_scholar(*, release_dir: Path, version: str, commons_url: str | None = None, dry_run: bool = False, offline: bool = False) -> None:
    if offline:
        return
    base_raw = commons_url or os.environ.get("COMMONS_BASE_URL", "").strip() or DEFAULT_COMMONS_URL
    base_url = re.sub(r"/api/.*$", "", base_raw.rstrip("/")) or DEFAULT_COMMONS_URL
    if dry_run:
        print(f"  [commons] dry-run: ready-to-ingest bundle at {release_dir / 'commons_ingest_bundle.json'}")
        return
    req = urllib.request.Request(f"{base_url}/api/stats", headers={"User-Agent": f"{PLATFORM_SLUG}/{version}"}, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=4.0) as resp:
            print(f"  [commons] health ping {base_url}/api/stats -> HTTP {resp.status}")
    except (urllib.error.URLError, TimeoutError, OSError):
        print(f"  [commons] health ping {base_url}/api/stats unreachable; continuing non-blocking")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=f"Emit and verify WAI1 UDD envelopes for {PLATFORM_TITLE}.")
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--verify", metavar="PATH")
    parser.add_argument("--push-commons-only", action="store_true")
    parser.add_argument("--version")
    parser.add_argument("--release-dir")
    parser.add_argument("--tarball")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--encoding", choices=("zstd", "utf8"), default="zstd")
    parser.add_argument("--timestamp")
    parser.add_argument("--signing-key")
    parser.add_argument("--reported-energy-j", type=float, default=None)
    parser.add_argument("--energy-class", default="unmetered")
    parser.add_argument("--push-commons", action="store_true")
    parser.add_argument("--commons-url")
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    if args.validate_only:
        try:
            udd_obj, _ = validate_platform_repo(Path(args.repo_root))
            print(f"  UDD morphology: {udd_obj['meta']['name']} ({len(udd_obj['robot']['joints'])} joints, {len(SUBSYSTEM_SPECS)} tri-licensed subsystems)")
            return 0
        except Exception as exc:
            print(f"VALIDATION FAILED: {exc}", file=sys.stderr)
            return 1

    if args.verify:
        try:
            verify_offline(Path(args.verify))
            return 0
        except Exception as exc:
            print(f"VERIFY FAILED: {exc}", file=sys.stderr)
            return 1

    if args.push_commons_only:
        sync_commons_scholar(release_dir=Path(args.release_dir), version=args.version, commons_url=args.commons_url, dry_run=args.dry_run, offline=args.offline)
        return 0

    if not args.version or not args.release_dir or not args.tarball:
        parser.error("Emission requires --version, --release-dir, and --tarball")

    self_test_blake3()
    version = args.version
    repo_root = Path(args.repo_root)
    release_dir = Path(args.release_dir)
    tarball_path = Path(args.tarball)
    release_dir.mkdir(parents=True, exist_ok=True)
    release_ts = derive_release_timestamp(version, args.timestamp)

    udd_obj, canonical_udd_bytes = validate_platform_repo(repo_root)
    udd_b3, udd_sha = blake3_hex(canonical_udd_bytes), sha256_hex(canonical_udd_bytes)

    tar_bytes = tarball_path.read_bytes()
    tar_b3, tar_sha = blake3_hex(tar_bytes), sha256_hex(tar_bytes)
    tarball_name = tarball_path.name
    wai_filename = f"free-humanoid-{version}.wai"

    energy_rec = make_energy_cost_record(args.reported_energy_j, args.energy_class)
    signer_sk, signer_pk_bytes, signer_id, signer_mode = load_or_derive_ed25519_signer(args.signing_key)
    signer_pk_hex = signer_pk_bytes.hex()

    canon_records, canon_bytes = build_canonical_artifacts(
        repo_root=repo_root, udd_obj=udd_obj, canonical_udd_bytes=canonical_udd_bytes,
        version=version, release_timestamp=release_ts,
        tarball_name=tarball_name, tarball_bytes_len=len(tar_bytes),
        tarball_blake3=tar_b3, tarball_sha256=tar_sha,
        wai_filename=wai_filename,
        signer_sk=signer_sk, signer_pubkey_hex=signer_pk_hex, signer_id=signer_id,
        energy_record=energy_rec,
    )
    (release_dir / "artifacts.canonical.jsonl").write_bytes(canon_bytes)
    canon_b3, canon_sha = blake3_hex(canon_bytes), sha256_hex(canon_bytes)

    wai_payload = zstd_compress_deterministic(canonical_udd_bytes, level=19) if args.encoding == "zstd" else canonical_udd_bytes
    manifest_obj = {
        "wai": "1.0",
        "media": "text",
        "intent": "replicate",
        "model_requirement": {"capability": "wai.text.zstd" if args.encoding == "zstd" else "wai.text.utf8", "fallback": None},
        "conditioning": {"kind": "zstd" if args.encoding == "zstd" else "utf8"},
        "security": {"encryption": "none", "kid": 0},
        "target": {
            "schema": "openloco.udd/v1",
            "format": "application/vnd.openloco.udd+json",
            "encoding": "utf-8",
            "platform": PLATFORM_SLUG,
            "morphology_number": 17,
            "version": version,
            "license": "CC0-1.0",
            "decoded_bytes": len(canonical_udd_bytes),
            "decoded_sha256": udd_sha,
            "decoded_blake3": udd_b3,
        },
    }
    wai_bytes = build_wai1_envelope(manifest_obj, wai_payload)
    (release_dir / wai_filename).write_bytes(wai_bytes)
    wai_b3, wai_sha = blake3_hex(wai_bytes), sha256_hex(wai_bytes)

    _, commons_bytes = build_commons_ingest_bundle(
        udd_obj=udd_obj, canonical_records=canon_records, version=version, release_timestamp=release_ts,
        wai_filename=wai_filename, wai_blake3=wai_b3, wai_sha256=wai_sha,
        tarball_name=tarball_name, tarball_blake3=tar_b3, tarball_sha256=tar_sha,
    )
    (release_dir / "commons_ingest_bundle.json").write_bytes(commons_bytes)
    commons_b3, commons_sha = blake3_hex(commons_bytes), sha256_hex(commons_bytes)

    _, receipt_bytes = build_wai_receipt(
        version=version, release_timestamp=release_ts, wai_filename=wai_filename, wai_bytes=wai_bytes,
        decoded_bytes_len=len(canonical_udd_bytes), decoded_blake3=udd_b3, decoded_sha256=udd_sha,
        tarball_name=tarball_name, tarball_bytes_len=len(tar_bytes), tarball_blake3=tar_b3, tarball_sha256=tar_sha,
        artifacts_bytes_len=len(canon_bytes), artifacts_blake3=canon_b3, artifacts_sha256=canon_sha,
        commons_bytes_len=len(commons_bytes), commons_blake3=commons_b3, commons_sha256=commons_sha,
        canonical_record_count=len(canon_records),
        signer_sk=signer_sk, signer_pubkey_hex=signer_pk_hex, signer_id=signer_id,
        signer_key_mode=signer_mode, energy_record=energy_rec,
    )
    (release_dir / "WAI_RECEIPT.json").write_bytes(receipt_bytes)

    write_checksum_files(release_dir, [
        tarball_name, "artifacts.canonical.jsonl", wai_filename, "WAI_RECEIPT.json", "commons_ingest_bundle.json",
    ])
    verify_offline(release_dir, quiet=True)
    print(f"  Canonical OpenIE JSONL: {release_dir / 'artifacts.canonical.jsonl'} ({len(canon_records)} tri-license records)")
    print(f"  WAI1 UDD Envelope:      {release_dir / wai_filename} ({len(wai_bytes)} bytes, BLAKE3 {wai_b3[:16]}...)")
    if args.push_commons or args.dry_run:
        sync_commons_scholar(release_dir=release_dir, version=version, commons_url=args.commons_url, dry_run=args.dry_run, offline=args.offline)
    return 0


if __name__ == "__main__":
    sys.exit(main())
