package main

import "lx"
import "core:fmt"

Examples :: []string{" - This layout", " - Simple layout", " - Viewer layout", " - Btop layout"}

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

example_viewer :: proc(w, h : i32, ctx: ^lx.Context, show_labels := false) -> ^lx.Box {
    root := lx.box("vr", 1, 1, lx.Direction.Col, style = { padding = 7, gap = 7 })
    view := lx.box("vv", -1, 0.9, style = { bg = { 150, 120, 140, 255 }, round = 10, align = .Center, justify = .Center })
    lx.add_elements(view, lx.text("Nothing to view here :|", size = 35))
    thumbnails := lx.box("vt", -1, -1, style = { bg = { 70, 70, 100, 200 }, padding = 5, gap = 7, round = 10 })
    for i in 0..< 10 {
        label := fmt.tprintf("vt-%d", i+1)
        b := lx.box(label, -1, -1, style = { bg = { 120, 120, 150, 255 }, round = 10, align = .Center, justify = .Center })
        if show_labels { lx.add_elements(b, lx.text(label, size = 20)) }
        lx.add_elements(thumbnails, b)
    }

    lx.add_elements(root, view, thumbnails)
    lx.layout(root, { 0, 0, f32(w), f32(h) }, ctx)
    return root
}

example_btop :: proc(w, h : i32, ctx: ^lx.Context, show_labels := false) -> ^lx.Box {
    padding := 10
    min_size : i32 = 800
    root := lx.box("br", 1, 1, lx.Direction.Col, style = { padding = padding, gap = 7 })

    if w > min_size && h > min_size {
        top := lx.box("bt", -1, 0.3, style = { bg = { 80, 80, 80, 250 }, padding = padding, align = .Center, justify = .End })
        top_child := lx.box("bt-c", 0.4, 0.6, style = { bg = { 100, 100, 100, 255 } })
        if show_labels { lx.add_elements(top_child, lx.text("CPU")) }
        lx.add_elements(top, top_child)

        bottom := lx.box("bb", -1, -1, style = { gap = 7 })
        bottom_l := lx.box("bbl", -1, -1, lx.Direction.Col, style = { padding = 1, gap = 5 })
        bottom_l_t := lx.box("bblt", -1, -1, style = { bg = { 130, 130, 130, 100 }, gap = 7, padding = padding / 2 })
        mem := lx.box("mem",  -1, -1, style = { bg = { 160, 150, 200, 200 } })
        if show_labels { lx.add_elements(mem, lx.text("Memory Usage")) }
        disks := lx.box("disks", -1, -1, style = { bg = { 160, 150, 200, 200 } } )
        if show_labels { lx.add_elements(disks, lx.text("Disks Usage")) }
        lx.add_elements(bottom_l_t, mem, disks)

        bottom_l_b := lx.box("bblb", -1, -1, style = { bg = { 170, 170, 200, 200 }, padding = padding, align = .Center, justify = .End })
        download_upload := lx.box("download_upload", 0.5, 0.6, style = { bg = { 100, 100, 110, 200 } })
        if show_labels { lx.add_elements(download_upload, lx.text("Download/Upload")) }
        lx.add_elements(bottom_l_b, download_upload)

        lx.add_elements(bottom_l, bottom_l_t, bottom_l_b)


        // 6 = _Box_Padding (5) + 1
        bottom_r := lx.box("bbr", -1, -1, style = { bg = { 130, 130, 130, 100 }, padding = 6 })
        if show_labels {lx.add_elements(bottom_r, lx.text("Process List"))}
        lx.add_elements(bottom,  bottom_l, bottom_r)

        lx.add_elements(root, top, bottom)
    } else {
        too_small := lx.box("small", -1, -1, style = { bg = { 250, 140, 140, 200 }, align = .Center, justify = .Center })
        label := fmt.tprintf("Window too small:\nWidth = %d, Height = %d\n\nNeeded for current config:\nWidth = %d+, Height = %d+", w, h, min_size, min_size)
        lx.add_elements(too_small, lx.text(label, size = 30))
        lx.add_elements(root, too_small)
    }

    lx.layout(root, { 0,0, f32(w), f32(h) }, ctx)

    return root
}
