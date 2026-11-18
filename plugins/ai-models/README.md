# ai-models plugin

Custom AI models for business apps: fine-tune with Unsloth, serve behind an OpenAI-compatible endpoint, and call it from Power Platform through a governed custom connector.

## Skills
- [`unsloth-custom-llm-for-power-platform`](skills/unsloth-custom-llm-for-power-platform/)

## Install

```
/plugin marketplace add bilalshabbir123/power-platform-claude-skills
/plugin install ai-models@power-platform-claude-skills
```

## Test

```bash
claude plugin eval plugins/ai-models --runs 1 --no-publish
```
