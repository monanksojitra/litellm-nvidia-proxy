# LiteLLM Multi-Provider Free Proxy for Single & Multi-Agent Workflows

A high-performance LiteLLM proxy designed to route **Claude Code** and **Multi-Agent Systems** (AutoGen, CrewAI, LangGraph, Aider, Cursor, Cline) across **33 Free & Freemium LLM Providers** (modeled after OmniRoute) with automatic load balancing, multi-agent role pools, and resilient failover chains.

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
│  • `agent-coder` / `free-coding`       ──► (Gemini 2.5, Codestral, Groq 70B, Qwen,     │
│                                             SambaNova 70B, Zhipu GLM, DashScope,       │
│                                             Hyperbolic, DeepSeek V3, Together, Scaleway)│
│  • `agent-planner` / `free-reasoning`  ──► (DeepSeek Direct R1, SambaNova 405B,        │
│                                             Gemini Think, o3-mini, Nebius 405B,        │
│                                             Novita R1, Hyperbolic R1, AI21 Jamba, R+)  │
│  • `agent-reviewer` / `free-fast`      ──► (Cerebras 1000 tok/s, Groq 8B, ERNIE Speed, │
│                                             Hunyuan Lite, Cloudflare AI, Solar Mini)   │
│  • `free-auto`                         ──► (OpenRouter Free, Pollinations Keyless)     │
│                                                                                        │
│  Failover Chain (429 Rate-Limit & 5xx Outage Protection):                              │
│  `free-coding` ──► `free-reasoning` ──► `free-fast` ──► `free-auto`                   │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
   ┌────────────────────────────────────────┼────────────────────────────────────────┐
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│Google Gemini │                         │  Mistral AI  │                         │     Groq     │
│Gemini 2.5/2.0│                         │  Codestral   │                         │ Llama 3.3 70B│
│(1M-2M Context│                         │(1B Tokens/mo)│                         │ (300+ tok/s) │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  SambaNova   │                         │   Zhipu AI   │                         │DeepSeek Direct
│  Llama 405B  │                         │ GLM-4-Flash  │                         │ DeepSeek-R1  │
│ (DeepSeek R1)│                         │(Free Forever)│                         │ (5M Tokens)  │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  DashScope   │                         │  Hyperbolic  │                         │   Cerebras   │
│  Qwen Coder  │                         │ DeepSeek-R1  │                         │ 1,000+ tok/s │
│ (1M Tokens)  │                         │ ($10 Credits)│                         │ (Llama 70B)  │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│ GitHub Models│                         │ SiliconFlow  │                         │ Pollinations │
│ GPT-4o / o3  │                         │  Qwen / R1   │                         │ 100% Keyless │
│ (GitHub PAT) │                         │(Uncapped Free│                         │(Zero-Cost AI)│
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  Cloudflare  │                         │ Hugging Face │                         │ Baidu Qianfan│
│  Workers AI  │                         │  Serverless  │                         │ ERNIE Speed  │
│(10k neurons) │                         │ (Free Token) │                         │(Free Forever)│
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│Tencent Hunyuan                         │ Scaleway AI  │                         │   OVHcloud   │
│ Hunyuan Lite │                         │  Llama 3.3   │                         │ AI Endpoints │
│(Free Forever)│                         │(Euro Sovereign                         │(Monthly Free)│
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  Together AI │                         │  DeepInfra   │                         │  Nebius AI   │
│ ($25 Credits)│                         │ DeepSeek-R1  │                         │  Llama 405B  │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│ Fireworks AI │                         │    Cohere    │                         │  AI21 Labs   │
│ DeepSeek-R1  │                         │Command R+ 128│                         │Jamba 1.5 256k│
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│ Upstage Solar│                         │ Moonshot Kimi│                         │Perplexity AI │
│  Solar Pro   │                         │ Kimi K2.6    │                         │Sonar Reason  │
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼                                        ▼
┌──────────────┐                         ┌──────────────┐                         ┌──────────────┐
│  NVIDIA NIM  │                         │   StepFun    │                         │  FriendliAI  │
│Nemotron Super│                         │  Step-1/2    │                         │ Llama 3.3 70B│
└──────────────┘                         └──────────────┘                         └──────────────┘
   ▼                                        ▼
┌──────────────┐                         ┌──────────────┐
│   AIML API   │                         │  OpenRouter  │
│  Aggregator  │                         │:free models  │
└──────────────┘                         └──────────────┘
```

---

## 33 Supported Free Providers & API Portals

You can supply any combination of API keys to the proxy. The router automatically uses what is configured and skips unset keys.

| # | Provider | Top Free Models | Free Quota | Best For | Get API Key |
|---|:---|:---|:---|:---|:---|
| 1 | **Google AI Studio** | `gemini-2.5-flash`, `gemini-2.0-flash`, `gemini-2.0-flash-thinking` | **15 RPM / 1M TPM** (1,500 req/day) | 🥇 1M-2M context, tool calling | [aistudio.google.com](https://aistudio.google.com/) |
| 2 | **Mistral AI** | `codestral-latest`, `mistral-small-latest` | **1 Billion tokens/month** | 💻 Dedicated code generation | [console.mistral.ai](https://console.mistral.ai/api-keys/) |
| 3 | **Groq** | `llama-3.3-70b-versatile`, `qwen-2.5-coder-32b`, `llama-3.1-8b-instant` | **30 RPM / 30k TPM** | ⚡ Real-time agent speed (300+ tok/s) | [console.groq.com](https://console.groq.com/keys) |
| 4 | **SambaNova Cloud** | `Meta-Llama-3.1-405B-Instruct`, `DeepSeek-R1-Distill-Llama-70B` | **20-30 RPM** | 🧠 Massive 405B open model & DeepSeek R1 | [cloud.sambanova.ai](https://cloud.sambanova.ai/) |
| 5 | **DeepSeek Direct** | `deepseek-chat` (V3), `deepseek-reasoner` (R1) | **5 Million free tokens** | 🎯 Official native DeepSeek reasoning | [platform.deepseek.com](https://platform.deepseek.com/) |
| 6 | **Zhipu AI (GLM / Z.AI)**| `glm-4-flash`, `glm-4.5-flash` | **Permanently Free (Uncapped)** | 🌐 128k context, bilingual coding | [open.bigmodel.cn](https://open.bigmodel.cn/) |
| 7 | **Alibaba DashScope** | `qwen2.5-coder-32b-instruct`, `qwen-plus`, `qwen-turbo` | **1 Million free tokens/model** | 🚀 Native Qwen 2.5 Coder & Max | [bailian.console.aliyun.com](https://bailian.console.aliyun.com/) |
| 8 | **Hyperbolic AI** | `DeepSeek-R1`, `Qwen2.5-Coder-32B-Instruct`, `Llama-3.3-70B` | **$10 Free Credits** | ⚡ High-speed dedicated GPU clusters | [app.hyperbolic.xyz](https://app.hyperbolic.xyz/) |
| 9 | **Novita AI** | `deepseek/deepseek-r1`, `meta-llama/llama-3.3-70b-instruct` | Free trial credits | 🚀 Serverless DeepSeek R1 & Llama 70B | [novita.ai](https://novita.ai/) |
| 10 | **Pollinations AI** | `deepseek-r1`, `claude-hybrid`, `qwen-coder` | **100% Free & Keyless** | 🔄 Zero-config emergency fallback | [pollinations.ai](https://pollinations.ai/) |
| 11 | **Cerebras** | `llama-3.3-70b`, `llama3.1-8b` | **30 RPM / 60k TPM** | ⚡ Ultra-low latency (1,000+ tok/s) | [cloud.cerebras.ai](https://cloud.cerebras.ai/) |
| 12 | **GitHub Models** | `gpt-4o`, `gpt-4o-mini`, `o3-mini`, `DeepSeek-R1`, `Llama-3.3-70B` | **15-50 RPM** (Free with PAT) | 🛠️ GPT-4o & o3-mini via GitHub PAT | [github.com/marketplace/models](https://github.com/marketplace/models) |
| 13 | **SiliconFlow** | `DeepSeek-R1`, `DeepSeek-V3`, `Qwen2.5-Coder-32B-Instruct` | Millions of free tokens / uncapped | 💻 High-speed coding & DeepSeek R1 | [cloud.siliconflow.cn](https://cloud.siliconflow.cn/) |
| 14 | **Cloudflare Workers AI**| `@cf/meta/llama-3.3-70b-instruct`, `@cf/qwen/qwen2.5-coder-32b-instruct`| **10,000 neurons/day free** | 🌐 Edge inference & reviewer agent | [dash.cloudflare.com](https://dash.cloudflare.com/) |
| 15 | **Hugging Face** | `Qwen/Qwen2.5-Coder-32B-Instruct`, `meta-llama/Llama-3.3-70B-Instruct` | Free Serverless API with User Token | 🔀 Broad open-source ecosystem | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |
| 16 | **Baidu Qianfan** | `ernie-speed-128k`, `ernie-lite-8k`, `ernie-4.0-8k` | **Permanently Free (Uncapped)** | 🔍 Ultra-fast reasoning & general NLP | [qianfan.cloud.baidu.com](https://qianfan.cloud.baidu.com/) |
| 17 | **Tencent Hunyuan** | `hunyuan-lite`, `hunyuan-standard` | **Permanently Free (Uncapped)** | 🛡️ Background auditing & review | [cloud.tencent.com](https://cloud.tencent.com/product/hunyuan) |
| 18 | **Scaleway AI** | `llama-3.3-70b-instruct`, `deepseek-r1` | Free European cloud credits | 🇪🇺 European sovereign cloud inference | [scaleway.com](https://www.scaleway.com/en/ai-products/) |
| 19 | **OVHcloud AI** | `meta-llama-3.3-70b-instruct`, `mistral-small` | Monthly free tier allowance | 🇪🇺 European enterprise AI endpoints | [ovhcloud.com](https://www.ovhcloud.com/en/public-cloud/ai-endpoints/) |
| 20 | **Together AI** | `Qwen/Qwen2.5-Coder-32B-Instruct`, `Meta-Llama-3.1-70B-Instruct-Turbo` | **$25 Free trial credits** | 🚀 High-throughput code generation | [api.together.ai](https://api.together.ai/) |
| 21 | **DeepInfra** | `deepseek-ai/DeepSeek-R1`, `Qwen/Qwen2.5-Coder-32B-Instruct` | Free trial credits | 🎯 Fast DeepSeek R1 & Qwen Coder | [deepinfra.com](https://deepinfra.com/) |
| 22 | **Nebius AI Studio** | `meta-llama/Meta-Llama-3.1-405B-Instruct`, `DeepSeek-R1` | Free credits on signup | 🏢 High performance Llama 405B | [studio.nebius.ai](https://studio.nebius.ai/) |
| 23 | **Fireworks AI** | `accounts/fireworks/models/deepseek-r1` | Free trial credit | ⚡ Sub-second reasoning inference | [fireworks.ai](https://fireworks.ai/) |
| 24 | **Cohere** | `command-r-plus`, `command-r` | Free Developer Trial Key (100 RPM) | 🔍 High-precision RAG & complex reasoning | [dashboard.cohere.com](https://dashboard.cohere.com/api-keys) |
| 25 | **AI21 Labs** | `jamba-1.5-large`, `jamba-1.5-mini` | **$10 Free trial credits (256k ctx)** | 📚 Massive context hybrid Mamba-Transformer| [studio.ai21.com](https://studio.ai21.com/) |
| 26 | **Upstage** | `solar-pro`, `solar-mini` | **$10 Free trial credit** | 🎯 Agentic function calling & reasoning | [console.upstage.ai](https://console.upstage.ai/) |
| 27 | **Moonshot AI (Kimi)** | `kimi-k2.6`, `moonshot-v1-8k` | Free trial credits (128k context) | 📝 Deep context code analysis | [platform.moonshot.cn](https://platform.moonshot.cn/) |
| 28 | **Perplexity AI** | `sonar-reasoning`, `sonar` | Developer trial tier | 🌐 Web-grounded live reasoning | [perplexity.ai](https://www.perplexity.ai/settings/api) |
| 29 | **NVIDIA NIM** | `nvidia/llama-3.3-nemotron-super-49b-v1.5`, `deepseek-r1` | **1,000 free credits** | 🎯 Hybrid Nemotron reasoning | [build.nvidia.com](https://build.nvidia.com/) |
| 30 | **StepFun** | `step-1-8k`, `step-2-16k` | Free starter credits | 🧩 Multi-step reasoning & execution | [platform.stepfun.com](https://platform.stepfun.com/) |
| 31 | **FriendliAI** | `meta-llama-3.3-70b-instruct` | Free trial credits | ⚡ Ultra-fast Llama inference | [friendli.ai](https://friendli.ai/) |
| 32 | **AIML API** | `deepseek-r1`, `llama-3.3-70b` | Free tier requests | 🔀 Multi-model aggregator fallback | [aimlapi.com](https://aimlapi.com/) |
| 33 | **OpenRouter** | `openrouter/free` (auto-router), `llama-3.3-70b:free`, `deepseek-r1:free` | **20 RPM** (50-1000 req/day) | 🔄 Universal fallback across free models | [openrouter.ai/keys](https://openrouter.ai/keys) |

---

## Multi-Agent & Single-Agent Role Pools

When running multi-agent swarms (e.g. Architect + Coder + Reviewer) or single agents (Claude Code), routing to role-specific pools prevents rate limits and optimizes latency:

```yaml
# Available Logical Pools in config.yaml:
free-coding     # Primary Coding & Tool Calling Pool (Gemini 2.5, Codestral, Groq 70B, Qwen Coder, GLM, DashScope, Hyperbolic, etc.)
free-reasoning  # Deep Architecture & Reasoning Pool (DeepSeek Direct R1, SambaNova 405B, Nebius 405B, o3-mini, Novita R1, Jamba 1.5)
free-fast       # Ultra-Low Latency Reviewer Pool (Cerebras 1,000 tok/s, Groq 8B, ERNIE Speed, Hunyuan Lite, Cloudflare, Solar Mini)
free-auto       # OpenRouter & Pollinations Rotating Free Auto-Router Pool
```

### Role Aliases Mapping

| Framework Agent Role | Mapped Logical Pool | Target Use Case |
| :--- | :--- | :--- |
| `agent-coder` / `claude-3-5-sonnet` / `claude-3-7-sonnet` | `free-coding` | File editing, writing code, executing bash tool calls |
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
git commit -m "Configure 33 free LLM providers with multi-agent pools"
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
- `MISTRAL_API_KEY`
- `GROQ_API_KEY`
- `SAMBANOVA_API_KEY`
- `DEEPSEEK_API_KEY`
- `ZHIPUAI_API_KEY`
- `DASHSCOPE_API_KEY`
- `SILICONFLOW_API_KEY`
- `HYPERBOLIC_API_KEY`
- `NOVITA_API_KEY`
- `CEREBRAS_API_KEY`
- `GITHUB_API_KEY`
- `CLOUDFLARE_API_KEY` & `CLOUDFLARE_ACCOUNT_ID`
- `HF_TOKEN`
- `BAIDU_API_KEY`
- `HUNYUAN_API_KEY`
- `SCALEWAY_API_KEY`
- `OVHCLOUD_API_KEY`
- `TOGETHERAI_API_KEY`
- `DEEPINFRA_API_KEY`
- `NEBIUS_API_KEY`
- `FIREWORKS_AI_API_KEY`
- `COHERE_API_KEY`
- `AI21_API_KEY`
- `UPSTAGE_API_KEY`
- `MOONSHOT_API_KEY`
- `PERPLEXITYAI_API_KEY`
- `NVIDIA_API_KEY`
- `STEPFUN_API_KEY`
- `FRIENDLI_TOKEN`
- `AIMLAPI_KEY`
- `OPENROUTER_API_KEY`

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