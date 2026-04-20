# BOB'S SECURITY AUDIT SYSTEM
# Comprehensive security vulnerability scanning
# Inspired by production AI agent security best practices

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "scan",  # scan, report, history
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "",  # file, directory, or all
    
    [Parameter(Mandatory=$false)]
    [string]$Severity = "all"  # critical, high, medium, low, all
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$SECURITY_DIR = "C:\Users\clayt\opencode-bob\memory\security"
$SCAN_RESULTS = "$SECURITY_DIR\scan-results.json"
$VULN_TREATSOFT = "$SECURITY_DIR\vulnerability-database.json"

if (-not (Test-Path $SECURITY_DIR)) {
    New-Item -ItemType Directory -Force -Path $SECURITY_DIR | Out-Null
}

# ============================================================================
# VULNERABILITY PATTERNS (simplified for PowerShell)
# ============================================================================

$VULNERABILITIES = @{
    # Critical - Secret exposure
    "secrets-api-key" = @{
        pattern = "api.key"
        severity = "critical"
        description = "Potentially exposed API key or secret"
        fix = "Remove secrets from code, use environment variables"
    }
    "github-token" = @{
        pattern = "ghp_"
        severity = "critical"
        description = "GitHub personal access token exposed"
        fix = "Rotate token immediately, use GitHub secrets"
    }
    "aws-credentials" = @{
        pattern = "AKIA"
        severity = "critical"
        description = "AWS access key exposed"
        fix = "Rotate credentials, use IAM roles"
    }
    
    # High - Code injection
    "shell-injection" = @{
        pattern = "shell=True"
        severity = "high"
        description = "Potential shell injection vulnerability"
        fix = "Use subprocess with shell=False, validate inputs"
    }
    "eval-use" = @{
        pattern = "eval("
        severity = "high"
        description = "Dangerous eval usage"
        fix = "Avoid eval, use ast.literal_eval for trusted data"
    }
    "exec-use" = @{
        pattern = "exec("
        severity = "high"
        description = "Dangerous exec usage"
        fix = "Avoid exec, use safe interpreters"
    }
    "pickle-load" = @{
        pattern = "pickle.load"
        severity = "high"
        description = "Pickle deserialization vulnerability"
        fix = "Use JSON or custom safe serializers"
    }
    
    # Medium - Input validation
    "sql-injection" = @{
        pattern = "+ sql +"
        severity = "medium"
        description = "Potential SQL injection"
        fix = "Use parameterized queries"
    }
    "path-traversal" = @{
        pattern = ".."
        severity = "medium"
        description = "Potential path traversal"
        fix = "Validate and sanitize file paths"
    }
    
    # Low - Best practices
    "hardcoded-ip" = @{
        pattern = "192.168."
        severity = "low"
        description = "Hardcoded IP address"
        fix = "Use environment variables or config"
    }
    "print-password" = @{
        pattern = "print.*password"
        severity = "low"
        description = "Password printed to output"
        fix = "Use secure logging"
    }
}

# ============================================================================
# SAFE FILE PATTERNS
# ============================================================================

$SAFE_PATTERNS = @(
    "node_modules",
    ".git",
    "dist",
    "build",
    "__pycache__",
    ".venv"
)

# ============================================================================
# SIMPLE PATTERN MATCH
# ============================================================================

function Test-SecurityPattern {
    param([string]$Content, [string]$Pattern)
    
    # Simple contains check
    return $Content -like "*$Pattern*"
}

# ============================================================================
# SCAN FILE
# ============================================================================

function Invoke-SecurityScan {
    param([string]$FilePath, [string]$Sev)
    
    $vulns = @()
    
    # Get file extension
    $ext = [System.IO.Path]::GetExtension($FilePath)
    
    # Skip non-code files
    if ($ext -notmatch '\.(ps1|py|js|ts|java|cs|go|rb)$') {
        return $vulns
    }
    
    # Read file content
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $vulns }
    
    # Check each pattern
    foreach ($vulnName in $VULNERABILITIES.Keys) {
        $vuln = $VULNERABILITIES[$vulnName]
        
        # Filter by severity
        if ($Sev -ne "all" -and $vuln.severity -ne $Sev) {
            continue
        }
        
        # Find matches using simple pattern
        if (Test-SecurityPattern -Content $content -Pattern $vuln.pattern) {
            # Get line number
            $lineNum = 1
            $lines = $content -split "`n"
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -like "*$($vuln.pattern)*") {
                    $lineNum = $i + 1
                    break
                }
            }
            
            $vulns += @{
                type = $vulnName
                severity = $vuln.severity
                description = $vuln.description
                fix = $vuln.fix
                file = $FilePath
                line = $lineNum
                match = $vuln.pattern
            }
        }
    }
    
    return $vulns
}

# ============================================================================
# SCAN DIRECTORY
# ============================================================================

function Invoke-DirectoryScan {
    param([string]$Dir, [string]$Sev)
    
    $allVulns = @()
    
    # Get all code files
    $files = Get-ChildItem -Path $Dir -Recurse -Include "*.ps1","*.py","*.js","*.ts" -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        # Skip safe patterns
        $skip = $false
        foreach ($pattern in $SAFE_PATTERNS) {
            if ($file.FullName -like "*$pattern*") {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }
        
        # Scan file
        $vulns = Invoke-SecurityScan -FilePath $file.FullName -Sev $Sev
        $allVulns += $vulns
    }
    
    return $allVulns
}

# ============================================================================
# SAVE RESULTS
# ============================================================================

function Save-ScanResults {
    param([object]$Results)
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content $SCAN_RESULTS
}

# ============================================================================
# GET REPORT
# ============================================================================

function Get-SecurityReport {
    param([object]$Results)
    
    # Count by severity
    $critical = ($Results | Where-Object { $_.severity -eq "critical" }).Count
    $high = ($Results | Where-Object { $_.severity -eq "high" }).Count
    $medium = ($Results | Where-Object { $_.severity -eq "medium" }).Count
    $low = ($Results | Where-Object { $_.severity -eq "low" }).Count
    
    return @{
        total = $Results.Count
        critical = $critical
        high = $high
        medium = $medium
        low = $low
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "scan" {
        if ($Target -eq "") {
            Write-Error "Target (file or directory) required"
        }
        
        $results = @()
        
        if (Test-Path $Target) {
            if (Test-Path $Target -PathType Container) {
                $results = Invoke-DirectoryScan -Dir $Target -Sev $Severity
            } else {
                $results = Invoke-SecurityScan -FilePath $Target -Sev $Severity
            }
        }
        
        # Save results
        $scanResult = @{
            target = $Target
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            severity = $Severity
            findings = $results
        }
        Save-ScanResults -Results $scanResult
        
        # Get report
        $report = Get-SecurityReport -Results $results
        
        @{
            target = $Target
            findings = $results.Count
            report = $report
            saved = $SCAN_RESULTS
        } | ConvertTo-Json -Depth 10
    }
    "report" {
        if (Test-Path $SCAN_RESULTS) {
            Get-Content $SCAN_RESULTS -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 10
        } else {
            @{error = "No scan results found"}
        }
    }
    "history" {
        Get-ChildItem -Path $SECURITY_DIR -Filter "*.json" | Select-Object Name, LastWriteTime
    }
    "vulns" {
        $VULNERABILITIES.Keys | ForEach-Object {
            @{
                name = $_
                severity = $VULNERABILITIES[$_].severity
                description = $VULNERABILITIES[$_].description
            }
        } | ConvertTo-Json -Depth 10
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}