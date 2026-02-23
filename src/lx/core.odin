#+feature dynamic-literals
package lx

import "core:fmt"
import "core:os"
import "core:strings"

Direction :: enum  { Row, Col }
Node      :: union { Container, Text }

Container :: struct {
    id          : string,
    width       : f32,
    height      : f32,
    direction   : Direction,
    elements    : [dynamic]Node,
    rect        : Rect,
    style       : Style,
}

Text :: struct {
    id       : string,
    content  : string,
    size     : f32,
    color    : Color,
    pos      : Vec2,
}

Style :: struct {
    round     : f32,
    gap       : int,
    padding   : int,
    bg        : Color,
    hover_bg  : Color,
}

Vec2  :: distinct [2]f32
Rect  :: struct { x, y, w, h: f32 }
Color :: distinct [4]u8

@private
_current_id : int = 0

container :: proc(label: string, width: f32, height: f32, direction: Direction = .Row, style := Style{}) -> Container {
    _current_id += 1
    c := Container{
        id = fmt.aprintf("%s#%d", label, _current_id),
        direction = direction,
        width = width,
        height = height,
        rect = {},
        elements = {},
        style = style,
    }
    verify_container(c)
    return c
}

text :: proc(size: f32, content: string, color: Color) -> Text {
    _current_id += 1
    return Text{
        id = fmt.aprintf("##%d", _current_id),
        content = content,
        size = size,
        color = color,
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

layout :: proc(container: ^Container, parent_rect: Rect) {
    container.rect = parent_rect

    cursor : struct{ x, y: f32 } = {
        x = parent_rect.x + f32(container.style.padding),
        y = parent_rect.y + f32(container.style.padding),
    }

    total_gap := f32(container.style.gap * (len(container.elements) - 1))

    available_w := parent_rect.w - f32(container.style.padding * 2)
    available_h := parent_rect.h - f32(container.style.padding * 2)

    switch container.direction {
    case .Row: available_w -= total_gap
    case .Col: available_h -= total_gap
    }

    for &node, index in container.elements {
        switch &cont in node {
        case Container:
            cont.rect = {
                w = cont.width * available_w,
                h = cont.height * available_h,
                x = cursor.x,
                y = cursor.y,
            }

            layout(&cont, cont.rect)

            gap : f32 = 0.0
            if index != (len(container.elements) - 1) {
                gap = f32(container.style.gap)
            }

            switch container.direction {
            case .Row: cursor.x += cont.rect.w + gap
            case .Col: cursor.y += cont.rect.h + gap
            }
        case Text:
            cont.pos = { cursor.x, cursor.y }
        }
    }
}

render :: proc(container: ^Container, draw_fn: proc(node: ^Node)) {
    n := Node(container^)
    draw_fn(&n)
    for &child in container.elements {
        switch &c in child {
        case Container:
            render(&c, draw_fn)
        case Text:
            draw_fn(&child)
        }
    }
}

print_tree :: proc(container: ^Container) {
    depth : int = 0
    sb := strings.builder_make()

    n := Node(container^)
    walk_tree(&n, depth, &sb)
    fmt.print(strings.to_string(sb))
}

walk_tree :: proc(node: ^Node, depth: int, sb: ^strings.Builder) {
    strings.write_string(sb, write_node(node, depth))

    switch &elem in node {
    case Container:
        for &child in elem.elements {
            walk_tree(&child, depth + 1, sb)
        }
    case Text: // text is always a leaf node
    }
}

write_node :: proc(node: ^Node, depth: int = 0) -> string {
    n := ""
    switch c in node {
    case Container:
       n = fmt.aprintfln(
            "%*s Container(id=%s, direction=%v, width=%f, height=%f)",
            depth * 2, "",
            c.id, c.direction, c.width, c.height,
        )
    case Text:
        n = fmt.aprintfln(
            "%*s Text(id=%s, size=%f, color=%v, pos=%v, content=%s)",
            depth * 2, "",
            c.id, c.size, c.color, c.pos, c.content,
        )
    }

    return n
}

fatal :: proc(message: string) {
    fmt.eprintln(message)
    os.exit(1)
}
