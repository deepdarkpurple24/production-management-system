# Deployment Environment (배포 환경)

## Production Server
- **Server**: Ubuntu (별도 컴퓨터, 현재 개발 PC와 다름)
- **Container**: Docker (docker-compose)
- **Reverse Proxy / CDN**: Cloudflare Tunnel
- **Database**: PostgreSQL 17 (Docker container)
- **Backup**: Supabase (일일 자동 백업, 3 AM KST)

## Development Environment (현재 PC - Windows)
- 이 폴더는 개발용
- 코드 수정 후 `git push` → 서버에서 `pull`하여 배포
- 서버 배포 명령어는 서버에서 직접 실행
- CSS 빌드는 로컬에서 `yarn build:css` 후 커밋

## 서버 배포 절차 (Ubuntu 서버에서 실행)
```bash
cd ~/production-management-system
git pull
docker-compose down
docker-compose up -d --build
```

## Backup Commands (서버에서 실행)
```bash
# Manual backup
./scripts/backup_to_supabase_simple.sh

# Restore from Supabase (disaster recovery)
./scripts/restore_from_supabase.sh

# Check cron status
crontab -l

# View backup logs
tail -f ~/logs/pg_backup_cron.log
```

## Environment Variables (서버)
- `SUPABASE_PASSWORD` - Supabase 백업용
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` - Docker PostgreSQL
