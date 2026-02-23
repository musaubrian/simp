package main

import "lx"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 1080
SCREEN_HEIGHT :: 720

FONT_DATA :: #load("../resources/fonts/JetBrainsMono-Regular.ttf")

main :: proc() {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT, "SIMP")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    font := rl.LoadFontFromMemory(".ttf", raw_data(FONT_DATA), i32(len(FONT_DATA)), 50, nil, 0)
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
        measure_text = measure_text,
    }

    active_example := 0
    show_thumbnail_labels := false

    context.allocator = context.temp_allocator
    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) && rl.IsKeyPressed(rl.KeyboardKey.Q) {
            break
        }

        if rl.IsKeyPressed(rl.KeyboardKey.N) {
            active_example = len(Examples) - 1 if (active_example - 1) < 0 else active_example - 1
        }
        if rl.IsKeyPressed(rl.KeyboardKey.L) {
            show_thumbnail_labels = !show_thumbnail_labels
        }

        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl_mp := rl.GetMousePosition()
        mp := lx.Vec2{rl_mp.x, rl_mp.y}
        render_w := rl.GetRenderWidth()
        render_h := rl.GetRenderHeight()

        layout := example_default(render_w, render_h, &ctx)

        if active_example == 1 {
            layout = example_simple(render_w, render_h, &ctx, mp)
        } else if active_example == 2 {
            layout = example_viewer(render_w, render_h, &ctx, show_thumbnail_labels)
        }

        lx.render(layout, &ctx, proc(element: ^lx.Element, ctx: ^lx.Context) {
            switch &elem in element {
            case ^lx.Box:
                bg := elem.style.bg
                rl.DrawRectangleRounded(
                    { elem.bounds.x, elem.bounds.y, elem.bounds.w, elem.bounds.h },
                    elem.style.round, 16, rl.Color(bg),
                )
            case ^lx.Text:
                font, ok := ctx.font.(^rl.Font)
                if !ok { lx.fatal("render: Expected font to be of ^rl.Font") }
                rl.DrawTextEx(
                    font^,
                    strings.clone_to_cstring(elem.content),
                    { elem.pos.x, elem.pos.y },
                    elem.size, 0, rl.Color(elem.color),
                )
            }

        })
    }
}
