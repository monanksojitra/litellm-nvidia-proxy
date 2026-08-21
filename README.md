# LiteLLM Multi-Provider Free Proxy for Single & Multi-Agent Workflows

A high-performance LiteLLM proxy designed to route **Claude Code** and **Multi-Agent Systems** (AutoGen, CrewAI, LangGraph, Aider, Cursor) across **16 Free LLM Providers** with automatic load balancing, multi-agent role pools, and resilient failover chains.

---

## Architecture

```
                       Single Agent (Claude Code) OR Multi-Agent Swarms
                                      │
                                      │ HTTP / Anthropic / OpenAI Format
                                      │ Authorization: Bearer $LITELLM_MASTER_KEY
                                      ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        LiteLLM Intelligent Multi-Agent Gateway                         │
│                                                                                        │
│  Multi-Agent Role Pools:                                                               │
│  • `agent-coder` / `free-coding`       ──► (Gemini 2.5, Groq, SambaNova, Codestral,    │
│                                             SiliconFlow Qwen, GitHub, Together, HF)    │
│  • `agent-planner` / `free-reasoning`  ──► (SambaNova 405B, DeepSeek R1, Gemini Think, │
│                                             GitHub o3-mini, Nebius 405B, Cohere R+)    │
│  • `agent-reviewer` / `free-fast`      ──► (Cerebras 1000 tok/s, Groq 8B, Gemini Flash,│
│                                             Cloudflare Workers AI, SiliconFlow 8B)     │
│  • `free-auto`                         ──► (OpenRouter Rotating Free Pool)             │
│                                                                                        │
│  Failover Chain (429 Rate-Limit & 5xx Outage Protection):                              │
│  `free-coding` ──► `free-reasoning` ──► `free-fast` ──► `free-auto`                   │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
   ┌────────────────────────────────────────┼────────────────────────────────────────┐
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│Google Gemini │                         │     Groq     │                         │  SambaNova   │
│Gemini 2.5/2.0│                         │ Llama 3.3 70B│                         │  Llama 405B  │
│(1M-2M Context│                         │(Ultra-Fast)  │                         │(DeepSeek R1) │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│   Cerebras   │                         │ GitHub Models│                         │ SiliconFlow  │
│ 1,000+ tok/s │                         │ GPT-4o / o3  │                         │  Qwen Coder  │
│ (Llama 70B)  │                         │ (GitHub PAT) │                         │(DeepSeek R1) │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  Cloudflare  │                         │ Hugging Face │                         │    Cohere    │
│  Workers AI  │                         │  Serverless  │                         │Command R+ 128│
│(10k neurons) │                         │ (Free Token) │                         │ (Trial Keys) │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  Together AI │                         │  DeepInfra   │                         │  Nebius AI   │
│ Qwen / Llama │                         │ DeepSeek R1  │                         │  Llama 405B  │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│ Fireworks AI │                         │  Mistral AI  │                         │  OpenRouter  │
│ DeepSeek R1  │                         │  Codestral   │                         │:free models  │
└──────────────┘                         └──────────────┘                         └──────────────┘
                                            ▼
                                 ┌──────────────────────┐
                                 │      NVIDIA NIM      │
                                 │   Nemotron Super     │
                                 └──────────────────────┘
```

---

## 16 Supported Free Providers & API Portals

You can supply any combination of API keys to the proxy. The router automatically uses what is configured and skips unset keys.

| # | Provider | Top Free Models | Free Quota | Best For | Get API Key |
|---|:---|:---|:---|:---|:---|
| 1 | **Google AI Studio** | `gemini-2.5-flash`, `gemini-2.0-flash`, `gemini-2.0-flash-thinking` | **15 RPM / 1M TPM** (1,500 req/day) | 🥇 1M-2M context, tool calling | [aistudio.google.com](https://aistudio.google.com/) |
| 2 | **Groq** | `llama-3.3-70b-versatile`, `qwen-2.5-coder-32b`, `llama-3.1-8b-instant` | **30 RPM / 30k TPM** | ⚡ Real-time agent speed (200-500 tok/s) | [console.groq.com](https://console.groq.com/keys) |
| 3 | **SambaNova Cloud** | `Meta-Llama-3.1-405B-Instruct`, `DeepSeek-R1-Distill-Llama-70B` | **20-30 RPM** | 🧠 Massive 405B open model & DeepSeek R1 | [cloud.sambanova.ai](https://cloud.sambanova.ai/) |
| 4 | **Cerebras** | `llama-3.3-70b`, `llama3.1-8b` | **30 RPM / 60k TPM** | ⚡ Ultra-low latency (1,000+ tok/s) | [cloud.cerebras.ai](https://cloud.cerebras.ai/) |
| 5 | **GitHub Models** | `gpt-4o`, `gpt-4o-mini`, `o3-mini`, `DeepSeek-R1`, `Llama-3.3-70B` | **15-50 RPM** (Free with PAT) | 🛠️ GPT-4o & o3-mini via GitHub Personal Token | [github.com/marketplace/models](https://github.com/marketplace/models) |
| 6 | **SiliconFlow** | `DeepSeek-R1`, `DeepSeek-V3`, `Qwen2.5-Coder-32B-Instruct` | Millions of free tokens / free tier | 💻 High-speed coding & DeepSeek R1 | [cloud.siliconflow.cn](https://cloud.siliconflow.cn/) |
| 7 | **Cloudflare Workers AI** | `@cf/meta/llama-3.3-70b-instruct`, `@cf/qwen/qwen2.5-coder-32b-instruct` | **10,000 neurons/day free** | 🌐 Edge inference & reviewer agent | [dash.cloudflare.com](https://dash.cloudflare.com/) |
| 8 | **Hugging Face** | `Qwen/Qwen2.5-Coder-32B-Instruct`, `meta-llama/Llama-3.3-70B-Instruct` | Free Serverless API with User Token | 🔀 Broad open-source ecosystem | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |
| 9 | **Cohere** | `command-r-plus`, `command-r` | Free Developer Trial Key (100 RPM) | 🔍 High-precision RAG & complex reasoning | [dashboard.cohere.com](https://dashboard.cohere.com/api-keys) |
| 10 | **OpenRouter** | `openrouter/free` (auto-router), `llama-3.3-70b:free`, `deepseek-r1:free` | **20 RPM** (50-1000 req/day) | 🔄 Universal fallback across free models | [openrouter.ai/keys](https://openrouter.ai/keys) |
| 11 | **Mistral AI** | `codestral-latest`, `mistral-small-latest` | Free Experimentation Tier | 💻 Dedicated code generation | [console.mistral.ai](https://console.mistral.ai/api-keys/) |
| 12 | **Together AI** | `Qwen/Qwen2.5-Coder-32B-Instruct`, `Meta-Llama-3.1-70B-Instruct-Turbo` | Free trial credits ($5) | 🚀 High-throughput code generation | [api.together.ai](https://api.together.ai/) |
| 13 | **DeepInfra** | `deepseek-ai/DeepSeek-R1`, `Qwen/Qwen2.5-Coder-32B-Instruct` | Free trial credits | 🎯 Fast DeepSeek R1 & Qwen Coder | [deepinfra.com](https://deepinfra.com/) |
| 14 | **Nebius AI Studio** | `meta-llama/Meta-Llama-3.1-405B-Instruct`, `DeepSeek-R1` | Free credits on signup | 🏢 High performance Llama 405B | [studio.nebius.ai](https://studio.nebius.ai/) |
| 15 | **Fireworks AI** | `accounts/fireworks/models/deepseek-r1` | Free trial credit | ⚡ Sub-second reasoning inference | [fireworks.ai](https://fireworks.ai/) |
| 16 | **NVIDIA NIM** | `nvidia/llama-3.3-nemotron-super-49b-v1.5`, `deepseek-ai/deepseek-r1` | 1,000 free credits | 🎯 Hybrid Nemotron reasoning | [build.nvidia.com](https://build.nvidia.com/) |

---

## Multi-Agent & Single-Agent Role Pools

When running multi-agent swarms (e.g. Architect + Coder + Reviewer) or single agents (Claude Code), routing to role-specific pools prevents rate limits and optimizes latency:

```yaml
# Available Logical Pools in config.yaml:
free-coding     # Primary Coding & Tool Calling Pool (Gemini 2.5, Groq 70B, SambaNova, Codestral, SiliconFlow, HF, Together)
free-reasoning  # Deep Architecture & Reasoning Pool (SambaNova 405B, DeepSeek R1, Gemini Thinking, GitHub o3-mini, Nebius 405B)
free-fast       # Ultra-Low Latency Reviewer Pool (Cerebras 1,000 tok/s, Groq 8B, Cloudflare Workers AI, Gemini 2.0 Flash)
free-auto       # OpenRouter Rotating Free Auto-Router Pool
```

### Role Aliases Mapping

| Framework Agent Role | Mapped Logical Pool | Target Use Case |
| :--- | :--- | :--- |
| `agent-coder` / `claude-3-5-sonnet` | `free-coding` | File editing, writing code, executing bash tool calls |
| `agent-planner` / `agent-architect` / `claude-3-opus` | `free-reasoning` | High-level system design, multi-step plan decomposition |
| `agent-reviewer` / `agent-tester` / `claude-3-5-haiku` | `free-fast` | Fast linter checks, test suite audits, rapid completions |

---

## Claude Code Integration

### 1. Configure Shell Environment

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Point Claude Code to your LiteLLM Proxy
export ANTHROPIC_BASE_URL="https://your-litellm-proxy.onrender.com"

# LiteLLM Master Key (Must match LITELLM_MASTER_KEY configured on proxy)
export ANTHROPIC_API_KEY="sk-your-litellm-master-key"

# (Optional) Explicitly select a model pool or let it default to Sonnet mapping
export ANTHROPIC_MODEL="free-coding"
```

### 2. Verify Proxy Connection

```bash
# Public Health Check
curl "$ANTHROPIC_BASE_URL/health/liveliness"

# Test Primary Coding Pool
curl "$ANTHROPIC_BASE_URL/v1/chat/completions" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "free-coding",
    "messages": [{"role": "user", "content": "Write a Python fibonacci generator."}],
    "max_tokens": 100
  }'
```

### 3. Start Claude Code

```bash
claude
```

---

## Render Deployment

### 1. Push to GitHub
```bash
git add .
git commit -m "Configure 16 free LLM providers with multi-agent pools"
git push origin main
```

### 2. Deploy on Render
1. Go to [Render Dashboard](https://dashboard.render.com).
2. Create **New Web Service** → Connect repository.
3. Select **Docker** runtime on **Free Plan**.
4. Set `healthCheckPath` to `/health/liveliness`.

### 3. Add Environment Variables on Render
Add `LITELLM_MASTER_KEY` along with whichever free provider keys you have registered:

- `LITELLM_MASTER_KEY` (`sk-...`)
- `GEMINI_API_KEY`
- `GROQ_API_KEY`
- `SAMBANOVA_API_KEY`
- `CEREBRAS_API_KEY`
- `GITHUB_API_KEY`
- `SILICONFLOW_API_KEY`
- `CLOUDFLARE_API_KEY` & `CLOUDFLARE_ACCOUNT_ID`
- `HF_TOKEN`
- `COHERE_API_KEY`
- `OPENROUTER_API_KEY`
- `MISTRAL_API_KEY`
- `TOGETHERAI_API_KEY`
- `DEEPINFRA_API_KEY`
- `NEBIUS_API_KEY`
- `FIREWORKS_AI_API_KEY`
- `NVIDIA_API_KEY`

---

## Security Best Practices

1. **Zero Secret Leaks:**
   - Upstream API keys reside **only** in the Render Environment Dashboard.
   - Your local environment only requires `LITELLM_MASTER_KEY`.
2. **Master Key Guard:**
   - The master key must begin with `sk-` (e.g. `openssl rand -hex 32 | sed 's/^/sk-/'`).
3. **Protected Endpoints:**
   - Public access is only granted to `/health/liveliness` and `/health/readiness`. All inference routes require Bearer token authentication.

---

## License
MIT - Build unlimited agentic workflows with free AI models!