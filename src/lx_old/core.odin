#+feature dynamic-literals
package lx_old

import "core:fmt"
import "core:hash"
import "core:os"
import "core:strings"

Direction :: enum  { Row, Col }
Alignment :: enum  { Start, Center, End }
Node      :: union { Container, Text }

Container :: struct {
    id          : u32,
    width       : f32,
    height      : f32,
    direction   : Direction,
    elements    : [dynamic]Node,
    rect        : Rect,
    style       : Style,
}

Text :: struct {
    content  : string,
    size     : f32,
    color    : Color,
    pos      : Vec2,
    bounds   : Vec2,
}

Context :: struct {
    font            : any,
    measure_text_fn : proc(t: ^Text, ctx: ^Context) -> Vec2,
    ui_state        : UI_State,
}

Style :: struct {
    round     : f32,
    gap       : int,
    padding   : int,
    bg        : Color,
    hover_bg  : Color,
    justify   : Alignment,
    align     : Alignment,
}

Rect  :: struct { x, y, w, h: f32 }
Vec2  :: distinct [2]f32
Color :: distinct [4]u8

make_id :: proc(label: string) -> u32 {
    return hash.fnv32a(transmute([]u8)label)
}

container :: proc(label: string, width: f32, height: f32, direction: Direction = .Row, style := Style{}) -> Container {
    c := Container{
        id        = make_id(label),
        direction = direction,
        width     = width,
        height    = height,
        rect      = {},
        elements  = {},
        style     = style,
    }
    verify_container(c)
    return c
}

text :: proc(content: string, size: f32 = DEF_FONT_SIZE, color: Color = DEF_TEXT_COLOR) -> Text {
    return Text{
        content = content,
        size    = size,
        color   = color,
    }
}

verify_container :: proc(container: Container) {
    if container.width < 0 || container.width > 1 {
        fatal(fmt.aprintf("ERROR: LX: (Container '%s'): Width range should be 0..1, got %f", container.id, container.width))
    }

    if container.height < 0 || container.height > 1 {
        fatal(fmt.aprintf("ERROR: LX: (Container '%s'): Height range should be 0..1, got %f", container.id, container.height))
    }
}

add_elements :: proc(parent: ^Container, elements: ..Node) {
    // NOTE:: text doesn't participate in layout sizing
    total : f32 = 0
    for el in parent.elements {
        switch c in el {
        case Container: total += c.width if parent.direction == .Row else c.height
        case Text:
        }
    }
    for el in elements {
        switch c in el {
        case Container:
            total += c.width if parent.direction == .Row else c.height
            if total > 1.0 {
                fatal(fmt.aprintf("ERROR: LX: (Container '%s'): children exceed 1.0, got %f, '%s' pushed it over", parent.id, total, c.id))
            }
        case Text:
        }
        append(&parent.elements, el)
    }
}

layout :: proc(container: ^Container, parent_rect: Rect, ctx: ^Context) {
    container.rect = parent_rect

    // calculate the appropriate rounded ratio
    if container.style.round > 0 {
        smaller := min(parent_rect.w, parent_rect.h)
        container.style.round = container.style.round / smaller if smaller > 0 else 0
    }

    pad := f32(container.style.padding)
    content_x   := parent_rect.x + pad
    content_y   := parent_rect.y + pad
    available_w := parent_rect.w - pad * 2
    available_h := parent_rect.h - pad * 2

    total_gap := f32(container.style.gap * (len(container.elements) - 1))

    switch container.direction {
    case .Row: available_w -= total_gap
    case .Col: available_h -= total_gap
    }

    // first pass: compute sizes and total used on main axis
    used_main : f32 = 0
    for &node in container.elements {
        switch &cont in node {
        case Container:
            cont.rect.w = cont.width * available_w
            cont.rect.h = cont.height * available_h
            switch container.direction {
            case .Row: used_main += cont.rect.w
            case .Col: used_main += cont.rect.h
            }
        case Text:
            if ctx != nil && ctx.measure_text_fn != nil {
                cont.bounds = ctx.measure_text_fn(&cont, ctx)
            } else {
                cont.bounds = { cont.size, cont.size }
            }
            switch container.direction {
            case .Row: used_main += cont.bounds[0]
            case .Col: used_main += cont.bounds[1]
            }
        }
    }

    // justify: offset on main axis
    main_space : f32 = 0
    switch container.direction {
    case .Row: main_space = available_w - used_main
    case .Col: main_space = available_h - used_main
    }
    if main_space < 0 { main_space = 0 }

    main_offset : f32 = 0
    switch container.style.justify {
    case .Start:  main_offset = 0
    case .Center: main_offset = main_space / 2
    case .End:    main_offset = main_space
    }

    cursor : struct{ x, y: f32 }
    switch container.direction {
    case .Row: cursor = { content_x + main_offset, content_y }
    case .Col: cursor = { content_x, content_y + main_offset }
    }

    // second pass: position children with alignment
    for &node, index in container.elements {
        switch &cont in node {
        case Container:
            // align: offset on cross axis
            cross_offset : f32 = 0
            switch container.style.align {
            case .Start: cross_offset = 0
            case .Center:
                switch container.direction {
                case .Row: cross_offset = (available_h - cont.rect.h) / 2
                case .Col: cross_offset = (available_w - cont.rect.w) / 2
                }
            case .End:
                switch container.direction {
                case .Row: cross_offset = available_h - cont.rect.h
                case .Col: cross_offset = available_w - cont.rect.w
                }
            }

            switch container.direction {
            case .Row:
                cont.rect.x = cursor.x
                cont.rect.y = cursor.y + cross_offset
            case .Col:
                cont.rect.x = cursor.x + cross_offset
                cont.rect.y = cursor.y
            }

            layout(&cont, cont.rect, ctx)

            gap : f32 = 0.0
            if index != (len(container.elements) - 1) {
                gap = f32(container.style.gap)
            }

            switch container.direction {
            case .Row: cursor.x += cont.rect.w + gap
            case .Col: cursor.y += cont.rect.h + gap
            }
        case Text:
            cross_offset : f32 = 0
            switch container.style.align {
            case .Start: cross_offset = 0
            case .Center:
                switch container.direction {
                case .Row: cross_offset = (available_h - cont.bounds[1]) / 2
                case .Col: cross_offset = (available_w - cont.bounds[0]) / 2
                }
            case .End:
                switch container.direction {
                case .Row: cross_offset = available_h - cont.bounds[1]
                case .Col: cross_offset = available_w - cont.bounds[0]
                }
            }

            switch container.direction {
            case .Row: cont.pos = { cursor.x, cursor.y + cross_offset }
            case .Col: cont.pos = { cursor.x + cross_offset, cursor.y }
            }

            gap : f32 = 0.0
            if index != (len(container.elements) - 1) {
                gap = f32(container.style.gap)
            }

            switch container.direction {
            case .Row: cursor.x += cont.bounds[0] + gap
            case .Col: cursor.y += cont.bounds[1] + gap
            }
        }
    }

}

begin :: proc(container: ^Container, parent_rect: Rect, ctx: ^Context) {
    layout(container, parent_rect, ctx)
    if ctx != nil {
        ui_cache(&ctx.ui_state, container)
    }
}

render :: proc(container: ^Container, ctx: ^Context, draw_fn: proc(node: ^Node, ctx: ^Context)) {
    n := Node(container^)
    draw_fn(&n, ctx)
    for &child in container.elements {
        switch &c in child {
        case Container:
            render(&c, ctx, draw_fn)
        case Text:
            draw_fn(&child, ctx)
        }
    }
}

print_tree :: proc(container: ^Container) {
    sb := strings.builder_make()

    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)
    n := Node(container^)
    walk_tree(&n, &sb)
    fmt.print(strings.to_string(sb))
}

walk_tree :: proc(node: ^Node, sb: ^strings.Builder, depth: int = 0) {
    strings.write_string(sb, write_node(node, depth))

    switch &elem in node {
    case Container:
        for &child in elem.elements {
            walk_tree(&child, sb, depth + 1)
        }
    case Text: // text is always a leaf node
    }
}

write_node :: proc(node: ^Node, depth: int = 0) -> string {
    n := ""
    switch c in node {
    case Container:
       n = fmt.aprintfln(
            "%*s Container(id=%d, direction=%v, width=%f, height=%f)",
            depth * 2, "",
            c.id, c.direction, c.width, c.height,
        )
    case Text:
        n = fmt.aprintfln(
            "%*s Text(size=%f, color=%v, pos=%v, content=%s)",
            depth * 2, "",
            c.size, c.color, c.pos, c.content,
        )
    }

    return n
}

fatal :: proc(message: string) {
    fmt.eprintln(message)
    os.exit(1)
}
