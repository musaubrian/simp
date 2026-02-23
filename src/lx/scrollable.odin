package lx

scroll_area :: proc(label: string, w, h: f32, direction: Direction = .Col, style := Style{}, allocator := context.allocator) -> ^Box {
    b := box(label, w, h, direction, style = style, allocator = allocator)
    b.scroll.enabled = true
    return b
}
