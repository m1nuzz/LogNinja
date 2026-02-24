Clear-Host

$aiInstructionsEN = @"
---
INSTRUCTIONS FOR AI ASSISTANT:
The report below is sorted by Count (descending) — the highest Count means the most frequent error.
Your task:
1. START with the top errors by Count. These are the most critical — focus here first.
2. USE WEB SEARCH: Actively use your internet search tools to look up the exact error codes, Event IDs, and processes (taking into account the provided OS Version). Do not rely solely on your internal knowledge.
3. For each top error: explain the ROOT CAUSE and provide a CONCRETE FIX (registry key, PowerShell command, etc.) based on current up-to-date search results.
4. DO NOT start with a general summary. Start immediately with the #1 most frequent error.
5. DO NOT say "this is normal background behavior" for high-count errors without offering a fix first.
6. Group errors only if they share the exact same root cause and fix.
7. FORMAT YOUR RESPONSE like this:
   1. (62+31+31 = 124 events): Microsoft Account / NGC key failure chain
   2. (43 events): WMI 5858 — ResultCode 0x80041032
   Include the count in parentheses, then a short descriptive title, then the detailed explanation and fix.
---

"@

# --- DEFAULT ENGLISH LANGUAGE PACK (HARDCODED) ---
$defaultLang = @{
    Header = "🥷 LogNinja"
    PromptSeverity = "What should we look for?"
    Severity1 = "1 - Only Errors (Critical) [Default]"
    Severity2 = "2 - Errors and Warnings"
    Severity3 = "3 - Everything (Including Info)"
    InputSeverity = "Enter a number (1-3) or press Enter"
    DefaultSeverity = "Selected default: Errors"
    
    PromptUnit = "What period to scan?"
    Unit1 = "1 - Seconds"
    Unit2 = "2 - Minutes"
    Unit3 = "3 - Hours"
    Unit4 = "4 - Days [Default]"
    Unit5 = "5 - Weeks"
    Unit6 = "6 - Years"
    Unit7 = "7 - Since last boot"
    InputUnit = "Enter a number (1-7) or press Enter"
    
    PromptValue = "Enter amount (default: 1)"
    
    PrepLogs = "[LogNinja] Preparing shurikens (collecting log list)..."
    ScanStart = "[LogNinja] Scanning system since {0}..."
    ProgressActivity = "LogNinja Scanner"
    ProgressStatus = "Searching in: {0}"
    
    ResultHeader = "================ RESULTS ================"
    SystemClean = "System is clean! No errors found."
    AiReportTitle = "### LogNinja System Report"
    AiReportScanDates = "Scan from {0} to {1}"
    AiReportTotal = "Total events found: {0}"
    ProcessUnknown = "Unknown/System"
    SourceSource = "Source"
    LogLog = "Log"
    ProcessProcess = "Process"
    CountCount     = "Count"
    EventIdLabel   = "EventID"
    AiInstructions = $aiInstructionsEN
    
    AiSource = "🔴 Source: {0} | Count: {1}"
    AiLog = "   Log: {0} | Event ID: {1}"
    AiProcess = "   Related processes: {0}"
    AiError = "   Example error: {0}"
    
    CopyPrompt = "Press CTRL to copy the full report for AI (any other key to exit)..."
    CopySuccess = "[✓] Report copied to clipboard! Paste it into ChatGPT, Perplexity or Claude."
    ExitMsg = "[LogNinja] Exiting..."
}

# --- LANGUAGE SELECTION BLOCK ---
# GitHub raw base URL for lang files (auto-detected if running from GitHub)
$githubBase = "https://raw.githubusercontent.com/m1nuzz/LogNinja/main/lang"

# Detect if running via iex (Invoke-Expression) or locally
# $PSScriptRoot is empty when script runs via iex (no file on disk)
$isIex = [string]::IsNullOrWhiteSpace($PSScriptRoot)

# Language selection UI
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "               🥷 LogNinja                 " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select Language / Оберіть мову / Выберите язык / 选择语言 / 言語を選択:" -ForegroundColor Yellow
Write-Host "1 - English (en) [Default]"
Write-Host "2 - Українська (uk)"
Write-Host "3 - Русский (ru)"
Write-Host "4 - 日本語 (ja)"
Write-Host "5 - 中文 (zh)"
$inputLang = Read-Host "Enter a number (1-5) or press Enter"

$langCode = "en"
switch ($inputLang) {
    "2" { $langCode = "uk" }
    "3" { $langCode = "ru" }
    "4" { $langCode = "ja" }
    "5" { $langCode = "zh" }
}

# Load language: English is hardcoded, others from local file or GitHub
if ($langCode -eq "en") {
    $L = [PSCustomObject]$defaultLang
} else {
    if ($isIex) {
        # Running via iex - download lang JSON directly from GitHub
        try {
            Write-Host "[LogNinja] Downloading language pack from GitHub..." -ForegroundColor DarkGray
            $L = Invoke-RestMethod "$githubBase/$langCode.json"
        } catch {
            Write-Warning "Failed to download language file from GitHub. Falling back to English."
            Start-Sleep -Seconds 2
            $L = [PSCustomObject]$defaultLang
        }
    } else {
        # Running locally - read from lang/ folder next to script
        $langFolder = Join-Path $PSScriptRoot "lang"
        $langFile = Join-Path $langFolder "$langCode.json"
        if (Test-Path $langFile) {
            $L = Get-Content $langFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } else {
            Write-Warning "Language file ($langCode.json) not found. Falling back to English."
            Start-Sleep -Seconds 2
            $L = [PSCustomObject]$defaultLang
        }
    }
}
# --------------------------------

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "               $($L.Header)                 " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Severity selection
Write-Host $L.PromptSeverity -ForegroundColor Yellow
Write-Host $L.Severity1
Write-Host $L.Severity2
Write-Host $L.Severity3
$inputSeverity = Read-Host $L.InputSeverity

if ([string]::IsNullOrWhiteSpace($inputSeverity)) { $severityChoice = 1 } else { $severityChoice = [int]$inputSeverity }

$levels = @()
switch ($severityChoice) {
    1 { $levels = @(1, 2) } 
    2 { $levels = @(1, 2, 3) } 
    3 { $levels = @(1, 2, 3, 4, 0) } 
    default { $levels = @(1, 2); Write-Host $L.DefaultSeverity -ForegroundColor DarkGray }
}

Write-Host ""
# Time unit selection
Write-Host $L.PromptUnit -ForegroundColor Yellow
Write-Host $L.Unit1
Write-Host $L.Unit2
Write-Host $L.Unit3
Write-Host $L.Unit4
Write-Host $L.Unit5
Write-Host $L.Unit6
Write-Host $L.Unit7
$inputUnit = Read-Host $L.InputUnit

if ([string]::IsNullOrWhiteSpace($inputUnit)) { $timeUnitChoice = 4 } else { $timeUnitChoice = [int]$inputUnit }

Write-Host ""
# Time value selection
if ($timeUnitChoice -eq 7) {
    # For boot time, no need to ask for amount
    $timeValue = 1 
} else {
    # Ask for amount for other options
    $inputValue = Read-Host $L.PromptValue
    if ([string]::IsNullOrWhiteSpace($inputValue)) { $timeValue = 1 } else { $timeValue = [int]$inputValue }
}

# Calculate start date
$now = Get-Date
switch ($timeUnitChoice) {
    1 { $startDate = $now.AddSeconds(-$timeValue) }
    2 { $startDate = $now.AddMinutes(-$timeValue) }
    3 { $startDate = $now.AddHours(-$timeValue) }
    4 { $startDate = $now.AddDays(-$timeValue) }
    5 { $startDate = $now.AddDays(-($timeValue * 7)) }
    6 { $startDate = $now.AddYears(-$timeValue) }
    7 { 
        # Get exact last boot time from Windows
        $startDate = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime 
    }
    default { $startDate = $now.AddDays(-1) }
}

Write-Host "`n$($L.PrepLogs)" -ForegroundColor DarkGray
$allLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { $_.RecordCount -gt 0 }
$totalLogs = $allLogs.Count
$allEvents = @()

Write-Host ($L.ScanStart -f $startDate) -ForegroundColor Green

# Scanning loop with progress bar
$counter = 0
foreach ($log in $allLogs) {
    $counter++
    $percent = [math]::Round(($counter / $totalLogs) * 100)
    Write-Progress -Activity $L.ProgressActivity -Status ($L.ProgressStatus -f $log.LogName) -PercentComplete $percent
    
    $events = Get-WinEvent -FilterHashtable @{LogName=$log.LogName; Level=$levels; StartTime=$startDate} -ErrorAction SilentlyContinue
    if ($events) { $allEvents += $events }
}
Write-Progress -Activity $L.ProgressActivity -Completed

# Output results
Write-Host "`n$($L.ResultHeader)" -ForegroundColor Cyan
if ($allEvents.Count -eq 0) {
    Write-Host $L.SystemClean -ForegroundColor Green
    exit
}

# 1. Intelligent normalization
# Create cache for fast PID to process name lookup
$processCache = @{}

$normalizedEvents = foreach ($ev in $allEvents) {
    $msg = $ev.Message -replace "`n", " " -replace "`r", " "

    # Search for processes (.exe) in text
    $processes = ([regex]::Matches($msg, '(?i)[a-z0-9_-]+\.exe')).Value | Select-Object -Unique
    $processStr = if ($processes) { $processes -join ", " } else { $L.ProcessUnknown }

    # NEW FEATURE: Extract hidden PID from event properties
    # If no .exe in text, but Windows recorded process ID (PID > 4, since 4 and 0 are System)
    if ($processStr -eq $L.ProcessUnknown -and $ev.ProcessId -gt 4) {
        $epid = $ev.ProcessId
        if (-not $processCache.ContainsKey($epid)) {
            # Silent lookup without generating PowerShell errors
            $proc = Get-Process -Id $epid -ErrorAction Ignore
            if ($proc) {
                $processCache[$epid] = "$($proc.ProcessName).exe"
            } else {
                $processCache[$epid] = "PID:$epid"
            }
        }
        $processStr = $processCache[$epid]
    }

    # Parse according to Microsoft recommendations for WMI
    if ($ev.ProviderName -eq 'Microsoft-Windows-WMI-Activity' -and $ev.Id -eq 5858) {
        $opMatch = [regex]::Match($msg, 'Operation = ([^;]+)')
        $pidMatch = [regex]::Match($msg, 'ClientProcessId = (\d+)')

        $wmiProcessInfo = ""

        # Extract PID and try to get running process name
        if ($pidMatch.Success) {
            $cpid = $pidMatch.Groups[1].Value
            if (-not $processCache.ContainsKey($cpid)) {
                # Silent lookup without generating PowerShell errors
                $proc = Get-Process -Id $cpid -ErrorAction Ignore
                if ($proc) {
                    $processCache[$cpid] = "$($proc.ProcessName).exe"
                } else {
                    $processCache[$cpid] = "PID:$cpid (Terminated)"
                }
            }
            $wmiProcessInfo = $processCache[$cpid]
        }

        if ($opMatch.Success) {
            $opFull = $opMatch.Groups[1].Value
            if ($opFull -match 'from\s+([a-zA-Z0-9_]+)') { $opShort = $matches[1] }
            elseif ($opFull -match '(MSFT_[a-zA-Z0-9_]+)') { $opShort = $matches[1] }
            else { $opShort = "Query" }

            # Remove default "Unknown/System"
            $processStr = ($processStr -replace $L.ProcessUnknown, "").Trim()

            # Add found process to output string
            if ($wmiProcessInfo) {
                $processStr = "$wmiProcessInfo [WMI: $opShort]".Trim()
            } else {
                $processStr = "$processStr [WMI: $opShort]".Trim()
            }
        }
    }

    # Strict grouping (Source + EventID + Process/Essence)
    $groupKey = "$($ev.ProviderName)_$($ev.Id)_$($processStr)"

    [PSCustomObject] @{
        ProviderName = $ev.ProviderName
        LogName      = $ev.LogName
        EventId      = $ev.Id
        Message      = $msg
        ProcessStr   = $processStr
        GroupKey     = $groupKey
    }
}

# 2. Group events
$groupedEvents = $normalizedEvents | Group-Object -Property GroupKey | Sort-Object Count -Descending

# Get OS Version Info
$osInfo = Get-CimInstance Win32_OperatingSystem
$regVer = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
$osCaption = if ($osInfo.Caption) { $osInfo.Caption.Trim() } else { "Unknown OS" }
$osVersion = if ($regVer.DisplayVersion) { $regVer.DisplayVersion } else { "Unknown" }
$osBuild   = if ($osInfo.BuildNumber) { "$($osInfo.BuildNumber).$($regVer.UBR)" } else { "Unknown" }

# Prepare AI Report
$aiReport = "$($L.AiReportTitle)`n"
$aiReport += "OS: $osCaption | Version: $osVersion | Build: $osBuild`n"
$aiReport += ($L.AiReportScanDates -f $startDate, $now) + "`n"
$aiReport += ($L.AiReportTotal -f $allEvents.Count) + "`n`n"

# Add AI instructions from language file
$aiReport += $L.AiInstructions

$displayTable = @()

foreach ($group in $groupedEvents) {
    $sample = $group.Group[0]

    $displayTable += [PSCustomObject] @{
        Count   = $group.Count
        EventID = $sample.EventId
        Source  = $sample.ProviderName
        Process = $sample.ProcessStr
    }

    $aiReport += ($L.AiSource -f $sample.ProviderName, $group.Count) + "`n"
    $aiReport += ($L.AiLog -f $sample.LogName, $sample.EventId) + "`n"
    $aiReport += ($L.AiProcess -f $sample.ProcessStr) + "`n"

    # For WMI - clean operation, for others - original message
    if ($sample.ProviderName -eq 'Microsoft-Windows-WMI-Activity') {
        $cleanOp = [regex]::Match($sample.Message, 'Operation = ([^;]+)').Groups[1].Value.Trim()
        $cleanCode = [regex]::Match($sample.Message, 'ResultCode = ([^;]+)').Groups[1].Value.Trim()
        $cleanCause = [regex]::Match($sample.Message, 'PossibleCause = (.+)$').Groups[1].Value.Trim()
        $aiReport += ($L.AiError -f "Operation: $cleanOp | ResultCode: $cleanCode | Cause: $cleanCause") + "`n`n"
    } else {
        $aiReport += ($L.AiError -f $sample.Message) + "`n`n"
    }
}

# Display dynamic table
$displayTable | Select-Object @{Name=$L.CountCount;   Expression={$_.Count}},
                               @{Name=$L.EventIdLabel; Expression={$_.EventID}},
                               @{Name=$L.SourceSource; Expression={$_.Source}},
                               @{Name=$L.ProcessProcess; Expression={$_.Process}} |
                               Format-Table -AutoSize

Write-Host "=========================================" -ForegroundColor Cyan

# Clipboard prompt
Write-Host "`n$($L.CopyPrompt)" -ForegroundColor Yellow

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# VK_CONTROL=17, VK_LCONTROL=162, VK_RCONTROL=163
if ($key.VirtualKeyCode -in 17,162,163) {
    # Safe clipboard copy - only if report is not empty
    if (-not [string]::IsNullOrWhiteSpace($aiReport)) {
        $aiReport | Set-Clipboard
        Write-Host "`n$($L.CopySuccess)" -ForegroundColor Green
    } else {
        Write-Host "`n[!] Report is empty, nothing to copy." -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n$($L.ExitMsg)" -ForegroundColor DarkGray
}
