package lx_old

import "core:testing"
import "core:math"
import "core:fmt"

ctx := Context{}

@private
expect_approx :: proc(t: ^testing.T, got: f32, expected: f32, loc := #caller_location) {
    assert(math.abs(got - expected) <= 0.01, fmt.aprintf("expected %f, got %f", expected, got))
}

@(test)
test_add_elements :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)
    root    := container("root", 1, 1, Direction.Col, style = { bg = { 10, 100, 10, 255 } })
    element := container("element", 0.5, 0.5, style = { bg = { 100, 100, 100, 255 } })
    text    := text("hello")
    add_elements(&root, element, text)

    assert(len(root.elements) == 2, "Expected root's elements to be 2")
    root_element := root.elements[0].(Container)
    assert(root_element.id == element.id)
    assert(root_element.width == element.width)
    assert(root_element.height == element.height)

    _, ok := root.elements[1].(Text)
    assert(ok, "Expected second element to be Text")
}

@(test)
test_layout_single_child :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1)
    child := container("c", 0.5, 1)
    add_elements(&root, child)
    layout(&root, { 0, 0, 100, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.x, f32(0))
    testing.expect_value(t, c.rect.y, f32(0))
    testing.expect_value(t, c.rect.w, f32(50))
    testing.expect_value(t, c.rect.h, f32(100))
}

@(test)
test_layout_two_children_row :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1)
    a := container("a", 0.4, 1)
    b := container("b", 0.6, 1)
    add_elements(&root, a, b)
    layout(&root, { 0, 0, 200, 100 }, &ctx)

    ca := root.elements[0].(Container)
    cb := root.elements[1].(Container)
    expect_approx(t, ca.rect.x, 0)
    expect_approx(t, ca.rect.w, 80)
    expect_approx(t, cb.rect.x, 80)
    expect_approx(t, cb.rect.w, 120)
}

@(test)
test_layout_two_children_col :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, .Col)
    a := container("a", 1, 0.3)
    b := container("b", 1, 0.7)
    add_elements(&root, a, b)
    layout(&root, { 0, 0, 100, 200 }, &ctx)

    ca := root.elements[0].(Container)
    cb := root.elements[1].(Container)
    expect_approx(t, ca.rect.y, 0)
    expect_approx(t, ca.rect.h, 60)
    expect_approx(t, cb.rect.y, 60)
    expect_approx(t, cb.rect.h, 140)
}

@(test)
test_layout_gap :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { gap = 10 })
    a := container("a", 0.5, 1)
    b := container("b", 0.5, 1)
    add_elements(&root, a, b)
    layout(&root, { 0, 0, 200, 100 }, &ctx)

    ca := root.elements[0].(Container)
    cb := root.elements[1].(Container)
    testing.expect_value(t, ca.rect.w, f32(95))
    testing.expect_value(t, cb.rect.x, f32(105)) // 95 + 10 gap
    testing.expect_value(t, cb.rect.w, f32(95))
}

@(test)
test_layout_padding :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { padding = 20 })
    child := container("c", 1, 1)
    add_elements(&root, child)
    layout(&root, { 0, 0, 200, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.x, f32(20))
    testing.expect_value(t, c.rect.y, f32(20))
    testing.expect_value(t, c.rect.w, f32(160)) // 200 - 40
    testing.expect_value(t, c.rect.h, f32(60))  // 100 - 40
}

@(test)
test_justify_center :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { justify = .Center })
    child := container("c", 0.5, 1)
    add_elements(&root, child)
    layout(&root, { 0, 0, 100, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.x, f32(25)) // (100 - 50) / 2
    testing.expect_value(t, c.rect.w, f32(50))
}

@(test)
test_justify_end :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { justify = .End })
    child := container("c", 0.5, 1)
    add_elements(&root, child)
    layout(&root, { 0, 0, 100, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.x, f32(50)) // 100 - 50
}

@(test)
test_align_center :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { align = .Center })
    child := container("c", 0.5, 0.5)
    add_elements(&root, child)
    layout(&root, { 0, 0, 100, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.y, f32(25)) // (100 - 50) / 2
}

@(test)
test_align_end :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    root := container("r", 1, 1, style = { align = .End })
    child := container("c", 0.5, 0.5)
    add_elements(&root, child)
    layout(&root, { 0, 0, 100, 100 }, &ctx)

    c := root.elements[0].(Container)
    testing.expect_value(t, c.rect.y, f32(50)) // 100 - 50
}
