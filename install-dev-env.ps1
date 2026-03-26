#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script para instalar ambiente de desenvolvimento completo no Windows
.DESCRIPTION
    Instala PHP 8.2, Composer e configura tudo automaticamente
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalação de Ambiente de Desenvolvimento" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Função para verificar se comando existe
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Verificar se está rodando como admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️  Este script precisa ser executado como Administrador" -ForegroundColor Yellow
    Write-Host "Reiniciando com privilégios de administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "✅ Rodando como Administrador" -ForegroundColor Green
Write-Host ""

# Instalar Scoop se não existir
if (-not (Test-CommandExists scoop)) {
    Write-Host "📦 Instalando Scoop (gerenciador de pacotes)..." -ForegroundColor Yellow
    
    # Habilitar execução de scripts
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    
    # Instalar Scoop
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao instalar Scoop" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Scoop instalado!" -ForegroundColor Green
} else {
    Write-Host "✅ Scoop já está instalado" -ForegroundColor Green
}

Write-Host ""

# Instalar PHP 8.2
if (-not (Test-CommandExists php)) {
    Write-Host "📦 Instalando PHP 8.2..." -ForegroundColor Yellow
    scoop install php
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao instalar PHP" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ PHP 8.2 instalado!" -ForegroundColor Green
} else {
    Write-Host "✅ PHP já está instalado" -ForegroundColor Green
    php --version
}

Write-Host ""

# Instalar Composer
if (-not (Test-CommandExists composer)) {
    Write-Host "📦 Instalando Composer..." -ForegroundColor Yellow
    scoop install composer
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao instalar Composer" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Composer instalado!" -ForegroundColor Green
} else {
    Write-Host "✅ Composer já está instalado" -ForegroundColor Green
    composer --version
}

Write-Host ""

# Verificar Node.js e npm
if (Test-CommandExists node) {
    Write-Host "✅ Node.js já está instalado" -ForegroundColor Green
    node --version
} else {
    Write-Host "📦 Instalando Node.js..." -ForegroundColor Yellow
    scoop install nodejs
    Write-Host "✅ Node.js instalado!" -ForegroundColor Green
}

Write-Host ""

# Resumo
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Ambiente instalado com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Versões instaladas:" -ForegroundColor Cyan
php --version
composer --version
node --version
npm --version
Write-Host ""
Write-Host "Proximo passo: Execute setup-local-dev.ps1" -ForegroundColor Yellow
Write-Host ""
