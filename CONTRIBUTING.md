# Contributing to mac-dev-cleanup

Thanks for your interest in contributing! This project is made for developers, by developers. Whether you're fixing a bug, suggesting a new cleanup rule, or just improving the docs — you're welcome here.

---

## 🙋‍♂️ How to Contribute

1. **Fork the repository** and create a new branch:

   ```bash
   git checkout -b your-feature-name
   ```

2. **Make your changes** to `mac-dev-cleanup.sh`, `README.md`, or the config structure.

3. **Test your changes** locally:

   - Run the script and verify that your additions behave as expected.
   - Check output and confirmation prompts.
   - Test with both default and custom config files.

4. **Open a pull request** with a clear description of what you changed and why.

---

## 🧠 Contribution Ideas

- New directory cleanup sections (e.g. for specific tools like React Native, Flutter, etc.)
- Safety improvements and additional path validations
- Refactoring for maintainability
- Dry-run or logging options
- Documentation enhancements
- Additional tool integrations (e.g., npm, pip, etc.)
- Performance optimizations for large directories
- Automated testing framework
- CI/CD pipeline improvements

---

## ➕ How to Add a New Cleanup Section

To add a new cleanup section:

1. **Define a new section** in the config file (e.g. `my_custom_cleanup`):

```json
"my_custom_cleanup": [
  {
    "path": "~/Library/Caches/MyTool",
    "description": "MyTool Cache",
    "enabled": true
  }
]
```

2. **Update `mac-dev-cleanup.sh`**:

   - Add a new function for your cleanup section following the existing pattern
   - Implement proper safety checks using `is_safe_path`
   - Add size reporting using `print_size`
   - Include interactive confirmation using `confirm`
   - Add the new function call to the main cleanup sequence
   - Use the existing color-coded logging system

3. **Test** the section with both the default and custom config files.

4. **Update the README** with a brief description if it's a widely-used tool.

---

## ✅ Code Guidelines

- Follow the existing code style (functions, spacing, naming)
- Prefer clarity over cleverness
- Always guard against deleting important directories
- Use the provided utility functions for logging and safety checks
- Implement proper error handling and user feedback
- Add comments for non-obvious logic
- Keep functions focused and single-purpose
- Use consistent naming conventions:
  - camelCase for variables and functions
  - UPPER_CASE for constants
  - descriptive names for clarity

---

## 🧪 Testing Checklist

Before submitting your contribution, please make sure:

- [ ] The script runs without errors on your machine
- [ ] Your changes do not modify or remove critical paths
- [ ] You've tested your cleanup section with a realistic config
- [ ] Interactions (confirmation prompts, info messages) behave as expected
- [ ] You didn't introduce hardcoded paths or system-dependent logic
- [ ] Your code is commented if it includes non-obvious logic
- [ ] README or example config has been updated if needed
- [ ] All safety checks are properly implemented
- [ ] Size reporting works correctly for your new section
- [ ] Error handling is comprehensive
- [ ] The script handles missing dependencies gracefully

---

## 📬 Questions or Suggestions?

Open an issue or start a discussion — we're happy to help or brainstorm improvements together.

---

Thanks again for contributing! 💪
