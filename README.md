# 天国：拯救 2 — 无限负重 MOD

将 `BaseInventoryCapacity` 和 `MaxBaseInventoryCapacity` 都设为 **999999**，目标是让主角日常囤积物品时不会超重。它是极高的有限上限，并非数学意义上的无限；未移除游戏的超重判断。

## 安装（Windows / Steam）

1. 退出游戏。在 Steam 游戏库右键《天国：拯救 2》→ 管理 → 浏览本地文件。
2. 在游戏根目录找到或新建 `Mods` 文件夹。
3. 解压 `dist/UnlimitedWeight-1.0.1.zip`，把其中的 `UnlimitedWeight` 文件夹复制到 `Mods`。
4. 确认路径为 `Mods/UnlimitedWeight/mod.manifest` 和 `Mods/UnlimitedWeight/Data/unlimitedweight.pak`，避免多套一层目录。
5. 若已有 `Mods/mod_order.txt`，将 manifest 中的 modid `unlimitedweight` 单独加到一行，并保留其他条目。没有此文件时，先使用自动加载。根据 [官方目录规则](https://warhorse.youtrack.cloud/articles/KM-A-3)，这里填写 modid，而非文件夹名。
6. 启动游戏，加载存档，查看背包容量，再拿取超过原负重上限的物品，检查是否仍能正常移动和冲刺。

建议先用备份存档验证。不要同时启用其他修改 `BaseInventoryCapacity` 的 MOD；最终效果需要实测。

## 卸载

退出游戏，删除自己安装的 `Mods/UnlimitedWeight` 文件夹；若手动加过加载顺序条目，也删除该条目。卸载前将多余物品存入箱子，避免恢复正常容量后超重。

## 开发与打包

源码位于 `src/UnlimitedWeight`。从项目目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

脚本先使用 .NET ZIP API，再调用 `store_archives.py` 转换为真正的 ZIP_STORED（压缩方法 0），生成 `.pak` 和安装 ZIP；检查内部路径、XML、两项参数、压缩方法和 CRC。需要 Python 3，支持通过 `-PythonPath` 指定解释器，也可使用本机 Codex 捆绑的 Python。仅使用 Python 标准库。

补丁内部路径：`Libs/Tables/rpg/rpg_param__unlimitedweight.xml`。只包含两项容量参数，不复制整张游戏参数表。

### 1.0.1 修正与失效排查

1.0.0 遗漏 `MaxBaseInventoryCapacity`。[官方参数文档](https://warhorse.youtrack.cloud/articles/KM-A-20)将其描述为不计 archetype 倍率的背包基础容量上限，文档默认值为 600。1.0.1 将它与基础容量一起提高。该遗漏是可能导致容量仍受限的原因，尚待游戏内复测。

2026-10-02 检查本机游戏日志 `kcd.log`：版本为 `1.5.6-15693-release_1_5`，1.0.0 的 PAK 已打开，且日志报告参数表修改 1 行；因此该次失效不是安装目录未被识别。1.0.0 的 .NET `NoCompression` 实际产生 ZIP 方法 8，1.0.1 规范为官方要求的无压缩方法 0；日志证明旧包可被此次游戏读取，不能将压缩偏差断言为该次失效原因。

更新时退出游戏，用 1.0.1 覆盖自己安装的 MOD 文件夹，再重启加载存档。如果容量仍不正常，查看最新 `kcd.log` 中的 MOD 加载记录和 `rpg_param` 补丁记录，并记录背包显示的“当前重量 / 最大容量”。不要仅凭 manifest 路径判断参数已生效。

## 发布到 Steam 创意工坊（Windows）

以下流程依据 Warhorse 官方文档：[Modding Tools（KM-A-55）](https://warhorse.youtrack.cloud/articles/KM-A-55)、[Publishing to Steam workshop（KM-A-85）](https://warhorse.youtrack.cloud/articles/KM-A-85) 和 [Deep Silver 官方 MOD 指南](https://www.deepsilver.com/games/kingdom-come-deliverance-ii/news/modding-in-kingdom-come-deliverance-2)。2026-10-02 已通过官方 YouTrack API 核对前两篇正文；未实际操作上传器，按钮名称以安装版本为准。

### 1. 安装官方上传工具

1. 用拥有《天国：拯救 2》的账号登录 Steam，并保持客户端运行。官方说明要求账号已激活游戏；家庭共享或免费周末账号可能无法上传。
2. 在 Steam 库中启用“工具”筛选，搜索并安装 **Kingdom Come: Deliverance II Modding tools**。这是独立于游戏本体的工具应用。
3. 启动工具，选择 **Launch Workshop uploader**；也可以在工具安装目录运行：

   ```text
   Tools\SteamWorkshopUploader\SteamWorkshopUploader.exe
   ```

官方说明不能仅靠 Steam 客户端上传 MOD，必须使用这个专用上传器。若上传器提示缺少运行时，按提示安装对应架构的 [.NET 6 Desktop Runtime](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)；KM-A-55 将它列为上传器依赖。

### 2. 准备上传文件

先执行本文“开发与打包”中的构建命令。本项目应选择的上传目录是：

```text
E:\Docs\Projects\Unlimited-Weight-MOD-KCD2\dist\UnlimitedWeight
├── mod.manifest
└── Data
    └── unlimitedweight.pak
```

如果项目移到了其他位置，使用对应的 `dist\UnlimitedWeight` 绝对路径。**选择直接包含 `mod.manifest` 的目录**，不要选择项目根目录、`src`、`Data` 或安装 ZIP 文件。这是 KM-A-85 对上传目录的要求。

另准备一张封面图片，大小不超过 **1 MB**；官方说明超过该大小会上传失败。封面尚未包含在本项目中。

### 3. 首次上传

1. 在上传器点击 **+** 新建工坊条目（官方文档确认此按钮）。
2. 设置显示名称，例如 `Unlimited Weight — 无限负重`，并将 MOD 文件夹路径设为上面的 `dist\UnlimitedWeight`。
3. 按界面提供的字段选择封面、填写简介；若上传器没有简介编辑入口，在上传后的工坊页面补充。简介可参考下方模板。
4. 根据上传器界面执行上传，等待成功结果；本文未核验当前版本提交按钮的具体名称。
5. 按 Steam 提示接受 [Steam 创意工坊服务条款](https://steamcommunity.com/sharedfiles/workshoplegalagreement)。官方说明每个账号需要接受一次。
6. 打开生成的工坊条目，保存其链接和条目 ID。**官方说明首次上传默认隐藏，只有作者可以订阅**；在工坊页面或 Steam 客户端修改可见性后才向其他玩家发布。

### 4. 订阅验证后公开

这是建议的发布验证流程；Deep Silver 官方指南要求通过工坊下载后，在正式版游戏中测试自己的 MOD。

1. 退出游戏，将此前手动安装的 `Mods\UnlimitedWeight` 暂时移到游戏目录之外，避免测试时手动副本也在生效。若有 `mod_order.txt`，备份并检查其条目是否允许工坊版本加载；不要清空其他 MOD 配置。
2. 在自己的工坊页面订阅该条目，等待 Steam 下载完成。
3. 启动 **游戏本体的正式版**，不要用 Modding tools 的开发版测试工坊订阅；官方说明开发版不加载游戏本体的工坊订阅。
4. 用备份存档确认背包容量增大，拿取超过原容量的物品，测试行走和冲刺，并记录游戏版本、模式及其他启用的 MOD。
5. 测试通过后，在工坊条目中补充实测信息，再将可见性改为公开。未测试的游戏版本、硬核模式或组合不要标注为已兼容。

### 5. 后续更新与排错

- 修改源码中的参数或 manifest 版本后，重新执行 `build.ps1`，上传最新的 `dist\UnlimitedWeight`。
- 更新时应使用首次发布的原工坊条目，保留其链接、ID 和上传器记录；不要再次点击 **+** 创建重复条目。当前版本选择已有条目和提交更新的具体控件未实测，按上传器界面操作。
- 每次更新后重新订阅验证下载内容，并在条目页面写明更新内容和实测游戏版本。
- 上传失败时，核对账号是否拥有游戏、上传路径是否直接包含 manifest、封面是否超过 1 MB，以及是否接受服务条款。若有错误码，查询 [Valve EResult 官方说明](https://partner.steamgames.com/doc/api/steam_api#EResult)。

### 工坊简介模板

```text
Unlimited Weight — 无限负重

将基础背包容量及其基础上限设为 999999，让日常囤积物品时近似无限负重。
这是很高的有限上限，并非真正移除超重判定。

仅修改 BaseInventoryCapacity 和 MaxBaseInventoryCapacity 参数。请避免同时使用修改相同参数的 MOD。
订阅后等待 Steam 下载完成，再重启游戏。
取消订阅前，建议把多余物品存入箱子，避免恢复正常容量后超重。

实测游戏版本：[测试后填写]
实测模式：[测试后填写]
版本：1.0.1
本 MOD 为玩家制作。
```

## 验证范围

已通过自动包结构检查（ZIP_STORED、CRC、XML 和两项容量参数）。2026-10-02，用户反馈 1.0.1 在 Windows / Steam 稳定版、非硬核模式下实测生效；此前本机日志记录的游戏版本为 `1.5.6-15693-release_1_5`。这是用户提供的游戏内验证结果，未由开发助手直接观察。硬核模式、不同技能及其他 MOD 组合、其他使用该参数的实体仍未验证，不承诺所有版本兼容。

## 资料来源

- [Steam 社区参数补丁制作示例](https://steamcommunity.com/workshop/discussions/18446744073709551615/669453270933137711/?appid=1771300)：`BaseInventoryCapacity`、XML 格式、双下划线补丁文件名及 manifest 示例，属于社区作者提供的一手示例。
- [Warhorse 官方 MOD 文档入口](https://warhorse.youtrack.cloud/articles/KM-A-1)。
- [官方 Publishing a mod 文档的社区镜像](https://github.com/muyuanjin/kcd2-mod-docs/blob/main/official-wiki/KM-A-1%20Modding%20Kingdom%20Come%20Deliverance%202/KM-A-36%20Technical%20Overview/KM-A-58%20Publishing%20a%20mod/README.md)：发布版使用 PAK、无压缩 ZIP 和发布目录结构；当前读取的是镜像，并非对官方页面正文的直接核验。
