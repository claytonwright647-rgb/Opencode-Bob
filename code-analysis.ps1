# BOB'S CODE ANALYSIS
# Security and performance scanning

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "scan",  # scan, security, performance, full
    
    [Parameter(Mandatory=$false)]
    [string]$Path = ".",
    
    [switch]$Fix
)

$ErrorActionPreference = "Continue"

# ============================================================================
# SECURITY VULNERABILITIES
# ============================================================================

$SECURITY_PATTERNS = @{
    "hardcoded_password" = @{
        pattern = "(password|passwd|pwd|secret|api_key|apikey|token)\s*=\s*['\""][^'""'<!"
        severity = "HIGH"
        description = "Hardcoded credentials detected"
    }
    
    "sql_injection" = @{
        pattern = "(SELECT|INSERT|UPDATE|DELETE)\s+.*\$\{|@[_a-zA-Z]|concat\("
        severity = "HIGH"
        description = "Potential SQL injection risk"
    }
    
    "command_injection" = @{
        pattern = "(exec|system|shell_exec|popen|proc_open)\s*\("
        severity = "HIGH"
        description = "Command injection risk"
    }
    
    "eval_usage" = @{
        pattern = "\beval\s*\("
        severity = "MEDIUM"
        description = "eval() is dangerous"
    }
    
    "weak_crypto" = @{
        pattern = "(md5|sha1|des|rc4)\b"
        severity = "MEDIUM"
        description = "Weak cryptographic algorithm"
    }
    
    "unsafe_yaml" = @{
        pattern = "(yaml\.load|yaml\.unsafe_load)\s*\("
        severity = "MEDIUM"
        description = "unsafe YAML loading"
    }
    
    "path_traversal" = @{
        pattern = "(open|read|write)\s*\([^)]*\+[^)]*\)"
        severity = "MEDIUM"
        description = "Potential path traversal"
    }
}

# ============================================================================
# PERFORMANCE ISSUES
# ============================================================================

$PERFORMANCE_PATTERNS = @{
    "n_plus_one" = @{
        pattern = "for.*foreach.*SELECT.*IN\s*\("
        severity = "MEDIUM"
        description = "Potential N+1 query problem"
    }
    
    "regex_in_loop" = @{
        pattern = "for\s*\{.*match|regex"
        severity = "LOW"
        description = "Regex compiled inside loop"
    }
    
    "string_concat" = @{
        pattern = "\+\s*=.*\+\s*.*\+\s*.*\+\s*"
        severity = "LOW"
        description = "String concatenation in loop"
    }
    
    "no_index" = @{
        pattern = "WHERE.*LIKE"
        severity = "MEDIUM"
        description = "LIKE without index consideration"
    }
}

# ============================================================================
# SCAN FUNCTIONS
# ============================================================================

function Scan-Security {
    param([string]$Path)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "  🔒 SECURITY SCAN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "   Path: $Path" -ForegroundColor Gray
    Write-Host ""
    
    $issues = @()
    
    # Scan files
    $files = Get-ChildItem -Path $Path -Recurse -Include "*.cs","*.js","*.ts","*.py","*.ps1" -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        foreach ($vuln in $SECURITY_PATTERNS.Keys) {
            $pattern = $SECURITY_PATTERNS[$vuln].pattern
            
            if ($content -match $pattern) {
                $issue = @{
                    "file" = $file.FullName
                    "vulnerability" = $vuln
                    "severity" = $SECURITY_PATTERNS[$vuln].severity
                    "description" = $SECURITY_PATTERNS[$vuln].description
                    "line" = (Select-String -Path $file.FullName -Pattern $pattern | Select-Object -First 1).LineNumber
                }
                $issues += $issue
            }
        }
    }
    
    # Report findings
    if ($issues.Count -eq 0) {
        Write-Host "   ✅ No security issues found!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Found $($issues.Count) security issues:" -ForegroundColor Red
        Write-Host ""
        
        foreach ($issue in $issues) {
            $color = switch ($issue.severity) {
                "HIGH" { "Red" }
                "MEDIUM" { "Yellow" }
                "LOW" { "Gray" }
            }
            
            Write-Host "   [$($issue.severity)] $($issue.vulnerability)" -ForegroundColor $color
            Write-Host "      File: $($issue.file):$($issue.line)" -ForegroundColor Gray
            Write-Host "      $($issue.description)" -ForegroundColor White
            Write-Host ""
        }
    }
    
    return $issues
}

function Scan-Performance {
    param([string]$Path)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ⚡ PERFORMANCE SCAN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "   Path: $Path" -ForegroundColor Gray
    Write-Host ""
    
    $issues = @()
    
    $files = Get-ChildItem -Path $Path -Recurse -Include "*.cs","*.js","*.ts","*.py" -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        foreach ($perf in $PERFORMANCE_PATTERNS.Keys) {
            $pattern = $PERFORMANCE_PATTERNS[$perf].pattern
            
            if ($content -match $pattern) {
                $issue = @{
                    "file" = $file.FullName
                    "issue" = $perf
                    "severity" = $PERFORMANCE_PATTERNS[$perf].severity
                    "description" = $PERFORMANCE_PATTERNS[$perf].description
                }
                $issues += $issue
            }
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "   ✅ No performance issues found!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Found $($issues.Count) performance issues:" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($issue in $issues) {
            Write-Host "   [$($issue.severity)] $($issue.issue)" -ForegroundColor Yellow
            Write-Host "      $($issue.description)" -ForegroundColor Gray
        }
    }
    
    return $issues
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "scan" {
        $securityIssues = Scan-Security -Path $Path
        $perfIssues = Scan-Performance -Path $Path
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  📊 SCAN SUMMARY" -ForegroundColor Yellow
        Write-Host "══════════════════════════════════════=" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Security: $($securityIssues.Count) issues" -ForegroundColor $(if ($securityIssues.Count -gt 0) { "Red" } else { "Green" })
        Write-Host "   Performance: $($perfIssues.Count) issues" -ForegroundColor $(if ($perfIssues.Count -gt 0) { "Yellow" } else { "Green" })
        Write-Host ""
    }
    
    "security" {
        Scan-Security -Path $Path
    }
    
    "performance" {
        Scan-Performance -Path $Path
    }
    
    "full" {
        Scan-Security -Path $Path
        Scan-Performance -Path $Path
    }
    
    default {
        Write-Host "Usage: code-analysis.ps1 -Operation <scan|security|performance> -Path <directory>"
    }
}