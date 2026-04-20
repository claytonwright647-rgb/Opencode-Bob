# Opencode Bob - Knowledge Graph Engine
# Entity + Relationship storage with multi-hop reasoning
# Local JSON-based graph for persistence

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "query",  # query, add-entity, add-relation, learn, stats
    
    [Parameter(Mandatory=$false)]
    [string]$Entity = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Relation = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Properties = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Query = "",
    
    [switch]$DebugOutput
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$GRAPH_DIR = "C:\Users\clayt\opencode-bob\memory\knowledge-graph"
$ENTITIES_FILE = Join-Path $GRAPH_DIR "entities.json"
$RELATIONS_FILE = Join-Path $GRAPH_DIR "relations.json"
$PATTERNS_FILE = Join-Path $GRAPH_DIR "patterns.json"

# Ensure directory exists
New-Item -ItemType Directory -Force -Path $GRAPH_DIR | Out-Null

# ============================================================================
# DATA STRUCTURES
# ============================================================================

# Entity class
class Entity {
    [string]$Id
    [string]$Type
    [hashtable]$Properties
    [datetime]$Created
    [datetime]$Updated
    [int]$Strength
    
    Entity([string]$id, [string]$type) {
        $this.Id = $id
        $this.Type = $type
        $this.Properties = @{}
        $this.Created = Get-Date
        $this.Updated = Get-Date
        $this.Strength = 1
    }
}

# Relation class  
class Relation {
    [string]$From
    [string]$To
    [string]$Type
    [float]$Weight
    [datetime]$Created
    [int]$Count
    
    Relation([string]$from, [string]$to, [string]$type, [float]$weight = 0.8) {
        $this.From = $from
        $this.To = $to
        $this.Type = $type
        $this.Weight = $weight
        $this.Created = Get-Date
        $this.Count = 1
    }
}

# Pattern class
class Pattern {
    [string]$Id
    [string]$Description
    [string]$Solution
    [int]$SuccessCount
    [int]$FailCount
    [datetime]$LastUsed
    [float]$Strength
    
    Pattern([string]$id, [string]$desc, [string]$sol) {
        $this.Id = $id
        $this.Description = $desc
        $this.Solution = $sol
        $this.SuccessCount = 0
        $this.FailCount = 0
        $this.LastUsed = Get-Date
        $this.Strength = 0.5
    }
}

# ============================================================================
# STORAGE FUNCTIONS
# ============================================================================

function Load-Entities {
    if (Test-Path $ENTITIES_FILE) {
        return (Get-Content $ENTITIES_FILE | ConvertFrom-Json)
    }
    return @{}
}

function Save-Entities {
    param([hashtable]$Entities)
    $Entities | ConvertTo-Json -Depth 5 | Set-Content -Path $ENTITIES_FILE
}

function Load-Relations {
    if (Test-Path $RELATIONS_FILE) {
        return (Get-Content $RELATIONS_FILE | ConvertFrom-Json)
    }
    return @()
}

function Save-Relations {
    param([array]$Relations)
    $Relations | ConvertTo-Json -Depth 5 | Set-Content -Path $RELATIONS_FILE
}

function Load-Patterns {
    if (Test-Path $PATTERNS_FILE) {
        return (Get-Content $PATTERNS_FILE | ConvertFrom-Json)
    }
    return @{}
}

function Save-Patterns {
    param([hashtable]$Patterns)
    $Patterns | ConvertTo-Json -Depth 5 | Set-Content -Path $PATTERNS_FILE
}

# ============================================================================
# CORE OPERATIONS
# ============================================================================

function Add-Entity {
    param(
        [string]$Id,
        [string]$Type,
        [hashtable]$Properties
    )
    
    $entities = Load-Entities
    
    if ($entities.ContainsKey($Id)) {
        # Update existing
        $entities[$Id].Properties += $Properties
        $entities[$Id].Updated = Get-Date
        $entities[$Id].Strength = [Math]::Min(10, $entities[$Id].Strength + 0.5)
        Write-Host "Updated entity: $Id"
    } else {
        # Create new
        $entity = [Entity]::new($Id, $Type)
        $entity.Properties = $Properties
        $entities[$Id] = $entity
        Write-Host "Created entity: $Id (type: $Type)"
    }
    
    Save-Entities -Entities $entities
    return $entities[$Id]
}

function Add-Relation {
    param(
        [string]$From,
        [string]$To,
        [string]$Type,
        [float]$Weight = 0.8
    )
    
    $relations = Load-Relations
    
    # Check if relation exists
    $existing = $relations | Where-Object { $_.From -eq $From -and $_.To -eq $To -and $_.Type -eq $Type }
    
    if ($existing) {
        # Update weight and count
        $existing.Count++
        $existing.Weight = [Math]::Min(1.0, $existing.Weight + 0.1)
        Write-Host "Updated relation: $From -> $To ($Type) x$($existing.Count)"
    } else {
        # Create new
        $relation = [Relation]::new($From, $To, $Type, $Weight)
        $relations += $relation
        Write-Host "Created relation: $From -> $To ($Type)"
    }
    
    Save-Relations -Relations $relations
    return $relations
}

function Query-Graph {
    param(
        [string]$Query,
        [int]$MaxHops = 3
    )
    
    $entities = Load-Entities
    $relations = Load-Relations
    
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "KNOWLEDGE GRAPH QUERY: $Query"
    Write-Host "=" * 60
    
    # Simple keyword matching for now
    $keywords = $Query.ToLower() -split '\s+'
    $results = @()
    
    # Find entities matching keywords
    foreach ($key in $keywords) {
        # Check entity names
        foreach ($eid in $entities.Keys) {
            if ($eid.ToLower() -match $key -or $entities[$eid].Type.ToLower() -match $key) {
                $results += @{
                    Type = "entity"
                    Data = $entities[$eid]
                    Match = $key
                }
            }
        }
        
        # Check relation types
        foreach ($rel in $relations) {
            if ($rel.Type.ToLower() -match $key) {
                $results += @{
                    Type = "relation"
                    Data = $rel
                    Match = $key
                }
            }
        }
    }
    
    # Multi-hop reasoning: Find connected entities
    $hopResults = @()
    for ($hop = 1; $hop -le $MaxHops; $hop++) {
        foreach ($rel in $relations) {
            # From entities found in this hop, find relations
            $fromMatches = $results | Where-Object { $_.Type -eq "entity" -and $_.Data.Id -eq $rel.From }
            if ($fromMatches) {
                $hopResults += @{
                    Type = "hop"
                    Hop = $hop
                    Relation = $rel
                    ToEntity = $entities[$rel.To]
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "DIRECT MATCHES ($($results.Count)):"
    foreach ($r in $results) {
        if ($r.Type -eq "entity") {
            Write-Host "  [ENTITY] $($r.Data.Id) ($($r.Data.Type)) - Strength: $($r.Data.Strength)"
        } else {
            Write-Host "  [RELATION] $($r.Data.From) -> $($r.Data.To) ($($r.Data.Type))"
        }
    }
    
    if ($hopResults.Count -gt 0) {
        Write-Host ""
        Write-Host "MULTI-HOP CONNECTIONS ($($hopResults.Count)):"
        foreach ($hr in $hopResults | Select-Object -First 10) {
            Write-Host "  [HOP $($hr.Hop)] $($hr.Relation.From) --$($hr.Relation.Type)--> $($hr.ToEntity.Id)"
        }
    }
    
    Write-Host "=" * 60
    
    return @{
        Direct = $results
        Hops = $hopResults
        Total = $results.Count + $hopResults.Count
    }
}

function Learn-Pattern {
    param(
        [string]$Pattern,
        [string]$Solution,
        [bool]$Success
    )
    
    $patterns = Load-Patterns
    
    $patternId = ($Pattern.ToLower() -replace '[^a-z0-9]', '-').Substring(0, [Math]::Min(50, $Pattern.Length))
    
    if ($patterns.ContainsKey($patternId)) {
        if ($Success) {
            $patterns[$patternId].SuccessCount++
        } else {
            $patterns[$patternId].FailCount++
        }
        # Recalculate strength
        $total = $patterns[$patternId].SuccessCount + $patterns[$patternId].FailCount
        $patterns[$patternId].Strength = $patterns[$patternId].SuccessCount / $total
        $patterns[$patternId].LastUsed = Get-Date
    } else {
        $p = [Pattern]::new($patternId, $Pattern, $Solution)
        if ($Success) { $p.SuccessCount = 1 } else { $p.FailCount = 1 }
        $p.Strength = if ($Success) { 0.5 } else { 0.1 }
        $patterns[$patternId] = $p
    }
    
    Save-Patterns -Patterns $patterns
    
    $status = if ($Success) { "SUCCESS" } else { "FAILED" }
    Write-Host "Learned: $Pattern -> $Solution [$status] (strength: $($patterns[$patternId].Strength))"
    
    return $patterns[$patternId]
}

function Get-Stats {
    $entities = Load-Entities
    $relations = Load-Relations
    $patterns = Load-Patterns
    
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "KNOWLEDGE GRAPH STATISTICS"
    Write-Host "=" * 60
    Write-Host "Entities:  $($entities.Count)"
    Write-Host "Relations: $($relations.Count)"
    Write-Host "Patterns:  $($patterns.Count)"
    
    # Top entities by strength
    $topEntities = $entities.Values | Sort-Object Strength -Descending | Select-Object -First 5
    Write-Host ""
    Write-Host "TOP ENTITIES (by strength):"
    foreach ($e in $topEntities) {
        Write-Host "  $($e.Id): $($e.Strength)"
    }
    
    # Top patterns by strength
    $topPatterns = $patterns.Values | Sort-Object Strength -Descending | Select-Object -First 5
    Write-Host ""
    Write-Host "TOP PATTERNS (by success rate):"
    foreach ($p in $topPatterns) {
        Write-Host "  $($p.Id): $($p.Strength) ($($p.SuccessCount) success / $($p.FailCount) fail)"
    }
    
    Write-Host "=" * 60
    
    return @{
        Entities = $entities.Count
        Relations = $relations.Count
        Patterns = $patterns.Count
    }
}

# ============================================================================
# MAIN DISPATCH
# ============================================================================

switch ($Operation.ToLower()) {
    "add-entity" {
        $props = @{}
        if ($Properties) {
            $props = $Properties | ConvertFrom-Json
        }
        Add-Entity -Id $Entity -Type $Target -Properties $props
    }
    
    "add-relation" {
        Add-Relation -From $Entity -To $Target -Type $Relation -Weight 0.8
    }
    
    "learn" {
        # learn -Pattern "error" -Solution "fix" -Success
        $success = $Properties -eq "true" -or $Properties -eq "success"
        Learn-Pattern -Pattern $Entity -Solution $Relation -Success $success
    }
    
    "stats" {
        Get-Stats
    }
    
    default {
        # Query by default
        if ($Query) {
            Query-Graph -Query $Query
        } else {
            Get-Stats
        }
    }
}