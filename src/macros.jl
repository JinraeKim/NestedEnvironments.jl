"""
# Notes
- Must be used in the global scope.
- x0 can be any dummy collection such as NamedTuple-valued initial value.
"""
macro reg_env(env, x0)
    ex = quote
        if typeof($(env)) <: AbstractEnv
            # names
            # local env_names = NestedEnvironments._names($(env))
            # Base.names(env::typeof($(env))) = env_names
            # size
            # local env_size = NestedEnvironments._size($(env), $(x0))
            # NestedEnvironments.size(env::typeof($(env))) = env_size
            # NestedEnvironments.size(env::typeof($(env)), x0) = NestedEnvironments.size(env::typeof($(env)))
            # # flatten length
            # local env_flatten_length = NestedEnvironments._flatten_length($(env), $(x0))
            # NestedEnvironments.flatten_length(env::typeof($(env)), x0) = env_flatten_length
            # # index
            # local env_index = NestedEnvironments._index($(env), $(x0), 1:env_flatten_length)
            # NestedEnvironments.index(env::typeof($(env)), x0, _range) = env_index
            # # preprocess
            local env_index_nt, env_size_nt = NestedEnvironments._preprocess($(env), $(x0))
            # NestedEnvironments.preprocess(env::typeof($(env))) = env_index_nt, env_size_nt
            # NestedEnvironments.preprocess(env::typeof($(env)), x0) = NestedEnvironments.preprocess($(env))
            # readable
            NestedEnvironments.readable(env::typeof($(env)), _x) = NestedEnvironments._readable(_x, env_index_nt, env_size_nt)
            # raw
            NestedEnvironments.raw(env::typeof($(env)), x) = NestedEnvironments._raw($(env), x)
            # register an env
            push!(__REGISTERED_ENVS, $(env), $(x0))
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end

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

## macro for transformation from readable to raw
# basic
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
# auto-transformation
macro raw(x)
    ex = quote
        local env_x_cands = zip(__REGISTERED_ENVS.__envs, __REGISTERED_ENVS.__xs) |> Filter(env_x -> size(env_x[2]) == size($(x))) |> collect
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
# auto-transformation
macro readable(_x)
    ex = quote
        local env_x_cands = zip(__REGISTERED_ENVS.__envs, __REGISTERED_ENVS.__xs) |> Filter(env_x -> NestedEnvironments.flatten_length(env_x[2]) == NestedEnvironments.flatten_length($(_x))) |> collect
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
