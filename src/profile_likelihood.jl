function _binomial_loglikelihood_kernel(p, nsim, failures)
    probability = clamp(p, 1.0e-300, 1.0 - 1.0e-300)
    return failures * log(probability) +
           (nsim - failures) * log1p(-probability)
end

"""
    profile_likelihood_interval(nsim, failures; h=1000.0)

Return the maximum-likelihood binomial estimate and the absolute lower and
upper bounds whose likelihood is a factor `h` below the maximum.
"""
function profile_likelihood_interval(
    nsim::Integer,
    failures::Integer;
    h::Float64=1000.0,
)
    nsim > 0 || throw(ArgumentError("nsim must be positive"))
    0 <= failures <= nsim || throw(ArgumentError(
        "failures must satisfy 0 <= failures <= nsim",
    ))
    h >= 1.0 || throw(ArgumentError("h must be at least 1"))

    sample_count = float(nsim)
    estimate = failures / sample_count
    if failures == 0
        high = 1.0 - exp(-log(h) / sample_count)
        return (; low=0.0, estimate, high)
    elseif failures == nsim
        low = exp(-log(h) / sample_count)
        return (; low, estimate, high=1.0)
    end

    threshold = _binomial_loglikelihood_kernel(estimate, nsim, failures) - log(h)

    lower_outside = 0.0
    lower_inside = estimate
    for _ in 1:200
        midpoint = 0.5 * (lower_outside + lower_inside)
        if _binomial_loglikelihood_kernel(midpoint, nsim, failures) >= threshold
            lower_inside = midpoint
        else
            lower_outside = midpoint
        end
        abs(lower_inside - lower_outside) <= 1.0e-15 * max(1.0, estimate) && break
    end

    upper_inside = estimate
    upper_outside = 1.0
    for _ in 1:200
        midpoint = 0.5 * (upper_inside + upper_outside)
        if _binomial_loglikelihood_kernel(midpoint, nsim, failures) >= threshold
            upper_inside = midpoint
        else
            upper_outside = midpoint
        end
        abs(upper_outside - upper_inside) <=
            1.0e-15 * max(1.0, 1.0 - estimate) && break
    end

    return (; low=lower_inside, estimate, high=upper_inside)
end
