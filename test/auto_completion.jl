using NestedEnvironments
using DifferentialEquations
using Transducers

using Random
using Plots
using Test


function dynamics(env::NestedEnvironments.InputAffineQuadraticCostEnv)
    return function (x, p, t)
        u = command(env, x)
        NestedEnvironments.ẋ(env, x, t, u)
    end
end
command(env, x) = NestedEnvironments.u_optimal(env, x)
NestedEnvironments.initial_condition(env::NestedEnvironments.InputAffineQuadraticCostEnv) = 2*(rand(2) .- 0.5)
# register envs
__env = NestedEnvironments.InputAffineQuadraticCostEnv()
__x0 = NestedEnvironments.initial_condition(__env)
@reg_env __env __x0

function test()
    env = NestedEnvironments.InputAffineQuadraticCostEnv()
    x0 = NestedEnvironments.initial_condition(env)
    @show x0
    @show _x0 = @raw(env, x0)
    @test _x0 == @raw x0
    @test x0 == @readable(env, _x0)
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    tspan = (t0, tf)
    ts = t0:Δt:tf
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    @time sol = solve(prob, Tsit5(), saveat=ts)
    xs = sol.u |> Map(u -> @readable u) |> collect
    @show xs
end
