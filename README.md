# 🥷 LogNinja

A fast, interactive PowerShell tool for analyzing Windows Event Logs.
Scans all system journals, groups errors by source and process name,
and generates a ready-to-use report for AI assistants.

---

## ⚡ Quick Start (no installation needed)

Run directly from PowerShell as **Administrator**:

```powershell
irm https://raw.githubusercontent.com/m1nuzz/LogNinja/main/LogNinja.ps1 | iex
```

If you get an Execution Policy error (running scripts is disabled), use this command instead:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/m1nuzz/LogNinja/main/LogNinja.ps1 | iex"
```

---

## 🌐 Supported Languages

| # | Language     | Code |
|---|--------------|------|
| 1 | English      | en   |
| 2 | Українська   | uk   |
| 3 | Русский      | ru   |
| 4 | 日本語        | ja   |
| 5 | 中文          | zh   |

> English is built into the script — no extra files needed.
> Other languages are loaded automatically from the `lang/` folder or downloaded from GitHub.

---

## 🔍 What it does

1. Asks you to select a language
2. Asks what to look for: **Errors only**, **Errors + Warnings**, or **Everything**
3. Asks for a time period: seconds / hours / **days** / weeks / years
4. Scans **all** Windows Event Log journals (400+)
5. Groups results by source and extracts related `.exe` process names
6. Displays a clean summary table in the terminal
7. Press **`CTRL`** to copy a full AI-ready report to clipboard — paste it into ChatGPT, Perplexity or Claude

---

## 🖥️ Example Output

```text
=========================================
               🥷 LogNinja
=========================================

Count EventID Source                              Process
----- ------- ------                              -------
 1034    5858 Microsoft-Windows-WMI-Activity      svchost.exe [WMI: MSFT_NetAdapter]
  692    3033 Microsoft-Windows-CodeIntegrity     chrome.exe
    3     703 Service Control Manager             Unknown/System

=========================================
Press CTRL to copy the full report for AI (any other key to exit)...
[✓] Report copied to clipboard! Paste it into ChatGPT, Perplexity or Claude.
```

---

## 📁 Project Structure

```text
LogNinja/
├── LogNinja.ps1       # Main script (English hardcoded)
└── lang/
    ├── ru.json        # Russian
    ├── uk.json        # Ukrainian
    ├── ja.json        # Japanese
    └── zh.json        # Chinese (Simplified)
```

---

## 🔧 Local Usage

Clone the repo and run the script directly:

```powershell
git clone https://github.com/m1nuzz/LogNinja.git
cd LogNinja
.\LogNinja.ps1
```

> If you get an ExecutionPolicy error running it locally, run:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\LogNinja.ps1
> ```

---

## 🌍 Adding a New Language

1. Copy `lang/en.json` (structure reference) from the repo
2. Translate all **values** (do **not** change the keys)
3. Keep `{0}` and `{1}` placeholders intact
4. Keep `[LogNinja]` tag in English
5. Save as `lang/XX.json` (e.g. `de.json` for German) in **UTF-8** encoding
6. Add the language option to the selection menu in `LogNinja.ps1`

Pull requests with new translations are welcome! 🎉

---

## ⚠️ Requirements

- Windows 10 / 11
- PowerShell 5.1+ or PowerShell 7+
- **Run as Administrator** (required to access all Event Log journals)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
