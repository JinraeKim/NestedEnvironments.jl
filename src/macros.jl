"""
# Notes
- Must be used in the global scope.
- x0 can be any dummy collection such as NamedTuple-valued initial value.
"""
macro reg_env(env, x0)
    ex = quote
        if typeof($(env)) <: AbstractEnv
            # names
            local env_names = NestedEnvironments._names($(env))
            NestedEnvironments.names(env::typeof($(env))) = env_names
            # size
            local env_size = NestedEnvironments._size($(env), $(x0))
            NestedEnvironments.size(env::typeof($(env))) = env_size
            NestedEnvironments.size(env::typeof($(env)), x0) = NestedEnvironments.size(env::typeof($(env)))
            # # flatten length
            local env_flatten_length = NestedEnvironments._flatten_length($(env), $(x0))
            # NestedEnvironments.flatten_length(env::typeof($(env)), x0) = env_flatten_length
            # # index
            local env_index = NestedEnvironments._index($(env), $(x0), 1:env_flatten_length)
            # NestedEnvironments.index(env::typeof($(env)), x0, _range) = env_index
            # # preprocess
            local env_index_nt, env_size_nt = NestedEnvironments._preprocess($(env), $(x0))
            # NestedEnvironments.preprocess(env::typeof($(env))) = env_index_nt, env_size_nt
            # NestedEnvironments.preprocess(env::typeof($(env)), x0) = NestedEnvironments.preprocess($(env))
            # readable
            NestedEnvironments.readable(env::typeof($(env)), _x) = NestedEnvironments._readable(_x, env_index_nt, env_size_nt)
            # raw
            NestedEnvironments.raw(env::typeof($(env)), x) = NestedEnvironments._raw($(env), x)
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end

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
