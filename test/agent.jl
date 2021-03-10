using NestedEnvironments
using DifferentialEquations
using Transducers

using Random
using Plots


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


## main
function main()
    Random.seed!(1)
    env = Env(NestedEnvironments.InputAffineQuadraticCostEnv(), Policy())
    x0 = NestedEnvironments.initial_condition(env)
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    tspan = (t0, tf)
    ts = t0:Δt:tf
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    function affect!(integrator)
        x = @readable env integrator.u  # actually not necessary in this case but recommended
        integrator.p = command(env.policy, x.iaqc)
    end
    cb_policy = PresetTimeCallback(ts, affect!)
    saved_values = SavedValues(Float64, NamedTuple)
    cb_save = SavingCallback((u, t, integrator) -> (; state = @readable(env, integrator.u).iaqc, action = integrator.p), saved_values, saveat=ts)
    cb = CallbackSet(cb_policy, cb_save)
    @time sol = solve(prob, Tsit5(); p=0.0, callback=cb)
    xs = (hcat((saved_values.saveval |> Map(nt -> nt.state) |> collect)...))'
    actions = saved_values.saveval |> Map(nt -> nt.action) |> collect
    p_x = plot(ts, xs)
    log_dir = "data/agent"
    mkpath(log_dir)
    savefig(p_x, joinpath(log_dir, "x.png"))
    p_a = plot(ts, actions)
    savefig(p_a, joinpath(log_dir, "a.png"))
end
