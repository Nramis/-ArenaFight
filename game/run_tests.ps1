# Ejecuta la suite de tests (gdUnit4) en modo headless con el Godot local de .tools/.
# Uso:  .\run_tests.ps1            (toda la suite)
#       .\run_tests.ps1 test/unit  (solo una carpeta)
param([string]$Dir = "res://test")

$proj  = $PSScriptRoot
$godot = Join-Path $proj ".tools\Godot_v4.7.1-stable_win64_console.exe"

if (-not (Test-Path $godot)) {
	Write-Error "No se encontró Godot en .tools/. Descárgalo o ajusta la ruta en este script."
	exit 1
}

if ($Dir -notlike "res://*") { $Dir = "res://$Dir" }

& $godot --headless --path $proj `
	-s "res://addons/gdUnit4/bin/GdUnitCmdTool.gd" `
	--ignoreHeadlessMode -a $Dir
exit $LASTEXITCODE
