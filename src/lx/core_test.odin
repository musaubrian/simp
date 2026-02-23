package lx

import "core:testing"

@(test)
test_add_elements :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)
    root    := container("root", 1, 1, Direction.Col, style = { bg = { 10, 100, 10, 255 } })
    element := container("element", 0.5, 0.5, style = { bg = { 100, 100, 100, 255 } })
    text    := text(16, "hello", { 100, 100, 100, 255 })
    add_elements(&root, element, text)

    assert(len(root.elements) == 2, "Expected root's elements to be 2")
    root_element := root.elements[0].(Container)
    assert(root_element.id == element.id)
    assert(root_element.width == element.width)
    assert(root_element.height == element.height)

    _, ok := root.elements[1].(Text)
    assert(ok, "Expected second element to be Text")
}
