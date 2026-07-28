[CmdletBinding()]
param(
    [Parameter()]
    [string] $Organization = 'EvotecIT',

    [Parameter()]
    [string] $UserName = 'PrzemyslawKlys',

    [Parameter()]
    [string] $OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\assets\profile-story.svg'),

    [Parameter()]
    [string] $StaticOutputPath,

    [Parameter()]
    [string] $HtmlOutputPath,

    [Parameter()]
    [string] $Token = $env:GITHUB_TOKEN
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$data = & (Join-Path -Path $PSScriptRoot -ChildPath 'Get-GitHubProfileData.ps1') -Organization $Organization -UserName $UserName -Token $Token
& (Join-Path -Path $PSScriptRoot -ChildPath 'New-ProfileVisual.ps1') -Data $data -OutputPath $OutputPath -StaticOutputPath $StaticOutputPath -HtmlOutputPath $HtmlOutputPath
