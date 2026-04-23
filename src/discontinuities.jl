"""
    rootfunction(f)

Given a function `f` with a discontinuity or discontinuous derivative, return the rootfinding
function of `f`. The rootfinding function `g` takes the same arguments as `f`, and is such
that `f` can be described as a piecewise function based on the sign of `g`, where each piece
is continuous and has a continuous derivative. The pieces are obtained using
`left_continuous_function(f)` and `right_continuous_function(f)`.

More formally,
```julia
f(args...) = if g(args...) < 0
    left_continuous_function(f)(args...)
else
    right_continuous_function(f)(args...)
end
```

For example, if `f` is `max(x, y)`, the root function is `(x, y) -> x - y` with
`left_continuous_function` as `(x, y) -> y` and `right_continuous_function` as
`(x, y) -> x`.

See also: [`left_continuous_function`](@ref), [`right_continuous_function`](@ref).
"""
function rootfunction end

"""
    left_continuous_function(f)

Given a function `f` with a discontinuity or discontinuous derivative, return a function
taking the same arguments as `f` which is continuous and has a continuous derivative
when `rootfinding_function(f)` is negative.

See also: [`rootfunction`](@ref).
"""
function left_continuous_function end

"""
    right_continuous_function(f)

Given a function `f` with a discontinuity or discontinuous derivative, return a function
taking the same arguments as `f` which is continuous and has a continuous derivative
when `rootfinding_function(f)` is positive.

See also: [`rootfunction`](@ref).
"""
function right_continuous_function end

"""
    @register_discontinuity f(arg1, arg2, ...) root_expr left_expr right_expr

Utility macro to register functions with discontinuities. The function `f` with
arguments `arg1, arg2, ...` has a `rootfunction` of `root_expr`, a
`left_continuous_function` of `left_expr` and `right_continuous_function` of
`right_expr`. `root_expr`, `left_expr` and `right_expr` are all expressions in terms
of `arg1, arg2, ...`.

For example, `max(x, y)` can be registered as `@register_discontinuity max(x, y) x - y y x`.

See also: [`rootfunction`](@ref)
"""
macro register_discontinuity(f, root, left, right)
    Meta.isexpr(f, :call) || error("Expected function call as first argument")
    args = f.args[2:end]
    fn = esc(f.args[1])
    rootname = gensym(:root)
    rootfn = :(function $rootname($(args...))
        $root
    end)
    leftname = gensym(:left)
    leftfn = :(function $leftname($(args...))
        $left
    end)
    rightname = gensym(:right)
    rightfn = :(function $rightname($(args...))
        $right
    end)
    return quote
        $rootfn
        (::$typeof($rootfunction))(::$typeof($fn)) = $rootname
        $leftfn
        (::$typeof($left_continuous_function))(::$typeof($fn)) = $leftname
        $rightfn
        (::$typeof($right_continuous_function))(::$typeof($fn)) = $rightname
    end
end

# a triangle function which is zero when x is a multiple of period
function _triangle(x, period)
    x /= 2period
    abs(x + 1 // 4 - floor(x + 3 // 4)) - 1 // 2
end

@register_discontinuity abs(x) x -x x
# just needs a rootfind to hit the discontinuity
@register_discontinuity mod(x, y) _triangle(x, y) mod(x, y) mod(x, y)
@register_discontinuity rem(x, y) _triangle(x, y) rem(x, y) rem(x, y)
@register_discontinuity div(x, y) _triangle(x, y) div(x, y) div(x, y)
@register_discontinuity max(x, y) x - y y x
@register_discontinuity min(x, y) x - y x y
@register_discontinuity NaNMath.max(x, y) x - y y x
@register_discontinuity NaNMath.min(x, y) x - y x y
@register_discontinuity <(x, y) x - y true false
@register_discontinuity <=(x, y) y - x false true
@register_discontinuity >(x, y) y - x true false
@register_discontinuity >=(x, y) x - y false true

"""
    majorization_function(f)

Given a function `f`, return a majorization function `m` for `f`. The function `m` should
have the signature `m(k, args...)` where `args...` are the same arguments as `f`. `k` is a
`Real` value which acts as an approximation factor. For higher `k`, the function `m` should
more closely approximate `f` over the domain. A majorization function is such that
`m(k, args...) >= f(args...)` for all `args...` in the domain.
"""
function majorization_function end

"""
    minorization_function(f)

Given a function `f`, return a minorization function `m` for `f`. The function `m` should
have the signature `m(k, args...)` where `args...` are the same arguments as `f`. `k` is a
`Real` value which acts as an approximation factor. For higher `k`, the function `m` should
more closely approximate `f` over the domain. A minorization function is such that
`m(k, args...) <= f(args...)` for all `args...` in the domain.
"""
function minorization_function end

"""
    approximation_function(f)

Given a function `f`, return an approximation function `appr` for `f`. The function `appr` should
have the signature `appr(k, args...)` where `args..` are the same arguments as `f`. `k` is a
`Real` value acting as an approximation factor. For higher `k`, the function `appr` should more
closely approximate `f` over the domain. The function `appr` offers no guarantees other than
infinite differentiability over the domain. At any point in the domain, it may evaluate to a
value greater or less than the value returned by `f` for the same point.
"""
function approximation_function end
