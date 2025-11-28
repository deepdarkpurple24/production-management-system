import { Controller } from "@hotwired/stimulus"

// Session timeout warning controller
// Warns users before their session expires due to inactivity
export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 2 }, // minutes
    warningTime: { type: Number, default: 0.5 } // minutes before timeout to show warning (30 seconds)
  }

  connect() {
    this.timeoutMilliseconds = this.timeoutValue * 60 * 1000
    this.warningMilliseconds = (this.timeoutValue - this.warningTimeValue) * 60 * 1000

    this.resetTimer()
    this.setupActivityListeners()
  }

  disconnect() {
    this.clearTimers()
    this.removeActivityListeners()
  }

  setupActivityListeners() {
    // Events that indicate user activity
    this.activityEvents = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click']

    this.activityHandler = this.resetTimer.bind(this)
    this.activityEvents.forEach(event => {
      document.addEventListener(event, this.activityHandler, true)
    })
  }

  removeActivityListeners() {
    if (this.activityHandler) {
      this.activityEvents.forEach(event => {
        document.removeEventListener(event, this.activityHandler, true)
      })
    }
  }

  resetTimer() {
    this.clearTimers()

    // Set warning timer
    this.warningTimer = setTimeout(() => {
      this.showWarning()
    }, this.warningMilliseconds)

    // Set logout timer
    this.logoutTimer = setTimeout(() => {
      this.logout()
    }, this.timeoutMilliseconds)
  }

  clearTimers() {
    if (this.warningTimer) {
      clearTimeout(this.warningTimer)
      this.warningTimer = null
    }
    if (this.logoutTimer) {
      clearTimeout(this.logoutTimer)
      this.logoutTimer = null
    }
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
  }

  showWarning() {
    const remainingMinutes = this.warningTimeValue

    // Create warning toast
    const toastHtml = `
      <div id="session-timeout-warning" class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 9999;">
        <div class="toast show" role="alert">
          <div class="toast-header bg-warning text-dark">
            <i class="bi bi-clock-history me-2"></i>
            <strong class="me-auto">세션 만료 경고</strong>
            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
          </div>
          <div class="toast-body">
            <p class="mb-2">비활성으로 인해 <strong id="countdown">${remainingMinutes}</strong>분 후 자동 로그아웃됩니다.</p>
            <button class="btn btn-sm btn-primary w-100" id="stay-logged-in">
              <i class="bi bi-check-circle me-1"></i>
              계속 사용하기
            </button>
          </div>
        </div>
      </div>
    `

    // Remove existing warning if any
    const existingWarning = document.getElementById('session-timeout-warning')
    if (existingWarning) {
      existingWarning.remove()
    }

    // Add warning to page
    document.body.insertAdjacentHTML('beforeend', toastHtml)

    // Add event listener to "Stay logged in" button
    const stayButton = document.getElementById('stay-logged-in')
    if (stayButton) {
      stayButton.addEventListener('click', () => {
        this.stayLoggedIn()
      })
    }

    // Start countdown
    let remaining = remainingMinutes * 60 // seconds
    this.countdownInterval = setInterval(() => {
      remaining--
      const minutes = Math.floor(remaining / 60)
      const seconds = remaining % 60
      const countdownElement = document.getElementById('countdown')
      if (countdownElement) {
        countdownElement.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
      }

      if (remaining <= 0) {
        clearInterval(this.countdownInterval)
      }
    }, 1000)
  }

  stayLoggedIn() {
    // Remove warning
    const warning = document.getElementById('session-timeout-warning')
    if (warning) {
      warning.remove()
    }

    // Reset timer by triggering activity
    this.resetTimer()

    // Show success message
    if (window.toast) {
      window.toast.success('세션이 연장되었습니다', '계속 사용')
    }
  }

  logout() {
    // Clear timers
    this.clearTimers()

    // Remove warning if visible
    const warning = document.getElementById('session-timeout-warning')
    if (warning) {
      warning.remove()
    }

    // Show logout message
    if (window.toast) {
      window.toast.warning('비활성으로 인해 로그아웃되었습니다', '세션 만료')
    }

    // Redirect to sign out
    setTimeout(() => {
      window.location.href = '/users/sign_out'
    }, 2000)
  }
}
