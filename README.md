# Chatterfly × DeepSeek Harness Research

> 腾讯 Chatterfly（Windows）与 DeepSeek Harness（DSH）隐藏/实验集成的公开研究记录、复现说明与辅助工具。

**研究日期：2026-09-22**

本仓库记录一次从 Chatterfly 的实验语音模式出发，定位本地 127.0.0.1:3080 任务接口、发现腾讯随客户端分发的 DSH 插件，并最终跑通：

~~~text
语音指令
  ↓
Chatterfly voiceinput.exe
  ↓
127.0.0.1:3080/chatterfly/v1/*
  ↓
Tencent dsh-ime / dsh-chatterfly-web
  ↓
DeepSeek Harness
  ↓
DeepSeek 官方模型
  ↓
Agent 工具 / 文件 / Shell
~~~

实际验证中，一句语音“帮我用 Python 写一个从 1 数到 10 的小代码”成功进入 Harness，会话使用 deepseek-official / deepseek-flash，并在工作区生成了 count_1_to_10.py。

## 为什么值得记录

Chatterfly 官方已经公开宣传“听懂需求、帮你执行任务”和“AI 指令，快速执行任务”，但在本次研究开始时，公开信息主要停留在产品功能层。

本次研究进一步确认 Windows 客户端内存在一套完整的 DeepSeek Harness 集成：

- Chatterfly 会向本机 127.0.0.1:3080 提交任务；
- 客户端安装目录随附 dsh-ime.tgz 与 dsh-chatterfly-web.tgz；
- 随附安装脚本会把这两个插件安装进 DSH profile；
- 插件暴露 /chatterfly/v1/health、/tasks、/events 等接口；
- 任务能创建/恢复 DSH Session，并实际调用模型与 Agent 工具；
- 健康接口公开能力位包括 approval、questions、deliverables、resume。

这意味着它不是“语音转文字 + 调一次模型”，而是一个面向桌面 Agent 的输入入口。

## 已验证环境

| 项目 | 本次验证值 |
|---|---|
| Chatterfly 主程序 | 1.0.0.5406 |
| voice input 组件 | 1.0.0.3621 |
| 腾讯 dsh-ime manifest | 1.0.8 |
| DeepSeek Harness | 0.1.5-rc.2 |
| Node.js | 24.19.0 |
| Windows | Windows 11 |
| DSH 监听 | 127.0.0.1:3080 |
| 模型 | deepseek-official / deepseek-flash |
| reasoning effort | low |

这些版本只是本次验证快照。Chatterfly 与 DSH 都可能快速迭代。

## 观察到的本地协议

任务提交：

~~~http
POST /chatterfly/v1/tasks
Host: 127.0.0.1:3080
Content-Type: application/json
~~~

请求体至少包含：

~~~json
{
  "new_session": false,
  "text": "<voice transcript>",
  "token": "<opaque token>",
  "user_id": "1"
}
~~~

响应会携带 task_id。

已确认/识别的接口：

~~~text
/chatterfly/v1/health
/chatterfly/v1/tasks
/chatterfly/v1/events
/chatterfly/v1/answers
/chatterfly/v1/cancel
~~~

Harness 会话 URL 还会出现：

~~~text
http://127.0.0.1:3080/?chatterflySession=<session-id>
~~~

**重要：** 本仓库不研究、不绕过、不伪造 Chatterfly 的本地 token。token 被视为不透明值；研究工具默认对它脱敏。

## 官方插件在本机的位置

在本次版本中，Chatterfly 安装目录包含：

~~~text
C:\Program Files (x86)\Chatterfly\<version>\dsh-ime\
├─ manifest.json
├─ plugins\
│  ├─ dsh-ime.tgz
│  └─ dsh-chatterfly-web.tgz
└─ scripts\
   ├─ check-env.mjs
   ├─ install-dsh-ime.mjs
   └─ spawn-cli.mjs
~~~

本仓库**不会重新分发**这些腾讯文件。辅助脚本只会在用户自己的已安装 Chatterfly 中寻找它们。

## 复现思路

### 1. 准备 DSH

官方 DeepSeek Harness：

https://github.com/deepseek-ai/deepseek-harness

DSH 默认 Web 端口就是 3080。本次验证使用 0.1.5-rc.2。

需要 Node.js、DSH 与 pnpm 可用。

### 2. 检查 Chatterfly 是否包含官方 payload

~~~powershell
pwsh ./scripts/Find-ChatterflyDshPayload.ps1
~~~

如果能找到 manifest、两个 tgz 与安装脚本，说明当前安装包包含这套集成。

### 3. 安装官方 Chatterfly 插件到 DSH

推荐先检查环境：

~~~powershell
pwsh ./scripts/Install-OfficialIntegration.ps1 -CheckOnly
~~~

然后执行安装（示例）：

~~~powershell
pwsh ./scripts/Install-OfficialIntegration.ps1 -Root D:\chatgpt\DeepSeekHarness -DshBin dsh
~~~

脚本不会从网络下载腾讯插件，只调用本机 Chatterfly 自带的 install-dsh-ime.mjs。

### 4. 配置 DeepSeek API Key

更推荐通过 DSH Web 的 Models/Settings 页面配置。

也可以使用本仓库的本地输入脚本：

~~~powershell
pwsh ./scripts/Set-DeepSeekApiKey.ps1 -DshHome D:\chatgpt\DeepSeekHarness\home
~~~

脚本不会把 Key 输出到终端。

### 5. 启动 DSH 并检查健康状态

~~~powershell
pwsh ./scripts/Test-Integration.ps1
~~~

健康接口成功时会返回类似：

~~~json
{
  "ok": true,
  "plugin": "chatterfly",
  "protocol": 1
}
~~~

### 6. 触发 Chatterfly 的 DSH/实验语音模式

本仓库不提供修改腾讯程序文件的补丁，也不包含腾讯二进制。

如果你的 Chatterfly 构建已经暴露相应实验入口，语音任务应进入 DSH Web 会话，并由 Agent 执行。

## 真实验证结果

一次成功任务：

~~~text
语音：
“帮我用 Python 写一个从 1 数到 10 的小代码”
~~~

Harness 记录：

~~~text
provider: deepseek-official
model: deepseek-flash
reasoningEffort: low
~~~

生成文件：

~~~python
for i in range(1, 11):
    print(i)
~~~

这证明链路已经越过“任务卡片/假请求”阶段，进入真实模型调用和工具执行。

## 公开资料与先例检索

截至 **2026-09-22**，我对公开网页和 GitHub 做了针对性检索，包括：

- dsh-ime
- dsh-chatterfly-web
- /chatterfly/v1/tasks
- /chatterfly/v1/events
- chatterflySession

当时未检索到把这些技术指纹完整串起来的公开复现。

这**不等于证明“全球第一发现”**：未被搜索引擎收录的内容、私有仓库、内部资料、聊天群讨论等都可能存在。本仓库只陈述“公开检索未发现精确先例”。

公开产品层资料：

- Chatterfly 官方网站：https://chatterfly.tencent.com/
- IT之家 2026-09-18 对 Chatterfly “AI 指令、快速执行任务”的报道：https://www.ithome.com/1/004/273.htm
- DeepSeek Harness 官方仓库：https://github.com/deepseek-ai/deepseek-harness

## 仓库内容

~~~text
docs/
  architecture.md
  discovery-timeline.md
  protocol-notes.md

scripts/
  Find-ChatterflyDshPayload.ps1
  Install-OfficialIntegration.ps1
  Set-DeepSeekApiKey.ps1
  Test-Integration.ps1

tools/
  task_probe.py
~~~

## 安全与隐私

请不要提交以下内容：

- DeepSeek API Key；
- Chatterfly token；
- .credentials.yaml；
- DSH session 原始日志；
- 含个人信息的语音转写；
- 腾讯 DLL / EXE / TGZ；
- 从腾讯二进制中大段复制出的实现代码。

.gitignore 已覆盖常见敏感文件，但提交前仍应人工检查。

## 版权与商标

本仓库只发布原创研究记录与辅助脚本，不重新分发腾讯或 DeepSeek 的专有/第三方文件。

“腾讯”“Chatterfly”“DeepSeek”“DeepSeek Harness”等名称与商标归各自权利人所有。本项目与腾讯、DeepSeek 官方均无隶属或授权关系。

## License

本仓库原创代码与文档使用 MIT License。第三方文件不属于本许可范围。
