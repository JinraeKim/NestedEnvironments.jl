using NestedEnvironments
using DifferentialEquations


struct Env <: AbstractEnv
    iaqc::InputAffineQuadraticCostEnv
    ∫r::BaseEnv
end

function dynamics(env::Env)
    return function (x_nt, p, t)
        x = x_nt.iaqc
        ∫r = x_nt.∫r
        u = 0.0
        NestedEnvironments.ẋ(env.iaqc, x, t, u)
        (; env = , ∫r = NestedEnvironments.r(env.iaqc, x, u))
    end
end

initial_condition(env::InputAffineQuadraticCostEnv) = 2 * (rand(2) .- 0.5)


function test()
    iaqc = InputAffineQuadraticCostEnv()
    ∫r = BaseEnv()  # 0.0
    env = Env(iaqc, ∫r)
    x0 = initial_condition(env)
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    ts = t0:Δt:tf
    tspan = (t0, tf)
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    sol = solve(prob, Tsit5(), saveat=ts)
end
