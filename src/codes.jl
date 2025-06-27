"""
    generate_code_data(code::QuantumCode,filename::String)

Save the parity check matrix and logical operators for the code `code` and save them. 
    
The parity check matrix is saved to `filename*"pcm.txt"` in the form of `(X|Z)`. The size of the matrix is `(s, 2*n)`. `s` is the number of stabilizers, and `n` is the number of physical qubits. Each row of the matrix is a stabilizer. The first `n` columns represent whether this stabilizer contains a X operator on the physical qubit, and the last `n` columns represent whether this stabilizer contains a Z operator on the physical qubit.

The logical operators are saved to `filename*"logical_x.txt"` and `filename*"logical_z.txt"`. The size of the matrix is `(k, n)`. `k` is the number of logical operators, and `n` is the number of physical qubits. Each row of the matrix is a logical operator.

### Inputs
- `code::QuantumCode`: The quantum code.
- `filename::String`: The directory to save the data to.
"""
function generate_code_data(code::TensorQEC.QuantumCode,filename::String)
    tanner = CSSTannerGraph(code)
    bimat = TensorQEC.stabilizers2bimatrix(stabilizers(code)).matrix
    writedlm(filename*"pcm.txt", Int.(bimat))
    lx,lz = logical_operator(tanner)

    writedlm(filename*"logical_x.txt",Int.(lx))
    writedlm(filename*"logical_z.txt",Int.(lz))
end