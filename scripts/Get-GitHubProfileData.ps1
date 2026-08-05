[CmdletBinding()]
param(
    [Parameter()]
    [string] $Organization = 'EvotecIT',

    [Parameter()]
    [string] $UserName = 'PrzemyslawKlys',

    [Parameter()]
    [string] $Token = $env:GITHUB_TOKEN
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$headers = @{
    Accept                 = 'application/vnd.github+json'
    'User-Agent'           = 'PrzemyslawKlys-profile-visual'
    'X-GitHub-Api-Version' = '2022-11-28'
}
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $headers.Authorization = "Bearer $Token"
}

$repositories = [System.Collections.Generic.List[object]]::new()
$page = 1
while ($true) {
    $uri = "https://api.github.com/orgs/$Organization/repos?type=public&sort=updated&per_page=100&page=$page"
    $batch = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    foreach ($repository in $batch) {
        $repositories.Add($repository)
    }
    if ($batch.Count -lt 100) {
        break
    }
    $page++
}

$profile = Invoke-RestMethod -Uri "https://api.github.com/users/$UserName" -Headers $headers -Method Get
$displayName = if ([string]::IsNullOrWhiteSpace([string]$profile.name)) { [string]$profile.login } else { [string]$profile.name }
$maintained = @($repositories | Where-Object { -not $_.archived -and -not $_.fork })
$totalStars = 0
$totalForks = 0
foreach ($repository in $maintained) {
    $totalStars += [int]$repository.stargazers_count
    $totalForks += [int]$repository.forks_count
}
$now = [DateTime]::UtcNow
$activeCutoff = $now.AddDays(-90)
$portfolioCutoff = $now.AddDays(-180)
$activeProjects = @($maintained | Where-Object { ([DateTime]$_.pushed_at).ToUniversalTime() -ge $activeCutoff })
$portfolio = @(
    $maintained |
        Where-Object { ([DateTime]$_.pushed_at).ToUniversalTime() -ge $portfolioCutoff } |
        Sort-Object -Property @{ Expression = 'stargazers_count'; Descending = $true }, @{ Expression = 'pushed_at'; Descending = $true } |
        Select-Object -First 5 |
        ForEach-Object {
            [pscustomobject] @{
                Name        = $_.name
                Stars       = [int]$_.stargazers_count
                Forks       = [int]$_.forks_count
                Language    = if ([string]::IsNullOrWhiteSpace($_.language)) { 'Mixed' } else { $_.language }
                PushedAt    = ([DateTime]$_.pushed_at).ToUniversalTime().ToString('o')
                Url         = $_.html_url
                Description = $_.description
            }
        }
)

$contributionDays = @()
$totalContributions = 0
$activeDays = 0
$contributionDataAvailable = $false
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $from = $now.Date.AddDays(-364).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $to = $now.Date.AddDays(1).AddSeconds(-1).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $query = @'
query($login: String!, $from: DateTime!, $to: DateTime!) {
  user(login: $login) {
    contributionsCollection(from: $from, to: $to) {
      contributionCalendar {
        totalContributions
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}
'@
    $body = @{
        query     = $query
        variables = @{
            login = $UserName
            from  = $from
            to    = $to
        }
    } | ConvertTo-Json -Depth 8
    $response = Invoke-RestMethod -Uri 'https://api.github.com/graphql' -Headers $headers -Method Post -Body $body -ContentType 'application/json'
    if ($null -ne $response.PSObject.Properties['errors'] -and $response.errors) {
        throw "GitHub contribution query failed: $($response.errors.message -join '; ')"
    }

    $calendar = $response.data.user.contributionsCollection.contributionCalendar
    $totalContributions = [int]$calendar.totalContributions
    $contributionDays = @(
        $calendar.weeks |
            ForEach-Object { $_.contributionDays } |
            ForEach-Object {
                [pscustomobject] @{
                    Date  = $_.date
                    Count = [int]$_.contributionCount
                }
            }
    )
    $activeDays = @($contributionDays | Where-Object Count -gt 0).Count
    $contributionDataAvailable = $true
}

[pscustomobject] @{
    GeneratedAt      = $now.ToString('o')
    Organization     = $Organization
    UserName         = $UserName
    DisplayName      = $displayName
    Metrics          = [pscustomobject] @{
        MaintainedRepositories = $maintained.Count
        Stars                  = $totalStars
        Forks                  = $totalForks
        ActiveProjects         = $activeProjects.Count
        Contributions         = $totalContributions
        ActiveDays             = $activeDays
        ContributionDataAvailable = $contributionDataAvailable
    }
    ContributionDays = $contributionDays
    Projects         = $portfolio
}
