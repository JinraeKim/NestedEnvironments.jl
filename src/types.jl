# envs
abstract type AbstractEnv end

# registered envs
mutable struct RegisteredEnvs
    __envs::Array{AbstractEnv, 1}
    __xs::Array{Any, 1}
end
__REGISTERED_ENVS = RegisteredEnvs([], [])

# generic functions
function readable end
function raw end
