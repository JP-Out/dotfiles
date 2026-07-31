hl.window_rule({
    name = "whatsapp-special-workspace",
    match = { class = "^chrome-web\\.whatsapp\\.com__-Default$" },
    workspace = "special:whatsapp silent",
})

hl.window_rule({
    name = "suppress-client-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "lxsudo-dialog",
    match = { class = "^lxqt-sudo$" },
    float = true,
    center = true,
    size = "728 295",
})

hl.window_rule({
    name = "copyq-window",
    match = { class = "^com\\.github\\.hluk\\.copyq$" },
    float = true,
    move = "1520 540",
    size = "340 500",
})

hl.window_rule({
    name = "galendae-window",
    match = { class = "^galendae$" },
    float = true,
    pin = true,
    move = "1608 60",
    animation = "slide top",
})

hl.window_rule({
    name = "network-popup",
    match = { class = "^nmtui-popup$" },
    float = true,
    center = true,
    size = "450 380",
})

hl.window_rule({
    name = "bluetooth-popup",
    match = { class = "^bluetooth-popup$" },
    float = true,
    center = true,
    size = "650 480",
})

hl.window_rule({
    name = "kdenlive-no-fullscreen",
    match = { class = "^org\\.kde\\.kdenlive$" },
    suppress_event = "fullscreen maximize",
    fullscreen = false,
})

hl.window_rule({
    name = "kdenlive-project-window",
    match = { class = "^org\\.kde\\.kdenlive$", title = ".*— Kdenlive$" },
    float = false,
    center = false,
})

hl.window_rule({
    name = "kdenlive-start-window",
    match = { class = "^org\\.kde\\.kdenlive$", title = "^Kdenlive$" },
    float = true,
    center = true,
    size = "610 575",
})
