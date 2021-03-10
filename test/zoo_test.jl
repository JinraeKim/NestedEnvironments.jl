using NestedEnvironments
using DifferentialEquations
using Plots
using Random
using Transducers


function dyn(env)
    return function (x, p, t)
        u = command(env, x)
        NestedEnvironments.ẋ(env, x, t, u)
    end
end
command(env, x) = NestedEnvironments.u_optimal(env, x)

initial_condition(env::NestedEnvironments.InputAffineQuadraticCostEnv) = 2*(rand(2) .- 0.5)

__env = NestedEnvironments.InputAffineQuadraticCostEnv()
__x0 = initial_condition(__env)
@reg_env __env __x0

## main
function single()
    Random.seed!(1)
    env = NestedEnvironments.InputAffineQuadraticCostEnv()
    x0 = initial_condition(env)
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    tspan = (t0, tf)
    ts = t0:Δt:tf
    prob = ODEProblem(env, dyn(env), x0, tspan)
    @time sol = solve(prob, Tsit5(), saveat=ts)
    plot(sol)
end

function parallel()
    Random.seed!(1)
    env = NestedEnvironments.InputAffineQuadraticCostEnv()
    num = 10
    x0s = 1:num |> Map(i -> initial_condition(env))
    t0 = 0.0
    tf = 10.0
    Δt = 0.01
    tspan = (t0, tf)
    ts = t0:Δt:tf
    probs = x0s |> Map(x0 -> ODEProblem(env, dyn(env), x0, tspan)) |> collect
    sols = probs |> Map(prob -> solve(prob, Tsit5(), saveat=ts)) |> tcollect
    p = plot()
    _ = sols |> Map(sol -> plot!(sol, label=nothing)) |> collect
    display(p)
end
