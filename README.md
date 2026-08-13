# Wireshark Lua 协议解析插件

基于 Wireshark Lua 的轨道交通信号系统接口协议解析插件库，涵盖多条线路的 ATS-ISCS/TCMS-PIS 接口协议。

## 协议插件列表

| 协议 | 线路/系统 | 版本 | 文件 | 说明 |
|------|-----------|------|------|------|
| CQL15 | 重庆15号线 SIG-ISCS | v2.1.0 | [cql15_protocol.lua](cql15_protocol.lua) | 重庆15号线信号系统与综合监控系统接口协议 |
| DGL1 | 东莞1号线 ATS-ISCS | v1.0.3 | [dgl1_protocol.lua](dgl1_protocol.lua) | 东莞1号线信号系统与综合监控系统接口协议 |
| JNL7 | 济南7号线 SIG-ISCS | v1.0.0 | [jnl7_protocol.lua](jnl7_protocol.lua) | 济南7号线信号系统与综合监控系统接口协议 |
| FSL2-TCMS | 佛山2号线 ISCS-PIS | v1.0.0 | [fsl2_tcms_protocol.lua](fsl2_tcms_protocol.lua) | 佛山2号线综合监控与乘客信息系统的TCMS数据透传协议 |
| GZL1822/1012 | 广州18&22/10号线 ATS-ISCS | v1.0.0 | [gzl1822_1012_ats_protocol.lua](gzl1822_1012_ats_protocol.lua) | 广州18&22/10号线信号系统与综合监控系统接口协议 |
| RSIC | — | — | [rsic_protocol.lua](rsic_protocol.lua) | RSIC协议解析插件 |

## 安装

1. 将对应的 `.lua` 文件复制到 Wireshark 插件目录：
   - Windows: `%APPDATA%\Wireshark\plugins\`
   - macOS: `~/Library/Application Support/Wireshark/plugins/`
   - Linux: `~/.wireshark/plugins/`

2. 重启 Wireshark

3. 在过滤栏使用 `tcp.port == <端口>` 或协议名称过滤

## 测试文件

测试文件位于 [test/](test/) 目录：

| 文件 | 说明 |
|------|------|
| `test/cql15_ats.md` | CQL15协议规范文档 |
| `test/dgl1_all.pcap` | 东莞1号线抓包测试文件 |
| `test/dgl1_ats.md` | DGL1协议规范文档 |
| `test/fsl2_tcms.md` | FSL2 TCMS协议规范文档 |
| `test/fsl2_test.pcap` | FSL2协议抓包测试文件 |
| `test/gen_dgl1_all.py` | 东莞1号线测试数据生成脚本 |
| `test/gen_fsl2_test.py` | FSL2测试数据生成脚本 |
| `test/gen_gzl_all.py` | 广州18/22/10号线测试数据生成脚本 |
| `test/gen_jnl7_all.py` | 济南7号线测试数据生成脚本 |
| `test/gzl10_ats.md` | GZL10协议规范文档 |
| `test/gzl18_ats.md` | GZL18/22协议规范文档 |
| `test/gzl_all.pcap` | 广州18&22/10号线抓包测试文件 |
| `test/jnl7_all.pcap` | 济南7号线抓包测试文件 |
| `test/jnl7_ats.md` | JNL7协议规范文档 |

## 版本说明

各协议的详细版本说明和功能清单请查看对应的 `_VERSION.md` 文件：

- [CQL15 版本说明](cql15_protocol_VERSION.md)
- [DGL1 版本说明](dgl1_protocol_VERSION.md)
- [JNL7 版本说明](jnl7_protocol_VERSION.md)
- [FSL2-TCMS 版本说明](fsl2_tcms_protocol_VERSION.md)
- [GZL1822/1012 版本说明](gzl1822_1012_ats_protocol_VERSION.md)

## Wireshark Lua 开发教程

- [Wireshark Lua 插件开发教程](WIRESHARK_LUA_TUTORIAL.md) — 从入门到实战的完整开发指南，涵盖协议定义、字段注册、枚举解读、分包重组等内容

## 功能特性

- 解析轨道交通信号系统应用层二进制报文
- 结构化字段树展示，支持按字段过滤
- 枚举值中文解读
- CRC/校验和校验
- 支持 TCP desegment 分包重组
- 支持跨帧消息重组

## 仓库结构

```
├── cql15_protocol.lua           # CQL15协议解析
├── cql15_protocol_VERSION.md    # CQL15版本说明
├── dgl1_protocol.lua            # DGL1协议解析
├── dgl1_protocol_VERSION.md     # DGL1版本说明
├── fsl2_tcms_protocol.lua       # FSL2 TCMS协议解析
├── fsl2_tcms_protocol_VERSION.md # FSL2版本说明
├── gzl1822_1012_ats_protocol.lua # GZL1822/1012协议解析
├── gzl1822_1012_ats_protocol_VERSION.md # GZL版本说明
├── jnl7_protocol.lua            # JNL7协议解析
├── jnl7_protocol_VERSION.md     # JNL7版本说明
├── rsic_protocol.lua            # RSIC协议解析
├── rsic_protocol.zip            # RSIC协议压缩包
└── test/                        # 测试文件和规范文档
    ├── *.md                     # 各协议规范文档
    ├── *.pcap                   # 抓包测试文件
    └── gen_*.py                 # 测试数据生成脚本
```

## 贡献

欢迎提交 Issue 和 Pull Request。

## 许可

MIT License
