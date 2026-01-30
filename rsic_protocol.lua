-- ========================================================================
-- 插件名: RSIC Protocol
-- 版本: 1.0.0#20241107-1
-- 作者: 叶孟鹏
-- 描述: 广州地铁信号系统协议解析插件
--        支持线路: 广州18号线/11号线/22号线, 广州10号线/12号线
--        默认端口: 10090, 10020, 10030
-- 更新时间: 2024-11-07
-- ========================================================================

-- 创建协议对象
rsic_protocol = Proto("RSIC", "RSIC Protocol (地铁信号系统)")

-- ========================================================================
-- 首选项配置
-- ========================================================================
local prefs = rsic_protocol.prefs

-- 版本号显示（只读）
prefs.my_version = Pref.statictext("版本号", "1.0.0#20241107-1")

-- 端口配置
prefs.my_tcp_port = Pref.string("监听端口(s)", "10020,10030,10090", 
    "RSIC协议监听的TCP端口，多个端口用英文逗号分隔")

-- 线路项目选择
local line_project_tab = {
    {1, "广州18&22&11号线", 1},
    {2, "广州10&12号线", 2}
}
prefs.my_line_project = Pref.enum("线路选择", 1, "选择解析的地铁线路", 
    line_project_tab, false)

-- ========================================================================
-- 协议字段定义
-- ========================================================================

-- 协议基础字段
local data_head = ProtoField.uint16("rsic.data_head", "数据头标识", base.HEX)
local total = ProtoField.uint8("rsic.total", "分包总数", base.DEC)
local index = ProtoField.uint8("rsic.index", "当前分包序号", base.DEC)
local data_len = ProtoField.uint16("rsic.data_len", "数据体长度", base.DEC)
local dev_status = ProtoField.uint8("rsic.dev_status", "设备主备状态", base.DEC)
local data_type = ProtoField.uint16("rsic.data_type", "数据类型", base.DEC)
local data_content = ProtoField.none("rsic.data_content", "数据体内容", base.HEX)
local data_tail = ProtoField.uint16("rsic.data_tail", "数据尾标识", base.HEX)

-- 列车信息字段
local train_count = ProtoField.uint16("rsic.train.train_count", "列车数量", base.DEC)
local train_traingroup = ProtoField.string("rsic.train.train_group", "车组号", base.ASCII)
local train_trainlabel = ProtoField.string("rsic.train.train_label", "车次号", base.ASCII)
local train_traindirection = ProtoField.uint8("rsic.train.train_direction", "运行方向", base.DEC)
local train_front_partition_id = ProtoField.uint16("rsic.train.front_partition_id", "前方分区ID", base.DEC)
local train_block_status = ProtoField.uint8("rsic.train.block_status", "封锁状态", base.DEC)

-- 计划信息字段
local plan_stationId = ProtoField.uint16("rsic.plan.station_id", "车站ID", base.DEC)
local plan_platformId = ProtoField.uint8("rsic.plan.platform_id", "站台ID", base.DEC)
local plan_traingroup = ProtoField.string("rsic.plan.train_group", "车组号", base.ASCII)
local plan_trainlabel = ProtoField.string("rsic.plan.train_label", "车次号", base.ASCII)
local plan_stopTrainType = ProtoField.uint8("rsic.plan.stop_train_type", "停车类型", base.DEC)
local plan_currentStatus = ProtoField.uint8("rsic.plan.current_status", "当前状态", base.DEC)
local plan_destId = ProtoField.uint16("rsic.plan.dest_id", "目的地ID", base.DEC)
local plan_holdTrain = ProtoField.uint8("rsic.plan.hold_train", "扣车标识", base.DEC)
local plan_fastTrainFlag = ProtoField.uint8("rsic.plan.fast_train_flag", "快车标识", base.DEC)
local plan_nextdestId = ProtoField.uint16("rsic.plan.next_dest_id", "下一站目的地ID", base.DEC)
local plan_clearFlag = ProtoField.uint8("rsic.plan.clear_flag", "清客标识", base.DEC)

-- 首末班信息字段
local firstlastTrain_stationId = ProtoField.uint16("rsic.firstlastTrain.station_id", "车站ID", base.DEC)
local firstlastTrain_platformId = ProtoField.uint8("rsic.firstlastTrain.platform_id", "站台ID", base.DEC)

-- 车门信息字段
local traindoor_platformId = ProtoField.uint8("rsic.traindoor.platform_id", "站台ID", base.HEX)

-- 供电臂信息字段
local power_count = ProtoField.uint16("rsic.power.power_count", "供电臂数量", base.DEC)
local power_section_id = ProtoField.uint16("rsic.power.power_section_id", "供电臂ID", base.DEC)
local power_section_status = ProtoField.uint8("rsic.power.power_section_status", "供电臂状态", base.DEC)

-- 火灾信息字段
local fire_count = ProtoField.uint16("rsic.fire.fire_count", "火灾信息数量", base.DEC)
local fire_section_id = ProtoField.uint16("rsic.stationfire.section_id", "车站火灾分区ID", base.DEC)
local fire_section_status = ProtoField.uint8("rsic.stationfire.status", "车站火灾状态", base.DEC)
local zonefire_section_id = ProtoField.uint16("rsic.zonefire.section_id", "区间火灾分区ID", base.DEC)
local zonefire_section_status = ProtoField.uint8("rsic.zonefire.status", "区间火灾状态", base.DEC)
local zonewater_section_id = ProtoField.uint16("rsic.zonewater.section_id", "区间水灾分区ID", base.DEC)
local zonewater_section_status = ProtoField.uint8("rsic.zonewater.status", "区间水灾状态", base.DEC)

-- 站场信息字段
local stationyard_rtuId = ProtoField.uint32("rsic.stationyard.rtu_id", "站场RTU ID", base.DEC)

-- 注册所有协议字段
rsic_protocol.fields = {
    -- 基础字段
    data_head, total, index, data_len, dev_status, data_type, data_content, data_tail,
    -- 列车信息
    train_count, train_traingroup, train_trainlabel,
    train_traindirection, train_front_partition_id, train_block_status,
    -- 计划信息
    plan_stationId, plan_platformId, plan_traingroup, plan_trainlabel,
    plan_stopTrainType, plan_currentStatus, plan_destId, plan_holdTrain,
    plan_fastTrainFlag, plan_nextdestId, plan_clearFlag,
    -- 首末班信息
    firstlastTrain_stationId, firstlastTrain_platformId,
    -- 车门信息
    traindoor_platformId,
    -- 供电臂信息
    power_count, power_section_id, power_section_status,
    -- 火灾/水灾信息
    fire_count, fire_section_id, fire_section_status,
    zonefire_section_id, zonefire_section_status,
    zonewater_section_id, zonewater_section_status,
    -- 站场信息
    stationyard_rtuId
}

-- ========================================================================
-- 枚举值映射（数值转语义，提升可读性）
-- ========================================================================

-- 数据类型映射
local dataTypeStr = {
    [0] = "未知类型",
    [1] = "心跳信息",
    [2] = "列车信息",
    [3] = "计划信息",
    [4] = "首末班信息",
    [5] = "车门隔离状态信息",
    [6] = "站台门隔离状态信息",
    [7] = "站场表示信息",
    [8] = "供电臂信息",
    [9] = "首末班申请",
    [16] = "场段出入段计划信息",
    [17] = "车站火灾信息",
    [18] = "区间火灾信息",
    [19] = "区间水灾信息"
}

-- 设备状态映射
local haStatusStr = {[1] = "主用", [2] = "备用"}

-- 运行方向映射
local directionStr = {[1] = "上行", [2] = "下行"}

-- 封锁状态映射
local blockStr = {[0] = "未封锁", [1] = "已封锁"}

-- 停车类型映射
local stopTrainTypeStr = {[0] = "停车", [1] = "通过"}

-- 当前状态映射
local currentStatusStr = {
    [0] = "未进站",
    [1] = "进站中",
    [2] = "站内停车"
}

-- 扣车标识映射
local holdTrainStr = {[0] = "不扣车", [1] = "扣车"}

-- 快车标识映射
local fastTrainFlagStr = {[0] = "普通车", [1] = "快车"}

-- 清客标识映射
local clearTrainFlagStr = {[0] = "不清客", [1] = "清客"}

-- 供电状态映射
local powerStatusStr = {[0] = "未知", [1] = "供电", [2] = "断电"}

-- 火灾状态映射
local fireStatusStr = {[0] = "未知", [1] = "火灾", [2] = "无火灾"}

-- ========================================================================
-- 全局常量定义
-- ========================================================================
local CONST = {
    HEADER_LEN = 9,                -- RSIC协议基础头部长度
    TRAIN_LEN_GZ18 = 26,           -- 广州18&11&22号线单列车基础数据长度
    TRAIN_LEN_GZ10 = 41,           -- 广州10&12号线单列车基础数据长度
    DEFAULT_PORTS = "10020,10030,10090"  -- 默认监听端口
}

-- ========================================================================
-- 全局变量定义
-- ========================================================================
local data_dis = Dissector.get("data")  -- 未知协议交给Wireshark默认data解析器
local session_cache = {}  -- 会话数据缓存（使用 conversation key 作为索引）

-- ========================================================================
-- 工具函数
-- ========================================================================

--- 获取会话唯一标识
---@param pinfo PacketInfo 数据包信息
---@return string 会话唯一标识字符串
local function get_session_key(pinfo)
    return tostring(pinfo.src) .. ":" .. pinfo.src_port .. "->" .. 
           tostring(pinfo.dst) .. ":" .. pinfo.dst_port
end

--- 解析端口字符串为数字数组
---@param ports_str string 端口字符串（逗号分隔）
---@return table 端口数字数组
local function parse_ports(ports_str)
    local ports = {}
    for port in string.gmatch(ports_str, "%d+") do
        table.insert(ports, tonumber(port))
    end
    return ports
end

--- 转换为十六进制字符串（兼容旧版 Wireshark）
---@param tvb TvbRange TVB范围对象
---@return string 十六进制字符串
local function to_hex_string(tvb)
    local ok, result = pcall(function()
        return tvb:tohex()
    end)
    if ok then
        return result
    end
    
    -- 备用方法：手动转换为十六进制字符串
    local bytes = tvb:bytes()
    local hex_str = ""
    for i = 0, bytes:len() - 1 do
        hex_str = hex_str .. string.format("%02X", bytes:get_index(i))
    end
    return hex_str
end

--- 时间解析函数（增强校验+格式化补零，避免无效时间）
---@param buffer Tvb 时间字段缓冲区（7字节：年2+月1+日1+时1+分1+秒1）
---@return string 格式化时间字符串（YYYY-MM-DD HH:MM:SS）
function getTime(buffer)
    local year = buffer(0, 2):le_uint()
    local month = math.min(buffer(2, 1):le_uint(), 12)
    local day = math.min(buffer(3, 1):le_uint(), 31)
    local hour = math.min(buffer(4, 1):le_uint(), 23)
    local minute = math.min(buffer(5, 1):le_uint(), 59)
    local second = math.min(buffer(6, 1):le_uint(), 59)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", 
        year, month, day, hour, minute, second)
end

-- ========================================================================
-- 核心分包解析函数
-- ========================================================================
local function full_packet_dissactor(buffer, pinfo, tree)
    local b_offset = pinfo.desegment_offset or 0
    local buf_len = buffer:len()

    -- 基础头部长度校验
    if buf_len < CONST.HEADER_LEN then return -1 end

    -- 初始化TCP会话缓存：解决多流串扰问题，每个会话独立缓存
    local session_key = get_session_key(pinfo)
    if not session_cache[session_key] then
        session_cache[session_key] = ByteArray.new()
    end
    local tmp_buf = session_cache[session_key]

    while b_offset < buf_len do
        -- 安全校验：确保至少有头部数据可读
        if b_offset + CONST.HEADER_LEN > buf_len then
            return -1
        end

        -- 解析分包核心字段
        local rsic_data_len = buffer(b_offset + 4, 2):le_uint()
        local rsic_total = buffer(b_offset + 2, 1):le_uint()
        local rsic_index = buffer(b_offset + 3, 1):le_uint()
        local total_len = CONST.HEADER_LEN + rsic_data_len

        -- 数据长度不足：标记为不完整包，等待后续分包
        if b_offset + total_len > buf_len then
            pinfo.desegment_len = (b_offset + total_len) - buf_len
            pinfo.desegment_offset = b_offset
            return 0
        end

        -- 非法分包校验：总数 < 序号，标记错误并清空缓存
        if rsic_total < rsic_index then
            local err_msg = string.format("分包序号非法：总数[%d] < 当前序号[%d]", rsic_total, rsic_index)
            print(string.format("[RSIC协议错误] %s:%d -> %s:%d | %s",
                tostring(pinfo.src), pinfo.src_port, tostring(pinfo.dst), pinfo.dst_port, err_msg))
            local subtree = tree:add(rsic_protocol, buffer(b_offset, math.min(total_len, buf_len - b_offset)), 
                "RSIC Protocol [错误] " .. err_msg)
            subtree:add_expert_info(PI_MALFORMED, PI_ERROR, err_msg)
            tmp_buf = ByteArray.new()
            session_cache[session_key] = tmp_buf
            b_offset = b_offset + total_len
        else
            -- 合法包处理：设置协议名，创建解析树
            pinfo.cols.protocol = rsic_protocol.name

            local subtree = tree:add(rsic_protocol, buffer(b_offset, total_len),
                string.format("RSIC Protocol Data, 总长度: %d | 分包: %d/%d", 
                    total_len, rsic_index, rsic_total))

            -- 解析头部
            local headerTree = subtree:add(buffer(b_offset, CONST.HEADER_LEN - 2), "协议头部")
            headerTree:add_le(data_head, buffer(b_offset + 0, 2))
            headerTree:add(total, buffer(b_offset + 2, 1)):append_text(" (分包总数)")
            headerTree:add(index, buffer(b_offset + 3, 1)):append_text(" (当前分包)")
            headerTree:add_le(data_len, buffer(b_offset + 4, 2)):append_text(" (数据体长度)")
            local primaryFlag = buffer(b_offset + 6, 1):le_int()
            headerTree:add(dev_status, buffer(b_offset + 6, 1)):append_text(" (" .. 
                (haStatusStr[primaryFlag] or "未知状态") .. ")")

            -- 解析数据体
            if rsic_data_len > 0 then
                headerTree:add_le(buffer(b_offset + 7, rsic_data_len), 
                    "数据体: " .. rsic_data_len .. " 字节")
            end

            -- 解析数据类型（仅第一个分包显示）
            if rsic_index == 1 and rsic_data_len >= 2 then
                local type = buffer(b_offset + 7, 2):le_uint()
                headerTree:add_le(data_type, buffer(b_offset + 7, 2)):append_text(" (" .. 
                    (dataTypeStr[type] or "未知类型") .. ")")
            end

            -- 解析尾部
            local tailTree = subtree:add(buffer(b_offset + total_len - 2, 2), "协议尾部")
            tailTree:add_le(data_tail, buffer(b_offset + total_len - 2, 2))

            -- 分包拼接：第一个分包清空缓存，后续分包追加
            if rsic_index == 1 then
                tmp_buf = ByteArray.new()
                session_cache[session_key] = tmp_buf
            end
            if rsic_data_len > 0 then
                local byte_range1 = buffer:bytes(b_offset + 7, rsic_data_len)
                tmp_buf:append(byte_range1)
            end

            -- 完整包拼接完成：根据线路解析具体业务数据
            if rsic_total == rsic_index then
                local tvb = tmp_buf:tvb()
                -- 标记线路类型
                if prefs.my_line_project == 1 then
                    subtree:append_text(" | 广州18&22&11号线")
                    -- 解析各类业务数据
                    heartbeat_data(tvb, pinfo, subtree)
                    train_data(tvb, pinfo, subtree)
                    plan_data(tvb, pinfo, subtree)
                    firstLast_data(tvb, pinfo, subtree)
                    trainDoor_data(tvb, pinfo, subtree)
                    platformDoor_data(tvb, pinfo, subtree)
                    power_data(tvb, pinfo, subtree)
                    firstLastRequest_data(tvb, pinfo, subtree)
                elseif prefs.my_line_project == 2 then
                    subtree:append_text(" | 广州10&12号线")
                    -- 解析各类业务数据（含10/12号线特有）
                    heartbeat_data(tvb, pinfo, subtree)
                    gzl10_train_data(tvb, pinfo, subtree)
                    plan_data(tvb, pinfo, subtree)
                    firstLast_data(tvb, pinfo, subtree)
                    trainDoor_data(tvb, pinfo, subtree)
                    platformDoor_data(tvb, pinfo, subtree)
                    stationYard_data(tvb, pinfo, subtree)
                    power_data(tvb, pinfo, subtree)
                    firstLastRequest_data(tvb, pinfo, subtree)
                    stationPlan_data(tvb, pinfo, subtree)
                    fire_data(tvb, pinfo, subtree)
                    zonefire_data(tvb, pinfo, subtree)
                    zonewater_data(tvb, pinfo, subtree)
                end
                subtree:append_text(string.format(" | 拼接后总数据长度: %d", tmp_buf:len()))
            else
                -- 未完成拼接：标记当前缓存长度
                subtree:append_text(string.format(" | 拼接中，当前缓存长度: %d", tmp_buf:len()))
            end

            -- 推进偏移，继续处理后续数据
            b_offset = b_offset + total_len
        end

        if b_offset > buffer:len() then
            return -1
        elseif b_offset == buffer:len() then
            return 1
        end
    end
end

-- ========================================================================
-- 协议主解析函数
-- ========================================================================
function rsic_protocol.dissector(buffer, pinfo, tree)
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

-- ========================================================================
-- 业务数据解析函数
-- ========================================================================

--- 心跳信息解析
function heartbeat_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 1 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    subtree:add_le(buffer(2, 4), "心跳标识: 0x" .. to_hex_string(buffer(2, 4)))
end

--- 广州18/11/22号线列车信息解析
function train_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(offset, 2):le_uint()
    if type ~= 2 then return end
    
    local trainTree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    trainTree:add_le(data_type, buffer(offset, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local trainCount = buffer(offset, 2):le_uint()
    if trainCount == 0 then
        trainTree:add_le(train_count, buffer(offset, 2)):append_text(" (无列车数据)")
        return
    else
        trainTree:add_le(train_count, buffer(offset, 2))
    end
    offset = offset + 2

    for i = 1, trainCount do
        local offset_tmp = offset
        local trainGroupLen = buffer(offset_tmp, 1):le_uint()
        local trainLabelLen = buffer(offset_tmp + 1 + trainGroupLen, 1):le_int()
        local one_train_len = CONST.TRAIN_LEN_GZ18 + trainGroupLen + trainLabelLen
        
        local onetrainTree = trainTree:add_le(buffer(offset, one_train_len),
            "列车" .. i .. " | 数据长度: " .. one_train_len)
        
        -- 车组号
        onetrainTree:add_le(buffer(offset, 1), "车组号长度: " .. trainGroupLen)
        offset = offset + 1
        onetrainTree:add_le(train_traingroup, buffer(offset, trainGroupLen):string())
        offset = offset + trainGroupLen
        
        -- 车次号
        onetrainTree:add_le(buffer(offset, 1), "车次号长度: " .. trainLabelLen)
        offset = offset + 1
        onetrainTree:add_le(train_trainlabel, buffer(offset, trainLabelLen):string())
        offset = offset + trainLabelLen
        
        -- 其他字段
        onetrainTree:add_le(train_traindirection, buffer(offset, 1))
            :append_text(" (" .. (directionStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 2), "中心站ID: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(train_front_partition_id, buffer(offset, 2))
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 4), "前方分区偏移(cm): " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        
        onetrainTree:add_le(buffer(offset, 1), "紧急制动: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        local blockflag = buffer(offset, 1):le_uint()
        onetrainTree:add_le(train_block_status, buffer(offset, 1)):append_text(
            " (" .. (blockStr[blockflag] or "未知") .. ")")
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 2), "休眠状态: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 1), "工作信息: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "自动驾驶: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "司机请求: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "CAM请求: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 4), "清空站台ID: " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        
        onetrainTree:add_le(buffer(offset, 1), "超重状态: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "越站模式: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "火灾状态: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
    end
end

--- 广州10/12号线列车信息解析
function gzl10_train_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(offset, 2):le_uint()
    if type ~= 2 then return end
    
    local trainTree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    trainTree:add_le(data_type, buffer(offset, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local trainCount = buffer(offset, 2):le_uint()
    if trainCount == 0 then
        trainTree:add_le(train_count, buffer(offset, 2)):append_text(" (无列车数据)")
        return
    else
        trainTree:add_le(train_count, buffer(offset, 2))
    end
    offset = offset + 2

    for i = 1, trainCount do
        local offset_tmp = offset
        local trainGroupLen = buffer(offset_tmp, 1):le_uint()
        local trainLabelLen = buffer(offset_tmp + 1 + trainGroupLen, 1):le_int()
        local one_train_len = CONST.TRAIN_LEN_GZ10 + trainGroupLen + trainLabelLen
        
        local onetrainTree = trainTree:add_le(buffer(offset, one_train_len),
            "列车" .. i .. " | 数据长度: " .. one_train_len)
        
        -- 车组号
        onetrainTree:add_le(buffer(offset, 1), "车组号长度: " .. trainGroupLen)
        offset = offset + 1
        onetrainTree:add_le(train_traingroup, buffer(offset, trainGroupLen):string())
        offset = offset + trainGroupLen
        
        -- 车次号
        onetrainTree:add_le(buffer(offset, 1), "车次号长度: " .. trainLabelLen)
        offset = offset + 1
        onetrainTree:add_le(train_trainlabel, buffer(offset, trainLabelLen):string())
        offset = offset + trainLabelLen
        
        -- 其他字段（与18号线相同的部分）
        onetrainTree:add_le(train_traindirection, buffer(offset, 1))
            :append_text(" (" .. (directionStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 2), "中心站ID: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(train_front_partition_id, buffer(offset, 2))
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 4), "前方分区偏移(cm): " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        
        onetrainTree:add_le(buffer(offset, 1), "紧急制动: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        local blockflag = buffer(offset, 1):le_uint()
        onetrainTree:add_le(train_block_status, buffer(offset, 1)):append_text(
            " (" .. (blockStr[blockflag] or "未知") .. ")")
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 2), "休眠唤醒状态: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 1), "工作信息: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "自动驾驶: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "司机请求: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "CAM请求: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 4), "清空站台ID: " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        
        onetrainTree:add_le(buffer(offset, 1), "超重状态: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "越站模式: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 1), "火灾状态: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        -- 10号线特有字段
        onetrainTree:add_le(buffer(offset, 1), "驾驶模式: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        onetrainTree:add_le(buffer(offset, 2), "停车精度: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 2), "列车速度: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        onetrainTree:add_le(buffer(offset, 10), "预留: 0x" .. to_hex_string(buffer(offset, 10)))
        offset = offset + 10
    end
end

--- 计划信息解析
function plan_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 3 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local platCount = buffer(offset, 2):le_uint()
    subtree:add_le(buffer(offset, 2), "站台数量: " .. platCount)
    offset = offset + 2
    
    for i = 1, platCount do
        subtree:add_le(plan_stationId, buffer(offset, 2))
        offset = offset + 2
        subtree:add_le(plan_platformId, buffer(offset, 1))
        offset = offset + 1
        
        local trainCount = buffer(offset, 2):le_uint()
        subtree:add_le(buffer(offset, 2), "列车数量: " .. trainCount)
        offset = offset + 2

        for j = 1, trainCount do
            local offset_tmp = offset
            local trainGroupLen = buffer(offset_tmp, 1):le_uint()
            local trainLabelLenLen = buffer(offset_tmp + 1 + trainGroupLen, 1):le_uint()
            local onePlanLen = trainGroupLen + trainLabelLenLen + 27
            
            local oneplantree = subtree:add_le(buffer(offset, onePlanLen),
                "列车序号: " .. j .. " | 长度: " .. onePlanLen)
            
            oneplantree:add_le(buffer(offset, 1), "车组号长度: " .. buffer(offset, 1):le_uint())
            offset = offset + 1
            oneplantree:add_le(plan_traingroup, buffer(offset, trainGroupLen):string())
            offset = offset + trainGroupLen
            
            oneplantree:add_le(buffer(offset, 1), "车次号长度: " .. buffer(offset, 1):le_uint())
            offset = offset + 1
            oneplantree:add_le(plan_trainlabel, buffer(offset, trainLabelLenLen):string())
            offset = offset + trainLabelLenLen
            
            oneplantree:add_le(plan_stopTrainType, buffer(offset, 1))
                :append_text(" (" .. (stopTrainTypeStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
            offset = offset + 1
            
            oneplantree:add_le(buffer(offset, 7), "到达时间: " .. getTime(buffer(offset, 7)))
            offset = offset + 7
            
            oneplantree:add_le(buffer(offset, 7), "出发时间: " .. getTime(buffer(offset, 7)))
            offset = offset + 7
            
            oneplantree:add_le(plan_destId, buffer(offset, 2))
            offset = offset + 2
            
            oneplantree:add_le(plan_currentStatus, buffer(offset, 1))
                :append_text(" (" .. (currentStatusStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
            offset = offset + 1
            
            oneplantree:add_le(plan_holdTrain, buffer(offset, 1)):append_text(
                " (" .. (holdTrainStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
            offset = offset + 1
            
            oneplantree:add_le(buffer(offset, 1), "预留: " .. buffer(offset, 1):le_uint())
            offset = offset + 1
            
            oneplantree:add_le(plan_fastTrainFlag, buffer(offset, 1))
                :append_text(" (" .. (fastTrainFlagStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
            offset = offset + 1
            
            oneplantree:add_le(plan_nextdestId, buffer(offset, 2))
            offset = offset + 2
            
            oneplantree:add_le(plan_clearFlag, buffer(offset, 1)):append_text(
                " (" .. (clearTrainFlagStr[buffer(offset, 1):le_uint()] or "未知") .. ")")
            offset = offset + 1
            
            oneplantree:add_le(buffer(offset, 1), "预留: " .. buffer(offset, 1):le_uint())
            offset = offset + 1
        end
    end
end

--- 首末班信息解析
function firstLast_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 4 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local platCount = buffer(offset, 2):le_uint()
    subtree:add_le(buffer(offset, 2), "站台数量: " .. buffer(offset, 2):le_uint())
    offset = offset + 2

    for i = 1, platCount do
        local offset_tmp = offset + 3
        local firstTrainGroupLen = buffer(offset_tmp, 1):le_uint()
        local firstTrainLabelLen = buffer(offset_tmp + 1 + firstTrainGroupLen, 1):le_uint()
        local lastTrainGroupLen = buffer(offset_tmp + firstTrainGroupLen + firstTrainLabelLen + 19, 1):le_uint()
        local lastTrainLabelLen = buffer(offset_tmp + firstTrainGroupLen + firstTrainLabelLen + lastTrainGroupLen + 20, 1):le_uint()
        local oneplatLen = 41 + firstTrainGroupLen + firstTrainLabelLen + lastTrainGroupLen + lastTrainLabelLen
        
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "站台序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(firstlastTrain_stationId, buffer(offset, 2))
        offset = offset + 2
        oneplatTree:add_le(firstlastTrain_platformId, buffer(offset, 1))
        offset = offset + 1
        
        oneplatTree:add_le(buffer(offset, 1), "首班车车组号长度: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, firstTrainGroupLen), 
            "首班车车组号: " .. buffer(offset, firstTrainGroupLen):string())
        offset = offset + firstTrainGroupLen
        
        oneplatTree:add_le(buffer(offset, 1), "首班车车次号长度: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, firstTrainLabelLen), 
            "首班车车次号: " .. buffer(offset, firstTrainLabelLen):string())
        offset = offset + firstTrainLabelLen
        
        oneplatTree:add_le(buffer(offset, 1), "首班车停车类型: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, 7), "首班车到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 7), "首班车出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 2), "首班车目的地: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        oneplatTree:add_le(buffer(offset, 1), "末班车车组号长度: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, lastTrainGroupLen), 
            "末班车车组号: " .. buffer(offset, lastTrainGroupLen):string())
        offset = offset + lastTrainGroupLen
        
        oneplatTree:add_le(buffer(offset, 1), "末班车车次号长度: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, lastTrainLabelLen), 
            "末班车车次号: " .. buffer(offset, lastTrainLabelLen):string())
        offset = offset + lastTrainLabelLen
        
        oneplatTree:add_le(buffer(offset, 1), "末班车停车类型: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        oneplatTree:add_le(buffer(offset, 7), "末班车到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 7), "末班车出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        oneplatTree:add_le(buffer(offset, 2), "末班车目的地: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
    end
end

--- 车门隔离状态信息解析
function trainDoor_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 5 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    
    local offset = 2
    subtree:add_le(traindoor_platformId, buffer(offset, 4))
    offset = offset + 4
    subtree:add_le(buffer(offset, 4), "NID_PSD_1: 0x" .. to_hex_string(buffer(offset, 4)))
    offset = offset + 4
    subtree:add_le(buffer(offset, 8), "NID_PSD_1故障: 0x" .. to_hex_string(buffer(offset, 8)))
    offset = offset + 8
    subtree:add_le(buffer(offset, 4), "NID_PSD_2: 0x" .. to_hex_string(buffer(offset, 4)))
    offset = offset + 4
    subtree:add_le(buffer(offset, 8), "NID_PSD_2故障: 0x" .. to_hex_string(buffer(offset, 8)))
    offset = offset + 8
end

--- 站台门隔离状态信息解析
function platformDoor_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 6 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    
    local offset = 2
    local platformCount = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "站台数量: " .. platformCount)
    offset = offset + 1
    
    for i = 1, platformCount do
        local oneplatLen = 44
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "站台序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(buffer(offset, 4), "站台ID: 0x" .. to_hex_string(buffer(offset, 4)))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 4), "NID_PSD_1: 0x" .. to_hex_string(buffer(offset, 4)))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 8), "NID_PSD_1故障: 0x" .. to_hex_string(buffer(offset, 8)))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 8), "NID_PSD_1开启: 0x" .. to_hex_string(buffer(offset, 8)))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 4), "NID_PSD_2: 0x" .. to_hex_string(buffer(offset, 4)))
        offset = offset + 4
        oneplatTree:add_le(buffer(offset, 8), "NID_PSD_2故障: 0x" .. to_hex_string(buffer(offset, 8)))
        offset = offset + 8
        oneplatTree:add_le(buffer(offset, 8), "NID_PSD_2开启: 0x" .. to_hex_string(buffer(offset, 8)))
        offset = offset + 8
    end
end

--- 站场表示信息解析
function stationYard_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 7 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    subtree:add_le(buffer(offset, 1), "RTU状态: " .. buffer(offset, 1):le_uint())
    offset = offset + 1
    
    local station_count = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "车站信息个数: " .. station_count)
    offset = offset + 1
    
    for i = 1, station_count do
        local jizhongquid = buffer(offset, 4):le_uint()
        subtree:add_le(stationyard_rtuId, buffer(offset, 4)):append_text(" (站" .. i .. ")")
        offset = offset + 4
        
        local zcxx_len = buffer(offset, 2):le_uint()
        subtree:add_le(buffer(offset, 2), "站场表示信息长度: " .. zcxx_len)
        offset = offset + 2
        
        local index = 1
        local j = 0
        while j < zcxx_len do
            local start1 = offset
            local device_type = buffer(offset, 1):le_uint()
            
            local device_type_str = "未知类型"
            if device_type == 0x11 then
                device_type_str = "逻辑区段"
            elseif device_type == 0x14 then
                device_type_str = "道岔"
            elseif device_type == 0x21 then
                device_type_str = "信号机"
            elseif device_type == 0x52 then
                device_type_str = "ESB按钮"
            elseif device_type == 0x62 then
                device_type_str = "防淹门"
            elseif device_type == 0x63 then
                device_type_str = "SPKS状态灯"
            elseif device_type == 0x64 then
                device_type_str = "SPKS旁路按钮"
            end
            
            subtree:add_le(buffer(offset, 1), "站" .. i .. " 序号:" .. index .. " 设备类型: " .. 
                device_type .. " (" .. device_type_str .. ")")
            offset = offset + 1
            
            local shebeiid = buffer(offset, 4):le_uint()
            subtree:add_le(buffer(offset, 4), "站" .. i .. " 序号:" .. index .. " 设备编号: " .. shebeiid)
            offset = offset + 4
            
            local sema_len = buffer(offset, 1):le_uint()
            subtree:add_le(buffer(offset, 1), "站" .. i .. " 序号:" .. index .. " 色码长度: " .. sema_len)
            offset = offset + 1
            
            subtree:add_le(buffer(offset, sema_len), "站" .. i .. " 序号:" .. index .. " 色码: 0x" .. 
                to_hex_string(buffer(offset, sema_len)))
            
            offset = offset + sema_len
            local end1 = offset
            
            j = j + 6 + sema_len
            subtree:add_le(buffer(start1, end1 - start1), "站" .. i .. " 序号:" .. index .. 
                " 统计 -> 设备长度: " .. (end1 - start1) .. " 处理的长度: " .. j)
            index = index + 1
        end
    end
end

--- 供电臂信息解析
function power_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 8 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local powerCount = buffer(offset, 2):le_uint()
    subtree:add_le(power_count, buffer(offset, 2))
    offset = offset + 2
    
    for i = 1, powerCount do
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "供电臂序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(power_section_id, buffer(offset, 2))
        offset = offset + 2
        
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(power_section_status, buffer(offset, 1)):append_text(
            " (" .. (powerStatusStr[status] or "未知") .. ")")
        offset = offset + 1
    end
end

--- 首末班申请解析
function firstLastRequest_data(buffer, pinfo, payloadTree)
    local type = buffer(0, 2):le_uint()
    if type ~= 9 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    
    local offset = 2
    subtree:add_le(buffer(offset, 4), "首末班申请: 0x" .. to_hex_string(buffer(offset, 4)))
end

--- 场段出入段计划信息解析
function stationPlan_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 16 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    local start_1 = offset
    subtree:add_le(buffer(offset, 7), "调度日: " .. getTime(buffer(offset, 7)))
    offset = offset + 7
    
    local drawing_no_len = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "图号长度: " .. drawing_no_len)
    offset = offset + 1
    subtree:add_le(buffer(offset, drawing_no_len), "图号: " .. buffer(offset, drawing_no_len):string())
    offset = offset + drawing_no_len
    
    subtree:add_le(buffer(offset, 2), "段/场站码: " .. buffer(offset, 2):le_uint())
    offset = offset + 2
    
    local number = buffer(offset, 1):le_uint()
    subtree:add_le(buffer(offset, 1), "服务号组数: " .. buffer(offset, 1):le_uint())
    offset = offset + 1
    
    local end_1 = offset
    local len_1 = end_1 - start_1
    subtree:add_le(buffer(start_1, len_1), "统计 -> 段场计划信息头长度: " .. len_1)
    local len_3 = len_1
    
    for i = 1, number do
        local start_2 = offset
        local service_no_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 服务号长度: " .. service_no_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, service_no_len), "组:" .. i .. " 服务号: " .. 
            buffer(offset, service_no_len):string())
        offset = offset + service_no_len
        
        subtree:add_le(buffer(offset, 2), "组:" .. i .. " 出段/场站码: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        local out_train_label_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 出段/场车次号长度: " .. out_train_label_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, out_train_label_len), "组:" .. i .. " 出段/场车次号: " .. 
            buffer(offset, out_train_label_len):string())
        offset = offset + out_train_label_len
        
        local out_train_group_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 出段/场车组号长度: " .. out_train_group_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, out_train_group_len), "组:" .. i .. " 出段/场车组号: " .. 
            buffer(offset, out_train_group_len):string())
        offset = offset + out_train_group_len
        
        local departure_track_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 出发股道名称长度: " .. departure_track_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, departure_track_len), "组:" .. i .. " 出发股道名称: " .. 
            buffer(offset, departure_track_len):string())
        offset = offset + departure_track_len
        
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 计划出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 实际出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 报点标志: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        local transfer_rail_out_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 转换轨名称长度: " .. transfer_rail_out_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, transfer_rail_out_len), "组:" .. i .. " 出段转换轨名称: " .. 
            buffer(offset, transfer_rail_out_len):string())
        offset = offset + transfer_rail_out_len
        
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 转换轨计划到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 转换轨到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 转换轨计划出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 转换轨出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 转换轨报点标志: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 2), "组:" .. i .. " 出段正线站码: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 正线到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 4), "组:" .. i .. " 目的地码: " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        subtree:add_le(buffer(offset, 2), "组:" .. i .. " 入段车辆段站码: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        
        local in_train_label_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 入段车次号长度: " .. in_train_label_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, in_train_label_len), "组:" .. i .. " 入段车次号: " .. 
            buffer(offset, in_train_label_len):string())
        offset = offset + in_train_label_len
        
        local in_train_group_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 入段车组号长度: " .. in_train_group_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, in_train_group_len), "组:" .. i .. " 入段车组号: " .. 
            buffer(offset, in_train_group_len):string())
        offset = offset + in_train_group_len
        
        local arrival_track_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 到达股道名称长度: " .. arrival_track_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, arrival_track_len), "组:" .. i .. " 到达股道名称: " .. 
            buffer(offset, arrival_track_len):string())
        offset = offset + arrival_track_len
        
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 计划到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 实际到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 报点标志: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        
        local transfer_rail_in_len = buffer(offset, 1):le_uint()
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 入段转换轨长度: " .. transfer_rail_in_len)
        offset = offset + 1
        subtree:add_le(buffer(offset, transfer_rail_in_len), "组:" .. i .. " 入段转换轨名称: " .. 
            buffer(offset, transfer_rail_in_len):string())
        offset = offset + transfer_rail_in_len
        
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 入段转换轨计划到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 入段转换轨到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 入段转换轨计划出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 入段转换轨出发时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 入段转换轨报点标志: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 2), "组:" .. i .. " 入段正线站码: " .. buffer(offset, 2):le_uint())
        offset = offset + 2
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 入段正线到达时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 4), "组:" .. i .. " 入段目的地码: " .. buffer(offset, 4):le_uint())
        offset = offset + 4
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 是否初始化生成: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 初始化时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 是否回段洗车: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 2), "组:" .. i .. " 预留: 0x" .. to_hex_string(buffer(offset, 2)))
        offset = offset + 2
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 是否自动唤醒: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 计划唤醒时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 是否回库清扫: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 清扫开始时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 7), "组:" .. i .. " 清扫结束时间: " .. getTime(buffer(offset, 7)))
        offset = offset + 7
        subtree:add_le(buffer(offset, 1), "组:" .. i .. " 是否自动休眠: " .. buffer(offset, 1):le_uint())
        offset = offset + 1
        subtree:add_le(buffer(offset, 10), "组:" .. i .. " 预留: 0x" .. to_hex_string(buffer(offset, 10)))
        offset = offset + 10
        
        local end_2 = offset
        local len_2 = end_2 - start_2
        len_3 = len_3 + len_2
        subtree:add_le(buffer(start_2, len_2), "统计 -> 组:" .. i .. " 段场计划信息长度: " .. len_2)
    end
    
    subtree:add_le(buffer(start_1, len_3), "统计 -> 全部长度: " .. len_3)
end

--- 车站火灾信息解析
function fire_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 17 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    if offset + 2 > buffer:len() then
        subtree:add_expert_info(PI_MALFORMED, PI_WARN, "车站火灾数据长度不足")
        return
    end
    
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    
    for i = 1, fireCount do
        if offset + 3 > buffer:len() then
            subtree:add_expert_info(PI_MALFORMED, PI_WARN, "火灾分区" .. i .. "：数据长度不足，解析终止")
            break
        end
        
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "火灾分区序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(fire_section_id, buffer(offset, 2))
        offset = offset + 2
        
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(fire_section_status, buffer(offset, 1)):append_text(
            " (" .. (fireStatusStr[status] or "未知") .. ")")
        offset = offset + 1
    end
end

--- 区间火灾信息解析
function zonefire_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 18 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    if offset + 2 > buffer:len() then
        subtree:add_expert_info(PI_MALFORMED, PI_WARN, "区间火灾数据长度不足")
        return
    end
    
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    
    for i = 1, fireCount do
        if offset + 3 > buffer:len() then
            subtree:add_expert_info(PI_MALFORMED, PI_WARN, "区间火灾分区" .. i .. "：数据长度不足，解析终止")
            break
        end
        
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "区间火灾分区序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(zonefire_section_id, buffer(offset, 2))
        offset = offset + 2
        
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(zonefire_section_status, buffer(offset, 1)):append_text(
            " (" .. (fireStatusStr[status] or "未知") .. ")")
        offset = offset + 1
    end
end

--- 区间水灾信息解析
function zonewater_data(buffer, pinfo, payloadTree)
    local offset = 0
    local type = buffer(0, 2):le_uint()
    if type ~= 19 then return end
    
    local subtree = payloadTree:add_le(buffer(0, buffer:len()), 
        "业务数据: " .. dataTypeStr[type] .. " | 长度: " .. buffer:len())
    subtree:add_le(data_type, buffer(0, 2)):append_text(" (" .. dataTypeStr[type] .. ")")
    offset = offset + 2
    
    if offset + 2 > buffer:len() then
        subtree:add_expert_info(PI_MALFORMED, PI_WARN, "区间水灾数据长度不足")
        return
    end
    
    local fireCount = buffer(offset, 2):le_uint()
    subtree:add_le(fire_count, buffer(offset, 2))
    offset = offset + 2
    
    for i = 1, fireCount do
        if offset + 3 > buffer:len() then
            subtree:add_expert_info(PI_MALFORMED, PI_WARN, "区间水灾分区" .. i .. "：数据长度不足，解析终止")
            break
        end
        
        local oneplatLen = 3
        local oneplatTree = subtree:add_le(buffer(offset, oneplatLen),
            "区间水灾分区序号: " .. i .. " | 长度: " .. oneplatLen)
        
        oneplatTree:add_le(zonewater_section_id, buffer(offset, 2))
        offset = offset + 2
        
        local status = buffer(offset, 1):le_uint()
        oneplatTree:add_le(zonewater_section_status, buffer(offset, 1)):append_text(
            " (" .. (fireStatusStr[status] or "未知") .. ")")
        offset = offset + 1
    end
end

-- ========================================================================
-- 注册协议到指定端口
-- ========================================================================
local function register_rsic_ports()
    local tcp_dissector_table = DissectorTable.get("tcp.port")
    local ports = parse_ports(prefs.my_tcp_port)
    print("[RSIC] 正在注册端口: " .. prefs.my_tcp_port)
    for _, port in ipairs(ports) do
        tcp_dissector_table:add(port, rsic_protocol)
        print("[RSIC] 已注册端口: " .. port)
    end
end

-- 初始化注册端口
register_rsic_ports()

-- 监听首选项变化，动态更新端口
function rsic_protocol.prefs_changed()
    print("[RSIC] 首选项已更改，重新注册端口")
    register_rsic_ports()
end

print("[RSIC] 插件加载成功！版本: 1.0.0#20241107-1")