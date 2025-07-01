"""
    generate_code_data(code::QuantumCode,dirname::String,filename::String)

Save code information to a json file in the directory `dirname` with the name `filename*".json"`. The information includes
- `code_name`: The name of the code.
- `qubit_num`: The number of physical qubits.
- `stabilizer_num`: The number of stabilizers.
- `pcm`: The parity check matrix.
- `logical_x`: The logical X operator.
- `logical_z`: The logical Z operator.

The parity check matrix is in the form of `(X|Z)`. The size of the matrix is `(s, 2*n)`. `s` is the number of stabilizers, and `n` is the number of physical qubits. Each row of the matrix is a stabilizer. The first `n` columns represent whether this stabilizer contains a X operator on the physical qubit, and the last `n` columns represent whether this stabilizer contains a Z operator on the physical qubit.

The size of the logical operator matrix is `(k, n)`. `k` is the number of logical operators, and `n` is the number of physical qubits. Each row of the matrix is a logical operator.

### Inputs
- `code::QuantumCode`: The quantum code.
- `dirname::String`: The directory to save the data to.
- `filename::String`: The name of the file to save the data to.
"""
function generate_code_data(code::TensorQEC.QuantumCode,dirname::String,filename::String)
    mkpath(dirname)
    tanner = CSSTannerGraph(code)
    bimat = TensorQEC.stabilizers2bimatrix(stabilizers(code)).matrix
    lx,lz = logical_operator(tanner)
    data = Dict("code_name" => "$code", "qubit_num" => tanner.stgx.nq, "stabilizer_num" => size(bimat,1), "pcm" => Int.(vec(bimat)), "logical_x" => Int.(vec(lx)), "logical_z" => Int.(vec(lz)))
    write(joinpath(dirname, filename*".json"), JSON.json(data))
    return nothing
end