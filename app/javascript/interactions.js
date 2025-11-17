// ===================================
// Apple-style Interaction Helpers
// ===================================

// Toast Notification System
class ToastManager {
  constructor() {
    this.container = this.createContainer();
  }

  createContainer() {
    let container = document.querySelector('.toast-container');
    if (!container) {
      container = document.createElement('div');
      container.className = 'toast-container';
      document.body.appendChild(container);
    }
    return container;
  }

  show(message, type = 'info', title = null, duration = 4000) {
    const toast = this.createToast(message, type, title);
    this.container.appendChild(toast);

    // Auto dismiss
    setTimeout(() => {
      this.dismiss(toast);
    }, duration);

    return toast;
  }

  createToast(message, type, title) {
    const toast = document.createElement('div');
    toast.className = `toast-apple toast-${type}`;

    const icons = {
      success: 'bi-check-circle-fill',
      error: 'bi-x-circle-fill',
      warning: 'bi-exclamation-triangle-fill',
      info: 'bi-info-circle-fill'
    };

    const titles = {
      success: '성공',
      error: '오류',
      warning: '경고',
      info: '알림'
    };

    const icon = icons[type] || icons.info;
    const defaultTitle = titles[type] || titles.info;

    toast.innerHTML = `
      <i class="toast-icon bi ${icon}"></i>
      <div class="toast-content">
        ${title || defaultTitle ? `<div class="toast-title">${title || defaultTitle}</div>` : ''}
        <p class="toast-message">${message}</p>
      </div>
      <button class="toast-close" aria-label="닫기">
        <i class="bi bi-x"></i>
      </button>
    `;

    toast.querySelector('.toast-close').addEventListener('click', () => {
      this.dismiss(toast);
    });

    return toast;
  }

  dismiss(toast) {
    toast.style.animation = 'slideInRight 0.3s ease reverse';
    setTimeout(() => {
      toast.remove();
    }, 300);
  }

  success(message, title = null) {
    return this.show(message, 'success', title);
  }

  error(message, title = null) {
    return this.show(message, 'error', title);
  }

  warning(message, title = null) {
    return this.show(message, 'warning', title);
  }

  info(message, title = null) {
    return this.show(message, 'info', title);
  }
}

// Create global toast instance
window.toast = new ToastManager();

// Loading Overlay Manager
class LoadingManager {
  constructor() {
    this.overlay = this.createOverlay();
  }

  createOverlay() {
    let overlay = document.querySelector('.loading-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.className = 'loading-overlay';
      overlay.innerHTML = '<div class="spinner-apple"></div>';
      document.body.appendChild(overlay);
    }
    return overlay;
  }

  show() {
    this.overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  hide() {
    this.overlay.classList.remove('active');
    document.body.style.overflow = '';
  }
}

// Create global loading instance
window.loading = new LoadingManager();

// Button Loading State Helper
function setButtonLoading(button, isLoading) {
  if (isLoading) {
    button.classList.add('btn-loading');
    button.disabled = true;
    button.dataset.originalText = button.innerHTML;
  } else {
    button.classList.remove('btn-loading');
    button.disabled = false;
    if (button.dataset.originalText) {
      button.innerHTML = button.dataset.originalText;
    }
  }
}

window.setButtonLoading = setButtonLoading;

// Form Validation Helper
function validateForm(formElement) {
  const inputs = formElement.querySelectorAll('input[required], textarea[required], select[required]');
  let isValid = true;

  inputs.forEach(input => {
    const value = input.value.trim();
    const feedbackElement = input.parentElement.querySelector('.invalid-feedback');

    if (!value) {
      input.classList.add('is-invalid');
      input.classList.remove('is-valid');
      if (feedbackElement) {
        feedbackElement.textContent = '이 필드는 필수입니다.';
      }
      isValid = false;
    } else {
      input.classList.remove('is-invalid');
      input.classList.add('is-valid');
    }
  });

  return isValid;
}

window.validateForm = validateForm;

// Real-time Form Validation
document.addEventListener('DOMContentLoaded', () => {
  // Add validation feedback divs to all required fields
  const requiredInputs = document.querySelectorAll('input[required], textarea[required], select[required]');

  requiredInputs.forEach(input => {
    if (!input.parentElement.querySelector('.invalid-feedback')) {
      const feedback = document.createElement('div');
      feedback.className = 'invalid-feedback';
      input.parentElement.appendChild(feedback);
    }

    // Real-time validation
    input.addEventListener('blur', () => {
      const value = input.value.trim();
      const feedbackElement = input.parentElement.querySelector('.invalid-feedback');

      if (!value) {
        input.classList.add('is-invalid');
        input.classList.remove('is-valid');
        if (feedbackElement) {
          feedbackElement.textContent = '이 필드는 필수입니다.';
        }
      } else {
        input.classList.remove('is-invalid');
        input.classList.add('is-valid');
      }
    });

    input.addEventListener('input', () => {
      if (input.classList.contains('is-invalid') && input.value.trim()) {
        input.classList.remove('is-invalid');
        input.classList.add('is-valid');
      }
    });
  });

  // Add page transition animation
  document.body.classList.add('page-transition');
});

// Confirm Dialog Helper (Apple-style)
function confirmDialog(message, title = '확인') {
  return new Promise((resolve) => {
    const confirmed = confirm(`${title}\n\n${message}`);
    resolve(confirmed);
  });
}

window.confirmDialog = confirmDialog;

// Debounce Helper for Search/Filter
function debounce(func, wait = 300) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

window.debounce = debounce;

// Smooth Scroll Helper
function smoothScrollTo(element) {
  element.scrollIntoView({
    behavior: 'smooth',
    block: 'start'
  });
}

window.smoothScrollTo = smoothScrollTo;

// Export for module usage
export { ToastManager, LoadingManager, setButtonLoading, validateForm, confirmDialog, debounce, smoothScrollTo };
