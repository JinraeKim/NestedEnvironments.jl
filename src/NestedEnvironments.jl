module NestedEnvironments

using DifferentialEquations
using Transducers

export AbstractEnv
export __REGISTERED_ENVS  # do not change it manually
export raw, readable
export @reg_env, @raw, @readable


include("types.jl")
include("internalAPIs.jl")
include("APIs.jl")
include("macros.jl")
include("zoo.jl")


end
