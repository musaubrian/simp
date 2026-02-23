package lx_old

import "core:fmt"

button :: proc(
    parent     : ^Container,
    label      : string,
    width      : f32,
    height     : f32,
    ui         : ^UI_State,
    font_size  : f32   = DEF_FONT_SIZE,
    text_color : Color = DEF_TEXT_COLOR,
    style      := Style{},
) -> bool {
    str_label := fmt.tprintf("%s", label[0])
    id := make_id(str_label)
    btn := Container{
        id        = id,
        width     = width,
        height    = height,
        direction = .Row,
        style     = style,
    }
    verify_container(btn)

    txt := text(label, font_size, text_color)
    add_elements(&btn, txt)
    add_elements(parent, btn)

    clicked := false
    if ui == nil { return clicked }
    prev, has_prev := ui.widgets[id]
    if has_prev {
        hovered := point_in_rect(prev.rect, ui.mouse_pos)

        if hovered {
            ui.hot_id = id
        }

        if hovered && ui.mouse_down && ui.active_id == 0 {
            ui.active_id = id
        }

        if !ui.mouse_down && ui.active_id == id {
            if hovered { clicked = true }
            ui.active_id = 0
        }
    }

    return clicked
}
