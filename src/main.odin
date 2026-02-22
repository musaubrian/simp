package main

import "lx"
import "core:os"
import "core:fmt"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 1080
SCREEN_HEIGHT :: 720

ROUNDNESS :: 0.15

main :: proc() {
    args := os.args
    if len(args) != 2 { lx.fatal("Too few arguments") }

    switch args[1] {
    case "tree":
        layout := build_layout(SCREEN_WIDTH, SCREEN_HEIGHT)
        lx.print_tree(&layout)
    case "render":
        render_layout()
    case "version":
        fmt.println(#config(VERSION, ""))
    case:
        lx.fatal(fmt.aprintf("Unkown command <%s>", args[1]))


    }
}

render_layout :: proc() {
    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT, "SIMP")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })

        rl.BeginDrawing()
        defer rl.EndDrawing()

        layout := build_layout(SCREEN_WIDTH, SCREEN_HEIGHT)

        lx.render(&layout, proc(c: ^lx.Container) {
            rl.DrawRectangleRounded(
                { c.rect.x, c.rect.y, c.rect.w, c.rect.h },
                c.style.round, 10, rl.Color(c.style.bg),
            )
        })
    }
}

build_layout :: proc(width, height: i32) -> lx.Container {
    root := lx.new_container("root", lx.Direction.Row, 1, 1, { bg = { 23, 23, 23, 0 } })

    sidebar        := lx.new_container("sidebar", lx.Direction.Col, 0.3, 1, { bg = lx.Color(rl.DARKGRAY), gap = 5, padding = 5 })
    sidebar_header := lx.new_container("sidebar-header", lx.Direction.Row, 1, 0.05, { bg=lx.Color(rl.LIGHTGRAY) })
    sidebar_stuff := lx.new_container("sidebar-stuff", lx.Direction.Row, 0.2, 0.05, { bg=lx.Color(rl.PURPLE) })
    sidebar_more_stuff := lx.new_container("more-sidebar-stuff", lx.Direction.Row, 0.8, 0.05, { bg=lx.Color(rl.ORANGE) })
    lx.add_elements(&sidebar, sidebar_header, sidebar_stuff, sidebar_more_stuff)

    main_content := lx.new_container("main", lx.Direction.Col, 0.7, 1, { bg = lx.Color(rl.RED) })
    main_header  := lx.new_container("main-header", lx.Direction.Row, 1, 0.1, { bg = lx.Color(rl.MAGENTA) })

    boxes := lx.new_container("boxes", lx.Direction.Row, 1, 0.6, { bg =lx.Color(rl.BLUE), gap = 10, padding = 10 })
    box_l := lx.new_container("box-left", lx.Direction.Col, 0.4, 0.6, { bg = lx.Color(rl.GRAY), round = ROUNDNESS/2 })
    box_r := lx.new_container("box-right", lx.Direction.Col, 0.5, 0.2, { bg = lx.Color(rl.LIGHTGRAY), round = ROUNDNESS })
    lx.add_elements(&boxes, box_l, box_r)

    lx.add_elements(&main_content, main_header, boxes)
    lx.add_elements(&root, sidebar, main_content)

    lx.layout(&root, { 0, 0, f32(width), f32(height) })

    return root
}
