using NestedEnvironments
using DifferentialEquations
using Transducers
using Test


# `BaseEnv` is a kind of syntax sugar for definition of environment; provided by `src/zoo.jl`.
# Note: `NestedEnvironments.initial_condition(env::BaseEnv) = env.initial_state`
struct Env2 <: AbstractEnv
    env21::BaseEnv
    env22::BaseEnv
end
struct Env <: AbstractEnv
    env1::BaseEnv
    env2::Env2
    gain::Float64
end


# differential equations are regarded as nested envs (NamedTuple)
function dynamics(env::Env)
    return function (x, p, t)
        x1 = x.env1
        x21 = x.env2.env21
        x22 = x.env2.env22
        ẋ1 = -x1 - env.gain*sum(x21 + x22)
        ẋ21 = -x21
        ẋ22 = -x22
        (; env1 = ẋ1, env2 = (; env21 = ẋ21, env22 = ẋ22))
    end
end

# for convenience
function make_env()
    env21, env22 = BaseEnv(reshape(collect(1:8), 2, 4)), BaseEnv(reshape(collect(9:16), 2, 4))
    env1 = BaseEnv(-1)
    env2 = Env2(env21, env22)
    gain = 2.0
    env = Env(env1, env2, gain)
    env
end
# register env; do it in global scope
__env = make_env()
__x0 = NestedEnvironments.initial_condition(__env)
@reg_env __env __x0

# test
function test()
    env = make_env()
    # initial condition
    # if you extend `NestedEnvironments.initial_condition` for all sub environments, then `NestedEnvironments.initial_condition(env::Env)` will automatically complete a readable initial condition as NamedTuple.
    x0 = NestedEnvironments.initial_condition(env)  # auto-completion of initial condition
    @show x0  # x0 = (env1 = -1, env2 = (env21 = [1 3 5 7; 2 4 6 8], env22 = [9 11 13 15; 10 12 14 16]))
    t0 = 0.0
    tf = 10.0
    tspan = (t0, tf)
    Δt = 0.01  # saveat; not numerical integration
    ts = t0:Δt:tf
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    @time sol = solve(prob, Tsit5(), saveat=ts)
    # readable
    xs = sol.u |> Map(_x -> @readable _x) |> collect  # nested states
    @test xs[1].env1 == x0.env1
    @test xs[1].env2.env21 == x0.env2.env21
    @test xs[1].env2.env22 == x0.env2.env22
    # raw
    _x0 = @raw x0
    @show _x0  # _x0 = [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    @test _x0 == sol.u[1]
end
