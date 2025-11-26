# GitHub Webhook 자동 배포 설정 가이드

## 개요

Git push 시 자동으로 우분투 서버에 배포되는 시스템입니다.

## 배포 전략 (자동 감지)

| 변경 사항 | 배포 전략 |
|----------|----------|
| `Dockerfile`, `docker-compose.yml` 변경 | **No-cache 빌드** |
| `Gemfile`, `package.json` 변경 | **리빌드** |
| `db/migrate/` 새 파일 추가 | **마이그레이션 실행** |
| `db/schema.rb` 변경 | **마이그레이션 실행** |
| `.scss`, `.sass` 파일만 변경 | **리빌드 (CSS 컴파일)** |
| 기타 코드 변경 | **빠른 재시작** |

## 서버 설정

### 1. webhook 설치

```bash
# 서버에서 실행
sudo apt update
sudo apt install -y webhook
```

### 2. 파일 권한 설정

```bash
# 서버에서 실행
cd ~/Programs/production-management-system

# deploy.sh 실행 권한 부여
chmod +x deploy.sh

# hooks.json 보안 설정 (읽기 전용)
chmod 600 hooks.json
```

### 3. Webhook Secret 생성 및 설정

```bash
# 랜덤 secret 생성
openssl rand -hex 32

# 출력된 값을 복사한 후 hooks.json 파일 수정
nano hooks.json
# "YOUR_WEBHOOK_SECRET_HERE"를 생성한 secret으로 변경
```

### 4. Systemd 서비스 등록

```bash
# 서비스 파일 복사
sudo cp webhook.service /etc/systemd/system/

# 서비스 시작 및 활성화
sudo systemctl daemon-reload
sudo systemctl enable webhook.service
sudo systemctl start webhook.service

# 서비스 상태 확인
sudo systemctl status webhook.service
```

### 5. 방화벽 설정 (필요시)

```bash
# 포트 9000 열기
sudo ufw allow 9000/tcp

# 또는 로컬호스트만 허용 (Cloudflare Tunnel 사용 시)
# 추가 설정 불필요 - 내부 통신만 사용
```

### 6. Cloudflare Tunnel을 통한 외부 접근 설정

Cloudflare Tunnel을 이미 사용 중이므로, webhook 엔드포인트를 추가합니다:

```bash
# Cloudflare Zero Trust 대시보드에서 설정
# Tunnel > Configure > Public Hostname 추가
# - Subdomain: webhook (또는 원하는 이름)
# - Domain: suria.uk
# - Service: http://localhost:9000
```

또는 기존 도메인에 경로 기반 라우팅:
```
# pms.suria.uk/webhook → localhost:9000
```

## GitHub 설정

### 1. GitHub Repository Settings

1. GitHub 저장소 페이지 접속
2. **Settings** > **Webhooks** > **Add webhook**

### 2. Webhook 설정

- **Payload URL**: `https://webhook.suria.uk/hooks/deploy-production-management-system`
  - (또는 `https://pms.suria.uk/webhook/hooks/deploy-production-management-system`)
- **Content type**: `application/json`
- **Secret**: hooks.json에 설정한 secret 입력
- **Which events would you like to trigger this webhook?**:
  - **Just the push event** 선택
- **Active**: ✅ 체크
- **Add webhook** 클릭

## 테스트

### 1. 로컬에서 코드 수정 후 push

```bash
# 로컬에서
echo "# Test webhook" >> README.md
git add README.md
git commit -m "Test webhook deployment"
git push origin main
```

### 2. 서버 로그 확인

```bash
# 서버에서 webhook 로그 확인
sudo journalctl -u webhook.service -f

# 배포 로그 확인
ls -lt /tmp/deploy-*.log | head -1  # 최신 로그 파일 찾기
tail -f /tmp/deploy-YYYYMMDD-HHMMSS.log  # 로그 내용 확인
```

### 3. GitHub에서 Delivery 확인

1. GitHub Repository > Settings > Webhooks
2. 방금 생성한 webhook 클릭
3. **Recent Deliveries** 탭에서 요청/응답 확인

## 수동 배포

자동 배포가 실패하거나 수동으로 배포하고 싶을 때:

```bash
# 서버에서 직접 실행
cd ~/Programs/production-management-system
./deploy.sh
```

## 문제 해결

### Webhook이 실행되지 않을 때

```bash
# 서비스 상태 확인
sudo systemctl status webhook.service

# 로그 확인
sudo journalctl -u webhook.service -n 50

# 서비스 재시작
sudo systemctl restart webhook.service
```

### 배포 스크립트 오류

```bash
# 최신 로그 파일 확인
tail -100 /tmp/deploy-*.log | tail -100

# 수동 실행으로 디버깅
cd ~/Programs/production-management-system
bash -x ./deploy.sh  # 디버그 모드로 실행
```

### Docker 권한 문제

```bash
# alche0124 사용자를 docker 그룹에 추가
sudo usermod -aG docker alche0124

# 로그아웃 후 재로그인 (또는 서버 재시작)
```

## 보안 고려사항

1. **Secret 보호**: `hooks.json` 파일을 Git에 커밋하지 마세요
2. **HTTPS 사용**: Cloudflare Tunnel로 이미 HTTPS 적용됨
3. **IP 화이트리스트**: 필요시 GitHub IP 범위만 허용
4. **로그 관리**: `/tmp/deploy-*.log` 파일 정기적으로 정리

## 로그 자동 정리

```bash
# 30일 이상된 로그 파일 삭제 (cron 추가)
crontab -e

# 다음 라인 추가 (매일 새벽 3시 실행)
0 3 * * * find /tmp/deploy-*.log -mtime +30 -delete
```

## 참고

- Webhook 엔드포인트: `http://localhost:9000/hooks/deploy-production-management-system`
- 외부 URL: `https://webhook.suria.uk/hooks/deploy-production-management-system`
- 배포 로그: `/tmp/deploy-YYYYMMDD-HHMMSS.log`
- Webhook 로그: `sudo journalctl -u webhook.service`
