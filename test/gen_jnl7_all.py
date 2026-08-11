#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 jnl7 全部消息类型的测试 pcap（12 帧，类型19 双向）
import struct

def crc2hex(bs):
    s = sum(bs) & 0xFF
    return ("%02X" % s).encode("ascii")  # 高位在前，如 0x21 -> b"21"

def time19(date="2009-01-05", t="09:10:34"):
    return date.encode() + b"\x00" + t.encode()

def msg(type_str, seq, body):
    """body = send_time + 数据域(不含CRC). 长度域=send_time+数据+CRC, 即 total-10.
    CRC 覆盖 信息头标识+序号+类型+长度+body（即 dissector 的 [0, parse_crc)）。"""
    length = len(body) + 2
    head = b"\x01" + seq + type_str + b"%05d" % length
    crc = crc2hex(head + body)
    return head + body + crc

def pad(s, n):
    return s.encode() + b"\x00" * (n - len(s))

# ============ 类型01 列车运行信息及列车阻塞信息 (SIG->ISCS, 3列车) ============
def train01(i, tnum):
    t = b"%04d" % (1000 + i)          # 车组号4
    t += b"%03d" % (200 + i)          # 服务号3
    t += b"001"                       # 司机号3
    t += b"1" if i % 2 else b"0"      # CBTC 1
    t += b"1"                         # 位置 正线
    t += b"1"                         # 运行于 上行
    t += b"%03d" % (30 + i)           # 车站号3
    t += pad("T%04d" % (100 + i), 10) # 区段名称10
    t += b"1"                         # 阻塞
    t += b"1"                         # 方向 左向
    t += pad("314%02d" % i, 10)       # 线段ID10
    t += pad("%08d" % (34160 + i), 8) # 偏移量8(cm)
    t += b"1"                         # EB
    t += b"1"                         # 早晚点 晚点
    t += b"0"                         # 扣车
    t += b"1"                         # 立即停车
    t += b"0"                         # 清客
    t += b"1"                         # 跳停
    t += b"1"                         # 休眠
    t += b"0"                         # 唤醒
    t += b"4" if i % 2 else b"9"      # 驾驶模式 AM/EUM
    t += b"1"                         # 湿轨
    t += b"1"                         # 工况 进入正线服务
    assert len(t) == 57, ("train01", len(t))
    return t

def make_01():
    b = time19() + b"03" + b"".join(train01(i, n) for i, n in enumerate([1, 2, 3]))
    return msg(b"01", b"01", b)

# ============ 类型02 站台信息 (SIG->ISCS, 2列车) ============
def train02(i):
    t = b"%04d" % (2000 + i)          # 车组号4
    t += b"%03d" % (300 + i)          # 服务号3
    t += b"0"                         # 首班
    t += b"0"                         # 末班
    t += b"1"                         # 站台状态 到站
    t += time19(t="%02d:10:34" % (9 + i))  # 到站
    t += time19(t="%02d:11:34" % (9 + i))  # 离站
    t += b"007"                       # 终点站号3
    t += b"1"                         # 运行于
    t += b"011"                       # 目的地码3
    t += b"1"                         # 方向
    t += b"1"                         # 非载客
    t += b"1"                         # 接近
    t += b"0"                         # 轧道
    t += b"1"                         # 扣车
    t += b"0"                         # 跳停
    t += b"2"                         # 清客 计划清客
    assert len(t) == 62, ("train02", len(t))
    return t

def make_02():
    b = time19() + b"010" + b"1" + b"0" + b"02" + b"".join(train02(i) for i in range(2))
    return msg(b"02", b"02", b)

# ============ 类型06 当天使用的时刻表 (SIG->ISCS, 2行程x2站台) ============
def platform06(s):
    p = b"%03d" % (10 + s)            # 车站号3
    p += b"%d" % (1 + s % 2)          # 站台号1
    p += time19(t="08:0%d:00" % s)    # 到达19
    p += time19(t="08:0%d:30" % s)    # 离站19
    assert len(p) == 42, ("plat06", len(p))
    return p

def trip06(m):
    tp = b"%02d" % (m + 1)            # 序列号2
    tp += b"011"                      # 目的地码3
    tp += b"02"                       # 站台数量2
    return tp + b"".join(platform06(s) for s in range(2))

def make_06():
    b = time19() + b"002" + b"001" + b"201" + b"02" + b"".join(trip06(m) for m in range(2))
    return msg(b"06", b"03", b)

# ============ 类型07 SCADA供电区段 (ISCS->SIG, 5区段) ============
def make_07():
    b = time19() + b"05" + b"".join([b"1", b"2", b"1", b"0", b"2"])  # 已供电/未供电/未知
    return msg(b"07", b"04", b)

# ============ 类型08 回执信息 (双向, 无数据域) ============
def make_08():
    return msg(b"08", b"05", time19())

# ============ 类型09 心跳信息 (双向, 无数据域) ============
def make_09():
    return msg(b"09", b"00", time19())

# ============ 类型15 客流信息 (ISCS->SIG, 3车站+总客流) ============
def make_15():
    b = time19() + b"04" + b"".join(b"%08d" % (90000 + i) for i in range(4))
    return msg(b"15", b"06", b)

# ============ 类型17 站台运营载客首末班车信息 (SIG->ISCS) ============
def make_17():
    b = time19() + b"010" + b"1"
    b += time19(t="06:30:00")         # 首班发车
    b += b"044"                       # 首班终点
    b += time19(t="22:30:00")         # 末班发车
    b += b"044"                       # 末班终点
    return msg(b"17", b"07", b)

# ============ 类型19 段场出入库信息 (SIG->ISCS) ============
def make_19_sig():
    b = time19() + b"2001"            # 车组号4
    b += b"2"                         # 位置 车辆段
    b += pad("G3105", 10)             # 当前轨道
    b += pad("G0305", 10)             # 库线股道
    b += b"1"                         # 出库
    return msg(b"19", b"08", b)

# ============ 类型19 FAS火灾信息 (ISCS->SIG, 3点位) ============
def make_19_iscs():
    b = time19() + b"003" + b"".join([b"1", b"2", b"1"])  # 激活/未激活/激活
    return msg(b"19", b"09", b)

# ============ 类型21 区间超水位信息 (ISCS->SIG, 3区间) ============
def make_21():
    b = time19() + b"003" + b"".join([b"1", b"2", b"2"])  # 超高/非超高
    return msg(b"21", b"10", b)

# ============ 类型39 信号设备状态信息 (SIG->ISCS, 5类设备) ============
def make_39():
    b = time19() + b"010" + b"0005"
    # 设备1 信号机: 引导+CBTC = 0x0340
    b += b"1" + pad("T2101", 24) + b"\x03\x40"
    # 设备2 道岔: 反位+锁闭+单锁 = 0x000D (bit4=0定位,bit3=1反位,bit2=1锁闭,bit1=1单锁)
    b += b"2" + pad("W101", 24) + b"\x00\x0d"
    # 设备3 区段: 右锁+左锁+占用+封锁 = 0x000F
    b += b"3" + pad("S301", 24) + b"\x00\x0f"
    # 设备4 SPKS: 激活+旁路 = 0x0003
    b += b"4" + pad("SPK01", 24) + b"\x00\x03"
    # 设备5 联锁机: 正常 = 0x0000
    b += b"5" + pad("CBI01", 24) + b"\x00\x00"
    return msg(b"39", b"11", b)

# ============ 封装 Ethernet/IPv4/TCP ============
def frame(payload, src_port, dst_port, seq):
    eth = b"\x00\x11\x22\x33\x44\x55" + b"\x66\x77\x88\x99\xaa\xbb" + b"\x08\x00"
    total = 20 + 20 + len(payload)
    ip = struct.pack("!BBHHHBBH4s4s", 0x45, 0, total, 1, 0, 64, 6, 0,
                     b"\x0a\x00\x00\x01", b"\x0a\x00\x00\x02")
    tcp = struct.pack("!HHIIBBHHH", src_port, dst_port, seq, 2000, 0x50, 0x18, 8192, 0, 0)
    return eth + ip + tcp + payload

# 类型19方向: SIG端口=5000
# 每帧独立TCP连接: 源端口各不相同, seq均从0起。避免同连接seq间隙被当作TCP缺段。
frames = [
    (make_01(),  5000, 40000),  # 01 SIG->ISCS
    (make_02(),  5000, 40001),  # 02 SIG->ISCS
    (make_06(),  5000, 40002),  # 06 SIG->ISCS
    (make_07(),  41001, 5000),  # 07 ISCS->SIG
    (make_08(),  5000, 40003),  # 08 回执 SIG->ISCS
    (make_09(),  41002, 5000),  # 09 心跳 ISCS->SIG
    (make_15(),  41003, 5000),  # 15 ISCS->SIG
    (make_17(),  5000, 40004),  # 17 SIG->ISCS
    (make_19_sig(), 5000, 40005),  # 19 SIG->ISCS 出入库
    (make_19_iscs(), 41004, 5000), # 19 ISCS->SIG FAS
    (make_21(),  41005, 5000),  # 21 ISCS->SIG
    (make_39(),  5000, 40006),  # 39 SIG->ISCS
]

def write_pcap(path, frames):
    with open(path, "wb") as f:
        f.write(struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1))
        for i, (pl, sp, dp) in enumerate(frames):
            pkt = frame(pl, sp, dp, 1000)  # 每帧独立连接, seq 统一 1000
            f.write(struct.pack("<IIII", 20260810 + i, i * 1000, len(pkt), len(pkt)))
            f.write(pkt)
    print(f"wrote {path}: {len(frames)} frames")

write_pcap("jnl7_all.pcap", frames)
for i, (pl, sp, dp) in enumerate(frames):
    print(f"  frame{i+1}: type={pl[3:5].decode()} total={len(pl)}B  {sp}->{dp}")
