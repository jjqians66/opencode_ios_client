# OpenCode iOS Client — Working Document

> 实现过程中的进度、问题与决策记录

## 当前状态

- **最后更新**：2026-02-12
- **Phase**：Phase 1 基本完成
- **编译**：✅ 通过
- **测试**：✅ 9 个单元测试通过

## 已完成

- [x] Session 列表：Chat Tab 左侧列表按钮，展示 workspace 下所有 Session，支持切换、新建、下拉刷新
- [x] PRD 更新（async API、默认 server、移除大 session/推送/多项目）
- [x] RFC 更新（MarkdownUI、原生能力、Phase 4 暂不实现）
- [x] Git 初始化、.gitignore（含 opencode-official）、docs 移至 docs/
- [x] 初始 commit：docs、OpenCodeClient 脚手架
- [x] Phase 1 基础：Models、APIClient、SSEClient、AppState
- [x] Phase 1 UI：Chat Tab、Settings Tab、Files Tab（占位）
- [x] Phase 1 完善：SSE 事件解析、流式更新、Part.state 兼容、Markdown 渲染、工具调用全行显示
- [x] 单元测试：defaultServerAddress、sessionDecoding、messageDecoding、sseEvent、partDecoding

## 待办

- [ ] Phase 2：Part 渲染、权限手动批准、主题、模型切换
- [ ] Phase 3：文件树、Markdown 预览、文档 Diff、高亮
- [ ] 与真实 OpenCode Server 联调验证

## 遇到的问题

1. **Local network prohibited (iOS)**：连接 `192.168.180.128:4096` 时报错 `Local network prohibited`。需在 Info.plist 添加：
   - `NSLocalNetworkUsageDescription`：说明为何需要本地网络，首次访问会弹出权限弹窗
   - `NSAppTransportSecurity` → `NSAllowsLocalNetworking`：允许 HTTP 访问本地 IP
   - 用户需在弹窗中要点「允许」才能连接

2. **发送后卡住**：发送失败时无反馈，输入框已清空导致用户不知道失败。修复：发送失败时恢复输入、显示错误 alert、发送中显示 loading

3. **发送后无实时更新**：发送成功、web 端已有回应，但 iOS 端需重启才能看到。原因：
   - SSE 仅在 `willEnterForegroundNotification` 时连接，首次启动时未连接
   - 部分事件（如 `server.connected`）无 `directory` 字段，解析失败
   - 修复：在 `refresh()` 成功后调用 `connectSSE()`；`SSEEvent.directory` 改为可选；发送成功后启动 60 秒轮询（每 2 秒 loadMessages）作为 fallback

4. **loadMessages 解析失败**：LLM 输出 thinking delta 时，`Part.state` 期望 String 但 API 返回 object（ToolState）。报错：`Expected to decode String but found a dictionary`。修复：新增 `PartStateBridge`，支持 state 为 String 或 object，object 时提取 `status`/`title` 用于 UI 显示

5. **Unable to simultaneously satisfy constraints**：键盘相关 (TUIKeyboardContentView, UIKeyboardImpl) 的约束冲突。来自系统键盘，非应用代码，通常无需修复。

## 决策记录

（记录实现过程中的技术决策）
