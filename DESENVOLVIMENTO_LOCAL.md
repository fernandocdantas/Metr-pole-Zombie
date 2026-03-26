# 🚀 Desenvolvimento Local Conectado à VPS

Este projeto está configurado para permitir desenvolvimento local com banco de dados e serviços remotos na sua VPS com EasyPanel.

## ⚡ Quick Start (5 minutos)

### 1. Instalar dependências
Se você ainda não tem PHP, Node.js e Composer instalados, instale:
- **Laravel Herd** (recomendado): https://herd.laravel.com/
- Ou instale manualmente: PHP 8.2+, Node.js, Composer

### 2. Executar setup
```powershell
# No diretório raiz do projeto
.\setup-local-dev.ps1
```

Este script vai:
- ✅ Verificar dependências
- ✅ Instalar Composer (PHP)
- ✅ Instalar npm (Node.js)
- ✅ Criar arquivo `.env`
- ✅ Gerar chave da aplicação

### 3. Configurar conexão com VPS
Edite o arquivo `app/.env`:
```powershell
notepad app\.env
```

Altere estas linhas com os dados da sua VPS:
```env
DB_HOST=seu-dominio-ou-ip-da-vps.com
DB_PASSWORD=sua-senha-do-banco

REDIS_HOST=seu-dominio-ou-ip-da-vps.com
REDIS_PASSWORD=sua-senha-redis

PZ_RCON_HOST=seu-dominio-ou-ip-da-vps.com
PZ_RCON_PASSWORD=sua-senha-rcon
```

### 4. Iniciar desenvolvimento
```powershell
# No diretório raiz
.\start-dev.ps1
```

Ou manualmente em 2 terminais:

**Terminal 1 - Laravel (API):**
```powershell
cd app
php artisan serve
```
Acesso: http://localhost:8000

**Terminal 2 - Vite (React):**
```powershell
cd app
npm run dev
```
Acesso: http://localhost:5173

## 📝 Workflow de Desenvolvimento

### Editar código
1. Abra os arquivos em seu editor favorito (VS Code, etc)
2. Edite arquivos `.tsx`, `.ts`, `.php`
3. Vite faz hot reload automático
4. Laravel recarrega mudanças

### Testar localmente
- Acesse http://localhost:8000
- Os dados vêm do banco de dados remoto da VPS
- Todas as funcionalidades funcionam normalmente

### Fazer commit e push
```powershell
git add .
git commit -m "Descrição da mudança em português"
git push origin main
```

### Deploy na VPS
No seu servidor EasyPanel:
```bash
cd /path/to/project
git pull origin main
docker compose -f docker-compose.easypanel.yml up -d --build
```

## 🔌 Conectividade com VPS

### Verificar conexão com banco de dados
```powershell
cd app
php artisan tinker
```

Depois execute:
```php
DB::connection()->getPdo();
```

Se retornar sem erro, está conectado!

### Se não conseguir conectar

**Problema 1: Porta PostgreSQL não está acessível**
- No servidor, verifique se PostgreSQL está escutando:
  ```bash
  sudo netstat -tlnp | grep 5432
  ```
- Abra a porta no firewall:
  ```bash
  sudo ufw allow 5432/tcp from SEU_IP_LOCAL
  ```

**Problema 2: Credenciais incorretas**
- Verifique as senhas no `.env` da VPS
- Certifique-se de que estão corretas no seu `.env` local

**Problema 3: IP/Domínio incorreto**
- Verifique se o IP ou domínio está correto
- Teste com `ping seu-dominio-ou-ip-da-vps.com`

## 📁 Estrutura do Projeto

```
app/
├── app/                    # Código PHP (Controllers, Models, etc)
├── resources/
│   ├── js/                # Código React/TypeScript
│   │   ├── pages/         # Páginas (welcome.tsx, etc)
│   │   ├── components/    # Componentes React
│   │   └── hooks/         # Custom hooks
│   └── views/             # Templates Blade
├── routes/                # Rotas da API
├── database/              # Migrations
├── public/                # Assets públicos
├── .env                   # Configurações (NÃO commitar!)
├── .env.example           # Template padrão
└── .env.local.example     # Template para desenvolvimento local
```

## 🛠️ Comandos Úteis

### Laravel
```powershell
# Executar migrations
php artisan migrate

# Criar migration
php artisan make:migration create_table_name

# Tinker (console interativo)
php artisan tinker

# Limpar cache
php artisan cache:clear
php artisan config:clear
```

### npm/Vite
```powershell
# Build para produção
npm run build

# Lint/format código
npm run lint

# Visualizar build
npm run preview
```

### Git
```powershell
# Ver status
git status

# Ver mudanças
git diff

# Ver histórico
git log --oneline -10

# Desfazer mudanças
git restore arquivo.tsx
```

## 🔒 Segurança

⚠️ **IMPORTANTE:**
- **NUNCA** commite o arquivo `.env` com senhas reais
- O arquivo `.env` está no `.gitignore` (não será commitado)
- Use `.env.example` como template
- Mantenha senhas seguras e diferentes entre ambientes

## 📚 Documentação Completa

Para mais detalhes, leia: `SETUP_LOCAL_DEV.md`

## ❓ Troubleshooting

### "php: command not found"
- Instale PHP (Laravel Herd ou manualmente)
- Reinicie o PowerShell

### "npm: command not found"
- Instale Node.js
- Reinicie o PowerShell

### "SQLSTATE[08006] could not connect to server"
- Verifique IP/domínio da VPS
- Verifique se porta está aberta
- Verifique credenciais do banco

### Vite não carrega
- Certifique-se de que `npm run dev` está rodando
- Verifique se porta 5173 não está em uso

### Mudanças não aparecem
- Verifique se Vite está rodando
- Verifique se Laravel está rodando
- Limpe cache do navegador (Ctrl+Shift+Delete)

## 🎯 Próximos Passos

1. ✅ Instale dependências
2. ✅ Configure `.env` com dados da VPS
3. ✅ Inicie os servidores
4. ✅ Comece a editar código
5. ✅ Faça commit e push
6. ✅ Deploy na VPS

## 📞 Suporte

Se tiver dúvidas:
- Consulte a documentação oficial: https://laravel.com/docs
- Vite: https://vitejs.dev/
- React: https://react.dev/
- PostgreSQL: https://www.postgresql.org/docs/

---

**Última atualização:** 26 de março de 2026
**Versão:** 1.0
