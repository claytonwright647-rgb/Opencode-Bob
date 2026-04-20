# BOB'S VECTOR RAG KNOWLEDGE RETRIEVAL
# Deep knowledge retrieval using embeddings

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "add",  # add, search, status
    
    [Parameter(Mandatory=$false)]
    [string]$Text = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Query = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Collection = "bob-knowledge"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$RAG_DIR = "C:\Users\clayt\opencode-bob\memory\rag"
$COLLECTIONS_DIR = "$RAG_DIR\collections"

if (-not (Test-Path $COLLECTIONS_DIR)) {
    New-Item -ItemType Directory -Force -Path $COLLECTIONS_DIR | Out-Null
}

# Simple in-memory embeddings (no API needed)
# In production: would use chromadb or similar

# ============================================================================
# SIMPLE TEXT INDEX
# Uses keyword + position for simple retrieval
# Works without embeddings API
# ============================================================================

$INDEX_FILE = "$COLLECTIONS_DIR\default.json"

function Get-Index {
    if (Test-Path $INDEX_FILE) {
        return Get-Content $INDEX_FILE -Raw | ConvertFrom-Json
    }
    return @{ documents = @(); keywords = @{} }
}

function Save-Index {
    param([object]$Index)
    $Index | ConvertTo-Json -Depth 10 | Set-Content $INDEX_FILE
}

# ============================================================================
# EXTRACT KEYWORDS
# ============================================================================

function Get-Keywords {
    param([string]$Text)
    
    # Simple keyword extraction
    $words = $Text -split '\W+' | Where-Object { $_.Length -gt 3 }
    
    # Remove common words
    $stopWords = @("the", "and", "that", "this", "with", "for", "from", "have", "been", "will", "are", "were")
    $words = $words | Where-Object { $_ -notin $stopWords }
    
    # Count frequency
    $freq = @{}
    foreach ($w in $words) {
        $w = $w.ToLower()
        if (-not $freq[$w]) { $freq[$w] = 0 }
        $freq[$w]++
    }
    
    return $freq
}

# ============================================================================
# ADD DOCUMENT
# ============================================================================

function Add-Document {
    param([string]$Text, [string]$Collection)
    
    $index = Get-Index
    
    # Generate ID
    $docId = "doc_" + (Get-Random -Maximum 100000)
    
    # Extract keywords
    $keywords = Get-Keywords -Text $Text
    
    # Create document
    $doc = @{
        id = $docId
        text = $Text
        keywords = $keywords
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $index.documents += $doc
    
    # Update keyword index
    foreach ($kw in $keywords.Keys) {
        if (-not $index.keywords[$kw]) {
            $index.keywords[$kw] = @()
        }
        $index.keywords[$kw] += $docId
    }
    
    Save-Index -Index $index
    
    return @{
        success = $true
        id = $docId
        keywords = $keywords.Keys.Count
    }
}

# ============================================================================
# SEARCH DOCUMENTS
# ============================================================================

function Search-Documents {
    param([string]$Query)
    
    $index = Get-Index
    
    # Get query keywords
    $queryKeywords = Get-Keywords -Text $Query
    
    # Score each document
    $scores = @{}
    
    foreach ($doc in $index.documents) {
        $score = 0
        
        # Count matching keywords
        foreach ($kw in $queryKeywords.Keys) {
            if ($doc.keywords[$kw]) {
                $score += $doc.keywords[$kw] * $queryKeywords[$kw]
            }
        }
        
        if ($score -gt 0) {
            $scores[$doc.id] = $score
        }
    }
    
    # Sort by score
    $results = $scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
    
    $documents = @()
    foreach ($r in $results) {
        $doc = $index.documents | Where-Object { $_.id -eq $r.Name }
        if ($doc) {
            $documents += @{
                id = $doc.id
                text = $doc.text.Substring(0, [Math]::Min(200, $doc.text.Length))
                score = $r.Value
            }
        }
    }
    
    return @{
        query = $Query
        results = $documents
        count = $documents.Count
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-RAGStatus {
    $index = Get-Index
    
    return @{
        totalDocuments = $index.documents.Count
        totalKeywords = $index.keywords.Keys.Count
        collection = "bob-knowledge"
    }
}

# ============================================================================
# PRE-POPULATE WITH BOB KNOWLEDGE
# ============================================================================

function Initialize-DefaultKnowledge {
    $index = Get-Index
    
    # Only if empty
    if ($index.documents.Count -gt 0) {
        return @{ message = "Already initialized" }
    }
    
    # Add Bob's knowledge
    $knowledge = @(
        "Opencode Bob is an AI coding assistant built by Clay Wright. It uses Claude patterns and is persistent across sessions.",
        "Bob has VA claims expertise and can analyze disability claims with deep domain knowledge.",
        "Bob uses a 5-layer context compaction system inspired by Claude Code for memory management.",
        "Bob has error recovery that tracks mistakes and never repeats them.",
        "Bob uses Time Machine for state snapshots before and after critical operations.",
        "Bob can read PDFs using pdf-mcp and analyze documents like CT scans and decision letters.",
        "Bob uses MCP servers: github, filesystem, memory, and pdf for external integrations.",
        "Bob's skills include code-review, debug, test-gen, docs-gen, security-audit, refactor, and more."
    )
    
    foreach ($text in $knowledge) {
        $null = Add-Document -Text $text -Collection "bob-knowledge"
    }
    
    return @{
        success = $true
        documents = $knowledge.Count
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "add" {
        if ($Text -eq "") {
            Write-Error "Text required"
        }
        Add-Document -Text $Text -Collection $Collection
    }
    "search" {
        if ($Query -eq "") {
            Write-Error "Query required"
        }
        Search-Documents -Query $Query
    }
    "status" {
        Get-RAGStatus
    }
    "init" {
        Initialize-DefaultKnowledge
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}