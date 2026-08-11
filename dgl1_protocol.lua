-- 插件名: DGL1 Protocol
-- 版本: 1.0.3#20260810-1
-- 作者: 叶孟鹏
-- 描述: 东莞1号线 ATS-ISCS 接口协议解析插件。
--       依据 dgl1_ats.md《东莞市城市轨道交通1号线一期工程ATS-综合监控系统接口说明书》V1.1实现。
--       协议结构: 信息帧(0xEF 0xEF | 帧数1 | 帧序1 | Data_Len2 | Data | 0xFD 0xFD)
--       消息(Message_Len2 | Message_Time7 | Line_Id2 | Validity1 | Spare17 | Message_Id1 | version1 | Content)
--       全部多字节数值低字节在前(LE), 字符串ANSI, 时间7字节(年2LE+月日时分秒各1)。
--       支持: 帧内多消息 / 跨帧消息重组(Frame_Count>1按Frame_Index拼接) / TCP desegment。
--       字段展示格式: 名称[协议字段名](Nbytes),字节序(N):值
--       字节序: 统一从帧头(帧偏移0)起算。单帧消息字段=距帧头偏移;
--       跨帧重组消息=按消息起始所在帧的帧头(偏移6)起算。
-- 更新时间: 2026-08-10
dgl1_protocol = Proto("DGL1", "DGL1 Protocol")
-- 首选项
local prefs = dgl1_protocol.prefs
prefs.my_version = Pref.statictext("version:1.0.3#20260810-1",
                                   "1.0.3#20260810-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "2100",
                                "DGL1默认端口(ATS服务端实时端口)")


-- 过滤器字段定义
local function sf(name, desc) -- ASCII字符串字段
    return ProtoField.string("dgl1." .. name, desc, base.ASCII)
end
local function u8(name, desc)  return ProtoField.uint8("dgl1." .. name, desc, base.DEC) end
local function u16(name, desc) return ProtoField.uint16("dgl1." .. name, desc, base.DEC) end
local function u32(name, desc) return ProtoField.uint32("dgl1." .. name, desc, base.DEC) end
local function bf(name, desc)  return ProtoField.bytes("dgl1." .. name, desc) end

local pf = {
    -- 帧层
    frame_head  = bf("frame_head", "帧头"),
    frame_count = u8("frame_count", "总帧数"),
    frame_index = u8("frame_index", "当前帧序号"),
    data_len    = u16("data_len", "Data域长度"),
    frame_tail  = bf("frame_tail", "帧尾"),
    -- 消息层
    msg_len     = u16("msg_len", "消息长度"),
    msg_time    = bf("msg_time", "消息发送时间"),
    line_id     = u16("line_id", "线路号"),
    validity    = u8("validity", "消息有效标识"),
    msg_id      = u8("msg_id", "消息ID"),
    version     = u8("version", "版本号"),
    spare       = bf("spare", "预留"),
    -- 心跳 0x01
    poll_spare  = bf("poll_spare", "预留"),
    -- 0x03 站台到站列车
    platform_cnt  = u8("platform_cnt", "站台数目"),
    station_id    = u8("station_id", "车站编号"),
    platform_id   = u16("platform_id", "站台编号"),
    train_valid   = u8("train_valid", "列车信息有效"),
    train_id      = sf("train_id", "车组号"),
    server_number = sf("server_number", "表号"),
    order_number  = sf("order_number", "车次号"),
    dest_code     = sf("dest_code", "目的地码"),
    pre_arrival   = u8("pre_arrival", "即将进站标记"),
    sched_arrive  = bf("sched_arrive", "预计到达时间"),
    sched_depart  = bf("sched_depart", "预计离开时间"),
    otp_time      = u32("otp_time", "早晚点时间(秒)"),
    arrival_status  = u8("arrival_status", "列车到站标记"),
    departure_status= u8("departure_status", "列车离站标记"),
    hold_status   = u8("hold_status", "扣车标记"),
    skip_status   = u8("skip_status", "跳停标记"),
    out_of_service= u8("out_of_service", "清客标记"),
    last_train    = u8("last_train", "末班标记"),
    compartment   = u8("compartment", "编组数量"),
    driver_no     = u16("driver_no", "驾驶员编号"),
    passenger_attr= u8("passenger_attr", "载客不载客属性"),
    destination_id= u16("destination_id", "目的地编号"),
    oper_attr     = u8("oper_attr", "运营属性"),
    train_prop    = u8("train_prop", "列车属性"),
    extend        = u8("extend", "清客类型位"),
    -- 0x05 列车位置
    trains_cnt    = u8("trains_cnt", "列车数目"),
    rtu_id        = u16("rtu_id", "集中站站号"),
    station_up    = u16("station_up", "上行侧车站编号"),
    station_down  = u16("station_down", "下行侧车站编号"),
    active_tc     = u8("active_tc", "激活端"),
    direction     = u8("direction", "运行方向"),
    transfer_flag = u8("transfer_flag", "出入库标识"),
    on_transfer   = u8("on_transfer", "转换轨标识"),
    on_turnback   = u8("on_turnback", "折返轨/存车轨标识"),
    on_platform   = u8("on_platform", "站台标识"),
    lost_location = u8("lost_location", "失去真实位置"),
    logic_section = u16("logic_section", "逻辑区段ID"),
    physic_section= u16("physic_section", "物理区段ID"),
    window_offset = u8("window_offset", "同区段内次序"),
    timeout_status= u8("timeout_status", "区间停车超时"),
    arrive_time   = bf("arrive_time", "列车到达时间"),
    depart_time   = bf("depart_time", "列车离开时间"),
    drive_mode    = u8("drive_mode", "驾驶模式"),
    is_open_door  = u8("is_open_door", "车门状态"),
    is_stopped    = u8("is_stopped", "停车状态"),
    control_mode  = u8("control_mode", "运行控制级别"),
    non_pullback  = u8("non_pullback", "无人折返状态"),
    eb_flag       = u8("eb_flag", "紧急制动"),
    rate          = u8("rate", "满载率"),
    speed         = u8("speed", "速度(KM/H)"),
    stop_deviation= u8("stop_deviation", "停车过标欠标"),
    snow          = u8("snow", "雨雪模式"),
    fire          = u8("fire", "火灾报警"),
    derailment    = u8("derailment", "脱轨及障碍物检测"),
    platform_timeout = u8("platform_timeout", "列车停站超时"),
    first_route_id= u16("first_route_id", "前方第一条进路编号"),
    first_route_exist = u8("first_route_exist", "前方进路是否开放"),
    -- 0x07/0x08/0x13 通用记录
    rec_cnt       = u16("rec_cnt", "记录数目"),
    rec_id        = u16("rec_id", "记录编号"),
    rec_status    = u8("rec_status", "记录状态"),
    -- 0x0E 越站
    over_train_id = u16("over_train_id", "车组号"),
    over_server_no= u16("over_server_no", "表号"),
    over_order_no = u16("over_order_no", "车次号"),
    -- 0x10 设备状态全体
    type_cnt      = u16("type_cnt", "类型数量"),
    dev_type      = u16("dev_type", "设备类型"),
    obj_count     = u16("obj_count", "该类设备数目"),
    dev_id        = u32("dev_id", "设备唯一识别号"),
    dev_status    = u32("dev_status", "设备状态"),
    -- 0x11 外部报警
    alarm_id      = u8("alarm_id", "报警类型ID"),
    param_cnt     = u8("param_cnt", "参数个数"),
    param_1       = bf("param_1", "参数1"),
    param_2       = bf("param_2", "参数2"),
}
dgl1_protocol.fields = {}
for _, v in pairs(pf) do table.insert(dgl1_protocol.fields, v) end


-- 枚举中文描述
local enum_valid = {[0]="有效", [1]="无效"}
local enum_train_valid = {[0]="无效", [1]="有效"} -- 站台消息ValidityField: 0=invalid,1=valid(与消息头相反)
local enum_direction = {[0]="上行", [1]="下行", [2]="未知"}
local enum_transfer  = {[0]="段场→正线", [1]="正线→段场"}
local enum_drvmode   = {[0x01]="AM", [0x02]="CM", [0x03]="RM", [0x05]="FAM", [0x06]="CAM", [0x07]="RRM", [0xFF]="默认"}
local enum_scada     = {[1]="未知", [2]="单边供电", [3]="双边供电", [4]="无电"}
local enum_fas       = {[0x00]="无报警", [0x01]="有报警"}
local enum_water     = {[0x00]="无报警", [0x01]="有报警", [0x03]="未知"}
local enum_devtype   = {[0]="未知", [1]="集中站RTU", [2]="逻辑区段", [4]="洗车机", [5]="SPKS", [6]="ESB", [7]="站台", [8]="信号机", [9]="道岔"}
local enum_alarm     = {[0x01]="客流等级报警", [0x04]="场段全自动区域火灾报警"}
local enum_alarm_lvl = {[0x00]="客流报警恢复", [0x01]="客流等级1级", [0x02]="客流等级2级", [0x03]="客流等级3级"}
local enum_alarm_fire= {[0x00]="区域火灾报警恢复", [0x01]="区域火灾报警"}

local function desc(v, t)
    local d = t and t[v]
    if d then return " | " .. d end
    return ""
end

-- 字节序(帧内绝对偏移): fbase=消息头距帧头偏移, base=Content起始(相对msg_buf), 字段偏移=fbase+31+(o-base)
local function mbo(fbase, base, o) return fbase + (o - base) + 31 end

-- 消息ID->名称/方向 (方向: A=ATS→ISCS, I=ISCS→ATS, B=双向)
local msgDef = {
    [0x01] = { "心跳信息", "B" },
    [0x03] = { "站台到站列车信息", "A" },
    [0x05] = { "列车位置信息", "A" },
    [0x07] = { "供电状态消息", "I" },
    [0x08] = { "火灾状态消息", "I" },
    [0x0E] = { "越站命令信息", "A" },
    [0x10] = { "设备状态全体消息", "A" },
    [0x11] = { "外部报警信息", "I" },
    [0x13] = { "区间水位报警消息", "I" },
}

local data_dis = Dissector.get("data")
local sig_ports = {}
local function sender_is_sig(pinfo)
    if sig_ports[pinfo.src_port] then return true end
    if sig_ports[pinfo.dst_port] then return false end
    return true
end

-- 7字节时间: 年2LE + 月日时分秒各1
local function fmt_time7(buf, off)
    local y = buf(off, 2):le_uint()
    local mo = buf(off + 2, 1):uint()
    local d = buf(off + 3, 1):uint()
    local h = buf(off + 4, 1):uint()
    local mi = buf(off + 5, 1):uint()
    local s = buf(off + 6, 1):uint()
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", y, mo, d, h, mi, s)
end

-- ============ 0x01 心跳: Content = Spare(8字节0) ============
local function parse_01(buf, off, len, tree, fbase)
    local base = off
    tree:add(pf.poll_spare, buf(off, 8)):set_text("预留[Spare](8bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. buf(off, 8):raw())
    return off + 8
end

-- ============ 0x03 站台到站列车信息 ============
local function parse_03(buf, off, len, tree, fbase)
    local base = off
    tree:add(pf.platform_cnt, buf(off, 1)):set_text("站台数目[Plateform_cnt](1bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. buf(off, 1):uint())
    local cnt = buf(off, 1):uint()
    local o = off + 1
    for p = 1, cnt do
        local pt = tree:add(buf(o, 1), "站台:" .. p)
        pt:add(pf.station_id, buf(o, 1)):set_text("车站编号[Station_id](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint())
        o = o + 1
        pt:add(pf.platform_id, buf(o, 2)):set_text("站台编号[Plateform_id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint())
        o = o + 2
        for tn = 1, 3 do
            -- ValidityField 决定该列车是否有内容 (0=无效,1=有效)
            pt:add(pf.train_valid, buf(o, 1)):set_text("列车信息有效[ValidityField](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum_train_valid))
            if buf(o, 1):uint() == 1 then
                o = o + 1
                local tt = pt:add("Train" .. tn .. " 内容")
                local flen
                flen = buf(o, 1):uint(); tt:add(pf.train_id, buf(o + 1, flen)):set_text("车组号[Train_id](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
                flen = buf(o, 1):uint(); tt:add(pf.server_number, buf(o + 1, flen)):set_text("表号[Server_number](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
                flen = buf(o, 1):uint(); tt:add(pf.order_number, buf(o + 1, flen)):set_text("车次号[Order_number](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
                flen = buf(o, 1):uint(); if flen > 0 then tt:add(pf.dest_code, buf(o + 1, flen)):set_text("目的地码[Destination_code](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()) else tt:add(buf(o, 1), "目的地码[Destination_code](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "空") end; o = o + 1 + flen
                tt:add(pf.pre_arrival, buf(o, 1)):set_text("即将进站标记[Pre_arrival](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.sched_arrive, buf(o, 7)):set_text("预计到达时间[Scheduled_arrival_time](7bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. fmt_time7(buf, o)); o = o + 7
                tt:add(pf.sched_depart, buf(o, 7)):set_text("预计离开时间[Scheduled_depart_time](7bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. fmt_time7(buf, o)); o = o + 7
                tt:add(pf.otp_time, buf(o, 4)):set_text("早晚点时间[Otp_time](4bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 4):le_int() .. "秒"); o = o + 4
                tt:add(pf.arrival_status, buf(o, 1)):set_text("列车到站标记[Arrival_status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.departure_status, buf(o, 1)):set_text("列车离站标记[Departure_status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.hold_status, buf(o, 1)):set_text("扣车标记[Hold_status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.skip_status, buf(o, 1)):set_text("跳停标记[Skip_status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.out_of_service, buf(o, 1)):set_text("清客标记[Out_of_service](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.last_train, buf(o, 1)):set_text("末班标记[Lats_train](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.compartment, buf(o, 1)):set_text("编组数量[Compartment_cnt](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.driver_no, buf(o, 2)):set_text("驾驶员编号[Driver_Number](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
                tt:add(pf.passenger_attr, buf(o, 1)):set_text("载客不载客属性[PassengerAttributes_Status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.destination_id, buf(o, 2)):set_text("目的地编号[Destination_Id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
                tt:add(pf.oper_attr, buf(o, 1)):set_text("运营属性[Orerational_Attr](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.train_prop, buf(o, 1)):set_text("列车属性[TrainProperty](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
                tt:add(pf.extend, buf(o, 1)):set_text("清客类型位[Extend](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. (buf(o, 1):uint() % 4)); o = o + 1
                tt:add(pf.spare, buf(o, 2)):set_text("预留[Spare](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):raw()); o = o + 2
            else
                o = o + 1
            end
        end
    end
    return o
end

-- ============ 0x05 列车位置信息 ============
local function parse_05(buf, off, len, tree, fbase)
    local base = off
    tree:add(pf.trains_cnt, buf(off, 1)):set_text("列车数目[Trains_cnt](1bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. buf(off, 1):uint())
    local cnt = buf(off, 1):uint()
    local o = off + 1
    for i = 1, cnt do
        local t = tree:add(buf(o, 1), "车:" .. i)
        local flen
        flen = buf(o, 1):uint(); t:add(pf.train_id, buf(o + 1, flen)):set_text("车组号[Train_id](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
        flen = buf(o, 1):uint(); t:add(pf.server_number, buf(o + 1, flen)):set_text("表号[Server_number](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
        flen = buf(o, 1):uint(); t:add(pf.order_number, buf(o + 1, flen)):set_text("车次号[Order_number](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()); o = o + 1 + flen
        flen = buf(o, 1):uint(); if flen > 0 then t:add(pf.dest_code, buf(o + 1, flen)):set_text("目的地码[Destination_code](1+N)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o + 1, flen):string()) end; o = o + 1 + flen
        t:add(pf.rtu_id, buf(o, 2)):set_text("集中站站号[Rtu_id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.station_id, buf(o, 2)):set_text("车站编号[Station_ID](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.station_up, buf(o, 2)):set_text("上行侧车站编号[Station_ID_in_Up_Side](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.station_down, buf(o, 2)):set_text("下行侧车站编号[Station_ID_in_Down_Side](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.active_tc, buf(o, 1)):set_text("激活端[ActiveTC_ID](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.direction, buf(o, 1)):set_text("运行方向[Direction](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum_direction)); o = o + 1
        t:add(pf.transfer_flag, buf(o, 1)):set_text("出入库标识[Transfer_Flag](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum_transfer)); o = o + 1
        t:add(pf.on_transfer, buf(o, 1)):set_text("转换轨标识[On_Transfer](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.on_turnback, buf(o, 1)):set_text("折返轨/存车轨标识[On_TurnBack_Track_Flag](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.on_platform, buf(o, 1)):set_text("站台标识[On_Platform_Flag](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.lost_location, buf(o, 1)):set_text("失去真实位置[Lost_real_location](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.logic_section, buf(o, 2)):set_text("逻辑区段ID[LogicSection_ID](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.physic_section, buf(o, 2)):set_text("物理区段ID[PhysicSection_ID](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.window_offset, buf(o, 1)):set_text("同区段内次序[Window_offset](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.compartment, buf(o, 1)):set_text("编组数量[Compartment_cnt](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.driver_no, buf(o, 2)):set_text("驾驶员编号[Driver_Number](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.timeout_status, buf(o, 1)):set_text("区间停车超时[Timeout_Status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.otp_time, buf(o, 4)):set_text("早晚点时间[Otp_time](4bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 4):le_int() .. "秒"); o = o + 4
        t:add(pf.arrive_time, buf(o, 7)):set_text("列车到达时间[Arrive_time](7bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. fmt_time7(buf, o)); o = o + 7
        t:add(pf.depart_time, buf(o, 7)):set_text("列车离开时间[Depart_time](7bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. fmt_time7(buf, o)); o = o + 7
        t:add(pf.drive_mode, buf(o, 1)):set_text("驾驶模式[Drive_Mode](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint()) .. desc(buf(o, 1):uint(), enum_drvmode)); o = o + 1
        t:add(pf.is_open_door, buf(o, 1)):set_text("车门状态[IsOpenDoor](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.is_stopped, buf(o, 1)):set_text("停车状态[IsStopped](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.control_mode, buf(o, 1)):set_text("运行控制级别[Control_Mode](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.non_pullback, buf(o, 1)):set_text("无人折返状态[NonPullBackStatus](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.eb_flag, buf(o, 1)):set_text("紧急制动[EB_Flag](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.rate, buf(o, 1)):set_text("满载率[Rate](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. "%"); o = o + 1
        t:add(pf.speed, buf(o, 1)):set_text("速度[Speed](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. "KM/H"); o = o + 1
        t:add(pf.stop_deviation, buf(o, 1)):set_text("停车过标欠标[Stop_deviation](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%02X", buf(o, 1):uint())); o = o + 1
        t:add(pf.snow, buf(o, 1)):set_text("雨雪模式[SNOW](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.fire, buf(o, 1)):set_text("火灾报警[FIRE](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.derailment, buf(o, 1)):set_text("脱轨及障碍物检测[Derailment](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.platform_timeout, buf(o, 1)):set_text("列车停站超时[Platform_Timeout_Status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.first_route_id, buf(o, 2)):set_text("前方第一条进路编号[First_Route_Id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.first_route_exist, buf(o, 1)):set_text("前方进路是否开放[First_Route_Exist](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
    end
    return o
end

-- ============ 0x07/0x08/0x13 通用记录 ============
local function parse_records(buf, off, tree, enum, fbase)
    local base = off
    tree:add(pf.rec_cnt, buf(off, 2)):set_text("记录数目[Rec_cnt](2bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. buf(off, 2):le_uint())
    local cnt = buf(off, 2):le_uint()
    local o = off + 2
    for i = 1, cnt do
        tree:add(pf.rec_id, buf(o, 2)):set_text("记录编号[Id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        tree:add(pf.rec_status, buf(o, 1)):set_text("记录状态[Status](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum)); o = o + 1
    end
    return o
end

-- ============ 0x0E 越站命令 (每组19字节, 用长度推断条数) ============
local function parse_0e(buf, off, len, tree, fbase)
    local base = off
    local unit = 19
    local cnt = math.floor(len / unit)
    if len % unit ~= 0 then
        tree:add(buf(off, len), "⚠ 越站命令长度 " .. len .. " 不是19的整数倍")
    end
    local o = off
    for i = 1, cnt do
        local t = tree:add(buf(o, unit), "越站站台:" .. i)
        t:add(pf.station_id, buf(o, 1)):set_text("车站编号[Station_id](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint()); o = o + 1
        t:add(pf.platform_id, buf(o, 2)):set_text("站台编号[Plateform_id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.over_train_id, buf(o, 2)):set_text("车组号[Train_id](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.over_server_no, buf(o, 2)):set_text("表号[ServerNumber](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.over_order_no, buf(o, 2)):set_text("车次号[OrderNumber](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        t:add(pf.spare, buf(o, 10)):set_text("预留[Spare](10bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 10):raw()); o = o + 10
    end
    return o
end

-- ============ 0x10 设备状态全体 (位掩码按类型解码) ============
local DEV_STATUS_BITS = {
    [1] = { {0x00008000, "RTU通信中断"} }, -- RTU 集中站
    [2] = { {0x00000001, "CT车占用"}, {0x00000002, "UT车占用"}, {0x00000008, "锁闭"}, {0x00000010, "故障锁闭"}, {0x00000100, "轨道切除"}, {0x00000200, "ARB"}, {0x00000400, "OVERLAP保护区段锁闭"}, {0x00000800, "轨道区段封锁"} }, -- LOGSEC
    [4] = { {0x00000002, "洗车机故障"}, {0x00000004, "洗车机就绪"}, {0x00000008, "同意洗车"} }, -- WASH
    [5] = { {0x00000001, "SPKS按下"}, {0x00000002, "SPKS故障"} }, -- SPKS
    [6] = nil, -- ESB 特例: 0=有紧急关闭 1=无紧急关闭
    [7] = { {0x00000001, "站台门打开"}, {0x00000002, "下行站台清客"}, {0x00000004, "站台门切除"}, {0x00000008, "上行站台清客"}, {0x00000010, "上行车站扣车"}, {0x00000020, "下行车站扣车"}, {0x00000040, "上行中心扣车"}, {0x00000080, "下行中心扣车"}, {0x00000100, "上行跳停"}, {0x00000200, "下行跳停"}, {0x00000400, "上行指定列车跳停"}, {0x00000800, "下行指定列车跳停"} }, -- PLATFORM
    [8] = { {0x00000001, "红灯亮"}, {0x00000002, "红灯闪"}, {0x00000004, "绿灯亮"}, {0x00000008, "绿灯闪"}, {0x00000010, "黄灯亮"}, {0x00000020, "黄灯闪"}, {0x00000040, "白灯亮"}, {0x00000080, "白灯闪"}, {0x00000100, "蓝灯亮"}, {0x00000200, "蓝灯闪"}, {0x00010000, "fleet模式"}, {0x00040000, "auto模式"}, {0x00100000, "灭灯状态"}, {0x00200000, "接近锁闭"}, {0x00400000, "保护进路已办理"}, {0x00800000, "后方进路关闭自动触发"}, {0x01000000, "引导状态"}, {0x02000000, "双黄灯"}, {0x08000000, "信号机封锁"}, {0x10000000, "灯丝断丝"} }, -- SIGNAL
    [9] = { {0x00000002, "联锁报告占用"}, {0x00000004, "CBTC报告占用"}, {0x00000008, "道岔锁闭"}, {0x00000010, "道岔故障锁闭"}, {0x00000020, "道岔定位"}, {0x00000040, "道岔反位"}, {0x00000080, "道岔单锁"}, {0x00000100, "道岔挤岔"}, {0x00020000, "道岔切除"}, {0x00040000, "ARB"}, {0x04000000, "道岔封锁"}, {0x08000000, "道岔失表"} }, -- SWITCH
}
local function dev_status_text(devtype, st)
    local bits = DEV_STATUS_BITS[devtype]
    if devtype == 6 then -- ESB 特例
        if st == 0 then return "[有紧急关闭]" elseif st == 1 then return "[无紧急关闭]" end
        return ""
    end
    if not bits then return "" end
    local t = {}
    for _, b in ipairs(bits) do
        if st & b[1] ~= 0 then t[#t + 1] = b[2] end
    end
    if #t > 0 then return "[" .. table.concat(t, ",") .. "]" end
    return ""
end

local function parse_10(buf, off, len, tree, fbase)
    local base = off
    tree:add(pf.rtu_id, buf(off, 2)):set_text("集中站号[rtu_id](2bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. buf(off, 2):le_uint())
    tree:add(pf.type_cnt, buf(off + 2, 2)):set_text("类型数量[Type_cnt](2bytes)" .. ",字节序(" .. mbo(fbase, base, off + 2) .. "):" .. buf(off + 2, 2):le_uint())
    local types = buf(off + 2, 2):le_uint()
    local o = off + 4
    for ti = 1, types do
        local dt = buf(o, 2):le_uint()
        local tc = buf(o + 2, 2):le_uint()
        local t = tree:add(buf(o, 4), "类型:" .. dt .. desc(dt, enum_devtype) .. " ,数目:" .. tc)
        t:add(pf.dev_type, buf(o, 2)):set_text("设备类型[Type](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. dt .. desc(dt, enum_devtype)); o = o + 2
        t:add(pf.obj_count, buf(o, 2)):set_text("该类设备数目[obj_count](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. tc); o = o + 2
        for oi = 1, tc do
            local id = buf(o, 4):le_uint()
            local st = buf(o + 4, 4):le_uint()
            local d = dev_status_text(dt, st)
            t:add(pf.dev_id, buf(o, 4)):set_text("设备唯一识别号[dev_id](4bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. id); o = o + 4
            t:add(pf.dev_status, buf(o, 4)):set_text("设备状态[status](4bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. "0x" .. string.format("%08X", st) .. (d ~= "" and (" " .. d) or "")); o = o + 4
        end
    end
    return o
end

-- ============ 0x11 外部报警 (按附录6类型解析参数) ============
local function parse_11(buf, off, len, tree, fbase)
    local base = off
    local aid = buf(off, 1):uint()
    local pc = buf(off + 1, 1):uint()
    tree:add(pf.alarm_id, buf(off, 1)):set_text("报警类型ID[Id](1bytes)" .. ",字节序(" .. mbo(fbase, base, off) .. "):" .. "0x" .. string.format("%02X", aid) .. desc(aid, enum_alarm))
    tree:add(pf.param_cnt, buf(off + 1, 1)):set_text("参数个数[参数个数](1bytes)" .. ",字节序(" .. mbo(fbase, base, off + 1) .. "):" .. pc)
    local o = off + 2
    if aid == 0x01 then -- 客流等级报警: 参数1级别(1B) + 参数2车站ID(2B LE)
        if pc >= 1 then
            tree:add(pf.param_1, buf(o, 1)):set_text("参数1[Status1](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum_alarm_lvl)); o = o + 1
        end
        if pc >= 2 then
            tree:add(pf.param_2, buf(o, 2)):set_text("参数2[Status2](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        end
    elseif aid == 0x04 then -- 场段全自动区域火灾报警: 参数1状态(1B) + 参数2车站ID(2B LE)
        if pc >= 1 then
            tree:add(pf.param_1, buf(o, 1)):set_text("参数1[Status1](1bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 1):uint() .. desc(buf(o, 1):uint(), enum_alarm_fire)); o = o + 1
        end
        if pc >= 2 then
            tree:add(pf.param_2, buf(o, 2)):set_text("参数2[Status2](2bytes)" .. ",字节序(" .. mbo(fbase, base, o) .. "):" .. buf(o, 2):le_uint()); o = o + 2
        end
    else -- 未知类型: 原始hex
        tree:add(buf(o, len - 2), "参数原始数据(" .. (len - 2) .. "bytes):" .. buf(o, len - 2):raw())
        o = o + (len - 2)
    end
    return o
end

-- ============ 消息头 + 内容分派 ============
local body_parsers = {
    [0x01] = parse_01,
    [0x03] = parse_03,
    [0x05] = parse_05,
    [0x07] = function(b, o, l, t, f) return parse_records(b, o, t, enum_scada, f) end,
    [0x08] = function(b, o, l, t, f) return parse_records(b, o, t, enum_fas, f) end,
    [0x13] = function(b, o, l, t, f) return parse_records(b, o, t, enum_water, f) end,
    [0x0E] = parse_0e,
    [0x10] = parse_10,
    [0x11] = parse_11,
}

-- 解析单条消息; 返回消息结束偏移。msg_buf 可能来自跨帧拼接。
local function dissect_message(msg_buf, msg_off, msg_len, subtree, pinfo, frame_offset)
    local fbase = frame_offset + msg_off
    local mlen = msg_buf(msg_off, 2):le_uint()
    local mtime = fmt_time7(msg_buf, msg_off + 2)
    local line = msg_buf(msg_off + 9, 2):le_uint()
    local valid = msg_buf(msg_off + 11, 1):uint()
    local m_id = msg_buf(msg_off + 29, 1):uint()
    local ver = msg_buf(msg_off + 30, 1):uint()

    local def = msgDef[m_id]
    local name = def and def[1] or string.format("未知消息(0x%02X)", m_id)

    local h = subtree:add(msg_buf(msg_off, 31), "Message Head")
    h:add(pf.msg_len, msg_buf(msg_off, 2)):set_text("消息长度[Message_Len](2bytes)" .. ",字节序(" .. fbase .. "):" .. mlen)
    h:add(pf.msg_time, msg_buf(msg_off + 2, 7)):set_text("消息发送时间[Message_Time](7bytes)" .. ",字节序(" .. (fbase+2) .. "):" .. mtime)
    h:add(pf.line_id, msg_buf(msg_off + 9, 2)):set_text("线路号[Line_Id](2bytes)" .. ",字节序(" .. (fbase+9) .. "):" .. line)
    h:add(pf.validity, msg_buf(msg_off + 11, 1)):set_text("消息有效标识[Validity](1bytes)" .. ",字节序(" .. (fbase+11) .. "):" .. valid .. desc(valid, enum_valid))
    h:add(pf.spare, msg_buf(msg_off + 12, 17)):set_text("预留[Spare](17bytes)" .. ",字节序(" .. (fbase+12) .. "):" .. msg_buf(msg_off + 12, 17):raw())
    h:add(pf.msg_id, msg_buf(msg_off + 29, 1)):set_text("消息ID[Message_Id](1bytes)" .. ",字节序(" .. (fbase+29) .. "):" .. "0x" .. string.format("%02X", m_id) .. " " .. name)
    h:add(pf.version, msg_buf(msg_off + 30, 1)):set_text("版本号[version](1bytes)" .. ",字节序(" .. (fbase+30) .. "):" .. "0x" .. string.format("%02X", ver))

    local content_len = mlen - 29 -- 29 = 时间7+line2+valid1+spare17+id1+ver1(Message_Len不含长度本身)
    local content_off = msg_off + 31
    if content_len > 0 then
        local ct = subtree:add(msg_buf(content_off, content_len), "Content:" .. name .. " ,len:" .. content_len)
        local parser = body_parsers[m_id]
        if parser then
            parser(msg_buf, content_off, content_len, ct, fbase)
        else
            ct:add(msg_buf(content_off, content_len), "原始数据:" .. msg_buf(content_off, content_len):raw())
        end
    end

    -- Info 列
    local is_sig = sender_is_sig(pinfo)
    local dir
    if def then
        dir = (def[2] == "B") and (is_sig and "[SIG→ISCS]" or "[ISCS→SIG]")
            or (def[2] == "A" and "[SIG→ISCS]" or "[ISCS→SIG]")
    else
        dir = is_sig and "[SIG→ISCS]" or "[ISCS→SIG]"
    end
    pinfo.cols.info = dir .. " " .. name .. " line=" .. line ..
        (valid == 1 and " 无效" or "")
    pinfo.cols.protocol = dgl1_protocol.name

    return msg_off + mlen + 2
end

-- ============ 跨帧重组状态 ============
local reassembly = {}

local function conv_key(pinfo)
    return tostring(pinfo.src) .. ":" .. pinfo.src_port ..
           "->" .. tostring(pinfo.dst) .. ":" .. pinfo.dst_port
end

-- 解析 Data 域中的消息(可能多条)。返回已处理字节数。
local function parse_data_messages(data_tvb, subtree, pinfo, data_len, frame_offset)
    local o = 0
    while o + 2 <= data_len do
        local mlen = data_tvb(o, 2):le_uint()
        if mlen < 1 or mlen > 65533 then
            subtree:add(data_tvb(o, data_len - o), "⚠ 非法消息长度:" .. mlen)
            break
        end
        local total = mlen + 2
        if o + total > data_len then
            subtree:add(data_tvb(o, data_len - o), "⚠ 消息不完整(长度域声明" .. total .. "，剩余" .. (data_len - o) .. ")")
            break
        end
        o = dissect_message(data_tvb, o, total, subtree, pinfo, frame_offset)
    end
    return o
end

-- ============ 信息帧解析 ============
local function parse_frame(buffer, pinfo, tree)
    -- 帧头/帧数/帧序/长度 至少8字节
    if buffer:len() < 8 then return -1 end
    if buffer(0, 2):uint() ~= 0xEFEF then return -1 end

    local fcount = buffer(2, 1):uint()
    local findex = buffer(3, 1):uint()
    local dlen = buffer(4, 2):le_uint()
    if dlen > 1024 then return -1 end -- Data 最多1024
    local total = 8 + dlen

    if buffer:len() < total then
        pinfo.desegment_len = total - buffer:len()
        pinfo.desegment_offset = 0
        return 0
    end
    -- 帧尾校验
    if buffer(total - 2, 2):uint() ~= 0xFDFD then
        tree:add(dgl1_protocol, buffer(0, total), "DGL1 帧尾校验失败")
        return -1
    end

    pinfo.cols.protocol = dgl1_protocol.name
    local ftree = tree:add(dgl1_protocol, buffer(0, total),
        "DGL1 信息帧, Data_len:" .. dlen .. " (帧 " .. findex .. "/" .. fcount .. ")")
    ftree:add(pf.frame_head, buffer(0, 2)):set_text("帧头[Frame_Head](2bytes),字节序(0):0xEF 0xEF")
    ftree:add(pf.frame_count, buffer(2, 1)):set_text("总帧数[Frame_Count](1bytes),字节序(2):" .. fcount)
    ftree:add(pf.frame_index, buffer(3, 1)):set_text("当前帧序号[Frame_Index](1bytes),字节序(3):" .. findex)
    ftree:add(pf.data_len, buffer(4, 2)):set_text("Data域长度[Data_Len](2bytes),字节序(4):" .. dlen)
    local dtv = buffer(6, dlen)

    if fcount == 1 then
        -- 一帧内可能含多条完整消息
        if dlen > 0 then
            local sub = ftree:add(dtv, "Data(消息):")
            parse_data_messages(dtv, sub, pinfo, dlen, 6)
        end
    else
        -- 跨帧消息重组: 按 Frame_Index 缓存拼接
        local key = conv_key(pinfo)
        local st = reassembly[key]
        if not st then
            st = { count = fcount, chunks = {}, filled = 0 }
            reassembly[key] = st
        end
        if st.count ~= fcount then
            st = { count = fcount, chunks = {}, filled = 0 }
            reassembly[key] = st
        end
        if not st.chunks[findex] then st.chunks[findex] = dtv:bytes(); st.filled = st.filled + 1 end
        local psub = ftree:add(dtv, "Data:跨帧消息片断 (帧 " .. findex .. "/" .. fcount .. ")")
        psub:add(dtv, "Data(帧片断 " .. findex .. "):" .. dtv:raw())

        if st.filled == st.count then
            -- 拼接完整 (用 ByteArray 直接合并, 避免 string->ByteArray 遇 NUL 截断)
            local ba = ByteArray.new()
            for i = 1, st.count do
                if st.chunks[i] then ba:append(st.chunks[i]) end
            end
            reassembly[key] = nil
            local full = ba:tvb("DGL1 重组消息")
            local mt = ftree:add(full, "重组消息(跨" .. fcount .. "帧)")
            parse_data_messages(full, mt, pinfo, full:len(), 6)
        end
    end

    ftree:add(pf.frame_tail, buffer(total - 2, 2)):set_text("帧尾[Frame_Tail](2bytes),字节序(" .. (6 + dlen) .. "):0xFD 0xFD")
    return total
end

function dgl1_protocol.dissector(buffer, pinfo, tree)
    local consumed = parse_frame(buffer, pinfo, tree)
    if consumed == 0 then
        -- 等待更多数据
    elseif consumed == -1 then
        data_dis:call(buffer, pinfo, tree)
    else
        -- 可能一TCP段含多帧, 递归处理剩余
        local rest = buffer(consumed):tvb()
        if rest:len() >= 8 and rest(0, 2):uint() == 0xEFEF then
            dgl1_protocol.dissector(rest, pinfo, tree)
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
    sig_ports = {}
    if dgl1_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(dgl1_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do
            tcp_port:add(port, dgl1_protocol)
            sig_ports[port] = true
        end
    end
end

add_port()
function dgl1_protocol.prefs_changed() add_port() end
