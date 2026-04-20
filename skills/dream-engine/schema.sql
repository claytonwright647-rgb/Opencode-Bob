-- Dream Engine Schema for Bob's Memory Consolidation
-- Inspired by neural-memory (itsXactlY)
-- Three phases: NREM, REM, Insight

-- ============================================================================
-- DREAM SESSIONS - Track each dream cycle
-- ============================================================================
CREATE TABLE IF NOT EXISTS dream_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phase TEXT NOT NULL,           -- 'nrem', 'rem', 'insight', 'full'
    started_at REAL NOT NULL,
    finished_at REAL,
    memories_processed INTEGER DEFAULT 0,
    connections_strengthened INTEGER DEFAULT 0,
    connections_pruned INTEGER DEFAULT 0,
    bridges_found INTEGER DEFAULT 0,
    insights_created INTEGER DEFAULT 0,
    duration_seconds REAL DEFAULT 0,
    status TEXT DEFAULT 'running'  -- 'running', 'completed', 'failed'
);

-- ============================================================================
-- DREAM INSIGHTS - Generated insights from dream cycles
-- ============================================================================
CREATE TABLE IF NOT EXISTS dream_insights (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER,
    insight_type TEXT NOT NULL, -- 'cluster', 'bridge', 'theme', 'pattern'
    source_memory_id INTEGER,
    content TEXT,
    confidence REAL DEFAULT 0.0,
    created_at REAL NOT NULL,
    FOREIGN KEY (session_id) REFERENCES dream_sessions(id)
);

-- ============================================================================
-- CONNECTION HISTORY - Track connection changes over time
-- ============================================================================
CREATE TABLE IF NOT EXISTS connection_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    old_weight REAL,
    new_weight REAL,
    reason TEXT,                  -- 'nrem_strengthen', 'nrem_weaken', 'rem_bridge', 'manual'
    changed_at REAL NOT NULL
);

-- ============================================================================
-- DREAM STATS - Aggregate statistics
-- ============================================================================
CREATE TABLE IF NOT EXISTS dream_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    total_cycles INTEGER DEFAULT 0,
    total_memories_processed INTEGER DEFAULT 0,
    total_connections_strengthened INTEGER DEFAULT 0,
    total_connections_pruned INTEGER DEFAULT 0,
    total_bridges_found INTEGER DEFAULT 0,
    total_insights_created INTEGER DEFAULT 0,
    last_dream_at REAL,
    last_dream_status TEXT
);

-- Initialize stats if empty
INSERT OR IGNORE INTO dream_stats (id, total_cycles) VALUES (1, 0);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_dream_insights_type ON dream_insights(insight_type);
CREATE INDEX IF NOT EXISTS idx_dream_insights_session ON dream_insights(session_id);
CREATE INDEX IF NOT EXISTS idx_connection_history_nodes ON connection_history(source_id, target_id);
CREATE INDEX IF NOT EXISTS idx_dream_sessions_status ON dream_sessions(status);