---
name: unsloth-custom-llm-for-power-platform
description: Fine-tune an open model with Unsloth (LoRA / QLoRA) on your own business data, serve it behind an OpenAI-compatible endpoint (vLLM, Ollama, llama.cpp), and call it safely from Power Automate, a canvas app or a Power Apps code app through a custom connector — with data preparation from Dataverse, evaluation, licensing, DLP, the 120-second timeout and ALM. Use when someone asks to train or fine-tune their own model, use Unsloth, classify/extract/summarise with a private model, or connect a self-hosted LLM to Power Platform; also use it to decide whether AI Builder or Copilot Studio is enough instead.
---

# Custom fine-tuned LLM (Unsloth) for Power Platform

## Purpose
- **What it does:** the full path from "we have examples in Dataverse" to "a flow or app calls our own model": decide if fine-tuning is justified, prepare data, train with Unsloth, evaluate, export, host, and integrate through a governed custom connector.
- **When to use it:** repeated, narrow tasks with a clear right answer (classify support emails, extract fields from documents, write replies in a house style) where built-in AI is too costly, too generic, or data must stay on your infrastructure.
- **Expected outcome:** a measured model (beats the baseline on a held-out set), hosted behind an authenticated endpoint, called from Power Platform via a solution-aware custom connector with env vars and connection references.

## Expertise
- **Architects** try the built-in options first — **AI Builder prompts**, Copilot Studio, Azure AI Foundry models — because they're governed, supported and need no GPU. Fine-tune only when a measured gap remains.
- **ML engineers** know fine-tuning teaches *format and behaviour*, not fresh facts; facts belong in retrieval (RAG) over Dataverse/SharePoint.
- **Unsloth** (open source) speeds up LoRA/QLoRA fine-tuning and lowers VRAM; the project claims about 2× faster training with ~70% less VRAM and no accuracy loss, varying by model **[Unsloth]**. It ships a code library (Unsloth Core) and a local web UI (Unsloth Studio) with data recipes, chat, export and an OpenAI-compatible API **[Unsloth]**.
- **Power Platform specialists** never let a flow or app call a model endpoint without a connector, env vars, DLP review and a timeout plan.

## Instructions

### Design approach
1. **Decide** with a 50–200-example baseline test:
   | Result of the test | Choose |
   |---|---|
   | AI Builder prompt / Copilot Studio meets the bar | Stop — use built-in AI |
   | Quality OK but cost/latency/data-residency is not | Fine-tune a small model (e.g. 1–8B) |
   | Needs company facts that change | RAG, not fine-tuning |
2. **Architecture:**
   ```
   Dataverse (examples) → export + anonymise → JSONL → Unsloth training (GPU VM / notebook)
   → evaluate on held-out set → export (merged 16-bit for vLLM, or GGUF for Ollama/llama.cpp)
   → host behind HTTPS + Entra ID (e.g. Azure Container Apps / AKS GPU + API Management)
   → custom connector (in its own solution) → flow / canvas app / code app (via flow or connector)
   ```
3. **Code apps** can't `fetch` your endpoint directly (CSP `connect-src 'none'`) **[Microsoft]**; call it through the custom connector as a data source or through a cloud flow added to the app (`power-apps add-flow`).

### Development standards
- **Data preparation**
  - Pull only the columns needed; remove names, emails, phone numbers, account numbers (or replace with placeholders) **before** the data leaves Dataverse.
  - One example per line (JSONL), instruction/input/output or chat messages. Split **train / validation / test** (e.g. 80/10/10) by time or customer so test data is truly unseen.
  - Balance classes; keep a "none of these" class for classifiers.
- **Install (Unsloth Core)** **[Unsloth README]**:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  uv venv unsloth_env --python 3.13 && source unsloth_env/bin/activate
  uv pip install unsloth --torch-backend=auto
  ```
  (Windows: install `torchao` first. Studio: `unsloth studio`, default port 8888.)
- **Train (from the official Llama 3.1 8B Alpaca notebook)** **[Unsloth notebooks]**:
  ```python
  from unsloth import FastLanguageModel
  model, tokenizer = FastLanguageModel.from_pretrained(
      model_name = "unsloth/Llama-3.1-8B",
      max_seq_length = 2048, dtype = None, load_in_4bit = True)   # QLoRA
  model = FastLanguageModel.get_peft_model(
      model, r = 16, lora_alpha = 16, lora_dropout = 0, bias = "none",
      target_modules = ["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"],
      use_gradient_checkpointing = "unsloth", random_state = 3407)

  from trl import SFTConfig, SFTTrainer
  trainer = SFTTrainer(
      model = model, tokenizer = tokenizer, train_dataset = dataset,
      dataset_text_field = "text", max_seq_length = 2048,
      args = SFTConfig(per_device_train_batch_size = 2, gradient_accumulation_steps = 4,
                       warmup_steps = 5, num_train_epochs = 1, learning_rate = 2e-4,
                       optim = "adamw_8bit", weight_decay = 0.001, lr_scheduler_type = "linear",
                       seed = 3407, output_dir = "outputs", report_to = "none"))
  trainer.train()
  ```
  Every formatted example must end with `tokenizer.eos_token`, or generation won't stop **[Unsloth notebooks]**. Library versions move quickly (TRL argument names change); pin versions in `requirements.txt` and re-check the current notebook.
- **Export** **[Unsloth notebooks]**:
  ```python
  model.save_pretrained("cr123_classifier_lora"); tokenizer.save_pretrained("cr123_classifier_lora")  # adapter only
  model.save_pretrained_merged("cr123_classifier_16bit", tokenizer, save_method = "merged_16bit")    # for vLLM
  model.save_pretrained_gguf("cr123_classifier", tokenizer, quantization_method = "q4_k_m")          # for Ollama / llama.cpp
  ```
- **Serve with an OpenAI-compatible API** (check each tool's current docs): vLLM (`vllm serve <model-dir>` → `/v1/chat/completions`), Ollama (`/v1/` compatibility endpoint), or Unsloth Studio's own OpenAI-compatible API for local testing **[Vendor docs]**.
- **Prompt contract:** low temperature (0–0.2) for classification/extraction; ask for JSON with a fixed schema; validate the JSON in the flow (`Parse JSON` + a fallback branch).

### Evaluation (before any integration)
- Metrics on the **test** split: accuracy / F1 per class for classifiers, exact-match per field for extraction, human rating for writing tasks.
- Compare against the baseline (AI Builder prompt or base model). Ship only if it is better on the metric that matters.
- Keep a regression set of ~50 tricky examples and re-run it for every new model version.

### Governance and DLP
- Custom connectors and HTTP are often blocked or "Non-business" in DLP; ask the admin for a **URL-pattern rule** for your endpoint host **[Microsoft]**.
- Training data from Dataverse is company data: data owner approval, retention plan, and no customer personal data unless lawful and necessary.
- Record model card: base model, licence, data used, date, metrics, owner.

### Security
- Endpoint protected by **Entra ID OAuth** (custom connector OAuth 2.0) or an API key held in the **connection**, never in a flow definition, canvas formula or code app bundle.
- Put API Management (or similar) in front: auth, rate limits, logging, IP restrictions.
- Treat model output as untrusted input: validate before writing to Dataverse; never execute it.

### Performance
- Power Automate **synchronous outbound timeout is 120 seconds** **[Microsoft]**. Keep requests short (classification, short extraction) or use the async pattern (`202 Accepted` + `Location`, then poll).
- Custom connector limit: 10,000 requests per minute per connection **[Microsoft]**; your GPU is usually the real limit — size it, queue work, and set `max_tokens`.
- Batch nightly work instead of one call per record during the day where possible.

### ALM
- Training code, data-prep scripts, pinned `requirements.txt`, eval set and model card in Git; model files in a model registry or storage (not Git).
- Version the endpoint (`/v1/models/cr123-classifier-2026-11`) so flows can move version by version.
- **Custom connector in its own solution, imported before** the solution with flows and connection references **[Microsoft]**. Endpoint base URL as an environment variable (use the connector's *Set Host URL* policy or per-environment connector definitions).

### Licensing
- **Unsloth:** core package Apache 2.0; Unsloth Studio UI and some optional components AGPL-3.0 **[Unsloth README]** — check obligations before embedding Studio in a product.
- **Base model:** each has its own licence (e.g. Llama community licence, Gemma terms, Apache 2.0 for some Qwen models) — check commercial-use terms.
- **Power Platform:** custom connectors and HTTP are **premium** — users/flows need premium licences **[Microsoft]**.
- **Hosting:** GPU compute cost; compare with AI Builder credits / Azure AI per-token pricing.

## Examples

### Beginner — try it locally
Install Unsloth Studio, load 200 anonymised examples, fine-tune a small model, chat with it, compare answers against an AI Builder prompt on 20 test cases. No Power Platform integration yet.

### Intermediate — classify support emails in a flow
Train a classifier (categories + "other"), serve with vLLM behind API Management, custom connector `Contoso Classifier` (OAuth), flow: new email → connector → `Parse JSON` → write `cr123_category` + `cr123_confidence`; low confidence → human queue.

### Advanced (enterprise) — governed model lifecycle
Monthly retrain pipeline (data export with anonymisation → train → eval gate vs regression set → register → deploy new versioned endpoint in TEST → flows in TEST switch via env var → sign-off → PROD env var update). Dashboards for latency, errors, confidence drift. Custom connector solution imported first; DLP URL-pattern rule for the host.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Fine-tuning to add facts | Confident wrong answers when facts change | RAG for facts, fine-tune for format |
| No held-out test set | Overfitting not noticed | Train/validation/test split |
| Missing EOS token in training text | Model keeps generating | Append `tokenizer.eos_token` |
| API key in a flow or app | Key leaks to anyone with access | Key in the connection or OAuth |
| Long generations from a flow | 120 s timeout failures | Short outputs or async pattern |
| Custom connector shipped with its flows on first import | Import fails | Separate connector solution, imported first |
| Ignoring base-model licence | Commercial-use breach | Check licence before training |

## Validation checklist
### Security
- [ ] Endpoint behind Entra ID / API Management; secrets only in connections
- [ ] Training data anonymised and approved
### Performance
- [ ] p95 latency measured and well under 120 s, or async pattern used
- [ ] GPU capacity and rate limits sized
### ALM
- [ ] Code, pinned deps, eval set, model card in Git; model versioned
- [ ] Endpoint URL in an environment variable
### Solution packaging
- [ ] Custom connector in its own solution; connection references for flows
### Deployment readiness
- [ ] Model beats the baseline on the test set; regression set passes
- [ ] DLP rule for the endpoint host approved; licences confirmed

## References
- [Unsloth] [GitHub repository and licence](https://github.com/unslothai/unsloth)
- [Unsloth] [Official notebooks (Llama 3.1 8B Alpaca)](https://github.com/unslothai/notebooks)
- [Microsoft] [Power Automate request limits (120 s timeout)](https://learn.microsoft.com/power-automate/limits-and-config#request-limits)
- [Microsoft] [Custom connectors in solutions](https://learn.microsoft.com/connectors/custom-connectors/customconnectorssolutions)
- [Microsoft] [Custom connector FAQ (limits)](https://learn.microsoft.com/connectors/custom-connectors/faq)
- [Microsoft] [Data policies for custom connectors](https://learn.microsoft.com/power-platform/admin/dlp-custom-connector-parity)
- [Microsoft] [Code apps CSP](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/content-security-policy)
