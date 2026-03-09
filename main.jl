using CSV, DataFrames, LaTeXStrings, Plots, Plots.Measures, Peaks

const voltages₁ = CSV.read("OData1.csv", DataFrame, header=10)
const voltages₂ = CSV.read("OData2.csv", DataFrame, header=10)

function get_damping_ratio(yₙ, y₁, n)
    δ = log(y₁/yₙ)/(n-1)
    return δ/sqrt((4π^2+δ^2))
end

function get_strain(V, V₀)
    return 2(V-V₀)/(10.5)
end

function get_tension(V)
    return 261.66.*V
end

function get_frequency(T::Real, n::Int)
    return n/3.1496 * sqrt(T/0.006805)
end
<<<<<<< HEAD

show(first(voltages₁, 5), allcols=true)
=======
>>>>>>> 35fffdb (Updated main.jl)
