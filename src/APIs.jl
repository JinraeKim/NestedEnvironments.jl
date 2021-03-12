## ODEProblem
function DifferentialEquations.ODEProblem(env::AbstractEnv, f, x0, tspan; kwargs...)
    warn_is_registered(env)
    _x0 = raw(env, x0)
    _f(_x, p, t) = raw(env, f(readable(env, _x), p, t))
    ODEProblem(_f, _x0, tspan; kwargs...)
end

## initial condition
# automatic completion of initial condition
function initial_condition(env::AbstractEnv)
    env_names = names(env)
    values = env_names |> Map(name -> initial_condition(getfield(env, name)))
    return (; zip(env_names, values)...)  # NamedTuple
end


## register env
"""
# Notes
- Must be used in the global scope.
- x0 can be any dummy collection such as NamedTuple-valued initial value.
"""
macro reg_env(env, x0)
    ex = quote
        if typeof($(env)) <: AbstractEnv
            local env_index_nt, env_size_nt = NestedEnvironments._preprocess($(env), $(x0))
            # raw & readable
            NestedEnvironments.readable(env::typeof($(env)), _x) = NestedEnvironments._readable(_x, env_index_nt, env_size_nt)
            NestedEnvironments.raw(env::typeof($(env)), x) = NestedEnvironments._raw($(env), x)
            # register env
            push!(NestedEnvironments.__REGISTERED_ENVS, $(env), $(x0))
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end
# aux
function Base.push!(__REGISTERED_ENVS::RegisteredEnvs, env::AbstractEnv, x0)
    num_of_already_reg_envs = __REGISTERED_ENVS.__envs |> Filter(__env -> typeof(__env) == typeof(env)) |> collect |> length
    if num_of_already_reg_envs == 0
        push!(__REGISTERED_ENVS.__envs, env)
        push!(__REGISTERED_ENVS.__xs, x0)
        println("$(typeof(env)): registered")
    else
        println("$(typeof(env)): overwrite existing registered env")
    end
end

## macros
# macro for transformation from readable to raw
macro raw(env, x)
    ex = quote
        if typeof($(env)) <: AbstractEnv
            _x = NestedEnvironments.raw($(env), $(x))
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end
# auto-completion
macro raw(x)
    ex = quote
        local env_x_cands = zip(NestedEnvironments.__REGISTERED_ENVS.__envs, NestedEnvironments.__REGISTERED_ENVS.__xs) |> Filter(env_x -> size(env_x[2]) == size($(x))) |> collect
        if length(env_x_cands) == 0
            error("There is no matched registered envrionment")
        elseif length(env_x_cands) > 1
            error("It is ambiguous; too many matched registered environments")
        else
            @raw(env_x_cands[1][1], $(x))
        end
    end
    esc(ex)
end

# macro for transformation from raw to readable
"""
# Notes
Use it after @reg_env
"""
macro readable(env, _x)
    ex = quote
        if typeof($(env)) <: AbstractEnv
            x = NestedEnvironments.readable($(env), $(_x))
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end
# auto-completion
macro readable(_x)
    ex = quote
        local env_x_cands = zip(NestedEnvironments.__REGISTERED_ENVS.__envs, NestedEnvironments.__REGISTERED_ENVS.__xs) |> Filter(env_x -> NestedEnvironments.flatten_length(env_x[2]) == NestedEnvironments.flatten_length($(_x))) |> collect
        if length(env_x_cands) == 0
            error("There is no matched registered envrionment")
        elseif length(env_x_cands) > 1
            error("It is ambiguous; too many matched registered environments")
        else
            @readable(env_x_cands[1][1], $(_x))
        end
    end
    esc(ex)
end
