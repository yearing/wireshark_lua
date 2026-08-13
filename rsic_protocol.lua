-- 插件名: RSIC Protocol
-- 版本: 1.0.0#20241107-1
-- 作者: 叶孟鹏
-- 描述: 广州18号线和11号线的 sig协议， RSIC 端口10090，10020，10030
-- 更新时间: 2024-11-07
rsic_protocol = Proto("RSIC", "RSIC Protocol")
-- 首选项
local prefs = rsic_protocol.prefs
prefs.my_version = Pref.statictext("version:1.0.0#20241107-1",
                                   "1.0.0#20241107-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "10020,10030,10090",
                                "RSIC默认端口")

local line_project_tab = {{1, "广州18&22&11号线", 1}, {2, "广州10&12号线", 2}}

-- Create enum preference that shows as Combo Box under
-- Foo Protocol's preferences
prefs.my_line_project = Pref.enum("项目选择:", -- label
1, -- default value
"线路号选择", -- description
line_project_tab, -- enum table
false -- show as combo box
)
data_head = ProtoField.uint16("rsic.data_head", "data_head", base.HEX)
total = ProtoField.uint8("rsic.total", "total", base.DEC)
index = ProtoField.uint8("rsic.index", "index", base.DEC)
data_len = ProtoField.uint16("rsic.data_len", "data_len", base.DEC)
dev_status = ProtoField.uint8("rsic.dev_status", "dev_status", base.DEC)
data_type = ProtoField.uint16("rsic.data_type", "data_type", base.DEC)
data_content = ProtoField.none("rsic.data_content", "data_content", base.HEX)
data_tail = ProtoField.uint16("rsic.data_tail", "data_tail", base.HEX)

train_traingroup = ProtoField.string("rsic.train.train_group", "train group",
                                     base.ASCII)
train_trainlabel = ProtoField.string("rsic.train.train_label", "train label",
                                     base.ASCII)
train_traindirection = ProtoField.uint8("rsic.train.train_direction",
                                        "direction", base.DEC)
train_front_partition_id = ProtoField.uint16("rsic.train.front_partition_id",
                                             "front partition id", base.DEC)
train_block_status = ProtoField.uint8("rsic.train.block_status", "block status",
                                      base.DEC)
train_count = ProtoField.uint16("rsic.train.train_count", "train count",
                                base.DEC)
plan_stationId = ProtoField.uint16("rsic.plan.station_id", "station id",
                                   base.DEC)
plan_platformId = ProtoField.uint8("rsic.plan.platform_id", "platform id",
                                   base.DEC)
plan_traingroup = ProtoField.string("rsic.plan.train_group", "train group",
                                    base.ASCII)
plan_trainlabel = ProtoField.string("rsic.plan.train_label", "train label",
                                    base.ASCII)
plan_stopTrainType = ProtoField.uint8("rsic.plan.stop_train_type",
                                      "stop train type", base.DEC)
plan_currentStatus = ProtoField.uint8("rsic.plan.current_status",
                                      "current status", base.DEC)
plan_destId = ProtoField.uint16("rsic.plan.dest_id", "destination id", base.DEC)
plan_holdTrain =   ProtoField.uint8("rsic.plan.hold_train", "hold train", base.DEC)
plan_fastTrainFlag = ProtoField.uint8("rsic.plan.fast_train_flag",
                                      "fast train flag", base.DEC)
plan_nextdestId = ProtoField.uint16("rsic.plan.next_dest_id",
                                    "next destination id", base.DEC)
plan_clearFlag = ProtoField.uint8("rsic.plan.clear_flag", "clear guest flag",
                                  base.DEC)

firstlastTrain_stationId = ProtoField.uint16("rsic.firstlastTrain.station_id",
                                             "station id", base.DEC)
firstlastTrain_platformId = ProtoField.uint8("rsic.firstlastTrain.platform_id",
                                             "platform id", base.DEC)

traindoor_platformId = ProtoField.uint8("rsic.traindoor.platform_id",
                                        "platform id", base.HEX)

power_count = ProtoField.uint16("rsic.power.power_count", "power count",
                                base.DEC)
power_section_id = ProtoField.uint16("rsic.power.power_section_id",
                                     "power section id", base.DEC)
power_section_status = ProtoField.uint8("rsic.power.power_section_status",
                                        "power section status", base.DEC)
fire_count = ProtoField.uint16("rsic.fire.fire_count", "Station fire count",
                            base.DEC)
fire_section_id = ProtoField.uint16("rsic.stationfire.section_id",
        "stationfire id", base.DEC)
fire_section_status = ProtoField.uint8("rsic.stationfire.status",
        "stationfire status", base.DEC)
zonefire_section_id = ProtoField.uint16("rsic.zonefire.section_id",
        "zonefire id", base.DEC)
zonefire_section_status = ProtoField.uint8("rsic.zonefire.status",
        "zonefire status", base.DEC)
zonewater_section_id = ProtoField.uint16("rsic.zonewater.section_id",
        "zonewater id", base.DEC)
zonewater_section_status = ProtoField.uint8("rsic.zonewater.status",
        "zonewater status", base.DEC)
stationyard_rtuId = ProtoField.uint32("rsic.stationyard.rtu_id",
        "stationyard rtu id", base.DEC)
rsic_protocol.fields = {
    data_head, total, index, data_len, dev_status, data_type, data_content,
    data_tail, train_count, train_traingroup, train_trainlabel,
    train_traindirection, train_front_partition_id, train_block_status,
    plan_stationId, plan_platformId, plan_traingroup, plan_trainlabel,
    plan_stopTrainType, plan_currentStatus, plan_destId, plan_holdTrain,
    plan_fastTrainFlag, plan_nextdestId, plan_clearFlag,
    firstlastTrain_stationId, firstlastTrain_platformId, traindoor_platformId,
    power_count, power_section_id, power_section_status,
    fire_count,fire_section_id,fire_section_status,
    zonefire_section_id,zonefire_section_status,
    zonewater_section_id,zonewater_section_status,
    stationyard_rtuId
}
local dataTypeStr = {
    [0] = "unknown,未知类型",
    [1] = "heartbeat, 心跳信息",
    [2] = "train, 列车信息",
    [3] = "plan, 计划信息",
    [4] = "firstLastTrain, 首末班信息",
    [5] = "trainDoor, 车门隔离状态信息",
    [6] = "platformDoor, 站台门隔离状态信息",
    [7] = "stationYard, 站场表示信息",
    [8] = "power, 供电臂信息",
    [9] = "firstLastTrainRequest, 首末班申请",
    [16] = "stationPlan, 场段出入段计划信息",
    [17] = "stationFire, 车站火灾信息",
    [18] = "zoneFire, 区间火灾信息",
    [19] = "zoneWater, 区间水灾信息",
}

local haStatusStr = {[1] = "primary", [2] = "secondary"}
local directionStr = {[1] = "right/up_trace", [2] = "left/down_trace"}
local blockStr = {[0] = "unblock", [1] = "block"}
local stopTrainTypeStr = {[0] = "stop train", [1] = "no stop train"}
local currentStatusStr = {
    [0] = "no coming",
    [1] = "coming",
    [2] = "stop at station"
}
local holdTrainStr = {[0] = "no hold train", [1] = "hold train"}
local fastTrainFlagStr = {[0] = "slow train", [1] = "fast train"}
local clearTrainFlagStr = {[0] = "no clear train", [1] = "clear train"}
local powerStatusStr = {[0] = "unknown", [1] = "on", [2] = "off"}
local fireStatusStr = {[0] = "unknown", [1] = "fire", [2] = "not fire"}
local data_dis = Dissector.get("data")

local tmp_buf = ByteArray.new()
local function full_packet_dissactor(buffer, pinfo, tree)
    local b_offset = pinfo.desegment_offset or 0
    local buf_len = buffer:len()
    -- 头部分包我暂时没处理，目前假设头部不分包。
    if buf_len < 9 then return -1 end

    while b_offset < buf_len do
        -- ADD 1
        -- total_len = 解析头部获取当前头部指定的应用层payload长度
        -- tcp的负载长度小于应用层头部指定的应用层数据，即应用层数据分包
        local rsic_data_len = buffer(b_offset + 4, 2):le_uint()
        local rsic_total = buffer(b_offset + 2, 1):le_uint()
        local rsic_index = buffer(b_offset + 3, 1):le_uint()
        total_len = 9 + rsic_data_len
        if b_offset + total_len > buffer:len() then
            -- print("not enough")
            -- 标记一下缺多少报文，不知道是否必要
            pinfo.desegment_len = b_offset + total_len - buffer:len()
            -- 标记当前的buf已经处理了多少，下次从offset开始处理
            pinfo.desegment_offset = b_offset
            return 0
        end
        -- ADD 2
        -- 处理
        -- 处理完成，判断剩余是否还有报文，有则继续continue

        pinfo.cols.protocol = rsic_protocol.name

        local subtree = tree:add(rsic_protocol, buffer(b_offset, total_len),
                                 "RSIC Protocol Data, Len: " .. total_len)

        local headerTree = subtree:add(buffer(b_offset + 0, 7), "Header")
        local tailTree =
            subtree:add(buffer(b_offset + total_len - 2, 2), "Tail")
        headerTree:add_le(data_head, buffer(b_offset + 0, 2))
        headerTree:add(total, buffer(b_offset + 2, 1))
        headerTree:add(index, buffer(b_offset + 3, 1))
        headerTree:add_le(data_len, buffer(b_offset + 4, 2))
        local primaryFlag = buffer(b_offset + 6, 1):le_int()
        headerTree:add(dev_status, buffer(b_offset + 6, 1)):append_text(" (" ..
                                                                            haStatusStr[primaryFlag] ..
                                                                            ")")
        if rsic_data_len > 0 then
            headerTree:add_le(buffer(b_offset + 7, rsic_data_len),
                              "Data: (" .. rsic_data_len .. " bytes)")
        end
        if rsic_index==1 then
            local type = buffer(b_offset + 7, 2):le_uint()
            headerTree:add_le(data_type, buffer(b_offset + 7, 2)):append_text(" ," ..
            dataTypeStr[type])
        end
        tailTree:add(data_tail, buffer(b_offset + total_len - 2, 2))

        if rsic_index == 1 then
            tmp_buf = nil 
            tmp_buf = ByteArray.new()
        end

        if rsic_total == rsic_index then
            local byte_range1 = buffer:bytes(b_offset + 7, rsic_data_len)
            tmp_buf:append(byte_range1)
            local tvb = tmp_buf:tvb()
            if prefs.my_line_project == 1  then
                subtree:append_text(" , 广州18&22&11号线")
                hearbeat_data(tvb, pinfo, subtree)
                train_data(tvb, pinfo, subtree)
                plan_data(tvb, pinfo, subtree)
                firsLast_data(tvb, pinfo, subtree)
                trainDoor_data(tvb, pinfo, subtree)
                platformDoor_data(tvb, pinfo, subtree)
                --stationYard_data(tvb, pinfo, subtree)
                power_data(tvb, pinfo, subtree)
                firsLastRequest_data(tvb, pinfo, subtree)
            elseif prefs.my_line_project == 2 then
                subtree:append_text(" ,广州10&12号线协议")
                hearbeat_data(tvb, pinfo, subtree)
                gzl10_train_data(tvb, pinfo, subtree)
                plan_data(tvb, pinfo, subtree)
                firsLast_data(tvb, pinfo, subtree)
                trainDoor_data(tvb, pinfo, subtree)
                platformDoor_data(tvb, pinfo, subtree)
                stationYard_data(tvb, pinfo, subtree)
                power_data(tvb, pinfo, subtree)
                firsLastRequest_data(tvb, pinfo, subtree)
                stationPlan_data(tvb, pinfo, subtree)
                fire_data(tvb, pinfo, subtree)
                zonefire_data(tvb, pinfo, subtree)
                zonewater_data(tvb, pinfo, subtree)
            end
            subtree:append_text(
                " , total:" .. rsic_total .. " ,all data len:" .. tmp_buf:len())
           
        elseif rsic_total > rsic_index then
            
            local byte_range1 = buffer:bytes(b_offset + 7, rsic_data_len)
            tmp_buf:append(byte_range1)
            subtree:append_text(
                " ,need total:" .. rsic_total .. " but index:" .. rsic_index ..
                    " ,this len:" .. tmp_buf:len())
        else
            tmp_buf = nil
            tmp_buf = ByteArray.new()
            subtree:append_text(
                " ,wrong total:" .. rsic_total .. " and index:" .. rsic_index)
            return -1
        end

        b_offset = b_offset + total_len

        if b_offset > buffer:len() then
            return -1
        elseif b_offset == buffer:len() then
            return 1
        end
        -- return 1
    end
end

function rsic_protocol.dissector(buffer, pinfo, tree)
    ret = full_packet_dissactor(buffer, pinfo, tree)
    if ret == 1 then
        -- 完整包
    elseif ret == 0 then
        -- 不完整包
    else
        -- 当发现不是我的协议时，就应该调用data
        data_dis:call(buffer, pinfo, tree)
    end

end
-- 心跳信息
function hearbeat_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 1 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    subtree:add_le(buffer(2, 4), "hearbeat: 0x" .. buffer(2, 4))
end
-- 列车信息
function train_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(offset, 2):le_uint()
    if type ~= 2 then return end
    local trainTree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                             dataTypeStr[type] .. " ,len:" ..
                                             buffer:len())
    trainTree:add_le(data_type, buffer(offset, 2)):append_text(" ," ..
                                                                   dataTypeStr[type])
    offset = offset + 2
    local trainCount = buffer(offset, 2):le_uint()
    if trainCount == 0 then
        trainTree:add_le(train_count, buffer(offset, 2)):append_text(
            " ( empty train)")
        return
    else
        trainTree:add_le(train_count, buffer(offset, 2))
    end
    offset = offset + 2

    for i = 1, trainCount do
        local offset_tmp = offset
        local trainGroupLen = buffer(offset_tmp, 1):le_uint()
        local trainLabelLen = buffer(offset_tmp + 1 + trainGroupLen, 1):le_int()
        local one_train_len = 26 + trainGroupLen + trainLabelLen
        local onetrainTree = trainTree:add_le(buffer(offset, one_train_len),
                                              " trainId:" .. i .. " ,len:" ..
                                                  one_train_len)
        onetrainTree:add_le(buffer(offset, 1),
                            "train group len: " .. trainGroupLen);
        offset = offset + 1
        onetrainTree:add_le(train_traingroup, buffer(offset, trainGroupLen):string())
        offset = offset + trainGroupLen

        onetrainTree:add_le(buffer(offset, 1),
                            "train label len: " .. trainGroupLen);
        offset = offset + 1
        onetrainTree:add_le(train_trainlabel, buffer(offset, trainLabelLen):string())
        offset = offset + trainLabelLen
        onetrainTree:add_le(train_traindirection, buffer(offset, 1))
            :append_text(" ," .. directionStr[buffer(offset, 1):le_uint()])
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 2), "central station id: " ..
                                buffer(offset, 2):le_uint())
        offset = offset + 2
        onetrainTree:add_le(train_front_partition_id, buffer(offset, 2))
        offset = offset + 2
        onetrainTree:add_le(buffer(offset, 4), "front partition offset(cm): " ..
                                buffer(offset, 4):le_uint())
        offset = offset + 4
        onetrainTree:add_le(buffer(offset, 1), "emergency braking: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        local blockflag = buffer(offset, 1):le_uint()
        onetrainTree:add_le(train_block_status, buffer(offset, 1)):append_text(
            " ," .. blockStr[blockflag])
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 2),
                            "dormancy state: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        onetrainTree:add_le(buffer(offset, 1), "working information: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "auto driver: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "driver request: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "CAM request: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 4), "clear platform id: " ..
                                buffer(offset, 4):le_uint())
        offset = offset + 4
        onetrainTree:add_le(buffer(offset, 1), "Overweight status: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "skip mode: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "fire status: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
    end

end

function gzl10_train_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(offset, 2):le_uint()
    if type ~= 2 then return end
    local trainTree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                             dataTypeStr[type] .. " ,len:" ..
                                             buffer:len())
    trainTree:add_le(data_type, buffer(offset, 2)):append_text(" ," ..
                                                                   dataTypeStr[type])
    offset = offset + 2
    local trainCount = buffer(offset, 2):le_uint()
    if trainCount == 0 then
        trainTree:add_le(train_count, buffer(offset, 2)):append_text(
            " ( empty train)")
        return
    else
        trainTree:add_le(train_count, buffer(offset, 2))
    end
    offset = offset + 2

    for i = 1, trainCount do
        local offset_tmp = offset
        local trainGroupLen = buffer(offset_tmp, 1):le_uint()
        local trainLabelLen = buffer(offset_tmp + 1 + trainGroupLen, 1):le_int()
        local one_train_len = 41 + trainGroupLen + trainLabelLen
        local onetrainTree = trainTree:add_le(buffer(offset, one_train_len),
                                              " trainId:" .. i .. " ,len:" ..
                                                  one_train_len)
        onetrainTree:add_le(buffer(offset, 1),
                            "train group len: " .. trainGroupLen);
        offset = offset + 1
        onetrainTree:add_le(train_traingroup, buffer(offset, trainGroupLen):string())
        offset = offset + trainGroupLen

        onetrainTree:add_le(buffer(offset, 1),
                            "train label len: " .. trainLabelLen);
        offset = offset + 1
        onetrainTree:add_le(train_trainlabel, buffer(offset, trainLabelLen):string())
        offset = offset + trainLabelLen
        onetrainTree:add_le(train_traindirection, buffer(offset, 1))
            :append_text(" ," .. directionStr[buffer(offset, 1):le_uint()])
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 2), "central station id: " ..
                                buffer(offset, 2):le_uint())
        offset = offset + 2
        onetrainTree:add_le(train_front_partition_id, buffer(offset, 2))
        offset = offset + 2
        onetrainTree:add_le(buffer(offset, 4), "front partition offset(cm): " ..
                                buffer(offset, 4):le_uint())
        offset = offset + 4
        onetrainTree:add_le(buffer(offset, 1), "emergency braking: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        local blockflag = buffer(offset, 1):le_uint()
        onetrainTree:add_le(train_block_status, buffer(offset, 1)):append_text(
            " ," .. blockStr[blockflag])
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 2),
                            "sleep and wake state: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        onetrainTree:add_le(buffer(offset, 1), "working information: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "auto driver: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "driver request: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "CAM request: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 4), "clear platform id: " ..
                                buffer(offset, 4):le_uint())
        offset = offset + 4
        onetrainTree:add_le(buffer(offset, 1), "Overweight status: " ..
                                buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "skip mode: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "fire status: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 1),
                            "drive mode: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        onetrainTree:add_le(buffer(offset, 2),
            "parking accuracy: " .. buffer(offset, 2):le_uint())
        offset = offset + 2 
        onetrainTree:add_le(buffer(offset, 2),
            "train speed: " .. buffer(offset, 2):le_uint())
        offset = offset + 2 
        onetrainTree:add_le(buffer(offset, 10), "spare:0x"..buffer(offset, 10))
        offset = offset + 10 
    end

end
-- 计划信息
function plan_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 3 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])

    offset = offset + 2
    local platCount = buffer(offset, 2):le_uint()
    subtree:add_le(buffer(offset, 2), "platform count: " .. platCount)
    offset = offset + 2
    for i = 1, platCount do
        local begin = offset
        subtree:add_le(plan_stationId, buffer(offset, 2))
        offset = offset + 2
        subtree:add_le(plan_platformId, buffer(offset, 1))
        offset = offset + 1
        local trainCount = buffer(offset, 2):le_uint()
        subtree:add_le(buffer(offset, 2), "train count: " .. trainCount)
        offset = offset + 2

        for j = 1, trainCount do
            local offset_tmp = offset
            local trainGroupLen = buffer(offset_tmp, 1):le_uint()
            local trainLabelLenLen =
                buffer(offset_tmp + 1 + trainGroupLen, 1):le_uint()
            local onePlanLen = trainGroupLen + trainLabelLenLen + 27
            local oneplantree = subtree:add_le(buffer(offset, onePlanLen),
                                               "train index: " .. j .. " ,len:" ..
                                                   onePlanLen)
            oneplantree:add_le(buffer(offset, 1), "train group len: " ..
                                   buffer(offset, 1):le_uint())
            offset = offset + 1
            oneplantree:add_le(plan_traingroup, buffer(offset, trainGroupLen):string())
            offset = offset + trainGroupLen
            oneplantree:add_le(buffer(offset, 1), "train label len: " ..
                                   buffer(offset, 1):le_uint())
            offset = offset + 1
            oneplantree:add_le(plan_trainlabel, buffer(offset, trainLabelLenLen):string())
            offset = offset + trainLabelLenLen
            oneplantree:add_le(plan_stopTrainType, buffer(offset, 1))
                :append_text(" , " ..
                                 stopTrainTypeStr[buffer(offset, 1):le_uint()])
            offset = offset + 1
            oneplantree:add_le(buffer(offset, 7),
                               "arrive time: " .. getTime(buffer(offset, 7)))
            offset = offset + 7
            oneplantree:add_le(buffer(offset, 7),
                               "departure time: " .. getTime(buffer(offset, 7)))
            offset = offset + 7
            oneplantree:add_le(plan_destId, buffer(offset, 2))
            offset = offset + 2
            oneplantree:add_le(plan_currentStatus, buffer(offset, 1))
                :append_text(" ," ..
                                 currentStatusStr[buffer(offset, 1):le_uint()])
            offset = offset + 1
            oneplantree:add_le(plan_holdTrain, buffer(offset, 1)):append_text(
                " ," .. holdTrainStr[buffer(offset, 1):le_uint()])
            offset = offset + 1
            oneplantree:add_le(buffer(offset, 1),
                               "spare: " .. buffer(offset, 1):le_uint())
            offset = offset + 1
            oneplantree:add_le(plan_fastTrainFlag, buffer(offset, 1))
                :append_text(" ," ..
                                 fastTrainFlagStr[buffer(offset, 1):le_uint()])
            offset = offset + 1
            oneplantree:add_le(plan_nextdestId, buffer(offset, 2))
            offset = offset + 2
            oneplantree:add_le(plan_clearFlag, buffer(offset, 1)):append_text(
                " ," .. clearTrainFlagStr[buffer(offset, 1):le_uint()])
            offset = offset + 1
            oneplantree:add_le(buffer(offset, 1),
                               "spare: " .. buffer(offset, 1):le_uint())
            offset = offset + 1

        end

    end
end
function getTime(buffer)
    local year = buffer(0, 2):le_uint()
    local month = buffer(2, 1):le_uint()
    local day = buffer(3, 1):le_uint()
    local hour = buffer(4, 1):le_uint()
    local minute = buffer(5, 1):le_uint()
    local second = buffer(6, 1):le_uint()
    return year .. "-" .. month .. "-" .. day .. " " .. hour .. ":" .. minute ..
               ":" .. second
end
-- 首末班车
function firsLast_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 4 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])

    offset = offset + 2
    local platCount = buffer(offset, 2):le_uint()
    subtree:add_le(buffer(offset, 2),
                   "platform count: " .. buffer(offset, 2):le_uint())
    offset = offset + 2

    for i = 1, platCount do
        local offset_tmp = offset + 3
        local firstTrainGroupLen = buffer(offset_tmp, 1):le_uint()
        local firstTrainLabelLen =
            buffer(offset_tmp + 1 + firstTrainGroupLen, 1):le_uint()
        local lastTrainGroupLen = buffer(
                                      offset_tmp + firstTrainGroupLen +
                                          firstTrainLabelLen + 19, 1):le_uint()
        local lastTrainLabelLen = buffer(
                                      offset_tmp + firstTrainGroupLen +
                                          firstTrainLabelLen + lastTrainGroupLen +
                                          20, 1):le_uint()
        local oneplatLen = 41 + firstTrainGroupLen + firstTrainLabelLen +
                               lastTrainGroupLen + lastTrainLabelLen
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "platform index: " .. i .. " ,len:" ..
                                               oneplatLen)

        oneplatTree:add_le(firstlastTrain_stationId, buffer(offset, 2))
        offset = offset + 2
        oneplatTree:add_le(firstlastTrain_platformId, buffer(offset, 1))
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, 1), "first train group len: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, firstTrainGroupLen),
                           "first train group: " ..
                               buffer(offset, firstTrainGroupLen):string())
        offset = offset + firstTrainGroupLen
        oneplatTree:add_le(buffer(offset, 1), "first train label len: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, firstTrainLabelLen),
                           "first train label: " ..
                               buffer(offset, firstTrainLabelLen):string())
        offset = offset + firstTrainLabelLen
        oneplatTree:add_le(buffer(offset, 1), "first train stop type: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, 7), "first train arrive time: " ..
                               getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 7), "first train departure time: " ..
                               getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 2), "first train destination: " ..
                               buffer(offset, 2):le_uint())
        offset = offset + 2
        oneplatTree:add_le(buffer(offset, 1), "last train group len: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, lastTrainGroupLen),
                           "last train group: " ..
                               buffer(offset, lastTrainGroupLen):string())
        offset = offset + lastTrainGroupLen
        oneplatTree:add_le(buffer(offset, 1), "last train label len: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, lastTrainLabelLen),
                           "last train label: " ..
                               buffer(offset, lastTrainLabelLen):string())
        offset = offset + lastTrainLabelLen
        oneplatTree:add_le(buffer(offset, 1), "last train stop type: " ..
                               buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, 7), "last train arrive time: " ..
                               getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 7), "last train departure time: " ..
                               getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 2), "last train destination: " ..
                               buffer(offset, 2):le_uint())
        offset = offset + 2
    end
end
-- 车门隔离状态信息
function trainDoor_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 5 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])

    local offset = 2
    subtree:add_le(traindoor_platformId, buffer(offset, 4))
    offset = offset + 4
    subtree:add_le(buffer(offset, 4), "NID_PSD_1:0x" .. buffer(offset, 4))
    offset = offset + 4
    subtree:add_le(buffer(offset, 8), "NID_PSD_1 faults:0x" .. buffer(offset, 8))
    offset = offset + 8
    subtree:add_le(buffer(offset, 4), "NID_PSD_2:0x" .. buffer(offset, 4))
    offset = offset + 4
    subtree:add_le(buffer(offset, 8), "NID_PSD_2 faults:0x" .. buffer(offset, 8))
    offset = offset + 8
end
-- 站台门隔离状态信息
function platformDoor_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 6 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])

    local offset = 2
    local platformCount = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "platform count: " .. platformCount)
    offset = offset + 1
    for i = 1, platformCount do
        local oneplatLen = 44
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "platform index: " .. i .. " ,len:" ..
                                               oneplatLen)
        oneplatTree:add_le(buffer(offset, 4),
                           "platform id:0x" .. buffer(offset, 4))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 4),
                           "NID_PSD_1:0x" .. buffer(offset, 4))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 8),
                           "NID_PSD_1 faults:0x" .. buffer(offset, 8))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 8),
                           "NID_PSD_1 open:0x" .. buffer(offset, 8))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 4),
                           "NID_PSD_2:0x" .. buffer(offset, 4))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 8),
                           "NID_PSD_2 faults:0x" .. buffer(offset, 8))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 8),
                           "NID_PSD_2 open:0x" .. buffer(offset, 8))
        offset = offset + 8
    end
end
-- 站场表示信息
function stationYard_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 7 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = offset + 2
    subtree:add_le(buffer(offset, 1),
                   "1.RTU status,RTU状态: " .. buffer(offset, 1):le_uint())
    offset = offset + 1
    local station_count = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "2.station count,车站信息个数: " .. station_count)
    offset = offset + 1
    for i = 1, station_count do
        local jizhongquid = buffer(offset, 4):le_uint()
        subtree:add_le(stationyard_rtuId, buffer(offset, 4)):append_text(" , 站"..i.." 3.站码:"..jizhongquid)
        --subtree:add_le(buffer(offset, 4),"站"..i.." 3.站码:"..buffer(offset, 4):le_uint())
        offset = offset + 4
        local zcxx_len = buffer(offset, 2):le_uint()
        subtree:add_le(buffer(offset, 2),"站"..i.." 4.站场表示信息长:"..zcxx_len)
        offset = offset + 2
        local index = 1
        local j = 0
         while j < zcxx_len do
            local start1 = offset
            local device_type = buffer(offset, 1):le_uint()
    
            if device_type == 0x11 then
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." 逻辑区段")
            elseif device_type == 0x14 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." 道岔")
            elseif device_type == 0x21 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." 信号机")
            elseif device_type == 0x52 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." ESB按钮")
            elseif device_type == 0x62 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." 防淹门")
            elseif device_type == 0x63 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." SPKS状态灯")
            elseif device_type == 0x64 then 
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." SPKS旁路按钮")
            else  
                subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  5.设备类型:"..device_type.." 未知类型")
            end
            offset = offset + 1
            local shebeiid = buffer(offset,4):le_uint()
            subtree:add_le(buffer(offset, 4), "站"..i.." 序号:"..index.."  6.设备编号:"..shebeiid)
            offset = offset + 4
            local sema_len = buffer(offset, 1):le_uint()
            subtree:add_le(buffer(offset, 1), "站"..i.." 序号:"..index.."  7.色码长度:"..sema_len)
            offset = offset + 1
            subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:0x"..buffer(offset, sema_len))
           if device_type == 0x11 then
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                local b2 = buffer(offset, sema_len):bitfield(2,1)
                local b3 = buffer(offset, sema_len):bitfield(3,1)
                local b4 = buffer(offset, sema_len):bitfield(4,1)
                local b5 = buffer(offset, sema_len):bitfield(5,1)
                local b6 = buffer(offset, sema_len):bitfield(6,1)
                local b7 = buffer(offset, sema_len):bitfield(7,1)
                local b10 = buffer(offset, sema_len):bitfield(10,1)
                local b23 = buffer(offset, sema_len):bitfield(23,1)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1:非通信列车占用状态:"..b1.." b2:锁闭状态:"..b2 .." b3:故障锁闭:"..b3 .." b4:封锁状态:"..b4 .." b5:CBTC通信列车占用状态:"..b5)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b6:保护区段锁闭:"..b6 .." b7:区段切除:"..b7 .." b10:计轴复位:"..b10 .." b23:ARB故障:"..b23)
            elseif device_type == 0x14 then 
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                local b2 = buffer(offset, sema_len):bitfield(2,1)
                local b3 = buffer(offset, sema_len):bitfield(3,1)
                local b4_5 = buffer(offset, sema_len):bitfield(4,2)
                local b6 = buffer(offset, sema_len):bitfield(6,1)
                local b7 = buffer(offset, sema_len):bitfield(7,1)
                local b8 = buffer(offset, sema_len):bitfield(8,1)
                local b9 = buffer(offset, sema_len):bitfield(9,1)
                local b10 = buffer(offset, sema_len):bitfield(10,1)
                local b11 = buffer(offset, sema_len):bitfield(11,1)
                local b30 = buffer(offset, sema_len):bitfield(30,1)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1:非通信列车占用状态:"..b1.." b2:锁闭状态:"..b2 .." b3:故障锁闭:"..b3 .." b4_5:封锁状态:"..b4_5 .." b6:单锁状态:"..b6)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b7:单封状态:"..b7 .." b8:CBTC通信列车占用状态:"..b8 .." b9:保护区段锁闭:"..b9 .." b10:轨道区段切除:"..b10.." b11:区段封锁状态:"..b11.." b30:ARB故障:"..b30)
            elseif device_type == 0x21 then 
                local b1_4 = buffer(offset, sema_len):bitfield(1,4)
                local b5 = buffer(offset, sema_len):bitfield(5,1)
                local b6_9 = buffer(offset, sema_len):bitfield(6,3)
                local b10 = buffer(offset, sema_len):bitfield(10,1)
                local b12 = buffer(offset, sema_len):bitfield(12,1)
                local b14 = buffer(offset, sema_len):bitfield(14,1)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1_4:低位颜色:"..b1_4.." b5:低位闪烁:"..b5 .." b6_9:高位颜色:"..b6_9 .." b10:高位闪烁:"..b10 .." b12:室外信号机关闭（cbtc灭灯）:"..b14.." b12:屏蔽一次临时限速（没有，统一发0）:"..b14)
            elseif device_type == 0x52 then 
                local b0 = buffer(offset, sema_len):bitfield(0,1)
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                local b2_7 = buffer(offset, sema_len):bitfield(2,5)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b0:预留:"..b0.." b1:站台紧急关闭:"..b1.." b2_7:预留:"..b2_7)
            elseif device_type == 0x62 then 
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                local b2 = buffer(offset, sema_len):bitfield(2,1)
                local b3 = buffer(offset, sema_len):bitfield(3,1)
                local b4_7 = buffer(offset, sema_len):bitfield(4,3)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1:门关开状态:"..b1.." b2:关门请求:"..b2.." b3:关门允许:"..b3.." b4_7:预留:"..b4_7)
            elseif device_type == 0x63 then 
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1:SPKS状态灯:"..b1)
            elseif device_type == 0x64 then
                local b1 = buffer(offset, sema_len):bitfield(1,1)
                subtree:add_le(buffer(offset, sema_len),"站"..i.." 序号:"..index.."  8.色码:" .." b1:旁路按钮:"..b1)
            else 
                subtree:add_le(buffer(offset, sema_len), "站"..i.." 序号:"..index.."  5.设备类型:0x"..buffer(offset, sema_len).." 未知数据解析")
            end
            
            offset = offset + sema_len
            local end1 = offset 
            
            j = j+6+ sema_len
            subtree:add_le(buffer(start1, end1-start1),"站"..i.." 序号:"..index.." ,站码.类型.设备id:"..jizhongquid.."."..device_type.."."..shebeiid.. ", 统计-> 设备长度: "..(end1-start1).." 处理的长度:"..j)
            index = index + 1
           
        end
        
    end
end
-- 供电臂 
function power_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 8 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = offset + 2
    local powerCount = buffer(offset, 2):le_uint()
    subtree:add_le(power_count, buffer(offset, 2))
    offset = offset + 2
    for i = 1, powerCount do
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "index: " .. i .. " ,len:" ..
                                               oneplatLen)
        oneplatTree:add_le(power_section_id, buffer(offset, 2))
        offset = offset + 2
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(power_section_status, buffer(offset, 1)):append_text(
            " ," .. powerStatusStr[status])
        offset = offset + 1
    end
end
function firsLastRequest_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 9 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = 2
    subtree:add_le(buffer(offset, 4),
                   "firstLastTrainRequest:0x" .. buffer(offset, 4))
end

function stationPlan_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 16 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                           dataTypeStr[type])
    offset = offset + 2
  
    start_1 = offset
    subtree:add_le(buffer(offset, 7), "1.schedule_date:调度日:" .. getTime(buffer(offset, 7)))
    offset = offset + 7
    drawing_no_len = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1) , "2.drawing_no_len:图号长度: ".. drawing_no_len) 
    offset = offset + 1
    subtree:add_le(buffer(offset, drawing_no_len),  "3.drawing_no:图号: " ..  buffer(offset, drawing_no_len):string())
    offset = offset + drawing_no_len
    subtree:add_le(buffer(offset, 2),  "4.depot_station_code:段/场站码: " ..  buffer(offset, 2):le_uint())
    offset = offset + 2
    local number = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1),  "5.service_group_number:服务号组数: " ..  buffer(offset, 1):le_uint())
    offset = offset + 1
    end_1 = offset
    local len_1 = end_1 - start_1
    subtree:add_le(buffer(start_1, len_1),"统计->(从字段1~字段5)段场计划信息头长度: " .. len_1)
    local len_3 = len_1
    for i = 1, number do
        start_2 = offset
        service_no_len = buffer(offset, 1):le_uint()    
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".. "6.service_no_len:服务号长度: ".. service_no_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, service_no_len),  "组:".. i.." ,".."7.service_no:服务号: " ..  buffer(offset, service_no_len):string())
        offset = offset + service_no_len
        subtree:add_le(buffer(offset, 2),  "组:".. i.." ,".."8.out_depot_code:出段/场站码: " ..  buffer(offset, 2):le_uint())
        offset = offset + 2
        out_train_label_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."9.out_train_label_len:出段/场车次号长度: ".. out_train_label_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, out_train_label_len),  "组:".. i.." ,".."10.out_train_label:出段/场车次号: " ..  buffer(offset, out_train_label_len):string())
        offset = offset + out_train_label_len
        out_train_group_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."11.out_train_group_len:出段/场车组号长度: ".. out_train_group_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, out_train_group_len),  "组:".. i.." ,".."12.out_train_group:出段/场车组号: " ..  buffer(offset, out_train_group_len):string())
        offset = offset + out_train_group_len
        departure_track_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."13.departure_track_len:段/场内出发股道名称长度: ".. departure_track_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, departure_track_len),  "组:".. i.." ,".."14.departure_track:段/场内出发股道名称: " ..  buffer(offset, departure_track_len):string())
        offset = offset + departure_track_len    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."15.planned_departure:段/场内计划出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."16.actual_departure:段/场内出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."17.departure_mark:段/场内报点标志: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        transfer_rail_out_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."18.departure_track_len:段/场转换轨名称长度: ".. transfer_rail_out_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, transfer_rail_out_len), "组:".. i.." ,".. "19.transfer_rail_out:出段/场转换轨名称: " ..  buffer(offset, transfer_rail_out_len):string())
        offset = offset + transfer_rail_out_len    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."20.transfer_arr_plan:出段/场转换轨计划到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."21.transfer_arr_actual:出段/场转换轨到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."22.transfer_dep_plan:出段/场转换轨计划出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."23.transfer_dep_actual:出段/场转换轨出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."24.transfer_mark_out:出段/场转换轨报点标志: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 2) , "组:".. i.." ,".."25.mainline_code_out:出段/场正线站码: "..  buffer(offset, 2):le_uint()) 
        offset = offset + 2
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."26.mainline_arrival:出段/场正线到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 4) , "组:".. i.." ,".."27.destination_code:出段/场目的地码: "..  buffer(offset, 4):le_uint()) 
        offset = offset + 4
        subtree:add_le(buffer(offset, 2) , "组:".. i.." ,".."28.in_depot_code:入段/场车辆段站码: "..  buffer(offset, 2):le_uint()) 
        offset = offset + 2
        in_train_label_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."29.in_train_label_len:入段/场车次号长度: ".. in_train_label_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, in_train_label_len),  "组:".. i.." ,".."30.in_train_label:入段/场车次号: " ..  buffer(offset, in_train_label_len):string())
        offset = offset + in_train_label_len  
        in_train_group_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."31.in_train_group_len:入段/场车组号长度: ".. in_train_group_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, in_train_group_len),  "组:".. i.." ,".."32.in_train_group:入段/场车组号: " ..  buffer(offset, in_train_group_len):string())
        offset = offset + in_train_group_len   
        arrival_track_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."33.arrival_track_len:段/场内到达股道名称长度: ".. arrival_track_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, arrival_track_len),  "组:".. i.." ,".."34.arrival_track:段/场内到达股道名称: " ..  buffer(offset, arrival_track_len):string())
        offset = offset + arrival_track_len 
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."35.planned_arrival:段/场内计划到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."36.actual_arrival:段/场内到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."37.arrival_mark:段/场内报点标志: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        transfer_rail_in_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."38.transfer_rail_in_len: ".. transfer_rail_in_len) 
        offset = offset + 1
        subtree:add_le(buffer(offset, transfer_rail_in_len),  "组:".. i.." ,".."39.transfer_rail_in:入段/场转换轨名称: " ..  buffer(offset, transfer_rail_in_len):string())
        offset = offset + transfer_rail_in_len
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."40.in_transfer_arr_plan:入段/场转换轨计划到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7    
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."41.in_transfer_arr_actual:入段/场转换轨到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."42.in_transfer_dep_plan:入段/场转换轨计划出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."43.in_transfer_dep_actual:入段/场转换轨出发时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."44.transfer_mark_in:入段/场转换轨报点标志: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 2) , "组:".. i.." ,".."45.mainline_code_in:入段/场正线站码: "..  buffer(offset, 2):le_uint()) 
        offset = offset + 2
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."46.mainline_arrival_in:入段/场正线到达时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 4) , "组:".. i.." ,".."47.destination_code_in:入段/场目的地码: "..  buffer(offset, 4):le_uint()) 
        offset = offset + 4
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."48.is_initial:是否是初始化生成: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."49.initial_time:初始化时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."50.is_wash:是否回段洗车:"..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 2) , "组:".. i.." ,".."51.spare:预留:0x "..  buffer(offset, 2)) 
        offset = offset + 2
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."52.is_auto_wake:是否自动唤醒: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."53.wakeup_time:计划唤醒时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."54.is_clean:是否回库清扫: "..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."55.clean_start:清扫开始时间:" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:".. i.." ,".."56.clean_end:清扫结束时间" .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1) , "组:".. i.." ,".."57.is_auto_sleep:是否自动休眠:"..  buffer(offset, 1):le_uint()) 
        offset = offset + 1
        subtree:add_le(buffer(offset, 10) , "组:".. i.." ,".."58.预留:0x"..  buffer(offset, 10)) 
        offset = offset + 10
        end_2 = offset
        len_2 = end_2 - start_2
        len_3 = len_3 + len_2
        subtree:add_le(buffer(start_2, len_2),"统计->组:".. i.." ,".." (从字段6~字段57)段场计划信息头长度: " .. (len_2))
    end    
    subtree:add_le(buffer(start_1, len_3),"统计->: (从字段1~字段57)全部长度: " .. len_3)
end
-- 车站火灾 
function fire_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 17 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = offset + 2
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    for i = 1, fireCount do
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "index: " .. i .. " ,len:" ..
                                               oneplatLen)
        oneplatTree:add_le(fire_section_id, buffer(offset, 2))
        offset = offset + 2
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(fire_section_status, buffer(offset, 1)):append_text(
            " ," .. fireStatusStr[status])
        offset = offset + 1
    end
end

function zonefire_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 18 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = offset + 2
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    for i = 1, fireCount do
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "index: " .. i .. " ,len:" ..
                                               oneplatLen)
        oneplatTree:add_le(zonefire_section_id, buffer(offset, 2))
        offset = offset + 2
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(zonefire_section_status, buffer(offset, 1))
        offset = offset + 1
    end
end

function zonewater_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 19 then return end
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), "Data: " ..
                                           dataTypeStr[type] .. " ,len:" ..
                                           buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" ," ..
                                                            dataTypeStr[type])
    offset = offset + 2
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    for i = 1, fireCount do
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
                                           "index: " .. i .. " ,len:" ..
                                               oneplatLen)
        oneplatTree:add_le(zonewater_section_id, buffer(offset, 2))
        offset = offset + 2
        local status = buffer(offset, 1):le_uint() 
        oneplatTree:add_le(zonewater_section_status, buffer(offset, 1))
        offset = offset + 1
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
    if rsic_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(rsic_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do tcp_port:add(port, rsic_protocol) end
    end
end

add_port()
function rsic_protocol.prefs_changed() add_port() end
