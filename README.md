# 🧹 mac-dev-cleanup

A safe, interactive disk space cleanup tool for macOS developers.

This open-source Bash script helps you identify and remove stale caches, build artifacts, simulator remnants, and other development leftovers—_without risking your personal files or system stability._

> Built for developers who want to keep control of their environment without running random one-liners from Stack Overflow.

## ⚠️ Important Warning

**This script does not guarantee the safety of your data.** It is designed for experienced developers who:

- Understand what each cleanup step does
- Know the implications of deleting development artifacts
- Can assess the impact on their development environment
- Are familiar with the directories being cleaned

Due to its configurability, the script:

- Cannot handle all potentially risky cases
- Is not designed to be fool-proof
- May have unintended consequences if misconfigured
- Requires careful review of the directories being targeted

**Always review the configuration and understand what will be deleted before running the script.**

---

## ✨ Features

- 🧠 Smart safety checks to avoid dangerous paths (e.g., `/`, `~/Documents`, etc.)
- 🔧 Customizable config via `~/.mac-dev-cleanup-config.json` or a local file
- 📁 Targets iOS and Android development artifacts, caches, archives, and more
- 🧼 Interactive prompts before deleting anything
- 🗂 Configurable keep-count for simulators, build tools, platforms
- ✅ Dependency-aware (warns if `jq`, `brew`, `pod`, or `xcrun` are missing)
- 💬 Colored output and human-friendly messages
- 🔍 Size reporting for directories before cleanup
- 🛡️ Path validation and user confirmation for external directories
- 🔄 Dry-run mode to preview changes without actual deletion

---

## 📦 Installation

There's no installation — just clone and run:

```bash
git clone https://github.com/jirizoudun/MacDevCleanup.git
cd mac-dev-cleanup
chmod +x mac-dev-cleanup.sh
./mac-dev-cleanup.sh
```

---

## ⚙️ Configuration

On first run, the script will offer to create a default config file at:

```
~/.mac-dev-cleanup-config.json
```

Or you can provide your own:

```bash
./mac-dev-cleanup.sh ./my-cleanup-config.json
```

You can also run in dry-run mode to preview changes without actually deleting anything:

```bash
./mac-dev-cleanup.sh --dry-run
# or with a custom config
./mac-dev-cleanup.sh --dry-run ./my-cleanup-config.json
```

The config allows you to enable/disable individual cleanup sections, set how many versions to keep, and even add your own custom directories.

Example snippet:

```json
{
  "cache_directories": [
    {
      "path": "~/Library/Caches/Google",
      "description": "Google Cache (Chrome, etc.)",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/Yarn",
      "description": "Yarn Package Manager Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/org.swift.swiftpm",
      "description": "Swift Package Manager Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/typescript",
      "description": "TypeScript Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/Arc",
      "description": "Arc Browser Cache",
      "enabled": true
    }
  ],
  "developer_directories": [
    {
      "path": "~/Library/Developer/CoreSimulator/Caches",
      "description": "iOS Simulator Caches",
      "enabled": true
    },
    {
      "path": "~/Library/Developer/Xcode/DerivedData",
      "description": "Xcode Derived Data",
      "enabled": true
    },
    {
      "path": "~/Library/Developer/Xcode/Archives",
      "description": "Xcode Archives",
      "enabled": false
    },
    {
      "path": "~/Library/Developer/XCPGDevices",
      "description": "Xcode Testing Devices",
      "enabled": true
    }
  ],
  "application_support_directories": [
    {
      "path": "~/Library/Application Support/Caches",
      "description": "Application Support Cache Folder",
      "enabled": true
    },
    {
      "path": "~/Library/Application Support/Google",
      "description": "Google Application Data",
      "enabled": false
    }
  ],
  "android_directories": [
    {
      "path": "~/.android/cache",
      "description": "Android Cache",
      "enabled": true
    },
    {
      "path": "~/.gradle/caches",
      "description": "Gradle Cache",
      "enabled": true
    }
  ],
  "device_support": {
    "clean_ios_device_support": true,
    "keep_latest_ios_versions": 2,
    "clean_macos_device_support": true,
    "keep_latest_macos_versions": 1
  },
  "android_sdk": {
    "clean_build_tools": true,
    "clean_platforms": true,
    "clean_system_images": true
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
- Manage iOS and macOS device support files
- Clean up Android build tools and system images
- Remove old Xcode archives and derived data

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

MIT License — do whatever you want, but don't blame us if you delete your thesis. The script includes safeguards, but you're still responsible for using it wisely.

---

## 🤝 Contributing

Pull requests are welcome! Ideas, improvements, new cleanup strategies, and hardening suggestions are all encouraged. Please check open issues before submitting a new one.

---

## 🙏 Credits

Created and maintained by developers who got tired of gigabytes of derived data.
