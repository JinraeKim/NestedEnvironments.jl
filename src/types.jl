# envs
abstract type AbstractEnv end
mutable struct RegisteredEnvs
    __envs::Array{AbstractEnv, 1}
end
__REGISTERED_ENVS = RegisteredEnvs([])
# generic functions
function readable end
function raw end
