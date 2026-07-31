-- ╔══════════════════════════════════╗
-- ║           MY PROGRAMS            ║
-- ╚══════════════════════════════════╝

-- Programas usados com atalhos
local terminal = "kitty"
local file_manager = "dolphin"
local menu = "pkill -x rofi || rofi -show drun"

-- ╔══════════════════════════════════╗
-- ║           KEYBINDINGS            ║
-- ╚══════════════════════════════════╝

-- Mod principal
local mod = "SUPER"

local function bind(keys, dispatcher, description, options)
    local opts = options or {}
    opts.description = description
    hl.bind(keys, dispatcher, opts)
end

-- ─────────────────────────────
--  Aplicativos principais
-- ─────────────────────────────
bind(mod .. " + Return", hl.dsp.exec_cmd(terminal), "Abrir terminal")
bind(mod .. " + E", hl.dsp.exec_cmd(file_manager), "Abrir gerenciador de arquivos")
bind(mod .. " + Space", hl.dsp.exec_cmd(menu), "Alternar menu de aplicativos")

-- ─────────────────────────────
--  Controle do Hyprland
-- ─────────────────────────────
bind(mod .. " + Q", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/whatsapp-close-or-hide.sh"), "Ocultar ou fechar WhatsApp")
bind(mod .. " + X", hl.dsp.exec_cmd("nwg-bar"), "Abrir menu de energia")
bind(mod .. " + F", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/toggle-fullscreen.sh"), "Alternar tela cheia preservando pin")
bind(mod .. " + P", hl.dsp.window.pseudo(), "Alternar pseudo-tiling")
bind(mod .. " + J", hl.dsp.layout("togglesplit"), "Alternar divisão do layout")

-- ─────────────────────────────
--  Janela flutuante personalizada
-- ─────────────────────────────
bind(mod .. " + ALT + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
    hl.dispatch(hl.dsp.window.center({}))
end, "Alternar janela flutuante centralizada")

-- ─────────────────────────────
--  Navegação entre janelas
-- ─────────────────────────────
local directions = {
    LEFT = "l",
    RIGHT = "r",
    UP = "u",
    DOWN = "d",
    H = "l",
    L = "r",
    K = "u",
    J = "d",
}

for key, direction in pairs(directions) do
    bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }), "Focar janela " .. direction)
end

-- ─────────────────────────────
--  Trocar posição das janelas
-- ─────────────────────────────
for key, direction in pairs({ H = "l", L = "r", K = "u", J = "d" }) do
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = direction }), "Trocar janela " .. direction)
end

-- ─────────────────────────────
--  Gerenciar janelas flutuantes
-- ─────────────────────────────
bind(mod .. " + SHIFT + F", hl.dsp.window.bring_to_top(), "Trazer janela ao topo")
bind(mod .. " + SHIFT + B", function()
    local moved = hl.dispatch(hl.dsp.focus({ direction = "l" }))
    if moved == false then
        hl.dispatch(hl.dsp.focus({ direction = "r" }))
    end
end, "Focar janela lateral")

bind(mod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, "Circular janelas flutuantes")

-- ─────────────────────────────
--  Mover janelas flutuantes
-- ─────────────────────────────
local move_steps = {
    H = { x = -50, y = 0 },
    L = { x = 50, y = 0 },
    K = { x = 0, y = -50 },
    J = { x = 0, y = 50 },
}

for key, step in pairs(move_steps) do
    bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({
        x = step.x,
        y = step.y,
        relative = true,
    }), "Mover janela", { repeating = true })
end

-- ─────────────────────────────
--  Redimensionar janelas
-- ─────────────────────────────
local resize_steps = {
    H = { x = -50, y = 0 },
    L = { x = 50, y = 0 },
    K = { x = 0, y = -50 },
    J = { x = 0, y = 50 },
}

for key, step in pairs(resize_steps) do
    bind(mod .. " + ALT + " .. key, hl.dsp.window.resize({
        x = step.x,
        y = step.y,
        relative = true,
    }), "Redimensionar janela", { repeating = true })
end

-- ─────────────────────────────
--  Promover janela para Master
-- ─────────────────────────────
bind(mod .. " + SHIFT + Return", hl.dsp.layout("swapwithmaster"), "Trocar com janela mestre")

-- ─────────────────────────────
--  Workspaces
-- ─────────────────────────────
for workspace = 1, 10 do
    local key = workspace == 10 and "0" or tostring(workspace)
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = tostring(workspace) }), "Abrir workspace " .. workspace)
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(workspace) }), "Mover para workspace " .. workspace)
end

bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"), "Alternar workspace especial")
bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Mover para workspace especial")
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Próximo workspace")
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Workspace anterior")

-- ─────────────────────────────
--  Mover/Redimensionar com mouse
-- ─────────────────────────────
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Mover janela com mouse", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Redimensionar janela com mouse", { mouse = true })

-- ─────────────────────────────
--  Multimídia
-- ─────────────────────────────
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Próxima faixa", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Reproduzir ou pausar", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Reproduzir ou pausar", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Faixa anterior", { locked = true })

-- ─────────────────────────────
--  Screenshots
-- ─────────────────────────────
bind(mod .. " + Print", hl.dsp.exec_cmd("$HOME/.local/bin/screenshot.sh full"), "Capturar tela")
bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.local/bin/screenshot.sh area"), "Capturar região")

-- ─────────────────────────────
--  Waybar
-- ─────────────────────────────
bind(mod .. " + M", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/waybar-mode-toggle.sh"), "Alternar modo da Waybar")
bind(mod .. " + Tab", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/toggle-waybar-gaps.sh"), "Alternar margens da Waybar")
bind(mod .. " + Escape", hl.dsp.exec_cmd("killall waybar && waybar"), "Reiniciar Waybar")

-- ─────────────────────────────
--  Extras
-- ─────────────────────────────
bind(mod .. " + F1", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/open-rtsp-stream.sh sticky"), "Abrir câmera RTSP fixa")
bind(mod .. " + SHIFT + F1", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/open-rtsp-stream.sh normal"), "Abrir câmera RTSP no workspace atual")
bind(mod .. " + A", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/move-rtsp-window.sh 12 840"), "Mover câmera RTSP à esquerda")
bind(mod .. " + D", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/move-rtsp-window.sh 1505 835"), "Mover câmera RTSP à direita")
bind(mod .. " + W", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/hyprpaper_change.sh"), "Trocar papel de parede")
bind(mod .. " + CTRL + SHIFT + L", hl.dsp.exec_cmd("hyprlock"), "Bloquear sessão")
bind(mod .. " + N", hl.dsp.exec_cmd("sleep 0.1 && swaync-client -t -sw"), "Alternar notificações")
bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("pkill swaync && sleep 0.2 && swaync"), "Reiniciar notificações")
bind(mod .. " + V", hl.dsp.exec_cmd("copyq toggle"), "Alternar CopyQ")
bind(mod .. " + period", hl.dsp.exec_cmd("rofi -modi emoji -show emoji -emoji-format '{emoji}' -theme $HOME/.config/rofi/launchers/emoji.rasi"), "Abrir seletor de emoji")
bind(mod .. " + C", hl.dsp.exec_cmd("galendae -c $HOME/.config/galendae/galendae.conf"), "Abrir calendário")
