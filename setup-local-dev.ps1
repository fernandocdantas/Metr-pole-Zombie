#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script de setup para ambiente de desenvolvimento local conectado à VPS
.DESCRIPTION
    Instala dependências e configura ambiente para desenvolvimento local
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup de Desenvolvimento Local - Metr-pole-Zombie" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-not (Test-Path "app")) {
    Write-Host "❌ Erro: Execute este script no diretório raiz do projeto" -ForegroundColor Red
    exit 1
}

# Verificar dependências
Write-Host "🔍 Verificando dependências..." -ForegroundColor Yellow

$php_installed = $null -ne (Get-Command php -ErrorAction SilentlyContinue)
$node_installed = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
$npm_installed = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)
$composer_installed = $null -ne (Get-Command composer -ErrorAction SilentlyContinue)
$git_installed = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

Write-Host ""
Write-Host "Status das dependências:" -ForegroundColor Cyan
Write-Host "  PHP:       $(if ($php_installed) { '✅ Instalado' } else { '❌ NÃO instalado' })"
Write-Host "  Node.js:   $(if ($node_installed) { '✅ Instalado' } else { '❌ NÃO instalado' })"
Write-Host "  npm:       $(if ($npm_installed) { '✅ Instalado' } else { '❌ NÃO instalado' })"
Write-Host "  Composer:  $(if ($composer_installed) { '✅ Instalado' } else { '❌ NÃO instalado' })"
Write-Host "  Git:       $(if ($git_installed) { '✅ Instalado' } else { '❌ NÃO instalado' })"
Write-Host ""

if (-not $php_installed -or -not $node_installed -or -not $npm_installed) {
    Write-Host "⚠️  Dependências faltando!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instale as ferramentas necessárias:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Laravel Herd (Recomendado - instala PHP, Node, Composer):" -ForegroundColor Cyan
    Write-Host "   https://herd.laravel.com/" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. OU instale manualmente:" -ForegroundColor Cyan
    Write-Host "   - PHP 8.2+: https://www.php.net/downloads" -ForegroundColor Green
    Write-Host "   - Node.js: https://nodejs.org/" -ForegroundColor Green
    Write-Host "   - Composer: https://getcomposer.org/" -ForegroundColor Green
    Write-Host ""
    Write-Host "Após instalar, reinicie o PowerShell e execute este script novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Todas as dependências estão instaladas!" -ForegroundColor Green
Write-Host ""

# Navegar para diretório app
Set-Location app

# Instalar dependências PHP
Write-Host "📦 Instalando dependências PHP (Composer)..." -ForegroundColor Yellow
composer install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências PHP" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependências PHP instaladas!" -ForegroundColor Green
Write-Host ""

# Instalar dependências Node.js
Write-Host "📦 Instalando dependências Node.js (npm)..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências Node.js" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependências Node.js instaladas!" -ForegroundColor Green
Write-Host ""

# Verificar se .env existe
if (-not (Test-Path ".env")) {
    Write-Host "📝 Criando arquivo .env..." -ForegroundColor Yellow
    
    if (Test-Path ".env.local.example") {
        Copy-Item ".env.local.example" ".env"
        Write-Host "✅ Arquivo .env criado a partir de .env.local.example" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANTE: Edite o arquivo .env com suas configurações:" -ForegroundColor Yellow
        Write-Host "   - DB_HOST: IP ou domínio da sua VPS" -ForegroundColor Cyan
        Write-Host "   - DB_PASSWORD: Senha do banco de dados" -ForegroundColor Cyan
        Write-Host "   - REDIS_HOST: IP ou domínio da sua VPS" -ForegroundColor Cyan
        Write-Host "   - REDIS_PASSWORD: Senha do Redis" -ForegroundColor Cyan
        Write-Host "   - PZ_RCON_HOST: IP ou domínio da sua VPS" -ForegroundColor Cyan
        Write-Host "   - PZ_RCON_PASSWORD: Senha do RCON" -ForegroundColor Cyan
    } else {
        Copy-Item ".env.example" ".env"
        Write-Host "✅ Arquivo .env criado a partir de .env.example" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANTE: Edite o arquivo .env com suas configurações de VPS" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  Arquivo .env já existe" -ForegroundColor Blue
}
Write-Host ""

# Gerar APP_KEY
Write-Host "🔑 Gerando chave da aplicação..." -ForegroundColor Yellow
php artisan key:generate
Write-Host "✅ Chave gerada!" -ForegroundColor Green
Write-Host ""

# Resumo final
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Setup concluído com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Próximos passos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Edite o arquivo .env com suas configurações de VPS:" -ForegroundColor Cyan
Write-Host "   notepad .env" -ForegroundColor Green
Write-Host ""
Write-Host "2. Em um terminal, inicie o servidor Laravel:" -ForegroundColor Cyan
Write-Host "   php artisan serve" -ForegroundColor Green
Write-Host ""
Write-Host "3. Em outro terminal, inicie o Vite (React):" -ForegroundColor Cyan
Write-Host "   npm run dev" -ForegroundColor Green
Write-Host ""
Write-Host "4. Acesse a aplicação:" -ForegroundColor Cyan
Write-Host "   http://localhost:8000" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Documentação: Leia o arquivo SETUP_LOCAL_DEV.md para mais detalhes" -ForegroundColor Cyan
Write-Host ""
