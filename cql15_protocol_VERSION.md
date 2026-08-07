# CQL15 Protocol 插件版本说明

## 版本 2.1.0 (2026-08-07)

### 概述

重庆15号线 SIG-ISCS 接口 Wireshark Lua 解析插件，依据《CQS15A_SIG_TEC_ATS_024》V1.3 实现网络全局调度系统（SIG）与综合监控系统（ISCS）之间全部消息类型的解析。

本插件将 SIG-ISCS 接口的二进制应用层报文解析为结构化的字段树，支持按字段过滤、枚举中文解读、CRC 校验与分包重组。

---

## 一、实现的功能

### 1. 消息类型解析（14 种）

| 类型 | 方向 | 消息 | 解析内容 |
|------|------|------|----------|
| 01 | SIG→ISCS | 列车运行信息及阻塞信息 | 每列车 50 字节：车组号/司机号/CBTC状态/位置/运行方向/车站/轨道/阻塞/方向/线段ID/偏移量/EB/驾驶模式/湿轨模式 |
| 02 | SIG→ISCS | 站台信息 | 车站/站台号/紧停/列车数 + 每列车 80 字节：车组/编组/表号/车次/首末班/站台状态/到离站时间/终点/目的地码/方向/载客/接近/下一站/轧道/快慢/扣车/跳停/清客 |
| 03 | SIG→ISCS | SPKS 设备状态信息 | 车站/设备数量 + 每设备 13 字节：信号类型/设备名称/设备状态（bit1旁路/bit2激活） |
| 06 | SIG→ISCS | 当天使用的时刻表 | 总包数/当前包/表号/行程数 + 每行程：车次/目的地码/站台数量 + 每站台：车站/站台号/到离站时间 |
| 07 | ISCS→SIG | SCADA 供电区段 | 区段数量 + 各区段状态（0未知/1已供电/2未供电） |
| 08 | 双向 | 回执信息 | 头部 + CRC（无数据域，固定 31 字节） |
| 09 | 双向 | 心跳信息 | 头部 + CRC（无数据域，固定 31 字节） |
| 15 | ISCS→SIG | 客流信息 | 客流个数 + 每客流 8 字节 |
| 16 | ISCS→SIG | 请求当天时刻表 | 请求类型 |
| 18 | SIG→ISCS | 列车联动信息 | 每列车：车组/EB/休眠/唤醒 + 每车辆设备状态 1 字节 |
| 19 | SIG→ISCS | 段场出入库信息 | 车组/位置/当前轨道/库线股道/出入库状态 |
| 19 | ISCS→SIG | FAS 火灾信息 | FAS 数量 + 各 FAS 状态（1激活/2未激活） |
| 21 | ISCS→SIG | 区间超水位信息 | 区间数量 + 各区间状态 |
| 33 | ISCS→SIG | 过分相是否启用 | 分相区数量 + 各分相区状态 |
| 37 | ISCS→SIG | 区间瓦斯检测预警 | 瓦斯数量 + 各区间状态 |

### 2. 类型 19 方向自动区分

`信息类型` 19 在规格书中既是「段场出入库」（SIG 发起）又是「FAS 火灾信息」（ISCS 发起）。插件按 **TCP 端口方向** 自动区分：

- 报文的源端口是注册端口 → SIG 发起 → 解析为 **段场出入库**
- 报文的目的端口是注册端口 → ISCS 发起 → 解析为 **FAS 火灾信息**

Info 列同时标注方向 `[SIG→ISCS]` / `[ISCS→SIG]`。

### 3. CRC 校验

- 依据附录1累加和算法：对报文所有字节求和取低字节，以两位大写十六进制 ASCII 表示
- 每包末尾显示 `CRC校验[crc]:XX [OK]` 或 `[FAIL(calc=YY)]`
- CRC 定位以**结构解析结果**为准（而非长度域），避免无数据域消息长度域不可靠导致定位错

### 4. TCP 分包重组（desegment）

- 单条消息跨多个 TCP 段时自动重组
- 单 TCP 段含多条消息时逐一解析
- 同段多包时循环内先校验长度域完整性，避免越界

### 5. 数据健壮性

- 长度域合理性校验（21~32767），非法数据交回 data dissector
- 结构长度与长度域不一致时给出 ⚠ 告警
- 头部长度不足时等待重组而非崩溃

---

## 二、使用方法

### 1. 安装

- 文件 `cql15_protocol.lua` 存放于 Wireshark 个人插件目录（Windows）：
  `%APPDATA%\Wireshark\plugins\`
- 启动 Wireshark 自动加载；运行中修改后按 **Ctrl+Shift+L** 重载 Lua 插件

### 2. 端口配置

- 默认监听端口：`5000`
- 通过 **Analyze → Reload Lua Plugins** 后，在 **解析（Analyze）→ 协议首选项（Protocols）→ CQL15 Protocol** 中修改
- 支持多端口，用空格分隔，如 `5000 10020 10030`
- 修改后自动重新绑定端口

### 3. 报文显示

协议树字段格式：

```
CQL15 Protocol Data, Len: 56
    HEAD
        1.信息头标识(1bytes),字节序(0):0x01
        2.信息序号[seq](2bytes),字节序(1):03
        3.信息类型[data_type](2bytes),字节序(3): 19
        4.信息长度[data_len](5bytes),字节序(5):00046
        5.数据发送时间[send_time](19bytes),字节序(10):2009-21-05 09:10:34
    Data:段场出入库信息 ,type:19 ,len:27
        6.列车位置[train_pos](1bytes),字节序(34):2 | 车辆段
        ...
    CRC校验[crc](2bytes),字节序(54):... [OK]
```

- 每个字段标注：编号、名称、字节长度 `(Nbytes)`、字节序 `(X)`、过滤器名 `[field]`、值
- 枚举字段自动追加 ` | 中文`，如 `2 | 车辆段`、`1 | 出库`、`0 | 未激活`
- 循环体（多列车/多设备/多行程）的字节序自动累加

### 4. 显示过滤器

全部字段已注册 `cql15.*` 过滤器，常用示例：

| 过滤器 | 含义 |
|--------|------|
| `cql15` | 所有 CQL15 报文 |
| `cql15.data_type == "02"` | 站台信息 |
| `cql15.data_type == "19"` | 段场出入库 / FAS（按方向区分） |
| `cql15.train_num == "15271001"` | 指定列车车次号 |
| `cql15.station_no == "1502"` | 指定车站编号（跨类型生效） |
| `cql15.train_set == "15001"` | 指定列车车组号 |
| `cql15.dev_state == 0x0001` | SPKS 设备状态（hex） |
| `cql15.eb_state == "1"` | EB 激活 |
| `cql15.drive_mode == "4"` | AM 模式 |

### 5. Info 列

- 显示 `CQL15 [方向] 消息名 seq=序号`，如 `CQL15 [SIG→ISCS] 段场出入库信息 seq=03`

### 6. 常见问题

- **Trailing stray characters**：已通过 `send_time` 改 FT_BYTES 消除（时间域含 NUL 分隔符，FT_STRING 会截断触发告警）
- **未识别协议**：确认端口已配置；若报文非本协议，插件自动交回 data

---

## 三、变更记录

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 2.1.0 | 2026-08-07 | 类型19按方向区分段场出入库/FAS；全部字段可过滤并标注过滤器名；31个枚举字段追加中文描述；send_time 改 FT_BYTES 消除 stray；CRC 定位改用结构解析结果；08/09 无数据域固定31字节 |
| 2.0.0 | 2026-08-07 | 依据 V1.3 实现全部消息类型；类型01新增湿轨模式(49→50字节)；全部字段带 Nbytes/字节序 标注；修复同段多包越界 |

---

## 四、环境

- Wireshark 4.6.7（内置 Lua 5.4）
- 文件名：`cql15_protocol.lua`
- 依赖：仅 Wireshark 内置 Lua 引擎，无第三方库

---

## 五、附录：Wireshark Lua 插件开发指南

### 5.1 插件目录

Wireshark 4.x 有 4 类 Lua 插件目录（`tshark -G folders` 可查询实际路径）：

| 类型 | 路径（Windows） | 生效范围 |
|------|----------------|----------|
| 个人 Lua 插件 | `%APPDATA%\Wireshark\plugins\` | 仅当前用户，所有版本加载 |
| 全局 Lua 插件 | `C:\Program Files\Wireshark\plugins\` | 所有用户，所有版本加载 |
| 个人版本目录 | `%APPDATA%\Wireshark\plugins\4.6\` | 仅 Wireshark 4.6 加载，版本隔离 |
| 全局版本目录 | `C:\Program Files\Wireshark\plugins\4.6\` | 所有用户 + 版本隔离 |

- 根 `plugins\` 目录的 `.lua` 被所有版本加载；带版本号的子目录（如 `4.6\`）仅对应版本加载，升级大版本时不会加载旧目录，避免兼容性问题
- 文件后缀必须为 `.lua`

### 5.2 加载与重载

| 方式 | 场景 |
|------|------|
| 启动 Wireshark | 自动加载插件目录中的所有 `.lua` |
| Ctrl+Shift+L | 运行中修改代码后重载（开发时最常用） |
| 命令行 `-X lua_script:xx.lua` | 临时加载指定脚本，不放进插件目录（Windows 路径用正斜杠，如 `-X lua_script:C:/plugins/xx.lua`） |

### 5.3 调试方法（无需打开 Wireshark）

tshark 与 Wireshark 共用同一 Lua 引擎和插件目录，脚本语法错误会在启动时打印。以下命令均在本机 Wireshark 4.6.7 实测通过：

```bash
# 查询插件目录（输出 Personal/Global Lua Plugins 等 8 类路径）
tshark -G folders

# 语法/加载检查：能列出字段即加载成功（本插件输出 68 行 cql15.*）
tshark -G fields -q 2>&1 | grep "^F.*cql15\."

# 抓包文件实测解析（-V 输出字段树，-Y 过滤）
tshark -r test.pcap -V -Y cql15

# 查看 expert info（告警/错误）。注意：无 expert 告警时输出为空，属正常
tshark -r test.pcap -q -z expert
```

命令行临时加载脚本（不放进插件目录）：

```bash
# 正常加载：能列出字段即成功（-X 后紧跟脚本路径）
tshark -G fields -q -X lua_script:C:/path/to/xx.lua
# 脚本不存在时会明确报错：The file "...lua" doesn't exist.
```

脚本内可用 `print()` 输出到标准错误，或用 `error("msg")` 主动报错定位。

### 5.4 常用 Lua API

| API | 作用 | 本插件用法 |
|-----|------|-----------|
| `Proto("name","desc")` | 定义协议解析器 | `cq15_protocol = Proto(...)` |
| `ProtoField.string/uint8/uint16/bytes` | 定义可过滤字段 | `sf()`、`ProtoField.bytes("send_time")` |
| `proto.fields = {...}` | 注册字段到协议 | 68 个 `cql15.*` 字段 |
| `proto.dissector(buffer,pinfo,tree)` | 解析入口 | 拆包 → 逐条解析 |
| `proto.prefs` / `Pref.string` | 用户可配置首选项 | `my_tcp_port` |
| `DissectorTable.get("tcp.port"):add(port,proto)` | 按端口绑定解析器 | 5000 端口 |
| `buffer(off,len):string()/uint()/raw()` | 读取 TvbRange 值 | 读取字段值 |
| `pinfo.desegment_offset/len` | TCP 分包重组 | 处理跨段消息 |
| `tree:add(field, range)` | 在树中添加字段 | 显示字段树 |
| `set_text()` | 改显示文本但不影响过滤值 | 加 `[filter]`/中文枚举 |
| `pinfo.cols.info/protocol` | 设置 Info/Protocol 列 | 方向标注 |

### 5.5 常见坑

1. **FT_STRING 遇内嵌 `0x00` 截断** → 触发 `Trailing stray characters`。含 NUL 的字段用 `ProtoField.bytes`（本插件已修复）
2. **字段过滤名 = ProtoField 的名字参数**，非标签文本；同名过滤器跨协议冲突，用 `cql15.*` 前缀避免
3. **desegment 需同时设置 `desegment_offset` 和 `desegment_len`**，缺一不可
4. **prefs_changed() 回调**：用户改首选项时重新绑定，否则旧端口残留
5. **长度域不可靠时别依赖它定位**，以结构解析结果为准（08/09 的教训）
6. **Lua 全局变量泄漏**：用 `local` 声明，避免重载后污染
7. **Lua 版本**：Wireshark 4.2+ 内置 Lua 5.4，按 5.4 语法编写
