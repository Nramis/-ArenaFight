Add-Type -AssemblyName System.Speech

$assetDirectory = Join-Path $PSScriptRoot '..\game\assets\sfx'
$speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $speech.SelectVoice('Microsoft Pavel')
    $speech.Rate = 1
    foreach ($line in @(
        @{ File = 'yusupStory.wav'; Text = 'Там, короче...' },
        @{ File = 'yusupForget.wav'; Text = 'А забей!' }
    )) {
        $speech.SetOutputToWaveFile((Join-Path $assetDirectory $line.File))
        $speech.Speak($line.Text)
        $speech.SetOutputToNull()
    }
} finally {
    $speech.Dispose()
}
