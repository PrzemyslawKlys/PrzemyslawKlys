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

$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$background = [ChartForgeX.Primitives.ChartColor]::FromHex('#07111F')
$card = [ChartForgeX.Primitives.ChartColor]::FromHex('#0D1B2E')
$plot = [ChartForgeX.Primitives.ChartColor]::FromHex('#0A1728')
$border = [ChartForgeX.Primitives.ChartColor]::FromHex('#203653')
$text = [ChartForgeX.Primitives.ChartColor]::FromHex('#F4F8FF')
$muted = [ChartForgeX.Primitives.ChartColor]::FromHex('#91A6C2')
$cyan = [ChartForgeX.Primitives.ChartColor]::FromHex('#5ED7F2')
$mint = [ChartForgeX.Primitives.ChartColor]::FromHex('#49D6A7')
$amber = [ChartForgeX.Primitives.ChartColor]::FromHex('#F5C76A')
$profileName = 'Przemys' + [char]0x0142 + 'aw K' + [char]0x0142 + 'ys'
$separator = [char]0x00B7

$theme = [ChartForgeX.Themes.ChartTheme]::ReportDark()
[void] $theme.WithSurfaceColors($background, $card, $plot, $border, $border)
[void] $theme.WithTextColors($text, $muted)
[void] $theme.WithGuideColors([ChartForgeX.Primitives.ChartColor]::FromHex('#20324A'), [ChartForgeX.Primitives.ChartColor]::FromHex('#35506E'))
[void] $theme.WithPalette([string[]]@('#5ED7F2', '#6E8CFF', '#49D6A7', '#F5C76A', '#C084FC'))
[void] $theme.WithSemanticColors($mint, $amber, [ChartForgeX.Primitives.ChartColor]::FromHex('#FB7185'))
[void] $theme.WithTypography(30, 14, 13, 11, 11, 11)
[void] $theme.WithCornerRadius(20, 14)

$starsValue = [string]$Data.Metrics.Stars
if ([int]$Data.Metrics.Stars -ge 1000) {
    $starsValue = ([double]$Data.Metrics.Stars / 1000).ToString('0.0', $invariant) + 'K'
}
$contributionValue = [string]$Data.Metrics.Contributions
if ([int]$Data.Metrics.Contributions -ge 1000) {
    $contributionValue = ([double]$Data.Metrics.Contributions / 1000).ToString('0.0', $invariant) + 'K'
}

$repositoriesCard = [ChartForgeX.VisualBlocks.MetricCard]::Create()
[void] $repositoriesCard.WithMetric('Maintained repositories', [string]$Data.Metrics.MaintainedRepositories).WithCaption('public projects in EvotecIT').WithSymbol('OSS').WithStatus([ChartForgeX.VisualBlocks.VisualStatus]::Info).WithTheme($theme).WithSize(410, 132).WithPadding(22, 18, 22, 16)

$starsCard = [ChartForgeX.VisualBlocks.MetricCard]::Create()
[void] $starsCard.WithMetric('Community stars', $starsValue).WithCaption('across maintained projects').WithSymbol('STAR').WithStatus([ChartForgeX.VisualBlocks.VisualStatus]::Positive).WithTheme($theme).WithSize(410, 132).WithPadding(22, 18, 22, 16)

$forksCard = [ChartForgeX.VisualBlocks.MetricCard]::Create()
[void] $forksCard.WithMetric('Community forks', [string]$Data.Metrics.Forks).WithCaption('ideas carried into new work').WithSymbol('FORK').WithStatus([ChartForgeX.VisualBlocks.VisualStatus]::Neutral).WithTheme($theme).WithSize(410, 132).WithPadding(22, 18, 22, 16)

$contributionsCard = [ChartForgeX.VisualBlocks.MetricCard]::Create()
[void] $contributionsCard.WithMetric('Contributions', $contributionValue).WithCaption("$($Data.Metrics.ActiveDays) active days $separator last 12 months").WithSymbol('365').WithStatus([ChartForgeX.VisualBlocks.VisualStatus]::Info).WithTheme($theme).WithSize(410, 132).WithPadding(22, 18, 22, 16)

$calendarItems = [ChartForgeX.Core.ChartCalendarHeatmapItem[]]@(
    foreach ($day in $Data.ContributionDays) {
        [ChartForgeX.Core.ChartCalendarHeatmapItem]::new([DateTime]::Parse([string]$day.Date, $invariant), [double]$day.Count)
    }
)
if ($calendarItems.Count -eq 0) {
    $calendarItems = [ChartForgeX.Core.ChartCalendarHeatmapItem[]]@(
        [ChartForgeX.Core.ChartCalendarHeatmapItem]::new([DateTime]::UtcNow.Date, 0)
    )
}
$calendar = [ChartForgeX.Core.Chart]::Create()
[void] $calendar.WithTitle('Contribution rhythm').WithSubtitle('A year of engineering activity across GitHub').WithTheme($theme).WithSize(838, 264).WithPadding(36, 50, 20, 36).WithLegend($false)
[void] $calendar.AddCalendarHeatmap('Contributions', $calendarItems, $cyan)

$projects = [ChartForgeX.VisualBlocks.ChartTable]::Create()
[void] $projects.WithTitle('Active portfolio').WithSubtitle('Recently shipped EvotecIT projects, ranked by community reach').WithTheme($theme).WithSize(838, 264).WithDenseMode()
[void] $projects.WithColumns([string[]]@('Project', 'Stack', 'Stars', 'Updated'))
foreach ($project in $Data.Projects) {
    $updated = [DateTime]::Parse([string]$project.PushedAt, $invariant).ToUniversalTime().ToString('MMM d', $invariant)
    [void] $projects.AddRow([object[]]@(
        [string]$project.Name,
        [string]$project.Language,
        ([int]$project.Stars).ToString('N0', $invariant),
        $updated
    ))
}

$grid = [ChartForgeX.VisualBlocks.VisualGrid]::Create()
[void] $grid.WithTitle("$profileName $separator Engineering in public")
[void] $grid.WithSubtitle("PowerShell $separator .NET $separator Active Directory $separator Microsoft 365 $separator document automation")
[void] $grid.WithTheme($theme).WithColumns(2).WithPanelSize(410, 132).WithGap(18).WithPadding(24).WithFrame()
[void] $grid.Add('repositories', $repositoriesCard)
[void] $grid.Add('stars', $starsCard)
[void] $grid.Add('forks', $forksCard)
[void] $grid.Add('contributions', $contributionsCard)
[void] $grid.Add('calendar', $calendar, 2, 2)
[void] $grid.Add('projects', $projects, 2, 2)

$motion = [ChartForgeX.Motion.VisualMotionTimeline]::Create()
[void] $motion.Reveal('title', 0, 0.85)
[void] $motion.Fade('subtitle', 0.12, 0.65)
[void] $motion.Rise('repositories', 0.3, 0.68, 10)
[void] $motion.Rise('stars', 0.42, 0.68, 10)
[void] $motion.Rise('forks', 0.54, 0.68, 10)
[void] $motion.Rise('contributions', 0.66, 0.68, 10)
[void] $motion.Rise('calendar', 0.9, 0.72, 12)
[void] $motion.Rise('projects', 1.14, 0.72, 12)

$story = New-ImageVisualStory -Grid $grid -Motion $motion -FilePath $OutputPath -PassThru
if (-not [string]::IsNullOrWhiteSpace($StaticOutputPath)) {
    $story | New-ImageVisualStory -FilePath $StaticOutputPath
}
if (-not [string]::IsNullOrWhiteSpace($HtmlOutputPath)) {
    $story | New-ImageVisualStory -FilePath $HtmlOutputPath
}

$story
