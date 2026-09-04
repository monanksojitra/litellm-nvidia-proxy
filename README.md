# LiteLLM Free Multi-Provider Proxy (NVIDIA NIM Primary + 33 Free Providers)

A production-ready, ultra-resilient LiteLLM proxy tailored for **Claude Code CLI**, Cursor, Cline, OpenCode, and Multi-Agent Frameworks (AutoGen, CrewAI, LangGraph). 

Features **NVIDIA NIM** as the primary high-performance engine, backed by **33 Free Tier Providers** and a **100% Keyless Fallback** (Pollinations AI) so your agent workflows never stop due to rate limits or outages.

---

## ⚡ Key Highlights

- 🚀 **NVIDIA NIM as Main Engine**: High-speed, high-context models (`nvidia/llama-3.3-nemotron-super-49b-v1.5`, `meta/llama-3.3-70b-instruct`, `deepseek-ai/deepseek-r1`, `qwen/qwen2.5-coder-32b-instruct`).
- 🤖 **Native Claude Code Support**: Drop-in replacement for Anthropic API endpoints (`/v1/messages` and `/v1/chat/completions`).
- 🛡️ **Zero-Downtime Fallback Chains**: If NVIDIA NIM or any provider hits a rate limit (429) or error (5xx), LiteLLM automatically routes to the next best free model seamlessly.
- 🔑 **Keyless Safety Net**: Pollinations AI is pre-configured with zero API keys required as the ultimate baseline fallback.
- ☁️ **One-Click Render Free Deployment**: Docker-based, stateless, memory-efficient setup with public health endpoints.

---

## 🏗️ Architecture & Logical Role Pools

```
                           Claude Code CLI / Cursor / Multi-Agent Swarms
                                                │
                                                │ Anthropic / OpenAI Format
                                                │ Authorization: Bearer $LITELLM_MASTER_KEY
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        LiteLLM Intelligent Multi-Provider Router                       │
│                                                                                        │
│  Role Pools & Priority Fallbacks:                                                      │
│  • free-coding (Sonnet 3.7 / 3.5)      ──► 1. NVIDIA NIM Nemotron Super 49B            │
│                                            2. NVIDIA NIM Llama 3.3 70B                 │
│                                            3. NVIDIA NIM Qwen 2.5 Coder 32B            │
│                                            4. Google Gemini 2.5 Flash                  │
│                                            5. Mistral Codestral                        │
│                                            6. Groq Llama 3.3 70B                       │
│                                            7. OpenRouter Free Models                   │
│                                            8. Pollinations AI (Keyless Emergency)      │
│                                                                                        │
│  • free-reasoning (Opus / Planning)    ──► 1. NVIDIA NIM DeepSeek R1                   │
│                                            2. DeepSeek R1 Direct API                   │
│                                            3. SambaNova DeepSeek R1 / Llama 405B       │
│                                            4. Groq DeepSeek R1 Distill 70B             │
│                                            5. Gemini 2.0 Flash Thinking                │
│                                            6. GitHub Models (o3-mini)                  │
│                                            7. OpenRouter / Pollinations DeepSeek R1    │
│                                                                                        │
│  • free-fast (Haiku / Fast Reviewer)   ──► 1. NVIDIA NIM Llama 3.1 8B                  │
│                                            2. Groq Llama 3.1 8B Instant (300+ tok/s)   │
│                                            3. Cerebras Llama 3.1 8B (1,000+ tok/s)     │
│                                            4. OpenRouter / Pollinations Fast Models    │
│                                                                                        │
│  • free-auto (Auto Fallback)           ──► OpenRouter Free Auto / Pollinations Hybrid  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Model Mappings for Claude Code

When Claude Code connects to this proxy, model requests are automatically mapped as follows:

| Claude Code Model Request | Mapped Proxy Pool | Primary Free Model Used |
| :--- | :--- | :--- |
| `claude-3-7-sonnet-20250219` | `free-coding` | NVIDIA Nemotron Super 49B / Llama 3.3 70B |
| `claude-3-5-sonnet-20241022` | `free-coding` | NVIDIA Nemotron Super 49B / Gemini 2.5 Flash |
| `claude-3-5-haiku-20241022` | `free-fast` | NVIDIA Llama 3.1 8B / Groq 8B Instant |
| `claude-3-opus-20240229` | `free-reasoning` | NVIDIA DeepSeek R1 / SambaNova 405B |

---

## 🎯 Direct Model Endpoints & Dynamic Wildcard Selection

### 1. Direct Named Models
- **NVIDIA NIM**: `nvidia-nemotron`, `nvidia-llama-70b`, `nvidia-deepseek-r1`, `nvidia-qwen-coder`, `nvidia-llama-8b`
- **Google Gemini**: `gemini-flash`, `gemini-thinking`
- **Groq**: `groq-llama-70b`, `groq-deepseek-r1`, `groq-llama-8b`
- **Mistral**: `mistral-codestral`
- **SambaNova**: `sambanova-llama-70b`, `sambanova-llama-405b`, `sambanova-deepseek-r1`
- **GitHub Models**: `github-gpt-4o`, `github-o3-mini`, `github-llama-70b`
- **OpenRouter Free**: `openrouter-qwen-coder`, `openrouter-llama-70b`, `openrouter-deepseek-r1`, `openrouter-auto-free`
- **Pollinations (Keyless)**: `pollinations-qwen-coder`, `pollinations-deepseek-r1`, `pollinations-claude-hybrid`

### 2. ⚡ Dynamic Model Passthrough (Use ANY NVIDIA NIM Model from Local)
Whenever NVIDIA adds a new free or preview model on [build.nvidia.com](https://build.nvidia.com/explore/discover), you **do not need to redeploy the proxy**. You can call it directly using the `nim/<model-path>` prefix:

- `nim/nvidia/llama-3.3-nemotron-super-49b-v1.5`
- `nim/meta/llama-3.3-70b-instruct`
- `nim/deepseek-ai/deepseek-r1`
- `nim/qwen/qwen2.5-coder-32b-instruct`
- `nim/mistralai/mistral-large-2-instruct`

---

## 🚀 Claude Code CLI Quickstart

### 1. Set Environment Variables
Add the following to your `~/.bashrc`, `~/.zshrc`, or project `.env`:

```bash
# Point Claude Code to your deployed LiteLLM proxy (or http://localhost:4000 for local testing)
export ANTHROPIC_BASE_URL="https://your-proxy-name.onrender.com"

# The master key you defined in LITELLM_MASTER_KEY
export ANTHROPIC_AUTH_TOKEN="sk-your-litellm-master-key"
export ANTHROPIC_API_KEY="sk-your-litellm-master-key"

# OPTIONAL: Explicitly pick any model from your local system (or let it use default free-coding pool)
# Example 1: Use specific NVIDIA model directly
export ANTHROPIC_MODEL="nvidia-nemotron"
# Example 2: Use any dynamic NVIDIA NIM model from build.nvidia.com
# export ANTHROPIC_MODEL="nim/meta/llama-3.3-70b-instruct"
# Example 3: Model pool mappings
# export ANTHROPIC_DEFAULT_SONNET_MODEL="free-coding"
# export ANTHROPIC_DEFAULT_OPUS_MODEL="free-reasoning"
# export ANTHROPIC_DEFAULT_HAIKU_MODEL="free-fast"
```

### 2. Verify Connection
```bash
# 1. Health check (public)
curl "https://your-proxy-name.onrender.com/health/liveliness"

# 2. Test NVIDIA NIM / Primary Coding Pool
curl "https://your-proxy-name.onrender.com/v1/chat/completions" \
  -H "Authorization: Bearer sk-your-litellm-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "free-coding",
    "messages": [{"role": "user", "content": "Hello! Say hi from NVIDIA NIM."}],
    "max_tokens": 50
  }'
```

### 3. Launch Claude Code
```bash
claude
```

Claude Code will now route all commands, tool calling, and coding steps through your proxy with NVIDIA NIM and the free provider pool!

---

## ☁️ Deploy to Render in 3 Steps

### Step 1: Push Repository to GitHub
```bash
git add .
git commit -m "Configure NVIDIA NIM primary and free provider proxy"
git push origin master
```

### Step 2: Create Web Service on Render
1. Go to [Render Dashboard](https://dashboard.render.com).
2. Click **New +** → **Web Service** → Connect your GitHub repository.
3. Configuration:
   - **Environment**: `Docker`
   - **Plan**: `Free`
   - **Health Check Path**: `/health/liveliness`

### Step 3: Add Environment Variables in Render Dashboard
Go to **Environment** tab in Render and add:

| Variable Name | Description | Mandatory / Optional |
| :--- | :--- | :--- |
| `LITELLM_MASTER_KEY` | Custom authentication secret (e.g. `sk-mysecret123456789`) | **Mandatory** |
| `NVIDIA_API_KEY` | Free API key from [build.nvidia.com](https://build.nvidia.com/) (1,000 free credits) | **Primary Recommended** |
| `OPENROUTER_API_KEY` | Free key from [openrouter.ai/keys](https://openrouter.ai/keys) | Optional (for OpenRouter free models) |
| `GEMINI_API_KEY` | Free key from [aistudio.google.com](https://aistudio.google.com/) | Optional (15 RPM / 1M TPM) |
| `GROQ_API_KEY` | Free key from [console.groq.com](https://console.groq.com/) | Optional (300+ tok/s) |
| `MISTRAL_API_KEY` | Free key from [console.mistral.ai](https://console.mistral.ai/) | Optional (Codestral 1B tokens/mo) |
| `SAMBANOVA_API_KEY` | Free key from [cloud.sambanova.ai](https://cloud.sambanova.ai/) | Optional (Llama 405B & R1) |
| `GITHUB_API_KEY` | Personal Access Token from [github.com/settings/tokens](https://github.com/settings/tokens) | Optional (o3-mini & GPT-4o) |
| `DEEPSEEK_API_KEY` | Key from [platform.deepseek.com](https://platform.deepseek.com/) | Optional (5M free tokens) |
| `ZHIPUAI_API_KEY` | Key from [open.bigmodel.cn](https://open.bigmodel.cn/) | Optional (GLM-4-Flash free) |

> 💡 **Note**: You only need `LITELLM_MASTER_KEY` + `NVIDIA_API_KEY` to start. Any additional keys you add will automatically unlock extra providers in the pool. If a key is missing or rate limited, LiteLLM automatically bypasses it and uses the next available provider.

---

## 💻 Local Testing with Docker

To test locally before deploying:

```bash
# Run locally with Docker
docker build -t litellm-nvidia-proxy .
docker run -p 4000:4000 \
  -e LITELLM_MASTER_KEY="sk-test-master-key-12345" \
  -e NVIDIA_API_KEY="nvapi-your-key" \
  -e OPENROUTER_API_KEY="sk-or-your-key" \
  -e GEMINI_API_KEY="your-gemini-key" \
  litellm-nvidia-proxy
```

Test the local instance:
```bash
curl http://localhost:4000/health/liveliness
```

---

## 🔒 Security Best Practices

1. **Never commit actual API keys to Git**: All upstream keys are stored securely as environment variables on Render.
2. **Master Key Guard**: Use a strong random key prefixed with `sk-` for `LITELLM_MASTER_KEY` (`openssl rand -hex 24 | sed 's/^/sk-/'`).
3. **Protected Endpoints**: Only `/health/liveliness` and `/health/readiness` are open for Render health probes. All LLM endpoints require `Authorization: Bearer <LITELLM_MASTER_KEY>`.

---

## 📄 License
MIT