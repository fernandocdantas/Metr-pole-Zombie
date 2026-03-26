# Configurar Conexão com VPS

O arquivo `.env` foi criado com sucesso! Agora você precisa configurar as credenciais da sua VPS.

## 📝 Editar o arquivo .env

Abra o arquivo `app/.env` com um editor de texto e altere as seguintes linhas com os dados da sua VPS:

```powershell
notepad app\.env
```

## 🔧 Dados a Configurar

Procure pelas linhas abaixo e substitua pelos dados reais da sua VPS:

### 1. Banco de Dados PostgreSQL
```env
DB_HOST=seu-dominio-ou-ip-da-vps.com
DB_PORT=5432
DB_DATABASE=zomboid
DB_USERNAME=zomboid
DB_PASSWORD=sua-senha-do-banco
```

### 2. Redis
```env
REDIS_HOST=seu-dominio-ou-ip-da-vps.com
REDIS_PORT=6379
REDIS_PASSWORD=sua-senha-redis
```

### 3. Game Server RCON
```env
PZ_RCON_HOST=seu-dominio-ou-ip-da-vps.com
PZ_RCON_PORT=27015
PZ_RCON_PASSWORD=sua-senha-rcon
```

### 4. Admin (Opcional)
```env
ADMIN_EMAIL=seu-email@example.com
ADMIN_PASSWORD=sua-senha-admin
```

## 📋 Onde Encontrar Essas Informações

### No seu servidor EasyPanel:
1. Vá para a aplicação no painel
2. Clique em "Environment" ou "Variáveis de Ambiente"
3. Procure pelas variáveis:
   - `DB_HOST`, `DB_PASSWORD`
   - `REDIS_HOST`, `REDIS_PASSWORD`
   - `PZ_RCON_HOST`, `PZ_RCON_PASSWORD`

### Ou via SSH:
```bash
# Ver variáveis de ambiente
cat /path/to/.env

# Ou verificar as configurações do Docker
docker compose config | grep -E "DB_|REDIS_|PZ_RCON"
```

## ✅ Após Configurar

Depois de editar o `.env`, você pode:

1. **Testar a conexão com o banco de dados:**
   ```powershell
   cd app
   php artisan tinker
   ```
   
   Depois execute:
   ```php
   DB::connection()->getPdo();
   ```
   
   Se não houver erro, está conectado!

2. **Iniciar o servidor de desenvolvimento:**
   ```powershell
   # Terminal 1
   php artisan serve
   
   # Terminal 2
   npm run dev
   ```

3. **Acessar a aplicação:**
   - http://localhost:8000

## ⚠️ Importante

- **NÃO** faça commit do arquivo `.env` (está no `.gitignore`)
- Mantenha as senhas seguras
- Use IP ou domínio da sua VPS (não localhost)
- Certifique-se de que as portas estão abertas no firewall da VPS

## 🆘 Troubleshooting

Se não conseguir conectar:

1. **Verifique se as portas estão abertas:**
   ```bash
   # No servidor
   sudo ufw allow 5432/tcp from SEU_IP_LOCAL
   sudo ufw allow 6379/tcp from SEU_IP_LOCAL
   ```

2. **Verifique as credenciais:**
   ```bash
   # Teste PostgreSQL
   psql -h seu-dominio-ou-ip -U zomboid -d zomboid -c "SELECT 1"
   ```

3. **Verifique se os serviços estão rodando:**
   ```bash
   docker ps
   ```

---

**Próximo passo:** Edite o arquivo `app/.env` com os dados da sua VPS e depois execute:
```powershell
.\start-dev.ps1
```
