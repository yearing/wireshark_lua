-- 插件名: CQL15 Protocol
-- 版本: 2.1.0#20260807-1
-- 作者: 叶孟鹏
-- 描述: 重庆15号线 SIG-ISCS 接口协议（网络全局调度系统<->综合监控），
--       依据 CQS15A_SIG_TEC_ATS_024 V1.3 实现全部消息类型解析。
--       V1.3变更: 类型01列车运行信息增加"湿轨模式"字段，每列车记录49→50字节。
--       字段展示格式: 编号.名称(Nbytes),字节序(X):值 [过滤器名]
--       所有字段均已注册 ProtoField，可在显示过滤器按 cql15.* 过滤。
--       枚举字段(驾驶模式/列车位置/EB状态等)自动追加中文描述。
-- 更新时间: 2026-08-07
cq15_protocol = Proto("CQL15", "CQL15 Protocol")
-- 首选项
local prefs = cq15_protocol.prefs
prefs.my_version = Pref.statictext("version:2.1.0#20260807-1",
                                   "2.1.0#20260807-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "5000",
                                "CQL15默认端口")


-- 过滤器字段定义
local function sf(name, desc) -- ASCII字符串字段
    return ProtoField.string("cql15." .. name, desc, base.ASCII)
end
local pf = {
    -- 头部通用
    seq          = sf("seq", "2.信息序号"),
    data_type    = sf("data_type", "3.信息类型(data_type)"),
    data_len     = sf("data_len", "4.信息长度"),
    send_time    = ProtoField.bytes("cql15.send_time", "5.数据发送时间"),
    crc          = sf("crc", "CRC校验"),
    -- 类型01/02/18/19 共用列车字段
    train_count  = sf("train_count", "列车数量"),
    train_set    = sf("train_set", "列车车组号"),
    driver_no    = sf("driver_no", "列车司机号"),
    cbtc_flag    = sf("cbtc_flag", "CBTC/非CBTC状态"),
    train_pos    = sf("train_pos", "列车位置"),
    train_run_on = sf("train_run_on", "列车运行于"),
    station_no   = sf("station_no", "车站编号"),
    track_name   = sf("track_name", "轨道名称"),
    block_flag   = sf("block_flag", "列车阻塞标识"),
    train_dir    = sf("train_dir", "列车方向"),
    segment_id   = sf("segment_id", "列车运行线段ID(CBTC)"),
    offset_cbtc  = sf("offset_cbtc", "列车运行偏移量(CBTC)"),
    eb_state     = sf("eb_state", "EB状态"),
    drive_mode   = sf("drive_mode", "驾驶模式"),
    wet_rail     = sf("wet_rail", "湿轨模式"),
    -- 类型02 站台
    platform_no      = sf("platform_no", "站台号"),
    emergency_stop   = sf("emergency_stop", "站台紧停标志"),
    marshalling      = sf("marshalling", "列车编组信息"),
    timetable_no     = sf("timetable_no", "列车表号"),
    train_num        = sf("train_num", "列车车次号"),
    first_train      = sf("first_train", "首班列车"),
    last_train       = sf("last_train", "末班列车"),
    platform_state   = sf("platform_state", "列车站台状态"),
    arrive_time      = sf("arrive_time", "到站时间"),
    depart_time      = sf("depart_time", "离站时间"),
    terminal_station = sf("terminal_station", "终点站编号"),
    dest_code        = sf("dest_code", "目的地码"),
    non_passenger    = sf("non_passenger", "非载客列车"),
    train_approach   = sf("train_approach", "列车接近"),
    next_station     = sf("next_station", "下一停站车站编号"),
    ballast_train    = sf("ballast_train", "轧道列车"),
    fast_slow        = sf("fast_slow", "快慢车标识"),
    hold_train       = sf("hold_train", "列车扣车标志"),
    skip_stop        = sf("skip_stop", "列车跳停标志"),
    clear_train      = sf("clear_train", "列车清客标志"),
    -- 类型03 SPKS
    dev_count  = sf("dev_count", "设备数量"),
    sig_type   = sf("sig_type", "信号类型"),
    dev_name   = sf("dev_name", "设备名称"),
    dev_state  = ProtoField.uint16("cql15.dev_state", "设备状态", base.HEX),
    -- 类型06 时刻表
    total_packets = sf("total_packets", "总包数"),
    cur_packet    = sf("cur_packet", "当前包序号"),
    trip_count    = sf("trip_count", "行程数"),
    plat_count    = sf("plat_count", "站台数量"),
    -- 类型07 SCADA
    section_count = sf("section_count", "供电区段数量"),
    section_state = sf("section_state", "供电区段"),
    -- 类型15 客流
    flow_count = sf("flow_count", "客流信息的个数"),
    flow_value = sf("flow_value", "客流数"),
    -- 类型16 请求时刻表
    request_type = sf("request_type", "请求类型"),
    -- 类型18 列车联动
    sleep_state    = sf("sleep_state", "休眠"),
    wake_state     = sf("wake_state", "唤醒"),
    veh_state_count = sf("veh_state_count", "车辆设备状态数量"),
    veh_state       = ProtoField.uint8("cql15.veh_state", "车辆设备状态", base.HEX),
    -- 类型19 段场出入库
    cur_track   = sf("cur_track", "列车当前运行轨道名称"),
    depot_track = sf("depot_track", "库线股道名称"),
    inout_state = sf("inout_state", "出入库状态"),
    -- 类型19 ISCS方向 FAS
    fas_count = sf("fas_count", "FAS数量"),
    fas_state = sf("fas_state", "FAS"),
    -- 类型21 区间超水位
    interval_count = sf("interval_count", "区间数量"),
    interval_state = sf("interval_state", "区间"),
    -- 类型33 过分相
    phase_count = sf("phase_count", "分相区数量"),
    phase_state = sf("phase_state", "分相区"),
    -- 类型37 瓦斯
    gas_count = sf("gas_count", "区间的瓦斯检测预警信息数量"),
    gas_state = sf("gas_state", "瓦斯检测预警区间"),
}
cq15_protocol.fields = {}
for _, v in pairs(pf) do table.insert(cq15_protocol.fields, v) end


-- 枚举中文描述表
local enum_cbtc    = {["0"]="非CBTC车",["1"]="CBTC车"}
local enum_pos     = {["0"]="未知",["1"]="正线",["2"]="车辆段",["3"]="停车场",["4"]="停车场2"}
local enum_run_on  = {["0"]="未知",["1"]="上行线",["2"]="下行线"}
local enum_block   = {["0"]="非列车停车",["1"]="列车停车"}
local enum_dir     = {["0"]="未知",["1"]="左向",["2"]="右向"}
local enum_eb      = {["0"]="未激活",["1"]="激活"}
local enum_drive   = {["0"]="未知",["1"]="RM模式",["3"]="CM模式",["4"]="AM模式",["5"]="FAM模式",["6"]="CAM模式",["7"]="RRM模式",["8"]="ATB模式",["9"]="EUM模式"}
local enum_wet     = {["0"]="未激活",["1"]="激活"}
local enum_plat    = {["0"]="未知",["1"]="1站台",["2"]="2站台",["3"]="3站台",["4"]="4站台",["5"]="5站台",["6"]="6站台",["7"]="7站台",["8"]="8站台"}
local enum_emergency = {["0"]="未紧停",["1"]="紧停"}
local enum_marshal = {["0"]="未知编组",["4"]="4节编组",["6"]="6节编组",["8"]="8节编组"}
local enum_first   = {["0"]="非首班车",["1"]="首班车"}
local enum_last    = {["0"]="非末班车",["1"]="末班车"}
local enum_pstate  = {["0"]="未知",["1"]="到站",["2"]="离站"}
local enum_nonpass = {["0"]="载客列车",["1"]="非载客列车"}
local enum_approach= {["0"]="列车未到",["1"]="列车接近"}
local enum_ballast = {["0"]="非轧道列车",["1"]="轧道列车"}
local enum_fastslow= {["1"]="慢车",["2"]="快车"}
local enum_hold    = {["0"]="非扣车",["1"]="扣车"}
local enum_skip    = {["0"]="非跳停",["1"]="跳停"}
local enum_clear   = {["0"]="非清客",["1"]="临时清客",["2"]="计划清客"}
local enum_sigtype = {["4"]="SPKS"}
local enum_section = {["0"]="未知",["1"]="已供电",["2"]="未供电"}
local enum_request = {["01"]="请求当天计划图信息"}
local enum_inout   = {["0"]="未知",["1"]="出库",["2"]="入库"}
local enum_fas     = {["1"]="火灾激活",["2"]="火灾未激活"}
local enum_interval= {["1"]="超高水位",["2"]="非超高水位"}
local enum_phase   = {["0"]="启用",["1"]="不启用"}
local enum_gas     = {["1"]="浓度过大预警",["2"]="浓度未预警"}
local enum_sleep   = {["0"]="未激活",["1"]="激活"}
local enum_wake    = {["0"]="未激活",["1"]="激活"}

-- 值存在枚举描述则追加 " | 中文"
local function desc(v, t)
    local d = t and t[v]
    if d then return " | " .. d end
    return ""
end

local dataTypeStr = {
    ["01"] = "列车运行信息及列车阻塞信息",
    ["02"] = "站台信息",
    ["03"] = "SPKS设备状态信息",
    ["06"] = "当天使用的时刻表的全部信息",
    ["07"] = "SCADA供电区段",
    ["08"] = "回执信息",
    ["09"] = "心跳信息",
    ["15"] = "客流信息",
    ["16"] = "ISCS请求当天使用的计划时刻表的信息",
    ["18"] = "列车联动信息",
    ["19"] = "段场出入库信息", -- 类型19冲突: SIG方向=段场出入库, ISCS方向=FAS火灾信息(按TCP方向区分)
    ["21"] = "区间超水位信息",
    ["33"] = "过分相是否启用信息",
    ["37"] = "区间瓦斯检测预警信息",
}

local data_dis = Dissector.get("data")

-- SIG(网络全局调度系统)为服务端,监听注册端口; ISCS为客户端。
-- 类型19冲突: SIG发起=段场出入库, ISCS发起=FAS。据此方向区分。
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

-- 信息类型 01: 列车运行信息及列车阻塞信息 (V1.3: 每列车50字节,含湿轨模式)
local function parse_01(buf, off, tree)
    tree:add(pf.train_count, buf(off + 29, 2)):set_text("6.列车数量[train_count](2bytes),字节序(29):" .. buf(off + 29, 2):string())
    local num = tonumber(buf(off + 29, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 31 + i * 50
        local rel = 31 + i * 50
        local t = tree:add(buf(o, 50), "车:" .. (i + 1) .. "(50bytes),字节序(" .. rel .. "):数据长度:50")
        t:add(pf.train_set, buf(o, 5)):set_text("列车车组号[train_set](5bytes),字节序(" .. (rel + 0) .. "):" .. buf(o, 5):string())
        t:add(pf.driver_no, buf(o + 5, 5)):set_text("列车司机号[driver_no](5bytes),字节序(" .. (rel + 5) .. "):" .. buf(o + 5, 5):string())
        t:add(pf.cbtc_flag, buf(o + 10, 1)):set_text("CBTC/非CBTC状态[cbtc_flag](1bytes),字节序(" .. (rel + 10) .. "):" .. buf(o + 10, 1):string() .. desc(buf(o + 10, 1):string(), enum_cbtc))
        t:add(pf.train_pos, buf(o + 11, 1)):set_text("列车位置[train_pos](1bytes),字节序(" .. (rel + 11) .. "):" .. buf(o + 11, 1):string() .. desc(buf(o + 11, 1):string(), enum_pos))
        t:add(pf.train_run_on, buf(o + 12, 1)):set_text("列车运行于[train_run_on](1bytes),字节序(" .. (rel + 12) .. "):" .. buf(o + 12, 1):string() .. desc(buf(o + 12, 1):string(), enum_run_on))
        t:add(pf.station_no, buf(o + 13, 4)):set_text("车站编号[station_no](4bytes),字节序(" .. (rel + 13) .. "):" .. buf(o + 13, 4):string())
        t:add(pf.track_name, buf(o + 17, 10)):set_text("轨道名称[track_name](10bytes),字节序(" .. (rel + 17) .. "):" .. buf(o + 17, 10):string())
        t:add(pf.block_flag, buf(o + 27, 1)):set_text("列车阻塞标识[block_flag](1bytes),字节序(" .. (rel + 27) .. "):" .. buf(o + 27, 1):string() .. desc(buf(o + 27, 1):string(), enum_block))
        t:add(pf.train_dir, buf(o + 28, 1)):set_text("列车方向[train_dir](1bytes),字节序(" .. (rel + 28) .. "):" .. buf(o + 28, 1):string() .. desc(buf(o + 28, 1):string(), enum_dir))
        t:add(pf.segment_id, buf(o + 29, 10)):set_text("列车运行线段ID(CBTC)[segment_id](10bytes),字节序(" .. (rel + 29) .. "):" .. buf(o + 29, 10):string())
        t:add(pf.offset_cbtc, buf(o + 39, 8)):set_text("列车运行偏移量(CBTC)[offset_cbtc](8bytes),字节序(" .. (rel + 39) .. "):" .. buf(o + 39, 8):string())
        t:add(pf.eb_state, buf(o + 47, 1)):set_text("EB状态[eb_state](1bytes),字节序(" .. (rel + 47) .. "):" .. buf(o + 47, 1):string() .. desc(buf(o + 47, 1):string(), enum_eb))
        t:add(pf.drive_mode, buf(o + 48, 1)):set_text("驾驶模式[drive_mode](1bytes),字节序(" .. (rel + 48) .. "):" .. buf(o + 48, 1):string() .. desc(buf(o + 48, 1):string(), enum_drive))
        t:add(pf.wet_rail, buf(o + 49, 1)):set_text("湿轨模式[wet_rail](1bytes),字节序(" .. (rel + 49) .. "):" .. buf(o + 49, 1):string() .. desc(buf(o + 49, 1):string(), enum_wet))
    end
    return off + 31 + num * 50
end

-- 信息类型 02: 站台信息
local function parse_02(buf, off, tree)
    tree:add(pf.station_no, buf(off + 29, 4)):set_text("6.车站编号[station_no](4bytes),字节序(29):" .. buf(off + 29, 4):string())
    tree:add(pf.platform_no, buf(off + 33, 1)):set_text("7.站台号[platform_no](1bytes),字节序(33):" .. buf(off + 33, 1):string() .. desc(buf(off + 33, 1):string(), enum_plat))
    tree:add(pf.emergency_stop, buf(off + 34, 1)):set_text("8.站台紧停标志[emergency_stop](1bytes),字节序(34):" .. buf(off + 34, 1):string() .. desc(buf(off + 34, 1):string(), enum_emergency))
    tree:add(pf.train_count, buf(off + 35, 2)):set_text("9.列车数量[train_count](2bytes),字节序(35):" .. buf(off + 35, 2):string())
    local num = tonumber(buf(off + 35, 2):string()) or 0
    for i = 0, num - 1 do
        local o = off + 37 + i * 80
        local rel = 37 + i * 80
        local t = tree:add(buf(o, 80), "车:" .. (i + 1) .. "(80bytes),字节序(" .. rel .. "):数据长度:80")
        t:add(pf.train_set, buf(o, 5)):set_text("列车车组号[train_set](5bytes),字节序(" .. (rel + 0) .. "):" .. buf(o, 5):string())
        t:add(pf.marshalling, buf(o + 5, 1)):set_text("列车编组信息[marshalling](1bytes),字节序(" .. (rel + 5) .. "):" .. buf(o + 5, 1):string() .. desc(buf(o + 5, 1):string(), enum_marshal))
        t:add(pf.timetable_no, buf(o + 6, 3)):set_text("列车表号[timetable_no](3bytes),字节序(" .. (rel + 6) .. "):" .. buf(o + 6, 3):string())
        t:add(pf.train_num, buf(o + 9, 8)):set_text("列车车次号[train_num](8bytes),字节序(" .. (rel + 9) .. "):" .. buf(o + 9, 8):string())
        t:add(pf.first_train, buf(o + 17, 1)):set_text("首班列车[first_train](1bytes),字节序(" .. (rel + 17) .. "):" .. buf(o + 17, 1):string() .. desc(buf(o + 17, 1):string(), enum_first))
        t:add(pf.last_train, buf(o + 18, 1)):set_text("末班列车[last_train](1bytes),字节序(" .. (rel + 18) .. "):" .. buf(o + 18, 1):string() .. desc(buf(o + 18, 1):string(), enum_last))
        t:add(pf.platform_state, buf(o + 19, 1)):set_text("列车站台状态[platform_state](1bytes),字节序(" .. (rel + 19) .. "):" .. buf(o + 19, 1):string() .. desc(buf(o + 19, 1):string(), enum_pstate))
        t:add(pf.arrive_time, buf(o + 20, 19)):set_text("到站时间[arrive_time](19bytes),字节序(" .. (rel + 20) .. "):" .. fmt_time(buf, o + 20))
        t:add(pf.depart_time, buf(o + 39, 19)):set_text("离站时间[depart_time](19bytes),字节序(" .. (rel + 39) .. "):" .. fmt_time(buf, o + 39))
        t:add(pf.terminal_station, buf(o + 58, 4)):set_text("终点站编号[terminal_station](4bytes),字节序(" .. (rel + 58) .. "):" .. buf(o + 58, 4):string())
        t:add(pf.train_run_on, buf(o + 62, 1)):set_text("列车运行于[train_run_on](1bytes),字节序(" .. (rel + 62) .. "):" .. buf(o + 62, 1):string() .. desc(buf(o + 62, 1):string(), enum_run_on))
        t:add(pf.dest_code, buf(o + 63, 5)):set_text("目的地码[dest_code](5bytes),字节序(" .. (rel + 63) .. "):" .. buf(o + 63, 5):string())
        t:add(pf.train_dir, buf(o + 68, 1)):set_text("列车方向[train_dir](1bytes),字节序(" .. (rel + 68) .. "):" .. buf(o + 68, 1):string() .. desc(buf(o + 68, 1):string(), enum_dir))
        t:add(pf.non_passenger, buf(o + 69, 1)):set_text("非载客列车[non_passenger](1bytes),字节序(" .. (rel + 69) .. "):" .. buf(o + 69, 1):string() .. desc(buf(o + 69, 1):string(), enum_nonpass))
        t:add(pf.train_approach, buf(o + 70, 1)):set_text("列车接近[train_approach](1bytes),字节序(" .. (rel + 70) .. "):" .. buf(o + 70, 1):string() .. desc(buf(o + 70, 1):string(), enum_approach))
        t:add(pf.next_station, buf(o + 71, 4)):set_text("下一停站车站编号[next_station](4bytes),字节序(" .. (rel + 71) .. "):" .. buf(o + 71, 4):string())
        t:add(pf.ballast_train, buf(o + 75, 1)):set_text("轧道列车[ballast_train](1bytes),字节序(" .. (rel + 75) .. "):" .. buf(o + 75, 1):string() .. desc(buf(o + 75, 1):string(), enum_ballast))
        t:add(pf.fast_slow, buf(o + 76, 1)):set_text("快慢车标识[fast_slow](1bytes),字节序(" .. (rel + 76) .. "):" .. buf(o + 76, 1):string() .. desc(buf(o + 76, 1):string(), enum_fastslow))
        t:add(pf.hold_train, buf(o + 77, 1)):set_text("列车扣车标志[hold_train](1bytes),字节序(" .. (rel + 77) .. "):" .. buf(o + 77, 1):string() .. desc(buf(o + 77, 1):string(), enum_hold))
        t:add(pf.skip_stop, buf(o + 78, 1)):set_text("列车跳停标志[skip_stop](1bytes),字节序(" .. (rel + 78) .. "):" .. buf(o + 78, 1):string() .. desc(buf(o + 78, 1):string(), enum_skip))
        t:add(pf.clear_train, buf(o + 79, 1)):set_text("列车清客标志[clear_train](1bytes),字节序(" .. (rel + 79) .. "):" .. buf(o + 79, 1):string() .. desc(buf(o + 79, 1):string(), enum_clear))
    end
    return off + 37 + num * 80
end

-- 信息类型 03: SPKS设备状态信息
local function parse_03(buf, off, tree)
    tree:add(pf.station_no, buf(off + 29, 4)):set_text("6.车站编号[station_no](4bytes),字节序(29):" .. buf(off + 29, 4):string())
    tree:add(pf.dev_count, buf(off + 33, 4)):set_text("6.设备数量[dev_count](4bytes),字节序(33):" .. buf(off + 33, 4):string())
    local num = tonumber(buf(off + 33, 4):string()) or 0
    for i = 0, num - 1 do
        local o = off + 37 + i * 13
        local rel = 37 + i * 13
        local t = tree:add(buf(o, 13), "设备:" .. (i + 1) .. "(13bytes),字节序(" .. rel .. ")")
        t:add(pf.sig_type, buf(o, 1)):set_text("信号类型[sig_type](1bytes),字节序(" .. (rel + 0) .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_sigtype))
        t:add(pf.dev_name, buf(o + 1, 10)):set_text("设备名称[dev_name](10bytes),字节序(" .. (rel + 1) .. "):" .. buf(o + 1, 10):string())
        local lb = buf(o + 11, 1):uint()
        local desc = {}
        if lb % 2 == 1 then desc[#desc + 1] = "SPKS旁路" end
        if math.floor(lb / 2) % 2 == 1 then desc[#desc + 1] = "SPKS激活" end
        local d = (#desc > 0) and ("[" .. table.concat(desc, ",") .. "]") or ""
        t:add(pf.dev_state, buf(o + 11, 2)):set_text("设备状态[dev_state](2bytes),字节序(" .. (rel + 11) .. "):0x" ..
            string.format("%02X%02X", lb, buf(o + 12, 1):uint()) .. " " .. d)
    end
    return off + 37 + num * 13
end

-- 信息类型 06: 当天使用的时刻表的全部信息
local function parse_06(buf, off, tree)
    tree:add(pf.total_packets, buf(off + 29, 3)):set_text("6.总包数[total_packets](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    tree:add(pf.cur_packet, buf(off + 32, 3)):set_text("6.当前包序号[cur_packet](3bytes),字节序(32):" .. buf(off + 32, 3):string())
    tree:add(pf.timetable_no, buf(off + 35, 3)):set_text("7.列车表号[timetable_no](3bytes),字节序(35):" .. buf(off + 35, 3):string())
    tree:add(pf.trip_count, buf(off + 38, 2)):set_text("8.行程数[trip_count](2bytes),字节序(38):" .. buf(off + 38, 2):string())
    local trips = tonumber(buf(off + 38, 2):string()) or 0
    local o = off + 40
    for m = 0, trips - 1 do
        local plat = tonumber(buf(o + 13, 2):string()) or 0
        local trip_len = 15 + plat * 43
        local rel_o = o - off
        local t = tree:add(buf(o, trip_len), "行程:" .. (m + 1) .. " ,站台数量:" .. plat .. "(tripbytes:" .. trip_len .. "),字节序(" .. rel_o .. ")")
        t:add(pf.train_num, buf(o, 8)):set_text("列车车次号[train_num](8bytes),字节序(" .. (rel_o + 0) .. "):" .. buf(o, 8):string())
        t:add(pf.dest_code, buf(o + 8, 5)):set_text("目的地码[dest_code](5bytes),字节序(" .. (rel_o + 8) .. "):" .. buf(o + 8, 5):string())
        t:add(pf.plat_count, buf(o + 13, 2)):set_text("站台数量[plat_count](2bytes),字节序(" .. (rel_o + 13) .. "):" .. buf(o + 13, 2):string())
        local po = o + 15
        for n = 0, plat - 1 do
            local rel_p = po - off
            local p = t:add(buf(po, 43), "站台:" .. (n + 1) .. "(43bytes),字节序(" .. rel_p .. ")")
            p:add(pf.station_no, buf(po, 4)):set_text("车站编号[station_no](4bytes),字节序(" .. (rel_p + 0) .. "):" .. buf(po, 4):string())
            p:add(pf.platform_no, buf(po + 4, 1)):set_text("站台号[platform_no](1bytes),字节序(" .. (rel_p + 4) .. "):" .. buf(po + 4, 1):string() .. desc(buf(po + 4, 1):string(), enum_plat))
            p:add(pf.arrive_time, buf(po + 5, 19)):set_text("到达时间[arrive_time](19bytes),字节序(" .. (rel_p + 5) .. "):" .. fmt_time(buf, po + 5))
            p:add(pf.depart_time, buf(po + 24, 19)):set_text("离站时间[depart_time](19bytes),字节序(" .. (rel_p + 24) .. "):" .. fmt_time(buf, po + 24))
            po = po + 43
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

-- 信息类型 16: ISCS请求当天使用的计划时刻表的信息
local function parse_16(buf, off, tree)
    tree:add(pf.request_type, buf(off + 29, 2)):set_text("6.请求类型[request_type](2bytes),字节序(29):" .. buf(off + 29, 2):string() .. desc(buf(off + 29, 2):string(), enum_request))
    return off + 31
end

-- 信息类型 18: 列车联动信息
local function parse_18(buf, off, tree)
    tree:add(pf.train_count, buf(off + 29, 2)):set_text("6.列车数量[train_count](2bytes),字节序(29):" .. buf(off + 29, 2):string())
    local num = tonumber(buf(off + 29, 2):string()) or 0
    local o = off + 31
    for i = 0, num - 1 do
        local m = tonumber(buf(o + 8, 3):string()) or 0
        local train_len = 11 + m
        local rel_o = o - off
        local t = tree:add(buf(o, train_len), "车:" .. (i + 1) .. "(trainbytes:" .. train_len .. "),字节序(" .. rel_o .. ")")
        t:add(pf.train_set, buf(o, 5)):set_text("列车车组号[train_set](5bytes),字节序(" .. (rel_o + 0) .. "):" .. buf(o, 5):string())
        t:add(pf.eb_state, buf(o + 5, 1)):set_text("EB状态[eb_state](1bytes),字节序(" .. (rel_o + 5) .. "):" .. buf(o + 5, 1):string() .. desc(buf(o + 5, 1):string(), enum_eb))
        t:add(pf.sleep_state, buf(o + 6, 1)):set_text("休眠[sleep_state](1bytes),字节序(" .. (rel_o + 6) .. "):" .. buf(o + 6, 1):string() .. desc(buf(o + 6, 1):string(), enum_sleep))
        t:add(pf.wake_state, buf(o + 7, 1)):set_text("唤醒[wake_state](1bytes),字节序(" .. (rel_o + 7) .. "):" .. buf(o + 7, 1):string() .. desc(buf(o + 7, 1):string(), enum_wake))
        t:add(pf.veh_state_count, buf(o + 8, 3)):set_text("车辆设备状态数量[veh_state_count](3bytes),字节序(" .. (rel_o + 8) .. "):" .. buf(o + 8, 3):string())
        for j = 0, m - 1 do
            local so = o + 11 + j
            t:add(pf.veh_state, buf(so, 1)):set_text("车辆设备状态[veh_state]" .. (j + 1) .. "(1bytes),字节序(" .. (rel_o + 11 + j) .. "):0x" ..
                string.format("%02X", buf(so, 1):uint()))
        end
        o = o + train_len
    end
    return o
end

-- 信息类型 19 (SIG方向): 段场出入库信息
local function parse_19(buf, off, tree)
    tree:add(pf.train_set, buf(off + 29, 5)):set_text("6.列车车组号[train_set](5bytes),字节序(29):" .. buf(off + 29, 5):string())
    tree:add(pf.train_pos, buf(off + 34, 1)):set_text("6.列车位置[train_pos](1bytes),字节序(34):" .. buf(off + 34, 1):string() .. desc(buf(off + 34, 1):string(), enum_pos))
    tree:add(pf.cur_track, buf(off + 35, 10)):set_text("7.列车当前运行轨道名称[cur_track](10bytes),字节序(35):" .. buf(off + 35, 10):string())
    tree:add(pf.depot_track, buf(off + 45, 10)):set_text("8.库线股道名称[depot_track](10bytes),字节序(45):" .. buf(off + 45, 10):string())
    tree:add(pf.inout_state, buf(off + 55, 1)):set_text("9.出入库状态[inout_state](1bytes),字节序(55):" .. buf(off + 55, 1):string() .. desc(buf(off + 55, 1):string(), enum_inout))
    return off + 56
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

-- 信息类型 33: 过分相是否启用信息
local function parse_33(buf, off, tree)
    tree:add(pf.phase_count, buf(off + 29, 3)):set_text("6.分相区数量[phase_count](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    local num = tonumber(buf(off + 29, 3):string()) or 0
    for i = 0, num - 1 do
        local o = off + 32 + i
        local rel = 32 + i
        tree:add(pf.phase_state, buf(o, 1)):set_text("分相区[phase_state]" .. (i + 1) .. "(1bytes),字节序(" .. rel .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_phase))
    end
    return off + 32 + num
end

-- 信息类型 37: 区间瓦斯检测预警信息
local function parse_37(buf, off, tree)
    tree:add(pf.gas_count, buf(off + 29, 3)):set_text("6.区间的瓦斯检测预警信息数量[gas_count](3bytes),字节序(29):" .. buf(off + 29, 3):string())
    local num = tonumber(buf(off + 29, 3):string()) or 0
    for i = 0, num - 1 do
        local o = off + 32 + i
        local rel = 32 + i
        tree:add(pf.gas_state, buf(o, 1)):set_text("瓦斯检测预警区间[gas_state]" .. (i + 1) .. "(1bytes),字节序(" .. rel .. "):" .. buf(o, 1):string() .. desc(buf(o, 1):string(), enum_gas))
    end
    return off + 32 + num
end

local dissect_body = {
    ["01"] = parse_01,
    ["02"] = parse_02,
    ["03"] = parse_03,
    ["06"] = parse_06,
    ["07"] = parse_07,
    ["08"] = parse_08_09,
    ["09"] = parse_08_09,
    ["15"] = parse_15,
    ["16"] = parse_16,
    ["18"] = parse_18,
    ["19"] = parse_19,
    ["21"] = parse_21,
    ["33"] = parse_33,
    ["37"] = parse_37,
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
            -- 长度域合理性: 数据域至少21字节，最大32767
            if info_data_len_i < 21 or info_data_len_i > 32767 then return -1 end
            total_len = 10 + info_data_len_i
        end
        if b_offset + total_len > buffer:len() then
            pinfo.desegment_len = b_offset + total_len - buffer:len()
            pinfo.desegment_offset = b_offset
            return 0
        end

        pinfo.cols.protocol = cq15_protocol.name

        local subtree = tree:add(cq15_protocol, buffer(b_offset, total_len),
                                 "CQL15 Protocol Data, Len: " .. total_len)

        local is_sig = sender_is_sig(pinfo)
        local dir = is_sig and "[SIG→ISCS]" or "[ISCS→SIG]"
        local tname = (type_str == "19")
            and (is_sig and "段场出入库信息" or "FAS火灾信息")
            or (dataTypeStr[type_str] or type_str)
        pinfo.cols.info = "CQL15 " .. dir .. " " .. tname ..
            " seq=" .. buffer(b_offset + 1, 2):string()

        dissect_message(buffer, b_offset, total_len, subtree, is_sig)

        b_offset = b_offset + total_len
        if b_offset == buf_len then
            return 1
        end
        -- b_offset < buf_len 时继续下一轮
    end
end

function cq15_protocol.dissector(buffer, pinfo, tree)
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
    if cq15_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(cq15_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do
            tcp_port:add(port, cq15_protocol)
            sig_ports[port] = true
        end
    end
end

add_port()
function cq15_protocol.prefs_changed() add_port() end
