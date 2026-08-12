--[[
    FSL2 TCMS (ISCS-PIS) 协议解析插件
    依据文档: FSL02-JK-10028-ISCS-PIS-TCMS协议文件 (佛山地铁2号线)
    UDP 承载，端口可配置(默认 ISCS 收:18010, PIS 收:18030)

    消息格式 (规范 3.2.2):
        数据帧头(0x7F) 消息序号(1) 设备序号(1) 消息类型(1) 起始地址(2) 消息内容(N) 包校验(1) 数据帧尾(0x7E)
    字节序: 大端(网络字节序)
    包校验: 从消息序号到消息内容结束求和，取低字节
]]

-- 协议对象，Wireshark 过滤器名 fsl2tcms
fsl2tcms_protocol = Proto("fsl2tcms", "FSL2 TCMS Protocol")

-- 非 FSL2 报文时回退到 Wireshark 自带 Data 解析器
local data_dissector = Dissector.get('data')

-- 端口可配置，规范 3.2.1: 通信端口从配置文件读出
fsl2tcms_protocol.prefs.udp_ports = Pref.string("端口号(s):", "18010,18030",
    "FSL2 TCMS 通信 UDP 端口，多个用逗号分隔，修改后需重启生效")

-- 字段定义，描述格式: 中文(过滤器名)(字节数),字节序(消息内偏移)
local field = {
    head       = ProtoField.uint8("fsl2tcms.head", "数据帧头(head)(1bytes),字节序(0)", base.HEX),
    seq        = ProtoField.uint8("fsl2tcms.seq", "消息序号(seq)(1bytes),字节序(1)", base.DEC),
    device     = ProtoField.uint8("fsl2tcms.device", "设备序号(device)(1bytes),字节序(2)", base.HEX),
    message    = ProtoField.uint8("fsl2tcms.messageid", "消息类型(message)(1bytes),字节序(3)", base.HEX),
    start_addr = ProtoField.uint16("fsl2tcms.startaddr", "起始地址(startaddr)(2bytes),字节序(4)", base.DEC),
    crc        = ProtoField.uint8("fsl2tcms.crc", "包校验(crc)(1bytes)", base.HEX),    -- 偏移按消息类型动态生成
    tail       = ProtoField.uint8("fsl2tcms.tail", "数据帧尾(tail)(1bytes)", base.HEX),  -- 偏移按消息类型动态生成
    val        = ProtoField.uint8("fsl2tcms.val", "值(val)(1bytes)", base.DEC),    -- 点表行: 可过滤值=载荷字节
    ip         = ProtoField.ipv4("fsl2tcms.ip", "ISCS IP(ip)(4bytes),字节序(6)"),
}
fsl2tcms_protocol.fields = { field.head, field.seq, field.device, field.message,
    field.start_addr, field.crc, field.tail, field.val, field.ip }

-- 帧头/帧尾固定值 (规范 3.2.2)
local HEAD_BYTE = 0x7F
local TAIL_BYTE = 0x7E

-- 设备序号名称映射: 列车1~25 / ISCS 0xF0 / PIS 0xF5 (规范 3.2.2)
local function get_device_name(device)
    if device == 0xF0 then return "ISCS"
    elseif device == 0xF5 then return "PIS"
    elseif device >= 1 and device <= 25 then return "列车" .. device
    end
end

-- 消息类型名称 (规范 3.2.2)
local message_name = {
    [0x01] = "会话建立信令",
    [0x02] = "心跳信令",
    [0x04] = "确认报文",
    [0x10] = "数据信令",
}

-- 消息类型方向: 依据设备序号与消息类型 (规范 3.2.3)
local function get_direction(device, msg)
    if msg == 0x01 then return "ISCS→PIS" end
    if msg == 0x04 then return device == 0xF0 and "ISCS→PIS" or "PIS→ISCS" end
    return "PIS→ISCS" -- 0x02 心跳 / 0x10 数据
end

-- 消息类型信息: { len=消息总长, kind=数据域类型 }
-- kind: "session" 会话(4字节IP) / "ack" 确认(1字节) / "hb" 心跳(无数据) / "train" 数据(30字节)
local function get_message_info(device, msg)
    if device == 0xF0 and msg == 0x01 then return { len = 12, kind = "session" }
    elseif device == 0xF5 and msg == 0x04 then return { len = 9, kind = "ack" }
    elseif device == 0xF5 and msg == 0x02 then return { len = 8, kind = "hb" }
    elseif device == 0xF0 and msg == 0x04 then return { len = 9, kind = "ack" }
    elseif msg == 0x10 then return { len = 38, kind = "train" } -- 设备为列车号1~25
    end
end

-- 校验和: 从消息序号(offset+1)到消息内容结束(offset+total_len-3)求和，取低字节 (规范 3.2.2 包校验)
local function compute_checksum(buf, offset, total_len)
    local sum = 0
    for i = 0, total_len - 4 do
        sum = sum + buf(offset + 1 + i, 1):uint()
    end
    return sum % 256
end

-- 公共消息头: 数据帧头 消息序号 设备序号 消息类型 起始地址
local function add_message_header(tree, buf, offset)
    tree:add(field.head, buf(offset, 1))
    tree:add(field.seq, buf(offset + 1, 1))
    local dev_item = tree:add(field.device, buf(offset + 2, 1))
    local dev_name = get_device_name(buf(offset + 2, 1):uint())
    if dev_name then dev_item:append_text(" (" .. dev_name .. ")") end
    tree:add(field.message, buf(offset + 3, 1))
    tree:add(field.start_addr, buf(offset + 4, 2))
end

-- 解析一条完整消息，total_len 已保证不超过 buf 剩余长度
local function dissect_message(buf, offset, total_len, name, kind, tree)
    local msg_tree = tree:add(fsl2tcms_protocol, buf(offset, total_len),
        "FSL2 TCMS Data (" .. total_len .. " bytes) | " .. name)
    add_message_header(msg_tree, buf, offset)

    -- 数据域按类型显示 (规范 3.2.3)
    if kind == "session" then
        msg_tree:add(field.ip, buf(offset + 6, 4))
    elseif kind == "train" then
        local start = buf(offset + 4, 2):uint()
        local sub_tree = msg_tree:add(buf(offset + 6, 30),
            "数据点表: 地址 " .. start .. " ~ " .. (start + 29))
        if start % 30 ~= 0 then
            sub_tree:append_text(" [WARN: 起始地址不是30整数倍]")
        end
        for i = 0, 29 do
            local v = buf(offset + 6 + i, 1):uint()
            sub_tree:add(field.val, buf(offset + 6 + i, 1), v)
                :set_text(string.format("地址(addr),字节序(%d):%d | 值:%d", 6 + i, start + i, v))
        end
    elseif kind == "ack" then
        msg_tree:add(buf(offset + 6, 1), "确认内容: 0x" .. string.format("%02x", buf(offset + 6, 1):uint()))
    end
    -- kind == "hb" 无数据域

    -- 包校验: 验算 (不足 8 字节时 crc/tail 与起始地址重叠，跳过)
    if total_len >= 8 then
        local expected = compute_checksum(buf, offset, total_len)
        local actual = buf(offset + total_len - 2, 1):uint()
        local crc_status = (expected == actual) and "OK"
            or string.format("FAIL(计算值=0x%02x)", expected)
        msg_tree:add(field.crc, buf(offset + total_len - 2, 1))
            :set_text(string.format("包校验(crc)(1bytes),字节序(%d):0x%02x [%s]",
                total_len - 2, actual, crc_status))

        local tail_val = buf(offset + total_len - 1, 1):uint()
        local tail_status = (tail_val == TAIL_BYTE) and "OK" or "异常(应为0x7E)"
        msg_tree:add(field.tail, buf(offset + total_len - 1, 1))
            :set_text(string.format("数据帧尾(tail)(1bytes),字节序(%d):0x%02x [%s]",
                total_len - 1, tail_val, tail_status))
    end
end

-- Info 列内容: 消息类型+方向+序号+有效信息(数据信令的列车号/起始地址，会话信令的IP)
-- 仅对完整消息调用，buf(offset..) 范围已在调用方保证不越界
local function build_info(device, msg, kind, buf, offset)
    local s = string.format("%s %s seq=%d", message_name[msg] or "未知",
        get_direction(device, msg), buf(offset + 1, 1):uint())
    if kind == "train" then
        local dev_name = get_device_name(device)
        if dev_name then s = s .. " " .. dev_name end
        s = s .. string.format(" addr=%d", buf(offset + 4, 2):uint())
    elseif kind == "session" then
        s = s .. string.format(" IP=%d.%d.%d.%d",
            buf(offset + 6, 1):uint(), buf(offset + 7, 1):uint(),
            buf(offset + 8, 1):uint(), buf(offset + 9, 1):uint())
    end
    return s
end

-- 解析一个 UDP 数据报(可能含多条消息)。返回 true 表示已消费，false 表示非本协议
local function dissect_datagram(buf, tree, pinfo)
    -- 报文过短或帧头不匹配，不是本协议
    if buf:len() < 6 or buf(0, 1):uint() ~= HEAD_BYTE then
        return false
    end

    local offset = 0
    while offset < buf:len() do
        local remaining = buf:len() - offset
        -- 尾部不足一个消息头，原样显示，不丢弃
        if remaining < 6 then
            tree:add(fsl2tcms_protocol, buf(offset, remaining),
                "FSL2 TCMS trailing " .. remaining .. " bytes")
            break
        end
        -- 中间消息帧头不对，说明帧边界错位，余下按原始数据显示
        if buf(offset, 1):uint() ~= HEAD_BYTE then
            tree:add(fsl2tcms_protocol, buf(offset, remaining),
                string.format("FSL2 TCMS invalid head 0x%02x", buf(offset, 1):uint()))
            break
        end

        local device = buf(offset + 2, 1):uint()
        local msg = buf(offset + 3, 1):uint()
        local info = get_message_info(device, msg)
        local name
        local total_len
        local kind

        if info then
            total_len = info.len
            kind = info.kind
            name = (message_name[msg] or "未知") .. " " .. get_direction(device, msg)

            -- UDP 不做重组，消息被截断时只显示已有字节
            if total_len > remaining then
                local t = tree:add(fsl2tcms_protocol, buf(offset, remaining),
                    "FSL2 TCMS truncated (need " .. total_len .. " bytes, got " .. remaining .. ")")
                add_message_header(t, buf, offset)
                pinfo.cols.info:set(name .. " seq=" .. buf(offset + 1, 1):uint() .. " [截断]")
                break
            end

            -- Info 列: 消息类型+方向+序号+有效信息，多消息时以最后一条为准
            pinfo.cols.info:set(build_info(device, msg, kind, buf, offset))
        else
            total_len = remaining
            name = "unknown"
            pinfo.cols.info:set(string.format("未知类型(0x%02x) seq=%d",
                msg, buf(offset + 1, 1):uint()))
        end

        dissect_message(buf, offset, total_len, name, kind, tree)
        offset = offset + total_len
    end
    return true
end

function fsl2tcms_protocol.dissector(tvb, pinfo, tree)
    pinfo.cols.info:set('')

    if dissect_datagram(tvb, tree, pinfo) then
        -- 确认是本协议报文后，才设置协议列
        pinfo.cols.protocol:set('fsl2tcms')
    else
        data_dissector:call(tvb, pinfo, tree)
    end
end

-- 解析多个端口号
local function parse_ports(ports_str)
    local ports = {}
    for port in string.gmatch(ports_str, "%d+") do
        table.insert(ports, tonumber(port))
    end
    return ports
end

-- 注册到 UDP 端口
local udp_port_table = DissectorTable.get("udp.port")

local function register_ports()
    if fsl2tcms_protocol.prefs.udp_ports ~= "" then
        for _, port in ipairs(parse_ports(fsl2tcms_protocol.prefs.udp_ports)) do
            udp_port_table:add(port, fsl2tcms_protocol)
        end
    end
end

register_ports()
function fsl2tcms_protocol.prefs_changed() register_ports() end
