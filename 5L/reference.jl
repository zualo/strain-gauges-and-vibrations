################################################################################
# ME 646, Spring 2026 — Lab 5: Internal Combustion Engine Analysis
# Kohler CH20S SI Engine on Eddy-Current Dynamometer
#
# Usage:
#   Place this file in the same directory as the data files, then run:
#       julia ME646_Lab5.jl
#
# Required packages (install once):
#   import Pkg
#   Pkg.add(["CSV", "DataFrames", "XLSX", "Statistics", "Plots"])
################################################################################

using CSV, DataFrames, XLSX, Statistics, Plots, Printf

# Use the GR backend for reliable PDF export; switch to "pyplot" or "gr" as needed.
gr()

################################################################################
# ── CONSTANTS & ENGINE SPECIFICATIONS ─────────────────────────────────────────
################################################################################

const TRANSMISSION_RATIO = 3.16        # engine_RPM = ratio × dyno_RPM; torque reversed
const BORE               = 0.077       # m
const STROKE             = 0.067       # m
const CONN_ROD_LENGTH    = 0.116       # m
const COMPRESSION_RATIO  = 8.5
const N_CYLINDERS        = 2
const LHV_GASOLINE       = 44.0e6     # J/kg, lower heating value of gasoline
const PSI_PER_VOLT       = 1.0/0.0104 # psi / V  (sensor: 1.04 pC/psi × 1 mV/pC × gain 10)
const PA_PER_PSI         = 6894.76    # Pa / psi
const FT_LBF_TO_NM       = 1.35582   # Nm / ft·lbf
const HP_TO_KW           = 0.74570   # kW / hp
const G_PER_KG           = 1000.0
const S_PER_MIN          = 60.0

# Derived geometry (computed once at module load)
const DISP_PER_CYL = (π / 4) * BORE^2 * STROKE          # m³ per cylinder
const V_CLEARANCE  = DISP_PER_CYL / (COMPRESSION_RATIO - 1)  # m³ (clearance vol.)
const V_MAX        = DISP_PER_CYL + V_CLEARANCE          # m³  at BDC
const V_MIN        = V_CLEARANCE                         # m³  at TDC

################################################################################
# ── DATA STRUCTURES ───────────────────────────────────────────────────────────
################################################################################

"""Consolidated per-speed dynamometer results (Deliverables 1–3)."""
struct EngineCondition
    dyno_rpm      ::Float64
    engine_rpm    ::Float64
    mass_begin    ::Float64   # kg  (tank + fuel at start of interval)
    mass_end      ::Float64   # kg  (tank + fuel at end of interval)
    fuel_rate     ::Float64   # kg/s
    fuel_power    ::Float64   # kW  (chemical power in fuel flow)
    dyno_power    ::Float64   # kW  (brake power from dynamometer)
    thermal_eff   ::Float64   # –   (brake thermal efficiency)
    engine_torque ::Float64   # Nm  (corrected for transmission)
end

"""P-V work integration results for one engine speed (Deliverable 7)."""
struct CycleIntegration
    engine_rpm   ::Float64
    work_mean    ::Float64   # J  per thermodynamic cycle per cylinder
    work_std     ::Float64   # J
    power_mean   ::Float64   # kW per thermodynamic cycle per cylinder
    power_std    ::Float64   # kW
    dyno_power   ::Float64   # kW (brake, from dynamometer)
    engine_power ::Float64   # kW (indicated, 2-cylinder, from P-V)
    mech_eff     ::Float64   # –  (dyno_power / engine_power)
end

################################################################################
# ── FILE I/O ──────────────────────────────────────────────────────────────────
################################################################################

"""
    read_dyno_csv(path) -> (dt, optical, pressure_v)

Parse an NI-DAQ CSV with the following layout:

    Row 1 : "Meta data"  (may begin with UTF-8 BOM)
    Row 2 : column header for metadata
    Row 3 : Channel 0  name, start_time, sample_interval, sample_count
    Row 4 : Channel 1  metadata (same interval)
    Row 5 : blank
    Row 6 : "Data"
    Row 7 : "Channel 0 …, Channel 1 …"
    Rows 8+: data values (Channel 0 = pressure V, Channel 1 = optical V)

Returns
- `dt`         – sample interval (s)
- `optical`    – optical sensor voltage vector
- `pressure_v` – pressure sensor voltage vector
"""
function read_dyno_csv(path::String)
    lines = readlines(path)

    # Extract sample interval from Channel 0 metadata (row 3, index 3 in 1-based)
    meta_row = split(lines[3], ',')
    dt = parse(Float64, strip(meta_row[3]))

    # Data begins at row 8 (index 8)
    optical    = Float64[]
    pressure_v = Float64[]
    for i in 8:length(lines)
        row = strip(lines[i])
        isempty(row) && continue
        parts = split(row, ',')
        length(parts) < 2 && continue
        push!(pressure_v, parse(Float64, parts[1]))
        push!(optical,    parse(Float64, parts[2]))
    end

    return dt, optical, pressure_v
end

"""
    build_engine_conditions(xlsx_path) -> Vector{EngineCondition}

Read the XLSX dynamometer summary table and return one `EngineCondition`
per speed, sorted by ascending engine RPM.

Expected XLSX layout (Sheet1):
    Row 1: title
    Row 2: headers (Dyno RPM | Dyno torque ft-lbf | Dyno Power HP |
                     Beginning fuel wt g | Ending fuel wt g)
    Rows 3–8: one speed per row
"""
function build_engine_conditions(xlsx_path::String)
    wb = XLSX.readxlsx(xlsx_path)
    sh = wb["Sheet1"]

    conditions = EngineCondition[]
    for row in 3:8
        dyno_rpm            = Float64(sh["A$row"])
        dyno_torque_ftlbf   = Float64(sh["B$row"])
        dyno_power_hp       = Float64(sh["C$row"])
        begin_g             = Float64(sh["D$row"])
        end_g               = Float64(sh["E$row"])

        engine_rpm    = TRANSMISSION_RATIO * dyno_rpm
        dyno_power_kw = dyno_power_hp * HP_TO_KW

        # Through a gearbox: P_in = P_out  →  T_engine × ω_engine = T_dyno × ω_dyno
        # T_engine = T_dyno × (ω_dyno / ω_engine) = T_dyno / TRANSMISSION_RATIO
        engine_torque = dyno_torque_ftlbf * FT_LBF_TO_NM / TRANSMISSION_RATIO

        mass_begin = begin_g / G_PER_KG
        mass_end   = end_g   / G_PER_KG
        fuel_rate  = (mass_begin - mass_end) / S_PER_MIN   # kg/s (1-minute interval)
        fuel_power = fuel_rate * LHV_GASOLINE / 1000        # kW

        thermal_eff = dyno_power_kw / fuel_power

        push!(conditions, EngineCondition(
            dyno_rpm, engine_rpm, mass_begin, mass_end,
            fuel_rate, fuel_power, dyno_power_kw, thermal_eff, engine_torque
        ))
    end

    return sort(conditions; by = c -> c.engine_rpm)
end

################################################################################
# ── SIGNAL PROCESSING ─────────────────────────────────────────────────────────
################################################################################

"""
    find_tdc_indices(optical, dt; debounce_s) -> Vector{Int}

Detect rising-edge threshold crossings of the optical TDC sensor, with a
minimum debounce gap between successive detected events to suppress noise.

Returns a vector of sample indices (1-based) at each detected TDC.
"""
function find_tdc_indices(optical::AbstractVector{Float64}, dt::Float64;
                          debounce_s::Float64 = 0.005)
    lo, hi    = extrema(optical)
    threshold = lo + 0.5 * (hi - lo)
    debounce  = round(Int, debounce_s / dt)

    crossings = Int[]
    for i in 2:length(optical)
        if optical[i-1] <= threshold < optical[i]
            if isempty(crossings) || (i - last(crossings)) > debounce
                push!(crossings, i)
            end
        end
    end
    return crossings
end

################################################################################
# ── ENGINE GEOMETRY ───────────────────────────────────────────────────────────
################################################################################

"""
    cylinder_volume(theta) -> Float64

Cylinder volume (m³) as a function of crank angle θ (radians, 0 = TDC).
Uses the full slider-crank geometric relation:

    x(θ) = R(1 − cos θ) + L(1 − √(1 − (R/L · sin θ)²))
    V(θ) = V_clearance + (π/4)·B² · x(θ)

where R = stroke/2, L = connecting rod length, B = bore.
"""
function cylinder_volume(theta::Float64)
    R  = STROKE / 2
    L  = CONN_ROD_LENGTH
    x  = R * (1 - cos(theta)) + L * (1 - sqrt(max(0.0, 1 - (R / L * sin(theta))^2)))
    return V_CLEARANCE + (π / 4) * BORE^2 * x
end

# Broadcast-friendly scalar version
cylinder_volume(theta::AbstractVector) = cylinder_volume.(theta)

"""
    pressure_mpa(voltage) -> same shape

Convert raw pressure sensor voltage to pressure in MPa.
Sensor chain: piezo (1.04 pC/psi) → charge amp (1 mV/pC) → conditioner (gain 10)
→ net 0.0104 V/psi.
"""
pressure_mpa(v) = v .* (PSI_PER_VOLT * PA_PER_PSI / 1e6)

"""
    continuous_crank_angle(n, tdc_indices, dt, engine_rpm) -> Vector{Float64}

Build a continuous crank-angle time series (radians) across n samples.
Angle is set to 0 at each TDC index and increases linearly between pulses
(with linear interpolation for fractional revolution timing).

Returns a vector of length n; entries before the first TDC are NaN.
"""
function continuous_crank_angle(n::Int,
                                tdc_indices::AbstractVector{Int},
                                dt::Float64,
                                engine_rpm::Float64)
    ω  = 2π * engine_rpm / 60.0   # rad/s
    θ  = fill(NaN, n)

    for k in 1:(length(tdc_indices) - 1)
        i_start = tdc_indices[k]
        i_stop  = tdc_indices[k + 1] - 1
        # Actual revolution period from optical pulses (accounts for speed variation)
        T_rev = (tdc_indices[k + 1] - tdc_indices[k]) * dt
        ω_local = 2π / T_rev
        for i in i_start:i_stop
            θ[i] = ω_local * (i - i_start) * dt
        end
    end
    # Fill trailing segment after last TDC using nominal ω
    if !isempty(tdc_indices)
        i_last = last(tdc_indices)
        for i in i_last:n
            θ[i] = ω * (i - i_last) * dt
        end
    end
    return θ
end

################################################################################
# ── CYCLE EXTRACTION ──────────────────────────────────────────────────────────
################################################################################

"""
    extract_mechanical_cycles(tdc_indices, n; settle) -> Vector{UnitRange{Int}}

Return `n` consecutive index ranges, each spanning one mechanical cycle
(TDC[k] to TDC[k+1]-1), starting `settle` cycles after the first detected TDC.

Each pair of returned ranges constitutes one four-stroke thermodynamic cycle.
"""
function extract_mechanical_cycles(tdc_indices::AbstractVector{Int},
                                   n::Int;
                                   settle::Int = 5)
    k0 = min(settle + 1, length(tdc_indices) - n)
    return [tdc_indices[k]:(tdc_indices[k + 1] - 1)
            for k in k0:(k0 + n - 1)]
end

################################################################################
# ── P-V WORK INTEGRATION ─────────────────────────────────────────────────────
################################################################################

"""
    pv_work(V, P_mpa) -> Float64

Numerically integrate ∮ P dV over one closed thermodynamic cycle using the
trapezoidal rule.  Returns net work (J); positive = net work output.
"""
function pv_work(V::AbstractVector{Float64}, P_mpa::AbstractVector{Float64})
    P_pa = P_mpa .* 1e6
    dV   = diff(V)
    P_mid = (P_pa[1:end-1] .+ P_pa[2:end]) ./ 2
    return sum(P_mid .* dV)
end

################################################################################
# ── DELIVERABLE 1: SUMMARY TABLE ─────────────────────────────────────────────
################################################################################

function print_summary_table(conditions::Vector{EngineCondition})
    println("\n" * "="^110)
    println("DELIVERABLE 1 — Engine Performance Summary Table")
    println("="^110)
    hdr = @sprintf("%-13s  %-14s  %-13s  %-16s  %-16s  %-16s  %-13s  %-12s",
        "Engine RPM", "Begin Mass(kg)", "End Mass(kg)",
        "Fuel Rate(kg/s)", "Fuel Power(kW)", "Dyno Power(kW)",
        "Therm. Eff.", "Torque(Nm)")
    println(hdr)
    println("-"^110)
    for c in conditions
        println(@sprintf("%-13.0f  %-14.4f  %-13.4f  %-16.5f  %-16.2f  %-16.2f  %-13.4f  %-12.2f",
            c.engine_rpm, c.mass_begin, c.mass_end,
            c.fuel_rate, c.fuel_power, c.dyno_power,
            c.thermal_eff, c.engine_torque))
    end
    println("="^110)
end

################################################################################
# ── DELIVERABLE 2: TORQUE & POWER vs. RPM ────────────────────────────────────
################################################################################

"""
Dual-y-axis (yy) plot of brake torque (Nm) and brake power (kW) vs. engine
speed.  Data points are marked with symbols and connected with lines.
Maximum values for both quantities are annotated on the plot.
"""
function plot_torque_power(conditions::Vector{EngineCondition})
    rpms    = [c.engine_rpm    for c in conditions]
    torques = [c.engine_torque for c in conditions]
    powers  = [c.dyno_power    for c in conditions]

    i_max_t = argmax(torques)
    i_max_p = argmax(powers)

    p = plot(rpms, torques;
        label       = "Brake Torque",
        marker      = :circle, markersize = 6,
        linewidth   = 2, color = :royalblue,
        xlabel      = "Engine Speed (RPM)",
        ylabel      = "Brake Torque (Nm)",
        title       = "Brake Torque and Power vs. Engine Speed",
        legend      = :bottomleft,
        grid        = true,
        size        = (800, 500))

    # Annotate max torque
    annotate!(p, rpms[i_max_t], torques[i_max_t] + 1.5,
        text(@sprintf("Max: %.1f Nm\n@ %.0f RPM", torques[i_max_t], rpms[i_max_t]),
             :center, 9, :royalblue))

    # Power on twin axis
    p2 = twinx(p)
    plot!(p2, rpms, powers;
        label      = "Brake Power",
        marker     = :square, markersize = 6,
        linewidth  = 2, color = :firebrick,
        ylabel     = "Brake Power (kW)",
        legend     = :bottomright)

    annotate!(p2, rpms[i_max_p], powers[i_max_p] + 0.3,
        text(@sprintf("Max: %.1f kW\n@ %.0f RPM", powers[i_max_p], rpms[i_max_p]),
             :center, 9, :firebrick))

    return p
end

################################################################################
# ── DELIVERABLE 3: THERMAL EFFICIENCY vs. RPM ────────────────────────────────
################################################################################

function plot_thermal_efficiency(conditions::Vector{EngineCondition})
    rpms = [c.engine_rpm  for c in conditions]
    effs = [c.thermal_eff for c in conditions]

    plot(rpms, effs;
        marker     = :diamond, markersize = 7,
        linewidth  = 2, color = :forestgreen,
        xlabel     = "Engine Speed (RPM)",
        ylabel     = "Brake Thermal Efficiency (−)",
        title      = "Brake Thermal Efficiency vs. Engine Speed",
        ylims      = (0.0, 0.40),
        legend     = false,
        grid       = true,
        size       = (700, 450))
end

################################################################################
# ── DELIVERABLE 4: THREE-PANEL TIME-SERIES SUBPLOTS ──────────────────────────
################################################################################

"""
    plot_time_series_subplots(dt, optical, pressure_v, tdc_indices, engine_rpm, dyno_rpm)

Three vertically stacked yy subplots covering five thermodynamic cycles
(ten mechanical cycles / revolutions):
  Panel 1 — optical sensor voltage (norm.) + crank angle (rad)
  Panel 2 — optical sensor voltage (norm.) + cylinder volume (cm³)
  Panel 3 — optical sensor voltage (norm.) + pressure (MPa)
"""
function plot_time_series_subplots(dt::Float64,
                                   optical::AbstractVector{Float64},
                                   pressure_v::AbstractVector{Float64},
                                   tdc_indices::AbstractVector{Int},
                                   engine_rpm::Float64,
                                   dyno_rpm::Int)
    n_mech      = 10   # 10 mechanical cycles = 5 thermodynamic cycles
    mech_cycles = extract_mechanical_cycles(tdc_indices, n_mech)

    # Index range covering all selected cycles
    i_start = first(first(mech_cycles))
    i_stop  = last(last(mech_cycles))
    seg     = i_start:i_stop

    n_total  = length(optical)
    θ_all    = continuous_crank_angle(n_total, tdc_indices, dt, engine_rpm)

    t_vec    = range(0.0; step = dt, length = length(seg))
    opt_seg  = optical[seg]
    pres_seg = pressure_v[seg]
    θ_seg    = θ_all[seg]
    V_seg    = cylinder_volume.(θ_seg)
    P_seg    = pressure_mpa(pres_seg)

    # Normalise optical by its maximum absolute value for overlay clarity
    opt_norm = opt_seg ./ maximum(abs.(opt_seg))

    title_base = @sprintf("Engine %.0f RPM (Dyno %d RPM) — 5 Thermodynamic Cycles",
                           engine_rpm, dyno_rpm)

    # ── Panel 1: crank angle ───────────────────────────────────────────────
    p1 = plot(t_vec, opt_norm;
        label = "Optical (norm.)", color = :grey60, alpha = 0.7, linewidth = 0.8,
        ylabel = "Value (−)", title = title_base * "\nPanel 1: Crank Angle",
        legend = :topright, grid = true, xlabel = "")
    p1b = twinx(p1)
    plot!(p1b, t_vec, θ_seg;
        label = "Crank Angle (rad)", color = :royalblue, linewidth = 1.5,
        ylabel = "Crank Angle (rad)", legend = :topleft)

    # ── Panel 2: cylinder volume ───────────────────────────────────────────
    p2 = plot(t_vec, opt_norm;
        label = "Optical (norm.)", color = :grey60, alpha = 0.7, linewidth = 0.8,
        ylabel = "Value (−)", title = "Panel 2: Cylinder Volume",
        legend = :topright, grid = true, xlabel = "")
    p2b = twinx(p2)
    plot!(p2b, t_vec, V_seg .* 1e6;     # convert m³ → cm³ for readability
        label = "Volume (cm³)", color = :darkorange, linewidth = 1.5,
        ylabel = "Cylinder Volume (cm³)", legend = :topleft)

    # ── Panel 3: pressure ──────────────────────────────────────────────────
    p3 = plot(t_vec, opt_norm;
        label = "Optical (norm.)", color = :grey60, alpha = 0.7, linewidth = 0.8,
        ylabel = "Value (−)", title = "Panel 3: Cylinder Pressure",
        legend = :topright, grid = true, xlabel = "Time (s)")
    p3b = twinx(p3)
    plot!(p3b, t_vec, P_seg;
        label = "Pressure (MPa)", color = :firebrick, linewidth = 1.5,
        ylabel = "Pressure (MPa)", legend = :topleft)

    return plot(p1, p2, p3;
        layout        = (3, 1),
        size          = (900, 1100),
        left_margin   = 12Plots.mm,
        right_margin  = 12Plots.mm,
        top_margin    =  6Plots.mm,
        bottom_margin =  6Plots.mm)
end

################################################################################
# ── DELIVERABLE 5: SINGLE P-V CYCLE ──────────────────────────────────────────
################################################################################

"""
Plot P (MPa) vs. V (cm³) for one representative thermodynamic cycle
(cycles 4–5, i.e. mechanical cycles 7–8 out of 10 extracted).
"""
function plot_pv_single(dt::Float64,
                        optical::AbstractVector{Float64},
                        pressure_v::AbstractVector{Float64},
                        tdc_indices::AbstractVector{Int},
                        engine_rpm::Float64,
                        dyno_rpm::Int)
    n_total     = length(optical)
    θ_all       = continuous_crank_angle(n_total, tdc_indices, dt, engine_rpm)
    mech_cycles = extract_mechanical_cycles(tdc_indices, 10)

    # Thermodynamic cycle 4 = mechanical cycles 7 & 8 (0-indexed: pairs 0-1, 2-3, 4-5, 6-7, 8-9)
    rng = first(mech_cycles[7]):last(mech_cycles[8])
    V   = cylinder_volume.(θ_all[rng]) .* 1e6          # cm³
    P   = pressure_mpa(pressure_v[rng])

    plot(V, P;
        label     = "Thermodynamic Cycle 4",
        linewidth = 2, color = :royalblue,
        xlabel    = "Cylinder Volume (cm³)",
        ylabel    = "Pressure (MPa)",
        title     = @sprintf("P-V Diagram — Single Cycle  (Engine %.0f RPM)", engine_rpm),
        legend    = :topright,
        grid      = true,
        size      = (650, 500))
end

################################################################################
# ── DELIVERABLE 6: ALL P-V CYCLES OVERLAY ────────────────────────────────────
################################################################################

"""
Overlay all available thermodynamic-cycle P-V traces in the dataset at a
single engine speed.  Pairs of mechanical cycles form each thermodynamic loop.
"""
function plot_pv_all(dt::Float64,
                     optical::AbstractVector{Float64},
                     pressure_v::AbstractVector{Float64},
                     tdc_indices::AbstractVector{Int},
                     engine_rpm::Float64,
                     dyno_rpm::Int)
    n_total  = length(optical)
    θ_all    = continuous_crank_angle(n_total, tdc_indices, dt, engine_rpm)

    # Use all pairs of consecutive mechanical cycles (settle 2 at the start)
    n_avail  = length(tdc_indices) - 1 - 2       # leave a 2-cycle settling buffer
    n_pairs  = div(n_avail, 2)                    # number of full thermodynamic cycles
    n_mech   = n_pairs * 2
    mech_all = extract_mechanical_cycles(tdc_indices, n_mech; settle = 2)

    p = plot(;
        title  = @sprintf("All P-V Cycles  (Engine %.0f RPM, %d thermo cycles)",
                           engine_rpm, n_pairs),
        xlabel = "Cylinder Volume (cm³)",
        ylabel = "Pressure (MPa)",
        legend = false,
        grid   = true,
        size   = (650, 500))

    for j in 1:2:length(mech_all)-1
        rng = first(mech_all[j]):last(mech_all[j + 1])
        V   = cylinder_volume.(θ_all[rng]) .* 1e6
        P   = pressure_mpa(pressure_v[rng])
        plot!(p, V, P; color = :royalblue, alpha = 0.20, linewidth = 0.6)
    end
    return p
end

################################################################################
# ── DELIVERABLE 7: P-V WORK TABLE ────────────────────────────────────────────
################################################################################

"""
    compute_pv_table(csv_paths, conditions) -> Vector{CycleIntegration}

For each engine speed, integrate ∮ P dV over five thermodynamic cycles
(ten mechanical cycles) and return statistics.

The four-stroke cycle frequency is  f_cycle = ω_engine / (2 × 2π) = n_engine / 2
(one thermodynamic cycle per two crankshaft revolutions per cylinder).
"""
function compute_pv_table(csv_paths::Dict{Int,String},
                          conditions::Vector{EngineCondition})
    results = CycleIntegration[]

    for cond in conditions
        dyno_rpm = Int(cond.dyno_rpm)
        dt, optical, pressure_v = read_dyno_csv(csv_paths[dyno_rpm])

        engine_rpm  = cond.engine_rpm
        tdc_indices = find_tdc_indices(optical, dt)
        n_total     = length(optical)
        θ_all       = continuous_crank_angle(n_total, tdc_indices, dt, engine_rpm)

        # Extract 10 mechanical cycles → 5 thermodynamic cycles
        mech_cycles = extract_mechanical_cycles(tdc_indices, 10)

        thermo_works = Float64[]
        for j in 1:2:length(mech_cycles)-1      # step by 2: each pair = one thermo cycle
            rng = first(mech_cycles[j]):last(mech_cycles[j + 1])
            V   = cylinder_volume.(θ_all[rng])
            P   = pressure_mpa(pressure_v[rng])
            W   = pv_work(V, P)
            push!(thermo_works, W)
        end

        work_mean = mean(thermo_works)
        work_std  = std(thermo_works)

        # Cycle frequency: one thermodynamic cycle per 2 crankshaft revolutions per cylinder
        f_cycle    = engine_rpm / 60.0 / 2.0     # Hz (thermo cycles per second per cylinder)
        power_mean = work_mean * f_cycle / 1e3   # kW per (thermo-cycle · cylinder)
        power_std  = work_std  * f_cycle / 1e3

        # Full engine indicated power: sum over both cylinders
        engine_power_kw = work_mean * f_cycle * N_CYLINDERS / 1e3

        mech_eff = cond.dyno_power / engine_power_kw

        push!(results, CycleIntegration(
            engine_rpm, work_mean, work_std,
            power_mean, power_std,
            cond.dyno_power, engine_power_kw, mech_eff))
    end
    return results
end

function print_pv_table(results::Vector{CycleIntegration})
    println("\n" * "="^120)
    println("DELIVERABLE 7 — P-V Work Integration Table")
    println("="^120)
    hdr = @sprintf("%-13s  %-12s  %-10s  %-12s  %-12s  %-12s  %-12s  %-10s",
        "Engine RPM",
        "W_mean (J)", "W_std (J)",
        "P_mean (kW)", "P_std (kW)",
        "P_dyno (kW)", "P_eng (kW)", "η_mech")
    println(hdr)
    println("-"^120)
    for r in results
        println(@sprintf("%-13.0f  %-12.2f  %-10.2f  %-12.4f  %-12.4f  %-12.2f  %-12.2f  %-10.4f",
            r.engine_rpm,
            r.work_mean,  r.work_std,
            r.power_mean, r.power_std,
            r.dyno_power, r.engine_power, r.mech_eff))
    end
    println("="^120)
end

################################################################################
# ── MAIN ──────────────────────────────────────────────────────────────────────
################################################################################

function main()
    # ── Resolve file paths ─────────────────────────────────────────────────
    # Assumes all data files are in the same directory as this script.
    data_dir  = dirname(abspath(@__FILE__))
    xlsx_path = joinpath(data_dir, "EngineLabData2026/DynoData2026.xlsx")
    dyno_rpms = [600, 700, 800, 900, 1000, 1100]
    csv_paths = Dict(rpm => joinpath(data_dir, "EngineLabData2026/$(rpm)DynoRPM.csv")
                     for rpm in dyno_rpms)

    fig_dir = joinpath(data_dir, "figures")
    mkpath(fig_dir)
    fig(name) = joinpath(fig_dir, name)

    # ── Load dynamometer summary data ──────────────────────────────────────
    conditions = build_engine_conditions(xlsx_path)

    # ══════════════════════════════════════════════════════════════════════
    # DELIVERABLE 1 — Print summary table
    # ══════════════════════════════════════════════════════════════════════
    print_summary_table(conditions)

    # ══════════════════════════════════════════════════════════════════════
    # DELIVERABLE 2 — Torque & power vs. RPM
    # ══════════════════════════════════════════════════════════════════════
    p2 = plot_torque_power(conditions)
    savefig(p2, fig("D2_torque_power.pdf"))
    println("\nSaved → D2_torque_power.pdf")

    # ══════════════════════════════════════════════════════════════════════
    # DELIVERABLE 3 — Brake thermal efficiency vs. RPM
    # ══════════════════════════════════════════════════════════════════════
    p3 = plot_thermal_efficiency(conditions)
    savefig(p3, fig("D3_thermal_efficiency.pdf"))
    println("Saved → D3_thermal_efficiency.pdf")

    # ══════════════════════════════════════════════════════════════════════
    # DELIVERABLES 4–6: pick one engine speed (800 dyno RPM = 2528 engine RPM)
    # ══════════════════════════════════════════════════════════════════════
    chosen_dyno_rpm = 800
    chosen_cond = conditions[findfirst(c -> Int(c.dyno_rpm) == chosen_dyno_rpm, conditions)]
    dt, optical, pressure_v = read_dyno_csv(csv_paths[chosen_dyno_rpm])
    tdc_indices = find_tdc_indices(optical, dt)
    eng_rpm     = chosen_cond.engine_rpm

    # DELIVERABLE 4 — Time-series subplots
    p4 = plot_time_series_subplots(dt, optical, pressure_v, tdc_indices,
                                   eng_rpm, chosen_dyno_rpm)
    savefig(p4, fig("D4_time_series.pdf"))
    println("Saved → D4_time_series.pdf")

    # DELIVERABLE 5 — Single representative P-V cycle
    p5 = plot_pv_single(dt, optical, pressure_v, tdc_indices, eng_rpm, chosen_dyno_rpm)
    savefig(p5, fig("D5_pv_single.pdf"))
    println("Saved → D5_pv_single.pdf")

    # DELIVERABLE 6 — All P-V cycles overlaid
    p6 = plot_pv_all(dt, optical, pressure_v, tdc_indices, eng_rpm, chosen_dyno_rpm)
    savefig(p6, fig("D6_pv_all.pdf"))
    println("Saved → D6_pv_all.pdf")

    # ══════════════════════════════════════════════════════════════════════
    # DELIVERABLE 7 — P-V work integration table
    # ══════════════════════════════════════════════════════════════════════
    pv_results = compute_pv_table(csv_paths, conditions)
    print_pv_table(pv_results)

    println("\nAll deliverables complete.  Figures written to: $fig_dir\n")
    return conditions, pv_results
end

main()