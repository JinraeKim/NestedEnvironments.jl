# env names
function _names(env::AbstractEnv)
    return [name for name in fieldnames(typeof(env)) if typeof(getfield(env, name)) <: AbstractEnv]
end
# get the size of envs
function _size(env::AbstractEnv, x0)
    env_names = _names(env)
    if env_names == []
        return size(x0)
    else
        env_sizes = env_names |> Map(name -> _size(getfield(env, name), x0[name]))
        return (; zip(env_names, env_sizes)...)  # NamedTuple
    end
end
function Base.size(x0::NamedTuple)
    env_names = keys(x0)
    if env_names == []
        return size(x0)
    else
        env_sizes = env_names |> Map(name -> size(x0[name]))
        return (; zip(env_names, env_sizes)...)  # NamedTuple
    end
end
# transform readable to raw (flatten)
function _raw(env::AbstractEnv, x)
    env_names = _names(env)
    if env_names == []
        return x
    else
        _x = env_names |> MapCat(name -> _raw(getfield(env, name), x[name])) |> collect
        return _x
    end
end
# get the flatten length of given env
function _flatten_length(env::AbstractEnv, x0)
    env_names = _names(env)
    if env_names == []
        return prod(size(x0))
    else
        return env_names |> Map(name -> _flatten_length(getfield(env, name), x0[name])) |> sum
    end
end
function flatten_length(x0::NamedTuple)
    env_names = keys(x0)
    if env_names == []
        return prod(size(x0))
    else
        return env_names |> Map(name -> flatten_length(x0[name])) |> sum
    end
end
flatten_length(x0::Array{Float64, 1}) = prod(size(x0))

# get the index
function _index(env::AbstractEnv, x0, _range)
    env_names = _names(env)
    if env_names == []
        return _range
    else
        env_accumulated_flatten_lengths = env_names |> Map(name -> _flatten_length(getfield(env, name), x0[name])) |> Scan(+) |> collect
        range_first = first(_range)
        env_ranges_tmp = (range_first-1) .+ [0, env_accumulated_flatten_lengths...] |> Consecutive(length(env_accumulated_flatten_lengths); step=1)
        env_ranges = zip(env_ranges_tmp...) |> MapSplat((x, y) -> x+1:y)
        env_indices = zip(env_names, env_ranges) |> MapSplat((name, range) -> _index(getfield(env, name), x0[name], range))
        return (; zip(env_names, env_indices)...)  # NamedTuple
    end
end
# get env_index and env_isze
function _preprocess(env::AbstractEnv, x0)
    env_size_nt = _size(env, x0)
    env_flatten_length = _flatten_length(env, x0)
    env_index_nt = _index(env, x0, 1:env_flatten_length)
    return env_index_nt, env_size_nt
end
# transform raw (flatten) to readable
function _readable(_x, env_index_nt, env_size_nt)
    if typeof(env_index_nt) <: AbstractRange
        if env_size_nt == ()
            return _x[env_index_nt][1]  # scalar
        else
            return reshape(_x[env_index_nt], env_size_nt...)
        end
    else
        index_names = keys(env_index_nt)
        processed_values = index_names |> Map(name -> _readable(_x, env_index_nt[name], env_size_nt[name]))
        return (; zip(index_names, processed_values)...)
    end
end
