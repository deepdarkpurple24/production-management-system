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
              <div id="scannerContainer" style="position: relative; width: 100%; height: 200px; overflow: hidden;">
                <video id="scannerVideo" style="width: 100%; height: 100%; object-fit: cover;" playsinline autoplay muted></video>
                <canvas id="scannerCanvas" style="display: none;"></canvas>
                <!-- 스캔 가이드라인 -->
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
                            width: 80%; height: 60px; border: 2px solid rgba(0, 122, 255, 0.8);
                            border-radius: 8px; box-shadow: 0 0 0 9999px rgba(0,0,0,0.5);">
                  <div style="position: absolute; top: -25px; left: 50%; transform: translateX(-50%);
                              color: white; font-size: 12px; white-space: nowrap; text-shadow: 0 1px 2px rgba(0,0,0,0.8);">
                    바코드를 가이드라인 안에 맞춰주세요
                  </div>
                </div>
                <!-- 로딩 표시 -->
                <div id="scannerLoading" style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); display: none;">
                  <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="modal-footer justify-content-center py-2" style="background: #f8f9fa; border: none;">
              <button type="button" id="captureBtn" class="btn btn-primary px-4" style="border-radius: 20px;">
                <i class="bi bi-camera-fill me-2"></i>스캔
              </button>
              <button type="button" class="btn btn-outline-secondary px-3" data-bs-dismiss="modal" style="border-radius: 20px;">
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
      // 후면 카메라 우선 사용
      const constraints = {
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      };

      this.videoStream = await navigator.mediaDevices.getUserMedia(constraints);
      video.srcObject = this.videoStream;

      video.onloadedmetadata = () => {
        loading.style.display = 'none';
        this.isScanning = true;
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
  }

  // 캡처 후 스캔
  async captureAndScan() {
    if (!this.isScanning || !this.video) {
      return;
    }

    const captureBtn = document.getElementById('captureBtn');
    const loading = document.getElementById('scannerLoading');

    // 버튼 비활성화 및 로딩 표시
    captureBtn.disabled = true;
    captureBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>분석 중...';
    loading.style.display = 'block';

    try {
      // 캔버스에 현재 프레임 캡처
      const canvas = document.getElementById('scannerCanvas');
      const video = this.video;

      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      const ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

      // QuaggaJS로 바코드 디코딩
      const imageData = canvas.toDataURL('image/jpeg', 0.9);

      Quagga.decodeSingle({
        src: imageData,
        numOfWorkers: 0,
        inputStream: {
          size: 800
        },
        decoder: {
          readers: [
            'ean_reader',
            'ean_8_reader',
            'code_128_reader',
            'code_39_reader',
            'upc_reader',
            'upc_e_reader',
            'i2of5_reader'
          ]
        },
        locate: true,
        locator: {
          halfSample: false,
          patchSize: 'medium'
        }
      }, (result) => {
        loading.style.display = 'none';
        captureBtn.disabled = false;
        captureBtn.innerHTML = '<i class="bi bi-camera-fill me-2"></i>스캔';

        if (result && result.codeResult && result.codeResult.code) {
          const barcode = result.codeResult.code;
          this.handleSuccess(barcode);
        } else {
          this.showError('바코드를 인식할 수 없습니다. 바코드를 가이드라인 안에 맞추고 다시 시도해주세요.');
        }
      });
    } catch (error) {
      console.error('스캔 오류:', error);
      loading.style.display = 'none';
      captureBtn.disabled = false;
      captureBtn.innerHTML = '<i class="bi bi-camera-fill me-2"></i>스캔';
      this.showError('스캔 중 오류가 발생했습니다.');
    }
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
