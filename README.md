# CPUFreq - UNRAID CPU 频率监控插件

实时显示 CPU 各核心运行频率的 UNRAID 插件。

## 功能特性

- **仪表盘集成**：在 Dashboard 的 CPU 区域显示全核平均频率、最低/最高频率，每 3 秒自动刷新
- **独立详情页面**：顶部导航栏 `CPU Frequency` 独立标签页，展示每个核心的实时频率
  - 每核心频率卡片 + 负载进度条
  - 平均频率趋势图（最近 60 次采样）
  - 基准频率参考线
  - 可调刷新间隔（1s / 2s / 5s / 10s），支持暂停
- **数据来源**：优先读取 `/proc/cpuinfo`，自动回退到 `/sys/devices/system/cpu/*/cpufreq/` 接口

## 系统要求

- UNRAID OS 6.9.0 或更高版本
- 仪表盘组件需要 UNRAID 6.10+（旧版本仅独立页面可用）

## 构建插件

### Windows (PowerShell)

```powershell
cd cpufreq
.\build.ps1
```

### Linux / UNRAID (Bash)

```bash
cd cpufreq
chmod +x build.sh
./build.sh
```

构建完成后，最终插件文件位于 `archive/cpufreq.plg`。

## 安装方法

### 方法一：通过 Web 界面安装

1. 将 `archive/cpufreq.plg` 复制到 U 盘的 `/boot/config/plugins/` 目录
2. 重启 UNRAID（或在终端执行 `plugin install /boot/config/plugins/cpufreq.plg`）
3. 在 `Plugins` 标签页确认插件已安装

### 方法二：通过 URL 安装（推荐）

在 UNRAID Web 界面 `Plugins -> Install Plugin` 输入：

```
https://raw.githubusercontent.com/shxtmaker/unraid-cpufreq/main/archive/cpufreq.plg
```

安装后可通过 `Plugins -> Check for Updates` 在线更新。

### 方法三：命令行安装

```bash
# 将 plg 文件上传到服务器后（新版 UNRAID 已移除 installplg，统一使用 plugin 命令）
plugin install /path/to/cpufreq.plg

# 卸载
plugin remove cpufreq.plg
```

## 使用方法

1. **仪表盘**：打开 Dashboard 页面，CPU 区域下方会显示 "CPU Frequency" 平均频率信息
2. **详情页面**：点击顶部导航栏 `CPU Frequency` 标签，或直接访问 `http://<服务器IP>/CPUFreq`
3. 点击仪表盘组件中的 "Per-Core Detail" 链接可快速跳转到详情页

## 卸载

在 `Plugins` 标签页找到 CPU Frequency 插件，点击 Remove 即可。

## 项目结构

```
unraid-cpufreq/
├── README.md                         # 本文档
├── LICENSE                           # MIT 许可证
├── build.sh                          # Linux 构建脚本
├── build.ps1                         # Windows 构建脚本
├── verify.ps1                        # 构建产物格式校验脚本
├── archive/
│   └── cpufreq.plg                   # 构建产物（最终安装包，URL 安装指向此文件）
└── source/
    ├── cpufreq.plg                   # PLG 模板（含占位符）
    └── plugins/cpufreq/
        ├── CPUFreq.page              # 独立页面（顶部导航栏，单核频率详情 /CPUFreq）
        ├── cpufreq.php               # AJAX 数据接口（JSON）
        └── cpufreqdash.page          # 仪表盘磁贴（平均频率，UNRAID 6.12+）
```

## 技术说明

- 频率数据通过 PHP 读取 `/proc/cpuinfo` 中的 `cpu MHz` 字段获取
- 若系统启用了 cpufreq 驱动，会额外读取调速器（governor）和最大睿频信息
- 前端使用原生 Canvas 绘制趋势图，无外部依赖
- AJAX 接口返回 JSON 格式数据，可供第三方集成调用：`GET /plugins/cpufreq/cpufreq.php`

## API 响应示例

```json
{
  "timestamp": 1753948800,
  "model": "AMD Ryzen 5 5600G with Radeon Graphics",
  "core_count": 12,
  "avg_mhz": 3712.45,
  "min_mhz": 2871.33,
  "max_mhz": 4200.12,
  "base_mhz": 3900,
  "boost_mhz": 4400,
  "governor": "performance",
  "cores": [
    {"core": 0, "mhz": 3712.45},
    {"core": 1, "mhz": 3698.12}
  ]
}
```

## License

[MIT](LICENSE)
