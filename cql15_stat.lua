-- CQL15 统计分析插件
-- 版本: 1.0.2#20260813
-- 描述: 对 CQL15 协议报文进行通用统计分析
--       包含: 报文总数/双向分布、消息类型分布、序号异常、心跳间隔、会话时长、报文速率
-- 安装: 复制到 Wireshark 插件目录，重启后 工具 → CQL15 统计分析

-- 使用唯一协议名避免与 cql15_protocol.lua 冲突
local cql15_stat_plugin = Proto("CQL15Stat", "CQL15 Protocol Statistic Analyzer")

-- ============================================================
-- 统计状态
-- ============================================================
local S = {
    total        = 0,
    sig_to_iscs  = 0,
    iscs_to_sig  = 0,
    type_cnt     = {},
    seq_dup      = 0,
    seq_gap      = 0,
    seq_seen     = {},
    first_ts     = nil,
    last_ts      = nil,
    hb_sum       = 0,
    hb_cnt       = 0,
    hb_max       = 0,
    hb_min       = nil,
    hb_last_ts   = nil,
}

-- ============================================================
-- 辅助函数
-- ============================================================
local function ts_str(ts)
    if not ts then return "-" end
    return string.format("%.6f", ts)
end

local function dur_str(sec)
    if not sec or sec <= 0 then return "-" end
    if sec < 1 then return string.format("%.1f ms", sec * 1000)
    elseif sec < 3600 then return string.format("%.2f s", sec)
    else
        local m = math.floor(sec / 60)
        local s = sec - m * 60
        return string.format("%d min %.1f s", m, s)
    end
end

local function rate_str(n, sec)
    if not sec or sec <= 0 then return "-" end
    return string.format("%.2f pkt/s", n / sec)
end

local function pct(n, total)
    if total == 0 then return "0.0" end
    return string.format("%.1f", n / total * 100)
end

-- ============================================================
-- 方向判断
-- ============================================================
local sig_ports = {}
local function set_sig_ports(port_str)
    sig_ports = {}
    for port in string.gmatch(port_str, "%d+") do
        sig_ports[tonumber(port)] = true
    end
end

local function is_sig_dir(pinfo)
    for _, p in pairs(sig_ports) do
        if pinfo.src_port == p then return true end
    end
    return false
end

-- ============================================================
-- 统计更新
-- ============================================================
local function update(buffer, pinfo, tree)
    local ts = pinfo.rel_ts or pinfo.pkts_ts
    S.total = S.total + 1
    if not S.first_ts then S.first_ts = ts end
    S.last_ts = ts

    local is_sig = is_sig_dir(pinfo)
    if is_sig then
        S.sig_to_iscs = S.sig_to_iscs + 1
    else
        S.iscs_to_sig = S.iscs_to_sig + 1
    end

    -- 解析 CQL15 头部 (offset 1=seq, 3=data_type)
    if buffer:len() >= 10 then
        local dtype = buffer(3, 2):string()
        S.type_cnt[dtype] = (S.type_cnt[dtype] or 0) + 1

        local seq = buffer(1, 2):uint()
        local key = tostring(pinfo.src_port) .. (is_sig and "S" or "I")
        local last = S.seq_seen[key]
        if last ~= nil then
            if seq == last then
                S.seq_dup = S.seq_dup + 1
            elseif seq > last + 1 then
                S.seq_gap = S.seq_gap + 1
            end
        end
        S.seq_seen[key] = seq

        -- 心跳(09)间隔统计
        if dtype == "09" then
            if S.hb_last_ts then
                local iv = ts - S.hb_last_ts
                S.hb_sum = S.hb_sum + iv
                S.hb_cnt = S.hb_cnt + 1
                if iv > S.hb_max then S.hb_max = iv end
                if not S.hb_min or iv < S.hb_min then S.hb_min = iv end
            end
            S.hb_last_ts = ts
        end
    end
end

-- ============================================================
-- StatDialog 回调
-- ============================================================
local function stat_cb(dialog)
    local total = S.total
    local dur = 0
    if S.first_ts and S.last_ts then
        dur = S.last_ts - S.first_ts
    end

    dialog:append_text(string.rep("─", 56) .. "\n")
    dialog:append_text(string.format("  CQL15 协议统计  (%s)\n", os.date("%Y-%m-%d %H:%M:%S")))
    dialog:append_text(string.rep("─", 56) .. "\n\n")

    dialog:append_text("【一、基础统计】\n")
    dialog:append_text(string.format("  报文总数:        %d 包\n", total))
    dialog:append_text(string.format("  SIG→ISCS:        %d 包  (%s%%)\n",
        S.sig_to_iscs, pct(S.sig_to_iscs, total)))
    dialog:append_text(string.format("  ISCS→SIG:        %d 包  (%s%%)\n",
        S.iscs_to_sig, pct(S.iscs_to_sig, total)))
    dialog:append_text(string.format("  会话时长:        %s\n", dur_str(dur)))
    dialog:append_text(string.format("  平均速率:        %s\n", rate_str(total, dur)))
    dialog:append_text("\n")

    dialog:append_text("【二、消息类型分布】\n")
    dialog:append_text(string.format("  %-4s  %-32s  %6s  %5s\n",
        "类型", "名称", "计数", "占比"))
    dialog:append_text(string.rep("─", 56) .. "\n")
    for dtype, cnt in pairs(S.type_cnt) do
        local name = type_names[dtype] or dtype
        dialog:append_text(string.format("  %-4s  %-32s  %6d  %s%%\n",
            dtype, name, cnt, pct(cnt, total)))
    end
    dialog:append_text("\n")

    dialog:append_text("【三、时序统计】\n")
    dialog:append_text(string.format("  首包时间:        %s\n", ts_str(S.first_ts)))
    dialog:append_text(string.format("  末包时间:        %s\n", ts_str(S.last_ts)))
    if S.hb_cnt > 0 then
        dialog:append_text(string.format("  心跳间隔 平均:   %.3f s\n", S.hb_sum / S.hb_cnt))
        dialog:append_text(string.format("  心跳间隔 最大:   %.3f s\n", S.hb_max))
        dialog:append_text(string.format("  心跳间隔 最小:   %.3f s\n", S.hb_min or 0))
        dialog:append_text(string.format("  心跳包数:        %d\n", S.hb_cnt))
    end
    dialog:append_text("\n")

    dialog:append_text("【四、异常统计】\n")
    dialog:append_text(string.format("  序号重号:        %d\n", S.seq_dup))
    dialog:append_text(string.format("  序号断号:        %d\n", S.seq_gap))
    if S.seq_dup > 0 or S.seq_gap > 0 then
        dialog:append_text("  ⚠ 存在序号异常，可能存在丢包或重传\n")
    else
        dialog:append_text("  ✓ 序号连续，无异常\n")
    end
    dialog:append_text("\n")
    dialog:append_text(string.rep("─", 56) .. "\n")
end

-- ============================================================
-- 消息类型名称表
-- ============================================================
local type_names = {
    ["01"] = "列车运行信息及阻塞信息",
    ["02"] = "站台信息",
    ["03"] = "SPKS 设备状态信息",
    ["06"] = "当天使用的时刻表",
    ["07"] = "SCADA 供电区段",
    ["08"] = "回执信息",
    ["09"] = "心跳信息",
    ["15"] = "客流信息",
    ["16"] = "请求当天时刻表",
    ["18"] = "列车联动信息",
    ["19"] = "段场出入库 / FAS火灾",
    ["21"] = "区间超水位信息",
    ["39"] = "信号设备状态信息",
}

-- ============================================================
-- 注册
-- ============================================================
cql15_stat_plugin.prefs.monitored_port = Pref.string("监控端口:", "5000",
    "CQL15默认端口")

local function add_port()
    set_sig_ports(cql15_stat_plugin.prefs.monitored_port)
end
add_port()
function cql15_stat_plugin.prefs_changed() add_port() end

if StatDialog then
    StatDialog.register(cql15_stat_plugin, "CQL15 统计分析", stat_cb)
end

function cql15_stat_plugin.dissector(buffer, pinfo, tree)
    update(buffer, pinfo, tree)
end
