# LiteLLM NVIDIA Proxy

Secure LiteLLM proxy for accessing NVIDIA hosted LLMs (Nemotron, Llama Nemotron, etc.) via Render Free tier.

## Architecture

```
Claude Code (Local Ubuntu)
         │
         │ HTTPS + Bearer Token (LITELLM_MASTER_KEY)
         ▼
┌─────────────────────────────────────┐
│  Render Free Web Service            │
│  ┌─────────────────────────────┐   │
│  │  LiteLLM Proxy (Docker)     │   │
│  │  - Auth required            │   │
│  │  - Rate limited             │   │
│  │  - Model: nvidia-coding     │   │
│  └──────────────┬──────────────┘   │
└─────────────────┼──────────────────┘
                  │ NVIDIA_API_KEY (env var only)
                  ▼
         ┌─────────────────┐
         │  NVIDIA API     │
         │  integrate.api  │
         │  .nvidia.com/v1 │
         └─────────────────┘
```

**Key Security Properties:**
- NVIDIA API key **never** leaves Render (stored only as Render environment variable)
- LiteLLM master key used by Claude Code for authentication
- All traffic over HTTPS (Render provides TLS)
- Proxy requires authentication on all completion endpoints
- Rate limiting enforced at proxy level

---

## Local Testing

### Prerequisites
- Docker installed
- NVIDIA API key (from [build.nvidia.com](https://build.nvidia.com))
- Generated LiteLLM master key

### Generate Master Key
```bash
openssl rand -hex 32 | sed 's/^/sk-/'
```

### Build Image
```bash
cd litellm-nvidia-proxy
docker build -t litellm-nvidia-proxy .
```

> **Note**: Uses LiteLLM 1.84.0+ to address critical CVEs (CVE-2026-49468, CVE-2026-35029, etc.)

### Run Container
```bash
# Set your keys
export NVIDIA_API_KEY="nvapi-xxxxxxxxxxxxx"
export LITELLM_MASTER_KEY="sk-xxxxxxxxxxxxx"

docker run -d \
  --name litellm-proxy \
  -p 4000:4000 \
  -e NVIDIA_API_KEY="$NVIDIA_API_KEY" \
  -e LITELLM_MASTER_KEY="$LITELLM_MASTER_KEY" \
  litellm-nvidia-proxy
```

### Test Health Endpoint (no auth required)
```bash
curl http://localhost:4000/health/liveliness
# Expected: {"status": "ok"}

curl http://localhost:4000/health/readiness
# Expected: {"status": "ok"} (or checks DB if configured)
```

### Test Completion Endpoint (auth required)
```bash
# Valid authentication
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia-coding",
    "messages": [
      {"role": "user", "content": "Write a simple TypeScript hello world function."}
    ],
    "max_tokens": 200
  }'

# Invalid authentication (should fail with 401)
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-fake-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "nvidia-coding", "messages": [{"role": "user", "content": "test"}]}'

# No authentication (should fail with 401)
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "nvidia-coding", "messages": [{"role": "user", "content": "test"}]}'
```

### Clean Up
```bash
docker stop litellm-proxy && docker rm litellm-proxy
```

---

## Render Deployment

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "Initial commit: LiteLLM NVIDIA proxy"
git remote add origin https://github.com/YOUR_USERNAME/litellm-nvidia-proxy.git
git push -u origin main
```

### 2. Create Render Web Service
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **New** → **Web Service**
3. Connect your GitHub repository
4. Configure:
   - **Name**: `litellm-nvidia-proxy` (or your choice)
   - **Runtime**: `Docker`
   - **Plan**: `Free`
   - **Region**: Choose closest to you
   - **Dockerfile Path**: `./Dockerfile` (default)

### 3. Add Environment Variables
In Render Dashboard → Environment, add:

| Key | Value | Notes |
|-----|-------|-------|
| `NVIDIA_API_KEY` | `nvapi-xxxxxxxxxxxxx` | From [build.nvidia.com](https://build.nvidia.com) → API Keys |
| `LITELLM_MASTER_KEY` | `sk-xxxxxxxxxxxxx` | Generated via `openssl rand -hex 32 | sed 's/^/sk-/'` |

**⚠️ NEVER put these in render.yaml, GitHub, or Dockerfile.**

### 4. Deploy
Click **Create Web Service**. Render will build and deploy.

### 5. Test Deployed Service
```bash
# Replace with your Render URL
RENDER_URL="https://litellm-nvidia-proxy.onrender.com"

# Health check
curl "$RENDER_URL/health/liveliness"

# Completion (with your master key)
curl "$RENDER_URL/v1/chat/completions" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "nvidia-coding", "messages": [{"role": "user", "content": "Hello!"}], "max_tokens": 100}'
```

---

## Claude Code Integration

### Current Claude Code Configuration (v2.1+)

Claude Code supports custom API endpoints via environment variables:

```bash
# Set in your shell profile (~/.bashrc, ~/.zshrc, etc.)
export ANTHROPIC_BASE_URL="https://your-render-url.onrender.com"
export ANTHROPIC_API_KEY="sk-your-litellm-master-key"
export ANTHROPIC_MODEL="nvidia-coding"
```

**Important:** 
- `ANTHROPIC_BASE_URL` should point to your Render proxy URL (no trailing slash)
- `ANTHROPIC_API_KEY` is your **LiteLLM master key** (starts with `sk-`)
- `ANTHROPIC_MODEL` is the model alias defined in `config.yaml` (`nvidia-coding`)
- **NVIDIA_API_KEY is NOT set locally** - it only exists in Render

### Verify Configuration
```bash
# Test that Claude Code can reach the proxy
curl "$ANTHROPIC_BASE_URL/health/liveliness"

# Test authenticated request
curl "$ANTHROPIC_BASE_URL/v1/chat/completions" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "nvidia-coding", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'
```

### Start Claude Code
```bash
claude
```

Claude Code will now use your Render proxy → NVIDIA API for all model requests.

---

## Security

### Secret Locations

| Secret | Local Machine | Git Repo | Docker Image | Render Env Vars |
|--------|---------------|----------|--------------|-----------------|
| `NVIDIA_API_KEY` | ❌ Never | ❌ Never | ❌ Never | ✅ Only here |
| `LITELLM_MASTER_KEY` | ✅ In shell profile | ❌ Never | ❌ Never | ✅ Here too |

### Security Checklist
- [ ] `NVIDIA_API_KEY` only in Render environment variables
- [ ] `LITELLM_MASTER_KEY` only in Render env vars + local shell profile
- [ ] `.env` files in `.gitignore`
- [ ] Dockerfile does not copy `.env` or bake secrets
- [ ] `config.yaml` uses `os.environ/` for all secrets
- [ ] Proxy requires authentication (`master_key` configured)
- [ ] Rate limits configured (`rpm`, `tpm`)
- [ ] Health endpoints public, completion endpoints private
- [ ] HTTPS enforced (Render provides TLS)

### Remaining Risks
- **Render Free cold starts**: 15-min inactivity → 30-60s cold start
- **Public internet exposure**: Proxy URL is public; protect `LITELLM_MASTER_KEY`
- **NVIDIA API quota**: Monitor usage at [build.nvidia.com](https://build.nvidia.com)
- **Leaked master key**: Rotate immediately in Render + local config
- **NVIDIA model availability**: Models may change; check [build.nvidia.com](https://build.nvidia.com) periodically
- **Claude Code compatibility**: Verify `ANTHROPIC_BASE_URL` works with your version
- **Render Free limits**: 512MB RAM, 750 hrs/month, no persistent storage

---

## Configuration Reference

### Model Aliases (config.yaml)
| Alias | NVIDIA Model | Use Case |
|-------|--------------|----------|
| `nvidia-coding` | `nvidia/llama-3.3-nemotron-super-49b-v1.5` | General coding, reasoning |

### Available NVIDIA Models (check [build.nvidia.com](https://build.nvidia.com) for current list)
- `nvidia/llama-3.3-nemotron-super-49b-v1.5` - Best single-GPU reasoning/coding
- `nvidia/llama-3.1-nemotron-ultra-253b-v1` - Maximum accuracy (multi-GPU)
- `nvidia/nemotron-3-ultra` - Latest hybrid MoE, 1M context
- `meta/llama-3.1-405b-instruct` - Large open model
- `mistralai/mixtral-8x22b-instruct` - MoE model

Update `config.yaml` model field to switch models.

### Rate Limits
Default in `config.yaml`:
- `rpm: 60` (requests per minute)
- `tpm: 100000` (tokens per minute)

Adjust based on your NVIDIA API quota.

---

## Troubleshooting

### Container won't start
```bash
docker logs litellm-proxy
# Check for: missing env vars, config syntax errors, port conflicts
```

### 401 Unauthorized
- Verify `LITELLM_MASTER_KEY` matches in Render and local config
- Key must start with `sk-`

### 502/503 from NVIDIA
- Check NVIDIA API status
- Verify `NVIDIA_API_KEY` is valid and has quota
- Model may be temporarily unavailable

### Claude Code connects but errors
- Verify `ANTHROPIC_BASE_URL` ends with no trailing slash
- Check proxy logs: `docker logs litellm-proxy` or Render logs
- Ensure model name matches `model_name` in config.yaml

---

## License
MIT - Use at your own risk. Monitor your NVIDIA API quota.