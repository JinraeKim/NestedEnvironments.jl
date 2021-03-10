function DifferentialEquations.ODEProblem(env::AbstractEnv, f, x0, tspan; kwargs...)
    env_index_nt, env_size_nt = _preprocess(env, x0)
    _x0 = raw(env, x0)
    _f(_x, p, t) = raw(env, f(readable(env, _x), p, t))
    ODEProblem(_f, _x0, tspan; kwargs...)
end
