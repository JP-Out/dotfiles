(function () {
  "use strict";

  const STORAGE_KEY = "wwdt.settings";
  const SETTINGS_EVENT = "wwdt:settings";
  const STORAGE_SOUND_URL = "wwdt.notificationSoundUrl";
  const NOTIFICATION_HINT_EVENT = "wwdt:notification-hint";
  const SIDEBAR_BUTTON_ID = "wwdt-sidebar-toggle";
  const NOTIFICATION_BUTTON_ID = "wwdt-notification-button";
  const SELECTION_CONTEXT_MENU_ID = "wwdt-selection-context-menu";
  const OPEN_EXTERNAL_LINK = "wwdt:open-external-link";
  const PING_EXTERNAL_LINK_HOST = "wwdt:ping-external-link-host";
  const LOG_EXTERNAL_LINK = "wwdt:log-external-link";
  const EXTERNAL_LINK_REQUEST_EVENT = "wwdt:external-link-request";
  const EXTERNAL_LINK_LOG_EVENT = "wwdt:external-link-log";
  const EXTERNAL_LINK_BRIDGE_ATTR = "data-wwdt-external-link-bridge";
  const EXTERNAL_LINK_URL_ATTR = "data-wwdt-external-link-url";
  const EXTERNAL_LINK_LOG_ATTR = "data-wwdt-external-link-log";
  const devtoolsMode = new URLSearchParams(window.location.search).get("wwdt-devtools") === "1";
  const manifest = chrome.runtime.getManifest();
  const canHandleExternalLinks =
    Array.isArray(manifest.permissions) &&
    manifest.permissions.includes("nativeMessaging") &&
    Boolean(manifest.background?.service_worker);
  const UNREAD_WARMUP_MS = 10000;
  const UNREAD_SOUND_COOLDOWN_MS = 1200;

  const SYSTEM_DEFAULT_SOUND = {
    id: "system_default",
    name: "Padrão do Sistema",
    url: ""
  };

  const BUILTIN_SOUNDS = [
    {
      id: "whatsapp_1",
      name: "whatsapp_1.mp3",
      url: chrome.runtime.getURL("sounds/whatsapp_1.mp3")
    },
    {
      id: "whatsapp_2",
      name: "whatsapp_2.mp3",
      url: chrome.runtime.getURL("sounds/whatsapp_2.mp3")
    }
  ];

  const DEFAULT_SETTINGS = {
    sidebarCollapsed: false,
    selectedSoundId: SYSTEM_DEFAULT_SOUND.id,
    customSounds: []
  };

  let settings = { ...DEFAULT_SETTINGS };
  let mutationScheduled = false;
  let scriptStartedAt = Date.now();
  let unreadBaselineReady = false;
  let lastUnreadCount = 0;
  let lastUnreadSoundAt = 0;
  let sidebarTarget = null;

  const collapsedIcon = `
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" class="wwdt-nav-icon">
      <rect x="3" y="3" width="18" height="18" rx="3.6" stroke="currentColor" stroke-width="1.9"/>
      <path d="M9.25 4.25V19.75" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/>
      <rect x="5.1" y="5.8" width="2.8" height="12.4" rx="1.3" fill="currentColor"/>
    </svg>`;

  const expandedIcon = `
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" class="wwdt-nav-icon">
      <rect x="3" y="3" width="18" height="18" rx="3.6" stroke="currentColor" stroke-width="1.9"/>
      <path d="M9.25 4.25V19.75" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/>
      <rect x="5.1" y="5.8" width="2.8" height="12.4" rx="1.3" fill="currentColor" opacity="0.28"/>
      <rect x="11.15" y="5.8" width="7" height="12.4" rx="1.35" fill="currentColor" opacity="0.28"/>
    </svg>`;

  const bellIcon = `
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" class="wwdt-nav-icon">
      <path fill-rule="evenodd" clip-rule="evenodd" d="M12 2.25C9.18 2.25 6.88 4.55 6.88 7.38V9.55C6.88 10.81 6.48 12.04 5.74 13.06L4.75 14.43C3.81 15.73 4.74 17.55 6.34 17.55H17.66C19.26 17.55 20.19 15.73 19.25 14.43L18.26 13.06C17.52 12.04 17.12 10.81 17.12 9.55V7.38C17.12 4.55 14.82 2.25 12 2.25ZM9.2 19.05C9.58 20.61 10.98 21.75 12.64 21.75C14.3 21.75 15.7 20.61 16.08 19.05H9.2Z" fill="currentColor"/>
    </svg>`;

  const copyIcon = `
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" class="wwdt-context-icon">
      <rect x="8.25" y="7.25" width="9.5" height="12.5" rx="1.6" stroke="currentColor" stroke-width="1.7"/>
      <path d="M5.75 16.25H5.5C4.67 16.25 4 15.58 4 14.75V5.5C4 4.67 4.67 4 5.5 4H13.25C14.08 4 14.75 4.67 14.75 5.5V5.75" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>
    </svg>`;

  function chromeStorageGet(key) {
    return new Promise((resolve) => {
      chrome.storage.local.get(key, (value) => resolve(value[key]));
    });
  }

  function chromeStorageSet(value) {
    return new Promise((resolve) => chrome.storage.local.set(value, resolve));
  }

  async function loadSettings() {
    const stored = await chromeStorageGet(STORAGE_KEY);
    settings = {
      ...DEFAULT_SETTINGS,
      ...(stored && typeof stored === "object" ? stored : {})
    };
    settings.customSounds = Array.isArray(settings.customSounds) ? settings.customSounds : [];
    if (!allSounds().some((sound) => sound.id === settings.selectedSoundId)) {
      settings.selectedSoundId = SYSTEM_DEFAULT_SOUND.id;
    }
    syncPageHook();
    setSidebarCollapsed(settings.sidebarCollapsed);
  }

  async function saveSettings() {
    await chromeStorageSet({ [STORAGE_KEY]: settings });
    syncPageHook();
  }

  function allSounds() {
    return [...BUILTIN_SOUNDS, ...settings.customSounds, SYSTEM_DEFAULT_SOUND];
  }

  function selectedSound() {
    return allSounds().find((sound) => sound.id === settings.selectedSoundId) || SYSTEM_DEFAULT_SOUND;
  }

  function syncPageHook() {
    const sound = selectedSound();
    const soundUrl = sound ? sound.url : "";
    if (soundUrl) {
      window.localStorage.setItem(STORAGE_SOUND_URL, soundUrl);
    } else {
      window.localStorage.removeItem(STORAGE_SOUND_URL);
    }
    window.dispatchEvent(new CustomEvent(SETTINGS_EVENT, { detail: { soundUrl } }));
  }

  function selectedSoundUrl() {
    return selectedSound()?.url || "";
  }

  function parseUnreadCount() {
    const titleMatch = document.title.match(/^\((\d+)\)\s+/);
    if (titleMatch) return Number.parseInt(titleMatch[1], 10) || 0;
    return 0;
  }

  function shouldPlayUnreadNotificationSound(nextUnreadCount) {
    if (!selectedSoundUrl()) return false;
    if (!unreadBaselineReady) return false;
    if (Date.now() - scriptStartedAt < UNREAD_WARMUP_MS) return false;
    if (document.hasFocus()) return false;
    if (nextUnreadCount <= lastUnreadCount) return false;
    if (Date.now() - lastUnreadSoundAt < UNREAD_SOUND_COOLDOWN_MS) return false;
    return true;
  }

  function notifyPageHookAboutUnread() {
    lastUnreadSoundAt = Date.now();
    window.dispatchEvent(new CustomEvent(NOTIFICATION_HINT_EVENT));
  }

  function refreshUnreadNotificationState() {
    const nextUnreadCount = parseUnreadCount();

    if (!unreadBaselineReady) {
      lastUnreadCount = nextUnreadCount;
      unreadBaselineReady = true;
      return;
    }

    if (shouldPlayUnreadNotificationSound(nextUnreadCount)) {
      notifyPageHookAboutUnread();
    }

    lastUnreadCount = nextUnreadCount;
  }

  function cleanCloneIds(node) {
    if (node instanceof Element) {
      node.removeAttribute("id");
      node.removeAttribute("data-testid");
      node.removeAttribute("data-visualcompletion");
      node.querySelectorAll("[id], [data-testid], [data-visualcompletion]").forEach((child) => {
        child.removeAttribute("id");
        child.removeAttribute("data-testid");
        child.removeAttribute("data-visualcompletion");
      });
    }
  }

  function createFallbackNavButton(id, label) {
    const shell = document.createElement("span");
    shell.className = "wwdt-nav-shell";

    const outer = document.createElement("div");
    outer.className = "wwdt-nav-outer";

    const button = document.createElement("button");
    button.type = "button";
    button.className = "wwdt-nav-button";
    button.dataset.navbarItem = "true";

    const stack = document.createElement("div");
    stack.className = "wwdt-nav-stack";

    const row = document.createElement("div");
    row.className = "wwdt-nav-row";

    const iconSlot = document.createElement("div");
    iconSlot.className = "wwdt-nav-icon-slot";

    const iconFrame = document.createElement("span");
    iconFrame.className = "wwdt-nav-icon-frame";
    iconFrame.setAttribute("aria-hidden", "true");

    iconSlot.appendChild(iconFrame);
    row.appendChild(iconSlot);
    stack.appendChild(row);
    button.appendChild(stack);
    outer.appendChild(button);
    shell.appendChild(outer);
    shell.appendChild(document.createElement("span")).className = "wwdt-selection-pill";

    button.id = id;
    button.setAttribute("aria-label", label);
    return shell;
  }

  function createNavButton(id, label, html, onClick, referenceItem) {
    let shell = referenceItem?.cloneNode(true) || createFallbackNavButton(id, label);
    cleanCloneIds(shell);
    shell.classList.add("wwdt-nav-shell");
    shell.querySelectorAll("img, [role='status']").forEach((node) => node.remove());

    let button = shell.querySelector("button");
    if (!button) {
      shell = createFallbackNavButton(id, label);
      button = shell.querySelector("button");
    }

    button.id = id;
    button.type = "button";
    button.classList.add("wwdt-nav-button");
    button.dataset.wwdtNav = id;
    button.dataset.navbarItem = "true";
    button.dataset.navbarItemSelected = "false";
    button.removeAttribute("data-navbar-item-index");
    button.removeAttribute("aria-disabled");
    button.setAttribute("aria-label", label);
    button.setAttribute("aria-pressed", "false");
    button.setAttribute("tabindex", "-1");

    let iconFrame = shell.querySelector("span[aria-hidden='true']");
    if (!iconFrame) {
      iconFrame = document.createElement("span");
      iconFrame.setAttribute("aria-hidden", "true");
      button.prepend(iconFrame);
    }
    iconFrame.classList.add("wwdt-nav-icon-frame");
    iconFrame.innerHTML = html;

    if (!shell.querySelector(".wwdt-selection-pill")) {
      const pill = document.createElement("span");
      pill.className = "wwdt-selection-pill";
      shell.appendChild(pill);
    }

    button.addEventListener("click", onClick);
    return shell;
  }

  function findInsertPoint() {
    const mediaButton = document.querySelector("button[aria-label='Mídia'], button[aria-label='Media']");
    if (mediaButton) {
      return mediaButton.closest("span") || mediaButton.parentElement;
    }

    const communitiesButton = document.querySelector("button[aria-label='Comunidades'], button[aria-label='Communities']");
    if (communitiesButton) {
      const item = communitiesButton.closest("span") || communitiesButton.parentElement;
      return item ? item.nextElementSibling || item : null;
    }

    return document.querySelector("header[data-testid='chatlist-header'] button[data-navbar-item='true']")?.closest("span");
  }

  function injectNavButtons() {
    if (document.getElementById(SIDEBAR_BUTTON_ID) && document.getElementById(NOTIFICATION_BUTTON_ID)) {
      updateSidebarButton();
      updateNotificationButton(Boolean(document.querySelector(".wwdt-modal-backdrop")));
      return;
    }

    const insertPoint = findInsertPoint();
    if (!insertPoint || !insertPoint.parentElement) return;

    if (!document.getElementById(SIDEBAR_BUTTON_ID)) {
      const sidebarButton = createNavButton(
        SIDEBAR_BUTTON_ID,
        settings.sidebarCollapsed ? "Mostrar lista de conversas" : "Ocultar lista de conversas",
        settings.sidebarCollapsed ? expandedIcon : collapsedIcon,
        () => setSidebarCollapsed(!settings.sidebarCollapsed, true),
        insertPoint
      );
      insertPoint.parentElement.insertBefore(sidebarButton, insertPoint);
    }

    if (!document.getElementById(NOTIFICATION_BUTTON_ID)) {
      const notificationButton = createNavButton(
        NOTIFICATION_BUTTON_ID,
        "Som de notificação",
        bellIcon,
        openNotificationModal,
        insertPoint
      );
      insertPoint.parentElement.insertBefore(notificationButton, insertPoint);
    }
  }

  function findSidebarTarget() {
    const anchor = document.querySelector(
      [
        "#side",
        "#pane-side",
        "[data-testid='chat-list']",
        "[aria-label='Lista de conversas']",
        "[aria-label='Chat list']"
      ].join(",")
    );

    if (!anchor) return null;

    let candidate = anchor;
    let node = anchor.parentElement;
    while (node && node !== document.body) {
      if (node.querySelector(":scope > #side")) {
        candidate = node;
        break;
      }

      const rect = node.getBoundingClientRect();
      const styles = getComputedStyle(node);
      const keepsNavRailVisible = rect.left > 48;
      const reservesSidebarWidth =
        styles.flexBasis.endsWith("%") ||
        styles.maxWidth.endsWith("%") ||
        styles.flex.includes("%");
      const looksLikeSidebarColumn =
        rect.height > window.innerHeight * 0.65 &&
        rect.width > 220 &&
        rect.width < window.innerWidth * 0.55;

      if (keepsNavRailVisible && looksLikeSidebarColumn && reservesSidebarWidth) {
        candidate = node;
      }
      node = node.parentElement;
    }

    return candidate;
  }

  function setSidebarCollapsed(collapsed, persist = false) {
    settings.sidebarCollapsed = Boolean(collapsed);
    sidebarTarget = findSidebarTarget() || sidebarTarget;

    document.querySelectorAll(".wwdt-chat-pane-collapsed").forEach((node) => {
      if (node !== sidebarTarget) node.classList.remove("wwdt-chat-pane-collapsed");
    });

    if (sidebarTarget) {
      sidebarTarget.classList.toggle("wwdt-chat-pane-collapsed", settings.sidebarCollapsed);
    }

    updateCollapsedLayoutClasses();
    updateSidebarButton();
    if (persist) saveSettings();
  }

  function updateCollapsedLayoutClasses() {
    document.body.classList.toggle("wwdt-sidebar-is-collapsed", settings.sidebarCollapsed);
    document.querySelectorAll(".wwdt-layout-sidebar-collapsed, .wwdt-collapse-divider-cleanup").forEach((node) => {
      node.classList.remove("wwdt-layout-sidebar-collapsed", "wwdt-collapse-divider-cleanup");
    });

    if (!settings.sidebarCollapsed || !sidebarTarget?.parentElement) return;

    const layoutRoot = sidebarTarget.parentElement;
    layoutRoot.classList.add("wwdt-layout-sidebar-collapsed");

    const navRail = layoutRoot.querySelector("header[data-testid='chatlist-header']");
    const navRailRight = navRail ? navRail.getBoundingClientRect().right : 64;

    layoutRoot.querySelectorAll("div, section, main, span").forEach((node) => {
      const rect = node.getBoundingClientRect();
      if (rect.height < window.innerHeight * 0.72 || rect.left <= navRailRight + 8) return;

      const styles = getComputedStyle(node);
      if (parseFloat(styles.borderLeftWidth) > 0) {
        node.classList.add("wwdt-collapse-divider-cleanup");
      }
    });
  }

  function updateSidebarButton() {
    const button = document.getElementById(SIDEBAR_BUTTON_ID);
    if (!button) return;
    button.setAttribute("aria-pressed", String(settings.sidebarCollapsed));
    button.dataset.navbarItemSelected = String(settings.sidebarCollapsed);
    button.setAttribute("aria-label", settings.sidebarCollapsed ? "Mostrar lista de conversas" : "Ocultar lista de conversas");
    const iconFrame = button.querySelector(".wwdt-nav-icon-frame");
    if (iconFrame) {
      iconFrame.innerHTML = settings.sidebarCollapsed ? expandedIcon : collapsedIcon;
    } else {
      button.innerHTML = settings.sidebarCollapsed ? expandedIcon : collapsedIcon;
    }
    const shell = button.closest(".wwdt-nav-shell");
    shell?.classList.toggle("wwdt-nav-selected", settings.sidebarCollapsed);
  }

  function updateNotificationButton(selected) {
    const button = document.getElementById(NOTIFICATION_BUTTON_ID);
    if (!button) return;
    button.setAttribute("aria-pressed", String(selected));
    button.dataset.navbarItemSelected = String(selected);
    button.closest(".wwdt-nav-shell")?.classList.toggle("wwdt-nav-selected", selected);
  }

  function selectSound(soundId) {
    settings.selectedSoundId = soundId;
    saveSettings();
    const sound = selectedSound();
    if (sound?.url) {
      new Audio(sound.url).play().catch(() => {});
    }
    renderSoundList();
  }

  function renderSoundList() {
    const list = document.querySelector(".wwdt-sound-list");
    if (!list) return;

    list.textContent = "";
    for (const sound of allSounds()) {
      const row = document.createElement("button");
      row.type = "button";
      row.className = "wwdt-radio-row";
      row.setAttribute("role", "radio");
      row.setAttribute("aria-checked", String(sound.id === settings.selectedSoundId));
      row.innerHTML = `<span class="wwdt-radio" aria-hidden="true"></span><span>${escapeHtml(sound.name)}</span>`;
      row.addEventListener("click", () => selectSound(sound.id));
      list.appendChild(row);
    }
  }

  function openNotificationModal() {
    closeNotificationModal();
    updateNotificationButton(true);

    const backdrop = document.createElement("div");
    backdrop.className = "wwdt-modal-backdrop";
    backdrop.innerHTML = `
      <section class="wwdt-modal" role="dialog" aria-modal="true" aria-labelledby="wwdt-modal-title">
        <div class="wwdt-modal-body">
          <h1 id="wwdt-modal-title">Notificação do Sistema</h1>
          <div class="wwdt-sound-list" role="radiogroup"></div>
          <button class="wwdt-add-sound" type="button">
            <span class="wwdt-add-icon" aria-hidden="true"></span>
            <span>Adicionar Notificação Personalizada</span>
          </button>
          <input class="wwdt-file-input" type="file" accept="audio/mpeg,audio/mp3,audio/ogg,audio/wav,audio/webm" hidden>
        </div>
        <div class="wwdt-modal-actions">
          <button class="wwdt-action" type="button" data-action="cancel">Cancelar</button>
          <button class="wwdt-action wwdt-action-primary" type="button" data-action="ok">OK</button>
        </div>
      </section>`;

    backdrop.addEventListener("click", (event) => {
      if (event.target === backdrop) closeNotificationModal();
    });

    backdrop.querySelector("[data-action='cancel']").addEventListener("click", closeNotificationModal);
    backdrop.querySelector("[data-action='ok']").addEventListener("click", closeNotificationModal);
    backdrop.querySelector(".wwdt-add-sound").addEventListener("click", () => {
      backdrop.querySelector(".wwdt-file-input").click();
    });
    backdrop.querySelector(".wwdt-file-input").addEventListener("change", importCustomSound);

    document.body.appendChild(backdrop);
    renderSoundList();
  }

  function closeNotificationModal() {
    document.querySelector(".wwdt-modal-backdrop")?.remove();
    updateNotificationButton(false);
  }

  function importCustomSound(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("audio/")) return;

    const reader = new FileReader();
    reader.addEventListener("load", async () => {
      const customSound = {
        id: `custom_${Date.now()}`,
        name: file.name,
        url: String(reader.result || "")
      };
      settings.customSounds = [...settings.customSounds, customSound].slice(-8);
      settings.selectedSoundId = customSound.id;
      await saveSettings();
      renderSoundList();
      new Audio(customSound.url).play().catch(() => {});
    });
    reader.readAsDataURL(file);
  }

  function closeSelectionContextMenu(event) {
    if (event?.target instanceof Element && event.target.closest(`#${SELECTION_CONTEXT_MENU_ID}`)) return;
    document.getElementById(SELECTION_CONTEXT_MENU_ID)?.remove();
  }

  function selectedConversationText() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return "";

    const text = selection.toString();
    if (!text || !text.trim()) return "";

    const range = selection.getRangeAt(0);
    if (!isConversationSelection(range)) return "";

    return text;
  }

  function isEditableElement(node) {
    const element = node instanceof Element ? node : node?.parentElement;
    return Boolean(element?.closest("input, textarea, [contenteditable='true'], [contenteditable='plaintext-only']"));
  }

  function isConversationNode(node) {
    const element = node instanceof Element ? node : node?.parentElement;
    if (!element || isEditableElement(element)) return false;

    const conversationRoot = element.closest(
      [
        "#main",
        "[data-testid='conversation-panel-wrapper']",
        "[data-testid='conversation-panel-body']",
        "[role='application']"
      ].join(",")
    );

    if (!conversationRoot) return false;

    const sidebarRoot = element.closest("#side, #pane-side, [data-testid='chat-list']");
    return !sidebarRoot;
  }

  function isConversationSelection(range) {
    const container =
      range.commonAncestorContainer instanceof Element
        ? range.commonAncestorContainer
        : range.commonAncestorContainer.parentElement;

    return isConversationNode(container);
  }

  async function copyTextToClipboard(text) {
    if (!text) return false;

    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (_) {
      return fallbackCopyText(text);
    }
  }

  function fallbackCopyText(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.inset = "0 auto auto 0";
    textarea.style.width = "1px";
    textarea.style.height = "1px";
    textarea.style.opacity = "0";
    textarea.style.pointerEvents = "none";

    document.body.appendChild(textarea);
    textarea.select();
    textarea.setSelectionRange(0, textarea.value.length);

    let copied = false;
    try {
      copied = document.execCommand("copy");
    } catch (_) {
      copied = false;
    }

    textarea.remove();
    return copied;
  }

  function positionSelectionContextMenu(menu, x, y) {
    const margin = 8;
    const rect = menu.getBoundingClientRect();
    const left = Math.min(Math.max(margin, x), window.innerWidth - rect.width - margin);
    const top = Math.min(Math.max(margin, y), window.innerHeight - rect.height - margin);
    menu.style.left = `${left}px`;
    menu.style.top = `${top}px`;
  }

  function openSelectionContextMenu(event, text) {
    closeSelectionContextMenu();

    const menu = document.createElement("div");
    menu.id = SELECTION_CONTEXT_MENU_ID;
    menu.className = "wwdt-context-menu";
    menu.setAttribute("role", "menu");
    menu.setAttribute("aria-label", "Texto selecionado");

    const copyButton = document.createElement("button");
    copyButton.type = "button";
    copyButton.className = "wwdt-context-item";
    copyButton.setAttribute("role", "menuitem");
    copyButton.innerHTML = `${copyIcon}<span>Copiar</span>`;
    copyButton.addEventListener("click", async () => {
      await copyTextToClipboard(text);
      closeSelectionContextMenu();
    });

    menu.appendChild(copyButton);
    document.body.appendChild(menu);
    positionSelectionContextMenu(menu, event.clientX, event.clientY);
    copyButton.focus({ preventScroll: true });
  }

  function handleSelectionContextMenu(event) {
    if (!(event.target instanceof Node)) return false;
    if (event.target instanceof Element && event.target.closest(`#${SELECTION_CONTEXT_MENU_ID}`)) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return true;
    }
    if (!isConversationNode(event.target)) return false;

    const text = selectedConversationText();
    if (!text) return false;

    event.preventDefault();
    event.stopImmediatePropagation();
    openSelectionContextMenu(event, text);
    return true;
  }

  function blockChromiumShortcut(event) {
    const key = event.key.toLowerCase();

    if (event.key === "Escape") {
      closeSelectionContextMenu();
    }

    if (event.ctrlKey && event.shiftKey && key === "s") {
      event.preventDefault();
      event.stopImmediatePropagation();
      setSidebarCollapsed(!settings.sidebarCollapsed, true);
      return;
    }

    const ctrlBlocked = event.ctrlKey && ["l", "t", "n", "o", "p", "r", "s", "u"].includes(key);
    const ctrlShiftBlocked = event.ctrlKey && event.shiftKey && ["i", "j", "c", "delete"].includes(key);
    const functionBlocked = event.key === "F12" || event.key === "F5";
    const altNavBlocked = event.altKey && ["ArrowLeft", "ArrowRight", "Home"].includes(event.key);

    if (ctrlBlocked || ctrlShiftBlocked || functionBlocked || altNavBlocked) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }

  function suppressChromiumContextMenu(event) {
    if (event.target instanceof Element && event.target.closest(".wwdt-modal-backdrop")) return;
    if (handleSelectionContextMenu(event)) return;
    closeSelectionContextMenu();
    event.preventDefault();
  }

  function findExternalAnchor(target) {
    if (!(target instanceof Element)) return null;

    const anchor = target.closest("a[href]");
    if (!anchor || anchor.hasAttribute("download")) return null;

    let href = "";
    try {
      href = new URL(anchor.href, window.location.href).href;
    } catch (_) {
      return null;
    }

    if (!/^https?:/i.test(href)) return null;
    if (href.startsWith(`${window.location.origin}/`)) return null;

    return anchor;
  }

  function logExternalLink(event, data = {}) {
    chrome.runtime.sendMessage({ type: LOG_EXTERNAL_LINK, event, data }, () => {});
  }

  function openExternalLink(url, source) {
    logExternalLink("content-open-request", { source, url });
    chrome.runtime.sendMessage({ type: OPEN_EXTERNAL_LINK, url, source }, (response) => {
      if (chrome.runtime.lastError || !response?.ok) {
        const error = chrome.runtime.lastError?.message || response?.error || "unknown error";
        console.warn("WWDT: failed to open external link in Brave", error, response);
        logExternalLink("content-open-failed", { source, url, error, response });
        return;
      }
      logExternalLink("content-open-ok", { source, url, response });
    });
  }

  function handleExternalLinkClick(event) {
    if (event.defaultPrevented) return;
    if (event.button !== 0 && event.button !== 1) return;

    const anchor = findExternalAnchor(event.target);
    if (!anchor) return;

    event.preventDefault();
    event.stopImmediatePropagation();
    openExternalLink(anchor.href, `dom-${event.type}`);
  }

  function handleExternalLinkRequest(event) {
    const url = typeof event.detail === "string"
      ? event.detail
      : document.documentElement.getAttribute(EXTERNAL_LINK_URL_ATTR);
    if (typeof url !== "string" || !url) return;
    document.documentElement.removeAttribute(EXTERNAL_LINK_URL_ATTR);
    openExternalLink(url, "window-open");
  }

  function handleExternalLinkLog(event) {
    let detail = event.detail || {};
    if (!event.detail) {
      try {
        detail = JSON.parse(document.documentElement.getAttribute(EXTERNAL_LINK_LOG_ATTR) || "{}");
      } catch (_) {
        detail = {};
      }
      document.documentElement.removeAttribute(EXTERNAL_LINK_LOG_ATTR);
    }
    if (!detail.event) return;
    logExternalLink(detail.event || "page-log", detail);
  }

  function setExternalLinkBridgeReady(ready) {
    if (ready) {
      document.documentElement.setAttribute(EXTERNAL_LINK_BRIDGE_ATTR, "1");
    } else {
      document.documentElement.removeAttribute(EXTERNAL_LINK_BRIDGE_ATTR);
    }
  }

  function enableExternalLinkHandling() {
    if (!canHandleExternalLinks) {
      setExternalLinkBridgeReady(false);
      return;
    }

    setExternalLinkBridgeReady(true);
    document.addEventListener("click", handleExternalLinkClick, true);
    document.addEventListener("auxclick", handleExternalLinkClick, true);
    document.addEventListener(EXTERNAL_LINK_REQUEST_EVENT, handleExternalLinkRequest, true);
    document.addEventListener(EXTERNAL_LINK_LOG_EVENT, handleExternalLinkLog, true);
    window.addEventListener(EXTERNAL_LINK_REQUEST_EVENT, handleExternalLinkRequest, true);
    window.addEventListener(EXTERNAL_LINK_LOG_EVENT, handleExternalLinkLog, true);

    chrome.runtime.sendMessage({ type: PING_EXTERNAL_LINK_HOST }, (response) => {
      if (chrome.runtime.lastError || !response?.ok) {
        const error = chrome.runtime.lastError?.message || response?.error || "unknown error";
        console.warn("WWDT: external link bridge is not available", error, response);
        logExternalLink("content-ping-failed", { error, response });
        return;
      }
      logExternalLink("content-ping-ok", response);
    });
  }

  function escapeHtml(value) {
    const span = document.createElement("span");
    span.textContent = value;
    return span.innerHTML;
  }

  function scheduleRefresh() {
    if (mutationScheduled) return;
    mutationScheduled = true;
    requestAnimationFrame(() => {
      mutationScheduled = false;
      injectNavButtons();
      setSidebarCollapsed(settings.sidebarCollapsed);
      refreshUnreadNotificationState();
    });
  }

  if (!devtoolsMode) {
    document.addEventListener("keydown", blockChromiumShortcut, true);
    document.addEventListener("contextmenu", suppressChromiumContextMenu, true);
    document.addEventListener("click", closeSelectionContextMenu, true);
    document.addEventListener("scroll", closeSelectionContextMenu, true);
    window.addEventListener("resize", closeSelectionContextMenu, true);
    enableExternalLinkHandling();
  }

  const observer = new MutationObserver(scheduleRefresh);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.setInterval(refreshUnreadNotificationState, 500);

  loadSettings().then(() => {
    injectNavButtons();
    setSidebarCollapsed(settings.sidebarCollapsed);
    refreshUnreadNotificationState();
  });
})();
