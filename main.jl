using CSV, DataFrames, DSP, FFTW, LaTeXStrings, Plots, Plots.Measures, Peaks, Random, Statistics

const voltages₁ = CSV.read("OData1.csv", DataFrame, header=10)
const voltages₂ = CSV.read("OData2.csv", DataFrame, header=10)
const voltages₃ = CSV.read("OData3.csv", DataFrame, header = 6)
const voltages₄ = CSV.read("OData4.csv", DataFrame, header = 6)

const fₘ = 1/3.42e-6
const fₙ = 1/6.86e-5
const beam_mass = 0.02012
const zeroed_voltage = 7.5e-3
const theoretical_stiffness = 288.351

function get_damping_ratio(y₁, yₙ, n)
    δ = log(y₁/yₙ)/(n-1)
    return δ/sqrt((4π^2+δ^2))
end

function get_strain(V::Real)
    return 2(V-zeroed_voltage)/10.5
end

function get_tension(V::Real)
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

function frequency_response(voltages, w, f)
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
        ylabel = L"\mathrm{Power \; \; Spectrum} \ (V^2)",
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
        ylabel = L"\mathrm{Power \; \; Spectrum} \ (V^2)",
        yscale = :log10
    )

    plot!(
        fₛ[i₂], 
        p₂[i₂],
        seriestype = :scatter,
        marker = :circle,
        label = L"\mathrm{Peaks}"
    )

    display(a)
    display(b)

    #savefig(a, "figures/plot_$(randstring(8)).svg")
    #savefig(b, "figures/plot_$(randstring(8)).svg")
end

function strain_series(voltages, α)
    v = voltages[!, "Channel 0"]
    t = voltages[!, "Time"]
    fs = (t[2] - t[1])^(-1)

    ϵ = get_strain.(v)
    ϵ_clean = filtfilt(digitalfilter(Lowpass(0.01), Butterworth(2)), ϵ)

    i, h = findmaxima(ϵ_clean, 25; strict=false) |> peakheights(; min=0.07)

    ω_d = 2π/mean(diff(t[i]))
    println("ω_d = $ω_d")

    y₁ = h[1]
    ζ = [get_damping_ratio.(y₁, h[n], n) for n in 2:length(h)]
    μ = mean(ζ)
    σ = std(ζ)

    # Print the first 20 (or fewer) values of zeta
    for i in 1:min(20, length(ζ))
        println("ζ[$i] = $(ζ[i])")
    end

    println("μ: $μ, σ: $σ")

    ω_n = 0
    if α
        ω_n = sqrt(theoretical_stiffness/(0.0074+beam_mass+.042))
    else
        ω_n = sqrt(theoretical_stiffness/(0.0074+beam_mass))
    end

    println("ω_n = $ω_n")

    a = plot(
        t[1:10:end], 
        ϵ[1:10:end],
        grid=false, 
        minorgrid=false,
        margin=5mm, 
        legendfontsize=10,
        tickfontsize = 10,
        label = L"\mathrm{Signal}",
        xlabel = L"\mathrm{Time} \ (s)",
        ylabel = L"\mathrm{Stain}",
        legend= :outertop,
        legendcolumns = 2,
        guidefontsize = 15,
    )

    plot!(
        t[i], 
        ϵ[i],
        seriestype = :scatter,
        marker = :circle,
        label = L"\mathrm{Peaks}"
    )
    
    display(a)
    
    #savefig(a, "figures/plot_$(randstring(8)).svg")
end

get_theoretical_frequencies(voltages₁)
frequency_response(voltages₁, 5, fₘ)
frequency_response(voltages₂, 150, fₙ)

strain_series(voltages₃, true)
strain_series(voltages₄, false)