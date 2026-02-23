#+feature dynamic-literals
package lx

import "core:hash"
import "core:fmt"
import "core:os"
import "core:strings"

Direction :: enum { Row, Col }
Alignment :: enum { Start, Center, End }

Element   :: union { ^Box, ^Text }

Box  :: struct {
    parent      : ^Box,
    id          : u32,
    debug_label : string,
    w, h        : f32,
    direction   : Direction,
    elements    : [dynamic]Element,
    bounds      : Rect,
    state       : InteractionState,
    style       : Style,
}

Text :: struct {
    content     : string,
    size        : f32,
    color       : Color,
    pos, bounds : Vec2,
}

InteractionState :: struct {
    active  : bool,
    clicked : bool,
}

Style :: struct {
    padding : int,
    gap     : int,
    round   : f32,
    bg      : Color,
    justify : Alignment,
    align   : Alignment,
}

Context :: struct {
    font         : any,
    measure_text : proc(t: ^Text, ctx: ^Context) -> Vec2,
}

Rect  :: struct { x, y, w, h: f32 }
Vec2  :: distinct [2]f32
Color :: distinct [4]u8

// Defaults
_Text_Size  : f32 : 25.0
_Text_Color :: Color{ 255, 255, 255, 255 }

make_id :: proc(label: string) -> u32 { return hash.fnv32a(transmute([]u8)label) }

box :: proc(label: string, w, h : f32, direction: Direction = .Row, parent : ^Box = nil, style := Style{}, allocator := context.allocator) -> ^Box {
    b := new(Box)
    b^ = {
        id          = make_id(label),
        debug_label = label,
        parent      = parent,
        direction   = direction,
        w           = w,
        h           = h,
        bounds      = {},
        elements    = nil,
        state       = {},
        style       = style,
    }

    check_box_sizing(b)

    return b
}

text :: proc(content: string, size := _Text_Size, color := _Text_Color, allocator := context.allocator) -> ^Text {
    t := new(Text)
    t^ = { content = content, size = size, color = color }

    return t
}

check_box_sizing :: proc(box: ^Box) {
    if box.w != -1 && (box.w < 0 || box.w > 1) {
        fatal(fmt.tprintf("ERROR: (Box '%s'): Width should be -1 or 0..1, got %f", box.debug_label, box.w))
    }

    if box.h != -1 && (box.h < 0 || box.h > 1) {
        fatal(fmt.tprintf("ERROR: (Box '%s'): Height should be -1 or 0..1, got %f", box.debug_label, box.h))
    }
}

add_elements :: proc(parent: ^Box, elements: ..Element) {
    total : f32 = 0.0
    for el in parent.elements {
        switch n in el {
        case ^Box:
            sz := n.w if parent.direction == .Row else n.h
            if sz >= 0 { total += sz }
        case ^Text:
        }
    }

    for el in elements {
        switch n in el {
        case ^Box:
            n.parent = parent
            sz := n.w if parent.direction == .Row else n.h
            if sz >= 0 {
                total += sz
                if total > 1.0 {
                    fatal(fmt.tprintf("ERROR: LX: (Box '%s'): children exceed 1.0, got %.2f, '%s' pushed it over by '%.2f'", n.parent.debug_label, total, n.debug_label, (total - 1.0)))
                }
            }
        case ^Text:
        }

        append(&parent.elements, el)
    }
}

cross_align_offset :: proc(align: Alignment, avail_cross, child_cross: f32) -> f32 {
    switch align {
    case .Start:  return 0
    case .Center: return (avail_cross - child_cross) / 2
    case .End:    return avail_cross - child_cross
    }
    return 0
}

// Implementation "repurposed" from clay
//  https://github.com/nicbarker/clay
layout :: proc(b: ^Box, parent_rect: Rect, ctx: ^Context) {
    b.bounds = parent_rect

    if b.style.round > 0 {
        smaller := min(parent_rect.w, parent_rect.h)
        b.style.round = b.style.round / smaller if smaller > 0 else 0
    }

    pad := f32(b.style.padding)
    content_x   := parent_rect.x + pad
    content_y   := parent_rect.y + pad
    available_w := parent_rect.w - pad * 2
    available_h := parent_rect.h - pad * 2

    is_row := b.direction == .Row
    total_gap := f32(b.style.gap * (len(b.elements) - 1))
    if is_row { available_w -= total_gap } else { available_h -= total_gap }

    avail_main  := available_w if is_row else available_h
    avail_cross := available_h if is_row else available_w

    // First pass: compute sizes for fixed children, count growers
    used_main : f32 = 0
    grow_count : int = 0
    for &element in b.elements {
        switch el in element {
        case ^Box:
            main_frac  := el.w if is_row else el.h
            cross_frac := el.h if is_row else el.w

            if main_frac == -1 {
                grow_count += 1
            } else {
                if is_row { el.bounds.w = main_frac * available_w } else { el.bounds.h = main_frac * available_h }
                used_main += el.bounds.w if is_row else el.bounds.h
            }

            if cross_frac == -1 {
                if is_row { el.bounds.h = available_h } else { el.bounds.w = available_w }
            } else {
                if is_row { el.bounds.h = cross_frac * available_h } else { el.bounds.w = cross_frac * available_w }
            }
        case ^Text:
            if ctx != nil && ctx.measure_text != nil {
                el.bounds = ctx.measure_text(el, ctx)
            } else {
                el.bounds = { el.size, el.size }
            }
            used_main += el.bounds.x if is_row else el.bounds.y
        }
    }

    // Distribute remaining space to grow children
    if grow_count > 0 {
        remaining := max(avail_main - used_main, 0) / f32(grow_count)
        for &element in b.elements {
            switch el in element {
            case ^Box:
                main_frac := el.w if is_row else el.h
                if main_frac == -1 {
                    if is_row { el.bounds.w = remaining } else { el.bounds.h = remaining }
                }
            case ^Text:
            }
        }
    }

    // Justify: offset on main axis (no leftover when growers consumed it)
    main_space := f32(0) if grow_count > 0 else max(avail_main - used_main, 0)
    main_offset : f32 = 0
    switch b.style.justify {
    case .Start:  main_offset = 0
    case .Center: main_offset = main_space / 2
    case .End:    main_offset = main_space
    }

    cursor_main  := (content_x if is_row else content_y) + main_offset
    cursor_cross := content_y if is_row else content_x

    // Second pass: position children
    for &element, index in b.elements {
        child_main_size, child_cross_size : f32

        switch el in element {
        case ^Box:
            child_main_size  = el.bounds.w if is_row else el.bounds.h
            child_cross_size = el.bounds.h if is_row else el.bounds.w

            co := cross_align_offset(b.style.align, avail_cross, child_cross_size)
            if is_row {
                el.bounds.x = cursor_main
                el.bounds.y = cursor_cross + co
            } else {
                el.bounds.x = cursor_cross + co
                el.bounds.y = cursor_main
            }
            layout(el, el.bounds, ctx)
        case ^Text:
            child_main_size  = el.bounds.x if is_row else el.bounds.y
            child_cross_size = el.bounds.y if is_row else el.bounds.x

            co := cross_align_offset(b.style.align, avail_cross, child_cross_size)
            if is_row {
                el.pos = { cursor_main, cursor_cross + co }
            } else {
                el.pos = { cursor_cross + co, cursor_main }
            }
        }

        gap : f32 = 0
        if index != len(b.elements) - 1 { gap = f32(b.style.gap) }
        cursor_main += child_main_size + gap
    }
}

render :: proc(b: ^Box, ctx: ^Context, draw_fn: proc(element: ^Element, ctx: ^Context)) {
    root_element := Element(b)
    draw_fn(&root_element, ctx)

    for &element in b.elements {
        switch el in element {
        case ^Box:
            render(el, ctx, draw_fn)
        case ^Text:
            draw_fn(&element, ctx)
        }
    }
}

print_heirarchy :: proc(root: ^Box) {
    sb := strings.builder_make()
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root_element := Element(root)
    walk_tree(&root_element, &sb)
    fmt.println(strings.to_string(sb))
}

walk_tree :: proc(element: ^Element, sb: ^strings.Builder, depth := 0) {
    strings.write_string(sb, write_element(element, depth))
    switch &elem in element {
    case ^Box:
        for &child_elem in elem.elements {
            walk_tree(&child_elem, sb, depth + 1)
        }
    case ^Text: // always a leaf node
    }
}

write_element :: proc(element: ^Element, depth := 0) -> string {
    string_el := ""
    switch el in element {
    case ^Box:
        string_el = fmt.aprintfln(
            "%*s Box(label=%s, direction=%v, width=%f, height=%f)",
            depth * 2, "",
            el.debug_label, el.direction, el.w, el.h,
        )
    case ^Text:
        string_el = fmt.aprintfln(
            "%*s Text(size=%f, color=%v, pos=%v, content=%s)",
            depth * 2, "",
            el.size, el.color, el.pos, el.content,
        )
    }

    return string_el
}

fatal :: proc(message: string) {
    fmt.eprintln(message)
    os.exit(1)
}
