#################################################################################################
#=
    Model for inverted pendulum
=#
#################################################################################################

using ForwardDiff
using LinearAlgebra

export CartPole


# Cart pole dynamics as a Julia class
struct CartPole
    x_dim::Int64 # total state dimension
    u_dim::Int64 # total control input dimension

    # Boundary  conditions
    x_init::AbstractArray{Float64,1}
    x_final::AbstractArray{Float64,1}

    # simulation setting
    dt::Float64 # discretization step-size
    tN::Int64 # number of time-discretization steps
    hN::Int64 # number of horizon time-discretization steps

    dynamics::Function # dynamic equation of motion
    get_jacobian::Function # dynamic jacobian

    # dynamics constants
    mc::Float64
    mp::Float64
    l::Float64
    g::Float64

    # weight matrices for terminal and running costs
    F::AbstractArray{Float64,2}  # terminal cost weight matrix
    Q::AbstractArray{Float64,2}  # state running cost weight matrix
    R::AbstractArray{Float64,2}  # control running cost weight matrix

    conv_tol::Float64 # convergence tolerance
    max_ite::Int64 # maximum iteration threshhold

end



# Define the model struct with parameters
function CartPole()
    x_dim = 4
    u_dim = 2

    x_init = [0, 0, pi / 6, 0]
    x_final = [0, 0, pi, 0]

    dt = 0.02
    tN = 500
    hN = 100


    mc = 1.0
    mp = 0.01
    l = 1.0
    g = 9.81


    F = Diagonal([1e+2 * [1; 1]; 1e+2 * [1; 1]])
    Q = zeros(4, 4)
    R = Diagonal(1e-3 * [1, 1])

    conv_tol = 1e-5
    max_ite = 10


    CartPole(
        x_dim,
        u_dim,
        x_init,
        x_final,
        dt,
        tN,
        hN,
        dynamics,
        get_jacobian,
        mc,
        mp,
        l,
        g,
        F,
        Q,
        R,
        conv_tol,
        max_ite,
    )
end


function dynamics(
    model::CartPole,
    x::Vector,
    u::Vector,
    t::Float64,
    step::Int64
)
    mc = model.mc
    mp = model.mp
    l = model.l
    g = model.g

    # x = [p, ṗ, θ, θ̇] where p: position, θ: angle of the pendulum
    p = x[1]
    ṗ = x[2]
    θ = x[3]
    θ̇ = x[4]

    ẋ = [
        ṗ
        (u[1] + mp * sin(θ) * (l * θ̇^2 + g * cos(θ))) / (mc + mp * sin(θ)^2)
        θ̇
        (-u[1] * cos(θ) - mp * l * θ̇^2 * cos(θ) * sin(θ) - (mc + mp) * g * sin(θ)) / (mc + mp * sin(θ)^2)
    ]
    return ẋ
end


function get_jacobian(
    model::CartPole,
    x::AbstractArray{Float64,1},
    u::AbstractArray{Float64,1},
    Δt::Int64,
)
    fx = ForwardDiff.jacobian(x -> dynamics(model, x, u, 0.0, Δt), x)
    fu = ForwardDiff.jacobian(u -> dynamics(model, x, u, 0.0, Δt), u)

    return fx, fu
end
