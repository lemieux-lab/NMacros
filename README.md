# NMacros
 
A Julia package providing convenient macros for quick data visualization and benchmarking, built on top of [CairoMakie](https://docs.makie.org/stable/). Designed to minimize boilerplate in interactive and notebook environments.
 
## Installation
 
This package is registered in [LabRegistry](https://github.com/lemieux-lab/LabRegistry)

```julia
# With LabRegistry added in julia registry
] add NMacros

# Otherwise
] add https://github.com/lemieux-lab/NMacros
```
 
## Overview
 
Each plotting macro follows the same pattern: you declare which variable(s) to plot, then provide a `begin...end` block of code to run. After the block executes, the macro captures the named variables and produces a Makie `Figure`.
 
```julia
@nmacro var_name begin
    # your code here : var_name is defined in this block
end
```
 
The returned `Figure` can be displayed directly in a notebook or saved with `save("output.png", fig)`.
 
## Variable Naming Convention
 
By default, most macros fall back to `n_x`, `n_y`, or `n_z` if no variable name is provided. This is just a naming convention : any variable can be used by passing it explicitly.
 
```julia
# These two are equivalent:
@nscatter begin
    n_x = 1:10
    n_y = rand(10)
end
 
@nscatter n_x n_y begin
    n_x = 1:10
    n_y = rand(10)
end
```
 
## Macros
 
### `@nscatter` : Scatter Plot
 
Plots one or more y series as scattered points against a common x axis.
 
```julia
@nscatter x_var y_var  begin ... end   # single y
@nscatter x_var [y1, y2, ...] begin ... end  # multiple y series
@nscatter x_var begin ... end          # y defaults to n_y
@nscatter begin ... end                # x defaults to n_x, y to n_y
```
 
**Example:**
```julia
fig = @nscatter n_x [n_sin, n_cos] begin
    n_x   = range(0, 2π, length=100)
    n_sin = sin.(n_x)
    n_cos = cos.(n_x)
end
```
 
---
 
### `@nlines` : Line Plot
 
Same interface as `@nscatter`, but draws connected lines instead of points.
 
```julia
@nlines x_var y_var begin ... end
@nlines x_var [y1, y2, ...] begin ... end
@nlines x_var begin ... end
@nlines begin ... end
```
 
**Example:**
```julia
fig = @nlines n_x n_y begin
    n_x = 1:50
    n_y = cumsum(randn(50))
end
```
 
---
 
### `@nscatterlines` : Scatter + Line Plot
 
Combines scattered points with connecting lines. Same interface as `@nscatter`.
 
```julia
@nscatterlines x_var y_var begin ... end
@nscatterlines x_var [y1, y2, ...] begin ... end
@nscatterlines x_var begin ... end
@nscatterlines begin ... end
```
 
**Example:**
```julia
fig = @nscatterlines n_x n_y begin
    n_x = 1:20
    n_y = n_x .^ 2
end
```
 
---
 
### `@nhist` : Histogram
 
Plots the distribution of a single variable.
 
```julia
@nhist y_var begin ... end
@nhist begin ... end          # y defaults to n_y
```
 
**Example:**
```julia
fig = @nhist n_y begin
    n_y = randn(1_000)
end
```
 
---
 
### `@nboxplot` : Box Plot
 
Plots one or more datasets as labeled box plots on a categorical axis.
 
```julia
@nboxplot y_var begin ... end
@nboxplot [y1, y2, ...] begin ... end
@nboxplot begin ... end       # y defaults to n_y
```
 
**Example:**
```julia
fig = @nboxplot [n_a, n_b, n_c] begin
    n_a = randn(200)
    n_b = randn(200) .+ 2
    n_c = randn(200) .- 1
end
```
 
---
 
### `@nheatmap` : Heatmap
 
Plots a 2D matrix as a heatmap with a colorbar.
 
```julia
@nheatmap z_var begin ... end                      # single matrix
@nheatmap x_var y_var z_var begin ... end          # with axis coordinates
@nheatmap begin ... end                            # z defaults to n_z
```
 
**Example:**
```julia
# Matrix only
fig = @nheatmap n_z begin
    n_z = rand(50, 50)
end
 
# With explicit axis values
fig = @nheatmap n_x n_y n_z begin
    n_x = 1:50
    n_y = 1:50
    n_z = [sin(x) * cos(y) for x in 0:0.1:4.9, y in 0:0.1:4.9]
end
```
 
---
 
## Dependencies
 
| Package | Version |
|---|---|
| [CairoMakie](https://github.com/MakieOrg/Makie.jl) | ≥ 0.15 |
| [ProgressMeter](https://github.com/timholy/ProgressMeter.jl) | ≥ 1 |
| Julia | ≥ 1.0 |