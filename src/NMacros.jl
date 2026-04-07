module NMacros

using ProgressMeter
using Dates
using CairoMakie

export @nscatter, @nscatterlines, @nhist, @nboxplot, @nheatmap, @nlines

# Turn syntax into Vector{Symbol}
_as_syms(x) = x isa Symbol ? [x] :
              (x isa Expr && (x.head === :vect || x.head === :tuple)) ? [item isa Symbol ? item :
                                                  item isa QuoteNode ? item.value :
                                                  error("Expected Symbols, got $item")
                                                  for item in x.args] :
              error("Expected Symbol or vector literal, got $x")

_as_sym(x) = x isa Symbol ? x :
             (x isa QuoteNode && x.value isa Symbol) ? x.value :
             error("Expected Symbol, got $x")

macro nscatter(x_symbol, y_symbols, to_run)

    # Sanity checks
    ys = _as_syms(y_symbols)
    x  = _as_sym(x_symbol)

    # Generating unique variable symbols for collected variables
    ytemps = [gensym(s) for s in ys]
    xtemp = gensym(:x)

    # Expr that assigns values from collected variables to be executed after to_run (magic)
    x_assign = :(local $xtemp = $(esc(x)))
    y_assigns = [:(local $(ytemps[i]) = $(esc(ys[i]))) for i in eachindex(ys)]

    # Expr to call to generate scatters once code is ran, capturing values from passed variables
    scatter_calls = [
        :(Makie.scatter!($xtemp, $(ytemps[i]); label=String($(QuoteNode(ys[i])))))
        for i in eachindex(ys)
    ]

    return quote
        # Run blocked code
        $(esc(to_run))

        # Capture x & y variable values
        $(y_assigns...)
        $x_assign

        # Runtime plotting
        f = Figure()
        axis = Axis(f[1, 1])
        $(scatter_calls...)
        axislegend(axis)
        f
    end
end

# Overloading for default values (n_x, n_y)
macro nscatter(to_run)
    # default: x = n_x, y = n_y (single y)
    return :( @nscatter n_x n_y $(esc(to_run)) )
end

# Overloading for default y value (n_y)
macro nscatter(x_symbol, to_run)
    # allow: @nscatter x begin ... end  (default y = n_y)
    return :( @nscatter $(x_symbol) n_y $(esc(to_run)) )
end


macro nlines(x_symbol, y_symbols, to_run)

    # Sanity checks
    ys = _as_syms(y_symbols)
    x  = _as_sym(x_symbol)

    # Generating unique variable symbols for collected variables
    ytemps = [gensym(s) for s in ys]
    xtemp = gensym(:x)

    # Expr that assigns values from collected variables to be executed after to_run (magic)
    x_assign = :(local $xtemp = $(esc(x)))
    y_assigns = [:(local $(ytemps[i]) = $(esc(ys[i]))) for i in eachindex(ys)]

    # Expr to call to generate scatters once code is ran, capturing values from passed variables
    scatter_calls = [
        :(Makie.lines!($xtemp, $(ytemps[i]); label=String($(QuoteNode(ys[i])))))
        for i in eachindex(ys)
    ]

    return quote
        # Run blocked code
        $(esc(to_run))

        # Capture x & y variable values
        $(y_assigns...)
        $x_assign
        println($ytemps)
        # Runtime plotting
        f = Figure()
        axis = Axis(f[1, 1])
        $(scatter_calls...)
        axislegend(axis)
        f
    end
end

# Overloading for default values (n_x, n_y)
macro nlines(to_run)
    # default: x = n_x, y = n_y (single y)
    return :( @nlines n_x n_y $(esc(to_run)) )
end

# Overloading for default y value (n_y)
macro nlines(x_symbol, to_run)
    # allow: @nscatter x begin ... end  (default y = n_y)
    return :( @nlines $(x_symbol) n_y $(esc(to_run)) )
end

macro nhist(y_symbol, to_run)
    
    # Sanity checks
    y = _as_sym(y_symbol)

    # Generating unique variable symbols for collected variables
    ytemp = gensym(:y)

    # Expr that assigns values from collected variables to be executed after to_run (magic)
    y_assign = :(local $ytemp = $(esc(y)))

    # Expr to call to generate hist once code is ran, capturing values from passed variables
    hist_call = :(Makie.hist!($(ytemp)))
    return quote
        # Run blocked code
        $(esc(to_run))

        # Capture x & y variable values
        $(y_assign)
        
        # Runtime plotting
        f = Figure()
        axis = Axis(f[1, 1])
        $hist_call

        f
    end
end

# Overloading for default value n_y
macro nhist(to_run)
    # default: y = n_y
    return :( @nhist n_y $(esc(to_run)) )
end

macro nboxplot(y_symbols, to_run)
    ys = _as_syms(y_symbols)

    # Capture runtime values
    ytemps = [gensym(s) for s in ys]
    y_assigns = [:(local $(ytemps[k]) = $(esc(ys[k]))) for k in eachindex(ys)]

    labels_expr = Expr(:vect, (QuoteNode(String(s)) for s in ys)...)

    return quote
        $(esc(to_run))
        $(y_assigns...)

        f = Figure()
        ax = Axis(f[1, 1])

        # Build categorical x positions and concatenated y values
        local _x = Int[]
        local _y = eltype($(ytemps[1]))[]

        # Annoyingly building the datastruct boxplot expects
        local _ys = [$(ytemps...)]
        for i in 1:length(_ys)
            local yi = _ys[i]
            append!(_x, fill(i, length(yi)))
            append!(_y, yi)
        end

        Makie.boxplot!(ax, _x, _y)
        ax.xticks = (1:length($labels_expr), $labels_expr)

        f
    end
end

macro nboxplot(to_run)
    return :( @nboxplot n_y $(esc(to_run)) )
end

# This is basically the same as nlines
macro nscatterlines(x_symbol, y_symbols, to_run)
    ys = _as_syms(y_symbols)
    x  = _as_sym(x_symbol)

    ytemps = [gensym(s) for s in ys]
    xtemp  = gensym(:x)

    x_assign  = :(local $xtemp = $(esc(x)))
    y_assigns = [:(local $(ytemps[i]) = $(esc(ys[i]))) for i in eachindex(ys)]

    calls = [
        :(Makie.scatterlines!(axis, $xtemp, $(ytemps[i]); label=String($(QuoteNode(ys[i])))))
        for i in eachindex(ys)
    ]

    return quote
        $(esc(to_run))
        $(y_assigns...)
        $x_assign

        f = Figure()
        axis = Axis(f[1, 1])
        $(calls...)
        axislegend(axis)
        f
    end
end

macro nscatterlines(to_run)
    return :( @nscatterlines n_x n_y $(esc(to_run)) )
end

macro nscatterlines(x_symbol, to_run)
    return :( @nscatterlines $(x_symbol) n_y $(esc(to_run)) )
end

# Works similarly to nscatter, but can't have multiple n_y due to the nature of the plot
macro nhexbin(x_symbol, y_symbol, to_run)
    x = _as_sym(x_symbol)
    y = _as_sym(y_symbol)

    xtemp = gensym(:x)
    ytemp = gensym(:y)

    x_assign = :(local $xtemp = $(esc(x)))
    y_assign = :(local $ytemp = $(esc(y)))

    return quote
        $(esc(to_run))
        $x_assign
        $y_assign

        f = Figure()
        ax = Axis(f[1, 1])
        hb = Makie.hexbin!(ax, $xtemp, $ytemp)
        Colorbar(f[1, 2], hb)
        f
    end
end

macro nhexbin(to_run)
    return :( @nhexbin n_x n_y $(esc(to_run)) )
end

macro nhexbin(x_symbol, to_run)
    return :( @nhexbin $(x_symbol) n_y $(esc(to_run)) )
end

# A single matrix
macro nheatmap(z_symbol, to_run)
    z = _as_sym(z_symbol)
    ztemp = gensym(:z)
    z_assign = :(local $ztemp = $(esc(z)))

    return quote
        $(esc(to_run))
        $z_assign

        f = Figure()
        ax = Axis(f[1, 1])
        hm = Makie.heatmap!(ax, $ztemp)
        Colorbar(f[1, 2], hm)
        f
    end
end

# x, y arrays with a z matrix
macro nheatmap(x_symbol, y_symbol, z_symbol, to_run)
    x = _as_sym(x_symbol)
    y = _as_sym(y_symbol)
    z = _as_sym(z_symbol)

    xt = gensym(:x)
    yt = gensym(:y)
    zt = gensym(:z)

    x_assign = :(local $xt = $(esc(x)))
    y_assign = :(local $yt = $(esc(y)))
    z_assign = :(local $zt = $(esc(z)))

    return quote
        $(esc(to_run))
        $x_assign
        $y_assign
        $z_assign

        f = Figure()
        ax = Axis(f[1, 1])
        hm = Makie.heatmap!(ax, $xt, $yt, $zt)
        Colorbar(f[1, 2], hm)
        f
    end
end

macro nheatmap(to_run)
    return :( @nheatmap n_z $(esc(to_run)) )
end

end