# -*- coding: utf-8 -*-
"""生成 fsl2_test.pcap：覆盖 fsl2_tcms_protocol.lua 各解析路径。
依据规范 FSL02-JK-10028 (ISCS-PIS-TCMS)，帧头0x7F/帧尾0x7E，校验和=序号起求和取低字节。
用法: python gen_fsl2_test.py
"""
import struct

HEAD, TAIL = 0x7F, 0x7E
DST_MAC = bytes.fromhex("001122334455")
SRC_MAC = bytes.fromhex("66778899aabb")
SRC_IP = bytes([10, 0, 0, 2])
DST_IP = bytes([10, 0, 0, 1])
DPORT = 18030


def udp_packet(payload, sport=20000):
    """构造 以太网/IPv4/UDP 报文，目标端口 18030。"""
    udp_len = 8 + len(payload)
    ip_len = 20 + udp_len
    eth = DST_MAC + SRC_MAC + b"\x08\x00"
    ip = (b"\x45\x00" + struct.pack(">H", ip_len) + b"\x00\x00" + b"\x40\x00"
          + b"\x40\x11" + b"\x00\x00" + SRC_IP + DST_IP)
    udp = struct.pack(">HHHH", sport, DPORT, udp_len, 0)
    return eth + ip + udp + payload


def frame(seq, device, msgtype, start, content):
    """按规范组帧: 头 序号 设备 类型 起始地址(2) 内容 crc 尾。"""
    body = bytes([seq, device, msgtype]) + struct.pack(">H", start) + bytes(content)
    return bytes([HEAD]) + body + bytes([sum(body) & 0xFF, TAIL])


# 校验和算法与规范原文示例互证 (规范 3.2.3)
assert sum(bytes([0x01, 0xF0, 0x01, 0x00, 0x00, 0xC0, 0xA8, 0x00, 0x01])) & 0xFF == 0x5B  # 会话示例
assert sum(bytes([0x01, 0xF5, 0x04, 0x00, 0x00, 0x01])) & 0xFF == 0xFB                  # 确认回复示例
assert sum(bytes([0x06, 0xF5, 0x02, 0x00, 0x00])) & 0xFF == 0xFD                        # 心跳示例
assert sum(bytes([0x06, 0xF0, 0x04, 0x00, 0x00, 0x01])) & 0xFF == 0xFB                  # ISCS确认示例
print("校验和算法与规范示例一致")

spec_session = frame(0x01, 0xF0, 0x01, 0, [0xC0, 0xA8, 0x00, 0x01])          # 12B 会话(192.168.0.1)
spec_ack     = frame(0x01, 0xF5, 0x04, 0, [0x01])                            # 9B   PIS确认
spec_hb      = frame(0x06, 0xF5, 0x02, 0, [])                                # 8B   心跳
spec_ack_i   = frame(0x06, 0xF0, 0x04, 0, [0x01])                            # 9B   ISCS确认
train_ok     = frame(0x05, 0x01, 0x10, 90, list(range(30)))                  # 38B 数据信令,地址90
train_bad    = frame(0x06, 0x02, 0x10, 100, list(range(30)))                 # 38B 数据信令,地址非30倍数
unknown      = frame(0x07, 0x02, 0x07, 0, [1, 2, 3, 4])                      # 10B 未知类型
bad_crc      = spec_session[:-2] + bytes([spec_session[-2] + 1]) + spec_session[-1:]  # 校验和错误

packets = [
    spec_session,                       # 1 会话, IP 192.168.0.1
    spec_ack,                           # 2 PIS确认
    spec_hb,                            # 3 心跳
    spec_ack_i,                         # 4 ISCS确认
    train_ok,                           # 5 数据信令, 起始地址30整数倍
    train_bad,                          # 6 数据信令, 起始地址非30整数倍 -> WARN
    spec_session + spec_ack,            # 7 一个数据报含多条消息
    unknown,                            # 8 未知类型, 整段消耗
    spec_session + b"\xDE\xAD\xBE",     # 9 会话后跟3字节垃圾尾部
    spec_session + bytes([0xDE] * 6),   # 10 帧头错位 -> invalid head
    b"\x7F\x09\xF0\x01\x00\x00\x11\xBB",  # 11 截断(需12只有8)
    b"\x7F\x0A\xF0\x01",                # 12 不足6字节 -> data_dis
    bad_crc,                            # 13 校验和错误 -> FAIL
]

out = []
out.append(struct.pack("<IHHiIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
for i, payload in enumerate(packets):
    fr = udp_packet(payload)
    out.append(struct.pack("<IIII", 0, i, len(fr), len(fr)) + fr)

with open("fsl2_test.pcap", "wb") as f:
    f.write(b"".join(out))
print("wrote fsl2_test.pcap with %d packets" % len(packets))
