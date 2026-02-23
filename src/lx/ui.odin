package lx

State :: struct {
    active_id, hover_id : u32,
    // the debug_label attached to elements
    // not really needed but just used it to see
    // how the hover_id was
    _debug            : string,
    mouse_pos         : Vec2,
    mouse_down        : bool,
}

point_in_rect :: proc(rect: Rect, point: Vec2) -> bool {
    return point.x >= rect.x && point.x <= rect.x + rect.w &&
           point.y >= rect.y && point.y <= rect.y + rect.h
}
