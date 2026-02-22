#+feature dynamic-literals
package lx

import "core:fmt"
import "core:os"
import "core:strings"

Direction :: enum { Row, Col }

// Width and height is a float from 0.1,
Container :: struct {
    id        : string,
    direction : Direction,
    width     : f32,
    height    : f32,
    elements  : [dynamic]Container,
    rect      : Rect,
    bg        : Color,
}

Rect  :: struct { x, y, w, h : f32}
Color :: distinct [4]u8

new_container :: proc(id: string, direction: Direction, width: f32, height: f32, color: Color) -> Container {
    return Container{ id, direction, width, height, {}, {}, color }
}

verify_container :: proc(container: Container) {
    if container.width < 0 || container.width > 1 {
        fatal(fmt.aprintf("ERR: (Container %s): Width range should be 0..1, got %f", container.id, container.width))
    }

    if container.height < 0 || container.width > 1 {
        fatal(fmt.aprintf("ERR: (Container %s): Height range should be 0..1, got %f", container.id, container.width))
    }
}

add_elements :: proc(parent: ^Container, elements: ..Container) {
    for el in elements {
        verify_container(el)
        append(&parent.elements, el)
    }
}

layout :: proc(container: ^Container, parent_rect: Rect) {
    container.rect = parent_rect
    cursor : struct{ x, y: f32 } = {
        x = parent_rect.x,
        y = parent_rect.y,
    }

    for &cont in container.elements {
        cont.rect = {
            w = cont.width * parent_rect.w,
            h = cont.height * parent_rect.h,
            x = cursor.x,
            y = cursor.y,
        }

        if len(cont.elements) != 0 {
            layout(&cont, cont.rect)
        }

        switch container.direction {
        case .Row:
            cursor.x += cont.rect.w
        case .Col:
            cursor.y += cont.rect.h
        }
    }
}

render :: proc(layout: ^Container, draw_fn: proc(rect: Rect, color: Color)) {
    draw_fn(layout.rect, layout.bg)

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
        "%sContainer(id=%s, direction=%v, width=%f, height=%f)",
        str_padding(depth),
        container.id,container.direction, container.width, container.height,
    )
}

str_padding :: proc(depth: int) -> string {
    str : [dynamic]string
    for i in 0..<depth {
        _ = i
        append(&str, "  ")
    }

    return strings.concatenate(str[:])
}

fatal :: proc(message: string) {
    fmt.eprintln(message)
    os.exit(1)
}
