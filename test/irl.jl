using NestedEnvironments
using DifferentialEquations


struct IntegralRLEnv <: AbstractEnv
    env::InputAffineQuadraticCostEnv
    ∫r::IntegralRLEnv
end
