# Wireshark Lua 插件开发教程

本教程基于轨道交通信号系统协议解析插件实践编写，涵盖从入门到实战的完整开发流程。

---

## 目录

1. [入门基础](#1-入门基础)
2. [核心概念](#2-核心概念)
3. [字段定义](#3-字段定义)
4. [枚举与中文解读](#4-枚举与中文解读)
5. [分包重组](#5-分包重组)
6. [实战：完整插件示例](#6-实战完整插件示例)
7. [调试与测试](#7-调试与测试)
8. [最佳实践](#8-最佳实践)

---

## 1. 入门基础

### 1.1 插件安装位置

| 系统 | 插件目录 |
|------|----------|
| Windows | `%APPDATA%\Wireshark\plugins\` |
| macOS | `~/Library/Application Support/Wireshark/plugins/` |
| Linux | `~/.wireshark/plugins/` |

### 1.2 插件基本结构

```lua
-- 插件名: XXX Protocol
-- 版本: 1.0.0
-- 作者: XXX
-- 描述: 协议说明

local cq15_protocol = Proto("CQL15", "CQL15 Protocol")
```

**关键元素：**
- `Proto(name, fullname)` — 定义协议对象
- `ProtoField` — 定义字段
- `dissector(buffer, pinfo, tree)` — 核心解析函数
- `DissectorTable` — 端口注册表

---

## 2. 核心概念

### 2.1 Proto 对象

```lua
-- 定义协议
local my_proto = Proto("MYPROTO", "My Protocol")

-- 定义首选项（用户可配置）
local prefs = my_proto.prefs
prefs.my_port = Pref.string("端口号:", "5000", "默认TCP端口")
prefs.my_version = Pref.statictext("version:1.0.0", "版本号")
```

**Pref 类型：**

| 类型 | 用途 |
|------|------|
| `Pref.string` | 字符串配置 |
| `Pref.uint` | 无符号整数 |
| `Pref.int` | 有符号整数 |
| `Pref.bool` | 布尔开关 |
| `Pref.statictext` | 只读文本 |

### 2.2 dissector 函数签名

```lua
function my_proto.dissector(buffer, pinfo, tree)
    -- buffer: 协议数据缓冲区 (Tvb)
    -- pinfo:  包信息 (PacketInfo)
    -- tree:   树节点 (TreeItem)
end
```

### 2.3 注册到端口

```lua
-- TCP 注册
local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(5000, my_proto)

-- UDP 注册
local udp_port = DissectorTable.get("udp.port")
udp_port:add(5000, my_proto)
```

### 2.4 端口变更响应

```lua
function my_proto.prefs_changed()
    -- 用户修改首选项后重新注册端口
    tcp_port:remove(5000, my_proto)
    tcp_port:add(5000, my_proto)
end
```

---

## 3. 字段定义

### 3.1 ProtoField 类型

```lua
-- 创建工具函数（参考项目中的 sf, u8, u16 等）
local function sf(name, desc)   -- ASCII 字符串
    return ProtoField.string("myproto." .. name, desc, base.ASCII)
end

local function u8(name, desc)   -- 无符号字节
    return ProtoField.uint8("myproto." .. name, desc, base.DEC)
end

local function u16(name, desc)  -- 无符号字（小端）
    return ProtoField.uint16("myproto." .. name, desc, base.DEC)
end

local function u16x(name, desc) -- 无符号字（十六进制）
    return ProtoField.uint16("myproto." .. name, desc, base.HEX)
end

local function u32(name, desc)  -- 无符号双字
    return ProtoField.uint32("myproto." .. name, desc, base.DEC)
end

local function bf(name, desc)   -- 字节序列
    return ProtoField.bytes("myproto." .. name, desc)
end
```

### 3.2 字段注册

```lua
local pf = {
    seq       = ProtoField.uint16("myproto.seq", "序号", base.DEC),
    data_type = ProtoField.uint8("myproto.data_type", "类型", base.DEC),
    data_len  = ProtoField.uint16("myproto.data_len", "长度", base.DEC),
    crc       = ProtoField.uint16("myproto.crc", "CRC校验", base.HEX),
}
```

**注意：** 字段名格式为 `协议名.字段名`，过滤时可按 `myproto.*` 过滤。

### 3.3 向树添加字段

```lua
-- 基本用法
tree:add(pf.seq, buffer(offset, 2))

-- 带文本标注
tree:add(pf.seq, buffer(offset, 2)):set_text(
    "序号[seq](2bytes),字节序(" .. offset .. "):" .. buffer(offset, 2):uint()
)

-- 嵌套子树
local sub_tree = tree:add(buffer(offset, 10), "子结构(10bytes)")
sub_tree:add(pf.seq, buffer(offset, 2))
```

---

## 4. 枚举与中文解读

### 4.1 定义枚举表

```lua
local enum_drive = {
    ["0"] = "手动驾驶",
    ["1"] = "自动驾驶",
    ["2"] = "限制手动",
    ["3"] = "非限制手动",
}
```

### 4.2 解析辅助函数

```lua
-- 通用枚举解释函数
local function desc(value, enum_table)
    if not enum_table then return "" end
    local label = enum_table[value]
    return label and (" [" .. label .. "]") or ""
end

-- 在字段添加时使用
tree:add(pf.drive_mode, buffer(offset, 1))
    :set_text("驾驶模式:" .. value .. desc(value, enum_drive))
```

---

## 5. 分包重组

### 5.1 TCP Desegment

```lua
-- 检测分包并请求更多数据
function parse_tcp(buffer, pinfo, tree)
    local buf_len = buffer:len()
    local b_offset = pinfo.desegment_offset or 0
    
    -- 读取消息总长度（根据协议定）
    local total_len = read_total_length(buffer, b_offset)
    
    if buf_len < total_len then
        -- 数据不完整，请求更多
        pinfo.desegment_len = b_offset + total_len - buf_len
        pinfo.desegment_offset = b_offset
        return false  -- 返回 false 表示未解析完成
    end
    
    -- 数据完整，继续解析
    local subtree = tree:add(my_proto, buffer(b_offset, total_len), "My Protocol")
    -- ... 解析逻辑
    return true
end
```

### 5.2 判断方向

```lua
-- 根据端口判断消息方向
local function is_from_server(pinfo)
    return pinfo.srcport == 5000
end
```

---

## 6. 实战：完整插件示例

以下是一个完整的协议解析插件模板：

```lua
-- 插件名: Demo Protocol
-- 版本: 1.0.0
-- 描述: Wireshark Lua 插件开发示例

-- 1. 定义协议
local demo_proto = Proto("DEMO", "Demo Protocol")

-- 2. 定义首选项
local prefs = demo_proto.prefs
prefs.my_port = Pref.string("端口号:", "5000", "TCP端口")

-- 3. 定义字段
local pf = {
    header_id   = ProtoField.uint8("demo.header_id", "头部标识", base.HEX),
    seq         = ProtoField.uint16("demo.seq", "序号", base.DEC),
    data_type   = ProtoField.uint8("demo.data_type", "消息类型", base.DEC),
    data_len    = ProtoField.uint16("demo.data_len", "数据长度", base.DEC),
    payload     = ProtoField.bytes("demo.payload", "数据内容"),
    crc         = ProtoField.uint16("demo.crc", "CRC校验", base.HEX),
}

-- 4. 定义枚举
local enum_type = {
    [1] = "请求",
    [2] = "响应",
    [3] = "心跳",
}

-- 5. 解析函数
local function parse_message(buffer, offset, tree)
    -- 解析头部
    tree:add(pf.header_id, buffer(offset, 1))
    tree:add(pf.seq, buffer(offset + 1, 2))
    tree:add(pf.data_type, buffer(offset + 3, 1))
    tree:add(pf.data_len, buffer(offset + 4, 2))
    
    -- 解析数据
    local msg_type = buffer(offset + 3, 1):uint()
    local data_len = buffer(offset + 6, 2):uint()
    local payload_offset = offset + 8
    
    if data_len > 0 then
        tree:add(pf.payload, buffer(payload_offset, data_len))
    end
    
    -- 解析CRC
    tree:add(pf.crc, buffer(payload_offset + data_len, 2))
end

-- 6. 主解析函数
function demo_proto.dissector(buffer, pinfo, tree)
    local buf_len = buffer:len()
    if buf_len < 12 then return end  -- 最小长度校验
    
    -- 设置协议列
    pinfo.cols.protocol:set("DEMO")
    pinfo.cols.info:set("Demo Protocol")
    
    -- 分包处理
    local total_len = buffer(4, 2):uint() + 8
    if buf_len < total_len then
        pinfo.desegment_len = total_len - buf_len
        return
    end
    
    -- 添加树节点
    local subtree = tree:add(demo_proto, buffer(0, total_len), "Demo Protocol")
    parse_message(buffer, 0, subtree)
end

-- 7. 注册端口
local tcp_port = DissectorTable.get("tcp.port")
local function add_port()
    tcp_port:remove(5000, demo_proto)
    if prefs.my_port ~= "" then
        tcp_port:add(tonumber(prefs.my_port), demo_proto)
    end
end
add_port()
demo_proto.prefs_changed = add_port
```

---

## 7. 调试与测试

### 7.1 测试数据生成

```python
# test/gen_demo.py
import struct

def build_message(seq, msg_type, data=b''):
    header = struct.pack('>H', 8 + len(data))  # 长度
    header += struct.pack('>B', 0xAA)           # 头部标识
    header += struct.pack('>H', seq)            # 序号
    header += struct.pack('>B', msg_type)       # 类型
    return header + data

# 生成测试包
msg = build_message(1, 1, b'\x01\x02\x03\x04')
with open('test.pcapng', 'wb') as f:
    # 写入 pcapng 格式
    pass
```

### 7.2 过滤表达式

```
# 按协议过滤
demo.*

# 按字段过滤
demo.seq == 1
demo.data_type == 1

# 组合过滤
demo.seq > 0 and demo.data_type == 2
```

### 7.3 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 协议不显示 | 端口未注册 | 检查 `DissectorTable` 注册 |
| 字段值为空 | 偏移量错误 | 用 `buffer(offset, len):uint()` 验证 |
| 分包丢失 | desegment 逻辑错误 | 检查 `desegment_len` 计算 |
| 中文乱码 | 编码问题 | 使用 `base.ASCII` 或指定编码 |

---

## 8. 最佳实践

### 8.1 代码组织

```lua
-- 推荐结构
-- 1. 协议定义
-- 2. 首选项定义
-- 3. 字段定义（带工具函数）
-- 4. 枚举定义
-- 5. 解析函数
-- 6. 主 dissector
-- 7. 端口注册
-- 8. 首选项变更回调
```

### 8.2 性能优化

```lua
-- 使用局部变量缓存常用对象
local uint = buffer(offset, 2):uint  -- 函数引用
local string = buffer(offset, n):string

-- 避免重复计算
local total_len = buffer(4, 2):uint() + 8
```

### 8.3 错误处理

```lua
if buffer:len() < MIN_LEN then
    return
end

local val = buffer(offset, len)
if val == nil then
    return
end
```

### 8.4 文档规范

```lua
-- 插件名: 协议名称
-- 版本: X.Y.Z#日期-序号
-- 作者: 姓名
-- 描述: 协议说明
--       字段格式: 编号.名称(Nbytes),字节序(X):值 [过滤器名]
-- 更新时间: YYYY-MM-DD
```

---

## 参考资源

- [Wireshark Lua API 文档](https://www.wireshark.org/docs/man-pages/wireshark-lua.html)
- [Wireshark Lua 插件示例](https://wiki.wireshark.org/Lua/Examples)
- [Lua 语言参考](https://www.lua.org/manual/5.4/)

---

*本教程基于轨道交通信号系统协议解析插件实践编写。*
