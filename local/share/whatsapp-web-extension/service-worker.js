const NATIVE_HOST = "com.shaka.wwdt_brave";
const OPEN_EXTERNAL_LINK = "wwdt:open-external-link";
const PING_EXTERNAL_LINK_HOST = "wwdt:ping-external-link-host";
const LOG_EXTERNAL_LINK = "wwdt:log-external-link";
const SEND_SYSTEM_NOTIFICATION = "wwdt:send-system-notification";

function isExternalHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch (_) {
    return false;
  }
}

function logExternalLink(event, data = {}) {
  try {
    chrome.runtime.sendNativeMessage(
      NATIVE_HOST,
      {
        log: {
          event,
          data,
          timestamp: new Date().toISOString()
        }
      },
      () => {
        if (chrome.runtime.lastError) {
          console.warn("WWDT: failed to write external link log", chrome.runtime.lastError.message);
        }
      }
    );
  } catch (error) {
    console.warn("WWDT: failed to schedule external link log", error);
  }
}

function sendNativeMessage(payload, callback) {
  try {
    chrome.runtime.sendNativeMessage(NATIVE_HOST, payload, (response) => {
      if (chrome.runtime.lastError) {
        callback({ ok: false, error: chrome.runtime.lastError.message });
        return;
      }
      callback(response && typeof response === "object" ? response : { ok: true });
    });
  } catch (error) {
    callback({ ok: false, error: error?.message || String(error) });
  }
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message) {
    return;
  }

  if (message.type === LOG_EXTERNAL_LINK) {
    logExternalLink(message.event || "unknown", message.data || {});
    sendResponse({ ok: true });
    return;
  }

  if (message.type === SEND_SYSTEM_NOTIFICATION) {
    const notification = message.notification || {};
    sendNativeMessage({ notification }, (response) => {
      sendResponse(response);
      logExternalLink("service-worker-notification-response", {
        source: notification.source,
        titleLength: typeof notification.title === "string" ? notification.title.length : 0,
        bodyLength: typeof notification.body === "string" ? notification.body.length : 0,
        response
      });
    });
    return true;
  }

  if (message.type === PING_EXTERNAL_LINK_HOST) {
    sendNativeMessage({ ping: true }, (response) => {
      sendResponse(response && response.ok ? { ok: true, browser: response.browser } : response);
      logExternalLink("service-worker-ping-response", { response });
    });
    return true;
  }

  if (message.type !== OPEN_EXTERNAL_LINK || !isExternalHttpUrl(message.url)) return;

  sendNativeMessage({ url: message.url, source: message.source || "unknown" }, (response) => {
    sendResponse(response);
    logExternalLink("service-worker-open-response", { url: message.url, source: message.source, response });
  });

  return true;
});
