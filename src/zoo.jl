using LinearAlgebra
using Parameters


########## Base Env ##########
# BaseEnv
struct BaseEnv <: AbstractEnv
    initial_state
end
BaseEnv(given_size::Tuple) = BaseEnv(zeros(given_size))
BaseEnv(args...) = BaseEnv(zeros(args...))
BaseEnv() = BaseEnv(0.0)
# initial_condition
NestedEnvironments.initial_condition(env::BaseEnv) = env.initial_state


########## InputAffineQuadraticCostEnv ##########
"""
An example of continuous-time nonlinear dynamical system introduced in
several studies on approximate dynamic programming.
# Reference
[1] K. G. Vamvoudakis and F. L. Lewis, “Online Actor-Critic Algorithm to Solve the Continuous-Time Infinite Horizon Optimal Control Problem,” Automatica, vol. 46, no. 5, pp. 878–888, 2010, doi: 10.1016/j.automatica.2010.02.018.
[2] V. Nevistic and J. A. Primbs, “Constrained Nonlinear Optimal Control: a Converse HJB Approach,” 1996.
"""
@with_kw struct InputAffineQuadraticCostEnv <: AbstractEnv
    Q = Matrix(I, 2, 2)
    R = 1
    P = [0.5 0; 0 1]
end

function f(env::InputAffineQuadraticCostEnv, x)
    x1 = x[1]
    x2 = x[2]
    f1 = -x1 + x2
    f2 = -0.5*x1 -0.5*x2*(1-(cos(2*x1)+2)^2)
    return  [f1, f2]
end

function g(env::InputAffineQuadraticCostEnv, x)
    x1 = x[1]
    g1 = 0
    g2 = cos(2*x1) +2
    return [g1, g2]
end

"""
    r(env, x, u)

Calculate running cost, i.e., V = ∫r dt.
"""
function r(env::InputAffineQuadraticCostEnv, x, u)
    x'*env.Q*x + u'*env.R*u
end

function V_optimal(env::InputAffineQuadraticCostEnv, x)
    return x'*env.P*x
end

function u_optimal(env::InputAffineQuadraticCostEnv, x)
    _g = g(env, x)
    return -_g'*env.P*x
end

function ẋ(env::InputAffineQuadraticCostEnv, x, t, u)
    ẋ = f(env, x) + g(env, x)*u
    return ẋ
end
