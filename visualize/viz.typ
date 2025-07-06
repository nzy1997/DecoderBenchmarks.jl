#import "@preview/cetz:0.2.2": canvas, draw, tree, plot
#set page(width: auto, height: auto, margin: 5pt)

#let visualize-line(filename,field_name) = {
    import draw: *
    let data = json("../"+filename)
    let pvec = data.pvec
    let time_res = if field_name == "time_res" { data.time_res } else { data.error_rate }
    let label = data.code_name + " " + data.decoder
    if data.decoder == "BPDecoder(100, true)"{
    plot.add(pvec.zip(time_res), label: label,style: (stroke: (paint: red, dash: "dashed")))
    } else {
        plot.add(pvec.zip(time_res), label: label,style: (stroke: (paint: black)))
    }

    // plot.add(pvec.zip(time_res), label: label)
    // plot.add(pvec.zip(time_res), label: label, style: (stroke: (paint: red, dash: "dashed")))
}

#let visualize-all() = {
    import draw: *
    let data = json("data/files.json")
    let files = data.files

    plot.plot(size: (10, 10), axis-style: "scientific", {
    for file in files{
    visualize-line(file,"time_res")
    }})
    set-origin((17,0))
    plot.plot(size: (10, 10), axis-style: "scientific", {
    for file in files{
    visualize-line(file,"error_rate")
    }})
  }

#figure(canvas({
  import draw: *
  visualize-all()
}))


