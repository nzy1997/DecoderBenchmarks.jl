#import "@preview/cetz:0.2.2": canvas, draw, tree, plot
#set page(width: auto, height: auto, margin: 5pt)
 
#let visualize-treeverse(filename) = {
    import draw: *
    // Load and parse the JSON data
    let data = json(filename)
    let pvec = data.pvec
    let time_res = data.time_res

  plot.plot(size: (2, 2), axis-style: none, {
  // Using an array of points:
  plot.add(pvec.zip(time_res))
  // Sampling a function:
  })
  }

#figure(canvas({
  import draw: *
  // Function to visualize treeverse log
 
  // Visualize the treeverse log
  visualize-treeverse("../data/surface_code/result/TensorQEC_BP/code=SurfaceCode(3, 3)_pvec=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2]_nsample=10000_decoder=BPDecoder(100, true).json")
  //content((), [#res])
}))


