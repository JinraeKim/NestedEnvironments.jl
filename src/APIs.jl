function DifferentialEquations.ODEProblem(env::AbstractEnv, f, x0, tspan; kwargs...)
    env_index_nt, env_size_nt = _preprocess(env, x0)
    _x0 = raw(env, x0)
    _f(_x, p, t) = raw(env, f(readable(env, _x), p, t))
    ODEProblem(_f, _x0, tspan; kwargs...)
end

# automatic completion of initial condition
function initial_condition(env::AbstractEnv)
    env_names = NestedEnvironments._names(env)
    values = env_names |> Map(name -> initial_condition(getfield(env, name)))
    return (; zip(env_names, values)...)  # NamedTuple
end
