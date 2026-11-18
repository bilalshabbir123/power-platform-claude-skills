# Custom fine-tuned LLM (Unsloth) — summary

Read this when the request involves training or calling your own model from Power Platform. Full detail: skill **`unsloth-custom-llm-for-power-platform`** (plugin `ai-models`).

- Try AI Builder prompts / Copilot Studio first; fine-tune only for a measured gap (format, cost, data residency). Facts → RAG.
- Unsloth (core Apache 2.0, Studio AGPL-3.0) trains LoRA/QLoRA adapters; export merged 16-bit for vLLM or GGUF for Ollama **[Unsloth]**.
- Host behind HTTPS + Entra ID / API Management with an OpenAI-compatible API.
- Call from Power Platform via a **custom connector** in its own solution (imported first); endpoint URL in an env var; DLP URL-pattern rule **[Microsoft]**.
- Flows time out after 120 s on synchronous calls — keep outputs short or go async **[Microsoft]**.
- Code apps can't fetch the endpoint directly (CSP) — use the connector or a flow.
