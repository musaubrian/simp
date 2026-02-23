package lx

Button_Style :: struct {
    bg     : Color,
    round : f32,
}

button :: proc(parent: ^Box, label: string, w, h: f32, ctx: ^Context, style : Button_Style = {}) -> bool {
    button_style_with_defaults := Style{
        align    = .Center,
        justify  = .Center,
        bg       = style.bg,
        hover_bg = { style.bg.r, style.bg.g, style.bg.b, style.bg.a / 2 },
        round    = style.round if style.round > 0 else 5,
    }
    base := box(label, w, h, parent = parent, style = button_style_with_defaults)
    txt := text(label)
    add_elements(base, txt)
    add_elements(parent, base)

    hovered := ctx.state.hover_id == base.id
    if hovered && ctx.state.mouse_down { ctx.state.active_id = base.id }

    // Clear active if released outside
    if ctx.state.active_id == base.id && !ctx.state.mouse_down && !hovered {
        ctx.state.active_id = 0
    }

    clicked := ctx.state.active_id == base.id && hovered && !ctx.state.mouse_down
    if clicked { ctx.state.active_id = 0 }

    return clicked
}
