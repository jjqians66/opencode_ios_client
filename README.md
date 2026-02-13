# OpenCode iOS Client

OpenCode 的 iOS 原生客户端，用于远程连接 OpenCode 服务端、发送指令、监控 AI 工作进度、浏览代码变更。

## 功能概述

- **Chat**：发送消息、切换模型、查看 AI 回复与工具调用
- **Files**：文件树、Session 变更、代码/文档预览
- **Settings**：服务器连接、认证、主题、语音转写配置

## 环境要求

- iOS 17.0+
- Xcode 15+
- 运行中的 OpenCode Server（`opencode serve` 或 `opencode web`）

## 快速开始

1. 在 Mac 上启动 OpenCode：`opencode serve --port 4096`
2. 打开 iOS App，进入 Settings，填写服务器地址（如 `http://192.168.x.x:4096`）
3. 点击 Test Connection 验证连接
4. 在 Chat 中创建或选择 Session，开始对话

## 项目结构

```
OpenCodeClient/
├── OpenCodeClient/          # 主程序
│   ├── Models/              # 数据模型
│   ├── Services/            # API、SSE、语音转写
│   ├── Stores/              # 状态存储
│   ├── Utils/               # 工具类
│   └── Views/               # SwiftUI 视图
├── OpenCodeClientTests/     # 单元测试
└── OpenCodeClientUITests/   # UI 测试
```

## 文档

- `docs/OpenCode_iOS_Client_PRD.md` — 产品需求
- `docs/OpenCode_iOS_Client_RFC.md` — 技术方案
- `docs/OpenCode_Web_API.md` — OpenCode API 说明

## License

与 OpenCode 保持一致。
