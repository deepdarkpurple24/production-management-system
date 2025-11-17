# 인터랙션 & 반응형 디자인 가이드

이 문서는 프로젝트에 추가된 반응형 디자인 개선 사항과 인터랙션 컴포넌트의 사용법을 설명합니다.

## 📱 반응형 디자인 개선

### 주요 개선 사항

1. **반응형 타이포그래피**
   - 모바일 (< 576px): 작은 폰트 크기로 가독성 향상
   - 태블릿 (577px - 768px): 중간 크기
   - 데스크톱 (> 768px): 원본 크기

2. **모바일 네비게이션**
   - 991px 이하에서 햄버거 메뉴 자동 활성화
   - 드롭다운 메뉴 모바일 최적화
   - 터치 친화적인 탭 타겟 (최소 44x44px)

3. **카드 레이아웃**
   - 모바일: 1열 그리드
   - 태블릿: 2열 그리드
   - 데스크톱: 4열 그리드

## 🎨 인터랙션 컴포넌트

### 1. 토스트 알림 (Toast Notifications)

간단하고 우아한 알림 메시지를 표시합니다.

#### 기본 사용법

```javascript
// 성공 메시지
toast.success('저장되었습니다!');

// 오류 메시지
toast.error('오류가 발생했습니다.');

// 경고 메시지
toast.warning('주의가 필요합니다.');

// 정보 메시지
toast.info('새로운 업데이트가 있습니다.');
```

#### 커스텀 제목 사용

```javascript
toast.success('성공적으로 저장되었습니다!', '완료');
toast.error('서버에 연결할 수 없습니다.', '연결 오류');
```

#### 고급 사용법

```javascript
// 표시 시간 변경 (기본: 4000ms)
toast.show('메시지', 'success', '제목', 6000);
```

### 2. 로딩 오버레이 (Loading Overlay)

전체 화면 로딩 상태를 표시합니다.

```javascript
// 로딩 표시
loading.show();

// 작업 수행
await someAsyncOperation();

// 로딩 숨기기
loading.hide();
```

### 3. 버튼 로딩 상태

개별 버튼의 로딩 상태를 관리합니다.

```erb
<!-- HTML -->
<button class="btn-apple btn-apple-primary" id="saveBtn">
  <i class="bi bi-save me-2"></i>저장
</button>
```

```javascript
const button = document.getElementById('saveBtn');

// 로딩 상태 활성화
setButtonLoading(button, true);

// 비동기 작업 수행
await saveData();

// 로딩 상태 해제
setButtonLoading(button, false);
```

### 4. 폼 유효성 검사

자동 실시간 폼 검증을 제공합니다.

```erb
<!-- required 속성만 추가하면 자동으로 검증됩니다 -->
<form id="myForm">
  <div class="mb-3">
    <label for="name" class="form-label">이름</label>
    <input type="text" class="form-control" id="name" required>
    <div class="invalid-feedback"></div>
  </div>

  <div class="mb-3">
    <label for="email" class="form-label">이메일</label>
    <input type="email" class="form-control" id="email" required>
    <div class="invalid-feedback"></div>
  </div>

  <button type="submit" class="btn-apple btn-apple-primary">제출</button>
</form>
```

```javascript
// 폼 제출 시 검증
document.getElementById('myForm').addEventListener('submit', (e) => {
  e.preventDefault();

  if (validateForm(e.target)) {
    // 폼이 유효한 경우
    toast.success('폼이 제출되었습니다!');
  } else {
    // 폼이 유효하지 않은 경우
    toast.error('모든 필수 항목을 입력해주세요.');
  }
});
```

### 5. 확인 대화상자

```javascript
const confirmed = await confirmDialog('정말 삭제하시겠습니까?', '삭제 확인');

if (confirmed) {
  // 삭제 작업 수행
  await deleteItem();
  toast.success('삭제되었습니다!');
}
```

### 6. 디바운스 (Debounce)

검색이나 필터링 시 성능 최적화를 위해 사용합니다.

```javascript
const searchInput = document.getElementById('searchInput');

searchInput.addEventListener('input', debounce((e) => {
  const query = e.target.value;
  performSearch(query);
}, 300));
```

### 7. 스켈레톤 로더

콘텐츠 로딩 중 표시할 플레이스홀더입니다.

```erb
<!-- 로딩 중일 때 -->
<div class="card-apple">
  <div class="card-body">
    <div class="skeleton skeleton-circle mx-auto mb-3"></div>
    <div class="skeleton skeleton-title"></div>
    <div class="skeleton skeleton-text"></div>
    <div class="skeleton skeleton-text"></div>
  </div>
</div>

<!-- 데이터 로드 후 실제 콘텐츠로 교체 -->
```

## 🎯 실제 사용 예제

### 예제 1: 데이터 저장 플로우

```javascript
async function saveProduct(data) {
  const saveBtn = document.getElementById('saveBtn');

  // 버튼 로딩 시작
  setButtonLoading(saveBtn, true);

  try {
    // API 호출
    const response = await fetch('/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });

    if (response.ok) {
      toast.success('제품이 저장되었습니다!', '성공');
    } else {
      throw new Error('저장 실패');
    }
  } catch (error) {
    toast.error('저장 중 오류가 발생했습니다.', '오류');
  } finally {
    // 버튼 로딩 해제
    setButtonLoading(saveBtn, false);
  }
}
```

### 예제 2: 데이터 로드 플로우

```javascript
async function loadDashboard() {
  // 로딩 오버레이 표시
  loading.show();

  try {
    const data = await fetchDashboardData();
    renderDashboard(data);
    toast.info('대시보드가 업데이트되었습니다.');
  } catch (error) {
    toast.error('데이터를 불러올 수 없습니다.', '로드 실패');
  } finally {
    loading.hide();
  }
}
```

### 예제 3: 삭제 확인 플로우

```javascript
async function deleteItem(itemId) {
  // 확인 대화상자
  const confirmed = await confirmDialog(
    '이 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
    '삭제 확인'
  );

  if (!confirmed) return;

  loading.show();

  try {
    await fetch(`/api/items/${itemId}`, { method: 'DELETE' });
    toast.success('항목이 삭제되었습니다!');
    // 목록 새로고침
    reloadList();
  } catch (error) {
    toast.error('삭제 중 오류가 발생했습니다.');
  } finally {
    loading.hide();
  }
}
```

## 🎨 CSS 클래스 참조

### 스켈레톤 로더
- `.skeleton` - 기본 스켈레톤
- `.skeleton-text` - 텍스트 라인
- `.skeleton-title` - 제목
- `.skeleton-card` - 카드 형태
- `.skeleton-circle` - 원형 (아바타 등)

### 애니메이션
- `.pulse` - 맥박 애니메이션
- `.page-transition` - 페이지 전환 애니메이션

### 버튼 상태
- `.btn-loading` - 로딩 상태 (자동으로 스피너 표시)
- `:disabled` - 비활성 상태

### 폼 검증
- `.is-valid` - 유효한 입력
- `.is-invalid` - 유효하지 않은 입력
- `.valid-feedback` - 성공 피드백 메시지
- `.invalid-feedback` - 오류 피드백 메시지

## 📱 반응형 브레이크포인트

- **모바일**: < 576px
- **태블릿**: 577px - 768px
- **데스크톱 (소)**: 769px - 991px
- **데스크톱 (중)**: 992px - 1199px
- **데스크톱 (대)**: ≥ 1200px

## ♿ 접근성 개선

- 모든 인터랙티브 요소에 적절한 focus 상태 제공
- 키보드 네비게이션 지원
- ARIA 라벨 자동 추가
- 색상 대비 준수
- 터치 타겟 크기 최소 44x44px

## 🔧 커스터마이징

스타일을 커스터마이즈하려면 `app/assets/stylesheets/application.bootstrap.scss`에서 변수를 수정하세요:

```scss
// 색상 커스터마이징
$apple-blue: #0071e3;
$apple-green: #30d158;
$apple-red: #ff3b30;

// 애니메이션 속도 조정
@keyframes spin {
  to { transform: rotate(360deg); }
}
```

## 📚 추가 리소스

- Bootstrap Icons: https://icons.getbootstrap.com/
- CSS Animations: https://animate.style/
- 웹 접근성 가이드: https://www.w3.org/WAI/
