# Setup de Desenvolvimento Local com VPS Remota

Este guia configura um ambiente de desenvolvimento local que se conecta ao banco de dados e serviços da sua VPS no EasyPanel.

## 📋 Pré-requisitos

Você precisa instalar:

### 1. PHP 8.2+ (com extensões necessárias)

**Windows (Recomendado: Laravel Herd ou XAMPP)**

#### Opção A: Laravel Herd (Recomendado)
- Download: https://herd.laravel.com/
- Instala automaticamente: PHP, Node.js, Composer, SQLite
- Mais fácil e moderno

#### Opção B: XAMPP
- Download: https://www.apachefriends.org/
- Instale com PHP 8.2+
- Adicione ao PATH do Windows

**Verificar instalação:**
```powershell
php --version
composer --version
node --version
npm --version
```

### 2. Git (já deve estar instalado)
```powershell
git --version
```

## 🔧 Configuração do Ambiente Local

### Passo 1: Clonar o repositório (já feito)
```powershell
cd c:\Users\ferna\OneDrive\Documentos\REPOSITÓRIOS\Metr-pole-Zombie
```

### Passo 2: Criar arquivo .env para desenvolvimento local

Crie o arquivo `app/.env` com as seguintes configurações:

```env
APP_NAME="Zomboid Manager"
APP_ENV=local
APP_KEY=base64:YOUR_APP_KEY_HERE
APP_DEBUG=true
APP_URL=http://localhost:8000

# Banco de dados REMOTO (sua VPS)
DB_CONNECTION=pgsql
DB_HOST=seu-dominio-ou-ip-da-vps.com
DB_PORT=5432
DB_DATABASE=zomboid
DB_USERNAME=zomboid
DB_PASSWORD=sua-senha-do-banco

# Redis REMOTO (sua VPS)
REDIS_HOST=seu-dominio-ou-ip-da-vps.com
REDIS_PORT=6379
REDIS_PASSWORD=sua-senha-redis

# Game Server (sua VPS)
PZ_RCON_HOST=seu-dominio-ou-ip-da-vps.com
PZ_RCON_PORT=27015
PZ_RCON_PASSWORD=sua-senha-rcon

# Outros
DOCKER_PROXY_URL=http://localhost:2375
PZ_DATA_PATH=/pz-data
PZ_SERVER_PATH=/pz-server
BACKUP_PATH=/backups
LUA_BRIDGE_PATH=/lua-bridge
PZ_MAP_TILES_PATH=/map-tiles
```

**⚠️ IMPORTANTE:**
- Substitua `seu-dominio-ou-ip-da-vps.com` pelo IP ou domínio da sua VPS
- Substitua as senhas pelas senhas reais do seu banco de dados
- Gere uma APP_KEY: `php artisan key:generate`

### Passo 3: Instalar dependências

```powershell
cd c:\Users\ferna\OneDrive\Documentos\REPOSITÓRIOS\Metr-pole-Zombie\app

# Instalar dependências PHP
composer install

# Instalar dependências Node.js
npm install
```

### Passo 4: Gerar chave da aplicação

```powershell
php artisan key:generate
```

### Passo 5: Executar migrations (OPCIONAL - apenas se necessário)

Se quiser sincronizar o banco de dados local com a estrutura:

```powershell
php artisan migrate
```

## 🚀 Rodar o servidor de desenvolvimento

### Terminal 1: Servidor Laravel (API)
```powershell
cd c:\Users\ferna\OneDrive\Documentos\REPOSITÓRIOS\Metr-pole-Zombie\app
php artisan serve
```

Acesso: http://localhost:8000

### Terminal 2: Vite (Frontend - React)
```powershell
cd c:\Users\ferna\OneDrive\Documentos\REPOSITÓRIOS\Metr-pole-Zombie\app
npm run dev
```

Acesso: http://localhost:5173 (ou a porta que o Vite indicar)

## 📝 Workflow de Desenvolvimento

### 1. Editar código localmente
- Edite os arquivos `.tsx`, `.ts`, `.php` normalmente
- O Vite faz hot reload automático
- Laravel também recarrega mudanças

### 2. Testar localmente
- Acesse http://localhost:8000 ou http://localhost:5173
- Teste as funcionalidades
- Os dados vêm do banco de dados remoto da VPS

### 3. Fazer commit e push
```powershell
git add .
git commit -m "Descrição da mudança em português"
git push origin main
```

### 4. Deploy na VPS
No seu servidor EasyPanel:
```bash
cd /path/to/project
git pull origin main
docker compose -f docker-compose.easypanel.yml up -d --build
```

## 🔌 Conectar ao Banco de Dados Remoto

### Verificar conectividade

```powershell
# Testar conexão PostgreSQL
psql -h seu-dominio-ou-ip-da-vps.com -U zomboid -d zomboid -c "SELECT 1"

# Se psql não estiver instalado, você pode usar:
php artisan tinker
# Depois execute:
# DB::connection()->getPdo();
```

### Abrir porta no firewall da VPS (se necessário)

Se não conseguir conectar, pode ser que a porta PostgreSQL não esteja acessível. No seu servidor:

```bash
# Verificar se PostgreSQL está escutando
sudo netstat -tlnp | grep 5432

# Abrir porta no firewall (se usar ufw)
sudo ufw allow 5432/tcp from SEU_IP_LOCAL
```

## 🛠️ Troubleshooting

### Erro: "SQLSTATE[08006] could not connect to server"
- Verifique se o IP/domínio está correto
- Verifique se a porta está aberta na VPS
- Verifique as credenciais do banco de dados

### Erro: "php artisan not found"
- Certifique-se de que PHP está no PATH
- Reinicie o terminal após instalar PHP

### Erro: "npm: command not found"
- Instale Node.js (Laravel Herd ou Node.js direto)
- Reinicie o terminal

### Vite não carrega
- Certifique-se de que `npm run dev` está rodando em outro terminal
- Verifique se a porta 5173 não está em uso

## 📚 Estrutura do Projeto

```
app/
├── app/              # Código PHP (Controllers, Models, etc)
├── resources/
│   ├── js/          # Código React/TypeScript
│   │   └── pages/   # Páginas (welcome.tsx, etc)
│   └── views/       # Templates Blade
├── routes/          # Rotas da API
├── database/        # Migrations
├── public/          # Assets públicos
└── .env             # Configurações (NÃO commitar!)
```

## ✅ Checklist Final

- [ ] PHP 8.2+ instalado
- [ ] Node.js instalado
- [ ] Composer instalado
- [ ] Arquivo `.env` configurado com dados da VPS
- [ ] `composer install` executado
- [ ] `npm install` executado
- [ ] `php artisan key:generate` executado
- [ ] Consegue conectar ao banco de dados remoto
- [ ] `php artisan serve` rodando
- [ ] `npm run dev` rodando
- [ ] Acessa http://localhost:8000 com sucesso

## 🎯 Próximos Passos

1. Instale as ferramentas necessárias
2. Configure o arquivo `.env`
3. Execute os comandos de instalação
4. Inicie os servidores de desenvolvimento
5. Comece a editar o código!

Qualquer dúvida, consulte a documentação oficial:
- Laravel: https://laravel.com/docs
- Vite: https://vitejs.dev/
- React: https://react.dev/
