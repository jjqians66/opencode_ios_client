# Speech Recognition (AI Builder)

本项目支持「按住/点击麦克风录音 → 调用 AI Builder 语音转写 API → 将转写文本追加到输入框」。

## 1. 你需要准备什么

- 一个 AI Builder token（环境变量名：`AI_BUILDER_TOKEN`）

## 2. iOS 端如何配置（不会提交到 git）

在 App 的 Settings 里：

- `AI Builder Base URL`：默认 `https://www.ai-builders.com/backend`
- `AI Builder Token`：粘贴你的 token

说明：token 会存到 **Keychain**，不会写入仓库、也不会出现在源码里。

## 3. 使用方式

- Chat 输入框右侧点击麦克风：开始录音
- 再点击一次：停止录音并发起转写
- 转写成功后，文本会追加到输入框末尾

## 4. API

- `POST /v1/audio/transcriptions`（multipart/form-data）
  - `audio_file`：录音文件
  - 可选：`language`（如 `zh-CN`）
