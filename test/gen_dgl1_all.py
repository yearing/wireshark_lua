#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 DGL1 全部消息类型测试 pcap
# 帧: EF EF | Frame_Count1 | Frame_Index1 | Data_Len2(LE) | Data | FD FD
# 消息: Message_Len2(LE) | Time7 | Line_Id2(LE) | Validity1 | Spare17 | Msg_Id1 | version1 | Content
# 全部多字节 LE。端口: ATS服务端 2100。
import struct

def time7(y=2024, mo=9, d=21, h=15, mi=29, s=30):
    return struct.pack("<HBBBBB", y, mo, d, h, mi, s)

SPARE17 = b"\x00" * 17

def message(msg_id, content, line=144, validity=0, mtime=time7()):
    body = mtime + struct.pack("<H", line) + bytes([validity]) + SPARE17 + bytes([msg_id, 0x01])
    mlen = len(body) + len(content)          # 消息长度 = 时间..content, 不包括长度本身
    return struct.pack("<H", mlen) + body + content

def frame(data, count=1, index=1):
    return b"\xEF\xEF" + bytes([count, index]) + struct.pack("<H", len(data)) + data + b"\xFD\xFD"

# ---- 0x01 心跳: Content = Spare(8) ----
m01 = message(0x01, b"\x00" * 8)

# ---- 0x03 站台到站列车 ----
def train03():
    t = bytes([1])                    # Validity=1
    t += bytes([3]) + b"001"          # Train_id len=3
    t += bytes([3]) + b"201"          # Server_number
    t += bytes([2]) + b"01"           # Order_number
    t += bytes([3]) + b"010"          # Destination_code
    t += bytes([1])                   # Pre_arrival
    t += time7()                      # Scheduled_arrival
    t += time7(2024, 9, 21, 15, 30, 0)# Scheduled_depart
    t += struct.pack("<i", 60)        # Otp_time +60s晚点
    t += bytes([1, 0, 1, 0, 0, 0, 6]) # Arr,Dep,Hold,Skip,Out,Last,Comp
    t += struct.pack("<H", 123)       # Driver_Number
    t += bytes([1])                   # Passenger 载客
    t += struct.pack("<H", 10)        # Destination_Id
    t += bytes([0, 0, 1])             # Oper,TrainProp,Extend(计划清客bit0)
    t += b"\x00\x00"                  # Spare
    return t
m03 = message(0x03, bytes([1]) + bytes([10]) + struct.pack("<H", 7) + train03() + bytes([0, 0]))

# ---- 0x05 列车位置 ----
def train05():
    t = bytes([3]) + b"001"           # Train_id
    t += bytes([3]) + b"201"          # Server
    t += bytes([2]) + b"01"           # Order
    t += bytes([3]) + b"010"          # Dest
    t += struct.pack("<HHHH", 1, 10, 9, 9)  # Rtu,Station,Up,Down
    t += bytes([1])                   # ActiveTC TC1
    t += bytes([1])                   # Direction 下行
    t += bytes([0, 0, 0, 1, 0])       # Transfer,On_Transfer,TurnBack,On_Platform,Lost
    t += struct.pack("<HH", 50, 100)  # Logic,Physic
    t += bytes([1, 6])                # Window,Compartment
    t += struct.pack("<H", 123)       # Driver
    t += bytes([0])                   # Timeout
    t += struct.pack("<i", -30)       # Otp 早30s
    t += time7() + time7(2024, 9, 21, 15, 30, 0)  # Arrive,Depart
    t += bytes([0x01])                # Drive AM
    t += bytes([0x55])                # IsOpenDoor 开门
    t += bytes([0x55])                # IsStopped 停稳
    t += bytes([0x01])                # Control 连续式
    t += bytes([0x00])                # NonPullBack
    t += bytes([0x55])                # EB 无
    t += bytes([50, 60])              # Rate 50%  Speed 60
    t += bytes([0x55, 0, 0, 0, 0])    # StopDev,SNOW,FIRE,Derail,PlatTimeout
    t += struct.pack("<H", 12) + bytes([1])  # FirstRoute,Exist
    assert len(t) == 58 + (3+1)+(3+1)+(2+1)+(3+1), len(t)
    return t
m05 = message(0x05, bytes([1]) + train05())

# ---- 0x07 供电 / 0x08 火灾 / 0x13 水位 ----
m07 = message(0x07, struct.pack("<H", 2) + struct.pack("<HB", 1, 3) + struct.pack("<HB", 2, 4))
m08 = message(0x08, struct.pack("<H", 2) + struct.pack("<HB", 1, 1) + struct.pack("<HB", 2, 0))
m13 = message(0x13, struct.pack("<H", 1) + struct.pack("<HB", 5, 1))

# ---- 0x0E 越站命令 (1组19字节) ----
m0e = message(0x0E, bytes([10]) + struct.pack("<HHHH", 7, 3001, 201, 1) + b"\x00" * 10)

# ---- 0x10 设备状态全体 ----
def dev_bitmap():
    t = struct.pack("<HH", 1, 2)      # rtu_id, Type_cnt
    t += struct.pack("<HH", 8, 1)     # Type=信号机, obj=1
    t += struct.pack("<II", 100, 0x00000001)   # 红灯亮
    t += struct.pack("<HH", 9, 2)     # Type=道岔, obj=2
    t += struct.pack("<II", 200, 0x00000060)   # 定位+反位
    t += struct.pack("<II", 201, 0x08000002)   # 联锁占用+失表
    return t
m10 = message(0x10, dev_bitmap())

# ---- 0x11 外部报警(客流2级, 车站10) ----
m11 = message(0x11, bytes([0x01, 2, 0x02]) + struct.pack("<H", 10))

# ---- 帧1-9: 各消息一帧; 帧10: 一帧多消息; 帧11-12: 跨帧(0x10拆2帧) ----
f1  = frame(m01, 1, 1)   # 心跳 ISCS->SIG (方向测试)
f2  = frame(m03, 1, 1)   # 站台到站
f3  = frame(m05, 1, 1)   # 列车位置
f4  = frame(m07, 1, 1)   # 供电
f5  = frame(m08, 1, 1)   # 火灾
f6  = frame(m0e, 1, 1)   # 越站
f7  = frame(m10, 1, 1)   # 设备状态(单帧)
f8  = frame(m11, 1, 1)   # 外部报警
f9  = frame(m13, 1, 1)   # 水位
f10 = frame(m01 + m07, 1, 1)  # 一帧含心跳+供电两条消息
split = 20
f11 = frame(m10[:split], 2, 1)  # 跨帧第1片
f12 = frame(m10[split:], 2, 2)  # 跨帧第2片

def make_pcap(frames):
    out = struct.pack("<IHHiIII", 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1)
    for i, fr in enumerate(frames):
        pl, sp, dp = fr[0], fr[1], fr[2]
        seq = fr[3] if len(fr) > 3 else 1000  # 可选显式seq(跨帧同连接需连续)
        eth = b"\x00\x11\x22\x33\x44\x55" + b"\x66\x77\x88\x99\xaa\xbb" + b"\x08\x00"
        total = 20 + 20 + len(pl)
        ip = struct.pack("!BBHHHBBH4s4s", 0x45, 0, total, 1, 0, 64, 6, 0,
                         b"\x0a\x00\x00\x01", b"\x0a\x00\x00\x02")
        tcp = struct.pack("!HHIIBBHHH", sp, dp, seq, 2000, 0x50, 0x18, 8192, 0, 0)
        pkt = eth + ip + tcp + pl
        out += struct.pack("<IIII", 20260810 + i, i * 1000, len(pkt), len(pkt)) + pkt
    return out

# 方向: SIG=2100. 心跳/供电/火灾/报警/水位 由 ISCS->SIG
frames = [
    (f1,  41000, 2100),
    (f2,  2100, 40001),
    (f3,  2100, 40002),
    (f4,  41001, 2100),
    (f5,  41002, 2100),
    (f6,  2100, 40003),
    (f7,  2100, 40004),
    (f8,  41003, 2100),
    (f9,  41004, 2100),
    (f10, 41005, 2100),
    (f11, 2100, 40006, 1000),   # 跨帧第1片(同连接, seq连续)
    (f12, 2100, 40006, 1000 + len(f11)),  # 跨帧第2片
]
with open("dgl1_all.pcap", "wb") as f:
    f.write(make_pcap(frames))
print("wrote dgl1_all.pcap,", len(frames), "frames")
