#import "@preview/cetz:0.2.2": canvas, draw, tree, plot
#set page(width: auto, height: auto, margin: 5pt)

#let visualize-time(filename,label) = {
    let data = json(filename)
    let pvec = data.pvec
    let time_res = data.time_res
    plot.add(pvec.zip(time_res), label: label)
}

#let visualize-rate(filename,label) = {
    let data = json(filename)
    let pvec = data.pvec
    let error_rate = data.error_rate
    plot.add(pvec.zip(error_rate), label: label)
}

#let visualize-all() = {
    import draw: *
    plot.plot(size: (10, 10), axis-style: "scientific", {
    for d in range(3,13,step:2){
        visualize-time("../data/surface_code/result/TensorQEC_BP/code=SurfaceCode("+str(d)+", " +str(d)+")_pvec=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2]_nsample=10000_decoder=BPDecoder(100, true).json","TensorQEC BPOSD d="+str(d))
        visualize-time("../data/surface_code/result/ldpc/code=surface_code_"+str(d*d)+"_pvec=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2]_nsample=10000_decoder=BpOsdDecoder.json","LDPC BPOSD d="+str(d))}
  })
    set-origin((17,0))
        plot.plot(size: (10, 10), axis-style: "scientific", {
    for d in range(3,13,step:2){
        visualize-rate("../data/surface_code/result/TensorQEC_BP/code=SurfaceCode("+str(d)+", " +str(d)+")_pvec=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2]_nsample=10000_decoder=BPDecoder(100, true).json","TensorQEC BPOSD d="+str(d))
        visualize-rate("../data/surface_code/result/ldpc/code=surface_code_"+str(d*d)+"_pvec=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2]_nsample=10000_decoder=BpOsdDecoder.json","LDPC BPOSD d="+str(d))}
  })
  }

#figure(canvas({
  import draw: *
  visualize-all()
}))


