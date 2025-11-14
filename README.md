# 생산관리 통합 시스템 (Production Management System)

생산, 재고, 레시피, 기기를 통합 관리하는 웹 기반 ERP 시스템입니다.

## 프로젝트 개요

제조업 생산 현장의 전반적인 운영을 효율적으로 관리하기 위한 통합 시스템입니다.
각 모듈이 유기적으로 연동되어 데이터를 공유하며, 생산 계획부터 재고 관리, 레시피 관리, 기기 유지보수까지 전체 프로세스를 지원합니다.

## 주요 모듈

### 1. 생산관리
- **생산계획**: 생산 일정 및 계획 수립
- **반죽일지**: 생산 실적 기록 및 관리

### 2. 재고관리
- **입고**: 원자재 및 부자재 입고 처리
- **개봉품관리**: 개봉된 품목의 유통기한 및 사용 현황 관리
- **출고**: 제품 및 원자재 출고 처리
- **재고현황**: 실시간 재고 조회 및 모니터링
- **품목관리**: 품목 마스터 데이터 관리

### 3. 레시피관리
- **레시피관리**: 제품별 원자재 배합비 및 공정 관리
- **완제품관리**: 레시피를 조합하여 생성되는 완제품 정보 관리

### 4. 기기관리
- **장비목록**: 생산 장비 및 부품 정보 관리
  - 부품 모델명, 가격, 수급처 정보
- **유지보수기록**: 장비 점검 및 수리 이력 관리

## 기술 스택

- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **Database**: SQLite3 (개발), PostgreSQL (프로덕션 권장)
- **Frontend**:
  - Hotwire (Turbo + Stimulus)
  - Bootstrap 5.3
  - ImportMap
- **배포**: Docker, Kamal

## 설치 및 실행

### 필수 요구사항
- Ruby 3.4.7 이상
- Rails 8.1.1 이상
- Node.js (CSS 빌드용)
- Yarn

### 설치 방법

```bash
# 저장소 클론
git clone <repository-url>
cd production-management-system

# 의존성 설치
bundle install
yarn install

# 데이터베이스 생성 및 마이그레이션
rails db:create
rails db:migrate
rails db:seed

# 개발 서버 실행
bin/dev
```

### 서버 접속
개발 서버 실행 후 브라우저에서 `http://localhost:3000` 접속

## 개발 진행 상황

- [x] Rails 프로젝트 초기 설정
- [x] Git 저장소 초기화
- [ ] 데이터베이스 스키마 설계
- [ ] 생산관리 모듈 구현
- [ ] 재고관리 모듈 구현
- [ ] 레시피관리 모듈 구현
- [ ] 기기관리 모듈 구현
- [ ] 모듈 간 데이터 연동
- [ ] 사용자 인증 및 권한 관리
- [ ] 대시보드 구현

## 프로젝트 구조

```
production-management-system/
├── app/
│   ├── controllers/      # 컨트롤러
│   ├── models/           # 모델 (데이터베이스)
│   ├── views/            # 뷰 템플릿
│   ├── javascript/       # JavaScript (Stimulus)
│   └── assets/           # CSS, 이미지
├── config/               # 설정 파일
├── db/                   # 데이터베이스 마이그레이션
├── test/                 # 테스트 코드
└── public/               # 정적 파일
```

## 라이선스

MIT License
