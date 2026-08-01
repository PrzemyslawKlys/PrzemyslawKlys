[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [psobject] $Data,

    [Parameter()]
    [string] $OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\assets\profile-story.svg'),

    [Parameter()]
    [string] $StaticOutputPath,

    [Parameter()]
    [string] $AnimatedOutputPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\assets\profile-story.gif'),

    [Parameter()]
    [string] $HtmlOutputPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Import-Module -Name ImagePlayground -MinimumVersion 3.2.0 -Force -ErrorAction Stop

$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$profileName = [string]$Data.DisplayName
$userNameLiteral = "'" + ([string]$Data.UserName).Replace("'", "''") + "'"
$organizationLiteral = "'" + ([string]$Data.Organization).Replace("'", "''") + "'"
$separator = [char]0x00B7

$starsValue = [string]$Data.Metrics.Stars
if ([int]$Data.Metrics.Stars -ge 1000) {
    $starsValue = ([double]$Data.Metrics.Stars / 1000).ToString('0.0', $invariant) + 'K'
}
$forksValue = [string]$Data.Metrics.Forks
if ([int]$Data.Metrics.Forks -ge 1000) {
    $forksValue = ([double]$Data.Metrics.Forks / 1000).ToString('0.0', $invariant) + 'K'
}
$contributionValue = if (-not [bool]$Data.Metrics.ContributionDataAvailable) {
    'token required'
} elseif ([int]$Data.Metrics.Contributions -gt 0) {
    if ([int]$Data.Metrics.Contributions -ge 1000) {
        ([double]$Data.Metrics.Contributions / 1000).ToString('0.0', $invariant) + 'K'
    } else {
        [string]$Data.Metrics.Contributions
    }
} else {
    '0'
}
$activeDaysValue = if (-not [bool]$Data.Metrics.ContributionDataAvailable) {
    'token required'
} elseif ([int]$Data.Metrics.ActiveDays -gt 0) {
    [string]$Data.Metrics.ActiveDays
} else {
    '0'
}

$signal = @(
    [pscustomobject]@{ Signal = 'Maintained repositories'; Value = [string]$Data.Metrics.MaintainedRepositories }
    [pscustomobject]@{ Signal = 'Community stars'; Value = $starsValue }
    [pscustomobject]@{ Signal = 'Community forks'; Value = $forksValue }
    [pscustomobject]@{ Signal = 'Contributions (12 months)'; Value = $contributionValue }
    [pscustomobject]@{ Signal = 'Active days (12 months)'; Value = $activeDaysValue }
)

[array] $portfolio = foreach ($project in $Data.Projects) {
    $updated = [DateTime]::Parse([string]$project.PushedAt, $invariant).ToUniversalTime().ToString('MMM d', $invariant)
    [pscustomobject]@{
        Project = [string]$project.Name
        Stack   = [string]$project.Language
        Stars   = ([int]$project.Stars).ToString('N0', $invariant)
        Updated = $updated
    }
}

$story = New-ImageConsoleStory `
    -Title 'pwsh - C:\OpenSource' `
    -Dialect PowerShell `
    -WorkingDirectory 'C:\OpenSource' `
    -Theme PowerShell `
    -Width 886 `
    -FontSize 13.5 `
    -LineHeight 20 `
    -InitialDelaySeconds 0.35 `
    -CharactersPerSecond 52 `
    -LineDelaySeconds 0.055 `
    -Content {
        New-ImageConsoleStoryCommand -Text "Get-EngineeringProfile -Name $userNameLiteral"
        New-ImageConsoleStoryOutput -Text ('Name         ' + $profileName) -Tone Accent
        New-ImageConsoleStoryOutput -Text 'Role         IT Architect / Open-source maintainer / Microsoft MVP'
        New-ImageConsoleStoryOutput -Text "Focus        PowerShell $separator .NET $separator Identity $separator Microsoft 365 $separator Documents"
        New-ImageConsoleStoryOutput -Text 'Approach     Reusable cores. Thin surfaces. Production-grade automation.' -Tone Muted
        New-ImageConsoleStoryBlankLine

        New-ImageConsoleStoryCommand -Text "Get-OpenSourceSignal -Organization $organizationLiteral"
        $signal | New-ImageConsoleStoryTable -Property Signal, Value -Header SIGNAL, VALUE -Align @{ Value = 'Right' }
        New-ImageConsoleStoryBlankLine

        New-ImageConsoleStoryCommand -Text "Get-ActivePortfolio -Organization $organizationLiteral -Top 5"
        $portfolio | New-ImageConsoleStoryTable -Property Project, Stack, Stars, Updated -Header PROJECT, STACK, STARS, UPDATED -Align @{ Stars = 'Right' }
        New-ImageConsoleStoryBlankLine

        New-ImageConsoleStoryCommand -Text 'Get-EngineeringFocus -AsChecklist'
        New-ImageConsoleStoryOutput -Text '[+] Identity and Windows infrastructure' -Tone Success
        New-ImageConsoleStoryOutput -Text '[+] Documents, reporting, and Microsoft 365 automation' -Tone Success
        New-ImageConsoleStoryOutput -Text '[+] Shared foundations that keep product surfaces thin' -Tone Success
    } `
    -FilePath $OutputPath `
    -PassThru

if (-not [string]::IsNullOrWhiteSpace($StaticOutputPath)) {
    $story | New-ImageConsoleStory -FilePath $StaticOutputPath
}
if (-not [string]::IsNullOrWhiteSpace($AnimatedOutputPath)) {
    $story | New-ImageConsoleStory -FilePath $AnimatedOutputPath -FramesPerSecond 8 -EndHoldSeconds 1.5
}
if (-not [string]::IsNullOrWhiteSpace($HtmlOutputPath)) {
    $story | New-ImageConsoleStory -FilePath $HtmlOutputPath
}

$story
