# Cloudflare Tunnel 상시 실행 설정 가이드

## 개요

Cloudflare Tunnel을 systemd 서비스로 등록하여 서버 재부팅 시에도 자동으로 시작되도록 설정합니다.

## 설치 방법

### 1. cloudflared 설치 (아직 설치 안 된 경우)

```bash
# 서버에서 실행
# 최신 버전 다운로드
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

# 설치
sudo dpkg -i cloudflared-linux-amd64.deb

# 설치 확인
cloudflared --version

# 다운로드 파일 삭제
rm cloudflared-linux-amd64.deb
```

### 2. cloudflared 경로 확인

```bash
# cloudflared 위치 확인
which cloudflared

# 보통 다음 중 하나입니다:
# /usr/local/bin/cloudflared
# /usr/bin/cloudflared
```

만약 경로가 다르다면 `cloudflared-tunnel.service` 파일의 `ExecStart` 경로를 수정해야 합니다.

### 3. Systemd 서비스 등록

```bash
# 서버에서 실행
cd ~/Programs/production-management-system

# 서비스 파일 복사
sudo cp cloudflared-tunnel.service /etc/systemd/system/

# systemd 리로드
sudo systemctl daemon-reload

# 서비스 활성화 (부팅 시 자동 시작)
sudo systemctl enable cloudflared-tunnel.service

# 서비스 시작
sudo systemctl start cloudflared-tunnel.service
```

### 4. 서비스 상태 확인

```bash
# 서비스 상태 확인
sudo systemctl status cloudflared-tunnel.service

# 로그 확인 (실시간)
sudo journalctl -u cloudflared-tunnel.service -f

# 로그 확인 (최근 50줄)
sudo journalctl -u cloudflared-tunnel.service -n 50
```

## Docker Compose의 cloudflared 제거 (중복 방지)

docker-compose.yml에 이미 cloudflared 컨테이너가 있다면 제거하는 것이 좋습니다:

```bash
# docker-compose.yml 수정
nano ~/Programs/production-management-system/docker-compose.yml

# cloudflared 섹션 전체 삭제:
# cloudflared:
#   image: cloudflare/cloudflared:latest
#   command: tunnel --no-autoupdate run --token ...
#   restart: unless-stopped
#   network_mode: host

# 수정 후 Docker Compose 재시작
cd ~/Programs/production-management-system
docker-compose down
docker-compose up -d
```

## 터널 토큰 변경이 필요한 경우

### 방법 1: 서비스 파일 수정

```bash
# 서비스 파일 직접 수정
sudo nano /etc/systemd/system/cloudflared-tunnel.service

# ExecStart 라인의 토큰 부분을 새 토큰으로 변경
# 저장 후:
sudo systemctl daemon-reload
sudo systemctl restart cloudflared-tunnel.service
```

### 방법 2: 프로젝트 파일 수정 후 재배포

```bash
# 로컬에서
nano cloudflared-tunnel.service
# 토큰 변경 후 커밋, 푸시

# 서버에서
git pull origin main
sudo cp cloudflared-tunnel.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart cloudflared-tunnel.service
```

## 유용한 명령어

### 서비스 관리

```bash
# 서비스 시작
sudo systemctl start cloudflared-tunnel.service

# 서비스 중지
sudo systemctl stop cloudflared-tunnel.service

# 서비스 재시작
sudo systemctl restart cloudflared-tunnel.service

# 서비스 상태 확인
sudo systemctl status cloudflared-tunnel.service

# 부팅 시 자동 시작 활성화
sudo systemctl enable cloudflared-tunnel.service

# 부팅 시 자동 시작 비활성화
sudo systemctl disable cloudflared-tunnel.service
```

### 로그 확인

```bash
# 실시간 로그 (Ctrl+C로 종료)
sudo journalctl -u cloudflared-tunnel.service -f

# 최근 100줄
sudo journalctl -u cloudflared-tunnel.service -n 100

# 오늘 로그만
sudo journalctl -u cloudflared-tunnel.service --since today

# 특정 시간 이후 로그
sudo journalctl -u cloudflared-tunnel.service --since "2025-01-01 00:00:00"
```

## 문제 해결

### 서비스가 시작되지 않을 때

```bash
# 1. cloudflared 설치 확인
which cloudflared

# 2. 경로 확인 및 수정
# /usr/bin/cloudflared 또는 /usr/local/bin/cloudflared
sudo nano /etc/systemd/system/cloudflared-tunnel.service
# ExecStart 경로 수정

# 3. 토큰 유효성 확인
# Cloudflare Zero Trust 대시보드에서 터널 상태 확인

# 4. 수동 실행으로 테스트
cloudflared tunnel --no-autoupdate run --token <YOUR_TOKEN>
# Ctrl+C로 종료

# 5. 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl restart cloudflared-tunnel.service
```

### 터널이 연결되지 않을 때

```bash
# 로그에서 에러 확인
sudo journalctl -u cloudflared-tunnel.service -n 100

# 일반적인 에러:
# - "Invalid token": 토큰이 잘못됨 → 새 토큰으로 교체
# - "Cannot connect": 네트워크 문제 → 방화벽, DNS 확인
# - "Tunnel already connected": 다른 곳에서 이미 실행 중 → 중복 실행 확인
```

### Docker Compose와 충돌

```bash
# Docker Compose의 cloudflared 컨테이너 확인
docker ps | grep cloudflared

# 컨테이너가 있다면 중지
docker stop <container_name>

# docker-compose.yml에서 cloudflared 섹션 삭제
nano ~/Programs/production-management-system/docker-compose.yml

# Docker Compose 재시작
cd ~/Programs/production-management-system
docker-compose down
docker-compose up -d
```

## Cloudflare Zero Trust 대시보드에서 확인

1. https://one.dash.cloudflare.com/ 접속
2. **Access** > **Tunnels** 메뉴
3. 터널 상태가 **Healthy** (녹색)인지 확인
4. **Public Hostnames** 탭에서 설정 확인:
   - `pms.suria.uk` → `http://localhost:3000`
   - `webhook.suria.uk` → `http://localhost:9000`

## 서버 재부팅 후 확인

```bash
# 서버 재부팅
sudo reboot

# 재접속 후 서비스 상태 확인
sudo systemctl status cloudflared-tunnel.service

# Active: active (running) 상태여야 함
```

## 참고

- Cloudflare Tunnel 공식 문서: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- 서비스 로그: `sudo journalctl -u cloudflared-tunnel.service`
- 서비스 상태: `sudo systemctl status cloudflared-tunnel.service`
