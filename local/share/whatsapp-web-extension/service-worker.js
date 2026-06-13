const NATIVE_HOST = "com.shaka.wwdt_brave";
const OPEN_EXTERNAL_LINK = "wwdt:open-external-link";

function isExternalHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch (_) {
    return false;
  }
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || message.type !== OPEN_EXTERNAL_LINK || !isExternalHttpUrl(message.url)) {
    return;
  }

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
