#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 CQL15 测试 pcap（含心跳、类型01、类型02）
import struct
import time

def crc2hex(bs):
    s = sum(bs) & 0xFF
    return ("%02X" % s).encode("ascii")

def time19(date="2026-08-13", t="18:00:00"):
    return date.encode() + b"\x00" + t.encode()

def msg(type_str, seq, body):
    length = len(body) + 2
    head = b"\x01" + seq + type_str.encode() + b"%05d" % length
    crc = crc2hex(head + body)
    return head + body + crc

def make_pcap(pkts):
    import struct
    import binascii
    data = b""
    # pcap global header
    data += struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1)  # microsecond, snaplen
    for ts, pkt in pkts:
        ts_sec = int(ts)
        ts_usec = int((ts % 1) * 1000000)
        incl_len = len(pkt)
        orig_len = len(pkt)
        data += struct.pack("<IIII", ts_sec, ts_usec, incl_len, orig_len)
        data += pkt
    return data

# 生成测试包（模拟 CQL15 协议格式）
pkts = []
base_time = 1723552800  # 2026-08-13 18:00:00 UTC

# 心跳包 (09)
for i in range(5):
    ts = base_time + i * 30  # 每30秒一个心跳
    body = time19()
    pkt = msg("09", struct.pack(">H", i+1), body)
    pkts.append((ts + 0.0, pkt))

# 类型01 列车运行信息 (SIG→ISCS)
for i in range(3):
    ts = base_time + 10 + i * 5
    body = time19() + struct.pack(">H", 3) + b"\x00" * 48  # 3列车
    pkt = msg("01", struct.pack(">H", i+10), body)
    pkts.append((ts + 0.0, pkt))

# 类型02 站台信息 (ISCS→SIG)
for i in range(2):
    ts = base_time + 25 + i * 8
    body = time19() + struct.pack(">H", 2) + b"\x00" * 60  # 2站台
    pkt = msg("02", struct.pack(">H", i+20), body)
    pkts.append((ts + 0.0, pkt))

# 添加一个异常包（序号重号）
ts = base_time + 50
body = time19() + b"\x00" * 10
pkt = msg("01", struct.pack(">H", 10), body)  # 重号 10
pkts.append((ts + 0.0, pkt))

# 写入 pcap
import os
outpath = os.path.join(os.path.dirname(__file__), "cql15_test.pcap")
with open(outpath, "wb") as f:
    f.write(make_pcap(pkts))
print(f"Generated {outpath} with {len(pkts)} packets")
