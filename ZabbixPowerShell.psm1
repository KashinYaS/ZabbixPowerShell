$functions = Get-ChildItem -Recurse "$PSScriptRoot\ZabbixPowerShellPS" -Include *.ps1 

# dot source the individual scripts that make-up this module
foreach ($function in $functions) { . $function.FullName }

Write-Host -ForegroundColor Green "Module $(Split-Path $PSScriptRoot -Leaf) was successfully loaded."