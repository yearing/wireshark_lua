-- 插件名: GZL1822/1012 ATS Protocol
-- 版本: 1.0.0#20260813-1
-- 作者: 叶孟鹏
-- 描述: 广州轨道交通18&22号线 / 10号线 ATS-ISCS 接口协议解析插件。
--       依据 gzl18_ats.md《GZL18&22-S1-1903 V1.1》与 gzl10_ats.md《GZL10-S1-1903 V1.9》实现。
--       协议结构: 帧头(0xEF 0xEF | 总帧数1 | 当前帧1 | Data_Len2 LE | Dev_Status1 | Data | 0xFD 0xFD)
--       应用帧: 消息类型(Type 2B LE) + 内容(content)
--       TCP承载, ATS为服务端, 监听端口10020(可配置)。
--       跨帧重组: Total>1 时按 Index 收集分片, 收集齐后按 Index 顺序拼接再解析。
--       列车信息(0x02)每列车尾按残差自动识别: 0字节=GZL18, 15字节=GZL10(驾驶模式/停车精度/速度/预留)。
--       字节序: 如无特别说明多字节低位在前(LE); 车门隔离/站台门隔离(0x05/0x06)为高字节在前(BE)。
--       字段展示格式: 名称[协议字段名](Nbytes),字节序(相对Data域起算):值
-- 更新时间: 2026-08-13
gzlats_protocol = Proto("GZLATS", "GZL1822/1012 ATS Protocol")
-- 首选项
local prefs = gzlats_protocol.prefs
prefs.my_version = Pref.statictext("version:1.0.0#20260813-1",
                                   "1.0.0#20260813-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "10020",
                                "GZL ATS服务端监听端口")


-- 过滤器字段定义
local function sf(name, desc)  return ProtoField.string("gzlats." .. name, desc, base.ASCII) end
local function u8(name, desc)  return ProtoField.uint8("gzlats." .. name, desc, base.DEC) end
local function u16(name, desc) return ProtoField.uint16("gzlats." .. name, desc, base.DEC) end
local function u32(name, desc) return ProtoField.uint32("gzlats." .. name, desc, base.DEC) end
local function u16x(name, desc) return ProtoField.uint16("gzlats." .. name, desc, base.HEX) end
local function u32x(name, desc) return ProtoField.uint32("gzlats." .. name, desc, base.HEX) end
local function bf(name, desc)  return ProtoField.bytes("gzlats." .. name, desc) end

local pf = {
    -- 帧层
    frame_head  = bf("frame_head", "帧头"),
    frame_total = u8("frame_total", "总帧数"),
    frame_index = u8("frame_index", "当前帧序号"),
    data_len    = u16("data_len", "Data域长度"),
    dev_status  = u8("dev_status", "设备主备状态"),
    frame_tail  = bf("frame_tail", "帧尾"),
    -- 应用帧
    msg_type    = u16x("msg_type", "消息类型"),
    hb_status   = u32x("hb_status", "心跳状态"),
    -- 0x02 列车信息
    train_cnt   = u16("train_cnt", "列车个数"),
    group_len   = u8("group_len", "车组号长度"),
    group_no    = sf("group_no", "车组号"),
    order_len   = u8("order_len", "车次号长度"),
    order_no    = sf("order_no", "车次号"),
    direction   = u8("direction", "方向"),
    station_no  = u16("station_no", "集中站编号"),
    section_id  = u16("section_id", "前端分区ID"),
    front_offset= u32("front_offset", "前端偏移量"),
    eb_state    = u8("eb_state", "紧急制动状态"),
    block_flag  = u8("block_flag", "阻塞标志"),
    sleep_wake  = u16x("sleep_wake", "休眠唤醒状态"),
    work_mode   = u8("work_mode", "工况信息"),
    auth_confirm= u8("auth_confirm", "全自动驾驶授权确认信息"),
    dep_req     = u8("dep_req", "发车请求"),
    cam_req     = u8("cam_req", "CAM模式请求状态"),
    clear_platform = u32("clear_platform", "清客站台ID"),
    over_under  = u8("over_under", "欠/超标状态"),
    jump_mode   = u8("jump_mode", "跳跃模式"),
    fire_alarm  = u8("fire_alarm", "火灾报警状态"),
    drive_mode  = u8("drive_mode", "列车驾驶模式"),
    stop_accuracy = u16("stop_accuracy", "停车精度"),
    speed       = u16("speed", "列车速度信息"),
    spare       = bf("spare", "预留"),
    -- 0x03 计划信息
    platform_cnt = u16("platform_cnt", "站台数"),
    station_id   = u16("station_id", "车站编号"),
    platform_id  = u8("platform_id", "站台编号"),
    train_per_platform = u16("train_per_platform", "站台列车趟数"),
    stop_type    = u8("stop_type", "停车类型"),
    plan_arrive  = bf("plan_arrive", "计划到站时间"),
    plan_depart  = bf("plan_depart", "计划离站时间"),
    terminal_station = u16("terminal_station", "终到站"),
    cur_state    = u8("cur_state", "当前状态"),
    hold_flag    = u8("hold_flag", "是否扣车"),
    fast_flag    = u8("fast_flag", "大站快车标志"),
    next_station_code = u16("next_station_code", "下一停车站站码"),
    clear_flag   = u8("clear_flag", "清客标志"),
    -- 0x04 首末班信息
    first_group_no = sf("first_group_no", "首班车组号"),
    first_order_no = sf("first_order_no", "首班车次号"),
    first_stop_type= u8("first_stop_type", "首班停车类型"),
    first_arrive = bf("first_arrive", "首班计划到站时间"),
    first_depart = bf("first_depart", "首班计划离站时间"),
    first_terminal = u16("first_terminal", "首班终到站"),
    last_group_no = sf("last_group_no", "末班车组号"),
    last_order_no = sf("last_order_no", "末班车次号"),
    last_stop_type = u8("last_stop_type", "末班停车类型"),
    last_arrive  = bf("last_arrive", "末班计划到站时间"),
    last_depart  = bf("last_depart", "末班计划离站时间"),
    last_terminal= u16("last_terminal", "末班终到站"),
    -- 0x05/0x06 车门/站台门隔离
    platform_track_id = u32x("platform_track_id", "站台(股道)ID"),
    psd1_id      = u32x("psd1_id", "1侧站台门ID"),
    isolate_req1 = bf("isolate_req1", "1侧故障隔离要求"),
    psd2_id      = u32x("psd2_id", "2侧站台门ID"),
    isolate_req2 = bf("isolate_req2", "2侧故障隔离要求"),
    door_state1  = bf("door_state1", "1侧每扇站台门状态"),
    door_state2  = bf("door_state2", "2侧每扇站台门状态"),
    -- 0x07 站场表示信息
    rtu_status   = u8("rtu_status", "RTU状态"),
    station_info_cnt = u8("station_info_cnt", "车站信息个数"),
    yard_station_code = u32("yard_station_code", "站码"),
    yard_info_len = u16("yard_info_len", "站场表示信息长"),
    dev_type     = u8("dev_type", "设备类型"),
    dev_id       = u32("dev_id", "设备编号"),
    color_len    = u8("color_len", "色码长度"),
    color_code   = bf("color_code", "色码"),
    -- 0x08 供电分区信息
    section_cnt  = u16("section_cnt", "供电区段数目"),
    section_no   = u16("section_no", "供电区段编号"),
    section_state= u8("section_state", "供电区段状态"),
    -- 0x09 首末班申请
    request_flag = u32x("request_flag", "申请"),
    -- 0x10 场段出入段计划信息
    plan_day     = bf("plan_day", "调度日"),
    graph_len    = u8("graph_len", "图号长度"),
    graph_no     = sf("graph_no", "图号"),
    depot_station= u16("depot_station", "段/场站码"),
    service_group_cnt = u8("service_group_cnt", "服务号组数"),
    service_len  = u8("service_len", "服务号长度"),
    service_no   = sf("service_no", "服务号"),
    out_depot_station = u16("out_depot_station", "出段/场站码"),
    out_order_len = u8("out_order_len", "出段/场车次号长度"),
    out_order_no  = sf("out_order_no", "出段/场车次号"),
    out_group_len = u8("out_group_len", "出段/场车组号长度"),
    out_group_no  = sf("out_group_no", "出段/场车组号"),
    out_track_len = u8("out_track_len", "段/场内出发股道名称长度"),
    out_track_name= sf("out_track_name", "段/场内出发股道名称"),
    out_plan_depart = bf("out_plan_depart", "段/场内计划出发时间"),
    out_depart    = bf("out_depart", "段/场内出发时间"),
    out_report    = u8("out_report", "段/场内报点标志"),
    out_conv_len  = u8("out_conv_len", "出段/场转换轨名称长度"),
    out_conv_track= sf("out_conv_track", "出段/场转换轨名称"),
    out_conv_plan_arrive = bf("out_conv_plan_arrive", "出段/场转换轨计划到达时间"),
    out_conv_arrive = bf("out_conv_arrive", "出段/场转换轨到达时间"),
    out_conv_plan_depart = bf("out_conv_plan_depart", "出段/场转换轨计划出发时间"),
    out_conv_depart = bf("out_conv_depart", "出段/场转换轨出发时间"),
    out_conv_report = u8("out_conv_report", "出段/场转换轨报点标志"),
    out_line_station = u16("out_line_station", "出段/场正线站码"),
    out_line_arrive = bf("out_line_arrive", "出段/场正线到达时间"),
    out_dest_code = sf("out_dest_code", "出段/场目的地码"),
    in_depot_station = u16("in_depot_station", "入段/场车辆段站码"),
    in_order_len = u8("in_order_len", "入段/场车次号长度"),
    in_order_no  = sf("in_order_no", "入段/场车次号"),
    in_group_len = u8("in_group_len", "入段/场车组号长度"),
    in_group_no  = sf("in_group_no", "入段/场车组号"),
    in_track_len = u8("in_track_len", "段/场内到达股道名称长度"),
    in_track_name= sf("in_track_name", "段/场内到达股道名称"),
    in_plan_arrive = bf("in_plan_arrive", "段/场内计划到达时间"),
    in_arrive    = bf("in_arrive", "段/场内到达时间"),
    in_report    = u8("in_report", "段/场内报点标志"),
    in_conv_len  = u8("in_conv_len", "入段/场转换轨名称长度"),
    in_conv_track= sf("in_conv_track", "入段/场转换轨名称"),
    in_conv_plan_arrive = bf("in_conv_plan_arrive", "入段/场转换轨计划到达时间"),
    in_conv_arrive = bf("in_conv_arrive", "入段/场转换轨到达时间"),
    in_conv_plan_depart = bf("in_conv_plan_depart", "入段/场转换轨计划出发时间"),
    in_conv_depart = bf("in_conv_depart", "入段/场转换轨出发时间"),
    in_conv_report = u8("in_conv_report", "入段/场转换轨报点标志"),
    in_line_station = u16("in_line_station", "入段/场正线站码"),
    in_line_arrive = bf("in_line_arrive", "入段/场正线到达时间"),
    in_dest_code = sf("in_dest_code", "入段/场目的地码"),
    init_flag    = u8("init_flag", "是否初始化生成"),
    init_time    = bf("init_time", "初始化时间"),
    wash_flag    = u8("wash_flag", "是否回段洗车"),
    spare2       = bf("spare2", "预留"),
    wake_flag    = u8("wake_flag", "是否自动唤醒"),
    wake_time    = bf("wake_time", "计划唤醒时间"),
    clean_flag   = u8("clean_flag", "是否回库清扫"),
    clean_start  = bf("clean_start", "清扫开始时间"),
    clean_end    = bf("clean_end", "清扫结束时间"),
    sleep_flag   = u8("sleep_flag", "是否自动休眠"),
    -- 0x11/0x12/0x13 火灾/水位
    fire_station_cnt = u16("fire_station_cnt", "车站数目"),
    fire_station_id  = u16("fire_station_id", "车站编号"),
    station_fire_state = u8("station_fire_state", "车站火灾状态"),
    interval_cnt = u16("interval_cnt", "区间数目"),
    interval_no  = u16("interval_no", "区间编号"),
    interval_fire_state = u8("interval_fire_state", "区间火灾状态"),
    sensor_cnt   = u16("sensor_cnt", "轨面水位传感器数目"),
    sensor_no    = u16("sensor_no", "轨面水位传感器编号"),
    water_alarm  = u8("water_alarm", "轨面水位告警标志"),
}
gzlats_protocol.fields = {}
for _, v in pairs(pf) do table.insert(gzlats_protocol.fields, v) end


-- 枚举中文描述表
local enum_dev     = {[1]="主机", [2]="备机"}
local enum_dir     = {[1]="向右", [2]="向左"}
local enum_eb      = {[0x55]="无紧急制动", [0xAA]="紧急制动"}
local enum_block   = {[0]="未阻塞", [1]="阻塞"}
local enum_sleep   = {["0x01ff"]="唤醒-允许休眠", ["0xff01"]="休眠-允许唤醒", ["0x0104"]="唤醒-不允许休眠",
                      ["0x0204"]="唤醒中", ["0x03ff"]="唤醒失败-允许休眠", ["0x0304"]="唤醒失败-不允许休眠",
                      ["0x0401"]="休眠-不允许唤醒", ["0x0402"]="休眠中", ["0x0403"]="休眠失败"}
local enum_work    = {[0]="无工况", [1]="待命", [2]="场内运行", [3]="进入正线服务",
                      [4]="停止正线服务", [5]="清扫", [6]="洗车", [7]="检修"}
local enum_auth    = {[0x55]="确认收到全自动驾驶授权", [0xAA]="确认收到禁止全自动驾驶命令", [0xFF]="无命令"}
local enum_depreq  = {[0x55]="发车请求", [0xAA]="无发车请求"}
local enum_cam     = {[0x55]="申请进入蠕动模式", [0xFF]="默认值"}
local enum_ou      = {[0x55]="过标或正值", [0xAA]="欠标或负值", [0xFF]="默认值"}
local enum_jump    = {[0x55]="跳跃中", [0xAA]="未跳跃"}
local enum_fire    = {[0x55]="有火灾报警", [0xFF]="无报警"}
local enum_drive   = {[1]="AM", [2]="CM", [3]="RM", [4]="EUM", [5]="FAM", [6]="CAM",
                      [7]="RM60", [8]="RRM", [0xFF]="默认"}
local enum_stop    = {[0]="到站停车", [1]="到站不停车"}
local enum_state   = {[0]="未进站", [1]="即将进站", [2]="到站停稳"}
local enum_hold    = {[0]="未扣车", [1]="扣车中"}
local enum_fast    = {[0]="普通车", [1]="大站快车"}
local enum_clear   = {[0]="不清客", [1]="清客"}
local enum_section = {[0]="未知", [1]="供电中", [2]="未供电"}
local enum_station_fire = {[0]="未知", [1]="有火灾", [2]="无火灾"}
local enum_interval_fire = {[0]="无火灾", [1]="有火灾"}
local enum_water   = {[0]="无告警", [1]="有告警"}
local enum_devtype = {[0x11]="逻辑区段", [0x14]="道岔", [0x21]="信号机", [0x52]="ESB按钮",
                      [0x62]="防淹门", [0x63]="SPKS状态灯", [0x64]="SPKS旁路按钮"}

local function desc(v, t)
    local d = t and t[v]
    if d then return " | " .. d end
    return ""
end

-- 消息类型->名称
local msgName = {
    [0x01] = "心跳信息",
    [0x02] = "列车信息",
    [0x03] = "计划信息",
    [0x04] = "首末班信息",
    [0x05] = "车门隔离状态信息",
    [0x06] = "站台门隔离状态信息",
    [0x07] = "站场表示信息",
    [0x08] = "供电分区信息",
    [0x09] = "首末班申请",
    [0x10] = "场段出入段计划信息",
    [0x11] = "车站火灾信息",
    [0x12] = "区间火灾信息",
    [0x13] = "区间轨面水位告警信息",
}

local data_dis = Dissector.get("data")
local ats_ports = {}

-- 方向判断: ATS为服务端(监听端口), src端口为ATS端口→ATS发起
local function sender_is_ats(pinfo)
    if ats_ports[pinfo.src_port] then return true end
    if ats_ports[pinfo.dst_port] then return false end
    return true -- 兜底默认ATS
end

-- 7字节时间: 年2LE + 月日时分秒各1
local function t7(c, off)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",
        c(off, 2):le_uint(), c(off + 2, 1):uint(), c(off + 3, 1):uint(),
        c(off + 4, 1):uint(), c(off + 5, 1):uint(), c(off + 6, 1):uint())
end

-- 色码小端数值(限6字节, 避免超过Lua double精确范围)
local function le_bytes_num(cs)
    local v = 0
    local n = math.min(cs:len(), 6)
    for i = 0, n - 1 do v = v + cs(i, 1):uint() * (256 ^ i) end
    return v
end

-- 字节显示为十六进制(避免raw()中NUL截断标签)
local function rawhex(r)
    local t = {}
    for i = 0, r:len() - 1 do t[#t + 1] = string.format("%02x", r(i, 1):uint()) end
    return table.concat(t, " ")
end

local color_name = {[0]="无色", [1]="绿", [2]="黄", [3]="红", [4]="白", [5]="蓝",
                    [6]="灰", [7]="紫", [8]="黑", [9]="橙", [10]="青"}

-- 设备色码位解码(附录4)
local function color_code_text(dt, cs)
    if cs:len() < 1 then return "" end
    local v = le_bytes_num(cs)
    local t = {}
    if dt == 0x11 then -- 逻辑区段
        for _, b in ipairs({{0x2,"非通信占用"},{0x4,"锁闭"},{0x8,"故障锁闭"},{0x10,"封锁"},
                            {0x20,"CBTC占用"},{0x40,"保护区段锁闭"},{0x80,"区段切除"},
                            {0x400,"计轴复位"},{0x800000,"ARB故障"}}) do
            if v & b[1] ~= 0 then t[#t + 1] = b[2] end
        end
        return "[" .. table.concat(t, ",") .. "]"
    elseif dt == 0x14 then -- 道岔
        local pos = {[0]="四开", [1]="定位", [2]="反位", [3]="挤岔"}
        for _, b in ipairs({{0x2,"非通信占用"},{0x4,"锁闭"},{0x8,"故障锁闭"},{0x40,"单锁"},
                            {0x80,"单封"},{0x100,"CBTC占用"},{0x200,"保护区段锁闭"},
                            {0x400,"轨道切除"},{0x800,"区段封锁"},{0x40000000,"ARB故障"}}) do
            if v & b[1] ~= 0 then t[#t + 1] = b[2] end
        end
        table.insert(t, 1, "位置:" .. (pos[(v >> 4) & 3] or "?"))
        return "[" .. table.concat(t, ",") .. "]"
    elseif dt == 0x21 then -- 信号机: 低位色(bit1-4) 低位闪(5) 高位色(6-9) 高位闪(10) 关闭(12)
        local b0 = cs(0, 1):uint()
        local b1 = cs:len() >= 2 and cs(1, 1):uint() or 0
        local low = (b0 >> 1) & 0xF
        local high = ((b1 & 0x3) << 2) | ((b0 >> 6) & 0x3)
        local s = "低位:" .. (color_name[low] or "?")
        if (b0 >> 5) & 1 == 1 then s = s .. "闪" end
        s = s .. " 高位:" .. (color_name[high] or "?")
        if (b1 >> 2) & 1 == 1 then s = s .. "闪" end
        if (b1 >> 4) & 1 == 1 then s = s .. " 室外关闭" end
        return "[" .. s .. "]"
    elseif dt == 0x52 then -- ESB按钮
        if v & 2 ~= 0 then return "[站台紧急关闭]" end
    elseif dt == 0x62 then -- 防淹门
        if v & 2 ~= 0 then t[#t + 1] = "门关闭" else t[#t + 1] = "门打开" end
        if v & 4 ~= 0 then t[#t + 1] = "关门请求" end
        if v & 8 ~= 0 then t[#t + 1] = "关门允许" end
        return "[" .. table.concat(t, ",") .. "]"
    elseif dt == 0x63 then -- SPKS状态灯
        if v & 2 ~= 0 then return "[灯亮]" else return "[灯灭]" end
    elseif dt == 0x64 then -- SPKS旁路按钮
        if v & 2 ~= 0 then return "[按钮按下]" end
    end
    return ""
end


-- ============ 0x01 心跳: Content = 状态(4) = 0xFFFFFFFF ============
local function parse_01(c, tree)
    tree:add(pf.hb_status, c(0, 4)):set_text("状态[hb_status](4bytes),字节序(0):0x" ..
        string.format("%08x", c(0, 4):le_uint()))
    return 4
end

-- ============ 0x02 列车信息 (GZL18/GZL10 自动识别) ============
local FIXED_COMMON = 24 -- 每列车固定字段(方向~火灾报警)字节数
-- 识别线路: 每列车公共部分之后的残差 0=GZL18, 15=GZL10
local function detect_train_tail(c, cnt)
    if cnt == 0 then return 0 end
    local function run(tail)
        local o = 2
        for i = 1, cnt do
            if o + 2 > c:len() then return false end
            local n1 = c(o, 1):uint(); o = o + 1 + n1
            if o + 1 > c:len() then return false end
            local n2 = c(o, 1):uint(); o = o + 1 + n2
            o = o + FIXED_COMMON + tail
        end
        return o == c:len()
    end
    if run(0) then return 0 end
    if run(15) then return 15 end
    return 0 -- 默认按 GZL18
end

local function parse_02(c, tree)
    local o = 0
    local cnt = c(o, 2):le_uint()
    tree:add(pf.train_cnt, c(o, 2)):set_text("列车个数[train_cnt](2bytes),字节序(0):" .. cnt)
    o = o + 2
    local tail = detect_train_tail(c, cnt)
    local line = (tail == 15) and "GZL10" or "GZL18"
    tree:add("识别线路: " .. line .. " (每列车尾" .. tail .. "字节)")
    for i = 1, cnt do
        if o + 2 > c:len() then tree:add(c(o, c:len() - o), "⚠ 列车数据不完整"); break end
        local t = tree:add(c(o, 1), "车:" .. i)
        local n1 = c(o, 1):uint()
        t:add(pf.group_len, c(o, 1)):set_text("车组号长度[group_len](1bytes),字节序(" .. o .. "):" .. n1); o = o + 1
        if n1 > 0 then t:add(pf.group_no, c(o, n1)):set_text("车组号[group_no](" .. n1 .. "bytes),字节序(" .. o .. "):" .. c(o, n1):string()) end
        o = o + n1
        if o >= c:len() then tree:add(c(o - 1, 1), "⚠ 数据不完整"); break end
        local n2 = c(o, 1):uint()
        t:add(pf.order_len, c(o, 1)):set_text("车次号长度[order_len](1bytes),字节序(" .. o .. "):" .. n2); o = o + 1
        if n2 > 0 then t:add(pf.order_no, c(o, n2)):set_text("车次号[order_no](" .. n2 .. "bytes),字节序(" .. o .. "):" .. c(o, n2):string()) end
        o = o + n2
        t:add(pf.direction, c(o, 1)):set_text("方向[direction](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_dir)); o = o + 1
        t:add(pf.station_no, c(o, 2)):set_text("集中站编号[station_no](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        t:add(pf.section_id, c(o, 2)):set_text("前端分区ID[section_id](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        t:add(pf.front_offset, c(o, 4)):set_text("前端偏移量[front_offset](4bytes),字节序(" .. o .. "):" .. c(o, 4):le_uint()); o = o + 4
        t:add(pf.eb_state, c(o, 1)):set_text("紧急制动状态[eb_state](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_eb)); o = o + 1
        t:add(pf.block_flag, c(o, 1)):set_text("阻塞标志[block_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_block)); o = o + 1
        local sw = c(o, 2):le_uint()
        t:add(pf.sleep_wake, c(o, 2)):set_text("休眠唤醒状态[sleep_wake](2bytes),字节序(" .. o .. "):0x" .. string.format("%04x", sw) .. desc(string.format("0x%04x", sw), enum_sleep)); o = o + 2
        t:add(pf.work_mode, c(o, 1)):set_text("工况信息[work_mode](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_work)); o = o + 1
        t:add(pf.auth_confirm, c(o, 1)):set_text("全自动驾驶授权确认信息[auth_confirm](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_auth)); o = o + 1
        t:add(pf.dep_req, c(o, 1)):set_text("发车请求[dep_req](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_depreq)); o = o + 1
        t:add(pf.cam_req, c(o, 1)):set_text("CAM模式请求状态[cam_req](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_cam)); o = o + 1
        t:add(pf.clear_platform, c(o, 4)):set_text("清客站台ID[clear_platform](4bytes),字节序(" .. o .. "):" .. c(o, 4):le_uint()); o = o + 4
        t:add(pf.over_under, c(o, 1)):set_text("欠/超标状态[over_under](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_ou)); o = o + 1
        t:add(pf.jump_mode, c(o, 1)):set_text("跳跃模式[jump_mode](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_jump)); o = o + 1
        t:add(pf.fire_alarm, c(o, 1)):set_text("火灾报警状态[fire_alarm](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_fire)); o = o + 1
        if tail == 15 then -- GZL10 尾部: 驾驶模式1 停车精度2 速度2 预留10
            t:add(pf.drive_mode, c(o, 1)):set_text("列车驾驶模式[drive_mode](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", c(o, 1):uint()) .. desc(c(o, 1):uint(), enum_drive)); o = o + 1
            t:add(pf.stop_accuracy, c(o, 2)):set_text("停车精度[stop_accuracy](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
            t:add(pf.speed, c(o, 2)):set_text("列车速度信息[speed](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
            t:add(pf.spare, c(o, 10)):set_text("预留[spare](10bytes),字节序(" .. o .. "):" .. rawhex(c(o, 10))); o = o + 10
        end
    end
    if o < c:len() then tree:add(c(o, c:len() - o), "⚠ 尾部未解析(" .. (c:len() - o) .. "bytes):" .. rawhex(c(o, c:len() - o))) end
    return o
end

-- ============ 0x03 计划信息 ============
local function parse_03(c, tree)
    local o = 0
    local pcnt = c(o, 2):le_uint()
    tree:add(pf.platform_cnt, c(o, 2)):set_text("站台数[platform_cnt](2bytes),字节序(0):" .. pcnt); o = o + 2
    for p = 1, pcnt do
        if o + 5 > c:len() then tree:add(c(o, c:len() - o), "⚠ 站台数据不完整"); break end
        local pt = tree:add(c(o, 1), "站台:" .. p)
        pt:add(pf.station_id, c(o, 2)):set_text("车站编号[station_id](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        pt:add(pf.platform_id, c(o, 1)):set_text("站台编号[platform_id](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        local tcnt = c(o, 2):le_uint()
        pt:add(pf.train_per_platform, c(o, 2)):set_text("站台列车趟数[train_per_platform](2bytes),字节序(" .. o .. "):" .. tcnt); o = o + 2
        for t = 1, tcnt do
            if o + 2 > c:len() then tree:add(c(o, c:len() - o), "⚠ 列车计划不完整"); break end
            local tt = pt:add(c(o, 1), "列车:" .. t)
            local n1 = c(o, 1):uint()
            tt:add(pf.group_len, c(o, 1)):set_text("车组号长度[group_len](1bytes),字节序(" .. o .. "):" .. n1); o = o + 1
            if n1 > 0 then tt:add(pf.group_no, c(o, n1)):set_text("车组号[group_no](" .. n1 .. "bytes),字节序(" .. o .. "):" .. c(o, n1):string()) end
            o = o + n1
            if o >= c:len() then break end
            local n2 = c(o, 1):uint()
            tt:add(pf.order_len, c(o, 1)):set_text("车次号长度[order_len](1bytes),字节序(" .. o .. "):" .. n2); o = o + 1
            if n2 > 0 then tt:add(pf.order_no, c(o, n2)):set_text("车次号[order_no](" .. n2 .. "bytes),字节序(" .. o .. "):" .. c(o, n2):string()) end
            o = o + n2
            tt:add(pf.stop_type, c(o, 1)):set_text("停车类型[stop_type](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_stop)); o = o + 1
            tt:add(pf.plan_arrive, c(o, 7)):set_text("计划到站时间[plan_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
            tt:add(pf.plan_depart, c(o, 7)):set_text("计划离站时间[plan_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
            tt:add(pf.terminal_station, c(o, 2)):set_text("终到站[terminal_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
            tt:add(pf.cur_state, c(o, 1)):set_text("当前状态[cur_state](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_state)); o = o + 1
            tt:add(pf.hold_flag, c(o, 1)):set_text("是否扣车[hold_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_hold)); o = o + 1
            tt:add(pf.spare, c(o, 1)):set_text("预留[spare](1bytes),字节序(" .. o .. "):" .. rawhex(c(o, 1))); o = o + 1
            tt:add(pf.fast_flag, c(o, 1)):set_text("大站快车标志[fast_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_fast)); o = o + 1
            tt:add(pf.next_station_code, c(o, 2)):set_text("下一停车站站码[next_station_code](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
            tt:add(pf.clear_flag, c(o, 1)):set_text("清客标志[clear_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_clear)); o = o + 1
            tt:add(pf.spare, c(o, 1)):set_text("预留[spare](1bytes),字节序(" .. o .. "):" .. rawhex(c(o, 1))); o = o + 1
        end
    end
    return o
end

-- ============ 0x04 首末班信息 ============
local function parse_04(c, tree)
    local o = 0
    local pcnt = c(o, 2):le_uint()
    tree:add(pf.platform_cnt, c(o, 2)):set_text("站台数[platform_cnt](2bytes),字节序(0):" .. pcnt); o = o + 2
    for p = 1, pcnt do
        if o + 3 > c:len() then tree:add(c(o, c:len() - o), "⚠ 站台数据不完整"); break end
        local pt = tree:add(c(o, 1), "站台:" .. p)
        pt:add(pf.station_id, c(o, 2)):set_text("车站编号[station_id](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        pt:add(pf.platform_id, c(o, 1)):set_text("站台编号[platform_id](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        -- 首班
        local n1 = c(o, 1):uint()
        pt:add(pf.group_len, c(o, 1)):set_text("首班车组号长度[group_len](1bytes),字节序(" .. o .. "):" .. n1); o = o + 1
        if n1 > 0 then pt:add(pf.first_group_no, c(o, n1)):set_text("首班车组号[first_group_no](" .. n1 .. "bytes),字节序(" .. o .. "):" .. c(o, n1):string()) end
        o = o + n1
        local n2 = c(o, 1):uint()
        pt:add(pf.order_len, c(o, 1)):set_text("首班车次号长度[order_len](1bytes),字节序(" .. o .. "):" .. n2); o = o + 1
        if n2 > 0 then pt:add(pf.first_order_no, c(o, n2)):set_text("首班车次号[first_order_no](" .. n2 .. "bytes),字节序(" .. o .. "):" .. c(o, n2):string()) end
        o = o + n2
        pt:add(pf.first_stop_type, c(o, 1)):set_text("首班停车类型[first_stop_type](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_stop)); o = o + 1
        pt:add(pf.first_arrive, c(o, 7)):set_text("首班计划到站时间[first_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        pt:add(pf.first_depart, c(o, 7)):set_text("首班计划离站时间[first_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        pt:add(pf.first_terminal, c(o, 2)):set_text("首班终到站[first_terminal](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        -- 末班
        local m1 = c(o, 1):uint()
        pt:add(pf.group_len, c(o, 1)):set_text("末班车组号长度[group_len](1bytes),字节序(" .. o .. "):" .. m1); o = o + 1
        if m1 > 0 then pt:add(pf.last_group_no, c(o, m1)):set_text("末班车组号[last_group_no](" .. m1 .. "bytes),字节序(" .. o .. "):" .. c(o, m1):string()) end
        o = o + m1
        local m2 = c(o, 1):uint()
        pt:add(pf.order_len, c(o, 1)):set_text("末班车次号长度[order_len](1bytes),字节序(" .. o .. "):" .. m2); o = o + 1
        if m2 > 0 then pt:add(pf.last_order_no, c(o, m2)):set_text("末班车次号[last_order_no](" .. m2 .. "bytes),字节序(" .. o .. "):" .. c(o, m2):string()) end
        o = o + m2
        pt:add(pf.last_stop_type, c(o, 1)):set_text("末班停车类型[last_stop_type](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_stop)); o = o + 1
        pt:add(pf.last_arrive, c(o, 7)):set_text("末班计划到站时间[last_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        pt:add(pf.last_depart, c(o, 7)):set_text("末班计划离站时间[last_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        pt:add(pf.last_terminal, c(o, 2)):set_text("末班终到站[last_terminal](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
    end
    return o
end

-- ============ 0x05 车门隔离状态信息 (字节序高字节在前) ============
local function parse_05(c, tree)
    local o = 0
    tree:add(pf.platform_track_id, c(o, 4)):set_text("站台(股道)ID[platform_track_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
    tree:add(pf.psd1_id, c(o, 4)):set_text("1侧站台门ID[psd1_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
    tree:add(pf.isolate_req1, c(o, 8)):set_text("1侧故障隔离站台门要求[isolate_req1](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
    tree:add(pf.psd2_id, c(o, 4)):set_text("2侧站台门ID[psd2_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
    tree:add(pf.isolate_req2, c(o, 8)):set_text("2侧故障隔离站台门要求[isolate_req2](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
    return o
end

-- ============ 0x06 站台门隔离状态信息 (字节序高字节在前) ============
local function parse_06(c, tree)
    local o = 0
    local pcnt = c(o, 1):uint()
    tree:add(pf.platform_cnt, c(o, 1)):set_text("站台个数[platform_cnt](1bytes),字节序(0):" .. pcnt); o = o + 1
    for p = 1, pcnt do
        if o + 44 > c:len() then tree:add(c(o, c:len() - o), "⚠ 站台数据不完整"); break end
        local pt = tree:add(c(o, 1), "站台:" .. p)
        pt:add(pf.platform_track_id, c(o, 4)):set_text("站台(股道)ID[platform_track_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
        pt:add(pf.psd1_id, c(o, 4)):set_text("1侧站台门ID[psd1_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
        pt:add(pf.isolate_req1, c(o, 8)):set_text("1侧故障隔离车门要求[isolate_req1](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
        pt:add(pf.door_state1, c(o, 8)):set_text("1侧每扇站台门打开状态[door_state1](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
        pt:add(pf.psd2_id, c(o, 4)):set_text("2侧站台门ID[psd2_id](4bytes),字节序(" .. o .. "):0x" .. string.format("%08x", c(o, 4):uint())); o = o + 4
        pt:add(pf.isolate_req2, c(o, 8)):set_text("2侧故障隔离车门要求[isolate_req2](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
        pt:add(pf.door_state2, c(o, 8)):set_text("2侧每扇站台门打开状态[door_state2](8bytes),字节序(" .. o .. "):" .. rawhex(c(o, 8))); o = o + 8
    end
    return o
end

-- ============ 0x07 站场表示信息 ============
local function parse_07(c, tree)
    local o = 0
    tree:add(pf.rtu_status, c(o, 1)):set_text("RTU状态[rtu_status](1bytes),字节序(0):" .. c(o, 1):uint()); o = o + 1
    local scnt = c(o, 1):uint()
    tree:add(pf.station_info_cnt, c(o, 1)):set_text("车站信息个数[station_info_cnt](1bytes),字节序(1):" .. scnt); o = o + 1
    for s = 1, scnt do
        if o + 6 > c:len() then tree:add(c(o, c:len() - o), "⚠ 车站数据不完整"); break end
        local st = tree:add(c(o, 1), "车站:" .. s)
        st:add(pf.yard_station_code, c(o, 4)):set_text("站码[yard_station_code](4bytes),字节序(" .. o .. "):" .. c(o, 4):le_uint()); o = o + 4
        local ilen = c(o, 2):le_uint()
        st:add(pf.yard_info_len, c(o, 2)):set_text("站场表示信息长[yard_info_len](2bytes),字节序(" .. o .. "):" .. ilen); o = o + 2
        local dev_end = o + ilen
        if dev_end > c:len() then dev_end = c:len() end
        local di = 0
        while o + 6 <= dev_end and o + 6 <= c:len() do
            di = di + 1
            local dt = c(o, 1):uint()
            local d = tree:add(c(o, 1), "设备:" .. di)
            d:add(pf.dev_type, c(o, 1)):set_text("设备类型[dev_type](1bytes),字节序(" .. o .. "):0x" .. string.format("%02x", dt) .. desc(dt, enum_devtype)); o = o + 1
            d:add(pf.dev_id, c(o, 4)):set_text("设备编号[dev_id](4bytes),字节序(" .. o .. "):" .. c(o, 4):le_uint()); o = o + 4
            local cl = c(o, 1):uint()
            d:add(pf.color_len, c(o, 1)):set_text("色码长度[color_len](1bytes),字节序(" .. o .. "):" .. cl); o = o + 1
            if cl > 0 and o + cl <= c:len() then
                local cs = c(o, cl)
                local txt = color_code_text(dt, cs)
                d:add(pf.color_code, cs):set_text("色码[color_code](" .. cl .. "bytes),字节序(" .. o .. "):" .. rawhex(cs) .. (txt ~= "" and (" " .. txt) or ""))
                o = o + cl
            end
        end
        if o < dev_end then st:add(c(o, dev_end - o), "⚠ 设备段长度不符(剩余" .. (dev_end - o) .. "bytes):" .. rawhex(c(o, dev_end - o))) end
        o = dev_end
    end
    return o
end

-- ============ 0x08 供电分区信息 ============
local function parse_08(c, tree)
    local o = 0
    local cnt = c(o, 2):le_uint()
    tree:add(pf.section_cnt, c(o, 2)):set_text("供电区段数目[section_cnt](2bytes),字节序(0):" .. cnt); o = o + 2
    for i = 1, cnt do
        if o + 3 > c:len() then tree:add(c(o, c:len() - o), "⚠ 区段数据不完整"); break end
        tree:add(pf.section_no, c(o, 2)):set_text("供电区段编号[section_no](" .. i .. ")(2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        tree:add(pf.section_state, c(o, 1)):set_text("供电区段状态[section_state](" .. i .. ")(1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), enum_section)); o = o + 1
    end
    return o
end

-- ============ 0x09 首末班申请 ============
local function parse_09(c, tree)
    tree:add(pf.request_flag, c(0, 4)):set_text("申请[request_flag](4bytes),字节序(0):0x" .. string.format("%08x", c(0, 4):le_uint()))
    return 4
end

-- ============ 0x10 场段出入段计划信息 ============
local function parse_10(c, tree)
    local o = 0
    tree:add(pf.plan_day, c(o, 7)):set_text("调度日[plan_day](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
    local gl = c(o, 1):uint()
    tree:add(pf.graph_len, c(o, 1)):set_text("图号长度[graph_len](1bytes),字节序(" .. o .. "):" .. gl); o = o + 1
    if gl > 0 and o + gl <= c:len() then tree:add(pf.graph_no, c(o, gl)):set_text("图号[graph_no](" .. gl .. "bytes),字节序(" .. o .. "):" .. c(o, gl):string()) end
    o = o + gl
    tree:add(pf.depot_station, c(o, 2)):set_text("段/场站码[depot_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
    local gcnt = c(o, 1):uint()
    tree:add(pf.service_group_cnt, c(o, 1)):set_text("服务号组数[service_group_cnt](1bytes),字节序(" .. o .. "):" .. gcnt); o = o + 1
    for g = 1, gcnt do
        if o + 1 > c:len() then tree:add(c(o, c:len() - o), "⚠ 服务组数据不完整"); break end
        local gt = tree:add(c(o, 1), "服务组:" .. g)
        local sl = c(o, 1):uint()
        gt:add(pf.service_len, c(o, 1)):set_text("服务号长度[service_len](1bytes),字节序(" .. o .. "):" .. sl); o = o + 1
        if sl > 0 and o + sl <= c:len() then gt:add(pf.service_no, c(o, sl)):set_text("服务号[service_no](" .. sl .. "bytes),字节序(" .. o .. "):" .. c(o, sl):string()) end
        o = o + sl
        gt:add(pf.out_depot_station, c(o, 2)):set_text("出段/场站码[out_depot_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        local n1 = c(o, 1):uint(); gt:add(pf.out_order_len, c(o, 1)):set_text("出段/场车次号长度[out_order_len](1bytes),字节序(" .. o .. "):" .. n1); o = o + 1
        if n1 > 0 and o + n1 <= c:len() then gt:add(pf.out_order_no, c(o, n1)):set_text("出段/场车次号[out_order_no](" .. n1 .. "bytes),字节序(" .. o .. "):" .. c(o, n1):string()) end
        o = o + n1
        local n2 = c(o, 1):uint(); gt:add(pf.out_group_len, c(o, 1)):set_text("出段/场车组号长度[out_group_len](1bytes),字节序(" .. o .. "):" .. n2); o = o + 1
        if n2 > 0 and o + n2 <= c:len() then gt:add(pf.out_group_no, c(o, n2)):set_text("出段/场车组号[out_group_no](" .. n2 .. "bytes),字节序(" .. o .. "):" .. c(o, n2):string()) end
        o = o + n2
        local n3 = c(o, 1):uint(); gt:add(pf.out_track_len, c(o, 1)):set_text("段/场内出发股道名称长度[out_track_len](1bytes),字节序(" .. o .. "):" .. n3); o = o + 1
        if n3 > 0 and o + n3 <= c:len() then gt:add(pf.out_track_name, c(o, n3)):set_text("段/场内出发股道名称[out_track_name](" .. n3 .. "bytes),字节序(" .. o .. "):" .. c(o, n3):string()) end
        o = o + n3
        gt:add(pf.out_plan_depart, c(o, 7)):set_text("段/场内计划出发时间[out_plan_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_depart, c(o, 7)):set_text("段/场内出发时间[out_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_report, c(o, 1)):set_text("段/场内报点标志[out_report](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        local n4 = c(o, 1):uint(); gt:add(pf.out_conv_len, c(o, 1)):set_text("出段/场转换轨名称长度[out_conv_len](1bytes),字节序(" .. o .. "):" .. n4); o = o + 1
        if n4 > 0 and o + n4 <= c:len() then gt:add(pf.out_conv_track, c(o, n4)):set_text("出段/场转换轨名称[out_conv_track](" .. n4 .. "bytes),字节序(" .. o .. "):" .. c(o, n4):string()) end
        o = o + n4
        gt:add(pf.out_conv_plan_arrive, c(o, 7)):set_text("出段/场转换轨计划到达时间[out_conv_plan_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_conv_arrive, c(o, 7)):set_text("出段/场转换轨到达时间[out_conv_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_conv_plan_depart, c(o, 7)):set_text("出段/场转换轨计划出发时间[out_conv_plan_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_conv_depart, c(o, 7)):set_text("出段/场转换轨出发时间[out_conv_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_conv_report, c(o, 1)):set_text("出段/场转换轨报点标志[out_conv_report](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.out_line_station, c(o, 2)):set_text("出段/场正线站码[out_line_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        gt:add(pf.out_line_arrive, c(o, 7)):set_text("出段/场正线到达时间[out_line_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.out_dest_code, c(o, 4)):set_text("出段/场目的地码[out_dest_code](4bytes),字节序(" .. o .. "):" .. c(o, 4):string()); o = o + 4
        gt:add(pf.in_depot_station, c(o, 2)):set_text("入段/场车辆段站码[in_depot_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        local m1 = c(o, 1):uint(); gt:add(pf.in_order_len, c(o, 1)):set_text("入段/场车次号长度[in_order_len](1bytes),字节序(" .. o .. "):" .. m1); o = o + 1
        if m1 > 0 and o + m1 <= c:len() then gt:add(pf.in_order_no, c(o, m1)):set_text("入段/场车次号[in_order_no](" .. m1 .. "bytes),字节序(" .. o .. "):" .. c(o, m1):string()) end
        o = o + m1
        local m2 = c(o, 1):uint(); gt:add(pf.in_group_len, c(o, 1)):set_text("入段/场车组号长度[in_group_len](1bytes),字节序(" .. o .. "):" .. m2); o = o + 1
        if m2 > 0 and o + m2 <= c:len() then gt:add(pf.in_group_no, c(o, m2)):set_text("入段/场车组号[in_group_no](" .. m2 .. "bytes),字节序(" .. o .. "):" .. c(o, m2):string()) end
        o = o + m2
        local m3 = c(o, 1):uint(); gt:add(pf.in_track_len, c(o, 1)):set_text("段/场内到达股道名称长度[in_track_len](1bytes),字节序(" .. o .. "):" .. m3); o = o + 1
        if m3 > 0 and o + m3 <= c:len() then gt:add(pf.in_track_name, c(o, m3)):set_text("段/场内到达股道名称[in_track_name](" .. m3 .. "bytes),字节序(" .. o .. "):" .. c(o, m3):string()) end
        o = o + m3
        gt:add(pf.in_plan_arrive, c(o, 7)):set_text("段/场内计划到达时间[in_plan_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_arrive, c(o, 7)):set_text("段/场内到达时间[in_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_report, c(o, 1)):set_text("段/场内报点标志[in_report](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        local m4 = c(o, 1):uint(); gt:add(pf.in_conv_len, c(o, 1)):set_text("入段/场转换轨名称长度[in_conv_len](1bytes),字节序(" .. o .. "):" .. m4); o = o + 1
        if m4 > 0 and o + m4 <= c:len() then gt:add(pf.in_conv_track, c(o, m4)):set_text("入段/场转换轨名称[in_conv_track](" .. m4 .. "bytes),字节序(" .. o .. "):" .. c(o, m4):string()) end
        o = o + m4
        gt:add(pf.in_conv_plan_arrive, c(o, 7)):set_text("入段/场转换轨计划到达时间[in_conv_plan_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_conv_arrive, c(o, 7)):set_text("入段/场转换轨到达时间[in_conv_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_conv_plan_depart, c(o, 7)):set_text("入段/场转换轨计划出发时间[in_conv_plan_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_conv_depart, c(o, 7)):set_text("入段/场转换轨出发时间[in_conv_depart](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_conv_report, c(o, 1)):set_text("入段/场转换轨报点标志[in_conv_report](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.in_line_station, c(o, 2)):set_text("入段/场正线站码[in_line_station](2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        gt:add(pf.in_line_arrive, c(o, 7)):set_text("入段/场正线到达时间[in_line_arrive](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.in_dest_code, c(o, 4)):set_text("入段/场目的地码[in_dest_code](4bytes),字节序(" .. o .. "):" .. c(o, 4):string()); o = o + 4
        gt:add(pf.init_flag, c(o, 1)):set_text("是否初始化生成[init_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.init_time, c(o, 7)):set_text("初始化时间[init_time](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.wash_flag, c(o, 1)):set_text("是否回段洗车[wash_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.spare2, c(o, 2)):set_text("预留[spare2](2bytes),字节序(" .. o .. "):" .. rawhex(c(o, 2))); o = o + 2
        gt:add(pf.wake_flag, c(o, 1)):set_text("是否自动唤醒[wake_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.wake_time, c(o, 7)):set_text("计划唤醒时间[wake_time](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.clean_flag, c(o, 1)):set_text("是否回库清扫[clean_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.clean_start, c(o, 7)):set_text("清扫开始时间[clean_start](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.clean_end, c(o, 7)):set_text("清扫结束时间[clean_end](7bytes),字节序(" .. o .. "):" .. t7(c, o)); o = o + 7
        gt:add(pf.sleep_flag, c(o, 1)):set_text("是否自动休眠[sleep_flag](1bytes),字节序(" .. o .. "):" .. c(o, 1):uint()); o = o + 1
        gt:add(pf.spare, c(o, 10)):set_text("预留[spare](10bytes),字节序(" .. o .. "):" .. rawhex(c(o, 10))); o = o + 10
    end
    return o
end

-- ============ 0x11/0x12/0x13 简单记录循环 ============
local function parse_records(c, tree, cnt_field, no_field, st_field, no_desc, st_enum)
    local o = 0
    local cnt = c(o, 2):le_uint()
    tree:add(cnt_field, c(o, 2)):set_text("数目[" .. cnt_field.name:match("[^.]+$") .. "](2bytes),字节序(0):" .. cnt); o = o + 2
    for i = 1, cnt do
        if o + 3 > c:len() then tree:add(c(o, c:len() - o), "⚠ 记录不完整"); break end
        tree:add(no_field, c(o, 2)):set_text(no_desc .. "[" .. no_field.name:match("[^.]+$") .. "](" .. i .. ")(2bytes),字节序(" .. o .. "):" .. c(o, 2):le_uint()); o = o + 2
        tree:add(st_field, c(o, 1)):set_text("状态[" .. st_field.name:match("[^.]+$") .. "](" .. i .. ")(1bytes),字节序(" .. o .. "):" .. c(o, 1):uint() .. desc(c(o, 1):uint(), st_enum)); o = o + 1
    end
    return o
end

local function parse_11(c, tree)
    return parse_records(c, tree, pf.fire_station_cnt, pf.fire_station_id, pf.station_fire_state,
        "车站编号", enum_station_fire)
end
local function parse_12(c, tree)
    return parse_records(c, tree, pf.interval_cnt, pf.interval_no, pf.interval_fire_state,
        "区间编号", enum_interval_fire)
end
local function parse_13(c, tree)
    return parse_records(c, tree, pf.sensor_cnt, pf.sensor_no, pf.water_alarm,
        "轨面水位传感器编号", enum_water)
end

local body_parsers = {
    [0x01] = parse_01,
    [0x02] = parse_02,
    [0x03] = parse_03,
    [0x04] = parse_04,
    [0x05] = parse_05,
    [0x06] = parse_06,
    [0x07] = parse_07,
    [0x08] = parse_08,
    [0x09] = parse_09,
    [0x10] = parse_10,
    [0x11] = parse_11,
    [0x12] = parse_12,
    [0x13] = parse_13,
}

-- Info列附加信息
local function app_extra(ttype, content)
    if not content or content:len() < 1 then return "" end
    if ttype == 0x02 and content:len() >= 2 then return " 列车数=" .. content(0, 2):le_uint() end
    if (ttype == 0x03 or ttype == 0x04) and content:len() >= 2 then return " 站台数=" .. content(0, 2):le_uint() end
    if ttype == 0x06 and content:len() >= 1 then return " 站台数=" .. content(0, 1):uint() end
    if ttype == 0x07 and content:len() >= 2 then return " 车站数=" .. content(1, 1):uint() end
    if ttype == 0x08 and content:len() >= 2 then return " 区段数=" .. content(0, 2):le_uint() end
    if ttype == 0x11 and content:len() >= 2 then return " 车站数=" .. content(0, 2):le_uint() end
    if ttype == 0x12 and content:len() >= 2 then return " 区间数=" .. content(0, 2):le_uint() end
    if ttype == 0x13 and content:len() >= 2 then return " 传感器数=" .. content(0, 2):le_uint() end
    return ""
end

-- 解析一条应用帧 (data_tvb = Data域: Type2 + content)
local function dissect_app(data_tvb, ftree, pinfo)
    if data_tvb:len() < 2 then
        ftree:add(data_tvb, "⚠ 应用帧过短(<2字节)")
        return
    end
    local ttype = data_tvb(0, 2):le_uint()
    local name = msgName[ttype] or string.format("未知类型(0x%02x)", ttype)
    local is_ats = sender_is_ats(pinfo)
    local dir = is_ats and "[ATS→ISCS]" or "[ISCS→ATS]"

    local mtree = ftree:add(data_tvb, "Data(应用帧): " .. name .. " (Type=0x" .. string.format("%02x", ttype) .. ")")
    mtree:add(pf.msg_type, data_tvb(0, 2)):set_text("消息类型[msg_type](2bytes),字节序(0):0x" ..
        string.format("%04x", ttype) .. " " .. name)

    if data_tvb:len() > 2 then
        local content = data_tvb(2, data_tvb:len() - 2)
        local ctree = mtree:add(content, "Content:" .. name .. " ,len:" .. content:len())
        local parser = body_parsers[ttype]
        if parser then
            parser(content, ctree)
        else
            ctree:add(content, "原始数据:" .. rawhex(content))
        end
    end

    pinfo.cols.info = dir .. " " .. name .. " type=0x" .. string.format("%02x", ttype) ..
        app_extra(ttype, data_tvb:len() > 2 and data_tvb(2) or nil)
    pinfo.cols.protocol = gzlats_protocol.name
end


-- ============ 跨帧重组状态 ============
local reassembly = {}

local function conv_key(pinfo)
    return tostring(pinfo.src) .. ":" .. pinfo.src_port ..
           "->" .. tostring(pinfo.dst) .. ":" .. pinfo.dst_port
end

-- ============ 信息帧解析 ============
local function parse_frame(buffer, pinfo, tree)
    -- 帧头(2+1+1+2+1=7) 至少7字节
    if buffer:len() < 7 then return -1 end
    if buffer(0, 2):uint() ~= 0xEFEF then return -1 end

    local ftotal = buffer(2, 1):uint()
    local findex = buffer(3, 1):uint()
    local dlen = buffer(4, 2):le_uint()
    if dlen > 2048 then return -1 end -- Data 最多2048
    local total = 9 + dlen -- 7头 + data + 2尾

    if buffer:len() < total then
        pinfo.desegment_len = total - buffer:len()
        pinfo.desegment_offset = 0
        return 0
    end
    if buffer(total - 2, 2):uint() ~= 0xFDFD then
        tree:add(gzlats_protocol, buffer(0, total), "GZL ATS 帧尾校验失败")
        return -1
    end

    pinfo.cols.protocol = gzlats_protocol.name
    local ftree = tree:add(gzlats_protocol, buffer(0, total),
        "GZL ATS 信息帧, Data_len:" .. dlen .. " (帧 " .. findex .. "/" .. ftotal .. ")")
    ftree:add(pf.frame_head, buffer(0, 2)):set_text("帧头[frame_head](2bytes),字节序(0):0xEF 0xEF")
    ftree:add(pf.frame_total, buffer(2, 1)):set_text("总帧数[frame_total](1bytes),字节序(2):" .. ftotal)
    ftree:add(pf.frame_index, buffer(3, 1)):set_text("当前帧序号[frame_index](1bytes),字节序(3):" .. findex)
    ftree:add(pf.data_len, buffer(4, 2)):set_text("Data域长度[data_len](2bytes),字节序(4):" .. dlen)
    local ds = buffer(6, 1):uint()
    ftree:add(pf.dev_status, buffer(6, 1)):set_text("设备主备状态[dev_status](1bytes),字节序(6):0x" ..
        string.format("%02x", ds) .. desc(ds, enum_dev))

    local dv = buffer(7, dlen)
    if ftotal == 1 then
        if dlen > 0 then dissect_app(dv, ftree, pinfo) end
    else
        -- 跨帧重组: 按 Frame_Index 缓存拼接
        local key = conv_key(pinfo)
        local st = reassembly[key]
        if not st or st.count ~= ftotal then
            st = { count = ftotal, chunks = {}, filled = 0 }
            reassembly[key] = st
        end
        if findex >= 1 and findex <= ftotal and not st.chunks[findex] then
            st.chunks[findex] = dv:bytes()
            st.filled = st.filled + 1
        end
        local psub = ftree:add(dv, "Data:跨帧消息片断 (帧 " .. findex .. "/" .. ftotal .. ")")
        psub:add(dv, "Data(帧片断 " .. findex .. "):" .. rawhex(dv))

        if st.filled == st.count then
            local ba = ByteArray.new()
            for i = 1, st.count do
                if st.chunks[i] then ba:append(st.chunks[i]) end
            end
            reassembly[key] = nil
            local full = ba:tvb("GZL ATS 重组应用帧")
            local mt = ftree:add(full, "重组应用帧(跨" .. ftotal .. "帧, 共" .. full:len() .. "字节)")
            dissect_app(full, mt, pinfo)
        end
    end

    ftree:add(pf.frame_tail, buffer(total - 2, 2)):set_text("帧尾[frame_tail](2bytes),字节序(" .. (7 + dlen) .. "):0xFD 0xFD")
    return total
end

function gzlats_protocol.dissector(buffer, pinfo, tree)
    local consumed = parse_frame(buffer, pinfo, tree)
    if consumed == 0 then
        -- 等待更多数据
    elseif consumed == -1 then
        data_dis:call(buffer, pinfo, tree)
    else
        -- 可能一TCP段含多帧, 递归处理剩余
        local rest = buffer(consumed):tvb()
        if rest:len() >= 7 and rest(0, 2):uint() == 0xEFEF then
            gzlats_protocol.dissector(rest, pinfo, tree)
        end
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
    ats_ports = {}
    if gzlats_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(gzlats_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do
            tcp_port:add(port, gzlats_protocol)
            ats_ports[port] = true
        end
    end
end

add_port()
function gzlats_protocol.prefs_changed() add_port() end
