/**
 * Device Fingerprinting for Browser-based Authentication
 * Uses available browser APIs to create a unique device identifier
 */

export class DeviceFingerprint {
  static async generate() {
    const components = await this.collectComponents();
    const fingerprintString = JSON.stringify(components);
    return await this.hash(fingerprintString);
  }

  static async collectComponents() {
    return {
      // Screen information
      screen: {
        width: window.screen.width,
        height: window.screen.height,
        colorDepth: window.screen.colorDepth,
        pixelRatio: window.devicePixelRatio
      },

      // Timezone
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      timezoneOffset: new Date().getTimezoneOffset(),

      // Language
      language: navigator.language,
      languages: navigator.languages,

      // Platform
      platform: navigator.platform,
      userAgent: navigator.userAgent,

      // Hardware concurrency (CPU cores)
      hardwareConcurrency: navigator.hardwareConcurrency,

      // Canvas fingerprint
      canvas: await this.getCanvasFingerprint(),

      // WebGL fingerprint
      webgl: this.getWebGLFingerprint(),

      // Fonts (approximation)
      fonts: this.getFonts(),

      // Touch support
      touchSupport: 'ontouchstart' in window || navigator.maxTouchPoints > 0
    };
  }

  static async getCanvasFingerprint() {
    try {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');

      canvas.width = 200;
      canvas.height = 50;

      ctx.textBaseline = 'top';
      ctx.font = '14px Arial';
      ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = '#f60';
      ctx.fillRect(125, 1, 62, 20);
      ctx.fillStyle = '#069';
      ctx.fillText('Device Fingerprint', 2, 15);
      ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
      ctx.fillText('Device Fingerprint', 4, 17);

      return canvas.toDataURL();
    } catch (e) {
      return 'canvas-error';
    }
  }

  static getWebGLFingerprint() {
    try {
      const canvas = document.createElement('canvas');
      const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');

      if (!gl) return 'webgl-not-supported';

      const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
      return {
        vendor: gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL),
        renderer: gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL)
      };
    } catch (e) {
      return 'webgl-error';
    }
  }

  static getFonts() {
    const baseFonts = ['monospace', 'sans-serif', 'serif'];
    const testFonts = [
      'Arial', 'Verdana', 'Times New Roman', 'Courier New', 'Georgia',
      'Palatino', 'Garamond', 'Bookman', 'Comic Sans MS', 'Trebuchet MS',
      'Impact', 'Lucida Console'
    ];

    const detected = [];
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    for (const font of testFonts) {
      let detected_font = false;
      for (const baseFont of baseFonts) {
        ctx.font = `72px ${baseFont}`;
        const baseWidth = ctx.measureText('mmmmmmmmmmlli').width;

        ctx.font = `72px ${font}, ${baseFont}`;
        const testWidth = ctx.measureText('mmmmmmmmmmlli').width;

        if (baseWidth !== testWidth) {
          detected_font = true;
          break;
        }
      }
      if (detected_font) {
        detected.push(font);
      }
    }

    return detected;
  }

  static async hash(str) {
    const encoder = new TextEncoder();
    const data = encoder.encode(str);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }

  static getDeviceInfo() {
    const ua = navigator.userAgent;

    // Browser detection
    let browser = 'Unknown';
    if (ua.includes('Firefox/')) browser = 'Firefox';
    else if (ua.includes('Edg/')) browser = 'Edge';
    else if (ua.includes('Chrome/')) browser = 'Chrome';
    else if (ua.includes('Safari/') && !ua.includes('Chrome/')) browser = 'Safari';

    // OS detection
    let os = 'Unknown';
    if (ua.includes('Windows')) os = 'Windows';
    else if (ua.includes('Mac OS')) os = 'macOS';
    else if (ua.includes('Linux')) os = 'Linux';
    else if (ua.includes('Android')) os = 'Android';
    else if (ua.includes('iOS')) os = 'iOS';

    return {
      browser,
      os,
      device_name: `${browser} on ${os}`
    };
  }

  static async generateAndStore() {
    const fingerprint = await this.generate();
    const deviceInfo = this.getDeviceInfo();

    // Store in sessionStorage for the current session
    sessionStorage.setItem('device_fingerprint', fingerprint);
    sessionStorage.setItem('device_info', JSON.stringify(deviceInfo));

    return {
      fingerprint,
      ...deviceInfo
    };
  }

  static getStored() {
    const fingerprint = sessionStorage.getItem('device_fingerprint');
    const deviceInfo = JSON.parse(sessionStorage.getItem('device_info') || '{}');

    return fingerprint ? { fingerprint, ...deviceInfo } : null;
  }
}

// Auto-generate fingerprint on page load and add to forms
// Use 'turbo:load' for Hotwire Turbo compatibility
document.addEventListener('turbo:load', async () => {
  const stored = DeviceFingerprint.getStored();
  const data = stored || await DeviceFingerprint.generateAndStore();

  console.log('Device fingerprint generated:', data.fingerprint.substring(0, 16) + '...');

  // Add fingerprint to all Devise forms
  // Include: /users/sign_in, /users/sign_up, /users (registration), /admin/users (admin user creation)
  const deviseForms = document.querySelectorAll('form[action*="sign_in"], form[action*="sign_up"], form[action="/users"], form[action*="/admin/users"]');

  deviseForms.forEach(form => {
    // Add fingerprint field
    const fingerprintField = document.createElement('input');
    fingerprintField.type = 'hidden';
    fingerprintField.name = 'device_fingerprint';
    fingerprintField.value = data.fingerprint;
    form.appendChild(fingerprintField);

    // Add browser field
    const browserField = document.createElement('input');
    browserField.type = 'hidden';
    browserField.name = 'device_browser';
    browserField.value = data.browser;
    form.appendChild(browserField);

    // Add OS field
    const osField = document.createElement('input');
    osField.type = 'hidden';
    osField.name = 'device_os';
    osField.value = data.os;
    form.appendChild(osField);

    // Add device name field
    const deviceNameField = document.createElement('input');
    deviceNameField.type = 'hidden';
    deviceNameField.name = 'device_name';
    deviceNameField.value = data.device_name;
    form.appendChild(deviceNameField);
  });
});

// Export for use in other modules if needed
window.DeviceFingerprint = DeviceFingerprint;
