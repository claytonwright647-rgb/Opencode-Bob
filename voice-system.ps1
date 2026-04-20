# BOB'S VOICE/SPEECH SYSTEM
# Speech interaction for Bob

param(
    [Parameter(Mandatory=$false)]
    [string]$Operation = "speak",  # speak, listen, status
    
    [Parameter(Mandatory=$false)]
    [string]$Text = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Voice = "default"  # default, male, female
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================
$VOICE_DIR = "C:\Users\clayt\opencode-bob\memory\voice"
$VOICE_CONFIG = "$VOICE_DIR\config.json"

if (-not (Test-Path $VOICE_DIR)) {
    New-Item -ItemType Directory -Force -Path $VOICE_DIR | Out-Null
}

# ============================================================================
# WINDOWS SPEECH SYNTHESIS
# Uses .NET SAPI for text-to-speech
# ============================================================================

function Initialize-VoiceConfig {
    # Get available voices
    Add-Type -AssemblyName System.Speech
    
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $voices = $synth.GetInstalledVoices() | ForEach-Object {
        $_.VoiceInfo.Name
    }
    $synth.Dispose()
    
    return @{
        available = $voices
        default = $voices[0]
    }
}

# ============================================================================
# SPEAK TEXT
# ============================================================================

function Invoke-Speak {
    param([string]$Text, [string]$Voice)
    
    Add-Type -AssemblyName System.Speech
    
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    
    # Select voice if specified and available
    if ($Voice -ne "default") {
        try {
            $synth.SelectVoice($Voice)
        } catch {
            # Use default if not found
        }
    }
    
    # Speak
    $synth.Speak($Text)
    $synth.Dispose()
    
    return @{
        success = $true
        text = $Text
        voice = $Voice
    }
}

# ============================================================================
# SPEAK TO FILE
# ============================================================================

function Export-Speech {
    param([string]$Text, [string]$OutputFile)
    
    Add-Type -AssemblyName System.Speech
    
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    
    # Create file
    $synth.SetOutputToWaveFile($OutputFile)
    $synth.Speak($Text)
    $synth.SetOutputToDefaultAudio()
    $synth.Dispose()
    
    return @{
        success = $true
        file = $OutputFile
    }
}

# ============================================================================
# TEXT TO SPEECH PRE-SCRIPTED RESPONSES
# Response templates for common interactions
# ============================================================================

$VOICE_RESPONSES = @{
    "greeting" = "Hello! I'm Opencode Bob. How can I help you today?"
    "thinking" = "Let me think about that..."
    "success" = "Done! I've completed that task."
    "error" = "I encountered an issue. Let me try a different approach."
    "va-ready" = "I have your VA claim information ready. You've filed for multiple conditions and we can expect a 70 to 100 percent rating."
    "context" = "I'm working on your request. Let me check the current status."
    "memory" = "Let me search my memory for that information."
}

# ============================================================================
# SPEAK PRE-SCRIPTED
# ============================================================================

function Speak-Response {
    param([string]$ResponseType)
    
    $response = $VOICE_RESPONSES[$ResponseType]
    if (-not $response) {
        return @{ success = $false; reason = "unknown_response_type" }
    }
    
    return Invoke-Speak -Text $response -Voice "default"
}

# ============================================================================
# STATUS
# ============================================================================

function Get-VoiceStatus {
    $config = Initialize-VoiceConfig
    
    return @{
        ready = $true
        voices = $config.available
        default = $config.default
        responses = $VOICE_RESPONSES.Keys
    }
}

# ============================================================================
# EXECUTE
# ============================================================================

switch ($Operation) {
    "speak" {
        if ($Text -eq "") {
            Write-Error "Text required"
        }
        Invoke-Speak -Text $Text -Voice $Voice
    }
    "say" {
        # Pre-scripted response
        if ($Text -eq "") {
            Write-Error "Response type required (greeting, thinking, success, error, va-ready)"
        }
        Speak-Response -ResponseType $Text
    }
    "export" {
        if ($Text -eq "") {
            Write-Error "Text required"
        }
        $outputFile = "$VOICE_DIR\speech.wav"
        Export-Speech -Text $Text -OutputFile $outputFile
    }
    "status" {
        Get-VoiceStatus
    }
    "voices" {
        Initialize-VoiceConfig
    }
    default {
        Write-Error "Unknown operation: $Operation"
    }
}