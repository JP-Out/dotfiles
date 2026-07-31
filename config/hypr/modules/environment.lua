local home = assert(os.getenv("HOME"), "HOME precisa estar definida para carregar os dotfiles")

hl.monitor({
    output = "DP-2",
    mode = "1920x1080@165",
    position = "0x0",
    scale = 1,
})

local environment = {
    PATH = table.concat({
        home .. "/bin",
        home .. "/.local/bin",
        "/usr/local/sbin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
    }, ":"),
    TERMINAL = "kitty",
    LANG = "pt_BR.UTF-8",
    LC_TIME = "pt_BR.UTF-8",
    LC_ALL = "pt_BR.UTF-8",
    XDG_MENU_PREFIX = "arch-",
    XCURSOR_THEME = "BreezeX-RosePine-Linux",
    XCURSOR_SIZE = "32",
    HYPRCURSOR_THEME = "rose-pine-hyprcursor",
    HYPRCURSOR_SIZE = "32",
    XCURSOR_PATH = table.concat({
        home .. "/.local/share/icons",
        home .. "/.icons",
        "/usr/share/icons",
    }, ":"),
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    XDG_SESSION_DESKTOP = "Hyprland",
    GDK_BACKEND = "wayland,x11,*",
    QT_QPA_PLATFORM = "wayland;xcb",
    QT_QPA_PLATFORMTHEME = "qt6ct",
    QT_AUTO_SCREEN_SCALE_FACTOR = "1",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
}

for name, value in pairs(environment) do
    hl.env(name, value)
end
