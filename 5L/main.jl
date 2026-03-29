using CSV, DataFrames, Plots, Plots.Measures, Statistics, XLSX

const TRANSMISSION_RATIO = 3.16
const LHV_GASOLINE = 43400
const FT_LBF_TO_NM = 1.3558179483
const HP_TO_KW = 0.74570
const G_TO_KG = 1000.0
const S_PER_MIN = 60.0

struct EngineConditions
    dyno_rpm::Float64
    engine_rpm::Float64
    mass_start::Float64
    mass_end::Float64
    fuel_rate::Float64
    fuel_power::Float64
    dyno_power::Float64
    thermal_eff::Float64
    engine_torque::Float64
end

dyno_rpms = [600, 700, 800, 900, 1000, 1100]

data = Dict(rpm => CSV.read("EngineLabData2026/$(rpm)DynoRPM.csv", DataFrame, header=7) for rpm in dyno_rpms)
data = sort(data)

function build_engine_conditions(path::String)
    sheet = XLSX.readxlsx(path)["Sheet1"]
    conditions = EngineConditions[]

    for row in 3:8
        dyno_rpm = Float64(sheet["A$row"])
        dyno_torque = Float64(sheet["B$row"])
        dyno_power = Float64(sheet["C$row"])
        mass_start = Float64(sheet["D$row"])
        mass_end = Float64(sheet["E$row"])

        engine_rpm = TRANSMISSION_RATIO * dyno_rpm
        engine_torque = dyno_torque * FT_LBF_TO_NM / TRANSMISSION_RATIO

        dyno_power *= HP_TO_KW

        Δmass = (mass_end - mass_start)/1000

        fuel_rate = Δmass / S_PER_MIN
        fuel_power = abs(fuel_rate) * LHV_GASOLINE

        thermal_eff = dyno_power / fuel_power

        push!(conditions, EngineConditions(
            dyno_rpm, engine_rpm, mass_start, mass_end, fuel_rate, 
            fuel_power, dyno_power, thermal_eff, engine_torque
        ))
    end

    return sort(conditions; by = c -> c.engine_rpm)
 end

function plot_torque_power(conditions::Vector{EngineConditions})
    rpms = [condition.engine_rpm for condition in conditions]
    torques = [condition.engine_torque for condition in conditions]
    powers = [condition.dyno_power for condition in conditions]

    max_torque_idx = argmax(torques)
    max_power_idx = argmax(powers)

    max_torque = torques[max_torque_idx]
    max_power = powers[max_power_idx]

    max_t_val = round(max_torque, digits=2)
    max_p_val = round(max_power, digits=2)

    p = plot(rpms, torques,
        xlabel = "Engine Speed (RPM)",
        ylabel = "Brake Torque (Nm)",
        margin=5mm,
        color = :blue,
        linewidth=2,
        label = "Brake Torque",
        legend = :bottom,
        grid=false,
        minorgrid=false
    )

    plot!(p, [], [],
        label="Brake Power",
        linewidth = 2,
        color=:red
    )

    scatter!(p, [rpms[max_torque_idx]], [max_torque], color=:royalblue, label="Max Torque: $max_t_val Nm")
    scatter!(p, [], [], label="Max Power: $max_p_val kW", color=:firebrick)

    p2 = twinx(p)
    plot!(p2, rpms, powers,
        ylabel = "Brake Power (kW)",
        margin=5mm,
        color = :red,
        linewidth = 2,
        label = "",
    )

    scatter!(p2, [rpms[max_power_idx]], [max_power], color=:firebrick, label="")

    return p
 end

function plot_thermal_efficiency(conditions::Vector{EngineConditions})
    rpms = [condition.engine_rpm for condition in conditions]
    effs = [condition.thermal_eff for condition in conditions]

    max_idx = argmax(effs)

    plot(rpms, effs,
        linewidth = 2,
        marker=:dot,
        xlabel = "Engine Speed (RPM)",
        ylabel = "Thermal Efficiency",
        grid = false,
        minorgrid = false,
        margin=5mm,
        label="",
        ylims = [0.17, 0.27]
    )

    scatter!([rpms[max_idx]], [effs[max_idx]], label="Max Efficiency: $(round(effs[max_idx], digits=4))")
end

conditions = build_engine_conditions("EngineLabData2026/DynoData2026.xlsx")
 
p = plot_torque_power(conditions)
display(p)
#savefig(p, "figures/torque_power.svg")

p2 = plot_thermal_efficiency(conditions)
display(p2)
#savefig(p2, "figures/efficiency_speed.svg")