package main

import "lx"
import "core:os"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 1080
SCREEN_HEIGHT :: 720

FONT_DATA :: #load("../resources/fonts/JetBrainsMono-Regular.ttf")

main :: proc() {
    args := os.args
    if len(args) != 2 { lx.fatal("Too few arguments") }

    switch args[1] {
    case "tree":
        layout := hello_lx(SCREEN_WIDTH, SCREEN_HEIGHT, {})
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

    font := rl.LoadFontFromMemory(".ttf", raw_data(FONT_DATA), i32(len(FONT_DATA)), 35, nil, 0)
    defer rl.UnloadFont(font)

    rl.SetTextureFilter(font.texture, .BILINEAR)

    measure_text :: proc(t: ^lx.Text, ctx: ^lx.Context) -> lx.Vec2 {
        rl_font, ok := ctx.font.(^rl.Font)
        if !ok {
            lx.fatal("measure_text: Expected font to be of rl.Font")
        }

        v := rl.MeasureTextEx(rl_font^, strings.clone_to_cstring(t.content), f32(t.size), 1)
        return { v.x, v.y }
    }


    ctx := lx.Context {
        font = &font,
        measure_text_fn = measure_text,
    }

    layout := hello_lx(rl.GetScreenWidth(), rl.GetScreenHeight(), &ctx)

    for !rl.WindowShouldClose() {
        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })

        rl.BeginDrawing()
        defer rl.EndDrawing()

        if rl.IsWindowResized() {
            layout = hello_lx(rl.GetScreenWidth(), rl.GetScreenHeight(), &ctx)
        }

        lx.render(&layout, &ctx, proc(n: ^lx.Node, ctx: ^lx.Context) {
            switch &c in n {
            case lx.Container:
                rl.DrawRectangleRounded(
                    { c.rect.x, c.rect.y, c.rect.w, c.rect.h },
                    c.style.round, 16, rl.Color(c.style.bg),
                )
            case lx.Text:
                font, ok := ctx.font.(^rl.Font)
                if !ok {
                    lx.fatal("render: Expected font to be of rl.Font")
                }


                rl.DrawTextEx(
                    font^,
                    strings.clone_to_cstring(c.content),
                    {c.pos.x, c.pos.y},
                    c.size, 0, rl.Color(c.color),
                )
            }
        })
    }
}

hello_lx :: proc(width, height: i32, ctx: ^lx.Context) -> lx.Container {
    roundness :: 10.0
    root      := lx.container("root", 1, 1, style = { bg = { 23, 23, 23, 0 }, align = .Center, justify = .Center })

    box       := lx.container("bx", 0.5, 0.2, lx.Direction.Col, style = { bg = lx.Color(rl.RED), padding = 5, round = roundness * 5, justify = .Center, align = .Center })
    box_cont  := lx.container("bxc", 1, 1, lx.Direction.Col, style = { bg = lx.Color(rl.DARKGRAY), round = roundness * 4, justify = .Center, align = .Center })
    bxc_label := lx.text(25, "SIMP - LX", lx.Color(rl.RAYWHITE))
    bxc_text  := lx.text(25, fmt.aprintf("HEIGHT: %d - WIDTH: %d", height, width), lx.Color(rl.RAYWHITE))
    bxc_vers  := lx.text(20, #config(VERSION, ""), lx.Color(rl.WHITE))
    lx.add_elements(&box_cont, bxc_label, bxc_text, bxc_vers)
    lx.add_elements(&box, box_cont)
    lx.add_elements(&root, box)

    lx.layout(&root, { 0, 0, f32(width), f32(height) }, ctx)

    return root
}
