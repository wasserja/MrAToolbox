# Source all ps1 scripts in current directory.
#Get-ChildItem (Join-Path $PSScriptRoot *.ps1) | foreach {. $_.FullName}

foreach ($file in Get-ChildItem $PSScriptRoot\*.ps1) {
    . (
        [scriptblock]::Create(
            [io.file]::ReadAllText($file)
        )
    )
}