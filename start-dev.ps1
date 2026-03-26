#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script para iniciar o servidor de desenvolvimento local
.DESCRIPTION
    Inicia Laravel e Vite em paralelo para desenvolvimento
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Iniciando Servidor de Desenvolvimento" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-not (Test-Path "app")) {
    Write-Host "❌ Erro: Execute este script no diretório raiz do projeto" -ForegroundColor Red
    exit 1
}

# Verificar se .env existe
if (-not (Test-Path "app\.env")) {
    Write-Host "❌ Erro: Arquivo app\.env não encontrado" -ForegroundColor Red
    Write-Host "Execute primeiro: .\setup-local-dev.ps1" -ForegroundColor Yellow
    exit 1
}

Set-Location app

Write-Host "📝 Configuração:" -ForegroundColor Cyan
Write-Host "  Laravel: http://localhost:8000" -ForegroundColor Green
Write-Host "  Vite:    http://localhost:5173" -ForegroundColor Green
Write-Host ""
Write-Host "⏳ Iniciando servidores..." -ForegroundColor Yellow
Write-Host ""

# Iniciar Laravel em background
Write-Host "🚀 Iniciando Laravel..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "php artisan serve"

# Aguardar um pouco para Laravel iniciar
Start-Sleep -Seconds 3

# Iniciar Vite em foreground
Write-Host "🚀 Iniciando Vite..." -ForegroundColor Cyan
npm run dev

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Servidores encerrados" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
