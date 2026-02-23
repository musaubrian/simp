package main

import "lx"
import "core:os"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 1080
SCREEN_HEIGHT :: 720

FONT_DATA :: #load("../resources/fonts/JetBrainsMono-Regular.ttf")

counter := 0
main :: proc() {
    args := os.args
    if len(args) != 2 { lx.fatal("Too few arguments") }

    switch args[1] {
    case "tree":
        ctx := lx.Context{}
        layout := hello_lx(SCREEN_WIDTH, SCREEN_HEIGHT, &ctx)
        lx.print_heirarchy(layout)
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
        measure_text = measure_text,
    }
    // ctx.ui_state.widgets = make(map[u32]lx.Widget_State)
        // mp := rl.GetMousePosition()
        // ctx.ui_state.mouse_pos = { mp.x, mp.y }
        // ctx.ui_state.mouse_down = rl.IsMouseButtonDown(.LEFT)
        // ctx.ui_state.hot_id = 0

    context.allocator = context.temp_allocator
    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)
        rl.ClearBackground(rl.Color{ 23, 23, 23, 0 })

        rl.BeginDrawing()
        defer rl.EndDrawing()


        layout := hello_lx(rl.GetRenderWidth(), rl.GetRenderHeight(), &ctx)
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

hello_lx :: proc(width, height: i32, ctx: ^lx.Context) -> ^lx.Box {
    roundness :: 10.0
    root      := lx.box("root", 1, 1, style = { bg = { 23, 23, 23, 0 }, align = .Center, justify = .Center })

    box       := lx.box("bx", 0.5, 0.2, lx.Direction.Col, style = { bg = { 230, 41, 55, 255 }, padding = 5, round = roundness * 5, justify = .Center, align = .Center })
    box_cont  := lx.box("bxc", -1, -1, lx.Direction.Col, style = { bg = { 80, 80, 80, 255 }, gap = 5, round = roundness * 4, justify = .Center, align = .Center })
    bxc_label := lx.text("SIMP - LX", color = { 200, 122, 255, 255 })
    bxc_text  := lx.text(fmt.tprintf("HEIGHT: %d - WIDTH: %d", height, width))
    bxc_vers  := lx.text(#config(VERSION, ""))

    // if lx.button(&box_cont, fmt.tprintf("Clicked %d", state^), 0.5, 0.2, &ctx.ui_state, style = { bg = { 120, 230, 23, 255 }, round = roundness * 2,  align = .Center, justify = .Center }) {
    //     state^ += 1
    // }

    lx.add_elements(box_cont, bxc_label, bxc_text, bxc_vers)
    lx.add_elements(box, box_cont)
    lx.add_elements(root, box)

    lx.layout(root, { 0, 0, f32(width), f32(height) }, ctx)

    return root
}
