using CSV, DataFrames, FFTW, LaTeXStrings, Plots, Plots.Measures, Peaks, Statistics

default(show=true)

const voltages₁ = CSV.read("OData1.csv", DataFrame, header=10)
const times₁ = voltages₁[!, "Time"]

const voltages₂ = CSV.read("OData2.csv", DataFrame, header=10)
const times₂ = voltages₂[!, "Time"]

const fₘ = 1/3.42e-6
const fₙ = 1/6.86e-5

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

function get_theoretical_frequencies(voltages)
    tensions = get_tension.(voltages[!, "Channel 0"])
    T̅ = mean(tensions)

    freqs₀ = [get_frequency(n, T̅) for n in 1:4]
    println("Theoretical Frequencies: ", freqs₀)
end

power_series = x -> abs.(rfft(x)).^2

function frequency_response(voltages, times, w, f)
    powers₁ = power_series(voltages[!, "Channel 0"])
    powers₂ = power_series(voltages[!, "Channel 1"])

    freqsₙ = rfftfreq(100000, f)
    
    mask = freqsₙ .< 220
    fₛ = freqsₙ[mask]
    p₁ = powers₁[mask]
    p₂ = powers₂[mask]

    i₁ = argmaxima(p₁, w; strict=true)
    i₂ = argmaxima(p₂, w; strict=true)
    println("Channel 0 Frequencies: ", fₛ[i₁])
    println("Channel 1 Frequencies: ", fₛ[i₂])

    a = plot(
        fₛ,
        p₁,
        grid=false, 
        minorgrid=false,
        margin=5mm, 
        legendfontsize=10,
        tickfontsize = 10,
        yformatter = :scientific,
        label = L"\mathrm{Signal}",
        legend= :outertop,
        legendcolumns = 2,
        guidefontsize = 15,
        xlabel = L"\mathrm{Frequency} \ (Hz)",
        ylabel = L"\mathrm{Power} \ (V^2)",
        yscale = :log10
    )

    plot!(
        fₛ[i₁], 
        p₁[i₁],
        seriestype = :scatter,
        marker = :circle,
        label = L"\mathrm{Peaks}"
    )

    b = plot(
        fₛ,
        p₂,
        grid=false, 
        minorgrid=false,
        margin=5mm, 
        legendfontsize=10,
        tickfontsize = 10,
        yformatter = :scientific,
        label = L"\mathrm{Signal}",
        legend= :outertop,
        legendcolumns = 2,
        guidefontsize = 15,
        xlabel = L"\mathrm{Frequency} \ (Hz)",
        ylabel = L"\mathrm{Power} \ (V^2)",
        yscale = :log10
    )

    plot!(
        fₛ[i₂], 
        p₂[i₂],
        seriestype = :scatter,
        marker = :circle,
        label = L"\mathrm{Peaks}"
    )

    return a, b
end

get_theoretical_frequencies(voltages₁)
frequency_response(voltages₁, times₁, 5, fₘ)
frequency_response(voltages₂, times₂, 150, fₙ)