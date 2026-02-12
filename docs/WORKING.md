# OpenCode iOS Client — Working Document

> 实现过程中的进度、问题与决策记录

## 当前状态

- **最后更新**：2026-02-12
- **Phase**：Phase 1 基本完成
- **编译**：✅ 通过
- **测试**：✅ 3 个单元测试通过

## 已完成

- [x] PRD 更新（async API、默认 server、移除大 session/推送/多项目）
- [x] RFC 更新（MarkdownUI、原生能力、Phase 4 暂不实现）
- [x] Git 初始化、.gitignore（含 opencode-official）、docs 移至 docs/
- [x] 初始 commit：docs、OpenCodeClient 脚手架
- [x] Phase 1 基础：Models、APIClient、SSEClient、AppState
- [x] Phase 1 UI：Chat Tab、Settings Tab、Files Tab（占位）
- [x] 单元测试：defaultServerAddress、sessionDecoding、messageDecoding

## 待办

- [ ] Phase 1 完善：SSE 事件解析、流式渲染优化
- [ ] Phase 2：Part 渲染、权限手动批准、主题、模型切换
- [ ] Phase 3：文件树、Markdown 预览、文档 Diff、高亮
- [ ] 与真实 OpenCode Server 联调验证

## 遇到的问题

（记录实现过程中遇到的问题与解决方案）

## 决策记录

（记录实现过程中的技术决策）
