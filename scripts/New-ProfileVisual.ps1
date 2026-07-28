[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [psobject] $Data,

    [Parameter()]
    [string] $OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\assets\profile-story.svg'),

    [Parameter()]
    [string] $StaticOutputPath,

    [Parameter()]
    [string] $HtmlOutputPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not (Get-Command -Name New-ImageConsoleStory -ErrorAction SilentlyContinue)) {
    Import-Module -Name ImagePlayground -MinimumVersion 3.1.0 -ErrorAction Stop
}

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

$signal = [ChartForgeX.Terminal.TerminalTable]::Create()
[void] $signal.WithColumns([string[]]@('SIGNAL', 'VALUE'))
[void] $signal.AddRow([object[]]@('Maintained repositories', [string]$Data.Metrics.MaintainedRepositories))
[void] $signal.AddRow([object[]]@('Community stars', $starsValue))
[void] $signal.AddRow([object[]]@('Community forks', $forksValue))
[void] $signal.AddRow([object[]]@('Contributions (12 months)', $contributionValue))
[void] $signal.AddRow([object[]]@('Active days (12 months)', $activeDaysValue))
[void] $signal.AlignColumn(1, [ChartForgeX.Terminal.TerminalColumnAlignment]::Right)

$portfolio = [ChartForgeX.Terminal.TerminalTable]::Create()
[void] $portfolio.WithColumns([string[]]@('PROJECT', 'STACK', 'STARS', 'UPDATED'))
[void] $portfolio.AlignColumn(2, [ChartForgeX.Terminal.TerminalColumnAlignment]::Right)
foreach ($project in $Data.Projects) {
    $updated = [DateTime]::Parse([string]$project.PushedAt, $invariant).ToUniversalTime().ToString('MMM d', $invariant)
    [void] $portfolio.AddRow([object[]]@(
        [string]$project.Name,
        [string]$project.Language,
        ([int]$project.Stars).ToString('N0', $invariant),
        $updated
    ))
}

$story = New-ImageConsoleStory -StoryScript {
    param($Console)

    [void] $Console.WithTitle('pwsh - C:\OpenSource')
    [void] $Console.WithDialect([ChartForgeX.Terminal.TerminalDialect]::PowerShell)
    [void] $Console.WithWorkingDirectory('C:\OpenSource')
    [void] $Console.WithTheme([ChartForgeX.Terminal.TerminalTheme]::PowerShell())
    [void] $Console.WithWidth(886).WithTypography(13.5, 20).WithTiming(0.35, 52, 0.055)

    [void] $Console.Command("Get-EngineeringProfile -Name $userNameLiteral")
    [void] $Console.Output(('Name         ' + $profileName), [ChartForgeX.Terminal.TerminalTextTone]::Accent)
    [void] $Console.Output('Role         IT Architect / Open-source maintainer / Microsoft MVP')
    [void] $Console.Output("Focus        PowerShell $separator .NET $separator Identity $separator Microsoft 365 $separator Documents")
    [void] $Console.Output('Approach     Reusable cores. Thin surfaces. Production-grade automation.', [ChartForgeX.Terminal.TerminalTextTone]::Muted)
    [void] $Console.Blank()

    [void] $Console.Command("Get-OpenSourceSignal -Organization $organizationLiteral")
    [void] $Console.Table($signal)
    [void] $Console.Blank()

    [void] $Console.Command("Get-ActivePortfolio -Organization $organizationLiteral -Top 5")
    [void] $Console.Table($portfolio)
    [void] $Console.Blank()

    [void] $Console.Command('Get-EngineeringFocus -AsChecklist')
    [void] $Console.Output('[+] Identity and Windows infrastructure', [ChartForgeX.Terminal.TerminalTextTone]::Success)
    [void] $Console.Output('[+] Documents, reporting, and Microsoft 365 automation', [ChartForgeX.Terminal.TerminalTextTone]::Success)
    [void] $Console.Output('[+] Shared foundations that keep product surfaces thin', [ChartForgeX.Terminal.TerminalTextTone]::Success)
} -FilePath $OutputPath -PassThru

if (-not [string]::IsNullOrWhiteSpace($StaticOutputPath)) {
    $story | New-ImageConsoleStory -FilePath $StaticOutputPath
}
if (-not [string]::IsNullOrWhiteSpace($HtmlOutputPath)) {
    $story | New-ImageConsoleStory -FilePath $HtmlOutputPath
}

$story
