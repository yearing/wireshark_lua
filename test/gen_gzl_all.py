# -*- coding: utf-8 -*-
"""生成 gzl_all.pcap：覆盖 gzl1822_1012_ats_protocol.lua 各解析路径。
依据 gzl18_ats.md / gzl10_ats.md 帧格式:
    帧头(0xEF 0xEF | total1 | index1 | data_len2 LE | dev_status1 | data | 0xFD 0xFD)
    应用帧: Type(2B LE) + Content
用法: python gen_gzl_all.py
"""
import struct

DST_MAC = bytes.fromhex("001122334455")
SRC_MAC = bytes.fromhex("66778899aabb")
SRC_IP = bytes([10, 0, 0, 2])
DST_IP = bytes([10, 0, 0, 1])
ATS_PORT = 10020


def t7(y, mo, d, h, mi, s):
    return struct.pack("<HBBBBB", y, mo, d, h, mi, s)


def frame(data, total=1, index=1, dev=1):
    """底层帧: 帧头 total index data_len(LE) dev_status data 帧尾"""
    return (b"\xef\xef" + bytes([total, index])
            + struct.pack("<H", len(data)) + bytes([dev])
            + data + b"\xfd\xfd")


def app(ttype, content=b""):
    """应用帧: Type(2B LE) + content"""
    return struct.pack("<H", ttype) + content


def train_common(g, o, direction, station, sec, off, eb, block, sleep, work,
                 auth, dep, cam, clearpl, ou, jump, fire):
    """列车信息公共部分(GZL18/GZL10共有): 车组号长度+车组号 ... 火灾报警状态"""
    return (bytes([len(g)]) + g.encode() + bytes([len(o)]) + o.encode()
            + bytes([direction]) + struct.pack("<H", station)
            + struct.pack("<H", sec) + struct.pack("<I", off)
            + bytes([eb, block]) + struct.pack("<H", sleep)
            + bytes([work, auth, dep, cam]) + struct.pack("<I", clearpl)
            + bytes([ou, jump, fire]))


def train_tail10(drive, acc, spd):
    """GZL10列车尾部: 驾驶模式1 停车精度2 速度2 预留10"""
    return bytes([drive]) + struct.pack("<H", acc) + struct.pack("<H", spd) + bytes(10)


def name(n):
    """ASCII 长度前缀字符串: 长度1 + 内容"""
    return bytes([len(n)]) + n.encode()


# ---------- 消息内容 ----------
HB = struct.pack("<I", 0xFFFFFFFF)  # 0x01 心跳
REQ = struct.pack("<I", 0)          # 0x09 首末班申请

# 0x02 列车 GZL18 (2列车)
g18 = app(0x02, struct.pack("<H", 2)
          + train_common("T001", "101", 1, 5, 100, 1234, 0x55, 0, 0x01FF, 3, 0x55, 0xAA, 0xFF, 0, 0xFF, 0xAA, 0xFF)
          + train_common("GZ002", "102", 2, 6, 101, 5678, 0xAA, 1, 0x0402, 0, 0xFF, 0x55, 0x55, 200, 0x55, 0x55, 0x55))

# 0x02 列车 GZL10 (1列车, 含15字节尾)
g10 = app(0x02, struct.pack("<H", 1)
          + train_common("T010", "201", 1, 7, 200, 999, 0x55, 0, 0x0204, 4, 0xFF, 0xAA, 0xFF, 10, 0x55, 0xAA, 0x55)
          + train_tail10(0x05, 32, 800))

# 0x03 计划信息 (1站台1趟)
plan = app(0x03, struct.pack("<H", 1)
           + struct.pack("<H", 10) + bytes([1]) + struct.pack("<H", 1)
           + name("P001") + name("201") + bytes([0])
           + t7(2026, 8, 13, 10, 0, 0) + t7(2026, 8, 13, 10, 2, 0)
           + struct.pack("<H", 15) + bytes([0, 0, 0, 0, 0]) + struct.pack("<H", 0) + bytes([0, 0]))

# 0x04 首末班 (1站台)
fl = app(0x04, struct.pack("<H", 1)
         + struct.pack("<H", 20) + bytes([2])
         + name("F001") + name("301") + bytes([0])
         + t7(2026, 8, 13, 6, 0, 0) + t7(2026, 8, 13, 6, 1, 0) + struct.pack("<H", 30)
         + name("L001") + name("302") + bytes([1])
         + t7(2026, 8, 13, 23, 0, 0) + t7(2026, 8, 13, 23, 1, 0) + struct.pack("<H", 30))

# 0x05 车门隔离 (28字节, 大端)
door05 = app(0x05, struct.pack(">II", 1, 100) + bytes(8)
             + struct.pack(">II", 0, 0) + bytes(8))

# 0x06 站台门隔离 (站台个数1 + 44字节/站台, 大端)
pd = (bytes([1]) + struct.pack(">II", 1, 100) + bytes(8) + bytes(8)
      + struct.pack(">II", 0, 0) + bytes(8) + bytes(8))
door06 = app(0x06, pd)

# 0x07 站场表示: RTU1 + 车站个数1 + 站码4 + 信息长2 + 设备(类型1+编号4+色码长1+色码N)
logic_sec = bytes([0x11]) + struct.pack("<I", 1) + bytes([4]) + bytes([0x04, 0, 0, 0])   # 锁闭
sw = bytes([0x14]) + struct.pack("<I", 2) + bytes([4]) + bytes([0x12, 0, 0, 0])          # 占用+定位
sig = bytes([0x21]) + struct.pack("<I", 3) + bytes([2]) + bytes([(0x03 << 1) | 1, 0x0C]) # 低位红 + 高位黄, 室外关闭
esb = bytes([0x52]) + struct.pack("<I", 4) + bytes([1]) + bytes([0x02])                  # 站台紧急关闭
flood = bytes([0x62]) + struct.pack("<I", 5) + bytes([1]) + bytes([0x0E])                # 关门+请求+允许
devices = logic_sec + sw + sig + esb + flood
yard = app(0x07, bytes([1, 1]) + struct.pack("<I", 100) + struct.pack("<H", len(devices)) + devices)

# 0x08 供电分区 (2区段)
power = app(0x08, struct.pack("<H", 2)
            + struct.pack("<H", 1) + bytes([1])
            + struct.pack("<H", 2) + bytes([2]))

# 0x10 场段出入段计划 (1服务组)
depot = app(0x10,
            t7(2026, 8, 13, 0, 0, 0) + name("GZ001") + struct.pack("<H", 100) + bytes([1])
            + name("S001") + struct.pack("<H", 200)
            + name("301") + name("T001") + name("GOUT1")
            + t7(2026, 8, 13, 5, 30, 0) + t7(2026, 8, 13, 5, 31, 0) + bytes([1])
            + name("CONV1")
            + t7(2026, 8, 13, 5, 40, 0) + t7(2026, 8, 13, 5, 41, 0)
            + t7(2026, 8, 13, 5, 45, 0) + t7(2026, 8, 13, 5, 46, 0) + bytes([1])
            + struct.pack("<H", 300) + t7(2026, 8, 13, 6, 0, 0) + b"DEST"
            + struct.pack("<H", 400) + name("401") + name("T001")
            + name("GIN1")
            + t7(2026, 8, 13, 23, 30, 0) + t7(2026, 8, 13, 23, 31, 0) + bytes([1])
            + name("CONV2")
            + t7(2026, 8, 13, 23, 40, 0) + t7(2026, 8, 13, 23, 41, 0)
            + t7(2026, 8, 13, 23, 45, 0) + t7(2026, 8, 13, 23, 46, 0) + bytes([1])
            + struct.pack("<H", 500) + t7(2026, 8, 13, 0, 0, 0) + b"DES2"
            + bytes([1]) + t7(2026, 8, 13, 0, 0, 0)
            + bytes([1]) + bytes(2)
            + bytes([1]) + t7(2026, 8, 13, 4, 0, 0)
            + bytes([1]) + t7(2026, 8, 13, 3, 0, 0) + t7(2026, 8, 13, 3, 30, 0)
            + bytes([1]) + bytes(10))

# 0x11/0x12/0x13 简单循环
fire_st = app(0x11, struct.pack("<H", 2) + struct.pack("<H", 1) + bytes([1]) + struct.pack("<H", 2) + bytes([2]))
fire_iv = app(0x12, struct.pack("<H", 1) + struct.pack("<H", 10) + bytes([1]))
water   = app(0x13, struct.pack("<H", 1) + struct.pack("<H", 20) + bytes([1]))

# 未知类型 (回退原始数据)
unknown = app(0xFF, bytes([1, 2, 3, 4]))

# 跨帧重组: 将 GZL10 列车信息拆成2帧
g10_raw = struct.pack("<H", 1) + train_common("T010", "201", 1, 7, 200, 999, 0x55, 0, 0x0204, 4, 0xFF, 0xAA, 0xFF, 10, 0x55, 0xAA, 0x55) + train_tail10(0x05, 32, 800)
half = len(g10_raw) // 2
chunk1 = struct.pack("<H", 0x02) + g10_raw[:half]
chunk2 = g10_raw[half:]

packets = [
    frame(app(0x01, HB)),                 # 1  心跳
    frame(g18),                            # 2  GZL18列车信息
    frame(g10),                            # 3  GZL10列车信息
    frame(plan),                           # 4  计划信息
    frame(fl),                             # 5  首末班
    frame(door05),                         # 6  车门隔离
    frame(door06),                         # 7  站台门隔离
    frame(yard),                           # 8  站场表示
    frame(power),                          # 9  供电分区
    frame(app(0x09, REQ)),                 # 10 首末班申请
    frame(depot),                          # 11 场段出入段计划
    frame(fire_st),                        # 12 车站火灾
    frame(fire_iv),                        # 13 区间火灾
    frame(water),                          # 14 区间轨面水位
    frame(unknown),                        # 15 未知类型
    frame(chunk1, total=2, index=1),       # 16 跨帧-片断1
    frame(chunk2, total=2, index=2),       # 17 跨帧-片断2
    frame(app(0x08, struct.pack("<H", 1) + struct.pack("<H", 3) + bytes([0])), dev=2),  # 18 备机供电分区
]

# 结构性自检: 跨帧片断拼接应等于完整应用帧
assert chunk1 + chunk2 == app(0x02, g10_raw), "跨帧重组字节不一致"
print("跨帧重组自检通过, 拆分=%d/%d" % (half, len(g10_raw)))


# ---------- TCP 封装 ----------
def tcp_segment(payload, src_port, dst_port, seq, ack=1000):
    """以太网/IPv4/TCP 段(无校验和, tshark 可正常解析)"""
    eth = DST_MAC + SRC_MAC + b"\x08\x00"
    ip = (b"\x45\x00" + struct.pack(">H", 20 + 20 + len(payload))
          + b"\x00\x00" + b"\x40\x00" + b"\x40\x06" + b"\x00\x00"
          + SRC_IP + DST_IP)
    tcp = struct.pack(">HHIIBBHHH", src_port, dst_port, seq, ack, 0x50, 0x18, 8192, 0, 0)
    return eth + ip + tcp + payload


def build_stream(payloads, src_port, dst_port, seq):
    segs = []
    for p in payloads:
        segs.append(tcp_segment(p, src_port, dst_port, seq))
        seq = (seq + len(p)) & 0xFFFFFFFF
    return segs, seq


# 流A: ISCS→ATS (GZL10列车/供电/心跳/申请/火灾/水位)
sA, _ = build_stream([frame(app(0x01, HB)), frame(g10), frame(power),
                      frame(app(0x09, REQ)), frame(fire_st), frame(fire_iv), frame(water)], 20000, 10020, 1000)
# 流B: ATS→ISCS (GZL18列车/计划/首末班/车门/站台门/站场/出入段/未知/跨帧)
sB, _ = build_stream([frame(g18), frame(plan), frame(fl), frame(door05), frame(door06),
                      frame(yard), frame(depot), frame(unknown),
                      frame(chunk1, total=2, index=1), frame(chunk2, total=2, index=2)], 10020, 20003, 1000)
# 流C: 单段拆分测试 (一条供电帧拆成2个TCP段, 验证desegment)
split_data = frame(power)
sC, _ = build_stream([split_data[:12], split_data[12:]], 20001, 10020, 1000)
# 流D: 备机帧
sD, _ = build_stream([frame(app(0x08, struct.pack("<H", 1) + struct.pack("<H", 3) + bytes([0])), dev=2)], 20002, 10020, 1000)

out = []
out.append(struct.pack("<IHHiIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
i = 0
for seg in sA + sB + sC + sD:
    out.append(struct.pack("<IIII", 0, i, len(seg), len(seg)) + seg)
    i += 1

with open("gzl_all.pcap", "wb") as f:
    f.write(b"".join(out))
print("wrote gzl_all.pcap with %d packets" % i)
