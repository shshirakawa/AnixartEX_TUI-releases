# AnixartEX TUI — установщик для Windows (PowerShell 5.1+)
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$DEFAULT_VERSION = "2.0.0"
$DEFAULT_RELEASE_TAG = "celestia"
$DEFAULT_BASE_URL = "https://github.com/ShakhShirakawa/AnixartEX_TUI-releases/releases/download"

$Version = if ($env:ANIXARTEX_VERSION) { $env:ANIXARTEX_VERSION } else { $DEFAULT_VERSION }
$ReleaseTag = if ($env:ANIXARTEX_RELEASE_TAG) { $env:ANIXARTEX_RELEASE_TAG } else { $DEFAULT_RELEASE_TAG }
$BaseUrl = if ($env:ANIXARTEX_BASE_URL) { $env:ANIXARTEX_BASE_URL } else { $DEFAULT_BASE_URL }
$InstallDir = if ($env:ANIXARTEX_INSTALL_DIR) { $env:ANIXARTEX_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "anixartex-tui" }
$BinDir = Join-Path $InstallDir "bin"

function Write-Log([string]$Message) {
    Write-Host "→ $Message"
}

function Write-Err([string]$Message) {
    Write-Error $Message
}

function Test-NodeVersion {
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) {
        Write-Err "Node.js не найден. Установи Node.js 24 LTS+: https://nodejs.org"
    }

    $version = & node -p "process.versions.node.split('.')[0]"
    if ([int]$version -lt 24) {
        $current = & node -v
        Write-Err "нужен Node.js 24 LTS+, сейчас: $current"
    }
}

function Get-ArchiveName {
    return "anixartex-tui-$Version-win.zip"
}

function Get-DownloadUrl {
    $archive = Get-ArchiveName
    return "$BaseUrl/$ReleaseTag/$archive"
}

function Install-Release {
    $archive = Get-ArchiveName
    $url = Get-DownloadUrl
    $tmp = Join-Path $env:TEMP ("anixartex-install-" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        $archivePath = Join-Path $tmp $archive
        Write-Log "скачивание $Version ($ReleaseTag)"
        Write-Log $url

        Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing

        Write-Log "установка в $InstallDir"
        if (Test-Path $InstallDir) {
            Remove-Item -Recurse -Force $InstallDir
        }

        $extractRoot = Join-Path $tmp "extract"
        New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
        Expand-Archive -Path $archivePath -DestinationPath $extractRoot -Force

        $extracted = Join-Path $extractRoot "anixartex-tui-$Version"
        if (-not (Test-Path $extracted)) {
            Write-Err "неверная структура архива"
        }

        Move-Item -Path $extracted -Destination $InstallDir

        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$BinDir*") {
            Write-Log "добавление $BinDir в PATH пользователя"
            $newPath = if ($userPath) { "$userPath;$BinDir" } else { $BinDir }
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = "$env:Path;$BinDir"
        }

        Write-Log "готово: anixartex v$Version"
        Write-Log "запуск: anixartex (перезапусти терминал, если команда не найдена)"
    }
    finally {
        if (Test-Path $tmp) {
            Remove-Item -Recurse -Force $tmp
        }
    }
}

function Show-Help {
    @"
AnixartEX TUI — установщик для Windows

Использование:
  irm <url>/install-windows.ps1 | iex
  или: .\install-windows.ps1

Переменные окружения:
  ANIXARTEX_VERSION     версия (по умолчанию $DEFAULT_VERSION)
  ANIXARTEX_RELEASE_TAG тег релиза (по умолчанию $DEFAULT_RELEASE_TAG)
  ANIXARTEX_INSTALL_DIR каталог установки
  ANIXARTEX_BASE_URL    базовый URL релизов

Требования: Node.js 24 LTS+, Windows Terminal / PowerShell 5.1+
"@
}

if ($args -contains "-h" -or $args -contains "--help") {
    Show-Help
    exit 0
}

Test-NodeVersion
Install-Release
