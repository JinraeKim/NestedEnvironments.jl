using NestedEnvironments
using DifferentialEquations
using Test


## user-defined nested environments
struct SubSubEnv <: AbstractEnv
end
struct SubEnv <: AbstractEnv
    env21::SubSubEnv
    env22::SubSubEnv
end
struct Env <: AbstractEnv
    env1::SubSubEnv
    env2::SubEnv
end
# dynamics
function f(x, p, t)
    ẋ1 = -x.env1
    ẋ21 = -x.env2.env21
    ẋ22 = -x.env2.env22
    (; env1 = ẋ1, env2 = (; env21 = ẋ21, env22 = ẋ22))
end
# initial condition
function initial_condition(env::Env)
    (; env1 = 1, env2 = (; env21 = rand(4), env22 = rand(2, 7)))
end

# for register
__env = Env(SubSubEnv(), SubEnv(SubSubEnv(), SubSubEnv()))
__x0 = initial_condition(__env)
@reg_env __env __x0

## test
function test1()
    env = Env(SubSubEnv(), SubEnv(SubSubEnv(), SubSubEnv()))
    x0 = initial_condition(env)
    @test x0 == @readable(@raw(x0))
end

function test2()
    env = Env(SubSubEnv(), SubEnv(SubSubEnv(), SubSubEnv()))
    x0 = initial_condition(env)
    _x0 = @raw env x0
    x0_new = @readable env _x0
    @test x0 == x0_new
end

function test3()
    env = Env(SubSubEnv(), SubEnv(SubSubEnv(), SubSubEnv()))
    x0 = initial_condition(env)
    t0 = 0.0
    tf = 100.0
    tspan = (t0, tf)
    ts = t0:0.01:tf
    prob = ODEProblem(env, f, x0, tspan)
    sol = solve(prob, Tsit5(), saveat=ts)
    @test sol.u[1] == @raw env x0
end

function test4()
    env1 = BaseEnv()
    @test NestedEnvironments.initial_condition(env1) == 0.0
    size_tuple = (1, 2)
    env2 = BaseEnv(size_tuple)
    @test NestedEnvironments.initial_condition(env2) == zeros(size_tuple)
    env3 = BaseEnv(size_tuple...)
    @test NestedEnvironments.initial_condition(env3) == zeros(size_tuple)
    x0 = reshape(collect(1:15), 3, 5)
    env4 = BaseEnv(x0)
    @test NestedEnvironments.initial_condition(env4) == x0
end

function test()
    test1()
    test2()
    test3()
    test4()
end
