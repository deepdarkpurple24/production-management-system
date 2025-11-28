# Architecture Overview

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.1 / Ruby 3.4.7
- **Database**: PostgreSQL 17 (production), SQLite3 (development)
- **Authentication**: Devise + Device Fingerprinting
- **Background**: Solid Queue, Solid Cache, Solid Cable

### Frontend
- **JavaScript**: ES6+ with Import Maps, Hotwire (Turbo + Stimulus)
- **CSS**: Bootstrap 5.3.8 + SASS (Apple-style design)
- **Libraries**: Flatpickr, QuaggaJS (barcode), SortableJS

## Directory Structure
```
app/
├── controllers/
│   ├── inventory/      # 재고 관리 (items, receipts, shipments)
│   ├── production/     # 생산 관리 (plans, logs)
│   ├── admin/          # 관리자 (users, devices, login_histories)
│   └── users/          # Devise 커스텀 컨트롤러
├── models/             # ActiveRecord 모델
├── services/           # 비즈니스 로직
│   ├── ingredient_inventory_service.rb  # FIFO 재고 관리
│   └── production_log_initializer.rb    # 생산일지 자동 생성
├── javascript/
│   ├── controllers/    # Stimulus 컨트롤러
│   ├── application.js  # 진입점
│   ├── interactions.js # 전역 유틸리티 (toast, loading)
│   ├── device_fingerprint.js  # 디바이스 인증
│   └── barcode_scanner.js     # 바코드 스캐너
└── views/
    ├── layouts/        # 메인 레이아웃
    ├── inventory/      # 재고 관리 뷰
    ├── production/     # 생산 관리 뷰
    └── admin/          # 관리자 뷰
```

## Key Routes
```
/                       # 홈 대시보드
/inventory/*            # 재고 관리 (items, receipts, shipments, stocks)
/production/*           # 생산 관리 (plans, logs)
/recipes                # 레시피 관리
/finished_products      # 완제품 관리
/ingredients            # 재료 관리
/equipments             # 장비 관리
/settings               # 설정
/admin/*                # 관리자 (users, login_histories)
/users/sign_in          # 로그인
```

## Frontend Utilities
```javascript
// Toast 알림
window.toast.success('메시지');
window.toast.error('메시지');
window.toast.warning('메시지');
window.toast.info('메시지');

// 로딩 오버레이
window.loading.show();
window.loading.hide();

// 바코드 스캐너
window.openBarcodeScanner('input_id', callback);
```
