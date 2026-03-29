using Distributions, Markdown, Measurements, Statistics

# problem 1
d = Normal(10, sqrt(0.2))

ans_a = cdf(d, 11) - cdf(d, 9)
ans_b = cdf(d, 10.1) - cdf(d, 9.9)
ans_c = cdf(d, 12) - cdf(d, 9)
ans_d = 1 - cdf(d, 10)
ans_e = 1 - cdf(d, 12)
ans_f = cdf(d, 8)
ans_g = cdf(d, 12)

println(
"P(9 < m < 11) = $(round(ans_a, digits=4))
P(9.9 < m < 10.1) = $(round(ans_b, digits=4))
P(9 < m < 12) = $(round(ans_c, digits=4))
P(m > 10) = $(round(ans_d, digits=4))
P(m > 12) = $(round(ans_e, digits=4))
P(m < 8) = $(round(ans_f, digits=4))
P(m < 12) = $(round(ans_g, digits=4))"
)

# problem 2
m = [10.2, 8.2, 11.1, 9.8, 10.7, 10.1]
n = length(m)

μₘ = mean(m)
σ = std(m)
σ²_unbiased = var(m)
σ²_biased = var(m; corrected=false)

println(
"\nμₘ = $(round(μₘ, digits=4))
σ²_unbiased = $(round(σ²_unbiased, digits=4))
σ²_biased = $(round(σ²_biased, digits=4))"
)


td = TDist(n-1)

t_crit(conf) = quantile(td, 1 - (1 - conf)/2)

ci90 = t_crit(0.90) * (σ)
ci95 = t_crit(0.95) * (σ)
ci99 = t_crit(0.99) * (σ / sqrt(n))

pi90 = t_crit(0.90) * σ * sqrt(1 + 1/n)
pi95 = t_crit(0.95) * σ * sqrt(1 + 1/n)
pi99 = t_crit(0.99) * σ * sqrt(1 + 1/n)

println(
"\n90% CI: $(round(μₘ, digits=4)) ± $(round(ci90, digits=4))
95% CI: $(round(μₘ, digits=4)) ± $(round(ci95, digits=4))
99% CI: $(round(μₘ, digits=4)) ± $(round(ci99, digits=4))
90% PI: $(round(μₘ, digits=4)) ± $(round(pi90, digits=4))
95% PI: $(round(μₘ, digits=4)) ± $(round(pi95, digits=4))
99% PI: $(round(μₘ, digits=4)) ± $(round(pi99, digits=4))"
)

# problem 3
σ_p = 0.4*sqrt(n)
σ²_p = σ_p^2

println("\nPopulation Variance: $σ²_p")

# problem 4
d = 0.012 ± 0.00001
F = 8000 ± 50

A = π/4 * d^2
σ₂ = F / 1e6A

println("\nTensile Strength: ", σ₂, " MPa")

# problem 5

force = 1 ± (1 * 0.001)
width = 25 ± 0.025
thickness = 1 ± 0.025
len = 75 ± 0.025
Δlen = 0.075 ± 0.0001

E = (force * len)/(width * thickness * Δlen)

frac = Measurements.uncertainty(E)/Measurements.value(E)

println("\nFractional Uncertainty: $(round(frac, digits=4))")


# problem 6

mass = 5.2 ± 0.002
⌀ = 0.0752 ± 0.00005
L = 0.150 ± 0.001

ρ = 4mass/(π * ⌀^2 * L)

println("\nDensity: ", ρ, " kg/m³")