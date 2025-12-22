using SpecialFunctions: loggamma

function sinter_like_fit_binomial(n::Integer, k::Integer, h::Real=1000.0)
    @assert n > 0 "n must be positive"
    @assert 0 <= k <= n "k must satisfy 0 <= k <= n"
    @assert h >= 1.0 "h must be >= 1"

    n_f = float(n)
    pbest = k / n_f

    if k == 0
        plow = 0.0
        phigh = 1.0 - exp(-log(h) / n_f)
        return (plow, pbest, phigh)
    end

    if k == n
        plow = exp(-log(h) / n_f)
        phigh = 1.0
        return (plow, pbest, phigh)
    end

    logC = loggamma(n_f + 1) - loggamma(float(k) + 1) - loggamma(n_f - float(k) + 1)
    eps = 1e-300
    function logf(p)
        p_clamped = clamp(p, eps, 1.0 - eps)
        return logC + k * log(p_clamped) + (n - k) * log1p(-p_clamped)
    end

    T = logf(pbest) - log(h)

    lo = 0.0
    hi = pbest
    for _ in 1:200
        mid = 0.5 * (lo + hi)
        if logf(mid) >= T
            hi = mid
        else
            lo = mid
        end
        if abs(hi - lo) <= 1e-15 * max(1.0, pbest)
            break
        end
    end
    plow = hi

    lo = pbest
    hi = 1.0
    for _ in 1:200
        mid = 0.5 * (lo + hi)
        if logf(mid) >= T
            lo = mid
        else
            hi = mid
        end
        if abs(hi - lo) <= 1e-15 * max(1.0, 1.0 - pbest)
            break
        end
    end
    phigh = lo

    return (plow, pbest, phigh)
end

function sinter_like_fit_binomial(n::Vector, k::Vector, h::Real=1000.0)
    lows = Vector{Float64}(undef, length(n))
    avs = Vector{Float64}(undef, length(n))
    highs = Vector{Float64}(undef, length(n))
    for i in 1:length(n)
        lows[i], avs[i], highs[i] = sinter_like_fit_binomial(n[i], k[i], h)
    end
    return lows, avs, highs
end