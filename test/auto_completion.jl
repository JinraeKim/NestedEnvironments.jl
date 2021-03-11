using NestedEnvironments
using DifferentialEquations
using Transducers

using Random
using Plots
using Test


## envs
struct Policy
end
command(policy::Policy, x::Array{Float64, 1}) = -5*sum(x)

struct Env <: AbstractEnv
    iaqc::NestedEnvironments.InputAffineQuadraticCostEnv
    policy::Policy
end

function dynamics(env::Env)
    return function (x, p, t)
        a = p  # zero-order-hold action
        (; iaqc = NestedEnvironments.ẋ(env.iaqc, x.iaqc, t, a))
    end
end
# automatic completion of initial condition
NestedEnvironments.initial_condition(env::NestedEnvironments.InputAffineQuadraticCostEnv) = 2*(rand(2) .- 0.5)

# register envs
__env = Env(NestedEnvironments.InputAffineQuadraticCostEnv(), Policy())
__x0 = NestedEnvironments.initial_condition(__env)
@reg_env __env __x0

function test()
    env = Env(NestedEnvironments.InputAffineQuadraticCostEnv(), Policy())
    x0 = NestedEnvironments.initial_condition(env)
    _x0 = @raw(env, x0)
    @test _x0 == @raw x0
    @test x0 == @readable(env, _x0)
end
