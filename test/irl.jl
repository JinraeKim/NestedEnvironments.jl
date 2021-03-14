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
        dx = NestedEnvironments.ẋ(env.iaqc, x, t, u)
        (; iaqc = dx, ∫r = NestedEnvironments.r(env.iaqc, x, u))
    end
end

NestedEnvironments.initial_condition(env::InputAffineQuadraticCostEnv) = 2 * (rand(2) .- 0.5)

function make_env()
    iaqc = InputAffineQuadraticCostEnv()
    ∫r = BaseEnv()  # 0.0
    env = Env(iaqc, ∫r)
    env
end

# register
__env = make_env()
__x0 = initial_condition(__env)
@reg_env __env __x0

function test()
    env = make_env()
    x0 = initial_condition(env)
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    ts = t0:Δt:tf
    tspan = (t0, tf)
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    saved_values = SavedValues(Float64, NamedTuple)
    cb_save = SavingCallback((_x, t, integrator) -> (; x = (@readable _x).iaqc), saved_values, saveat=ts)
    cb = CallbackSet(cb_save)
    _ = solve(prob, Tsit5(), callback=cb)
    saved_values.saveval
end
