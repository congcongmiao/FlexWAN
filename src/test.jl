# using JuMP, Ipopt
# model = Model(Ipopt.Optimizer)
# @variable(model, x[1:2]);
# @NLobjective(model, Min, exp(x[1]) - sqrt(x[2]))
# @NLconstraint(model, exp(x[1]) <= 1)
# @NLconstraint(model, [i = 1:2], x[i]^i >= i)
# @NLconstraint(model, con[i = 1:2], prod(x[j] for j = 1:i) == i)
# optimize!(model) 
# @show value.(x)



using DelimitedFiles
using Debugger
using LightGraphs
using JLD
topology = "Custom_2"
transponder_num_flexgrid_set = []
transponder_num_fixgrid_set =[]
spec_flexgrid_set = []
spec_fixgrid_set = []
for demand_scale in [4,6,9,12,15,17,21,24]
    println(demand_scale)
    ILP_result = load("../plot/$(topology)/ILP_result"*string(demand_scale)*".jld")
    IPlink_num = ILP_result["IPlink_num"]
    k_paths = ILP_result["k_paths"]
    N = ILP_result["N"]
    w = ILP_result["w"]
    flexgrid_optical = ILP_result["flexgrid_optical"]

    # flexgrid_optical = readdlm("../data/flexgrid_optical_v3.txt", header=true)[1]
    reach = flexgrid_optical[:,4]
    # candi_waves_d = flexgrid_optical[:,1]
    # candi_waves_l = flexgrid_optical[:,4]
    # candi_waves_Y = floor(Int64, flexgrid_optical[:,2]/flexgrid_slot_spectrum)
    flexgrid_slot_spectrum=12.5

    candi_waves_d = []
    candi_waves_l = []
    candi_waves_Y = []
    for i in 1:length(reach)
        push!(candi_waves_d,flexgrid_optical[i,1])
        push!(candi_waves_l,reach[i])
        push!(candi_waves_Y,floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum))
    end
    candi_wavenum = length(candi_waves_d)

    transponder_num = 0
    spectrum_used = 0

    for e in 1:IPlink_num
        for k in 1:k_paths
            for j in 1:candi_wavenum
                if N[e,k,j]!=0
                    transponder_num = transponder_num + N[e,k,j]
                    spectrum_used = spectrum_used + N[e,k,j]*flexgrid_optical[j,2]
                    # println("link e,path k,N[e,k,j]:",e,",",src_node[e],",",dst_node[e],",",k,",",j,",",N[e,k,j])
                end
            end
        end
    end
    push!(transponder_num_flexgrid_set, transponder_num)
    # push!(transponder_num_fixgrid_set, sum(wavelength_data["transponder_num_fixgrid"]))
    # println(tmp,wavelength_data["transponder_num_fixgrid"])
    push!(spec_flexgrid_set, spectrum_used)
    # push!(spec_fixgrid_set, 75* sum(wavelength_data["transponder_num_fixgrid"]))

    # save("../plot/$(topology)/ILP_result"*string(demand_scale)*".jld", "IPlink_num", IPlink_num, "k_paths", k_paths, "flexgrid_optical", flexgrid_optical, "N", N, "w", w)

end

println(transponder_num_flexgrid_set)
println(spec_flexgrid_set)




topology = "Cernet_small" #Cernet_small Custom_2
length_gap_set = []
link_spec_efficiency_set = []
for demand_scale in [1]#[4,6,8,15,17,21,24]
    println(demand_scale)
    ILP_result = load("../plot/$(topology)/fig10_result"*string(demand_scale)*".jld")
    length_gap_set = ILP_result["length_gap"]
    link_spec_efficiency_set = ILP_result["link_spec_efficiency"]
    println(length_gap_set)
    println(link_spec_efficiency_set)
    # flexgrid_optical = readdlm("../data/flexgrid_optical_v3.txt", header=true)[1]
    # reach = flexgrid_optical[:,4]
    # candi_waves_d = flexgrid_optical[:,1]
    # candi_waves_l = flexgrid_optical[:,4]
    # candi_waves_Y = floor(Int64, flexgrid_optical[:,2]/flexgrid_slot_spectrum)
    # flexgrid_slot_spectrum=12.5

    # candi_waves_d = []
    # candi_waves_l = []
    # candi_waves_Y = []
    # for i in 1:length(reach)
    #     push!(candi_waves_d,flexgrid_optical[i,1])
    #     push!(candi_waves_l,reach[i])
    #     push!(candi_waves_Y,floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum))
    # end
    # candi_wavenum = length(candi_waves_d)

    # transponder_num = 0
    # spectrum_used = 0

    # for e in 1:IPlink_num
    #     for k in 1:k_paths
    #         for j in 1:candi_wavenum
    #             if N[e,k,j]!=0
    #                 transponder_num = transponder_num + N[e,k,j]
    #                 spectrum_used = spectrum_used + N[e,k,j]*flexgrid_optical[j,2]
    #                 # println("link e,path k,N[e,k,j]:",e,",",src_node[e],",",dst_node[e],",",k,",",j,",",N[e,k,j])
    #             end
    #         end
    #     end
    # end
    # push!(transponder_num_flexgrid_set, transponder_num)
    # # push!(transponder_num_fixgrid_set, sum(wavelength_data["transponder_num_fixgrid"]))
    # # println(tmp,wavelength_data["transponder_num_fixgrid"])
    # push!(spec_flexgrid_set, spectrum_used)
    # # push!(spec_fixgrid_set, 75* sum(wavelength_data["transponder_num_fixgrid"]))

    # # save("../plot/$(topology)/ILP_result"*string(demand_scale)*".jld", "IPlink_num", IPlink_num, "k_paths", k_paths, "flexgrid_optical", flexgrid_optical, "N", N, "w", w)

end


topology = "Cernet_small" #Cernet_small[1] Custom_2 [scale6]
path_length = []
length_data_rate = []
for demand_scale in [1]#[4,6,8,15,17,21,24]
    println(demand_scale)
    ILP_result = load("../plot/$(topology)/fig11a_result"*string(demand_scale)*".jld")
    path_length = ILP_result["path_length"]
    length_data_rate = ILP_result["length_data_rate"]
    println(path_length)
    println(length_data_rate)
    # flexgrid_optical = readdlm("../data/flexgrid_optical_v3.txt", header=true)[1]
    # reach = flexgrid_optical[:,4]
    # candi_waves_d = flexgrid_optical[:,1]
    # candi_waves_l = flexgrid_optical[:,4]
    # candi_waves_Y = floor(Int64, flexgrid_optical[:,2]/flexgrid_slot_spectrum)
    # flexgrid_slot_spectrum=12.5

    # candi_waves_d = []
    # candi_waves_l = []
    # candi_waves_Y = []
    # for i in 1:length(reach)
    #     push!(candi_waves_d,flexgrid_optical[i,1])
    #     push!(candi_waves_l,reach[i])
    #     push!(candi_waves_Y,floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum))
    # end
    # candi_wavenum = length(candi_waves_d)

    # transponder_num = 0
    # spectrum_used = 0

    # for e in 1:IPlink_num
    #     for k in 1:k_paths
    #         for j in 1:candi_wavenum
    #             if N[e,k,j]!=0
    #                 transponder_num = transponder_num + N[e,k,j]
    #                 spectrum_used = spectrum_used + N[e,k,j]*flexgrid_optical[j,2]
    #                 # println("link e,path k,N[e,k,j]:",e,",",src_node[e],",",dst_node[e],",",k,",",j,",",N[e,k,j])
    #             end
    #         end
    #     end
    # end
    # push!(transponder_num_flexgrid_set, transponder_num)
    # # push!(transponder_num_fixgrid_set, sum(wavelength_data["transponder_num_fixgrid"]))
    # # println(tmp,wavelength_data["transponder_num_fixgrid"])
    # push!(spec_flexgrid_set, spectrum_used)
    # # push!(spec_fixgrid_set, 75* sum(wavelength_data["transponder_num_fixgrid"]))

    # # save("../plot/$(topology)/ILP_result"*string(demand_scale)*".jld", "IPlink_num", IPlink_num, "k_paths", k_paths, "flexgrid_optical", flexgrid_optical, "N", N, "w", w)

end

# println(transponder_num_flexgrid_set)
# println(spec_flexgrid_set)









# using DelimitedFiles
# using Debugger
# using LightGraphs
# using JLD
# sum_link_based_entropy_set = []
# sum_path_based_entropy_set = []
# transponder_num_flexgrid_set = []
# transponder_num_fixgrid_set =[]
# spec_flexgrid_set = []
# spec_fixgrid_set = []
# for demand_scale in [5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5] #[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3]
#     tmp = []
#     wavelength_data=load("../plot/Custom_2/wavelength_data"*string(demand_scale)*".jld")
#     for i in wavelength_data["wavelength_2d"]
#         for j in i
#             push!(tmp, j)
#         end
#     end
#     push!(transponder_num_flexgrid_set, length(tmp))
#     push!(transponder_num_fixgrid_set, sum(wavelength_data["transponder_num_fixgrid"]))
#     # println(tmp,wavelength_data["transponder_num_fixgrid"])
#     push!(spec_flexgrid_set, sum(tmp))
#     push!(spec_fixgrid_set, 75* sum(wavelength_data["transponder_num_fixgrid"]))

#     sum_link_based_entropy=load("../plot/Custom_2/sum_link_based_entropy"*string(demand_scale)*".jld")
#     push!(sum_link_based_entropy_set, sum_link_based_entropy["sum_optical_entropy"])
#     sum_path_based_entropy=load("../plot/Custom_2/sum_path_based_entropy"*string(demand_scale)*".jld")
#     push!(sum_path_based_entropy_set, sum_path_based_entropy["sum_optical_entropy"])
# end

# println(transponder_num_flexgrid_set)
# println(transponder_num_fixgrid_set)
# println(spec_flexgrid_set)
# println(spec_fixgrid_set)

# println(sum_link_based_entropy_set)
# println(sum_path_based_entropy_set)



                # using Juniper, Ipopt, JuMP, Cbc # <- last package is optional
                # N = 4

                # function myfunction(x...)
                #     return sum(x[i].^2 for i = 1:length(x))
                # end

                # function OR(x...)
                #     r = 0.0
                #     for i in 1:length(x)
                #         r = (x[i]+r)>=1.0 ? 1.0 : 0.0
                #     end
                #     return r
                # end

                # XOR(x,y) = x!=y ? 1.0 : 0.0

                # m = Model(
                #     with_optimizer(
                #         Juniper.Optimizer;
                #             nl_solver = with_optimizer(Ipopt.Optimizer, print_level = 0),
                #             mip_solver = with_optimizer(Cbc.Optimizer, logLevel=0), # <- optional
                #             registered_functions = [
                #                 Juniper.register(:myfunction,  N, myfunction; autodiff = true)
                #                 Juniper.register(:OR, N, OR; autodiff = true)
                #                 Juniper.register(:XOR, 2, XOR; autodiff = true)
                #             ]
                #         )
                #     )
                # register(m, :myfunction, N, myfunction; autodiff = true)
                # register(m, :OR, N, OR; autodiff = true)
                # register(m, :XOR, 2, XOR; autodiff = true)

                # @variable(m, x[1:N], Bin)

                # # @NLconstraint(m, sum(sin(x[i]^2) for i=1:N) <= 4)   
                # # @NLconstraint(m, XOR(0, x[1])+XOR(x[N], 0)+sum(XOR(x[i], x[i+1]) for i in 1:length(x)-1)<=2)
                # @NLconstraint(m, OR(x...)<=2)
                # @constraint(m, x[1]+x[2]+x[3] <= 5)   

                # @NLobjective(m, Max, myfunction(x...))
                # optimize!(m)

                # println(JuMP.value.(x))
                # println(JuMP.objective_value(m))


                # println(JuMP.termination_status(m))



# using JuMP, Ipopt, Cbc, Juniper
# L=[[1,2],[3,4],[5,6]]

# XOR(x,y) = x!=y ? 1.0 : 0.0
# OR(x) = length(x)>=1 ? 1.0 : 0.0
# using JuMP
# using Ipopt
# model =Model(Cbc.Optimizer)
# # model = Model(Ipopt.Optimizer)
# solver = Juniper.Optimizer(Ipopt.Optimizer; mip_solver=Cbc.Optimizer)
# model = Model(solver=solver)
# # set_optimizer_attribute(model, "OutputFlag", 0)
# # set_optimizer_attribute(model, "Threads", 32)

# set_silent(model)
# @variable(model, z)
# @variable(model, x[1:10] >= 0);

# register(model, :XOR, 2, XOR; autodiff = true)
# register(model, :OR, 1, OR; autodiff = true)

# @NLconstraint(model, sum(exp(x[i]) for i in 1:length(x)) <= L[3][2])
# @NLconstraint(model, sum(XOR(x[i], x[i+1]) for i in 1:length(x)-1)<=2)
# # @NLconstraint(model, sum(OR(x) <= 1 for i in 1:length(x)-1)<=2)

# @NLobjective(model, Min, (z - *(x...)^2))
# optimize!(model)
# @show value.(x) # Equals 1.0.













# using Dates, HDF5, JLD, Formatting


# include("./enviroment.jl")
# include("./evaluations.jl")
# include("./restoration.jl")
# include("./plotting.jl")

# T1, Tf1 = getTunnels(IPTopo, flows, tunnelK_s, new_tunnel_or_not, verbose, IPScenarios["code"], edge_disjoint=tunnel_rounting)

# TunnelBw = [550.37611840625 0.0 0.0 0.0; 13.088331553 0.0 0.0 0.0; 800.0 0.0 0.0 0.0]
# TunnelBw_q = deepcopy(TunnelBw)
# # println(a[2,:])
# TunnelBw=[]
# for vec in 1:size(TunnelBw_q,1)
#     push!(TunnelBw, maximum(TunnelBw_q[vec,:]))
# end
# println("TunnelBw ", TunnelBw)
# println("TunnelBw_q ", TunnelBw_q)

# TunnelBw_before = [550.37611840625 0.0 0.0 0.0; 13.088331553 0.0 0.0 0.0; 800.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 900.0 0.0 0.0 0.0; 660.1906917702499 0.0 0.0 0.0; 345.09119853225 0.0 0.0 0.0; 0.06322636474997978 36.53555004075002 0.0 0.0; 599.75947283425 0.0 0.0 0.0; 886.911668447 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 799.919933378 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 983.77140066425 0.0 0.0 0.0; 743.13030393175 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 661.50271037475 0.0 0.0 0.0; 0.24052716575 0.0 0.0 0.0; 897.71766662775 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 0.08006662199999999 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 400.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 1.9617395845 0.0 0.0 0.0; 772.6707954285 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 798.139747154 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 900.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 27.3292045715 0.0 0.0 0.0; 0.0 65.36704138524999 0.0 0.0; 726.901704596 0.0 0.0 0.0; 177.51405205875 0.0 0.0 0.0; 800.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 900.0 0.0 0.0 0.0; 375.24789118974996 0.0 0.0 0.0; 0.0 16.22859933575 0.0 0.0; 0.0 56.86969606825001 0.0 0.0; 127.39243093624998 0.0 81.87101536624999 0.0; 572.60756906375 0.0 0.0 0.0; 437.82962102125 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 694.857134898 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 34.65400844725 0.0 0.0 0.0; 127.51637053149999 0.0 0.0 0.0; 1400.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 894.59717918675 0.0 0.0 0.0; 574.9209923945 0.0 0.0 0.0; 900.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 1500.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 534.63295861475 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 422.48594794125 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 698.4079521545 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 900.0 0.0 0.0 0.0; 800.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 518.12898463375 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 894.8447002175 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 0.0 1.5920478455000002 0.0 0.0; 600.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 798.4079521545 0.0 0.0 0.0; 5.1552997825 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 800.0 0.0 0.0 0.0; 360.936546551 0.0 0.0 0.0; 887.16045486325 0.0 0.0 0.0; 1.8602528459999998 0.0 0.0 0.0; 8.63498844175 0.0 0.0 0.0; 1500.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 1.7189764147499997 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 689.6460351435 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 5.402820813250001 0.0 0.0 0.0; 25.079007605499996 0.0 0.0 0.0; 569.51817158125 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 1000.0 0.0 0.0 0.0; 1400.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 700.0 0.0 0.0 0.0; 39.063453449 0.0 0.0 0.0; 10.97929229075 0.0 0.0 0.0; 0.0 5.142865102 0.0 0.0; 1386.22214645625 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 600.0 0.0 0.0 0.0; 598.28102358525 0.0 0.0 0.0; 649.95725426025 0.0 0.0 0.0; 1400.0 0.0 0.0 0.0]
scenario= Any[[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0], [1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]]
println("scenario ", length(scenario))
# TunnelBw = [550.37611840625 0.0 0.0 0.0; 13.088331553 0.0 0.0 0.0; 800.0 0.0 0.0 0.0;;;
#             0.0 2.2693898957500003 0.0 0.0; 0.0 0.0 0.0 0.0; 2.35301969875 0.0 0.0 0.0]

# 132 * 4 * 3

# println("TunnelBw_before ", size(TunnelBw))

# A = zeros(2,4,3)
# A[:,:,1] = [1 2 3 4; 5 6 7 8]
# A[:,:,2] = [10 20 30 40; 50 60 70 80]
# A[:,:,3] = [100 200 300 400; 500 600 700 800]
# println(size(A))
# println(A)

# print(size(A)[3])

# A = [1,2,3,4]
# C = [10,20,30,40]
# B = []
# push!(B,A)
# push!(B,C)
# println("B ", B)
# println("B ", B[1])
# println("B size ", size(B))


# using Dates, HDF5, JLD


# include("./enviroment.jl")
# include("./evaluations.jl")
# include("./restoration.jl")
# include("./plotting.jl")

# #在所有场景的票中提取（删除重复项）随机取整的票，但不考虑那些0恢复容量的不可恢复的方案
# ## distill (remove duplicates) randomized rounded tickets among all scenarios, but do not consider the 0 restored capacity in those non-restorable scenarios
# function distill_tickets(rr_scenario_restored_bw, IPTopo, IPScenarios, verbose)
#     distill_rr_scenario_restored_bw = []
#     max_ticket_num = 0
#     for q in 1:length(IPScenarios["code"])
#         for r in 1:size(rr_scenario_restored_bw[q], 1)
#             # println("rr_scenario_restored_bw[q][r] ", rr_scenario_restored_bw[q][r])
#             # println(zeros(length(IPTopo["capacity"])))
#             #容量没有变化，即没有恢复
#             if rr_scenario_restored_bw[q][r] == IPTopo["capacity"] .* IPScenarios["code"][q]  # recognize no restoration happens, 0 paddings
#                 if r > max_ticket_num
#                     #
#                     max_ticket_num = r
#                 end
#             end
#         end
#     end
#     if verbose println("max_ticket_num ", max_ticket_num) end

#     for q in 1:length(IPScenarios["code"])
#         distill_rr_current_scenario_restored_bw = []
#         for r in 1:max_ticket_num
#             push!(distill_rr_current_scenario_restored_bw, rr_scenario_restored_bw[q][r])
#         end
#         push!(distill_rr_scenario_restored_bw, distill_rr_current_scenario_restored_bw)
#     end

#     return distill_rr_scenario_restored_bw
# end

# # 生成/读取票，如果生成，以并行模式运行，如果读取，以单线程模式运行
# ## Generating/Reading lottery tickets, if generating, run in parallel mode, if reading, run in single thread mode
# function lottery_ticket_generation(GRB_ENV, ticket_dir, RWAFileName, LPFileName, TicketFileName, IPTopo, IPScenarios, OpticalTopo, OpticalScenarios, scenario_generation_only, optical_rerouting_K, option_num, option_gap, scenario_id, topology_index, verbose, ticket_or_not, progress0)
#     #不同故障场景的rwa解决方案list
#     #不同场景的rwa lp解决方案list
#     #不同场景的票list
#     #每个场景的票与LP解决方案的差距
#     rwa_scenario_restored_bw = []  # list of rwa solutions for different scenarios
#     rwa_lp_scenario_restored_bw = []  # list of rwa lp solutions for different scenarios
#     rr_scenario_restored_bw = []  # list of lottery tickets for different scenarios
#     absolute_gap = zeros(length(IPScenarios["code"]))  # the gap of sum tickets to LP solution for each scenario

#     fiber_lost = []
#     fiber_provisioned = []
#     fiber_restorationratio = []

#     if scenario_generation_only == 0
#         PyPlot.clf()  # plotting lottery tickets
#     end

#     #迭代场景文件中的每个可能的故障场景，可以针对场景文件中的每个场景进行并行化
#     ## iterating each possible failure scenario in the scenario file, this can be parallelized for each scenario in the scenario file
#     for q in 1:length(IPScenarios["code"])
#         ## only generate tickets for this given failure scenario
#         #如果只是生成票，那么并行化生成，并行化调用lottery_ticket_generation，scenario_generation_only就是每个并行化的场景的index
#         if scenario_generation_only > 0
#             if verbose println("Parallel generating lottery tickets for $(scenario_generation_only) scenario") end
#             q = scenario_generation_only
#         end
#         if verbose println("Generating tickets for fiber cut scenario: ", OpticalScenarios["code"][q]) end

#         ## store tickets for the current scenario
#         #当前故障场景的rwa解决方案list
#         #当前场景的rwa lp解决方案list
#         #当前场景的票list
#         rwa_current_scenario_restored_bw = []
#         rwa_lp_current_scenario_restored_bw = []
#         rr_current_scenario_restored_bw = []
       
#         ## this is a failure scenario
#         #求和code判断当前场景存在故障
#         if sum(IPScenarios["code"][q]) < length(IPScenarios["code"][q])
#             ## locate failure scenario on cross-layer topo
#             #定位故障光纤的index
#             failed_fibers_index = FailureLocator(OpticalTopo, OpticalScenarios["code"][q])
#             #故障的IP link，IP link的index，及其capacity容量
#             failed_IPedge, failed_IP_initialindex, failed_IP_initialbw = ReadFailureScenario(IPScenarios["code"][q], IPTopo["links"], IPTopo["capacity"])
#             #计算故障的IP link的波长数量=容量/100 (假设一个波长承载100Gbps)
#             push!(fiber_provisioned, sum(failed_IP_initialbw)/100)
#             if verbose println("\nfailed_IPedge: ", failed_IPedge) end
#             if verbose println("failed_IP_initialbw (wavelength number): ", sum(failed_IP_initialbw)/100, " ", failed_IP_initialbw./100) end

#             #计算故障IP link的新路由，每个IP link找到optical_rerouting_K条新路由
#             ## routing of restored wavelengths
#             #重新规划的IP link路由,形式是光纤link的index,[[1,2,5],[2,3],   [8,2],[2,3,4],   [3,2],[9,3]]代表3个fail IP link的新光纤路由,放在了一起
#             #重新规划的IP link路由,形式是光纤<src node, dst node> 序列
#             #重新规划的所有IP link的index数组，[1,2,3,4,5,6]代表3个fail IP link的新光纤路由的index，放在了一起
#             #重新规划的IP link的index group,[[1,2],[3,4],[5,6]]分布代表3个fail IP link的新光纤路由的index，不同的IP link的index放在不同的group
#             rehoused_IProutingEdge, rehoused_IProuting, failedIPbranckindex, failedIPbrachGroup = WaveRerouting(OpticalTopo, failed_IPedge, failed_fibers_index, optical_rerouting_K)
#             if verbose println("rehoused_IProutingEdge: ", rehoused_IProutingEdge) end
#             if verbose println("rehoused_IProuting: ", rehoused_IProuting) end
#             if verbose println("failedIPbranckindex: ", failedIPbranckindex) end
#             if verbose println("failedIPbrachGroup: ", failedIPbrachGroup) end

#             #故障IP link的路由恢复后的波长分配（ILP）
#             #IP link的带宽分配 restored_bw_rwa： restored_bw[1:nfailedIPedges] >= 0, Int)  
#             #IP link对应的IP branch上的带宽分配 IPBranch_bw： IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink]
#             ## wavelength assignment of routed restored wavelengths (ILP)
#             rwa_runtime = @timed restored_bw_rwa, obj, IPBranch_bw = RestoreILP(GRB_ENV, OpticalTopo["links"], OpticalTopo["capacityCode"], failed_IPedge, rehoused_IProutingEdge, failedIPbranckindex, failedIPbrachGroup, failed_IP_initialbw, optical_rerouting_K)
#             if verbose println("wavelength continuous ILP results: ", sum(restored_bw_rwa), " ", restored_bw_rwa) end
#             if verbose println("wavelength continuous ILP IP branch results:", IPBranch_bw) end
#             if verbose println("wavelength continuous ILP runtime: ", rwa_runtime[2]) end

#             #更新rwa恢复后所有IP link的capacity(ILP)，把故障的IP link重分配的带宽更新(ILP)
#             rwa_full_capacity = deepcopy(IPTopo["capacity"])
#             for i in 1:length(failed_IP_initialindex)
#                 #波长*100=capacity
#                 rwa_full_capacity[failed_IP_initialindex[i]] = Int(round(restored_bw_rwa[i])) * 100  # each wave 100 Gbps
#             end
#             rwa_current_scenario_restored_bw = rwa_full_capacity  # network capacity vector of all links after rwa restoration
#             push!(rwa_scenario_restored_bw, rwa_current_scenario_restored_bw)
#             if verbose println("wavelength continuous ILP full capacity: ", rwa_current_scenario_restored_bw) end
            
#             #故障IP link的路由恢复后的波长分配（LP）
#             ## wavelength assignment of routed restored wavelengths (relaxed LP)
#             lp_runtime = @timed lp_restored_bw, obj, lp_IPBranch_bw = RestoreLP(GRB_ENV, OpticalTopo["links"], OpticalTopo["capacityCode"], failed_IPedge, rehoused_IProutingEdge, failedIPbranckindex, failedIPbrachGroup, failed_IP_initialbw, optical_rerouting_K)
#             if verbose println("relaxed LP results: ", sum(lp_restored_bw), " ", lp_restored_bw) end
#             if verbose println("relaxed LP IP branch results:", lp_IPBranch_bw) end
#             if verbose println("relaxed LP runtime: ", lp_runtime[2]) end

#             #更新rwa恢复后 所有 IP link的capacity(LP)，把故障的IP link重分配的带宽更新
#             rwa_lp_full_capacity = deepcopy(IPTopo["capacity"])
#             for i in 1:length(failed_IP_initialindex)
#                 rwa_lp_full_capacity[failed_IP_initialindex[i]] = Int(round(lp_restored_bw[i])) * 100  # each wave 100 Gbps
#             end
#             rwa_lp_current_scenario_restored_bw = rwa_lp_full_capacity  # network capacity vector of all links after rwa restoration
#             push!(rwa_lp_scenario_restored_bw, rwa_lp_current_scenario_restored_bw)
#             if verbose println("wavelength continuous LP full capacity: ", rwa_lp_current_scenario_restored_bw) end
            
#             #ARROW时只load tickets
#             ## only load lottery tickets if it is ARROW
#             if ticket_or_not == 2  
#                 ## absolute gap for bounding the ARROW tickets
#                 #absolute_gap：ticket随机四舍五入后的capacity，与初始capacity的最大差距，不能大于这个差距，否则在RandomRounding中会被删去filter
#                 absolute_gap[q]= (1-option_gap) * sum(lp_restored_bw) * 100

#                 ## Randomized rounding
#                 if verbose printstyled("Now - Running randomized rounding algorithm\n", color=:blue) end
#                 #对RWA lp的结果随机四舍五入，restored_bw_rr是四舍五入的ticket的结果, 每组产生 option_num 张 tickets
#                 restored_bw_rr = RandomRounding(GRB_ENV, lp_restored_bw, restored_bw_rwa, failed_IPedge, failed_IP_initialbw, option_num, option_gap, OpticalTopo, rehoused_IProutingEdge, failedIPbranckindex, failedIPbrachGroup, optical_rerouting_K, verbose)
#                 if verbose println("randomized rounding results: ", restored_bw_rr) end                
#                 if verbose println("randomized rounding capacities: ") end
#                 for x in 1:size(restored_bw_rr,1)  # different rr scenarios
#                     if verbose println("Ticket $(x) sum restore capacity: ", sum(restored_bw_rr[x,:])) end
#                     if verbose println("Ticket $(x) restore capacity: ", restored_bw_rr[x,:]) end

#                     #计算修复率，可视化
#                     ## print and calculate restoration ratios for visualization of non-parallel generation
#                     if scenario_generation_only == 0 
#                         scenario_restorationratio = []
#                         for e in 1:size(restored_bw_rr,2)
#                             #每个场景x中的每个IP link e的修复率=修复后随机四舍五入的容量/初始容量
#                             edge_restore_ratio = restored_bw_rr[x,e] / (failed_IP_initialbw[e]/100)
#                             # println("edge_restore_ratio: ", edge_restore_ratio)
#                             push!(scenario_restorationratio, edge_restore_ratio)
#                         end
#                         #画每个场景x中的每个IP link e的修复率的CDF图
#                         sorted_edge_restore_ratio = sort(scenario_restorationratio)
#                         cdf = []
#                         for i in 1:length(sorted_edge_restore_ratio)
#                             push!(cdf, i/length(sorted_edge_restore_ratio))
#                         end
#                         PyPlot.plot(sorted_edge_restore_ratio, cdf, marker="P", alpha = 0.6, linewidth=0.5)
#                         if verbose println("Ticket $(x) scenario_restorationratio: ", scenario_restorationratio) end
#                     end
#                 end
#                 # if it is randomize rounding then there are multiple restored_bw options
#                 for t in 1:size(restored_bw_rr, 1)
#                     rr_full_capacity = deepcopy(IPTopo["capacity"])
#                     for i in 1:length(failed_IP_initialindex)
#                         rr_full_capacity[failed_IP_initialindex[i]] = Int(round(restored_bw_rr[t,i])) * 100
#                     end
#                     #当前场景，故障恢复后所有IP link的票(branch)的capacity
#                     push!(rr_current_scenario_restored_bw, rr_full_capacity)  # network capacity vector of all links after rr restoration
#                 end
#                 #所有场景的，故障恢复后所有IP link的票(branch)的capacity
#                 push!(rr_scenario_restored_bw, rr_current_scenario_restored_bw)
#             end

#             #不需要随机四舍五入的话，直接计算RWA后的波长修复数
#             # if it not randomize rounding then only one restored_bw options
#             if scenario_generation_only == 0
#                 push!(fiber_lost, (sum(IPTopo["capacity"])-sum(rwa_scenario_restored_bw[q]))/100)
#             end

#         #无故障的场景，都等于IPTopo["capacity"]，capacity保持不变
#         # this is a non-failure scenario
#         else
#             if verbose println("Healthy network without failures") end
#             rwa_current_scenario_restored_bw = deepcopy(IPTopo["capacity"])
#             push!(rwa_scenario_restored_bw, rwa_current_scenario_restored_bw)
            
#             rwa_lp_current_scenario_restored_bw = deepcopy(IPTopo["capacity"])
#             push!(rwa_lp_scenario_restored_bw, rwa_lp_current_scenario_restored_bw)
                    
#             if ticket_or_not == 2  # only load lottery tickets if it is ARROW
#                 rr_current_scenario_restored_bw_0 = deepcopy(IPTopo["capacity"])
#                 for i in 1:option_num
#                     push!(rr_current_scenario_restored_bw, rr_current_scenario_restored_bw_0)
#                 end
#                 push!(rr_scenario_restored_bw, rr_current_scenario_restored_bw)
#             end
#             #无故障，则为0
#             absolute_gap[q] = 0
#         end
#         ProgressMeter.next!(progress0, showvalues = [])

#         ## single operation of a parallel ticket generation
#         if scenario_generation_only > 0
#             break
#         end
#     end

#     ## if not parallel generation, we distill tickets here, otherwise, distill at aggregation function
#     if scenario_generation_only == 0
#         #如果 scenario_generation_only ==0，则为所有场景生成票，并存入一个文件，>0时，只为第scenario_generation_only个场景生成票
#         #因此，==0时 在这里就提取distill票（删去重复项）；否则返回第scenario_generation_only个场景的生成的票，之后在aggregation function再distill
#         distill_rr_scenario_restored_bw = distill_tickets(rr_scenario_restored_bw, IPTopo, IPScenarios, verbose)

#         #画 RWA后的波长修复数 和 故障的IP link的波长数量的 CDF图
#         ## finising the plotting of randomized rounding tickets
#         figname = "$(ticket_dir)/02_restorationratio_IP_rr_topo$(topology_index)_scenario$(scenario_id)_wave$(size(OpticalTopo["capacityCode"],2)).png"
#         PyPlot.xlabel("Restoration ratio for IP links")
#         PyPlot.ylabel("CDF")
#         PyPlot.savefig(figname)
#         if verbose
#             println("fiber_lost ", fiber_lost)
#             println("fiber_provisioned ", fiber_provisioned)
#         end
        
#         #画  RWA后的波长修复率=(fiber_provisioned[t]-fiber_lost[t])/fiber_provisioned[t])
#         ## plotting restoration ratios (CDF) of RWA
#         PyPlot.clf()
#         fiber_restorationratio = []
#         for t in 1:length(fiber_lost)
#             push!(fiber_restorationratio, (fiber_provisioned[t]-fiber_lost[t])/fiber_provisioned[t])
#         end
#         sorted_fiber_restorationratio = sort(fiber_restorationratio)
#         cdf = []
#         for i in 1:length(sorted_fiber_restorationratio)
#             push!(cdf, i/length(sorted_fiber_restorationratio))
#         end
#         PyPlot.plot(sorted_fiber_restorationratio, cdf, marker="P", linewidth=1)
#         figname = "$(ticket_dir)/02_restorationratio_fiber_rwa_cdf_topo$(topology_index)_scenario$(scenario_id)_wave$(size(OpticalTopo["capacityCode"],2)).png"
#         PyPlot.xlabel("Scenario restoration ratio on fibers")
#         PyPlot.ylabel("CDF")
#         PyPlot.savefig(figname)

#         #画 fiber_provisioned对应 fiber_restorationratio的 散点图
#         ## plotting restoration ratios (scatter points) of RWA
#         PyPlot.clf()
#         PyPlot.scatter(fiber_provisioned, fiber_restorationratio, alpha = 0.25)
#         figname = "$(ticket_dir)/02_restorationratio_fiber_rwa_scatter_topo$(topology_index)_scenario$(scenario_id)_wave$(size(OpticalTopo["capacityCode"],2)).png"
#         PyPlot.xlabel("Scenario's lost wavelengths on fiber")
#         PyPlot.ylabel("Restoration ratio")
#         PyPlot.savefig(figname)
#     else
#         distill_rr_scenario_restored_bw = rr_scenario_restored_bw
#     end

    
#     #所有IP link的带宽分配，里面故障的IP link的带宽已经重分配(ILP)
#     ## save the tickets into .jld
#     JLD.save(RWAFileName, "rwa_scenario_restored_bw", rwa_scenario_restored_bw)
#     open(replace(RWAFileName, ".jld"=>".txt"), "w+") do io
#         for q in 1:length(IPScenarios["code"])
#             if scenario_generation_only > 0
#                 q = scenario_generation_only
#                 writedlm(io, (IPScenarios["code"][q], rwa_scenario_restored_bw[1]))
#                 break
#             else
#                 writedlm(io, (IPScenarios["code"][q], rwa_scenario_restored_bw[q]))
#             end
            
#         end
#     end

#     #所有IP link的带宽分配，里面故障的IP link的带宽已经重分配(LP)
#     JLD.save(LPFileName, "rwa_lp_scenario_restored_bw", rwa_lp_scenario_restored_bw)
#     open(replace(LPFileName, ".jld"=>".txt"), "w+") do io
#         for q in 1:length(IPScenarios["code"])
#             if scenario_generation_only > 0
#                 q = scenario_generation_only
#                 writedlm(io, (IPScenarios["code"][q], rwa_lp_scenario_restored_bw[1]))
#                 break
#             else
#                 writedlm(io, (IPScenarios["code"][q], rwa_lp_scenario_restored_bw[q]))
#             end
#         end
#     end
    
#     #返回distill后的 所有IP link的带宽分配
#     if ticket_or_not == 2  # only handle lottery tickets if it is ARROW
#         JLD.save(TicketFileName, "lottery_ticket_restored_bw", distill_rr_scenario_restored_bw)
#         open(replace(TicketFileName, ".jld"=>".txt"), "w+") do io
#             for q in 1:length(IPScenarios["code"])
#                 if scenario_generation_only > 0
#                     q = scenario_generation_only
#                     writedlm(io, (IPScenarios["code"][q], distill_rr_scenario_restored_bw[1]))
#                     break
#                 else
#                     writedlm(io, (IPScenarios["code"][q], distill_rr_scenario_restored_bw[q]))
#                 end
#             end
#         end
#     end

#     return rwa_scenario_restored_bw, distill_rr_scenario_restored_bw, absolute_gap
# end


# ## loading existing lottery tickets
# function lottery_ticket_loading(RWAFileName, LPFileName, TicketFileName, IPScenarios, option_gap, progress0)
#     rwa_scenario_restored_bw = load(RWAFileName, "rwa_scenario_restored_bw")  # load RWA ILP results
#     rwa_lp_scenario_restored_bw = load(LPFileName, "rwa_lp_scenario_restored_bw")  # load RWA LP results
#     lottery_ticket_restored_bw = load(TicketFileName, "lottery_ticket_restored_bw")  # load existing tickets
#     #随机四舍五入
#     absolute_gap = zeros(length(IPScenarios["code"]))  # the gap of sum tickets to LP solution for each scenario

#     #迭代scenario文件中的每个可能的故障scenario，scenario文件中的每个scenario可以并行化跑
#     ## iterating each possible failure scenario in the scenario file, this can be parallelized for each scenario in the scenario file
#     for q in 1:length(IPScenarios["code"])
#         lp_restored_bw = rwa_lp_scenario_restored_bw[q]
#         absolute_gap[q]= (1-option_gap) * sum(lp_restored_bw) * 100
#     end
#     ProgressMeter.next!(progress0, showvalues = [])

#     return rwa_scenario_restored_bw, lottery_ticket_restored_bw, absolute_gap
# end


# ## get failure scenarios files
# #生成失败场景的文件
# function get_failure_scenarios(dir, topology, topology_index, verbose, scenario_cutoff, scenario_id, weibull_or_k, failure_free, expanded_spectrum)
#     #scenario_cutoff表示cutoff概率，weibull_failure为真时则基于韦伯分布产生光纤切断，产生链路失败的场景；否则无需产生切断，从文件中解析故障分布
#     if scenario_cutoff == 0
#         weibull_failure = false  ## no cutoff needed, parse failure distribution from files
#     else
#         weibull_failure = true  ## apply cutoff to weibull distribution for link failure distribution
#     end

#     ## Get the network topology
#     #获取IP层，光层的拓扑信息
#     IPTopo, OpticalTopo = ReadCrossLayerTopo(dir, topology, topology_index, verbose, expanded_spectrum, weibull_failure=weibull_failure, IPfromFile=true, tofile=false)

#     ## plotting spectrum utilization
#     #画光纤的已使用的频谱cfd图
#     fiber_capacity = OpticalTopo["capacity"]
#     if verbose println("fiber_capacity $(fiber_capacity)") end
#     if verbose println("fiber capacity code $(OpticalTopo["capacityCode"])") end
#     fiber_utilization = []
#     cdf = []
#     for x in 1:length(fiber_capacity)
#         #每条光纤 已使用的频谱=总频谱-空余的频谱
#         push!(fiber_utilization, 96+expanded_spectrum-fiber_capacity[x])
#         push!(cdf, x/length(fiber_capacity))
#     end
#     fiber_utilization = sort(fiber_utilization)

#     open("$(dir)/$(topology)/00_fiber_spectrum.txt", "w+") do io
#         writedlm(io, ("spectrum", fiber_utilization))
#         writedlm(io, ("cdf", cdf))
#     end

#     PyPlot.clf()
#     PyPlot.plot(fiber_utilization, cdf, marker="P", alpha = 0.8)
#     figname = "$(dir)/$(topology)/00_fiber_spectrum.png"
#     PyPlot.xlabel("Occupied wavelength number per fiber")
#     PyPlot.ylabel("CDF")
#     PyPlot.savefig(figname)

#     if failure_free
#         #生成没有光纤cutoff的场景
#         ## there is no fiber cut scenarios
#         #IP场景字典，code对应每一个IP link的全1编码，prob表示概率
#         IPScenarios = Dict()
#         IPScenarios["code"] = [ones(length(IPTopo["links"]))]
#         IPScenarios["prob"] = [1]
#         OpticalScenarios = Dict()
#         OpticalScenarios["code"] = [ones(length(OpticalTopo["links"]))]
#         OpticalScenarios["prob"] = [1]
#     else 
#         #生成光纤cutoff的场景
#         ## get all fiber cut scenarios on this topology, and store them into file
#         if verbose println("Computing fiber cut scenarios...cutoff=$(scenario_cutoff)") end
#         failureFileName =  "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_ip_scenarios_$(scenario_id).jld"
#         if isfile(failureFileName) == false
#             if weibull_or_k == 1
#                 #生成
#                 IPScenarios, OpticalScenarios = GetAllScenarios(IPTopo, OpticalTopo, scenario_cutoff, false, 1)
#             else
#                 #所有光纤都有可能cutoff
#                 IPScenarios, OpticalScenarios = GetAllScenarios(IPTopo, OpticalTopo, 0, true, 1)  # all single fiber cut scenario
#             end
#             JLD.save(failureFileName, "IPScenarios", IPScenarios, "OpticalScenarios", OpticalScenarios)
#             open("./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_ip_scenarios_$(scenario_id).txt", "w+") do io
#                 for i in 1:size(IPScenarios["code"],1)
#                     writedlm(io, (IPScenarios["prob"][i], IPScenarios["code"][i]))
#                 end
#             end
#         else
#             data = load(failureFileName)
#             IPScenarios, OpticalScenarios = data["IPScenarios"], data["OpticalScenarios"]
#         end
#         if verbose println("Scenario number: ", size(IPScenarios["code"],1)) end

#         ## plot failure distribution
#         failureprobIP = IPScenarios["prob"]
#         cdf_IP = []
#         for x in 1:length(failureprobIP)
#             push!(cdf_IP, x/length(failureprobIP))
#         end
#         sorted_failureprobIP = sort(failureprobIP)
#         PyPlot.clf()
#         PyPlot.plot(sorted_failureprobIP, cdf_IP, marker="P", alpha = 0.8, label=topology)
#         figname = "$(dir)/$(topology)/01_failure_scenario_prob_$(scenario_id).png"
#         PyPlot.xscale("log")
#         PyPlot.legend(loc="upper left")
#         PyPlot.savefig(figname)
#     end

#     return IPTopo, OpticalTopo, IPScenarios, OpticalScenarios
# end

# ## 故障场景下选ticket
# ## abstracting optical layer's restoration candidates considering failure scenarios
# function abstract_optical_layer(GRB_ENV, IPTopo, OpticalTopo, IPScenarios, OpticalScenarios, scenario_generation_only, dir, topology, topology_index, verbose, scenario_cutoff, scenario_id, optical_rerouting_K, partial_load_full_tickets, option_num, large_option_num, option_gap, ticket_or_not, expanded_spectrum)
#     ## if we read partial tickets
#     partial_tickets = large_option_num
#     if partial_load_full_tickets
#         if option_num < large_option_num
#             partial_tickets = deepcopy(option_num)
#             option_num = large_option_num
#         end
#     end
#     if ticket_or_not > 0
#         ## 根据故障场景使用随机舍入生成彩票 generate lottery tickets using random rounding based on failure scenarios
#         ticket_dir = "$(dir)/$(topology)"
#         #scenario_generation_only == 0 ，则为所有场景生成票，并存入一个文件，>0时，只为第scenario_generation_only个场景生成票
#         if scenario_generation_only == 0  # generate tickets for all scenarios in a scenario file
#             if expanded_spectrum == 0
#                 RWAFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_rwa_scenario_restored_$(scenario_id).jld"
#                 LPFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lp_bw_scenario_restored_$(scenario_id).jld"
#                 TicketFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lotterytickets$(option_num)_$(scenario_id).jld"
#             else
#                 RWAFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_rwa_scenario_restored_$(scenario_id)_extend_$(expanded_spectrum).jld"
#                 LPFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lp_bw_scenario_restored_$(scenario_id)_extend_$(expanded_spectrum).jld"
#                 TicketFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lotterytickets$(option_num)_$(scenario_id)_extend_$(expanded_spectrum).jld"
#             end
#         else  
#             # generate tickets for only for expanded_spectrum'th scenarios in a scenario file
#             # 仅为频谱扩展expanded_spectrum的场景生成ticket
#             if expanded_spectrum == 0
#                 RWAFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_rwa_scenario_restored_$(scenario_id)_$(scenario_generation_only).jld"
#                 LPFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lp_bw_scenario_restored_$(scenario_id)_$(scenario_generation_only).jld"
#                 TicketFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lotterytickets$(option_num)_$(scenario_id)_$(scenario_generation_only).jld"
#             else
#                 RWAFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_rwa_scenario_restored_$(scenario_id)_$(scenario_generation_only)_extend_$(expanded_spectrum).jld"
#                 LPFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lp_bw_scenario_restored_$(scenario_id)_$(scenario_generation_only)_extend_$(expanded_spectrum).jld"
#                 TicketFileName = "./data/topology/$(topology)/IP_topo_$(topology_index)/$(scenario_cutoff)_lotterytickets$(option_num)_$(scenario_id)_$(scenario_generation_only)_extend_$(expanded_spectrum).jld"
#             end
#         end

#         #检查RWA，LP和ticket文件是否存在，以确定是否生成新票 还是 加载现有票
#         ## check the file exists or not to determine generate new or load existing lottery tickets
#         RWA_exists = false
#         if isfile(RWAFileName)
#             RWA_exists = true
#         end
#         LP_exists = false
#         if isfile(LPFileName)
#             LP_exists = true
#         end
#         Ticket_exists = false
#         if isfile(TicketFileName)
#             Ticket_exists = true
#         end
#         #加载现有票
#         if RWA_exists && LP_exists && Ticket_exists
#             ## load existing lottery tickets
#             progress0 = ProgressMeter.Progress(length(IPScenarios["code"]), .1, "Loading $(partial_tickets)/$(option_num) lottery tickets (restoration options) on $(size(OpticalTopo["capacityCode"],2)) wave fiber under failure scenario file-$(scenario_id) from file...\n", 50)
#             if scenario_generation_only == 0
#                 #直接读取 每个scenario的RWA ILP的IP link的恢复带宽，distill后的LP的ticket的IP link的恢复带宽，和absolute_gap(四舍五入后与初始容量的差距gap)
#                 #文件格式具体什么意思?
#                 rwa_scenario_restored_bw, full_rr_scenario_restored_bw, absolute_gap = lottery_ticket_loading(RWAFileName, LPFileName, TicketFileName, IPScenarios, option_gap, progress0)
#                 rr_scenario_restored_bw = []
#                 for q in 1:length(IPScenarios["code"])
#                     #从大的ticket文件中读取所需数量的部分ticket
#                     push!(rr_scenario_restored_bw, full_rr_scenario_restored_bw[q][1:partial_tickets])
#                 end
#             else
#                 rwa_scenario_restored_bw = []
#                 rr_scenario_restored_bw = []
#                 absolute_gap = []
#             end
#         else
#             #生成新票
#             ## generate new lottery tickets
#             if scenario_generation_only == 0 
#                 progress0 = ProgressMeter.Progress(length(IPScenarios["code"]), .1, "[Serial] Computing $(option_num) lottery tickets (restoration options) on $(size(OpticalTopo["capacityCode"],2)) wave fiber under failure scenario file-$(scenario_id)...\n", 50)
#             else
#                 progress0 = ProgressMeter.Progress(length(IPScenarios["code"]), .1, "[Parallel] Computing $(option_num) lottery tickets (restoration options) on $(size(OpticalTopo["capacityCode"],2)) wave fiber under failure scenario file-$(scenario_id) & scenario-$(scenario_generation_only)...\n", 50)
#             end
#             #生成新票
#             rwa_scenario_restored_bw, rr_scenario_restored_bw, absolute_gap = lottery_ticket_generation(GRB_ENV, ticket_dir, RWAFileName, LPFileName, TicketFileName, IPTopo, IPScenarios, OpticalTopo, OpticalScenarios, scenario_generation_only, optical_rerouting_K, option_num, option_gap, scenario_id, topology_index, verbose, ticket_or_not, progress0)
#         end

#         # print intermediate results for debug
#         if verbose
#             for rr in 1:size(rwa_scenario_restored_bw, 1)
#                 if sum(rwa_scenario_restored_bw[rr]) != sum(rr_scenario_restored_bw[rr][1])
#                     println("RWA results: ", sum(rwa_scenario_restored_bw[rr]), " ", rwa_scenario_restored_bw[rr])
#                     println("RR results: ", sum(rr_scenario_restored_bw[rr][1]), " ", rr_scenario_restored_bw[rr][1])
#                 end
#             end
#         end
#     else
#         #不是ARROW or ARROW-NAIVE， 不需要考虑故障修复
#         ## This is not ARROW or ARROW-NAIVE, hence no need to solve restoration formulation
#         rwa_scenario_restored_bw = []
#         rr_scenario_restored_bw = []
#         absolute_gap = []
#     end
#     return rwa_scenario_restored_bw, rr_scenario_restored_bw, absolute_gap
# end


# ## The traffic engineering simulator master function
# function simulator(GRB_ENV, dir, AllTopologies, AllTopoIndex, AllTunnelNum, AllAlgorithms, All_demand_upscale, All_demand_downscale, AllTraffic, scenario_cutoff, beta, scales, optical_rerouting_K, partial_load_full_tickets, option_num, large_option_num, option_gap, verbose, parallel_dir, singleplot, scenario_id, tunnel_rounting, failure_simulation, failure_free, expanded_spectrum)
#     if verbose println("please find logs files in ", dir) end
#     traffic_id = 0
#     scale_id = 0

#     for t in 1:length(AllTopologies)
#         for ii in 1:length(AllTopoIndex)
#             DirectThroughput = Dict{String,Array{Float64,2}}()
#             SecureThroughput = Dict{String,Array{Float64,2}}()
#             Scenario_Availability = Dict{String,Array{Float64,2}}()
#             conditional_Scenario_Availability = Dict{String,Array{Float64,2}}()
#             Algo_LinksUtilization = Dict{String,Array{Float64,3}}()
#             Algo_RouterPorts = Dict{String,Array{Float64,3}}()
#             Flow_Availability = Dict{String,Array{Float64,2}}()
#             conditional_Flow_Availability = Dict{String,Array{Float64,2}}()
#             Bandwidth_Availability = Dict{String,Array{Float64,2}}()
#             conditional_Bandwidth_Availability = Dict{String,Array{Float64,2}}()
#             Algo_Runtime = Dict{String,Array{Float64,2}}()
#             scenario_number=0
#             Algo_var = Dict{String,Array{Float64,2}}()
#             Algo_accommodate_ratio = Dict{String,Array{Float64,2}}()

#             topology = AllTopologies[t]
#             topology_index = AllTopoIndex[ii]
#             predefine_tunnel_num = AllTunnelNum[t]
#             tunnelK = parse(Int64, predefine_tunnel_num)
#             demand_upscale = All_demand_upscale[t]
#             demand_downscale = All_demand_downscale[t]

#             #判断是ARROW还是ARROW NAIVE
#             if in("ARROW", AllAlgorithms) || in("ARROW_BIN", AllAlgorithms)
#                 ticket_or_not = 2  # ARROW algorithms that need multiple tickets
#             elseif in("ARROW_NAIVE", AllAlgorithms)
#                 ticket_or_not = 1  # ARROW NAIVE with only one ticket
#             else
#                 ticket_or_not = 0
#             end

#             ## abstracting optical layer for TE
#             if verbose println("\n - evaluating topology: ", topology, "-", topology_index, " ,upscale: ", demand_upscale, " ,downscale: ", demand_downscale) end
#             weibull_or_k = 0  # does not affect because we do not generate tickets here
#             scenario_generation_only = 0  # does not affect because here we read all tickets, not generating tickets, but if generate, 0 means non-parallel
#             #获取故障场景
#             IPTopo, OpticalTopo, IPScenarios, OpticalScenarios = get_failure_scenarios(dir, topology, topology_index, verbose, scenario_cutoff, scenario_id, weibull_or_k, failure_free, expanded_spectrum)
#             #计算 每个scenario的RWA ILP的IP link的恢复带宽，distill后的LP的ticket的IP link的恢复带宽，和absolute_gap(四舍五入后与初始容量的差距gap)
#             rwa_scenario_restored_bw, rr_scenario_restored_bw, absolute_gap = abstract_optical_layer(GRB_ENV, IPTopo, OpticalTopo, IPScenarios, OpticalScenarios, scenario_generation_only, dir, topology, topology_index, verbose, scenario_cutoff, scenario_id, optical_rerouting_K, partial_load_full_tickets, option_num, large_option_num, option_gap, ticket_or_not, expanded_spectrum)
#             scenario_number = length(IPScenarios["code"])
            
#             ## record the TE settings
#             open("$(dir)/$(topology)/00_setup.txt", "w+") do io
#                 writedlm(io, ("AllAlgorithms", AllAlgorithms))
#                 writedlm(io, ("AllTopoIndex", AllTopoIndex))
#                 writedlm(io, ("AllTunnelNum", AllTunnelNum))
#                 writedlm(io, ("All_demand_upscale", All_demand_upscale))
#                 writedlm(io, ("All_demand_downscale", All_demand_downscale))
#                 writedlm(io, ("AllTraffic", AllTraffic))
#                 writedlm(io, ("tunnelK", tunnelK))
#                 writedlm(io, ("tunnelType", tunnel_rounting))
#                 writedlm(io, ("scenario_cutoff", scenario_cutoff))
#                 writedlm(io, ("beta", beta))
#                 writedlm(io, ("scales", scales))
#                 writedlm(io, ("target option_num", option_num))
#                 if ticket_or_not == 2 writedlm(io, ("actual option_num", size(rr_scenario_restored_bw[1],1))) end
#                 writedlm(io, ("number of scenarios", scenario_number))
#                 writedlm(io, ("parallel results", parallel_dir))
#                 writedlm(io, ("scenario_id", scenario_id))
#             end

#             ## Traffic engineering module
#             progress = ProgressMeter.Progress(length(AllAlgorithms)*length(AllTraffic)*length(scales), .1, "Running TE simulations ...\n", 50)
#             for algorithm in AllAlgorithms
#                 if verbose println("\n\n   - evaluating TE algorithm: ", algorithm) end
#                 DirectThroughput[algorithm] = zeros(length(AllTraffic), length(scales))
#                 SecureThroughput[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Scenario_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Flow_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Bandwidth_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 conditional_Scenario_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 conditional_Flow_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 conditional_Bandwidth_Availability[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Algo_LinksUtilization[algorithm] = zeros(length(AllTraffic), length(scales), length(IPTopo["links"]))
#                 Algo_RouterPorts[algorithm] = zeros(length(AllTraffic), length(scales), length(IPTopo["links"]))
#                 Algo_Runtime[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Algo_var[algorithm] = zeros(length(AllTraffic), length(scales))
#                 Algo_accommodate_ratio[algorithm] = zeros(length(AllTraffic), length(scales))

#                 for traffic_num in 1:length(AllTraffic)
#                     # parsing demand from demand matrices
#                     #读取 demand和flow
#                     initial_demand, initial_flows = readDemand("$(topology)/demand", length(IPTopo["nodes"]), AllTraffic[traffic_num], demand_upscale, demand_downscale, false)  # no rescaled
#                     rescaled_demand = initial_demand
#                     flows = initial_flows
#                     traffic_id = AllTraffic[traffic_num]

#                     ## tunnel routing
#                     # 生成tunnels，T是所有的tunnels(每一个tunnel由其中的IP link在IP[topo]中的index组成)，Tf是每一个flow对应的多个tunnel的在T1中的索引集合
#                     T1, Tf1 = getTunnels(IPTopo, flows, tunnelK, verbose, IPScenarios["code"], edge_disjoint=tunnel_rounting)

                    
#                     if tunnel_rounting > 0
#                         #不同的tunnel类型
#                         tunnel_style = "KSP"  # default tunnel
#                         if tunnel_rounting == 5
#                             tunnel_style = "FailureAwareCapacityAware"
#                         elseif tunnel_rounting == 4
#                             tunnel_style = "FailureAware"
#                         elseif tunnel_rounting == 3
#                             tunnel_style = "FiberDisjoint"
#                         elseif tunnel_rounting == 2
#                             tunnel_style = "IPedgeDisjoint"
#                         end

#                         # 保存tunnel到文件中
#                         ## save tunnel routings
#                         if isdir("data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_$(tunnel_style)") == false
#                             mkdir("data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_$(tunnel_style)")
#                             open("data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_$(tunnel_style)/tunnels_edges.txt", "w+") do io
#                                 for f in 1:length(flows)
#                                     for t in 1:size(Tf1[f],1)
#                                         edge_list = [IPTopo["links"][x] for x in T1[Tf1[f][t]]]
#                                         line = "Flow: $(flows[f]) and Tunnel: $(edge_list)"
#                                         println(io, (line))
#                                     end
#                                 end
#                             end
#                             open("data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_$(tunnel_style)/tunnels.txt", "w+") do io
#                                 writedlm(io, ("Flows", flows))
#                                 writedlm(io, ("All Tunnels", T1))
#                                 writedlm(io, ("Flow Tunnels", Tf1))
#                                 writedlm(io, ("IP edges", IPTopo["links"]))
#                             end
#                             open("data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_$(tunnel_style)/IPedges.txt", "w+") do io
#                                 for e in 1:length(IPTopo["links"])
#                                     println(io, (IPTopo["links"][e]))
#                                 end
#                             end
#                         end
#                     else
#                         #从文件中读取tunnels
#                         printstyled("parse tunnels from file\n", color=:blue)
#                         ## read tunnels from files
#                         tunnel_file = "data/topology/$(topology)/IP_topo_$(topology_index)/tunnels_ParseExternalTunnel/tunnels.txt"
#                         T1, Tf1, flows = parseTunnels(tunnel_file, IPTopo["links"])
#                     end

#                     if verbose println("T1: ", T1) end
#                     if verbose println("Tf1: ", Tf1) end
#                     if verbose println("flows: ", flows) end
#                     #计算flow对应的demand
#                     flow_matched_demand = []
#                     for d in 1:length(rescaled_demand)
#                         flow_index = findfirst(x->x==flows[d], initial_flows)
#                         push!(flow_matched_demand, rescaled_demand[flow_index])
#                     end

#                     if verbose println("rescaled_demand: ", flow_matched_demand) end

#                     for s in 1:length(scales)
#                         scale_id = scales[s]
#                         demand = convert(Array{Float64}, rescaled_demand .* scales[s])
#                         demand = convert(Array{Float64}, flow_matched_demand .* scales[s])
#                         #将demand scale和current total demand写入文件
#                         open("$(dir)/$(topology)/00_setup.txt", "a+") do io
#                             writedlm(io, ("demand scale", scale_id))
#                             writedlm(io, ("current total demand", sum(demand)))
#                         end
#                         if verbose
#                             println("\nscale: ", scales[s])
#                             println("demand: ", demand)
#                             println("total demand: ", sum(demand))
#                             println("topology: ", topology)
#                         end

#                         #根据是ARROW_NAIVE还是ARROW，选择不同的tickets(ILP方案，OR lottyticket的LP方案)
#                         ## Provision the network with current TE
#                         if algorithm == "ARROW_NAIVE"
#                             scenario_restored_bw = rwa_scenario_restored_bw
#                         elseif algorithm == "ARROW" || algorithm == "ARROW_BIN"
#                             scenario_restored_bw = rr_scenario_restored_bw
#                         else
#                             scenario_restored_bw = []
#                         end

#                         TunnelBw, var, initial_throughput, TEruntime, best_options, best_scenario_resored_bw = 0, 0, 0, 0, 0, 0, 0

#                         ## TE optimization with given tunnels
#                         solve_or_not = false  # if we solve the optimal super ILP
#                         #TE工程，选择不同的TE算法
#                         TunnelBw, FlowBw, var, initial_throughput, TEruntime, best_options, best_scenario_resored_bw = TrafficEngineering(GRB_ENV, IPTopo, OpticalTopo, algorithm, IPTopo["links"], IPTopo["capacity"], demand, flows, T1, Tf1, IPScenarios["code"], OpticalScenarios["code"], IPScenarios["prob"], scenario_restored_bw, optical_rerouting_K, tunnelK, beta, absolute_gap, verbose, solve_or_not)
#                         #画tunnel的图
#                         drawTunnel(topology, TunnelBw, T1, Tf1, IPTopo["links"], length(IPTopo["nodes"]), dir, algorithm)   # draw tunnel bandwidth graph
                        
#                         #把flow进行norm
#                         if verbose
#                             println("$(sum(TunnelBw)) - $(length(FlowBw)) - TunnelBw: ", TunnelBw)
#                             println("$(sum(FlowBw)) - $(length(FlowBw)) - Flowbw", FlowBw)
#                             norm_FlowBw = []
#                             for i in 1:length(FlowBw)
#                                 push!(norm_FlowBw, FlowBw[i]/demand[i])
#                             end
#                             println("$(sum(norm_FlowBw)) - $(length(norm_FlowBw)) - Flowbw", norm_FlowBw)
#                         end

#                         ## store results
#                         DirectThroughput[algorithm][traffic_num, s] = Float64(initial_throughput/sum(demand))
#                         Algo_Runtime[algorithm][traffic_num, s] = Float64(TEruntime)

#                         if failure_simulation  # if we run failure simulation after TE optimization
#                             ## prepare the restorable capacity (full capacity for all links) for TE failure simulation
#                             if algorithm == "ARROW_NAIVE"
#                                 selected_scenario_restored_bw = scenario_restored_bw
#                             elseif algorithm == "ARROW" || algorithm == "ARROW_BIN"
#                                 selected_scenario_restored_bw = best_scenario_resored_bw  # ARROW selected restoration option (installed on ROADM)
#                             else
#                                 selected_scenario_restored_bw = []
#                                 for s in 1:size(IPScenarios["code"], 1)
#                                     push!(selected_scenario_restored_bw, zeros(Int8, length(IPTopo["links"])))
#                                 end
#                             end

#                             ## for debug
#                             if verbose
#                                 for rr in 1:size(rwa_scenario_restored_bw, 1)
#                                     if sum(rwa_scenario_restored_bw[rr]) != sum(selected_scenario_restored_bw[rr])
#                                         println("initial RWA restoration results: ", sum(rwa_scenario_restored_bw[rr]))
#                                         println("after TE restoration results: ", sum(selected_scenario_restored_bw[rr]))
#                                     end
#                                 end
#                                 println("$(sum(TunnelBw)) - TunnelBw: ", TunnelBw)
#                                 println("$(sum(FlowBw)) - $(length(FlowBw)) - ", FlowBw)
#                             end

#                             ## post failure evaluation under different failure scenarios
#                             #计算故障后的IP link上的带宽利用率
#                             links_utilization = computeLinksUtilization(IPTopo["links"], IPTopo["capacity"], demand, flows, T1, Tf1, tunnelK, TunnelBw)
#                             #tunnel上的流量重新分配
#                             #每个scenario中的demand的满足率
#                             #受到影响的flow的数量
#                             #故障恢复后 router需要的端口数，等于 故障恢复后的 IP link上的带宽使用量(即波长占用数量) 
#                             losses, affected_flows, required_RouterPorts = TrafficReAssignment(links_utilization, IPTopo["links"], IPTopo["capacity"], demand, flows, T1, Tf1, tunnelK, TunnelBw, FlowBw, IPScenarios["code"], selected_scenario_restored_bw, algorithm, verbose)
                            
#                             ## compute evaluation metrics
#                             #故障前后 依然保持100%吞吐量的 scenarios的百分比
#                             scenario_availability = ScenarioAvailability(losses, IPScenarios["prob"], 0, false)  # conditional=false
#                             flow_availability = FlowAvailability(losses, affected_flows, flows, IPScenarios["prob"], 0, false)  # conditional=false
#                             bw_availability = BandwidthAvailability(losses, IPScenarios["prob"], 0, false)   # conditional=false
#                             conditional_scenario_availability = ScenarioAvailability(losses, IPScenarios["prob"], 0, true)  # conditional=true
#                             conditional_flow_availability = FlowAvailability(losses, affected_flows, flows, IPScenarios["prob"], 0, true)  # conditional=true
#                             conditional_bw_availability = BandwidthAvailability(losses, IPScenarios["prob"], 0, true)  # conditional=true
                            
#                             ## store results
#                             Scenario_Availability[algorithm][traffic_num, s] = Float64(scenario_availability)
#                             Flow_Availability[algorithm][traffic_num, s] = Float64(flow_availability)
#                             Bandwidth_Availability[algorithm][traffic_num, s] = Float64(bw_availability)
#                             conditional_Scenario_Availability[algorithm][traffic_num, s] = Float64(conditional_scenario_availability)
#                             conditional_Flow_Availability[algorithm][traffic_num, s] = Float64(conditional_flow_availability)
#                             conditional_Bandwidth_Availability[algorithm][traffic_num, s] = Float64(conditional_bw_availability)
#                             Algo_LinksUtilization[algorithm][traffic_num, s, :] = Float64.(links_utilization)
#                             Algo_RouterPorts[algorithm][traffic_num, s, :] = Float64.(required_RouterPorts)
#                             Algo_accommodate_ratio[algorithm][traffic_num, s] = Float64(initial_throughput/sum(demand))

#                             allowed = 0
#                             var = VAR(losses, IPScenarios["prob"], beta)
#                             if var < 1
#                                 allowed = initial_throughput * (1-var)
#                             end
#                             Algo_var[algorithm][traffic_num, s] = var
#                             SecureThroughput[algorithm][traffic_num, s] = round(allowed/sum(demand), digits=16)

#                             if verbose
#                                 println("var: ", var)
#                                 println("scenario prob: ", sum(IPScenarios["prob"]), " ", IPScenarios["prob"])
#                                 println("scenario losses: ", losses)
#                                 println("scenario affected_flows num: ", affected_flows)
#                                 println("direct throughput: ", initial_throughput)
#                                 println("allowed throughput: ", allowed)
#                                 println("scenario availability: ", scenario_availability)
#                                 println("flow availability: ", flow_availability)
#                                 println("bandwidth availability: ", bw_availability)
#                                 println("initial link bandwidth: $(IPTopo["capacity"]) - ", IPTopo["capacity"])
#                                 println("links utilization: $(sum(links_utilization)) - ", links_utilization)
#                                 println("router ports: $(sum(required_RouterPorts)) - ", required_RouterPorts)
#                             end
#                         end
#                         ProgressMeter.next!(progress, showvalues = [])
#                     end
#                 end

#                 DirectThroughput_Filename = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Direct_Throughput_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                 JLD.save(DirectThroughput_Filename, "DirectThroughput", DirectThroughput)
#                 Algo_Runtime_Filename = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Algo_Runtime_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                 JLD.save(Algo_Runtime_Filename, "Algo_Runtime", Algo_Runtime)

#                 if failure_simulation  # if we run failure simulation after TE optimization
#                     ## write results to jld files for parallel processing
#                     Scenario_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Scenario_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(Scenario_Availability_FileName, "Scenario_Availability", Scenario_Availability)
#                     Flow_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Flow_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(Flow_Availability_FileName, "Flow_Availability", Flow_Availability)
#                     Bandwidth_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Bandwidth_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(Bandwidth_Availability_FileName, "Bandwidth_Availability", Bandwidth_Availability)

#                     conditional_Scenario_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/conditional_Scenario_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(conditional_Scenario_Availability_FileName, "conditional_Scenario_Availability", conditional_Scenario_Availability)
#                     conditional_Flow_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/conditional_Flow_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(conditional_Flow_Availability_FileName, "conditional_Flow_Availability", conditional_Flow_Availability)
#                     conditional_Bandwidth_Availability_FileName = "$(parallel_dir)/$(topology)/jld/$(algorithm)/conditional_Bandwidth_Availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(conditional_Bandwidth_Availability_FileName, "conditional_Bandwidth_Availability", conditional_Bandwidth_Availability)

#                     SecureThroughput_Filename = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Secure_Throughput_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(SecureThroughput_Filename, "SecureThroughput", SecureThroughput)

#                     Algo_RouterPorts_Filename = "$(parallel_dir)/$(topology)/jld/$(algorithm)/Algo_RouterPorts_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id)_$(option_num).jld"
#                     JLD.save(Algo_RouterPorts_Filename, "Algo_RouterPorts", Algo_RouterPorts)
#                 end
#             end

#             if singleplot
#                 if failure_simulation  # if we run failure simulation after TE optimization
#                     open("$(dir)/$(topology)/03_availability_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id).txt", "w+") do io
#                         writedlm(io, ("ScenarioAvailability",))
#                         for alg in AllAlgorithms
#                             writedlm(io, (alg, Scenario_Availability[alg]))
#                         end
#                         writedlm(io, ("FlowAvailability",))
#                         for alg in AllAlgorithms
#                             writedlm(io, (alg, Flow_Availability[alg]))
#                         end
#                         writedlm(io, ("Bandwidth_Availability",))
#                         for alg in AllAlgorithms
#                             writedlm(io, (alg, Bandwidth_Availability[alg]))
#                         end
#                     end
#                     open("$(dir)/$(topology)/04_secure_throughput_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id).txt", "w+") do io
#                         writedlm(io, ("Guaranteed Throughput",))
#                         for alg in AllAlgorithms
#                             writedlm(io, (alg, SecureThroughput[alg]))
#                         end
#                     end
#                     open("$(dir)/$(topology)/06_links_utilization.txt", "w+") do io
#                         writedlm(io, ("Algo_LinksUtilization", Algo_LinksUtilization))
#                     end
#                     # plot scenario availability
#                     xname = "Demand scales"
#                     yname = "Scenario availability"
#                     figname = "$(dir)/$(topology)/03_scenario_availability.png"
#                     figname2 = "$(dir)/$(topology)/03_scenario_availability_ribbon.png"
#                     line_plot(scales, Scenario_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, Scenario_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)
#                     figname_zoom = "$(dir)/$(topology)/03_scenario_availability_zoom.png"
#                     figname_zoom2 = "$(dir)/$(topology)/03_scenario_availability_zoom_ribbon.png"
#                     line_plot(scales, Scenario_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, true, false)
#                     line_plot(scales, Scenario_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, false, false)

#                     figname_med = "$(dir)/$(topology)/03_scenario_availability_med.png"
#                     figname2_med = "$(dir)/$(topology)/03_scenario_availability_ribbon_med.png"
#                     line_plot(scales, Scenario_Availability, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)
#                     figname_zoom_med = "$(dir)/$(topology)/03_scenario_availability_zoom_med.png"
#                     figname_zoom2_med = "$(dir)/$(topology)/03_scenario_availability_zoom_ribbon_med.png"
#                     line_plot(scales, Scenario_Availability, xname, yname, figname_zoom_med, figname_zoom2_med, AllAlgorithms, true, false, false, false)

#                     ## plot flow level availability
#                     xname = "Demand scales"
#                     yname = "Flow availability"
#                     figname = "$(dir)/$(topology)/03_flow_availability.png"
#                     figname2 = "$(dir)/$(topology)/03_flow_availability_ribbon.png"
#                     line_plot(scales, Flow_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, Flow_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)
#                     figname_zoom = "$(dir)/$(topology)/03_flow_availability_zoom.png"
#                     figname_zoom2 = "$(dir)/$(topology)/03_flow_availability_zoom_ribbon.png"
#                     line_plot(scales, Flow_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, true, false)
#                     line_plot(scales, Flow_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, false, false)

#                     figname_med = "$(dir)/$(topology)/03_flow_availability_med.png"
#                     figname2_med = "$(dir)/$(topology)/03_flow_availability_ribbon_med.png"
#                     line_plot(scales, Flow_Availability, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)
#                     figname_zoom_med = "$(dir)/$(topology)/03_flow_availability_zoom_med.png"
#                     figname_zoom2_med = "$(dir)/$(topology)/03_flow_availability_zoom_ribbon_med.png"
#                     line_plot(scales, Flow_Availability, xname, yname, figname_zoom_med, figname_zoom2_med, AllAlgorithms, true, false, false, false)

#                     ## plot flow level availability
#                     xname = "Demand scales"
#                     yname = "Bandwidth availability"
#                     figname = "$(dir)/$(topology)/03_bandwidth_availability.png"
#                     figname2 = "$(dir)/$(topology)/03_bandwidth_availability_ribbon.png"
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)
#                     figname_zoom = "$(dir)/$(topology)/03_bandwidth_availability_zoom.png"
#                     figname_zoom2 = "$(dir)/$(topology)/03_bandwidth_availability_zoom_ribbon.png"
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, true, false)
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname_zoom, figname_zoom2, AllAlgorithms, true, true, false, false)

#                     figname_med = "$(dir)/$(topology)/03_bandwidth_availability_med.png"
#                     figname2_med = "$(dir)/$(topology)/03_bandwidth_availability_ribbon_med.png"
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)
#                     figname_zoom_med = "$(dir)/$(topology)/03_bandwidth_availability_zoom_med.png"
#                     figname_zoom2_med = "$(dir)/$(topology)/03_bandwidth_availability_zoom_ribbon_med.png"
#                     line_plot(scales, Bandwidth_Availability, xname, yname, figname_zoom_med, figname_zoom2_med, AllAlgorithms, true, false, false, false)

#                     ## plot network throughput
#                     xname = "Demand scales"
#                     yname = "Guaranteed throughput under Availability $(beta)"
#                     figname = "$(dir)/$(topology)/04_SecureThroughput.png"
#                     figname2 = "$(dir)/$(topology)/04_SecureThroughput_ribbon.png"
#                     line_plot(scales, SecureThroughput, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, SecureThroughput, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)

#                     figname_med = "$(dir)/$(topology)/04_SecureThroughput_med.png"
#                     figname2_med = "$(dir)/$(topology)/04_SecureThroughput_ribbon_med.png"
#                     line_plot(scales, SecureThroughput, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, true, false)
#                     line_plot(scales, SecureThroughput, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)

#                     xname = "Demand scales"
#                     yname = "Value at Risk under Availability $(beta)"
#                     figname = "$(dir)/$(topology)/04_ValueAtRisk.png"
#                     figname2 = "$(dir)/$(topology)/04_ValueAtRisk_ribbon.png"
#                     line_plot(scales, Algo_var, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, Algo_var, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)

#                     figname_med = "$(dir)/$(topology)/04_ValueAtRisk_med.png"
#                     figname2_med = "$(dir)/$(topology)/04_ValueAtRisk_ribbon_med.png"
#                     line_plot(scales, Algo_var, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)

#                     xname = "Demand scales"
#                     yname = "Demand satisfaction ratio"
#                     figname = "$(dir)/$(topology)/04_AccomodationRatio.png"
#                     figname2 = "$(dir)/$(topology)/04_AccomodationRatio_ribbon.png"
#                     line_plot(scales, Algo_accommodate_ratio, xname, yname, figname, figname2, AllAlgorithms, false, true, true, false)
#                     line_plot(scales, Algo_accommodate_ratio, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)

#                     figname_med = "$(dir)/$(topology)/04_AccomodationRatio_med.png"
#                     figname2_med = "$(dir)/$(topology)/04_AccomodationRatio_ribbon_med.png"
#                     line_plot(scales, Algo_accommodate_ratio, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)

#                     ## plot links utilization: the throughput carried across each link when there are no failures
#                     for s in 1:length(scales)
#                         PyPlot.clf()
#                         nbars = length(AllAlgorithms)
#                         sum_routerports = zeros(nbars)
#                         for aa in 1:length(AllAlgorithms)
#                             algorithm = AllAlgorithms[aa]
#                             average_utilization = zeros(length(IPTopo["links"]))
#                             average_routerports = zeros(length(IPTopo["links"]))
#                             for e in 1:length(IPTopo["links"])
#                                 for traffic_num in 1:length(AllTraffic)
#                                     average_utilization[e] += Algo_LinksUtilization[algorithm][traffic_num, s, e]
#                                     average_routerports[e] += Algo_RouterPorts[algorithm][traffic_num, s, e]
#                                 end
#                                 average_utilization[e] /= length(AllTraffic)
#                                 average_routerports[e] /= length(AllTraffic)
#                             end
#                             sum_routerports[aa] = sum(average_routerports)
#                             average_utilization_sorted = sort(average_utilization)
#                             n_data = length(average_utilization_sorted)
#                             indices = collect(0:1:n_data-1) ./ (n_data-1)
#                             PyPlot.plot(average_utilization_sorted, indices)
#                         end
#                         PyPlot.legend(AllAlgorithms, loc="best")
#                         PyPlot.xlabel("Link load (utilization)")
#                         PyPlot.ylabel("CDF")
#                         figname = "$(dir)/$(topology)/06_links_utilization_cdf_$(scales[s]).png"
#                         PyPlot.savefig(figname)

#                         PyPlot.clf()
#                         nbars = length(AllAlgorithms)
#                         sum_routerports = zeros(nbars)
#                         for aa in 1:length(AllAlgorithms)
#                             algorithm = AllAlgorithms[aa]
#                             average_utilization = zeros(length(IPTopo["links"]))
#                             average_routerports = zeros(length(IPTopo["links"]))
#                             for e in 1:length(IPTopo["links"])
#                                 for traffic_num in 1:length(AllTraffic)
#                                     average_utilization[e] += Algo_LinksUtilization[algorithm][traffic_num, s, e] / IPTopo["capacity"][e]
#                                     average_routerports[e] += Algo_RouterPorts[algorithm][traffic_num, s, e]
#                                 end
#                                 average_utilization[e] /= length(AllTraffic)
#                                 average_routerports[e] /= length(AllTraffic)
#                             end
#                             sum_routerports[aa] = sum(average_routerports)
#                             average_utilization_sorted = sort(average_utilization)
#                             n_data = length(average_utilization_sorted)
#                             indices = collect(0:1:n_data-1) ./ (n_data-1)
#                             PyPlot.plot(average_utilization_sorted, indices)
#                         end
#                         PyPlot.legend(AllAlgorithms, loc="best")
#                         PyPlot.xlabel("Link load (utilization)")
#                         PyPlot.ylabel("CDF")
#                         figname = "$(dir)/$(topology)/06_links_utilization_ratio_cdf_$(scales[s]).png"
#                         PyPlot.savefig(figname)

#                         PyPlot.clf()
#                         barWidth = 1/(nbars + 1)
#                         for aa in 1:length(AllAlgorithms)
#                             # calculate secure throughput
#                             vectorized = reshape(SecureThroughput[AllAlgorithms[aa]][:,:,s], size(SecureThroughput[AllAlgorithms[aa]][:,:,s],1)*size(SecureThroughput[AllAlgorithms[aa]][:,:,s],2))
#                             null_position = findall(x->x==-1, vectorized)
#                             real_vectorized = deleteat!(vectorized, null_position)
#                             throughput_avg = round(sum(real_vectorized)/length(real_vectorized), digits=16)
#                             sum_routerports[aa] = sum_routerports[aa] / throughput_avg
#                         end
#                         max_routerports = maximum(sum_routerports)
#                         normalized_sum_routerports = sum_routerports ./ max_routerports
#                         for aa in 1:length(AllAlgorithms)
#                             if AllAlgorithms[aa] != "ARROW_NAIVE"
#                                 PyPlot.bar(AllAlgorithms[aa], normalized_sum_routerports[aa], width=barWidth, alpha = 0.8, label=AllAlgorithms[aa])
#                             end
#                         end
#                         subAllAlgorithms = deleteat!(AllAlgorithms, findall(x->x=="ARROW_NAIVE", AllAlgorithms))
#                         PyPlot.legend(subAllAlgorithms, loc="best")
#                         PyPlot.xlabel("TE algorithms")
#                         PyPlot.ylabel("overall subscribed link bandwidth")
#                         figname = "$(dir)/$(topology)/06_links_utilization_bar_$(scales[s]).png"
#                         PyPlot.savefig(figname)
#                     end
#                 end

#                 open("$(dir)/$(topology)/04_direct_throughput_$(topology_index)_$(scenario_id)_$(traffic_id)_$(scale_id).txt", "w+") do io
#                     writedlm(io, ("Direct Throughput",))
#                     for alg in AllAlgorithms
#                         writedlm(io, (alg, DirectThroughput[alg]))
#                     end
#                 end

#                 xname = "Demand scales"
#                 yname = "Direct throughput"
#                 figname = "$(dir)/$(topology)/04_DirectThroughput.png"
#                 figname2 = "$(dir)/$(topology)/04_DirectThroughput_ribbon.png"
#                 line_plot(scales, DirectThroughput, xname, yname, figname, figname2, AllAlgorithms, false, true, false, false)
#                 figname_med = "$(dir)/$(topology)/04_DirectThroughput_med.png"
#                 figname2_med = "$(dir)/$(topology)/04_DirectThroughput_ribbon_med.png"
#                 line_plot(scales, DirectThroughput, xname, yname, figname_med, figname2_med, AllAlgorithms, false, false, false, false)                
#             end

#             open("$(dir)/$(topology)/05_runtime.txt", "w+") do io
#                 writedlm(io, ("Algo_Runtime", Algo_Runtime))
#             end            

#             ## plot gurobi solver runtime
#             PyPlot.clf()
#             nbars = length(AllAlgorithms)
#             barWidth = 1/(nbars + 1)
#             for bar in 1:nbars
#                 PyPlot.bar(AllAlgorithms[bar], sum(Algo_Runtime[AllAlgorithms[bar]])/(length(scales)*length(AllTraffic)), width=barWidth, alpha = 0.8, label=AllAlgorithms[bar])
#             end
#             PyPlot.legend(loc="best")
#             PyPlot.xticks(rotation=-45)
#             PyPlot.xlabel("TE Algorithms")
#             PyPlot.ylabel("Gurobi solver runtime (second)")
#             figname = "$(dir)/$(topology)/05_solver_runtime.png"
#             PyPlot.savefig(figname)

#             ## plot the gurobi runtime vs scenario number
#             PyPlot.clf()
#             for bar in 1:nbars
#                 PyPlot.scatter(scenario_number, sum(Algo_Runtime[AllAlgorithms[bar]])/(length(scales)*length(AllTraffic)), alpha = 0.25)
#             end
#             PyPlot.legend(loc="best")
#             PyPlot.xticks(rotation=-45)
#             PyPlot.xlabel("Number of scenarios")
#             PyPlot.ylabel("Gurobi solver runtime (second)")
#             figname = "$(dir)/$(topology)/05_scenario_num_runtime.png"
#             PyPlot.savefig(figname)
#         end
#     end
# end