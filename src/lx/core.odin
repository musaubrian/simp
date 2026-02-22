#+feature dynamic-literals
package lx

import "core:fmt"
import "core:os"

Direction :: enum { Row, Col }

// Width and height is a float from 0.1,
Container :: struct {
    id        : string,
    direction : Direction,
    width     : f32,
    height    : f32,
    elements  : [dynamic]Container,
    rect      : Rect,
    style     : Style,
}

Style :: struct {
    round     : f32,
    gap       : int,
    padding   : int,
    bg        : Color,
}

Rect  :: struct { x, y, w, h: f32 }
Color :: distinct [4]u8

new_container :: proc(id: string, direction: Direction, width: f32, height: f32, style := Style{}) -> Container {
    c := Container{ id, direction, width, height, {}, {}, style }
    verify_container(c)
    return c
}

verify_container :: proc(container: Container) {
    if container.width < 0 || container.width > 1 {
        fatal(fmt.aprintf("ERROR: LX: (Container '%s'): Width range should be 0..1, got %f", container.id, container.width))
    }

    if container.height < 0 || container.height > 1 {
        fatal(fmt.aprintf("ERROR: LX: (Container '%s'): Height range should be 0..1, got %f", container.id, container.height))
    }
}

add_elements :: proc(parent: ^Container, elements: ..Container) {
   total : f32 = 0
    for el in parent.elements {
        total += el.width if parent.direction == .Row else el.height
    }
    for el in elements {
        total += el.width if parent.direction == .Row else el.height
        if total > 1.0 {
            fatal(fmt.aprintf("ERROR: LX: (Container '%s'): children exceed 1.0, got %f, '%s' pushed it over", parent.id, total, el.id))
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


    for &cont, index in container.elements {
        cont.rect = {
            w = cont.width * available_w,
            h = cont.height * available_h,
            x = cursor.x,
            y = cursor.y,
        }

        if len(cont.elements) != 0 {
            layout(&cont, cont.rect)
        }

        gap : f32 = 0.0
        if index != (len(container.elements) - 1) {
            gap = f32(container.style.gap)
        }

        switch container.direction {
        case .Row: cursor.x += cont.rect.w + gap
        case .Col: cursor.y += cont.rect.h + gap
        }
    }
}

render :: proc(layout: ^Container, draw_fn: proc(container: ^Container)) {
    draw_fn(layout)

    for &elem in layout.elements {
        render(&elem, draw_fn)
    }
}

print_tree :: proc(container: ^Container) {
    depth : int = 0
    print_container(container, depth)
    for &el in container.elements {
        walk_tree(&el, depth + 1)
    }
}

walk_tree :: proc(node: ^Container, depth: int) {
    d := depth
    print_container(node, d)

    if len(node.elements) == 0 { return }
    d += 1
    for &ne in node.elements {
        walk_tree(&ne, d)
    }

}

print_container :: proc(container: ^Container, depth: int = 0) {
    fmt.printfln(
        "%*s Container(id=%s, direction=%v, width=%f, height=%f)",
        depth * 2, "",
        container.id,container.direction, container.width, container.height,
    )
}

fatal :: proc(message: string) {
    fmt.eprintln(message)
    os.exit(1)
}
