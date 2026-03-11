package main

import "lx"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 1080
SCREEN_HEIGHT :: 720

MOUSE_SENSITIVITY :: 50

FONT_DATA :: #load("../resources/fonts/JetBrainsMono-Regular.ttf")

main :: proc() {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT, "SIMP")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    text_font := rl.LoadFontFromMemory(".ttf", raw_data(FONT_DATA), i32(len(FONT_DATA)), 50, nil, 0)
    defer rl.UnloadFont(text_font)

    icon_font := rl.LoadFontFromMemory(".ttf", raw_data(lx.ICON_FONT_DATA), i32(len(lx.ICON_FONT_DATA)), 50,
                                        raw_data(lx.ICON_CODEPOINTS), i32(len(lx.ICON_CODEPOINTS)))
    defer rl.UnloadFont(icon_font)

    rl.SetTextureFilter(text_font.texture, .BILINEAR)
    rl.SetTextureFilter(icon_font.texture, .BILINEAR)

    measure_text :: proc(t: ^lx.Text, ctx: ^lx.Context) -> lx.Vec2 {
        font_any := ctx.font.icon if t.icon else ctx.font.text
        rl_font, ok := font_any.(^rl.Font)
        if !ok {
            lx.fatal("measure_text: Expected font to be of rl.Font")
        }

        v := rl.MeasureTextEx(rl_font^, strings.clone_to_cstring(t.content), f32(t.size), 1)
        return { v.x, v.y }
    }


    ctx := lx.Context {
        font           = { text = &text_font, icon = &icon_font },
        measure_text   = measure_text,
        begin_scissor  = proc(r: lx.Rect) { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) },
        end_scissor    = proc() { rl.EndScissorMode() },
        scroll_offsets = make(map[u32]f32),
    }

    active_example := 0
    show_labels := false


    img := rl.LoadTexture("resources/example.png")
    defer rl.UnloadTexture(img)

    img_size := 200
    img_texture := ImgTexture {
        texture = &img,
        w = f32(img_size),
        h = f32(img_size),
    }

    count := 0

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
            show_labels = !show_labels
        }

        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl_mp := rl.GetMousePosition()
        mp := lx.Vec2{ rl_mp.x, rl_mp.y }
        ctx.state.mouse_pos = mp
        ctx.state.mouse_down = rl.IsMouseButtonDown(rl.MouseButton.LEFT)
        ctx.state.scroll_wheel = rl.GetMouseWheelMoveV().y * MOUSE_SENSITIVITY

        render_w := rl.GetRenderWidth()
        render_h := rl.GetRenderHeight()

        layout: ^lx.Box
        switch active_example {
        case 1: layout = example_simple(render_w, render_h, &ctx, mp)
        case 2: layout = example_viewer(render_w, render_h, &ctx, show_labels)
        case 3: layout = example_btop(render_w, render_h, &ctx, show_labels)
        case 4: layout = example_image(render_w, render_h, &ctx, &img_texture)
        case 5: layout = example_button(render_w, render_h, &ctx, &count)
        case 6: layout = example_scrollable(render_w, render_h, &ctx)
        case 7: layout = example_floating(render_w, render_h, &ctx)
        case:   layout = example_default(render_w, render_h, &ctx)
        }

        lx.handle_input(layout, &ctx)
        lx.render(layout, &ctx, proc(element: ^lx.Element, ctx: ^lx.Context) {
            switch &elem in element {
            case ^lx.Box:
                bg := elem.style.bg

                if ctx.state.hover_id == elem.id && elem.style.hover_bg.r != 0 {
                    bg = elem.style.hover_bg
                }

                rl.DrawRectangleRounded(
                    { elem.bounds.x, elem.bounds.y, elem.bounds.w, elem.bounds.h },
                    elem.style.round, 16, rl.Color(bg),
                )
            case ^lx.Text:
                font_any := ctx.font.icon if elem.icon else ctx.font.text
                font, ok := font_any.(^rl.Font)
                if !ok { lx.fatal("render: Expected font to be of ^rl.Font") }
                rl.DrawTextEx(
                    font^,
                    strings.clone_to_cstring(elem.content),
                    { elem.pos.x, elem.pos.y },
                    elem.size, 0, rl.Color(elem.color),
                )
            case ^lx.Image:
                texture, ok := elem.texture.(^rl.Texture2D)
                if !ok { lx.fatal("render: Expected texture to be of ^rl.Texture2D") }
                src_rect  := rl.Rectangle{ elem.pos.x, elem.pos.y, f32(texture.width), f32(texture.height) }
                dest_rect := rl.Rectangle{ elem.pos[0], elem.pos[1], elem.bounds.x, elem.bounds.y }
                rl.DrawTexturePro(texture^, src_rect, dest_rect, { 0, 0 }, 0.0, rl.WHITE)
            }

        })
    }
}
