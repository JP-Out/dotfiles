(function () {
  "use strict";

  const STORAGE_SOUND_URL = "wwdt.notificationSoundUrl";
  const SETTINGS_EVENT = "wwdt:settings";
  const NOTIFICATION_HINT_EVENT = "wwdt:notification-hint";
  const EXTERNAL_LINK_REQUEST_EVENT = "wwdt:external-link-request";
  const EXTERNAL_LINK_LOG_EVENT = "wwdt:external-link-log";
  const EXTERNAL_LINK_URL_ATTR = "data-wwdt-external-link-url";
  const EXTERNAL_LINK_LOG_ATTR = "data-wwdt-external-link-log";
  const CUSTOM_AUDIO_MARK = "wwdtCustomNotificationSound";
  const NOTIFICATION_AUDIO_GRACE_MS = 1200;
  const NOTIFICATION_FALLBACK_SOUND_MS = 180;
  const NOTIFICATION_SOUND_DEBOUNCE_MS = 500;

  const NativeAudio = window.Audio;
  const NativeNotification = window.Notification;
  const nativeWindowOpen = window.open.bind(window);
  const nativePlay = HTMLMediaElement.prototype.play;
  const nativeShowNotification = window.ServiceWorkerRegistration?.prototype?.showNotification;
  let notificationSoundUrl = window.localStorage.getItem(STORAGE_SOUND_URL) || "";
  let lastNotificationSoundAt = 0;
  let notificationAudioUntil = 0;
  let notificationSoundHandled = false;
  let notificationFallbackTimer = 0;

  window.addEventListener(SETTINGS_EVENT, (event) => {
    const detail = event.detail || {};
    notificationSoundUrl = detail.soundUrl || "";
    if (notificationSoundUrl) {
      window.localStorage.setItem(STORAGE_SOUND_URL, notificationSoundUrl);
    } else {
      window.localStorage.removeItem(STORAGE_SOUND_URL);
    }
  });

  window.addEventListener(NOTIFICATION_HINT_EVENT, () => {
    scheduleNotificationSound();
  });

  function isUserControlledAudio(media) {
    if (media.controls || media.loop) return true;
    if (Number.isFinite(media.duration) && media.duration > 7) return true;

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

  function shouldReplaceNotificationAudio(media) {
    if (!notificationSoundUrl) return false;
    if (!(media instanceof HTMLAudioElement)) return false;
    if (media.dataset && media.dataset[CUSTOM_AUDIO_MARK] === "1") return false;
    if (isUserControlledAudio(media)) return false;

    const src = media.currentSrc || media.src || "";
    if (src.startsWith("chrome-extension://")) return false;

    const hintedNotificationAudio = Date.now() <= notificationAudioUntil;
    const unfocusedShortAudio =
      !document.hasFocus() &&
      (!Number.isFinite(media.duration) || media.duration <= 4);

    return hintedNotificationAudio || unfocusedShortAudio;
  }

  function playReplacementSound() {
    if (!notificationSoundUrl) return;
    const now = Date.now();
    if (now - lastNotificationSoundAt < NOTIFICATION_SOUND_DEBOUNCE_MS) return;
    lastNotificationSoundAt = now;
    notificationSoundHandled = true;

    const sound = new NativeAudio(notificationSoundUrl);
    sound.dataset[CUSTOM_AUDIO_MARK] = "1";
    sound.preload = "auto";
    sound.volume = 1;
    sound.play().catch(() => {});
  }

  function scheduleNotificationSound() {
    if (!notificationSoundUrl) return;
    notificationAudioUntil = Date.now() + NOTIFICATION_AUDIO_GRACE_MS;
    notificationSoundHandled = false;

    if (notificationFallbackTimer) {
      clearTimeout(notificationFallbackTimer);
    }

    notificationFallbackTimer = window.setTimeout(() => {
      notificationFallbackTimer = 0;
      if (!notificationSoundHandled && Date.now() <= notificationAudioUntil) {
        playReplacementSound();
      }
    }, NOTIFICATION_FALLBACK_SOUND_MS);
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
    const root = document.documentElement;
    root.setAttribute(EXTERNAL_LINK_LOG_ATTR, JSON.stringify({ event: "page-window-open", url }));
    root.setAttribute(EXTERNAL_LINK_URL_ATTR, url);
    document.dispatchEvent(new Event(EXTERNAL_LINK_LOG_EVENT));
    document.dispatchEvent(new Event(EXTERNAL_LINK_REQUEST_EVENT));
  }

  window.open = function patchedWindowOpen(url) {
    const href = externalHttpUrl(url);
    if (href) {
      requestExternalLinkOpen(href);
      return null;
    }

    return nativeWindowOpen.apply(window, arguments);
  };

  if (typeof NativeNotification === "function") {
    function PatchedNotification() {
      const notification = Reflect.construct(NativeNotification, arguments, new.target || PatchedNotification);
      scheduleNotificationSound();
      return notification;
    }

    Object.setPrototypeOf(PatchedNotification, NativeNotification);
    PatchedNotification.prototype = NativeNotification.prototype;
    Object.defineProperty(PatchedNotification, "permission", {
      configurable: true,
      enumerable: true,
      get() {
        return NativeNotification.permission;
      }
    });
    PatchedNotification.requestPermission = NativeNotification.requestPermission.bind(NativeNotification);
    window.Notification = PatchedNotification;
  }

  if (nativeShowNotification && window.ServiceWorkerRegistration?.prototype) {
    window.ServiceWorkerRegistration.prototype.showNotification = function patchedShowNotification() {
      const result = nativeShowNotification.apply(this, arguments);
      scheduleNotificationSound();
      return result;
    };
  }

  HTMLMediaElement.prototype.play = function patchedPlay() {
    if (shouldReplaceNotificationAudio(this)) {
      try {
        this.pause();
        this.currentTime = 0;
      } catch (_) {}

      if (notificationFallbackTimer) {
        clearTimeout(notificationFallbackTimer);
        notificationFallbackTimer = 0;
      }
      playReplacementSound();
      return Promise.resolve();
    }

    return nativePlay.apply(this, arguments);
  };
})();
