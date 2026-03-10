using CSV, DataFrames, LaTeXStrings, Plots, Plots.Measures, Peaks, Statistics

const voltages₁ = CSV.read("OData1.csv", DataFrame, header=10)
const time₁ = voltages₁[!, "Time"]

const voltages₂ = CSV.read("OData2.csv", DataFrame, header=10)

function get_damping_ratio(yₙ, y₁, n)
    δ = log(y₁/yₙ)/(n-1)
    return δ/sqrt((4π^2+δ^2))
end

function get_strain(V, V₀)
    return 2(V-V₀)/(10.5)
end

function get_tension(V:: Real)
    return 261.66 * (V + 0.330)
end

function get_frequency(n::Int, T::Real)
    return n/3.1496 * sqrt(T/0.006805)
end

tensions₁ = get_tension.(voltages₁[!, "Channel 0"])
T̅₁ = mean(tensions₁)

freqs₀ = [get_frequency(n, T̅₁) for n in 1:4]
println(freqs₀)

fₛ = 1/0.00000171
fₘ = fₛ/2

freqsₙ = collect(range(0.004847867, fₘ, 100000))
powers₁ = voltages₁[!, "FFT 1"] .^ 2
powers₂ = voltages₁[!, "FFT 2"] .^ 2

mask = freqsₙ .< 200
f_sub = freqsₙ[mask]
p₁_sub = powers₁[mask]
p₂_sub = powers₂[mask]

indices, heights = findpeaks(p₁_sub; proms=(;min=2))
indices2, heights2 = findpeaks(p₂_sub; proms=(;min=2))

final_indices₁ = []
final_indices₂ = []

for f in freqs₀
    window = findall(x -> abs(x - f) < 10, f_sub)

    best_in_window₁ = window[argmax(p₁_sub[window])]
    best_in_window₂ = window[argmax(p₂_sub[window])]
    
    push!(final_indices₁, best_in_window₁)
    push!(final_indices₂, best_in_window₂)
end

f_final₁ = f_sub[final_indices₁]
f_final₂ = f_sub[final_indices₂]

println(f_final₁)
println(f_final₂)