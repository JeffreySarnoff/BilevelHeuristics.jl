########################################################
########################################################
# MMF4
########################################################
########################################################

function MMF4_UL_solutions(n_solutions = 100)

    F, f, bounds_ul, bounds_lls = MMF4()

    x = 3ones(10) 
    x[6:9] .= -3

    X = Vector[]
    for t in range(2, 2.5, length=n_solutions)
        xx = copy(x)
        xx[end] = t
        push!(X, xx)
    end

    return X

end


function MMF4_ψ(x, i_follower; n_samples=100, D_ll = length(x))
        k = 5
        u = l = 4
        x1, x2, x3 = split_vector(x, k, u)

        Y = [ zeros(D_ll) for i in 1:n_samples]

        # for x3
        θ = range(0, x3[1], length = n_samples)

        if i_follower == 1
            for i = 1:n_samples
                y1, y2, y3 = split_vector(Y[i], k, l)
                y1[:] = cos.(x1)
                y2[:] .= 0.0 
                y3[:] .= θ[i]
            end
            
        elseif i_follower == 2
            for i = 1:n_samples
                y1, y2, y3 = split_vector(Y[i], k, l)
                y1[:] = -x1
                y2[:] .= 0.0 
                y3[:] .= θ[i]
            end
        elseif i_follower == 3
            θ = range(0, 2, length = n_samples)
            for i = 1:n_samples
                y1, y2, y3 = split_vector(Y[i], k, l)
                y1[:] = (x1) / 3.0
                y2[:] .= 0.0 
                y3[:] .= θ[i]
            end
        else
            error("only three followers")
        end

       return Y 
end

function MMF4()
    D_ul = 10
    bounds_ul = Array([-5ones(D_ul) 5ones(D_ul)]')
    bounds_ul[:,end] = [1, 4]


    D_ll = 10
    bounds_ll = Array([-5ones(D_ll) 5ones(D_ll)]')
    bounds_ll[:,end] = [-5, 5]

    function f(x, Y, i)
        k = 5
        u = l = 4
        x1, x2, x3 = split_vector(x, k, u)

        if i == 1
            y1, y2, y3 = split_vector(Y[1], k, l)

            p = sum( (cos.(x1) - y1).^2 )
            q = sum(y2 .^ 2)

            r1 = y3[1] ^ 2
            r2 = (y3[1] - x3[1]) ^ 2
        elseif i == 2
            y1, y2, y3 = split_vector(Y[2], k, l)

            p = 100sum( (x1 + y1).^2 )
            q = sum(abs.(y2).^(1:length(y2)))

            r1 = abs(y3[1] - x3[1]) 
            r2 = abs(y3[1]) # - x3[1]
        elseif i == 3
            y1, y2, y3 = split_vector(Y[3], k, l)

            z = (x1 - 3y1)
            p = 10.0*length(z) + sum(z .^ 2 - 10.0cos.(2π*z))
            q = 10.0*length(y2) + sum(y2 .^ 2 - 10.0cos.(20π*y2))

            r1 = x3[1]^2.0 + (y3[1]) .^ 2
            r2 = 100.0*x3[1] + (y3[1] .- 2.0).^2
        else
            error("this function only has 2 followers")
        end

        g = [0.0]
        h = [0.0]

        f1 = ((1.0 + p)*(1.0 + q)*r1)
        f2 = ((1.0 + p)*(1.0 + q)*r2)

        return [f1, f2], g, h
        
    end
    

    F(x, Y) = begin
        k = 5
        u = l = 4

        γ = 0.3
        γ2 = 0.01
        β = 4.0 # all feasible are non dominated? <=1 yes, >=1 for no 
        α = 4.0 # all LL fronts work well at UL?

        x1, x2, x3 = split_vector(x, k, u)
        y_1_1, y_1_2, y_1_3 = split_vector(Y[1], k, l)
        y_2_1, y_2_2, y_2_3 = split_vector(Y[2], k, l)
        y_3_1, y_3_2, y_3_3 = split_vector(Y[3], k, l)


        p1 = sum( (cos.(x1) - y_1_1).^2 )
        p2 = 100sum( (x1 + y_2_1).^2 )
        z = (x1 - 3y_3_1)
        p3 = 10.0*length(z) + sum(z .^ 2 - 10.0cos.(2π*z))

        P = sum( (x1 .- (3.0)).^2 ) + p1 + p2 + p3
        Q = sum( (x2 .+ 3.0).^2)


        R1 = @. 1 + floor(y_3_3[1]) - (1 - γ)*cos(α*π*x3[1])  # upper level shape
        R1 += - (1 - γ)*γ*cos( β*π * (y_1_3[1])/(2.0 * x3[1]) ) # follower 1 contribution
        R1 += - γ^2 *cos( β*π * (y_2_3[1])/(2.0 * x3[1]) ) # follower 2 contribution

        R2 = @. 3 - floor(y_3_3[1]) - (1 - γ)* sin(α*π*x3[1]) 
        R2 += - (1 - γ)*γ*sin( β*π * (y_1_3[1])/(2.0 * x3[1]) )
        R2 += - γ^2 * sin( β*π * (y_2_3[1])/(2.0 * x3[1]) )

        F1 = ((1.0 + P)*(1 + Q) * R1)
        F2 = ((1.0 + P)*(1 + Q) * R2)

        G = [0.0]
        H = [0.0]

        return [F1, F2], G, H
    end

    return F, f, bounds_ul, [bounds_ll, bounds_ll, bounds_ll], MMF4_ψ, MMF4_UL_solutions

end
