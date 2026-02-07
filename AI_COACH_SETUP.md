# 🤖 AI Coach Setup Guide

## Quick Start (5 minutes)

### Step 1: Get Your FREE Gemini API Key

1. Go to **[Google AI Studio](https://aistudio.google.com/apikey)**
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key (starts with `AIzaSy...`)

### Step 2: Add Your API Key

Open the file: `lib/core/services/ai_coach_service.dart`

Find this line (around line 18):
```dart
static const String _apiKey = 'AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxx';
```

Replace it with YOUR key:
```dart
static const String _apiKey = 'AIzaSyB_YOUR_REAL_KEY_HERE';
```

### Step 3: Hot Reload

Press `r` in your Flutter terminal or hot reload from your IDE.

---

## What The AI Coach Can Do

| Feature | Description |
|---------|-------------|
| 🏃 **Today's Run** | "Quelle course aujourd'hui?" |
| 📅 **Next Event** | "Quel est le prochain événement?" |
| 👥 **My Group** | "Parle-moi de mon groupe" |
| 💪 **Motivation** | "Donne-moi un conseil" |
| 🎤 **Voice Input** | Tap the mic button to speak |

---

## Files Added

| File | Purpose |
|------|---------|
| `lib/core/services/ai_coach_service.dart` | Gemini AI integration |
| `lib/core/widgets/ai_coach_widget.dart` | Chat UI component |

---

## Security Note

For production, store API keys securely:
- Use `flutter_dotenv` for .env files
- Or use Firebase Remote Config
- Never commit API keys to public repos!

---

## Troubleshooting

### "AI Coach not initialized"
- Check your API key is valid
- Ensure internet connection

### Voice input not working
- Grant microphone permissions
- Check `speech_to_text` initialization

### Slow responses
- Gemini 1.5 Flash is optimized for speed
- If still slow, check network

---

## Hackathon Demo Tips 🏆

1. **Have pre-planned questions ready** - Show off the smartest responses
2. **Demo voice input** - It's more impressive than typing
3. **Show event context** - AI knows your user's group and upcoming events
4. **Highlight multilingual** - Works in French, Arabic, and English!

Good luck! 🚀
