package lx

Widget_State :: struct {
    rect : Rect,
}

UI_State :: struct {
    widgets        : map[u32]Widget_State,
    mouse_pos      : Vec2,
    mouse_down     : bool,
    hot_id         : u32,
    active_id      : u32,
}

DEF_FONT_SIZE :: 25
DEF_TEXT_COLOR :: Color{ 255, 255, 255, 255 }

point_in_rect :: proc(rect: Rect, point: Vec2) -> bool {
    return point.x >= rect.x && point.x <= rect.x + rect.w &&
           point.y >= rect.y && point.y <= rect.y + rect.h
}


// call after layout() to store rects for next frame's hit testing
ui_cache :: proc(ui: ^UI_State, root: ^Container) {
    ui.widgets[root.id] = Widget_State{ rect = root.rect }

    for &node in root.elements {
        switch &c in node {
        case Container:
            ui_cache(ui, &c)
        case Text:
        }
    }
}
