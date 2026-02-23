package main

import "lx"
import "core:os"
import "core:fmt"
import "core:strings"
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
    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT, "SIMP")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    context.allocator = context.temp_allocator
    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)
        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })

        rl.BeginDrawing()
        defer rl.EndDrawing()
        layout := build_layout(rl.GetScreenWidth(), rl.GetScreenHeight())


        lx.render(&layout, proc(n: ^lx.Node) {
            switch &c in n {
            case lx.Container:
                rl.DrawRectangleRounded(
                    { c.rect.x, c.rect.y, c.rect.w, c.rect.h },
                    c.style.round, 10, rl.Color(c.style.bg),
                )
            case lx.Text:
                rl.DrawText(
                    strings.clone_to_cstring(c.content),
                    auto_cast(c.pos.x), i32(c.pos.y),
                    i32(c.size), rl.Color(c.color),
                )
            }
        })
    }
}

build_layout :: proc(width, height: i32) -> lx.Container {
    root := lx.container("root", 1, 1, style = { bg = { 23, 23, 23, 0 } })

    sidebar            := lx.container("sb", 0.25, 1, lx.Direction.Col, style = { bg = lx.Color(rl.DARKGRAY), gap = 5, padding = 5 })
    sidebar_header     := lx.container("sbh", 1, 0.05, style = { bg = lx.Color(rl.LIGHTGRAY) })
    sidebar_stuff      := lx.container("sbs", 0.2, 0.05, style = { bg = lx.Color(rl.PURPLE) })
    sidebar_more_stuff := lx.container("sbms", 0.8, 0.05, style = { bg = lx.Color(rl.ORANGE) })
    lx.add_elements(&sidebar, sidebar_header, sidebar_stuff, sidebar_more_stuff)

    main_content := lx.container("m", 0.75, 1, lx.Direction.Col, style = { bg = lx.Color(rl.RED) })
    main_header  := lx.container("mh", 1, 0.1, style = { bg = lx.Color(rl.MAGENTA) })

    boxes := lx.container("b", 1, 0.6, style = { bg = lx.Color(rl.BLUE), gap = 10, padding = 10 })
    box_l := lx.container("bl", 0.4, 0.6, style = { bg = lx.Color(rl.GRAY), round = ROUNDNESS/2 })
    box_r := lx.container("br", 0.5, 0.2, style = { bg = lx.Color(rl.LIGHTGRAY), hover_bg = lx.Color(rl.GREEN), round = ROUNDNESS, padding = 10 })
    box_r_text := lx.text(20, fmt.aprintf("HEIGHT: %d - WIDTH: %d", height, width), lx.Color(rl.PINK))
    lx.add_elements(&box_r, box_r_text)

    lx.add_elements(&boxes, box_l, box_r)

    lx.add_elements(&main_content, main_header, boxes)
    lx.add_elements(&root, sidebar, main_content)

    lx.layout(&root, { 0, 0, f32(width), f32(height) })


    return root
}
