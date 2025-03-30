# Termux AI Assistant 🤖

[![Termux](https://img.shields.io/badge/Termux-Compatible-brightgreen)](https://termux.com)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![Models](https://img.shields.io/badge/Models-10_free-orange)](https://openrouter.ai)

> **Access 10 cutting-edge AI models directly in your Termux terminal**

![Demo Animation](assets/demo.gif)

## 🌟 Features
- **10 Free Models** from leading AI providers
- **No Root Required** works on standard Termux
- **Encrypted API Key** storage
- **Conversation History** with timestamp
- **Model Comparison** tool built-in

## 📦 Installation Methods

### Method 1: Direct Install (Recommended)
```bash
curl -sL https://is.gd/Termux_Ai | bash
```

### Method 2: Termux Repository
```bash
pkg install termux-ai
```

*Repository URL:* `https://Anon4You.github.io/alienkrishn`

## 🧠 Available Models

| Model ID | Provider | Parameters | Best For |
|----------|----------|------------|----------|
| `deepseek-r1` | Deepseek | 7B | General queries |
| `qwen2.5-vl-32b` | Alibaba | 32B | Multimodal tasks |
| `gemma-3-27b` | Google | 27B | Fast responses |
| `mistral-small` | Mistral | 24B | Instructions |
| `gemini-pro2.5` | Google | Experimental | Creative writing |
| `meta-llama` | Meta | 8B | Coding help |
| `qwerky-72b` | Featherless | 72B | Complex reasoning |
| `allen-ai` | AllenAI | 7B | Scientific research |
| `deephermes` | NousResearch | 8B | Roleplaying |
| `rogue-rose` | Sophosympatheia | 103B | Detailed analysis |

## 🚀 Basic Usage

1. **First Run Setup**:
   ```bash
   termux-ai
   ```
   - Select option `2` → `1` to set your OpenRouter API key
   - Get free key: https://openrouter.ai/keys

2. **Start Chatting**:
   - Choose option `1` from main menu
   - Type your message and press Enter
   - Type `exit` to end session

3. **Switch Models**:
   - Menu → Settings → Model Selection
   - Use number keys to choose model

## 📚 Advanced Usage

### View History
```bash
cat ~/.config/termux_assistant/history
```

# Export conversation
```
cp ~/.config/termux_assistant/history ./my_chat.txt
```

## 🔧 Troubleshooting

**Common Issues**:
- `API Error`: Verify key at https://openrouter.ai/keys
- `Model Unavailable`: Try a different model
- `Install Failed`: Run `pkg update` before installing

**Error Codes**:
- `101`: Network connection issue
- `202`: Invalid API key
- `303`: Model timeout

## ❓ FAQ

**Q: How to update?**  
```bash
pkg upgrade termux-ai
```

**Q: Where are configs stored?**  
`~/.config/termux_assistant/`

**Q: Can I use paid models?**  
Yes - fund your OpenRouter account

## 📚 Documentation

For advanced usage and troubleshooting, visit:  
[Termux AI Wiki](https://github.com/Anon4You/Termux-Ai/wiki)

---

💡 **Pro Tip**: Use `termux-notification` to get AI alerts!  
📆 **Last Updated**: June 2024  
🐛 **Report Issues**: https://github.com/Anon4You/Termux-Ai/issues
