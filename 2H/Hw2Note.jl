### A Pluto.jl notebook ###
# v0.20.23

using Markdown
using InteractiveUtils

# ╔═╡ 9824c82d-8e0e-4ade-bcff-4759d75375ee
using BmlipTeachingTools, Distributions, Markdown, Measurements, Statistics

# ╔═╡ aaeb392f-3a26-434c-a76c-8ab2ec6a562c
title("ME 646 Homework 2")

# ╔═╡ 528d0286-ca3b-45fa-96c1-a734a0ee4b52
PlutoUI.TableOfContents()

# ╔═╡ 15f6be03-5d7e-4aed-8955-49f07e550637
md"""
## Problem 1
"""

# ╔═╡ 702d26f0-24d4-11f1-8cda-a705892b9869
# Problem 1

begin
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
P(m > 12) = $(round(ans_e, digits=8))
P(m < 8) = $(round(ans_f, digits=8))
P(m < 12) = $(round(ans_g, digits=4))"
	)
end

# ╔═╡ 687ab3a1-6de0-49de-bf24-060c3807729e
md"""
## Problem 2
"""

# ╔═╡ d11ac4d1-1629-49f4-8b50-9f8be3d61699
# Problem 2

begin
	m = [10.2, 8.2, 11.1, 9.8, 10.7, 10.1]
	n = length(m)
	
	μₘ = mean(m)
	σ = std(m)
	σ²_unbiased = var(m)
	σ²_biased = var(m; corrected=false)
	
	println(
    "μₘ = $(round(μₘ, digits=4))
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
end

# ╔═╡ d50f4e62-552e-414a-bc97-3be86e8bc684
md"""
For the best estimate of population mean, take $$\mu_m \approx 10.0167$$.

For the best estimate of population variance, take the unbiased $$\sigma^2 \approx 1.0057$$.
"""

# ╔═╡ 6d620ac8-4092-4fac-bdb3-e936879466d4
md"""
## Problem 3
"""

# ╔═╡ 6de10bf7-daf7-4b1e-9b56-9794ace4e73f
# Problem 3

begin
	σ_p = 0.4*sqrt(n)
	σ²_p = σ_p^2
	
	println("Population Variance: $σ²_p")
end

# ╔═╡ c291d31c-4238-4362-ae02-60d3781dc80e
md"""
This answer does not depend on an assumption that the underlying population distribution is normal. The **central limit theorem** states that the distribution of the sample mean converges to a Gaussian distribution as sample size $$n$$ increases. Because the variance of this distribution is finite and defined as:

$$\large \begin{aligned}
Var(\bar{X}) = \frac{\sigma^2}{n}, \quad \sigma^2 < \infty,
\end{aligned}$$

we can see that the variation, $$\sigma^2$$, does not depend on the assumption that the underlying population distribution is normal.
"""

# ╔═╡ 1806eb75-c1a4-42a7-88a6-044d54fcd6d4
md"""
## Problem 4
"""

# ╔═╡ 8797d033-8da9-4054-922b-997c7ad0891a
md"""
### Algebraic Solution
$$\large \begin{aligned}
&\sigma = \frac{4F}{\pi d^2} \\
&\Delta \sigma = \sqrt{ \left( \frac{\partial \sigma}{\partial F} \Delta F \right)^2 + \left( \frac{\partial \sigma}{\partial d} \Delta d \right)^2 } \\
&\frac{\partial \sigma}{\partial F} = \frac{4}{\pi d^2} \quad \text{and} \quad \frac{\partial \sigma}{\partial d} = -\frac{8F}{\pi d^3} \\
&\Delta \sigma = \sqrt{ \left( \frac{4}{\pi d^2} \Delta F \right)^2 + \left( -\frac{8F}{\pi d^3} \Delta d \right)^2 }
\end{aligned}$$
"""

# ╔═╡ d1f77012-91bf-459c-974c-113c56d17461
md"""
### Numeric Solution
"""

# ╔═╡ 4ca3b29b-ca9e-46c9-bbc4-5be58a871814
# Problem 4

begin
	dia = 0.012 ± 0.00001
	F = 8000 ± 50
	
	A = π/4 * dia^2
	σ₂ = F / 1e6A
	
	println("Tensile Strength: ", σ₂, " MPa")
end

# ╔═╡ acce8594-8bf7-4769-98fd-5cd2e23931b7
md"""
## Problem 5
"""

# ╔═╡ 1cc6039d-125d-41c4-afef-f9b2038d40e6
md"""
### Algebraic Solution
$$\begin{aligned}
&E = \frac{Fl}{wt\Delta l} \\
&\frac{\partial E}{\partial F} = \frac{l}{wt\Delta l}, \quad \frac{\partial E}{\partial l} = \frac{F}{wt\Delta l}, \quad \frac{\partial E}{\partial w} = -\frac{Fl}{w^2t\Delta l}, \\
&\frac{\partial E}{\partial t} = -\frac{Fl}{wt^2\Delta l}, \quad \frac{\partial E}{\partial \Delta l} = -\frac{Fl}{wt(\Delta l)^2} \\
&u_E = \sqrt{\left(\frac{\partial E}{\partial F} u_F\right)^2 + \left(\frac{\partial E}{\partial l} u_l\right)^2 + \left(\frac{\partial E}{\partial w} u_w\right)^2 + \left(\frac{\partial E}{\partial t} u_t\right)^2 + \left(\frac{\partial E}{\partial \Delta l} u_{\Delta l}\right)^2}
\end{aligned}$$
"""

# ╔═╡ e4497abc-4f2e-46d9-a7d1-5e34f13c8f5c
md"""
### Numeric Solution
"""

# ╔═╡ ad27555c-04b4-4f5e-87e8-af6c349c031b
# Problem 5

begin
	force = 1 ± (1 * 0.001)
	width = 25 ± 0.025
	thickness = 1 ± 0.025
	len = 75 ± 0.025
	Δlen = 0.075 ± 0.0001
	
	E = (force * len)/(width * thickness * Δlen)
	
	frac = Measurements.uncertainty(E)/Measurements.value(E)
	
	println("Fractional Uncertainty: ±$(round(frac, digits=4))")
end

# ╔═╡ 13e35384-0dd9-4e5e-9012-9972048d3ff2
md"""
To determine which component gives the largest contribution to the uncertainty in our Young's modulus $$E$$, we must determine the relative uncertainties $$\frac{\Delta x}{x}$$:

$$\large \begin{aligned}
&\text{Force}: 0.10\% \\
&\text{Width}: \frac{0.025}{25.0} = 0.10\% \\
&\text{Thickness}: \frac{0.025}{1.0} = 2.5\% \\
&\text{Length}: \frac{0.025}{75} = 0.033\% \\
&\text{Change in Length}: \frac{0.0001}{0.075} = 0.13\%
\end{aligned}$$

As can be seen, thickness $$t$$ with a relative uncertainty of $$2.5\%$$ is the largest contributor to uncertainty in $$E$$.
"""

# ╔═╡ f8df0531-1495-4231-a04b-a8a694a3c4e4
md"""
## Problem 6
"""

# ╔═╡ 370da28f-f11f-417c-a70c-7ba61cc31a9e
# Problem 6

begin
	mass = 5.2 ± 0.002
	⌀ = 0.0752 ± 0.00005
	L = 0.150 ± 0.001
	
	ρ = 4mass/(π * ⌀^2 * L)
	
	println("Density: ", ρ, " kg/m³")
end

# ╔═╡ 8831efa1-abac-477e-95f5-363c868148ab
md"""
## Note
If code is necessary for the grading process, please email me: [miles.zelasko@unh.edu](mailto:miles.zelasko@unh.edu).
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BmlipTeachingTools = "656a7065-6f73-6c65-7465-6e646e617262"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
BmlipTeachingTools = "~1.4.1"
Distributions = "~0.25.123"
Measurements = "~2.14.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.5"
manifest_format = "2.0"
project_hash = "58ac09abf7ebb493616f49b121a1a7d3d5752e18"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BmlipTeachingTools]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "PlutoTeachingTools", "PlutoUI", "Reexport"]
git-tree-sha1 = "721865ca80c702e053b7d3958c5de5295ad84eca"
uuid = "656a7065-6f73-6c65-7465-6e646e617262"
version = "1.4.1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9cb23bbb1127eefb022b022481466c0f1127d430"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.2"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "e357641bb3e0638d353c4b29ea0e40ea644066a6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.3"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "fbcc7610f6d8348428f722ecbe0e6cfe22e672c6"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.123"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2f979084d1e13948a3352cf64a25df6bd3b4dca3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.16.0"

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStaticArraysExt = "StaticArrays"
    FillArraysStatisticsExt = "Statistics"

    [deps.FillArrays.weakdeps]
    PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "68c173f4f449de5b438ee67ed0c9c748dc31a2ec"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.28"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6893345fd6658c8e475d40155789f4860ac3b21"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.4+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "Ghostscript_jll", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "44f93c47f9cd6c7e431f2f2091fcba8f01cd7e8f"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.10"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"
    TectonicExt = "tectonic_jll"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"
    tectonic_jll = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.Measurements]]
deps = ["Calculus", "LinearAlgebra", "Printf"]
git-tree-sha1 = "cb47f69a1cab9dcec7ff4a5d6e163410d6905866"
uuid = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
version = "2.14.1"

    [deps.Measurements.extensions]
    MeasurementsBaseTypeExt = "BaseType"
    MeasurementsJunoExt = "Juno"
    MeasurementsMakieExt = "Makie"
    MeasurementsRecipesBaseExt = "RecipesBase"
    MeasurementsSpecialFunctionsExt = "SpecialFunctions"
    MeasurementsUnitfulExt = "Unitful"

    [deps.Measurements.weakdeps]
    BaseType = "7fbed51b-1ef5-4d67-9085-a4a9b26f478c"
    Juno = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "e4cff168707d441cd6bf3ff7e4832bdf34278e4a"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.37"
weakdeps = ["StatsBase"]

    [deps.PDMats.extensions]
    StatsBaseExt = "StatsBase"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "90b41ced6bacd8c01bd05da8aed35c5458891749"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "fbc875044d82c113a9dee6fc14e16cf01fd48872"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.80"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9da16da70037ba9d701192e27befedefb91ec284"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.2"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "5b3d50eb374cea306873b371d3f8d3915a018f0b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.9.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5acc6a41b3082920f79ca3c759acbcecf18a8d78"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.7.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "aceda6f4e598d331548e04cc6b2124a6148138e3"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.10"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "91f091a8716a6bb38417a6e6f274602a19aaa685"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.2"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"
"""

# ╔═╡ Cell order:
# ╟─aaeb392f-3a26-434c-a76c-8ab2ec6a562c
# ╟─528d0286-ca3b-45fa-96c1-a734a0ee4b52
# ╟─15f6be03-5d7e-4aed-8955-49f07e550637
# ╟─702d26f0-24d4-11f1-8cda-a705892b9869
# ╟─687ab3a1-6de0-49de-bf24-060c3807729e
# ╟─d11ac4d1-1629-49f4-8b50-9f8be3d61699
# ╟─d50f4e62-552e-414a-bc97-3be86e8bc684
# ╟─6d620ac8-4092-4fac-bdb3-e936879466d4
# ╟─6de10bf7-daf7-4b1e-9b56-9794ace4e73f
# ╟─c291d31c-4238-4362-ae02-60d3781dc80e
# ╟─1806eb75-c1a4-42a7-88a6-044d54fcd6d4
# ╟─8797d033-8da9-4054-922b-997c7ad0891a
# ╟─d1f77012-91bf-459c-974c-113c56d17461
# ╟─4ca3b29b-ca9e-46c9-bbc4-5be58a871814
# ╟─acce8594-8bf7-4769-98fd-5cd2e23931b7
# ╟─1cc6039d-125d-41c4-afef-f9b2038d40e6
# ╟─e4497abc-4f2e-46d9-a7d1-5e34f13c8f5c
# ╟─ad27555c-04b4-4f5e-87e8-af6c349c031b
# ╟─13e35384-0dd9-4e5e-9012-9972048d3ff2
# ╟─f8df0531-1495-4231-a04b-a8a694a3c4e4
# ╟─370da28f-f11f-417c-a70c-7ba61cc31a9e
# ╟─8831efa1-abac-477e-95f5-363c868148ab
# ╟─9824c82d-8e0e-4ade-bcff-4759d75375ee
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
