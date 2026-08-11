-- 插件名: JNL7 Protocol
-- 版本: 1.0.0#20260810-1
-- 作者: 叶孟鹏
-- 描述: 济南7号线 ATS-ISCS 接口协议（信号ATS<->综合监控ISCS），
--       依据 jnl7_ats.md《济南城市轨道交通7号线一期工程ATS与综合监控系统接口规格书》V1.0 实现全部消息类型解析。
--       字段展示格式: 编号.名称(Nbytes),字节序(X):值 [过滤器名]
--       所有字段均已注册 ProtoField，可在显示过滤器按 jnl7.* 过滤。
--       枚举字段(驾驶模式/列车位置/EB状态等)自动追加中文描述。
-- 更新时间: 2026-08-10
jnl7_protocol = Proto("JNL7", "JNL7 Protocol")
-- 首选项
local prefs = jnl7_protocol.prefs
prefs.my_version = Pref.statictext("version:1.0.0#20260810-1",
                                   "1.0.0#20260810-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "5000",
                                "JNL7默认端口")


-- 过滤器字段定义
local function sf(name, desc) -- ASCII字符串字段
    return ProtoField.string("jnl7." .. name, desc, base.ASCII)
end
local pf = {
    -- 头部通用
    seq          = sf("seq", "2.信息序号"),
    data_type    = sf("data_type", "3.信息类型(data_type)"),
    data_len     = sf("data_len", "4.信息长度"),
    send_time    = ProtoField.bytes("jnl7.send_time", "5.数据发送时间"),
    crc          = sf("crc", "CRC校验"),
    -- 类型01/02/06/19 共用列车/车站字段
    train_count  = sf("train_count", "列车数量"),
    train_set    = sf("train_set", "列车车组号"),
    service_no   = sf("service_no", "列车服务号"),
    driver_no    = sf("driver_no", "列车司机号"),
    cbtc_flag    = sf("cbtc_flag", "CBTC/非CBTC状态"),
    train_pos    = sf("train_pos", "列车位置"),
    train_run_on = sf("train_run_on", "列车运行于"),
    station_no   = sf("station_no", "车站号"),
    block_flag   = sf("block_flag", "列车阻塞标识"),
    train_dir    = sf("train_dir", "列车方向"),
    segment_id   = sf("segment_id", "列车运行线段ID(CBTC)"),
    offset_cbtc  = sf("offset_cbtc", "列车运行偏移量(CBTC)"),
    eb_state     = sf("eb_state", "EB状态"),
    drive_mode   = sf("drive_mode", "驾驶模式"),
    wet_rail     = sf("wet_rail", "湿轨模式"),
    -- 类型01 列车运行独有
    section_name = sf("section_name", "区段名称"),
    late_early   = sf("late_early", "列车早晚点信息"),
    hold_train   = sf("hold_train", "列车扣车"),
    imm_stop     = sf("imm_stop", "列车立即停车"),
    clear_train  = sf("clear_train", "列车清客"),
    skip_stop    = sf("skip_stop", "列车跳停"),
    sleep_state  = sf("sleep_state", "休眠"),
    wake_state   = sf("wake_state", "唤醒"),
    train_mode   = sf("train_mode", "列车工况"),
    -- 类型02 站台信息
    platform_no      = sf("platform_no", "站台号"),
    emergency_stop   = sf("emergency_stop", "站台紧停标志"),
    first_train      = sf("first_train", "首班列车"),
    last_train       = sf("last_train", "末班列车"),
    platform_state   = sf("platform_state", "列车站台状态"),
    -- 时间域含 NUL(0x00)分隔符(日期与时间之间), FT_STRING 遇 NUL 截断会触发
    -- Trailing stray characters 告警, 故与头部 send_time 一致用 FT_BYTES
    arrive_time      = ProtoField.bytes("jnl7.arrive_time", "到站时间"),
    depart_time      = ProtoField.bytes("jnl7.depart_time", "离站时间"),
    terminal_station = sf("terminal_station", "终点站号"),
    dest_code        = sf("dest_code", "目的地码"),
    non_passenger    = sf("non_passenger", "非载客列车"),
    train_approach   = sf("train_approach", "列车接近"),
    ballast_train    = sf("ballast_train", "轧道列车"),
    -- 类型06 时刻表
    total_packets = sf("total_packets", "总包数"),
    cur_packet    = sf("cur_packet", "当前包序号"),
    trip_count    = sf("trip_count", "行程数"),
    trip_seq      = sf("trip_seq", "序列号"),
    plat_count    = sf("plat_count", "站台数量"),
    -- 类型07 SCADA
    section_count = sf("section_count", "供电区段数量"),
    section_state = sf("section_state", "供电区段"),
    -- 类型15 客流
    flow_count = sf("flow_count", "客流信息的个数"),
    flow_value = sf("flow_value", "客流数"),
    -- 类型17 站台运营载客首末班车信息 (同 send_time 用 FT_BYTES 避免 NUL 截断告警)
    first_time     = ProtoField.bytes("jnl7.first_time", "首班载客列车发车时间"),
    first_terminal = sf("first_terminal", "首班载客列车终点站号"),
    last_time      = ProtoField.bytes("jnl7.last_time", "末班载客列车发车时间"),
    last_terminal  = sf("last_terminal", "末班载客列车终点站编号"),
    -- 类型19 SIG方向 出入库
    cur_track   = sf("cur_track", "列车当前运行轨道名称"),
    depot_track = sf("depot_track", "库线股道名称"),
    inout_state = sf("inout_state", "出入库状态"),
    -- 类型19 ISCS方向 FAS
    fas_count = sf("fas_count", "FAS数量"),
    fas_state = sf("fas_state", "FAS"),
    -- 类型21 区间超水位
    interval_count = sf("interval_count", "区间数量"),
    interval_state = sf("interval_state", "区间"),
    -- 类型39 信号设备状态
    dev_count = sf("dev_count", "设备数量"),
    sig_type  = sf("sig_type", "信号类型"),
    dev_name  = sf("dev_name", "设备名称"),
    dev_state = ProtoField.uint16("jnl7.dev_state", "设备状态", base.HEX),
}
jnl7_protocol.fields = {}
for _, v in pairs(pf) do table.insert(jnl7_protocol.fields, v) end


-- 枚举中文描述表
local enum_cbtc     = {["0"]="非CBTC车",["1"]="CBTC车"}
local enum_pos      = {["0"]="未知",["1"]="正线",["2"]="车辆段",["3"]="停车场"}
local enum_run_on   = {["0"]="未知",["1"]="上行线",["2"]="下行线"}
local enum_block    = {["0"]="非列车停车",["1"]="列车停车"}
local enum_dir      = {["0"]="未知",["1"]="左向",["2"]="右向"}
local enum_eb       = {["0"]="未激活",["1"]="激活"}
local enum_late     = {["0"]="未知",["1"]="晚点",["2"]="早点"}
local enum_hold     = {["0"]="非扣车",["1"]="扣车"}
local enum_immstop  = {["0"]="未激活",["1"]="激活"}
local enum_clear01  = {["0"]="未清客",["1"]="清客"}
local enum_clear02  = {["0"]="未清客",["1"]="临时清客",["2"]="计划清客"}
local enum_skip     = {["0"]="非跳停",["1"]="跳停"}
local enum_sleep    = {["0"]="未激活",["1"]="激活"}
local enum_wake     = {["0"]="未激活",["1"]="激活"}
local enum_drive    = {["0"]="未知",["1"]="RM模式",["3"]="CM模式",["4"]="AM模式",["5"]="FAM模式",["6"]="CAM模式",["7"]="RRM模式",["8"]="ATB模式",["9"]="EUM模式"}
local enum_wet      = {["0"]="未激活",["1"]="激活"}
local enum_mode     = {["0"]="未知",["1"]="进入正线服务",["2"]="退出正线服务",["3"]="清扫",["4"]="洗车",["5"]="非FAM模式",["6"]="待命",["7"]="场内运行"}
local enum_plat     = {["0"]="未知",["1"]="1站台",["2"]="2站台",["3"]="3站台",["4"]="4站台"}
local enum_plat8    = {["0"]="未知",["1"]="1站台",["2"]="2站台",["3"]="3站台",["4"]="4站台",["5"]="5站台",["6"]="6站台",["7"]="7站台",["8"]="8站台"}
local enum_emergency= {["0"]="未紧停",["1"]="紧停"}
local enum_first    = {["0"]="非首班车",["1"]="首班车"}
local enum_last     = {["0"]="非末班车",["1"]="末班车"}
local enum_pstate   = {["0"]="未知",["1"]="到站",["2"]="离站"}
local enum_nonpass  = {["0"]="载客列车",["1"]="非载客列车"}
local enum_approach = {["0"]="列车未到",["1"]="列车接近"}
local enum_ballast  = {["0"]="非轧道列车",["1"]="轧道列车"}
local enum_section  = {["0"]="未知",["1"]="已供电",["2"]="未供电"}
local enum_inout    = {["0"]="未知",["1"]="出库",["2"]="入库"}
local enum_fas      = {["1"]="火灾激活",["2"]="火灾未激活"}
local enum_interval = {["1"]="超高水位",["2"]="非超高水位"}
local enum_sigtype  = {["1"]="信号机",["2"]="道岔",["3"]="区段",["4"]="SPKS",["5"]="联锁机"}

-- 值存在枚举描述则追加 " | 中文"
local function desc(v, t)
    local d = t and t[v]
    if d then return " | " .. d end
    return ""
end

local dataTypeStr = {
    ["01"] = "列车运行信息及列车阻塞信息",
    ["02"] = "站台信息",
    ["06"] = "当天使用的时刻表的全部信息",
    ["07"] = "SCADA供电区段",
    ["08"] = "回执信息",
    ["09"] = "心跳信息",
    ["15"] = "客流信息",
    ["17"] = "站台运营载客首末班车信息",
    ["19"] = "段场出入库信息", -- 类型19冲突: SIG方向=出入库, ISCS方向=FAS火灾信息(按TCP方向区分)
    ["21"] = "区间超水位信息",
    ["39"] = "信号设备状态信息",
}

local data_dis = Dissector.get("data")

-- SIG(ATS)为服务端,监听注册端口; ISCS为客户端。
-- 类型19冲突: SIG发起=出入库, ISCS发起=FAS。据此方向区分。
local sig_ports = {}

-- 方向判断: src端口为SIG端口→SIG发起; 否则dst为SIG端口→ISCS发起
local function sender_is_sig(pinfo)
    if sig_ports[pinfo.src_port] then return true end
    if sig_ports[pinfo.dst_port] then return false end
    return true -- 兜底默认SIG
end

-- 19字节时间域: 前10字节日期 + 1字节分隔符 + 8字节时间 "YYYY-MM-DD HH:MM:SS"
local function fmt_time(buf, off)
    return buf(off, 10):string() .. " " .. buf(off + 11, 8):string()
end

-- 累加和校验: 对 [from, to) 字节求和取低字节，以两位大写十六进制ASCII表示（附录1）
local function checksum_hex(buf, from, to)
    local sum = 0
    local raw = buf(from, to - from):raw()
    for i = 1, #raw do sum = sum + raw:byte(i) end
    return string.format("%02X", sum % 256)
end

-- ============ 类型39 信号设备状态: 2字节设备状态按信号类型解码 ============
-- 位索引按从右至左顺序(LSB=bit1)。高位byte: 仅信号机用作色码(0绿/1黄/2红/3引导)
local function dev_state_text(sig_type, hi, lo)
    local t = {}
    local function on(byte, n) return math.floor(byte / 2 ^ (n - 1)) % 2 == 1 end
    if sig_type == "1" then -- 信号机
        local color = {[0]="绿灯",[1]="黄灯",[2]="红灯",[3]="引导"}
        t[#t + 1] = "色码:" .. (color[hi] or string.format("%X", hi))
        if on(lo, 7) then t[#t + 1] = "CBTC" end
        if on(lo, 6) then t[#t + 1] = "闪灯" end
        if on(lo, 5) then t[#t + 1] = "封锁" end
        if on(lo, 4) then t[#t + 1] = "Fleet进路" end
        if on(lo, 3) then t[#t + 1] = "绿/黄灯丝断丝" end
        if on(lo, 2) then t[#t + 1] = "红灯断丝" end
        if on(lo, 1) then t[#t + 1] = "蓝灯断丝" end
    elseif sig_type == "2" then -- 道岔
        if on(lo, 5) then t[#t + 1] = "失表" end
        if on(lo, 4) then t[#t + 1] = "定位" end
        if on(lo, 3) then t[#t + 1] = "反位" end
        if on(lo, 2) then t[#t + 1] = "锁闭" end
        if on(lo, 1) then t[#t + 1] = "单锁" end
    elseif sig_type == "3" then -- 区段
        if on(lo, 4) then t[#t + 1] = "右向锁闭" end
        if on(lo, 3) then t[#t + 1] = "左向锁闭" end
        if on(lo, 2) then t[#t + 1] = "占用" end
        if on(lo, 1) then t[#t + 1] = "封锁" end
    elseif sig_type == "4" then -- SPKS
        if on(lo, 2) then t[#t + 1] = "激活" end
        if on(lo, 1) then t[#t + 1] = "旁路" end
    elseif sig_type == "5" then -- 联锁机
        if on(lo, 1) then t[#t + 1] = "故障" end
    end
    if #t > 0 then return "[" .. table.concat(t, ",") .. "]" end
    return ""
end

-- 信息类型 01: 列车运行信息及列车阻塞信息 (每列车57字节)
local function parse_01(buf, off, tree)
    tree:add(pf.train_count, buf(off + 29, 2)):set_text("6.列车数量[train_count](2bytes),字节序(29):" .. buf(off + 29, 2):string())
    local num = tonumber(buf(off + 29, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 31 + i * 57
        local rel = 31 + i * 57
        local t = tree:add(buf(o, 57), "车:" .. (i + 1) .. "(57bytes),字节序(" .. rel .. "):数据长度:57")
        t:add(pf.train_set, buf(o, 4)):set_text("列车车组号[train_set](4bytes),字节序(" .. (rel + 0) .. "):" .. buf(o, 4):string())
        t:add(pf.service_no, buf(o + 4, 3)):set_text("列车服务号[service_no](3bytes),字节序(" .. (rel + 4) .. "):" .. buf(o + 4, 3):string())
        t:add(pf.driver_no, buf(o + 7, 3)):set_text("列车司机号[driver_no](3bytes),字节序(" .. (rel + 7) .. "):" .. buf(o + 7, 3):string())
        t:add(pf.cbtc_flag, buf(o + 10, 1)):set_text("CBTC/非CBTC状态[cbtc_flag](1bytes),字节序(" .. (rel + 10) .. "):" .. buf(o + 10, 1):string() .. desc(buf(o + 10, 1):string(), enum_cbtc))
        t:add(pf.train_pos, buf(o + 11, 1)):set_text("列车位置[train_pos](1bytes),字节序(" .. (rel + 11) .. "):" .. buf(o + 11, 1):string() .. desc(buf(o + 11, 1):string(), enum_pos))
        t:add(pf.train_run_on, buf(o + 12, 1)):set_text("列车运行于[train_run_on](1bytes),字节序(" .. (rel + 12) .. "):" .. buf(o + 12, 1):string() .. desc(buf(o + 12, 1):string(), enum_run_on))
        t:add(pf.station_no, buf(o + 13, 3)):set_text("车站号[station_no](3bytes),字节序(" .. (rel + 13) .. "):" .. buf(o + 13, 3):string())
        t:add(pf.section_name, buf(o + 16, 10)):set_text("区段名称[section_name](10bytes),字节序(" .. (rel + 16) .. "):" .. buf(o + 16, 10):string())
        t:add(pf.block_flag, buf(o + 26, 1)):set_text("列车阻塞标识[block_flag](1bytes),字节序(" .. (rel + 26) .. "):" .. buf(o + 26, 1):string() .. desc(buf(o + 26, 1):string(), enum_block))
        t:add(pf.train_dir, buf(o + 27, 1)):set_text("列车方向[train_dir](1bytes),字节序(" .. (rel + 27) .. "):" .. buf(o + 27, 1):string() .. desc(buf(o + 27, 1):string(), enum_dir))
        t:add(pf.segment_id, buf(o + 28, 10)):set_text("列车运行线段ID(CBTC)[segment_id](10bytes),字节序(" .. (rel + 28) .. "):" .. buf(o + 28, 10):string())
        t:add(pf.offset_cbtc, buf(o + 38, 8)):set_text("列车运行偏移量(CBTC)[offset_cbtc](8bytes),字节序(" .. (rel + 38) .. "):" .. buf(o + 38, 8):string())
        t:add(pf.eb_state, buf(o + 46, 1)):set_text("EB状态[eb_state](1bytes),字节序(" .. (rel + 46) .. "):" .. buf(o + 46, 1):string() .. desc(buf(o + 46, 1):string(), enum_eb))
        t:add(pf.late_early, buf(o + 47, 1)):set_text("列车早晚点信息[late_early](1bytes),字节序(" .. (rel + 47) .. "):" .. buf(o + 47, 1):string() .. desc(buf(o + 47, 1):string(), enum_late))
        t:add(pf.hold_train, buf(o + 48, 1)):set_text("列车扣车[hold_train](1bytes),字节序(" .. (rel + 48) .. "):" .. buf(o + 48, 1):string() .. desc(buf(o + 48, 1):string(), enum_hold))
        t:add(pf.imm_stop, buf(o + 49, 1)):set_text("列车立即停车[imm_stop](1bytes),字节序(" .. (rel + 49) .. "):" .. buf(o + 49, 1):string() .. desc(buf(o + 49, 1):string(), enum_immstop))
        t:add(pf.clear_train, buf(o + 50, 1)):set_text("列车清客[clear_train](1bytes),字节序(" .. (rel + 50) .. "):" .. buf(o + 50, 1):string() .. desc(buf(o + 50, 1):string(), enum_clear01))
        t:add(pf.skip_stop, buf(o + 51, 1)):set_text("列车跳停[skip_stop](1bytes),字节序(" .. (rel + 51) .. "):" .. buf(o + 51, 1):string() .. desc(buf(o + 51, 1):string(), enum_skip))
        t:add(pf.sleep_state, buf(o + 52, 1)):set_text("休眠[sleep_state](1bytes),字节序(" .. (rel + 52) .. "):" .. buf(o + 52, 1):string() .. desc(buf(o + 52, 1):string(), enum_sleep))
        t:add(pf.wake_state, buf(o + 53, 1)):set_text("唤醒[wake_state](1bytes),字节序(" .. (rel + 53) .. "):" .. buf(o + 53, 1):string() .. desc(buf(o + 53, 1):string(), enum_wake))
        t:add(pf.drive_mode, buf(o + 54, 1)):set_text("驾驶模式[drive_mode](1bytes),字节序(" .. (rel + 54) .. "):" .. buf(o + 54, 1):string() .. desc(buf(o + 54, 1):string(), enum_drive))
        t:add(pf.wet_rail, buf(o + 55, 1)):set_text("湿轨模式[wet_rail](1bytes),字节序(" .. (rel + 55) .. "):" .. buf(o + 55, 1):string() .. desc(buf(o + 55, 1):string(), enum_wet))
        t:add(pf.train_mode, buf(o + 56, 1)):set_text("列车工况[train_mode](1bytes),字节序(" .. (rel + 56) .. "):" .. buf(o + 56, 1):string() .. desc(buf(o + 56, 1):string(), enum_mode))
    end
    return off + 31 + num * 57
end

-- 信息类型 02: 站台信息
-- ponytail: 站台信息每列列车块字节数。jnl7_ats.md 表内字段偏移排到+61(占62字节)，
-- 但步长写60(36+(N-1)*60)、CRC写36+N*61，三处不一致。
-- 按「原文档为准」：此处取62（字段偏移唯一自洽值），待对照Word原稿确认后改这一个数即可。
local PLAT_BLOCK = 62
local function parse_02(buf, off, tree)
    tree:add(pf.station_no, buf(off + 29, 3)):set_text("6.车站号[station_no](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    tree:add(pf.platform_no, buf(off + 32, 1)):set_text("7.站台号[platform_no](1bytes),字节序(32):" .. buf(off + 32, 1):string() .. desc(buf(off + 32, 1):string(), enum_plat))
    tree:add(pf.emergency_stop, buf(off + 33, 1)):set_text("8.站台紧停标志[emergency_stop](1bytes),字节序(33):" .. buf(off + 33, 1):string() .. desc(buf(off + 33, 1):string(), enum_emergency))
    tree:add(pf.train_count, buf(off + 34, 2)):set_text("9.列车数量[train_count](2bytes),字节序(34):" .. buf(off + 34, 2):string())
    local num = tonumber(buf(off + 34, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 36 + i * PLAT_BLOCK
        local rel = 36 + i * PLAT_BLOCK
        local t = tree:add(buf(o, PLAT_BLOCK), "车:" .. (i + 1) .. "(" .. PLAT_BLOCK .. "bytes),字节序(" .. rel .. "):数据长度:" .. PLAT_BLOCK)
        t:add(pf.train_set, buf(o, 4)):set_text("列车车组号[train_set](4bytes),字节序(" .. (rel + 0) .. "):" .. buf(o, 4):string())
        t:add(pf.service_no, buf(o + 4, 3)):set_text("列车服务号[service_no](3bytes),字节序(" .. (rel + 4) .. "):" .. buf(o + 4, 3):string())
        t:add(pf.first_train, buf(o + 7, 1)):set_text("首班列车[first_train](1bytes),字节序(" .. (rel + 7) .. "):" .. buf(o + 7, 1):string() .. desc(buf(o + 7, 1):string(), enum_first))
        t:add(pf.last_train, buf(o + 8, 1)):set_text("末班列车[last_train](1bytes),字节序(" .. (rel + 8) .. "):" .. buf(o + 8, 1):string() .. desc(buf(o + 8, 1):string(), enum_last))
        t:add(pf.platform_state, buf(o + 9, 1)):set_text("列车站台状态[platform_state](1bytes),字节序(" .. (rel + 9) .. "):" .. buf(o + 9, 1):string() .. desc(buf(o + 9, 1):string(), enum_pstate))
        t:add(pf.arrive_time, buf(o + 10, 19)):set_text("到站时间[arrive_time](19bytes),字节序(" .. (rel + 10) .. "):" .. fmt_time(buf, o + 10))
        t:add(pf.depart_time, buf(o + 29, 19)):set_text("离站时间[depart_time](19bytes),字节序(" .. (rel + 29) .. "):" .. fmt_time(buf, o + 29))
        t:add(pf.terminal_station, buf(o + 48, 3)):set_text("终点站号[terminal_station](3bytes),字节序(" .. (rel + 48) .. "):" .. buf(o + 48, 3):string())
        t:add(pf.train_run_on, buf(o + 51, 1)):set_text("列车运行于[train_run_on](1bytes),字节序(" .. (rel + 51) .. "):" .. buf(o + 51, 1):string() .. desc(buf(o + 51, 1):string(), enum_run_on))
        t:add(pf.dest_code, buf(o + 52, 3)):set_text("目的地码[dest_code](3bytes),字节序(" .. (rel + 52) .. "):" .. buf(o + 52, 3):string())
        t:add(pf.train_dir, buf(o + 55, 1)):set_text("列车方向[train_dir](1bytes),字节序(" .. (rel + 55) .. "):" .. buf(o + 55, 1):string() .. desc(buf(o + 55, 1):string(), enum_dir))
        t:add(pf.non_passenger, buf(o + 56, 1)):set_text("非载客列车[non_passenger](1bytes),字节序(" .. (rel + 56) .. "):" .. buf(o + 56, 1):string() .. desc(buf(o + 56, 1):string(), enum_nonpass))
        t:add(pf.train_approach, buf(o + 57, 1)):set_text("列车接近[train_approach](1bytes),字节序(" .. (rel + 57) .. "):" .. buf(o + 57, 1):string() .. desc(buf(o + 57, 1):string(), enum_approach))
        t:add(pf.ballast_train, buf(o + 58, 1)):set_text("轧道列车[ballast_train](1bytes),字节序(" .. (rel + 58) .. "):" .. buf(o + 58, 1):string() .. desc(buf(o + 58, 1):string(), enum_ballast))
        t:add(pf.hold_train, buf(o + 59, 1)):set_text("列车扣车标志[hold_train](1bytes),字节序(" .. (rel + 59) .. "):" .. buf(o + 59, 1):string() .. desc(buf(o + 59, 1):string(), enum_hold))
        t:add(pf.skip_stop, buf(o + 60, 1)):set_text("跳停标志[skip_stop](1bytes),字节序(" .. (rel + 60) .. "):" .. buf(o + 60, 1):string() .. desc(buf(o + 60, 1):string(), enum_skip))
        t:add(pf.clear_train, buf(o + 61, 1)):set_text("列车清客[clear_train](1bytes),字节序(" .. (rel + 61) .. "):" .. buf(o + 61, 1):string() .. desc(buf(o + 61, 1):string(), enum_clear02))
    end
    return off + 36 + num * PLAT_BLOCK
end

-- 信息类型 06: 当天使用的时刻表的全部信息 (行程循环M, 站台循环N)
local function parse_06(buf, off, tree)
    tree:add(pf.total_packets, buf(off + 29, 3)):set_text("6.总包数[total_packets](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    tree:add(pf.cur_packet, buf(off + 32, 3)):set_text("7.当前包序号[cur_packet](3bytes),字节序(32):" .. buf(off + 32, 3):string())
    tree:add(pf.service_no, buf(off + 35, 3)):set_text("8.列车服务号[service_no](3bytes),字节序(35):" .. buf(off + 35, 3):string())
    tree:add(pf.trip_count, buf(off + 38, 2)):set_text("9.行程数[trip_count](2bytes),字节序(38):" .. buf(off + 38, 2):string())
    local trips = tonumber(buf(off + 38, 2):string()) or 0
    local o = off + 40
    for m = 0, trips - 1 do
        local plat = tonumber(buf(o + 5, 2):string()) or 0
        local trip_len = 7 + plat * 42
        local rel_o = o - off
        local t = tree:add(buf(o, trip_len), "行程:" .. (m + 1) .. " ,站台数量:" .. plat .. "(tripbytes:" .. trip_len .. "),字节序(" .. rel_o .. ")")
        t:add(pf.trip_seq, buf(o, 2)):set_text("序列号[trip_seq](2bytes),字节序(" .. (rel_o + 0) .. "):" .. buf(o, 2):string())
        t:add(pf.dest_code, buf(o + 2, 3)):set_text("目的地码[dest_code](3bytes),字节序(" .. (rel_o + 2) .. "):" .. buf(o + 2, 3):string())
        t:add(pf.plat_count, buf(o + 5, 2)):set_text("站台数量[plat_count](2bytes),字节序(" .. (rel_o + 5) .. "):" .. buf(o + 5, 2):string())
        local po = o + 7
        for n = 0, plat - 1 do
            local rel_p = po - off
            local p = t:add(buf(po, 42), "站台:" .. (n + 1) .. "(42bytes),字节序(" .. rel_p .. ")")
            p:add(pf.station_no, buf(po, 3)):set_text("车站号[station_no](3bytes),字节序(" .. (rel_p + 0) .. "):" .. buf(po, 3):string())
            p:add(pf.platform_no, buf(po + 3, 1)):set_text("站台号[platform_no](1bytes),字节序(" .. (rel_p + 3) .. "):" .. buf(po + 3, 1):string() .. desc(buf(po + 3, 1):string(), enum_plat8))
            p:add(pf.arrive_time, buf(po + 4, 19)):set_text("到达时间[arrive_time](19bytes),字节序(" .. (rel_p + 4) .. "):" .. fmt_time(buf, po + 4))
            p:add(pf.depart_time, buf(po + 23, 19)):set_text("离站时间[depart_time](19bytes),字节序(" .. (rel_p + 23) .. "):" .. fmt_time(buf, po + 23))
            po = po + 42
        end
        o = o + trip_len
    end
    return o
end

-- 信息类型 07: SCADA供电区段
local function parse_07(buf, off, tree)
    tree:add(pf.section_count, buf(off + 29, 2)):set_text("6.供电区段数量[section_count](2bytes),字节序(29):" .. buf(off + 29, 2):string())
    local num = tonumber(buf(off + 29, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 31 + i
        local rel = 31 + i
        tree:add(pf.section_state, buf(o, 1)):set_text("供电区段[section_state]" .. (i + 1) .. "(1bytes),字节序(" .. rel .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_section))
    end
    return off + 31 + num
end

-- 信息类型 08/09: 回执信息 / 心跳信息（无数据域）
local function parse_08_09(buf, off, tree)
    return off + 29
end

-- 信息类型 15: 客流信息
-- ponytail: jnl7_ats.md 表内 CRC 写 39+N*8，但客流数据自31起每8字节，CRC 应为 31+N*8。
-- 与 cql15 同规格同处理，此处按结构结果 31+N*8 定位（39 疑为笔误），待确认。
local function parse_15(buf, off, tree)
    tree:add(pf.flow_count, buf(off + 29, 2)):set_text("6.客流信息的个数[flow_count](2bytes),字节序(29):" .. buf(off + 29, 2):string())
    local num = tonumber(buf(off + 29, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 31 + i * 8
        local rel = 31 + i * 8
        tree:add(pf.flow_value, buf(o, 8)):set_text("客流[flow_value]" .. (i + 1) .. "(8bytes),字节序(" .. rel .. "):" .. buf(o, 8):string())
    end
    return off + 31 + num * 8
end

-- 信息类型 17: 站台运营载客首末班车信息
local function parse_17(buf, off, tree)
    tree:add(pf.station_no, buf(off + 29, 3)):set_text("6.车站号[station_no](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    tree:add(pf.platform_no, buf(off + 32, 1)):set_text("7.站台号[platform_no](1bytes),字节序(32):" .. buf(off + 32, 1):string() .. desc(buf(off + 32, 1):string(), enum_plat))
    tree:add(pf.first_time, buf(off + 33, 19)):set_text("8.首班载客列车发车时间[first_time](19bytes),字节序(33):" .. fmt_time(buf, off + 33))
    tree:add(pf.first_terminal, buf(off + 52, 3)):set_text("9.首班载客列车终点站号[first_terminal](3bytes),字节序(52):" .. buf(off + 52, 3):string())
    tree:add(pf.last_time, buf(off + 55, 19)):set_text("10.末班载客列车发车时间[last_time](19bytes),字节序(55):" .. fmt_time(buf, off + 55))
    tree:add(pf.last_terminal, buf(off + 74, 3)):set_text("11.末班载客列车终点站编号[last_terminal](3bytes),字节序(74):" .. buf(off + 74, 3):string())
    return off + 77
end

-- 信息类型 19 (SIG方向): 段场出入库信息
local function parse_19(buf, off, tree)
    tree:add(pf.train_set, buf(off + 29, 4)):set_text("6.列车车组号[train_set](4bytes),字节序(29):" .. buf(off + 29, 4):string())
    tree:add(pf.train_pos, buf(off + 33, 1)):set_text("7.列车位置[train_pos](1bytes),字节序(33):" .. buf(off + 33, 1):string() .. desc(buf(off + 33, 1):string(), enum_pos))
    tree:add(pf.cur_track, buf(off + 34, 10)):set_text("8.列车当前运行轨道名称[cur_track](10bytes),字节序(34):" .. buf(off + 34, 10):string())
    tree:add(pf.depot_track, buf(off + 44, 10)):set_text("9.库线股道名称[depot_track](10bytes),字节序(44):" .. buf(off + 44, 10):string())
    tree:add(pf.inout_state, buf(off + 54, 1)):set_text("10.出入库状态[inout_state](1bytes),字节序(54):" .. buf(off + 54, 1):string() .. desc(buf(off + 54, 1):string(), enum_inout))
    return off + 55
end

-- 信息类型 19 (ISCS方向): FAS火灾信息
local function parse_fas(buf, off, tree)
    tree:add(pf.fas_count, buf(off + 29, 3)):set_text("6.FAS数量[fas_count](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    local num = tonumber(buf(off + 29, 3):string()) or 0
    for i = 0, num - 1 do
        local o = off + 32 + i
        local rel = 32 + i
        tree:add(pf.fas_state, buf(o, 1)):set_text("FAS[fas_state]" .. (i + 1) .. "(1bytes),字节序(" .. rel .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_fas))
    end
    return off + 32 + num
end

-- 信息类型 21: 区间超水位信息
local function parse_21(buf, off, tree)
    tree:add(pf.interval_count, buf(off + 29, 3)):set_text("6.区间数量[interval_count](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    local num = tonumber(buf(off + 29, 3):string()) or 0
    for i = 0, num - 1 do
        local o = off + 32 + i
        local rel = 32 + i
        tree:add(pf.interval_state, buf(o, 1)):set_text("区间[interval_state]" .. (i + 1) .. "(1bytes),字节序(" .. rel .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_interval))
    end
    return off + 32 + num
end

-- 信息类型 39: 信号设备状态信息 (每设备27字节, 状态2字节按信号类型解码)
local function parse_39(buf, off, tree)
    tree:add(pf.station_no, buf(off + 29, 3)):set_text("6.车站号[station_no](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    tree:add(pf.dev_count, buf(off + 32, 4)):set_text("7.设备数量[dev_count](4bytes),字节序(32):" .. buf(off + 32, 4):string())
    local num = tonumber(buf(off + 32, 4):string()) or 0
    for i = 0, num - 1 do
        local o = off + 36 + i * 27
        local rel = 36 + i * 27
        local st = buf(o, 1):string()
        local hi = buf(o + 25, 1):uint()
        local lo = buf(o + 26, 1):uint()
        local t = tree:add(buf(o, 27), "设备:" .. (i + 1) .. "(27bytes),字节序(" .. rel .. ")")
        t:add(pf.sig_type, buf(o, 1)):set_text("信号类型[sig_type](1bytes),字节序(" .. (rel + 0) .. "):" .. st .. desc(st, enum_sigtype))
        t:add(pf.dev_name, buf(o + 1, 24)):set_text("设备名称[dev_name](24bytes),字节序(" .. (rel + 1) .. "):" .. buf(o + 1, 24):string())
        local ds = dev_state_text(st, hi, lo)
        t:add(pf.dev_state, buf(o + 25, 2)):set_text("设备状态[dev_state](2bytes),字节序(" .. (rel + 25) .. "):0x" ..
            string.format("%02X%02X", hi, lo) .. (ds ~= "" and (" " .. ds) or ""))
    end
    return off + 36 + num * 27
end

local dissect_body = {
    ["01"] = parse_01,
    ["02"] = parse_02,
    ["06"] = parse_06,
    ["07"] = parse_07,
    ["08"] = parse_08_09,
    ["09"] = parse_08_09,
    ["15"] = parse_15,
    ["17"] = parse_17,
    ["19"] = parse_19,
    ["21"] = parse_21,
    ["39"] = parse_39,
}

-- 解析单条消息（头部 + 数据域 + CRC）
local function dissect_message(buf, off, total_len, subtree, is_sig)
    local type_str = buf(off + 3, 2):string()
    local name
    if type_str == "19" then
        name = is_sig and "段场出入库信息" or "FAS火灾信息"
    else
        name = dataTypeStr[type_str] or ("未知类型:" .. type_str)
    end

    local headerTree = subtree:add(buf(off, 29), "HEAD")
    headerTree:add(buf(off, 1), "1.信息头标识(1bytes),字节序(0):" .. string.format("0x%02X", buf(off, 1):uint()))
    headerTree:add(pf.seq, buf(off + 1, 2)):set_text("2.信息序号[seq](2bytes),字节序(1):" .. buf(off + 1, 2):string())
    headerTree:add(pf.data_type, buf(off + 3, 2)):set_text("3.信息类型[data_type](2bytes),字节序(3): " .. buf(off + 3, 2):string())
    headerTree:add(pf.data_len, buf(off + 5, 5)):set_text("4.信息长度[data_len](5bytes),字节序(5):" .. buf(off + 5, 5):string())
    headerTree:add(pf.send_time, buf(off + 10, 19)):set_text("5.数据发送时间[send_time](19bytes),字节序(10):" .. fmt_time(buf, off + 10))

    local crc_off = off + total_len - 2 -- 依据长度域确定CRC位置（最后一字节）
    local body_len = crc_off - (off + 29)
    local parse_crc = crc_off -- 实际CRC位置，以结构解析结果为准
    if body_len > 0 then
        local msg_tree = subtree:add(buf(off + 29, body_len),
            "Data:" .. name .. " ,type:" .. type_str .. " ,len:" .. body_len)
        local parser = dissect_body[type_str]
        if type_str == "19" then
            parser = is_sig and parse_19 or parse_fas
        end
        if parser then
            parse_crc = parser(buf, off, msg_tree)
            if parse_crc ~= crc_off then
                msg_tree:add(buf(parse_crc, 1), "⚠ 结构长度不一致:解析到" ..
                    (parse_crc - off) .. "，长度域声明" .. (crc_off - off) .. "（可能分包/计数异常）")
            end
        end
    end

    local calc = checksum_hex(buf, off, parse_crc)
    local got = buf(parse_crc, 2):string():upper()
    local status = (calc == got) and "OK" or ("FAIL(calc=" .. calc .. ")")
    subtree:add(pf.crc, buf(parse_crc, 2)):set_text("CRC校验[crc](2bytes),字节序(" .. (parse_crc - off) .. "):" .. got .. " [" .. status .. "]")
end

local function full_packet_dissactor(buffer, pinfo, tree)
    local b_offset = pinfo.desegment_offset or 0
    local buf_len = buffer:len()
    -- 头部最小需10字节(信息长度域完整)。头部分包我暂时没处理，目前假设头部不分包。
    if buf_len < 10 then return -1 end

    while b_offset < buf_len do
        -- 每条消息前先确保长度域(10字节)完整，避免同段多包时越界
        if b_offset + 10 > buf_len then
            pinfo.desegment_len = b_offset + 10 - buf_len
            pinfo.desegment_offset = b_offset
            return 0
        end
        -- 依据头部长度域获取当前应用层报文长度
        local type_str = buffer(b_offset + 3, 2):string()
        local total_len
        if type_str == "08" or type_str == "09" then
            -- 回执/心跳无独立数据域: 头部29(含时间) + CRC2 = 31, 长度域不可靠(样例占位00018)
            total_len = 31
        else
            local info_data_len = buffer(b_offset + 5, 5):string()
            local info_data_len_i = tonumber(info_data_len) or 0
            -- 长度域合理性: 数据域至少21字节，最大99999(类型06时刻表允许多包大长度)
            if info_data_len_i < 21 or info_data_len_i > 99999 then return -1 end
            total_len = 10 + info_data_len_i
        end
        if b_offset + total_len > buffer:len() then
            pinfo.desegment_len = b_offset + total_len - buffer:len()
            pinfo.desegment_offset = b_offset
            return 0
        end

        pinfo.cols.protocol = jnl7_protocol.name

        local subtree = tree:add(jnl7_protocol, buffer(b_offset, total_len),
                                 "JNL7 Protocol Data, Len: " .. total_len)

        local is_sig = sender_is_sig(pinfo)
        local dir = is_sig and "[SIG→ISCS]" or "[ISCS→SIG]"
        local tname = (type_str == "19")
            and (is_sig and "段场出入库信息" or "FAS火灾信息")
            or (dataTypeStr[type_str] or type_str)
        pinfo.cols.info = dir .. " " .. tname ..
            " seq=" .. buffer(b_offset + 1, 2):string()

        dissect_message(buffer, b_offset, total_len, subtree, is_sig)

        b_offset = b_offset + total_len
        if b_offset == buf_len then
            return 1
        end
        -- b_offset < buf_len 时继续下一轮
    end
end

function jnl7_protocol.dissector(buffer, pinfo, tree)
    local ret = full_packet_dissactor(buffer, pinfo, tree)
    if ret == 1 then
        -- 完整包
    elseif ret == 0 then
        -- 不完整包
    else
        -- 当发现不是我的协议时，就应该调用data
        data_dis:call(buffer, pinfo, tree)
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

local tcp_port = DissectorTable.get("tcp.port")

local function add_port()
    sig_ports = {}
    if jnl7_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(jnl7_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do
            tcp_port:add(port, jnl7_protocol)
            sig_ports[port] = true
        end
    end
end

add_port()
function jnl7_protocol.prefs_changed() add_port() end
