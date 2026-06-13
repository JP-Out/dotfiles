(function () {
  "use strict";

  const STORAGE_KEY = "wwdt.settings";
  const SETTINGS_EVENT = "wwdt:settings";
  const STORAGE_SOUND_URL = "wwdt.notificationSoundUrl";
  const SIDEBAR_BUTTON_ID = "wwdt-sidebar-toggle";
  const NOTIFICATION_BUTTON_ID = "wwdt-notification-button";

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
    selectedSoundId: "whatsapp_2",
    customSounds: []
  };

  let settings = { ...DEFAULT_SETTINGS };
  let mutationScheduled = false;
  let sidebarTarget = null;

  const collapsedIcon = `
    <svg viewBox="0 0 423 423" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <rect x="43.25" y="42.25" width="96" height="338" rx="18" fill="currentColor" opacity="0.78"/>
      <path d="M60.1667 405.5H146.5M60.1667 405.5H362.333C386.174 405.5 405.5 386.174 405.5 362.333V60.1667C405.5 36.3264 386.174 17 362.333 17H60.1667M60.1667 405.5C36.3264 405.5 17 386.174 17 362.333V60.1667C17 36.3264 36.3264 17 60.1667 17M60.1667 17H146.5" stroke="currentColor" stroke-width="34" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M161.25 405.75V211.5V17.25" stroke="currentColor" stroke-width="26" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`;

  const expandedIcon = `
    <svg viewBox="0 0 423 423" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path d="M60.1667 405.5H146.5M60.1667 405.5H362.333C386.174 405.5 405.5 386.174 405.5 362.333V60.1667C405.5 36.3264 386.174 17 362.333 17H60.1667M60.1667 405.5C36.3264 405.5 17 386.174 17 362.333V60.1667C17 36.3264 36.3264 17 60.1667 17M60.1667 17H146.5" stroke="currentColor" stroke-width="34" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M161.25 405.75V211.5V17.25" stroke="currentColor" stroke-width="26" stroke-linecap="round" stroke-linejoin="round"/>
      <rect x="43.25" y="42" width="96" height="339" rx="18" fill="currentColor" opacity="0.14"/>
      <rect x="183" y="42" width="197" height="339" rx="18" fill="currentColor" opacity="0.14"/>
    </svg>`;

  const bellIcon = `
    <svg viewBox="0 0 274 343" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path d="M17.125 291.125C12.273 291.125 8.20578 289.484 4.92344 286.202C1.64109 282.919 0 278.852 0 274C0 269.148 1.64109 265.081 4.92344 261.798C8.20578 258.516 12.273 256.875 17.125 256.875H34.25V137C34.25 113.31 41.3855 92.2609 55.6562 73.8516C69.927 55.4422 88.4792 43.3833 111.312 37.675V25.6875C111.312 18.552 113.809 12.487 118.805 7.49219C123.8 2.49734 129.864 0 137 0C144.136 0 150.2 2.49734 155.195 7.49219C160.191 12.487 162.688 18.552 162.688 25.6875V37.675C185.52 43.3833 204.073 55.4422 218.344 73.8516C232.614 92.2609 239.75 113.31 239.75 137V256.875H256.875C261.727 256.875 265.794 258.516 269.077 261.798C272.359 265.081 274 269.148 274 274C274 278.852 272.359 282.919 269.077 286.202C265.794 289.484 261.727 291.125 256.875 291.125H17.125ZM137 342.5C127.581 342.5 119.519 339.147 112.811 332.439C106.103 325.731 102.75 317.669 102.75 308.25H171.25C171.25 317.669 167.897 325.731 161.189 332.439C154.481 339.147 146.419 342.5 137 342.5ZM68.5 256.875H205.5V137C205.5 118.162 198.792 102.036 185.378 88.6219C171.964 75.2074 155.838 68.5 137 68.5C118.162 68.5 102.036 75.2074 88.6219 88.6219C75.2074 102.036 68.5 118.162 68.5 137V256.875Z" fill="currentColor"/>
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
    syncPageHook();
    setSidebarCollapsed(settings.sidebarCollapsed);
  }

  async function saveSettings() {
    await chromeStorageSet({ [STORAGE_KEY]: settings });
    syncPageHook();
  }

  function allSounds() {
    return [...BUILTIN_SOUNDS, ...settings.customSounds];
  }

  function selectedSound() {
    return allSounds().find((sound) => sound.id === settings.selectedSoundId) || BUILTIN_SOUNDS[1];
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

  function createNavButton(id, label, html, onClick) {
    const shell = document.createElement("span");
    shell.className = "wwdt-nav-shell";

    const button = document.createElement("button");
    button.id = id;
    button.type = "button";
    button.className = "wwdt-nav-button";
    button.setAttribute("aria-label", label);
    button.innerHTML = html;
    button.addEventListener("click", onClick);

    shell.appendChild(button);
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
      return;
    }

    const insertPoint = findInsertPoint();
    if (!insertPoint || !insertPoint.parentElement) return;

    if (!document.getElementById(SIDEBAR_BUTTON_ID)) {
      const sidebarButton = createNavButton(
        SIDEBAR_BUTTON_ID,
        settings.sidebarCollapsed ? "Mostrar lista de conversas" : "Ocultar lista de conversas",
        settings.sidebarCollapsed ? expandedIcon : collapsedIcon,
        () => setSidebarCollapsed(!settings.sidebarCollapsed, true)
      );
      insertPoint.parentElement.insertBefore(sidebarButton, insertPoint);
    }

    if (!document.getElementById(NOTIFICATION_BUTTON_ID)) {
      const notificationButton = createNavButton(
        NOTIFICATION_BUTTON_ID,
        "Som de notificação",
        bellIcon,
        openNotificationModal
      );
      insertPoint.parentElement.insertBefore(notificationButton, insertPoint);
    }
  }

  function findSidebarTarget() {
    const direct = document.querySelector("#side");
    if (direct) return direct;

    const chatList = document.querySelector(
      [
        "#pane-side",
        "[data-testid='chat-list']",
        "[aria-label='Lista de conversas']",
        "[aria-label='Chat list']"
      ].join(",")
    );

    if (!chatList) return null;

    let candidate = chatList;
    let node = chatList.parentElement;
    while (node && node !== document.body) {
      const rect = node.getBoundingClientRect();
      if (rect.height > window.innerHeight * 0.65 && rect.width > 220 && rect.width < window.innerWidth * 0.55) {
        candidate = node;
      }
      node = node.parentElement;
    }

    return candidate;
  }

  function setSidebarCollapsed(collapsed, persist = false) {
    settings.sidebarCollapsed = Boolean(collapsed);
    sidebarTarget = findSidebarTarget() || sidebarTarget;

    if (sidebarTarget) {
      sidebarTarget.classList.toggle("wwdt-chat-pane-collapsed", settings.sidebarCollapsed);
    }

    updateSidebarButton();
    if (persist) saveSettings();
  }

  function updateSidebarButton() {
    const button = document.getElementById(SIDEBAR_BUTTON_ID);
    if (!button) return;
    button.setAttribute("aria-pressed", String(settings.sidebarCollapsed));
    button.setAttribute("aria-label", settings.sidebarCollapsed ? "Mostrar lista de conversas" : "Ocultar lista de conversas");
    button.innerHTML = settings.sidebarCollapsed ? expandedIcon : collapsedIcon;
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

  function blockChromiumShortcut(event) {
    const key = event.key.toLowerCase();

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
    event.preventDefault();
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
    });
  }

  document.addEventListener("keydown", blockChromiumShortcut, true);
  document.addEventListener("contextmenu", suppressChromiumContextMenu, true);

  const observer = new MutationObserver(scheduleRefresh);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  loadSettings().then(() => {
    injectNavButtons();
    setSidebarCollapsed(settings.sidebarCollapsed);
  });
})();
