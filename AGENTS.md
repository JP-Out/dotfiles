# Automação do Repositório de Dotfiles no Arch Linux

Quero automatizar o meu repositório de dotfiles no Arch Linux para instalar de forma autônoma e configurar todos os arquivos dentro dele.  

A automação deve abranger desde a instalação de utilitários como **CopyQ**, **Fastfetch** e **Galendae** até configurações mais complexas envolvendo **Hyprland**, **Waybar**, **Rofi** e **Zsh**, incluindo a indicação de pacotes opcionais (por exemplo, *fonts Nerd*, *Papirus icons*, etc.).

---

## 📌 Informações Essenciais

- **OS:** 󰣇 Arch Linux rolling [x86_64]  
- **Kernel:** 6.15.9-arch1-1  
- **WM:** Hyprland (Ver.: 0.50.1)  
- **Shell:** zsh (Ver.: 5.9)  
- **GTK/QT:** Breeze-Dark  
- **Fonte:** JetBrainsMono Nerd Font  
- **Icons:** Papirus-Dark  
- **Terminal:** kitty (Ver.: 0.42.2)  
- **CPU:** AMD Ryzen 5 3600  
- **GPU:** AMD Radeon RX 5700 XT  

---

## ⚙️ Como Funciona

- Eu irei fornecer os **arquivos específicos** e um **prompt**.  
- Com base nisso, você criará um **script** para automatizar a instalação e configuração de determinado programa/ferramenta.  
- Depois, **todos esses scripts** serão chamados em um **script principal** que executará a instalação completa.  

**Todos os scripts devem ser:**
- **Modulares**
- **Robustos**
- Fáceis de operar e manter

---

## 📜 Regras

- Todas as dependências devem ser adicionadas dentro do arquivo:  
  ```
  install/00-deps.sh
  ```

- Faça o script sabendo que ele será incorporado futuramente em um script principal.

---

## 📂 Estrutura em Árvore Completa

```ascii
/home/shaka/.dotfiles
├── config
│   ├── assets-dotfiles
│   │   ├── avatar.png
│   │   ├── avatar-rounded.png
│   │   ├── Regulamento-do-TCC.pdf
│   │   └── vegapunk-robot-rounded.png
│   ├── bluetooth
│   │   └── conectar_bluetooth.sh
│   ├── copyq
│   │   ├── copyq.conf
│   │   └── themes
│   │       └── system_theme.ini
│   ├── fastfetch
│   │   ├── config.jsonc
│   │   └── logo
│   │       ├── arch-logo.txt
│   │       └── desktop-computer.txt
│   ├── galendae
│   │   └── galendae.conf
│   ├── grim
│   │   └── screenshot.sh
│   ├── hypr
│   │   ├── hyprland.conf
│   │   ├── hyprlock.conf
│   │   ├── hyprpaper.conf
│   │   └── scripts
│   │       ├── hyprpaper_change.sh
│   │       ├── toggle-waybar-gaps.sh
│   │       ├── waybar-hover-daemon.sh
│   │       └── waybar-mode-toggle.sh
│   ├── kdeglobals
│   ├── kitty
│   │   ├── current-theme.conf
│   │   ├── kitty.conf
│   │   └── kitty.conf.bak
│   ├── nvim
│   │   ├── airline.vim
│   │   ├── ale.vim
│   │   ├── coc.vim
│   │   ├── init.vim
│   │   ├── plugins.vim
│   │   ├── remaps.vim
│   │   ├── settings.vim
│   │   └── themes.vim
│   ├── nwg-bar
│   │   ├── bar.json
│   │   ├── icons
│   │   │   ├── system-hibernate.svg
│   │   │   ├── system-lock-screen.svg
│   │   │   ├── system-log-out.svg
│   │   │   ├── system-reboot.svg
│   │   │   ├── system-shutdown.svg
│   │   │   └── system-suspend.svg
│   │   └── style.css
│   ├── rofi
│   │   ├── config.rasi
│   │   ├── launchers
│   │   │   ├── emoji.rasi
│   │   │   └── menu_1.rasi
│   │   └── themes
│   │       ├── font.rasi
│   │       └── onedark.rasi
│   ├── swaync
│   │   ├── buttons-grid
│   │   ├── config.json
│   │   ├── style.css
│   │   └── test
│   │       └── swaync-test.sh
│   ├── systemd
│   │   └── user
│   │       ├── bluetooth-autoconnect.service
│   │       ├── default.target.wants
│   │       ├── graphical-session.target.wants
│   │       ├── hyprpaper-change.service
│   │       ├── hyprpaper-change.timer
│   │       └── timers.target.wants
│   └── waybar
│       ├── config.jsonc
│       ├── scripts
│       │   ├── clock_ptbr_json.sh
│       │   ├── custom_uptime.sh
│       │   ├── gpu_usage.sh
│       │   ├── music.sh
│       │   ├── network_usage.sh
│       │   ├── separator_tray.sh
│       │   ├── spotify_volume.sh
│       │   ├── toggle-output.sh
│       │   └── volume.sh
│       └── style.css
├── install
│   └── install_galendae_ptbr.sh
└── zsh
    ├── zprofile
    ├── zshenv
    └── zshrc

30 directories, 66 files
```
