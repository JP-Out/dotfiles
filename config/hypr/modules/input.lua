-- ╔══════════════════════════════════╗
-- ║              INPUT               ║
-- ╚══════════════════════════════════╝

hl.config({
    -- ─────────────────────────────
    --  Teclado, mouse e touchpad
    -- ─────────────────────────────
    -- https://wiki.hypr.land/Configuring/Variables/#input
    input = {
        kb_layout = "br",
        kb_variant = "abnt2",
        kb_options = "kpdl:dot",
        numlock_by_default = true,
        follow_mouse = 1,
        accel_profile = "adaptive",
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },

    -- ─────────────────────────────
    --  Gestos do touchpad
    -- ─────────────────────────────
    gestures = {
        workspace_swipe_touch = false,
    },
})

-- ─────────────────────────────
--  Configuração por dispositivo
-- ─────────────────────────────
-- https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs
hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})
