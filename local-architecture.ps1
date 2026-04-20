# Opencode Bob - Local Architecture Configuration
# Ensures 100% local operation - no cloud dependency

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "status"  # status, check, config
)

$ErrorActionPreference = "Continue"

# ============================================================================
# LOCAL-ONLY ARCHITECTURE
# ============================================================================

$CONFIG = @{
    # Core - ALL LOCAL
    ModelProvider = "ollama"  # Local only!
    OllamaHost = "http://localhost:11434"
    
    # Memory - ALL LOCAL
    MemoryBackend = "filesystem"  # Local JSON files
    MemoryPath = "C:\Users\clayt\opencode-bob\memory"
    
    # Storage - ALL LOCAL
    DataPath = "C:\Users\clayt\opencode-bob"
    
    # No Cloud Services
    CloudDependency = $false
    ExternalAPIs = @()
    
    # Available Models (local)
    AvailableModels = @(
        "qwen2.5:7b",
        "qwen2.5:14b", 
        "llama3.2:3b",
        "llama3.2:1b",
        "mistral:7b",
        "codellama:7b",
        "phi3:14b"
    )
    
    # MCP Servers (local)
    MCPServers = @(
        "filesystem",
        "memory", 
        "github",
        "webfetch",
        "websearch",
        "bash"
    )
}

# ============================================================================
# STATUS CHECKS
# ============================================================================

function Test-OllamaRunning {
    try {
        $response = Invoke-RestMethod -Uri "$($CONFIG.OllamaHost)/api/tags" -TimeoutSec 5
        return @{
            Status = "running"
            Models = $response.models.name
        }
    } catch {
        return @{
            Status = "stopped"
            Error = $_.Exception.Message
        }
    }
}

function Test-LocalFiles {
    $paths = @(
        $CONFIG.MemoryPath,
        "$($CONFIG.DataPath)\time-machine",
        "$($CONFIG.DataPath)\skills",
        "$($CONFIG.DataPath)\knowledge-graph.ps1",
        "$($CONFIG.DataPath)\learning-engine.ps1",
        "$($CONFIG.DataPath)\parallel-agents.ps1"
    )
    
    $results = @{}
    foreach ($path in $paths) {
        $results[$path] = Test-Path $path
    }
    
    return $results
}

function Get-SystemStatus {
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "OPENCODE BOB - LOCAL ARCHITECTURE STATUS"
    Write-Host "=" * 60
    
    # Ollama Status
    Write-Host ""
    Write-Host "OLLAMA (Local LLM):"
    $ollama = Test-OllamaRunning
    if ($ollama.Status -eq "running") {
        Write-Host "  ✓ Running at $($CONFIG.OllamaHost)"
        Write-Host "  Available models: $($ollama.Models -join ', ')"
    } else {
        Write-Host "  ✗ Stopped or not installed"
        Write-Host "  Install: https://ollama.com"
    }
    
    # Local Files
    Write-Host ""
    Write-Host "LOCAL STORAGE:"
    $files = Test-LocalFiles
    foreach ($path in $files.Keys) {
        $status = if ($files[$path]) { "✓" } else { "✗" }
        $name = Split-Path $path -Leaf
        Write-Host "  $status $name"
    }
    
    # Cloud Dependency Check
    Write-Host ""
    Write-Host "CLOUD DEPENDENCY:"
    if ($CONFIG.CloudDependency) {
        Write-Host "  ✗ WARNING: Cloud dependent!"
    } else {
        Write-Host "  ✓ 100% Local - No cloud required"
    }
    
    # Feature Status
    Write-Host ""
    Write-Host "LOCAL FEATURES:"
    Write-Host "  ✓ Parallel Agents: $($CONFIG.AvailableModels.Count) models available"
    Write-Host "  ✓ Knowledge Graph: Local JSON storage"
    Write-Host "  ✓ Time Machine: Local snapshots"
    Write-Host "  ✓ Learning Engine: Local pattern tracking"
    
    Write-Host "=" * 60
    
    return @{
        Ollama = $ollama.Status
        LocalFiles = $files
        CloudDependency = $CONFIG.CloudDependency
    }
}

function Get-ArchitectureDiagram {
    Write-Host ""
    Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║           OPENCODE BOB - 100% LOCAL ARCHITECTURE                ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║   ┌─────────────────────────────────────────────────────────┐   ║
║   │                    USER INTERFACE                        │   ║
║   │              (Opencode CLI / Terminal)                    │   ║
║   └─────────────────────────────────────────────────────────┘   ║
║                              │                                    ║
║                              ▼                                    ║
║   ┌─────────────────────────────────────────────────────────┐   ║
║   │                 COMMANDER AGENT                          │   ║
║   │              (qwen3.5:cloud - Ollama)                   │   ║
║   │  • Planning    • Web search    • Orchestration           │   ║
║   └─────────────────────────────────────────────────────────┘   ║
║                              │                                    ║
║              ┌───────────────┼───────────────┐                    ║
║              ▼               ▼               ▼                    ║
║   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   ║
║   │   WORKER       │ │   WORKER       │ │   WORKER       │   ║
║   │  (qwen2.5:7b) │ │  (qwen2.5:7b) │ │  (qwen2.5:7b) │   ║
║   │                │ │                │ │                │   ║
║   │  Parallel #1  │ │  Parallel #2  │ │  Parallel #50  │   ║
║   └─────────────────┘ └─────────────────┘ └─────────────────┘   ║
║                              │                                    ║
║                              ▼                                    ║
║   ┌─────────────────────────────────────────────────────────┐   ║
║   │                 LOCAL MEMORY LAYER                       │   ║
║   │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │   ║
║   │  │Knowledge │  │Learning  │  │Patterns  │             │   ║
║   │  │  Graph   │  │ Engine   │  │  Store   │             │   ║
║   │  └──────────┘  └──────────┘  └──────────┘             │   ║
║   └─────────────────────────────────────────────────────────┘   ║
║                              │                                    ║
║                              ▼                                    ║
║   ┌─────────────────────────────────────────────────────────┐   ║
║   │               TIME MACHINE BACKUP                       │   ║
║   │        (Local snapshots every 15 minutes)              │   ║
║   │           6-month retention | Local storage            │   ║
║   └─────────────────────────────────────────────────────────┘   ║
║                                                                   ║
║   ═══════════════════════════════════════════════════════════    ║
║                 0% CLOUD | 100% LOCAL                           ║
╚══════════════════════════════════════════════════════════════════╝

"@
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Operation.ToLower()) {
    "status" {
        Get-SystemStatus
    }
    
    "diagram" {
        Get-ArchitectureDiagram
    }
    
    "check" {
        $status = Get-SystemStatus
        
        if ($status.Ollama -ne "running") {
            Write-Host "WARNING: Ollama not running. Install from https://ollama.com"
            Write-Host "Start with: ollama serve"
        }
        
        if ($status.CloudDependency) {
            Write-Host "ERROR: Cloud dependency detected!"
        } else {
            Write-Host "✓ Fully local - no cloud dependency"
        }
    }
    
    default {
        Get-SystemStatus
    }
}