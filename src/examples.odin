package main

import "lx"
import "core:fmt"

Examples :: []string{" 0 - This layout", " 1 - Simple layout"}

example_default :: proc(w, h: i32, ctx: ^lx.Context) -> ^lx.Box {
    root := lx.box("df-r", 1, 1, style = { bg = { 40, 40, 40, 255 }, padding = 50 })
    main := lx.box("df-m", -1, -1, lx.Direction.Col, style = {
        bg = { 110, 110, 140, 255 }, round = 15, padding = 10, gap = 5 })
    main_content := lx.box("df-mc", -1, -1, lx.Direction.Col, style = { padding = 10, gap = 5 })


    footer := lx.box("df-f", -1, 0.1, style = { padding = 10, align = .End })
    footer_text := lx.text("* Use 'n' to switch between different layouts", size = 22)
    lx.add_elements(footer, footer_text)

    title := lx.text("LX Examples", size = 30)
    lx.add_elements(main, title)

    for example in Examples { lx.add_elements(main_content, lx.text(example, size = 27)) }
    lx.add_elements(main, main_content, footer)
    lx.add_elements(root, main)

    lx.layout(root, { 0, 0, f32(w), f32(h) }, ctx)

    return root
}

example_simple :: proc(w, h: i32, ctx: ^lx.Context, mouse_pos: lx.Vec2) -> ^lx.Box {
    base_padding := 7
    radius : f32 = 10.0
    root := lx.box("root", 1, 1, lx.Direction.Col,
              style = {
                  bg = { 23, 23, 23, 0 },
                  align = .Center,
                  padding = base_padding * 2,
                  gap = 10,
              })

    top := lx.box("top", 1, 0.15, lx.Direction.Col, style = {
        bg = { 130, 150, 150, 200 },
        padding = base_padding, round = radius, gap = 5 })

    title      := lx.text("SIMP - LX", size = 30)
    dimensions := lx.text(fmt.tprintf("HEIGHT: %d - WIDTH: %d", h, w))
    mouse      := lx.text(fmt.tprintf("Mouse{{x=%.1f, y=%.1f}}", mouse_pos.x, mouse_pos.y))
    version    := lx.text(fmt.tprintf("VERSION: %s", #config(VERSION, "")), size = 27)
    lx.add_elements(top, title, version, dimensions, mouse)

    bottom := lx.box("bottom", -1, -1, lx.Direction.Col, style = {
            bg = { 150, 185, 200, 155 },
            round = radius,
            padding = base_padding,
            gap = 10 })

    lx.add_elements(root, top, bottom)

    heirarchy := lx.get_heirarchy(example_default(w,h,ctx))

    heirarchy_title := lx.text("Default Example layout", size = 28)
    tree := lx.text(heirarchy)
    lx.add_elements(bottom, heirarchy_title, tree)

    lx.layout(root, { 0, 0, f32(w), f32(h) }, ctx)

    return root
}
