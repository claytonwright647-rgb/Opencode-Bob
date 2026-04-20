# BOB'S REST API SERVER
# HTTP server for remote access to Bob
# Simple Flask-based API

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "start",  # start, stop, status
    
    [Parameter(Mandatory=$false)]
    [string]$Port = "18789"  # Default port (OpenClaw uses 18789)
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$API_DIR = "C:\Users\clayt\opencode-bob\api"
$API_SERVER = "$API_DIR\server.py"
$API_CONFIG = "$API_DIR\config.json"

if (-not (Test-Path $API_DIR)) {
    New-Item -ItemType Directory -Force -Path $API_DIR | Out-Null
}

# ============================================================================
# API SERVER TEMPLATE
# ============================================================================

$SERVER_CODE = @"
# Bob REST API Server
# Simple Flask API for remote access

from flask import Flask, request, jsonify
import subprocess
import json
import os

app = Flask(__name__)

# Base directory for Bob
BOB_DIR = r'C:\Users\clayt\opencode-bob'

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'name': 'Opencode Bob',
        'version': '1.0'
    })

# ============================================================================
# RUN POWERSHELL SCRIPT
# ============================================================================

def run_script(script, args=''):
    \"\"\"Run a PowerShell script and return output\"\"\"
    cmd = f'powershell -File {BOB_DIR}\{script}'
    if args:
        cmd += f' -{args.replace(' ', ' -')}'
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        return {
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/api/status', methods=['GET'])
def api_status():
    return jsonify(run_script('session-tracker.ps1', 'Operation status'))

@app.route('/api/memory', methods=['GET', 'POST'])
def api_memory():
    if request.method == 'GET':
        return jsonify(run_script('knowledge-graph.ps1', 'Operation read_graph'))
    
    data = request.json
    return jsonify(run_script('knowledge-graph.ps1', f'Operation create_entity Name={data.get("name")} Type={data.get("type")}'))

@app.route('/api/context', methods=['GET'])
def api_context():
    return jsonify(run_script('context-manager.ps1', 'Operation status'))

@app.route('/api/goals', methods=['GET'])
def api_goals():
    return jsonify(run_script('goal-tracker.ps1', 'Operation status'))

@app.route('/api/VA/claims', methods=['GET'])
def api_va_claims():
    \"\"\"Get VA claim status\"\"\"
    # Quick access to VA info
    va_info = {
        'filed': 'January 4, 2026',
        'expected_rating': '70-90% or 100% with TDIU',
        'back_pay': '\$7,000-\$12,000'
    }
    return jsonify(va_info)

# ============================================================================
# RUN COMMAND
# ============================================================================

@app.route('/api/run', methods=['POST'])
def api_run():
    \"\"\"Run arbitrary command\"\"\"
    data = request.json
    script = data.get('script', 'session-tracker.ps1')
    args = data.get('args', '')
    
    return jsonify(run_script(script, args))

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=False)
"@

# ============================================================================
# INSTALL FLASK
# ============================================================================

$installFlask = @"
if (!(Get-Module -ListAvailable -Name Flask)) {
    Write-Host 'Installing Flask...'
    pip install Flask
}
"@

# ============================================================================
# START SERVER
# ============================================================================

function Start-API {
    param([string]$Port)
    
    # Create server file
    $SERVER_CODE | Set-Content $API_SERVER
    
    # Start server in background
    $process = Start-Process -FilePath "python" -ArgumentList $API_SERVER -WindowStyle Hidden -PassThru
    
    return @{
        success = $true
        port = $Port
        url = "http://localhost:$Port"
        docs = "http://localhost:$Port/docs"
    }
}

# ============================================================================
# STOP SERVER
# ============================================================================

function Stop-API {
    # Find and stop Python processes running the API
    $procs = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*server.py*" -or $_.CommandLine -like "*api*"
    }
    
    foreach ($p in $procs) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
    
    return @{
        success = $true
        message = "API server stopped"
    }
}

# ============================================================================
# STATUS
# ============================================================================

function Get-APIStatus {
    $running = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*api*"
    }
    
    return @{
        running = $running -ne $null
        port = $Port
        endpoints = @(
            "/health",
            "/api/status",
            "/api/memory",
            "/api/context",
            "/api/goals",
            "/api/VA/claims",
            "/api/run"
        )
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "start" {
        Start-API -Port $Port
    }
    "stop" {
        Stop-API
    }
    "status" {
        Get-APIStatus -Port $Port
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}