// Barcode Scanner Module
// 모달 방식의 바코드 스캐너 (상단 표시, 수동 캡처 버튼)

class BarcodeScanner {
  constructor(options = {}) {
    this.targetInput = options.targetInput;
    this.onSuccess = options.onSuccess || (() => {});
    this.onError = options.onError || (() => {});
    this.modal = null;
    this.videoStream = null;
    this.isScanning = false;
    this.canvas = null;
    this.video = null;
    this.scanAttempts = 0;
    this.maxAttempts = 3;
  }

  // 모달 HTML 생성
  createModal() {
    const modalHtml = `
      <div class="modal fade" id="barcodeScannerModal" tabindex="-1" aria-labelledby="barcodeScannerModalLabel" aria-hidden="true" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width: 95%; width: 400px;">
          <div class="modal-content" style="border-radius: 16px; overflow: hidden;">
            <div class="modal-header py-2" style="background: linear-gradient(135deg, #007aff, #5856d6); border: none;">
              <h6 class="modal-title text-white mb-0" id="barcodeScannerModalLabel">
                <i class="bi bi-upc-scan me-2"></i>바코드 스캔
              </h6>
              <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-0" style="background: #000;">
              <div id="scannerContainer" style="position: relative; width: 100%; height: 280px; overflow: hidden;">
                <video id="scannerVideo" style="width: 100%; height: 100%; object-fit: cover;" playsinline autoplay muted></video>
                <canvas id="scannerCanvas" style="display: none;"></canvas>
                <!-- 스캔 가이드라인 -->
                <div id="scanGuide" style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
                            width: 90%; height: 140px; border: 3px solid rgba(0, 122, 255, 0.9);
                            border-radius: 8px; box-shadow: 0 0 0 9999px rgba(0,0,0,0.4);">
                  <div style="position: absolute; top: -28px; left: 50%; transform: translateX(-50%);
                              color: white; font-size: 13px; white-space: nowrap; text-shadow: 0 1px 3px rgba(0,0,0,0.9);
                              background: rgba(0,0,0,0.5); padding: 2px 10px; border-radius: 4px;">
                    바코드를 가이드라인 안에 맞춰주세요
                  </div>
                  <!-- 스캔 라인 애니메이션 -->
                  <div id="scanLine" style="position: absolute; top: 0; left: 5%; width: 90%; height: 2px;
                              background: linear-gradient(90deg, transparent, #00ff00, transparent);
                              animation: scanAnimation 2s ease-in-out infinite;"></div>
                </div>
                <!-- 로딩 표시 -->
                <div id="scannerLoading" style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); display: none; z-index: 10;">
                  <div class="spinner-border text-light" role="status" style="width: 3rem; height: 3rem;">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="modal-footer justify-content-center py-3" style="background: #f8f9fa; border: none;">
              <button type="button" id="captureBtn" class="btn btn-primary px-4 py-2" style="border-radius: 25px; font-size: 16px;">
                <i class="bi bi-camera-fill me-2"></i>스캔
              </button>
              <button type="button" class="btn btn-outline-secondary px-4 py-2" data-bs-dismiss="modal" style="border-radius: 25px;">
                취소
              </button>
            </div>
            <div id="scanResultArea" class="px-3 pb-3" style="display: none; background: #f8f9fa;">
              <div class="alert alert-success mb-0 py-2" style="border-radius: 8px;">
                <i class="bi bi-check-circle-fill me-2"></i>
                <span id="scanResultText"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
      <style>
        @keyframes scanAnimation {
          0%, 100% { top: 5px; opacity: 1; }
          50% { top: calc(100% - 7px); opacity: 0.7; }
        }
        #scanGuide.scanning {
          border-color: #00ff00 !important;
          box-shadow: 0 0 0 9999px rgba(0,0,0,0.4), 0 0 20px rgba(0,255,0,0.3) !important;
        }
      </style>
    `;

    // 기존 모달 제거
    const existingModal = document.getElementById('barcodeScannerModal');
    if (existingModal) {
      existingModal.remove();
    }

    // 새 모달 추가
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    this.modal = new bootstrap.Modal(document.getElementById('barcodeScannerModal'));

    // 이벤트 리스너 설정
    this.setupEventListeners();
  }

  setupEventListeners() {
    const modalElement = document.getElementById('barcodeScannerModal');
    const captureBtn = document.getElementById('captureBtn');

    // 캡처 버튼 클릭
    captureBtn.addEventListener('click', () => this.captureAndScan());

    // 모달 닫힐 때 카메라 정리
    modalElement.addEventListener('hidden.bs.modal', () => {
      this.stopCamera();
      this.resetScanResult();
    });

    // 모달 열릴 때 카메라 시작
    modalElement.addEventListener('shown.bs.modal', () => {
      this.startCamera();
    });
  }

  // 스캐너 열기
  open() {
    this.createModal();
    this.modal.show();
  }

  // 카메라 시작
  async startCamera() {
    const video = document.getElementById('scannerVideo');
    const loading = document.getElementById('scannerLoading');

    this.video = video;
    loading.style.display = 'block';

    try {
      // 후면 카메라 우선 사용, 높은 해상도 요청
      const constraints = {
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1920, min: 1280 },
          height: { ideal: 1080, min: 720 },
          focusMode: { ideal: 'continuous' },
          exposureMode: { ideal: 'continuous' }
        }
      };

      this.videoStream = await navigator.mediaDevices.getUserMedia(constraints);
      video.srcObject = this.videoStream;

      video.onloadedmetadata = () => {
        loading.style.display = 'none';
        this.isScanning = true;
        console.log('카메라 해상도:', video.videoWidth, 'x', video.videoHeight);
      };
    } catch (error) {
      console.error('카메라 접근 오류:', error);
      loading.style.display = 'none';
      this.showError('카메라에 접근할 수 없습니다. 카메라 권한을 확인해주세요.');
    }
  }

  // 카메라 중지
  stopCamera() {
    if (this.videoStream) {
      this.videoStream.getTracks().forEach(track => track.stop());
      this.videoStream = null;
    }
    this.isScanning = false;
    this.scanAttempts = 0;
  }

  // 캡처 후 스캔
  async captureAndScan() {
    if (!this.isScanning || !this.video) {
      return;
    }

    const captureBtn = document.getElementById('captureBtn');
    const loading = document.getElementById('scannerLoading');
    const scanGuide = document.getElementById('scanGuide');

    // 버튼 비활성화 및 로딩 표시
    captureBtn.disabled = true;
    captureBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>분석 중...';
    loading.style.display = 'block';
    scanGuide.classList.add('scanning');

    this.scanAttempts = 0;

    try {
      // 캔버스에 현재 프레임 캡처
      const canvas = document.getElementById('scannerCanvas');
      const video = this.video;

      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      const ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

      // 여러 설정으로 스캔 시도
      const result = await this.tryMultipleScans(canvas);

      loading.style.display = 'none';
      scanGuide.classList.remove('scanning');
      captureBtn.disabled = false;
      captureBtn.innerHTML = '<i class="bi bi-camera-fill me-2"></i>스캔';

      if (result) {
        this.handleSuccess(result);
      } else {
        this.showError('바코드를 인식할 수 없습니다. 바코드가 선명하게 보이도록 조정 후 다시 시도해주세요.');
      }
    } catch (error) {
      console.error('스캔 오류:', error);
      loading.style.display = 'none';
      scanGuide.classList.remove('scanning');
      captureBtn.disabled = false;
      captureBtn.innerHTML = '<i class="bi bi-camera-fill me-2"></i>스캔';
      this.showError('스캔 중 오류가 발생했습니다.');
    }
  }

  // 여러 설정으로 스캔 시도
  async tryMultipleScans(canvas) {
    const configurations = [
      // 기본 설정
      { patchSize: 'medium', halfSample: false, size: 1200 },
      // 큰 패치 사이즈
      { patchSize: 'large', halfSample: false, size: 1200 },
      // 작은 패치 사이즈
      { patchSize: 'small', halfSample: false, size: 1000 },
      // halfSample 활성화
      { patchSize: 'medium', halfSample: true, size: 800 },
      // x-large 패치
      { patchSize: 'x-large', halfSample: false, size: 1400 },
    ];

    for (const config of configurations) {
      console.log('스캔 시도:', config);
      const result = await this.scanWithConfig(canvas, config);
      if (result) {
        console.log('스캔 성공:', result);
        return result;
      }
    }

    // 이미지 전처리 후 재시도
    console.log('이미지 전처리 후 재시도...');
    const processedCanvas = this.preprocessImage(canvas);
    for (const config of configurations.slice(0, 3)) {
      const result = await this.scanWithConfig(processedCanvas, config);
      if (result) {
        console.log('전처리 후 스캔 성공:', result);
        return result;
      }
    }

    return null;
  }

  // 특정 설정으로 스캔
  scanWithConfig(canvas, config) {
    return new Promise((resolve) => {
      const imageData = canvas.toDataURL('image/jpeg', 0.95);

      Quagga.decodeSingle({
        src: imageData,
        numOfWorkers: 0,
        inputStream: {
          size: config.size,
          singleChannel: false
        },
        decoder: {
          readers: [
            'ean_reader',
            'ean_8_reader',
            'code_128_reader',
            'code_39_reader',
            'upc_reader',
            'upc_e_reader',
            'i2of5_reader',
            'codabar_reader'
          ],
          multiple: false
        },
        locate: true,
        locator: {
          halfSample: config.halfSample,
          patchSize: config.patchSize
        }
      }, (result) => {
        if (result && result.codeResult && result.codeResult.code) {
          // 신뢰도 검사 (선택적)
          const code = result.codeResult.code;
          // EAN-13 바코드 체크섬 검증
          if (this.validateBarcode(code)) {
            resolve(code);
          } else {
            console.log('바코드 검증 실패:', code);
            resolve(null);
          }
        } else {
          resolve(null);
        }
      });
    });
  }

  // 바코드 유효성 검사
  validateBarcode(code) {
    if (!code || code.length < 1) return false;

    // 숫자로만 구성된 바코드인지 확인
    const isNumericOnly = /^\d+$/.test(code);

    // EAN-13 체크섬 검증 (13자리 숫자 바코드)
    if (isNumericOnly && code.length === 13) {
      let sum = 0;
      for (let i = 0; i < 12; i++) {
        const digit = parseInt(code[i], 10);
        sum += (i % 2 === 0) ? digit : digit * 3;
      }
      const checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit === parseInt(code[12], 10);
    }

    // EAN-8 체크섬 검증 (8자리 숫자 바코드)
    if (isNumericOnly && code.length === 8) {
      let sum = 0;
      for (let i = 0; i < 7; i++) {
        const digit = parseInt(code[i], 10);
        sum += (i % 2 === 0) ? digit * 3 : digit;
      }
      const checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit === parseInt(code[7], 10);
    }

    // UPC-A 체크섬 검증 (12자리 숫자 바코드)
    if (isNumericOnly && code.length === 12) {
      let sum = 0;
      for (let i = 0; i < 11; i++) {
        const digit = parseInt(code[i], 10);
        sum += (i % 2 === 0) ? digit * 3 : digit;
      }
      const checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit === parseInt(code[11], 10);
    }

    // Code 39, Code 128 등 영문+숫자 바코드는 기본적으로 허용
    // 최소 길이만 검사
    if (code.length >= 1) {
      return true;
    }

    return false;
  }

  // 이미지 전처리 (대비 향상)
  preprocessImage(sourceCanvas) {
    const canvas = document.createElement('canvas');
    canvas.width = sourceCanvas.width;
    canvas.height = sourceCanvas.height;

    const ctx = canvas.getContext('2d');
    ctx.drawImage(sourceCanvas, 0, 0);

    // 이미지 데이터 가져오기
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    // 그레이스케일 변환 및 대비 향상
    for (let i = 0; i < data.length; i += 4) {
      // 그레이스케일
      const gray = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];

      // 대비 향상 (1.5배)
      const contrast = 1.5;
      const factor = (259 * (contrast * 100 + 255)) / (255 * (259 - contrast * 100));
      const newGray = Math.min(255, Math.max(0, factor * (gray - 128) + 128));

      // 이진화 (threshold)
      const threshold = 128;
      const binary = newGray > threshold ? 255 : 0;

      data[i] = binary;
      data[i + 1] = binary;
      data[i + 2] = binary;
    }

    ctx.putImageData(imageData, 0, 0);
    return canvas;
  }

  // 성공 처리
  handleSuccess(barcode) {
    const resultArea = document.getElementById('scanResultArea');
    const resultText = document.getElementById('scanResultText');

    resultArea.style.display = 'block';
    resultText.textContent = `바코드: ${barcode}`;

    // 입력 필드에 값 설정
    if (this.targetInput) {
      this.targetInput.value = barcode;
      // change 이벤트 발생 (연관된 처리를 위해)
      this.targetInput.dispatchEvent(new Event('change', { bubbles: true }));
    }

    // 콜백 호출
    this.onSuccess(barcode);

    // 1초 후 모달 닫기
    setTimeout(() => {
      this.modal.hide();
    }, 1000);
  }

  // 오류 표시
  showError(message) {
    const resultArea = document.getElementById('scanResultArea');
    const alertDiv = resultArea.querySelector('.alert');

    resultArea.style.display = 'block';
    alertDiv.className = 'alert alert-warning mb-0 py-2';
    alertDiv.style.borderRadius = '8px';
    alertDiv.innerHTML = `<i class="bi bi-exclamation-triangle-fill me-2"></i>${message}`;
  }

  // 결과 영역 리셋
  resetScanResult() {
    const resultArea = document.getElementById('scanResultArea');
    const alertDiv = resultArea.querySelector('.alert');

    resultArea.style.display = 'none';
    alertDiv.className = 'alert alert-success mb-0 py-2';
    alertDiv.innerHTML = '<i class="bi bi-check-circle-fill me-2"></i><span id="scanResultText"></span>';
  }
}

// 전역으로 노출
window.BarcodeScanner = BarcodeScanner;

// 간편 사용 함수
window.openBarcodeScanner = function(targetInputId, onSuccess, onError) {
  const targetInput = document.getElementById(targetInputId);
  const scanner = new BarcodeScanner({
    targetInput: targetInput,
    onSuccess: onSuccess || function(barcode) {
      console.log('바코드 스캔 성공:', barcode);
    },
    onError: onError || function(error) {
      console.error('바코드 스캔 오류:', error);
    }
  });
  scanner.open();
  return scanner;
};
