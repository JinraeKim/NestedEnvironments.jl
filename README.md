# NestedEnvironments.jl
This is an API for nested environments,
compatible with [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl).

## Terminology
An environment may consist of nested environments.
Each environment is a structure (e.g., `typeof(env) <: AbstractEnv`), which includes dynamical systems and additional information.

## Notes
- Currently, only ODE is supported.
See `src/API.jl` for more details.

# Features
## Nested environments
`NestedEnvironments.jl` supports nested environments API.
The **dynamical equations** and **initial condition** are treated as structured forms (as NamedTuple).
Compared to the original `DifferentialEquations.jl`, you don't need to match the index of derivative calculation.
For example,
```julia
function f(x, p, t)
    x1 = x.env1  # for example
    x2 = x.env2  # for example
    dx1 = x2
    dx2 = -x1
    (; x1 = dx1, x2 = dx2)  # NamedTuple
end
```
instead of
```julia
function f(x, p, t)
    dx = zero(x)
    dx[1] = x[2]
    dx[2] = -x[1]
    dx
end
```
.
For more details, see the below example.

## Macros and auto-completion
`NestedEnvironments.jl` provides convenient macros such as `@readable` and `@raw`.
`@readable` makes an Array, compatible with `DifferentialEquations.jl`, (structured) NamedTuple.
Conversely,
`@raw` makes a NamedTuple, default structure of `NestedEnvironments.jl`, an Array compatible with `DifferentialEquations.jl`.

## Environment Zoo
It provides some predefined environments.
See `src/zoo.jl` for more information.


# Usage
## Example
### Nested environments
It is highly recommended to run the following code and practice how to use it.

```julia
using NestedEnvironments
using DifferentialEquations
using Transducers
using Test


struct SubEnv2 <: AbstractEnv
end
struct Env1 <: AbstractEnv
end
struct Env2 <: AbstractEnv
    env21::SubEnv2
    env22::SubEnv2
end
struct Env <: AbstractEnv
    env1::Env1
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

# if you extend `NestedEnvironments.initial_condition` for all sub environments, then `NestedEnvironments.initial_condition(env::Env)` will automatically complete a nested initial condition as NamedTuple.
NestedEnvironments.initial_condition(env::SubEnv2) = reshape(1:2*4, 2, 4)
NestedEnvironments.initial_condition(env::Env1) = 9  # scalar system
# for convenience
function make_env()
    env21, env22 = SubEnv2(), SubEnv2()
    env1 = Env1()
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
    x0 = NestedEnvironments.initial_condition(env)  # auto-completion of initial condition
    @show x0  # x0 = (env1 = 9, env2 = (env21 = [1 3 5 7; 2 4 6 8], env22 = [1 3 5 7; 2 4 6 8]))
    t0 = 0.0
    tf = 10.0
    tspan = (t0, tf)
    Δt = 0.01  # saveat; not numerical integration
    ts = t0:Δt:tf
    prob = ODEProblem(env, dynamics(env), x0, tspan)
    @time sol = solve(prob, Tsit5(), saveat=ts)
    xs = sol.u |> Map(_x -> @readable _x) |> collect  # nested states
    @test xs[1].env1 == x0.env1
    @test xs[1].env2.env21 == x0.env2.env21
    @test xs[1].env2.env22 == x0.env2.env22
end
```
