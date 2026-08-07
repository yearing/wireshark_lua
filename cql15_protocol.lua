-- 插件名: CQL15 Protocol
-- 版本: 1.0.0#20241107-1
-- 作者: 叶孟鹏
-- 描述: 广州18号线和11号线的 sig协议， RSIC 端口10090，10020，10030
-- 更新时间: 2024-11-07
cq15_protocol = Proto("CQL15", "CQL15 Protocol")
-- 首选项
local prefs = cq15_protocol.prefs
prefs.my_version = Pref.statictext("version:1.0.0#20250507-1",
                                   "1.0.0#20250507-1")
prefs.my_tcp_port = Pref.string("端口号(s):", "5000",
                                "CQL15默认端口")


data_type = ProtoField.string("cql15.data_type", "3.信息类型(data_type)", base.ASCII)

cq15_protocol.fields = {
    data_type, 
}
local dataTypeStr = {
    [0] = "unknown,未知类型",
    
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
    if buf_len < 31 then return -1 end

    while b_offset < buf_len do
        -- ADD 1
        -- total_len = 解析头部获取当前头部指定的应用层payload长度
        -- tcp的负载长度小于应用层头部指定的应用层数据，即应用层数据分包
        local info_data_len = buffer(b_offset + 5, 5):string()
        local info_data_len_i = tonumber(info_data_len) or 0
        total_len = 10 + info_data_len_i
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

        pinfo.cols.protocol = cq15_protocol.name

        local subtree = tree:add(cq15_protocol, buffer(b_offset, total_len),
                                 "CQL15 Protocol Data, Len: " .. total_len)

        local headerTree = subtree:add(buffer(b_offset + 0, 29), "HEAD")
        headerTree:add(buffer(b_offset + 0, 1), "1.信息头标识:"..buffer(b_offset + 0, 1):le_uint())
        headerTree:add(buffer(b_offset + 1, 2), "2.信息序号:"..buffer(b_offset + 1, 2):string())
        headerTree:add(data_type, buffer(b_offset + 3, 2))
        headerTree:add(buffer(b_offset + 5, 5), "4.信息长度:"..buffer(b_offset + 5, 5):string())
        
        headerTree:add(buffer(b_offset + 10, 19), "5.数据发送时间:"..buffer(b_offset + 10, 10):string() .." "..buffer(b_offset + 21, 8):string())
        local tailTree =
            subtree:add(buffer(b_offset + total_len - 2, 2), "CRC校验:"..buffer(b_offset + total_len - 2, 2):string())
            
        plan_data(buffer,pinfo,tree)
        
        b_offset = b_offset + total_len

        if b_offset > buffer:len() then
            return -1
        elseif b_offset == buffer:len() then
            return 1
        end
        -- return 1
    end
end

-- 站台信息
function plan_data(buffer, pinfo, payloadTree)
    local type = buffer(3, 2):string()
    if type ~= "02" then return end
    local subtree = payloadTree:add_le(buffer(29, buffer:len()-29-2), "Data:站台信息: "..type .. " ,len:" ..(buffer:len()-29-2))
    subtree:add_le(buffer(29,4), "6.车站编号:"..buffer(29,4):string())
    subtree:add_le(buffer(33,1), "7.站台号:"..buffer(33,1):string())
    subtree:add_le(buffer(34,1), "8.站台紧停标志:"..buffer(34,1):string())
    subtree:add_le(buffer(35,2), "9.列车数量:"..buffer(35,2):string())
    local num =  tonumber(buffer(35,2):string()) or 0
    local offset=37
    for i = 1, num do
       local offset= offset + (i-1)*80
        subtree:add_le(buffer(offset, 80),  "车:".. i .." ,数据长度:80")
        subtree:add_le(buffer(offset, 5),  "车:".. i .." ,列车车组号:"..buffer(offset, 5):string())
        subtree:add_le(buffer(offset+5,1),  "车:".. i .." ,列车编组信息:"..buffer(offset+5,1):string())
        subtree:add_le(buffer(offset+6,3),  "车:".. i .." ,列车表号:"..buffer(offset+6,3):string())
        subtree:add_le(buffer(offset+9,8),  "车:".. i .." ,列车车次号:"..buffer(offset+9,8):string())
        subtree:add_le(buffer(offset+17,1),  "车:".. i .." ,首班列车:"..buffer(offset+17,1):string())
        subtree:add_le(buffer(offset+18,1),  "车:".. i .." ,末班列车:"..buffer(offset+18,1):string())
        subtree:add_le(buffer(offset+19,1),  "车:".. i .." ,列车站台状态:"..buffer(offset+19,1):string())
        subtree:add_le(buffer(offset+20,19),  "车:".. i .." ,到站时间:"..buffer(offset+20,10):string().." "..buffer(offset+31,8):string())
        subtree:add_le(buffer(offset+39,19),  "车:".. i .." ,离站时间:"..buffer(offset+39,10):string().." "..buffer(offset+50,8):string())
        subtree:add_le(buffer(offset+58,4),  "车:".. i .." ,终点站编号:"..buffer(offset+58,4):string())
        subtree:add_le(buffer(offset+62,1),  "车:".. i .." ,列车运行于:"..buffer(offset+62,1):string())
        subtree:add_le(buffer(offset+63,5),  "车:".. i .." ,目的地码:"..buffer(offset+63,5):string())
        subtree:add_le(buffer(offset+68,1),  "车:".. i .." ,列车方向:"..buffer(offset+68,1):string())
        subtree:add_le(buffer(offset+69,1),  "车:".. i .." ,非载客列车:"..buffer(offset+69,1):string())
        subtree:add_le(buffer(offset+70,1),  "车:".. i .." ,列车接近:"..buffer(offset+70,1):string())
        subtree:add_le(buffer(offset+71,4),  "车:".. i .." ,下一停站车站编号:"..buffer(offset+71,4):string())
        subtree:add_le(buffer(offset+75,1),  "车:".. i .." ,轧道列车:"..buffer(offset+75,1):string())
        subtree:add_le(buffer(offset+76,1),  "车:".. i .." ,快慢车标识:"..buffer(offset+76,1):string())
        subtree:add_le(buffer(offset+77,1),  "车:".. i .." ,列车扣车标志:"..buffer(offset+77,1):string())
        subtree:add_le(buffer(offset+78,1),  "车:".. i .." ,列车跳停标志:"..buffer(offset+78,1):string())
        subtree:add_le(buffer(offset+79,1),  "车:".. i .." ,列车清客标志:"..buffer(offset+79,1):string())
    end
end

function cq15_protocol.dissector(buffer, pinfo, tree)
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
    if cq15_protocol.prefs.my_tcp_port ~= "" then
        local ports = parse_ports(cq15_protocol.prefs.my_tcp_port)
        for _, port in ipairs(ports) do tcp_port:add(port, cq15_protocol) end
    end
end

add_port()
function cq15_protocol.prefs_changed() add_port() end
