# CPUFreq：Unraid CPU 频率监控插件

为 Unraid 原生 Dashboard CPU 磁贴补充逻辑处理器实时频率信息。

插件不创建独立页面，也不创建独立 Dashboard 磁贴。

> 当前验证目标：Unraid 7.3.2、Linux `6.18.38-Unraid`。

## 功能

- 在原生 CPU 磁贴详情中，紧接 `CPU N` 后显示当前频率，并与占用率保持同一行。
- 在 `Overall Load` 总计标签后显示本次采样的平均频率，并与总计占用率保持同一行。
- 使用 5 秒轮询间隔，与 Unraid CPU 占用率轮询频率保持一致。
- 浏览器页面进入后台或离开 Dashboard 后暂停请求，返回时自动恢复。
- 优先读取 `/proc/cpuinfo`，缺少读数时再使用 sysfs 补充：
  `/sys/devices/system/cpu/*/cpufreq/scaling_cur_freq`。
- 单个逻辑处理器读取失败时显示 `N/A`，不参与平均值计算。
- 保留 API 的 `core` 字段作为兼容别名，新代码使用 `cpu` 字段。

## 支持范围

| 类型 | 范围 | 说明 |
| --- | --- | --- |
| 验证目标 | Unraid 7.3.2 + Linux `6.18.38-Unraid` | 已按该版本的 WebGUI 和内核接口适配 |
| 兼容支持 | Unraid 7.3.0 及以上 + Linux `6.18.x` | 保留 Dashboard 集成脚本加载支持，未逐版本验证 |
| 不支持注入 | 其他内核系列 | 不向 Dashboard 注入内容，但保留数据接口文件 |

## 快速安装

### 通过 WebGUI 安装

1. 登录 Unraid WebGUI。
2. 打开 `Plugins`，点击 `Install Plugin`。
3. 输入插件地址：

   ```text
   https://raw.githubusercontent.com/shxtmaker/unraid-cpufreq/main/archive/cpufreq.plg
   ```

4. 点击 `Install`，确认插件来源并等待安装完成。
5. 返回 `Dashboard`，刷新页面并展开原生 CPU 磁贴详情。

### 通过命令行安装

通过 SSH 或 Unraid 本地终端执行：

```bash
plugin install https://raw.githubusercontent.com/shxtmaker/unraid-cpufreq/main/archive/cpufreq.plg
```

## 从源码构建

### Linux / Unraid

```bash
chmod +x build.sh
./build.sh
```

### Windows PowerShell

```powershell
.\build.ps1
```

构建产物为：

```text
archive/cpufreq.plg
```

## 安装本地构建产物

将本地构建产物 `archive/cpufreq.plg` 复制到 Unraid 的
`/boot/config/plugins/`，然后执行：

```bash
plugin install /boot/config/plugins/cpufreq.plg
```

安装脚本会写入插件文件，并清理旧版本遗留的独立页面、独立磁贴和临时状态文件。

## 安装后验证

安装完成后，在 Dashboard 中检查：

- `Plugins` 列表中出现 `CPUFreq`。
- 页面中没有独立 CPUFreq 页面或独立 CPUFreq 磁贴。
- 展开原生 CPU 磁贴详情后，每个 `CPU N` 行显示当前频率。
- `Overall Load` 总计行显示 `Average Frequency`。
- 某个频率无法读取时，该行显示 `N/A`。

如果没有显示频率：

1. 对 Dashboard 执行浏览器强制刷新。
2. 确认主机运行的是 Linux `6.18.x` 内核。
3. 检查插件文件是否存在：

   ```bash
   ls -l /usr/local/emhttp/plugins/cpufreq/
   ```

## 更新

重复执行安装步骤即可更新插件。安装脚本会覆盖当前版本并清理旧版本文件。

更新完成后刷新 Dashboard，并按照“安装后验证”检查 CPU 磁贴内容。

## 卸载

### 通过 WebGUI 卸载

1. 打开 Unraid WebGUI 的 `Plugins` 页面。
2. 找到 `CPUFreq`。
3. 点击 `Remove` 或 `Uninstall`。

### 通过命令行卸载

```bash
plugin remove cpufreq.plg
```

卸载不会修改 Unraid 系统文件，会移除插件目录、Dashboard 集成脚本和插件配置目录。

## 项目结构

```text
unraid-cpufreq/
├── README.md
├── LICENSE
├── build.sh
├── build.ps1
├── verify.ps1
├── archive/
│   └── cpufreq.plg
├── CONTEXT.md
├── docs/adr/
│   └── 0001-inject-frequency-into-native-cpu-tile.md
└── source/
    ├── cpufreq.plg
    └── plugins/cpufreq/
        ├── cpufreq.php
        └── cpufreqdash.page
```

## 数据接口

完整接口：

```text
GET /plugins/cpufreq/cpufreq.php
```

Dashboard 使用紧凑接口：

```text
GET /plugins/cpufreq/cpufreq.php?compact=1
```

紧凑接口只返回 `avg_mhz` 和 `cores`，减少周期请求中的文件读取和响应体积。完整接口保持兼容。

完整接口返回示例：

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
    {"cpu": 0, "core": 0, "mhz": 3712.45},
    {"cpu": 1, "core": 1, "mhz": 3698.12}
  ]
}
```

## 作者

[shxtmaker](https://github.com/shxtmaker)

## 许可证

[MIT](LICENSE)
