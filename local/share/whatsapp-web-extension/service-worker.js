const NATIVE_HOST = "com.shaka.wwdt_brave";
const OPEN_EXTERNAL_LINK = "wwdt:open-external-link";
const PING_EXTERNAL_LINK_HOST = "wwdt:ping-external-link-host";

function isExternalHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch (_) {
    return false;
  }
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message) {
    return;
  }

  if (message.type === PING_EXTERNAL_LINK_HOST) {
    chrome.runtime.sendNativeMessage(NATIVE_HOST, { ping: true }, (response) => {
      if (chrome.runtime.lastError) {
        sendResponse({ ok: false, error: chrome.runtime.lastError.message });
        return;
      }
      sendResponse(response && response.ok ? { ok: true } : { ok: false });
    });
    return true;
  }

  if (message.type !== OPEN_EXTERNAL_LINK || !isExternalHttpUrl(message.url)) return;

  chrome.runtime.sendNativeMessage(
    NATIVE_HOST,
    { url: message.url },
    (response) => {
      if (chrome.runtime.lastError) {
        sendResponse({ ok: false, error: chrome.runtime.lastError.message });
        return;
      }
      sendResponse(response && typeof response === "object" ? response : { ok: true });
    }
  );

  return true;
});
