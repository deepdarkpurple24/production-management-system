# Security

## 구현된 보안 기능

### Authentication
- **Devise**: 이메일/비밀번호 인증
- **Device Fingerprinting**: 브라우저 기반 디바이스 식별 (SHA-256)
- **Email Confirmation**: 이메일 인증 필수
- **Session Timeout**: 30분 비활성 시 자동 로그아웃

### Authorization
- **Admin Role**: 첫 사용자 자동 admin
- **Device Authorization**: 관리자가 디바이스 승인/해제

### Rate Limiting (Rack::Attack)
- 로그인: 5회/20초 (IP + 이메일)
- 회원가입: 3회/시간
- 비밀번호 재설정: 3회/시간
- 일반 요청: 300회/5분

### Monitoring
- **LoginHistory**: 모든 로그인 시도 기록
- **Trackable**: 로그인 횟수, 시간, IP 추적

### Protection
- **CSRF**: csrf_meta_tags
- **CSP**: csp_meta_tag
- **Brakeman**: 정적 보안 분석
- **Bundler Audit**: 의존성 보안 검사

## 알려진 제한사항
- Device Fingerprinting은 우회 가능 (완벽하지 않음)
- 2FA 미구현
- Admin 액션 감사 로그 없음

## 보안 검사 명령어
```bash
bin/brakeman           # Rails 취약점 스캔
bin/bundler-audit      # 의존성 취약점 확인
```
