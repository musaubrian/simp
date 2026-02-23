package lx

import "core:testing"

@(test)
test_add_elementss :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := new_container("root", 1, 1, Direction.Col, style = { bg = { 10, 100, 10, 255 } })
    element := new_container("element", 0.5, 0.5, style = { bg = { 100, 100, 100, 255 } })
    add_elements(&root, element)
    assert(len(root.elements) == 1, "Expected root's elements to be incremented")
    root_element := root.elements[0]
    assert(root_element.id == element.id)
    assert(root_element.width == element.width)
    assert(root_element.height == element.height)

}
