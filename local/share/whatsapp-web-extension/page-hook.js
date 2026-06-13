(function () {
  "use strict";

  const STORAGE_SOUND_URL = "wwdt.notificationSoundUrl";
  const SETTINGS_EVENT = "wwdt:settings";
  const EXTERNAL_LINK_REQUEST_EVENT = "wwdt:external-link-request";
  const EXTERNAL_LINK_BRIDGE_ATTR = "data-wwdt-external-link-bridge";
  const CUSTOM_AUDIO_MARK = "wwdtCustomNotificationSound";
  const USER_INPUT_GRACE_MS = 1400;

  const NativeAudio = window.Audio;
  const nativeWindowOpen = window.open.bind(window);
  const nativePlay = HTMLMediaElement.prototype.play;
  let notificationSoundUrl = window.localStorage.getItem(STORAGE_SOUND_URL) || "";
  let lastUserInputAt = 0;

  function markUserInput() {
    lastUserInputAt = Date.now();
  }

  window.addEventListener("pointerdown", markUserInput, true);
  window.addEventListener("keydown", markUserInput, true);
  window.addEventListener("touchstart", markUserInput, true);

  window.addEventListener(SETTINGS_EVENT, (event) => {
    const detail = event.detail || {};
    notificationSoundUrl = detail.soundUrl || "";
    if (notificationSoundUrl) {
      window.localStorage.setItem(STORAGE_SOUND_URL, notificationSoundUrl);
    } else {
      window.localStorage.removeItem(STORAGE_SOUND_URL);
    }
  });

  function isUserControlledAudio(media) {
    if (media.controls || media.loop) return true;
    if (Number.isFinite(media.duration) && media.duration > 7) return true;
    if (Date.now() - lastUserInputAt < USER_INPUT_GRACE_MS) return true;

    const interactiveMedia = media.closest(
      [
        "[data-testid*='audio']",
        "[data-testid*='voice']",
        "[aria-label*='audio' i]",
        "[aria-label*='voz' i]",
        "[aria-label*='voice' i]",
        "[role='button']"
      ].join(",")
    );

    return Boolean(interactiveMedia);
  }

  function shouldReplaceNotificationSound(media) {
    if (!notificationSoundUrl) return false;
    if (!(media instanceof HTMLAudioElement)) return false;
    if (media.dataset && media.dataset[CUSTOM_AUDIO_MARK] === "1") return false;

    const src = media.currentSrc || media.src || "";
    if (src.startsWith("chrome-extension://") || src.startsWith("data:")) return false;
    if (isUserControlledAudio(media)) return false;

    return true;
  }

  function playReplacementSound() {
    const sound = new NativeAudio(notificationSoundUrl);
    sound.dataset[CUSTOM_AUDIO_MARK] = "1";
    sound.preload = "auto";
    sound.volume = 1;
    sound.play().catch(() => {});
  }

  function externalHttpUrl(value) {
    try {
      const url = new URL(value, window.location.href);
      if (url.protocol !== "http:" && url.protocol !== "https:") return "";
      if (url.origin === window.location.origin) return "";
      return url.href;
    } catch (_) {
      return "";
    }
  }

  function requestExternalLinkOpen(url) {
    window.dispatchEvent(new CustomEvent(EXTERNAL_LINK_REQUEST_EVENT, { detail: url }));
  }

  function externalLinkBridgeReady() {
    return document.documentElement?.getAttribute(EXTERNAL_LINK_BRIDGE_ATTR) === "1";
  }

  window.open = function patchedWindowOpen(url) {
    const href = externalHttpUrl(url);
    if (href && externalLinkBridgeReady()) {
      requestExternalLinkOpen(href);
      return null;
    }

    return nativeWindowOpen.apply(window, arguments);
  };

  HTMLMediaElement.prototype.play = function patchedPlay() {
    if (shouldReplaceNotificationSound(this)) {
      try {
        this.pause();
        this.currentTime = 0;
      } catch (_) {}
      playReplacementSound();
      return Promise.resolve();
    }

    return nativePlay.apply(this, arguments);
  };
})();
