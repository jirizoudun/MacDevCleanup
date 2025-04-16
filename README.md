# 🧹 mac-cleanup

A safe, interactive disk space cleanup tool for macOS developers.

This open-source Bash script helps you identify and remove stale caches, build artifacts, simulator remnants, and other development leftovers—_without risking your personal files or system stability._

> Built for developers who want to keep control of their environment without running random one-liners from Stack Overflow.

---

## ✨ Features

- 🧠 Smart safety checks to avoid dangerous paths (e.g., `/`, `~/Documents`, etc.)
- 🔧 Customizable config via `~/.mac-cleanup-config.json` or a local file
- 📁 Targets iOS and Android development artifacts, caches, archives, and more
- 🧼 Interactive prompts before deleting anything
- 🗂 Configurable keep-count for simulators, build tools, platforms
- ✅ Dependency-aware (warns if `jq`, `brew`, or `pod` are missing)
- 💬 Colored output and human-friendly messages

---

## 📦 Installation

There’s no installation — just clone and run:

```bash
git clone https://github.com/yourusername/mac-cleanup.git
cd mac-cleanup
chmod +x mac-cleanup.sh
./mac-cleanup.sh
```

---

## ⚙️ Configuration

On first run, the script will offer to create a default config file at:

```
~/.mac-cleanup-config.json
```

Or you can provide your own:

```bash
./mac-cleanup.sh ./my-cleanup-config.json
```

The config allows you to enable/disable individual cleanup sections, set how many versions to keep, and even add your own custom directories.

Example snippet:

```json
{
  "cache_directories": [
    {
      "path": "~/Library/Caches/Yarn",
      "description": "Yarn Package Manager Cache",
      "enabled": true
    }
  ],
  "device_support": {
    "clean_ios_device_support": true,
    "keep_latest_ios_versions": 2
  }
}
```

---

## 🛡️ Safety by Design

This script is built with safety as the top priority:

- **No deletions without confirmation**
- **Hardcoded protection against critical paths**
- **All removals are scoped to user-writable directories**
- **Visual inspection (size, listing) before actions**

---

## 🧪 Requirements

- `bash` (pre-installed on macOS)
- [`jq`](https://stedolan.github.io/jq/) (install with `brew install jq`)
- Optional: `xcrun`, `brew`, `pod` if using related cleanup sections

---

## 💡 Use Cases

- Reclaim space from old iOS simulator data
- Clear stale Android SDK versions
- Clean out years-old caches from various tools
- Automate environment hygiene across your dev team

---

## 🧹 Extending the Script

You can define your own cleanup targets by adding a `custom_directories` section to the config:

```json
"custom_directories": [
  {
    "path": "~/Projects/tmp",
    "description": "Temporary project dumps",
    "enabled": true
  }
]
```

Want to contribute a new cleanup section? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📜 License

MIT License — do whatever you want, but don’t blame us if you delete your thesis. The script includes safeguards, but you’re still responsible for using it wisely.

---

## 🤝 Contributing

Pull requests are welcome! Ideas, improvements, new cleanup strategies, and hardening suggestions are all encouraged. Please check open issues before submitting a new one.

---

## 🙏 Credits

Created and maintained by developers who got tired of gigabytes of derived data.
