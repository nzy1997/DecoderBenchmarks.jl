#import "@preview/cetz:0.4.0": canvas, draw, tree
#import "@preview/cetz-plot:0.1.2": plot
#set page(width: auto, height: auto, margin: 5pt)

#let visualize-line(filename,field_name,color) = {
    import draw: *
    let data = json("../"+filename)
    let pvec = data.pvec
    let time_res = if field_name == "time_res" { data.time_res.map(x => 1000 * x) } else { data.error_rate }
    let label = data.code_name + " " + data.decoder


    // plot.add(pvec.zip(time_res), label: label, style: (stroke: (paint: color)))

    plot.add(pvec.zip(time_res), label: label)

    // if data.decoder == "BPDecoder(100, true)"{
    // plot.add(pvec.zip(time_res), label: label,style: (stroke: (paint: red, dash: "dashed")))
    // } else {
    //     plot.add(pvec.zip(time_res), label: label,style: (stroke: (paint: black)))
    // }
}

#let visualize-all(name_vecs) = {
    import draw: *
    // let data = json("data/files.json")
    // let files = data.files

    let file_content = read("../data/result/files.txt")
    let files = file_content.split("\n").filter(line => line != "")
    let files = files.filter(file => name_vecs.any(name_vec => name_vec.all(x => file.contains(x))))
    
    plot.plot(size: (10, 10), axis-style: "scientific",x-label: "p",y-label: "time(ms)", y-mode: "log", y-base: 10, {
    for file in files{
        visualize-line(file,"time_res",red)
    }})
    set-origin((25,0))
    plot.plot(size: (10, 10), axis-style: "scientific",x-label: "p",y-label: "error rate", {
    for file in files{
    visualize-line(file,"error_rate",black)
    }})
    set-origin((-25,0))
  }

#figure(canvas({
  import draw: *
  visualize-all((("TensorQEC","10000","IP"),("ldpc","10000"),("TensorQEC","10000","TN")))

  set-origin((0,-12))
  visualize-all((("TensorQEC","100","BP"),("ldpc","10000")))

  set-origin((0,-12))
  // visualize-all((("TensorQEC","10000","TN"),("TensorQEC","10000","IP")))
  // let data = json("../data/result/TensorQEC/code=SurfaceCode(3, 3)_pvec=[0.01, 0.02]_nsample=100_decoder=BPDecoder(100, true).json")
  // let data = json("/Users/nizhongyi/.julia/dev/DecoderBenchmarks/data/result/TensorQEC/code=SurfaceCode(3, 3)_pvec=[0.01, 0.02]_nsample=100_decoder=BPDecoder(100, true).json")
}))


