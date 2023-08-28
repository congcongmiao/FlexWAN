using JuMP, Gurobi
using Combinatorics


## routing of restored wavelength
function WaveRerouting(OpticalTopo, failed_IPedge, failed_fibers_index, rerouting_K)
    nfailedge = size(failed_IPedge, 1)
    rehoused_IProutingEdge = []  # routing of rehoused IP link in terms of fiber link index
    rehoused_IProuting = []  # routing of rehoused IP link in terms of fiber node sequence
    failedIPbranckIndexAll = []  # index of rehoused IP link branches
    failedIPbrachIndexGroup = []  # index group of rehoused IP link branches

    ## an optical topology after fiber cut (an optical scenario)
    num_nodes = length(OpticalTopo["nodes"])
    optical_graph = LightGraphs.SimpleDiGraph(num_nodes)
    distances = Inf*ones(num_nodes, num_nodes)
    num_edges = length(OpticalTopo["links"])
    
    for i in 1:num_edges
        if i in failed_fibers_index  # delete the failed fiber
            continue
        else
            LightGraphs.add_edge!(optical_graph, OpticalTopo["links"][i][1], OpticalTopo["links"][i][2])
            distances[OpticalTopo["links"][i][1], OpticalTopo["links"][i][2]] = OpticalTopo["fiber_length"][i]
            distances[OpticalTopo["links"][i][2], OpticalTopo["links"][i][1]] = OpticalTopo["fiber_length"][i]
        end
    end

    # find rerouting_K paths for each failed IP links, pay attention: IP links are bidirectional!
    global_IPbranch = 1
    for w in 1:nfailedge
        # println("failed IP src-dst: ", failed_IPedge[w][1], "-", failed_IPedge[w][2])
        state = LightGraphs.yen_k_shortest_paths(optical_graph, failed_IPedge[w][1], failed_IPedge[w][2], distances, rerouting_K)
        paths = state.paths
        if length(paths) <= rerouting_K
            path_edges = []
            for p in 1:length(paths)
                k_path_edges = []
                for i in 1:length(paths[p])-1
                    e = findfirst(x -> x == (paths[p][i], paths[p][i+1]), OpticalTopo["links"])
                    append!(k_path_edges, e)
                end
                push!(path_edges, k_path_edges)
            end
            
            append!(rehoused_IProutingEdge, path_edges)
            append!(rehoused_IProuting, paths)
            append!(failedIPbranckIndexAll, range(global_IPbranch, length=length(paths), step=1))
            push!(failedIPbrachIndexGroup, range(global_IPbranch, length=length(paths), step=1))
            global_IPbranch += length(paths)
        end
    end

    return rehoused_IProutingEdge, rehoused_IProuting, failedIPbranckIndexAll, failedIPbrachIndexGroup
end

function flexgrid_find(spectrum_width, path_length)
    println("spectrum_width, path_length: ",spectrum_width, ",", path_length)
    flexgrid_optical = readdlm("./data/flexgrid_optical.txt", header=true)[1]
    reach = flexgrid_optical[:,5]
    spectrum_require = flexgrid_optical[:,2]
    capacity = flexgrid_optical[:,1]
    
    max_capacity = 0
    for i in 1:length(reach)
        if reach[i] >= path_length && spectrum_require[i] <= spectrum_width 
            if capacity[i] > max_capacity
                max_capacity = capacity[i]
            end
        end
    end

    return max_capacity

end

#找到当前光纤路径 上空余的slot可以提供的 最大的flexgrid_capacity
function occupied_spectrum_flexgrid(OpticalTopo, path)
    fixgrid_slot_spectrum = 50 #fixgrid_slot的频谱，50GHZ
    flexgrid_slot_spectrum = 6.25 #fixgrid_slot的频谱，6.25 GHZ
    Cband = 96*(floor(Int, fixgrid_slot_spectrum / flexgrid_slot_spectrum))  # number of available wavelength, we use the ITU-T grid standard with 50 GHz spacing
    
    or_occupied_spec = []

    occupied_spectrum = []
    for i in 1:length(OpticalTopo["links"])
        #初始化占据的频谱
        push!(occupied_spectrum, [])
    end

    path_length = 0
    for e in path
        path_length += OpticalTopo["fiber_length"][e]
        for spec in OpticalTopo["fiber_spectrum_flexgrid"][e]
            spec_start = floor(Int, (spec[1]-spec[2]/2)/flexgrid_slot_spectrum+1)
            spec_end = floor(Int, (spec[1]+spec[2]/2)/flexgrid_slot_spectrum)
            for i in spec_start:spec_end
                push!(occupied_spectrum[e], i)
            end
        end
    end


    # for e in path
    #     for j in occupied_spectrum[e]
    #         if !(j in or_occupied_spec)
    #             push!(or_occupied_spec, j)
    #         end
    #     end
    # end

    # tmp_occupied_spec = copy(or_occupied_spec)
    # push!(tmp_occupied_spec, 0)
    # push!(tmp_occupied_spec, Cband+1)
    # # println("tmp_occupied_spec: ",tmp_occupied_spec)
    # tmp_occupied_spec = sort(tmp_occupied_spec)
    # println("tmp_occupied_spec: ",tmp_occupied_spec)

    # path_capacity = []
    # for j in 1:length(tmp_occupied_spec)-1
    #     if tmp_occupied_spec[j+1]-tmp_occupied_spec[j]-1 != 0
    #         spectrum_width = (tmp_occupied_spec[j+1]-tmp_occupied_spec[j]-1) * flexgrid_slot_spectrum
    #         push!(path_capacity, flexgrid_find(spectrum_width, path_length))
    #     end
    # end

    return occupied_spectrum, path_length

end

function path_capacity_flexgrid(occupied_spectrum, path, path_length)
    fixgrid_slot_spectrum = 50 #fixgrid_slot的频谱，50GHZ
    flexgrid_slot_spectrum = 6.25 #fixgrid_slot的频谱，6.25 GHZ
    Cband = 96*(floor(Int, fixgrid_slot_spectrum / flexgrid_slot_spectrum))  # number of available wavelength, we use the ITU-T grid standard with 50 GHz spacing
    
    or_occupied_spec = []
    for e in path
        for j in occupied_spectrum[e]
            if !(j in or_occupied_spec)
                push!(or_occupied_spec, j)
            end
        end
    end

    tmp_occupied_spec = copy(or_occupied_spec)
    push!(tmp_occupied_spec, 0)
    push!(tmp_occupied_spec, Cband+1)
    # println("tmp_occupied_spec: ",tmp_occupied_spec)
    tmp_occupied_spec = sort(tmp_occupied_spec)
    # println("tmp_occupied_spec: ",tmp_occupied_spec)

    max_path_capacity = 0
    max_path_capacity_index = 0
    for j in 1:length(tmp_occupied_spec)-1
        if tmp_occupied_spec[j+1]-tmp_occupied_spec[j]-1 != 0
            spectrum_width = (tmp_occupied_spec[j+1]-tmp_occupied_spec[j]-1) * flexgrid_slot_spectrum
            flexgrid_capacity = flexgrid_find(spectrum_width, path_length)
            if max_path_capacity <= flexgrid_capacity
                max_path_capacity = flexgrid_capacity
                max_path_capacity_index = j
            end
        end
    end

    return max_path_capacity, tmp_occupied_spec[max_path_capacity_index+1], tmp_occupied_spec[max_path_capacity_index]

end


## routing of restored wavelength
function WaveRerouting_flexgrid(OpticalTopo, IPTopo, failed_IPedge, failed_IP_initialindex, failed_fibers_index, rerouting_K)
    nfailedge = size(failed_IPedge, 1)
    rehoused_IProutingEdge = []  # routing of rehoused IP link in terms of fiber link index
    rehoused_IProuting = []  # routing of rehoused IP link in terms of fiber node sequence
    failedIPbranckIndexAll = []  # index of rehoused IP link branches
    failedIPbrachIndexGroup = []  # index group of rehoused IP link branches

    ## an optical topology after fiber cut (an optical scenario)
    num_nodes = length(OpticalTopo["nodes"])
    optical_graph = LightGraphs.SimpleDiGraph(num_nodes)
    distances = Inf*ones(num_nodes, num_nodes)
    num_edges = length(OpticalTopo["links"])
    
    for i in 1:num_edges
        if i in failed_fibers_index  # delete the failed fiber
            continue
        else
            LightGraphs.add_edge!(optical_graph, OpticalTopo["links"][i][1], OpticalTopo["links"][i][2])
            distances[OpticalTopo["links"][i][1], OpticalTopo["links"][i][2]] = OpticalTopo["fiber_length"][i]
            distances[OpticalTopo["links"][i][2], OpticalTopo["links"][i][1]] = OpticalTopo["fiber_length"][i]
        end
    end

    # find rerouting_K paths for each failed IP links, pay attention: IP links are bidirectional!
    global_IPbranch = 1
    for w in 1:nfailedge
        # println("failed IP src-dst: ", failed_IPedge[w][1], "-", failed_IPedge[w][2])
        rerouting_K = num_nodes*num_nodes
        state = LightGraphs.yen_k_shortest_paths(optical_graph, failed_IPedge[w][1], failed_IPedge[w][2], distances, rerouting_K)
        paths = state.paths
        println("WaveRerouting_flexgrid length(paths), rerouting_K, paths: ", length(paths),",", rerouting_K, paths)
        if length(paths) <= rerouting_K
            path_edges = []
            for p in 1:length(paths)
                k_path_edges = []
                for i in 1:length(paths[p])-1
                    e = findfirst(x -> x == (paths[p][i], paths[p][i+1]), OpticalTopo["links"])
                    append!(k_path_edges, e)
                end
                push!(path_edges, k_path_edges)
            end
            all_occupied_spectrum = []
            all_path_length = []
            for i in 1:length(path_edges)
                push!(all_occupied_spectrum, [])
            end
            #找到每条光纤路径 的最大能提供的capacity和RTT
            for i in 1:length(path_edges)
                path = path_edges[i]
                occupied_spectrum, path_length = occupied_spectrum_flexgrid(OpticalTopo, path)
                # println("occupied_spectrum, path_length: ",occupied_spectrum, ",", path_length)
                all_occupied_spectrum[i] = occupied_spectrum
                push!(all_path_length, path_length)
            end
            # println("all_occupied_spectrum: ", all_occupied_spectrum)
            
            
            transponders_num = length(IPTopo["link_spectrum_center_flexgrid"][failed_IP_initialindex[w]])
            for current_combination in collect(combinations(1:length(path_edges), transponders_num))
                fiber_used = zeros(length(OpticalTopo["links"]))
                for i in current_combination
                    max_path_capacity, right_slot_index, left_slot_index = path_capacity_flexgrid(all_occupied_spectrum[i], path_edges[i], all_path_length[i])
                    for slot in left_slot_index:right_slot_index
                        for e in path_edges[i]
                            push!(all_occupied_spectrum[i][e], slot)
                        end
                    end
                    println("max_path_capacity: ", max_path_capacity)
                end
            end

                



            
            append!(rehoused_IProutingEdge, path_edges)
            append!(rehoused_IProuting, paths)
            append!(failedIPbranckIndexAll, range(global_IPbranch, length=length(paths), step=1))
            push!(failedIPbrachIndexGroup, range(global_IPbranch, length=length(paths), step=1))
            global_IPbranch += length(paths)
        end
    end

    return rehoused_IProutingEdge, rehoused_IProuting, failedIPbranckIndexAll, failedIPbrachIndexGroup
end

## wavelength assignment of restored wavelength, generating restoration link options that maximize restored capacity, this is an ILP
function RestoreILP(GRB_ENV, Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K, fiber_length, failed_IP_transponders_num)
    println("solving restoration wavelength assignment ILP considering wavelength continuity")

    nFibers = length(Fibers)
    nfailedIPedges = length(failedIPedges)
    nfailedIPedgeBranchAll = length(failedIPbranckIndexAll)  # this number can be small than nfailedIPedges * nfailedIPedgeBranchPerLink
    nfailedIPedgeBranchPerLink = rerouting_K
    nwavelength = size(FibercapacityCode, 2)
    uni_failedIPedges = []
    reverse_failedIPedges = []
    for edge_index in 1:nfailedIPedges
        e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
        if edge_index < e
            push!(uni_failedIPedges, edge_index)
            push!(reverse_failedIPedges, e)
        end
    end

    flexgrid_optical = readdlm("./data/flexgrid_optical_v3.txt", header=true)[1]
    reach = flexgrid_optical[:,4]
    u = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #max capacity of a wavelength under length constraints
    s = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #Spectrum width of a wavelength in 𝑢_𝑒^𝑘
    IPlink_path_length = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
    # z = zeros(nfailedIPedgeBranchAll, nFibers, nwavelength)

    # 计算IP link 的 k条 fiper path的长度, 然后据此计算flexgrid最大的 波长的宽度和capacity
    for l in 1:nfailedIPedges
        for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index   
            current_branch_length = 0
            for f in failedIPBranchRoutingFiber[failedIPbrachIndexGroup[l][t]]
                current_branch_length +=  fiber_length[f]
            end
            IPlink_path_length[l,t] = current_branch_length
            println("l,t,current_branch_length,failedIPBranchRoutingFiber[l,t]:",l,",",t,",",current_branch_length,",",failedIPBranchRoutingFiber[failedIPbrachIndexGroup[l][t]])
            max_capacity = 0.0
            max_spectrum = 0.0
            for i in 1:length(reach)
                if reach[i] >= current_branch_length && flexgrid_optical[i,1]>max_capacity && flexgrid_optical[i,1]<=failed_IP_initialbw[l]
                    max_capacity = flexgrid_optical[i,1]
                    max_spectrum = floor(Int64, flexgrid_optical[i,2]/12.5) # 6.25 slots num
                end
            end
            u[l,t] = max_capacity
            s[l,t] = max_spectrum
        end
    end

    println("u[l,t]:",u)

    # how each IP branch is routed on fibers
    L = zeros(nfailedIPedgeBranchAll, nFibers)
    for t in 1:nfailedIPedgeBranchAll  # nfailedIPedgeBranchAll is global indexed
        for f in 1:nFibers
            if in(f, failedIPBranchRoutingFiber[t])
                L[t,f] = 1
            end
        end
    end

    fixgrid_slot_spectrum = 50 #fixgrid_slot的频谱，50GHZ
    flexgrid_slot_spectrum = 12.5 #6.25 #fixgrid_slot的频谱，6.25 GHZ; 这里要先使用flexgrid生成IPlink路由和fiber path上的capacity，所以还是使用6.25
    Cband = nwavelength
    # Cband = 48*(floor(Int, fixgrid_slot_spectrum / flexgrid_slot_spectrum))
    # Cband = 24*(floor(Int, fixgrid_slot_spectrum / flexgrid_slot_spectrum))
    println("restoration cband is :",Cband)
    
    candi_waves_d = []
    candi_waves_l = []
    candi_waves_Y = []
    for i in 1:length(reach)
        push!(candi_waves_d,flexgrid_optical[i,1])
        push!(candi_waves_l,reach[i])
        push!(candi_waves_Y,floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum))
    end
    candi_wavenum = length(candi_waves_d)

    # channel = []
    channel_set = []
    for i in 1:length(reach)
        channel_i_set = []
        for j in 1:Cband- candi_waves_Y[i]+1
            cband_state = zeros(Cband)
            for k in j:j+candi_waves_Y[i]-1
                cband_state[k] = 1
            end
            push!(channel_i_set, cband_state)
        end
        push!(channel_set, channel_i_set)
    end

    for f in 1:nFibers
       println("FibercapacityCode[f],f: ",f,FibercapacityCode[f,:])
    end

    if length(failedIPBranchRoutingFiber) > 0  # if this scenario has failures
        model = Model(() -> Gurobi.Optimizer(GRB_ENV))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "Threads", 32)

        @variable(model, restored_bw[1:nfailedIPedges] >= 0, Int)  
        @variable(model, restored_capacity[1:nfailedIPedges] >= 0, Int)  
        @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink, 1:candi_wavenum] >= 0, Int)  # bandwidth allocation for all IP branches
        @variable(model, lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] >=0, Bin)  # if IP link's branch use fiber and wavelength
        @variable(model, z[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength-1] >=0, Bin)
        @variable(model, gamma[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink, 1:candi_wavenum, 1:nwavelength] >=0, Bin)


        # Equation 13
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink
                for j in 1:candi_wavenum
                    @constraint(model, (candi_waves_l[j]-IPlink_path_length[l,t])*IPBranch_bw[l,t,j] >= 0)
                end
            end
        end

        # Equation 14, wavelength resource used only once if the resource is usable
        for w in 1:nwavelength 
            for f in 1:nFibers
                @constraint(model, sum(lambda[t,f,w] for t in 1:nfailedIPedgeBranchAll) <= FibercapacityCode[f,w])
            end
        end

        # # Equation 15, translate wavelength usage to IPBranch_bw
        # for l in 1:nfailedIPedges
        #     for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
        #         if t <= length(failedIPbrachIndexGroup[l]) 
        #             for f in 1:nFibers 
        #                 @constraint(model, s[l,t]*IPBranch_bw[l,t]*L[failedIPbrachIndexGroup[l][t],f] == sum(lambda[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength))
        #             end
        #         else
        #             @constraint(model, IPBranch_bw[l,t] == 0)
        #         end
        #     end
        # end

        # Equation 16, wavelength continuity
        for t in 1:nfailedIPedgeBranchAll
            for f in failedIPBranchRoutingFiber[t]
                for ff in failedIPBranchRoutingFiber[t]
                    for w in 1:nwavelength
                        @constraint(model, lambda[t,f,w]*L[t,f] == lambda[t,ff,w]*L[t,ff])
                    end
                end
            end
        end

        # Equation 17, restored bw(transponders_num) should no larger than initial bw, 100 is per wavelength gbps
        for l in 1:nfailedIPedges
            @constraint(model, restored_bw[l] <= failed_IP_transponders_num[l]+2)
            @constraint(model, restored_bw[l] == sum(IPBranch_bw[l,t,j] for t in 1:nfailedIPedgeBranchPerLink, j in 1:candi_wavenum))
        end

        # Equation 18, restored capacity should no larger than initial capacity
        for l in 1:nfailedIPedges
            @constraint(model, restored_capacity[l] <= failed_IP_initialbw[l])
            @constraint(model, restored_capacity[l] == sum(IPBranch_bw[l,t,j]*candi_waves_d[j] for t in 1:nfailedIPedgeBranchPerLink, j in 1:candi_wavenum))
        end

        # Equation 19, channel sum on slot equal to lambda slot state
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
                if t <= length(failedIPbrachIndexGroup[l]) 
                    for f in 1:nFibers 
                        for w in 1:nwavelength
                            @constraint(model, sum(channel_set[j][q][w]*gamma[l,t,j,q] for j in 1:candi_wavenum, q in 1:Cband-candi_waves_Y[j]+1)*L[failedIPbrachIndexGroup[l][t],f] == lambda[failedIPbrachIndexGroup[l][t],f,w])
                            # sum(channel_set[j][q][w]*gamma[l,t,j,q] for j in 1:candi_wavenum, q in 1:Cband-candi_waves_Y[j]+1)*L[l,t,f]
                        end
                    end
                else
                    for j in 1:candi_wavenum
                        @constraint(model, IPBranch_bw[l,t,j] == 0)
                    end
                end
            end
        end


        # # Equation 19, spectrum slots must be continuity
        # for l in 1:nfailedIPedges
        #     for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
        #         if t <= length(failedIPbrachIndexGroup[l]) 
        #             for f in failedIPBranchRoutingFiber[failedIPbrachIndexGroup[l][t]]
        #                 for w in 1:nwavelength-1
        #                     # if lambda[t,f,w+1] - lambda[t,f,w]>0
        #                     @constraint(model, z[failedIPbrachIndexGroup[l][t],f,w] == (lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w])*(lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w]))
        #                     # else
        #                         # @constraint(model, z[t,f,w] == -(lambda[t,f,w+1] - lambda[t,f,w]))
        #                     # end
        #                 end
        #                 # if lambda[failedIPbrachIndexGroup[l][t],f,1]==1 || lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1]==1
        #                 #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1)
        #                 # else
        #                 #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
        #                 # end
        #                 println("restoration test3")
        #                 @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
        #                 @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
        #                 # @constraint(model, lambda_type == lambda[failedIPbrachIndexGroup[l][t],f,1]+lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])
        #                 @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
        #             end
        #         end
        #     end
        # end

        # Equation 20, lambda equal to gamma sum on q
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
                for j in 1:candi_wavenum
                    @constraint(model, IPBranch_bw[l,t,j] == sum(gamma[l,t,j,q] for q in 1:Cband-candi_waves_Y[j]+1))
                end
            end
        end
    

        # Auxiliary: bidirectional link bandwidth equal
        for e in 1:length(uni_failedIPedges)
            @constraint(model, restored_bw[uni_failedIPedges[e]] == restored_bw[reverse_failedIPedges[e]])
        end

        @objective(model, Max, sum(IPBranch_bw[l,t,j]*candi_waves_d[j] for l in 1:nfailedIPedges, t in 1:nfailedIPedgeBranchPerLink, j in 1:candi_wavenum))  # maximizing total restorable bandwidth capacity
        optimize!(model)
        println("restoration test")
        
        IPBranch_bw_value = value.(IPBranch_bw)
        IPBranch_bw_return = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink
                for j in 1:candi_wavenum
                    if  IPBranch_bw_value[l,t,j]!=0
                        println(" IPBranch_bw_value[l,t,j]*candi_waves_d[j]:", IPBranch_bw_value[l,t,j],",",candi_waves_d[j])
                    end
                    IPBranch_bw_return[l,t] = IPBranch_bw_return[l,t] + IPBranch_bw_value[l,t,j]*candi_waves_d[j]
                end
            end
        end

        println("value.(IPBranch_bw)",value.(IPBranch_bw))
        return value.(restored_capacity), objective_value(model), IPBranch_bw_return

    else
        # restored_bw = zeros(nfailedIPedges)
        restored_capacity = zeros(nfailedIPedges)
        IPBranch_bw = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
        
        # return restored_bw, 0, IPBranch_bw
        return restored_capacity, 0, IPBranch_bw
    end
end


### back up，非channel版本，restoration v1版本
# ## wavelength assignment of restored wavelength, generating restoration link options that maximize restored capacity, this is an ILP
# function RestoreILP(GRB_ENV, Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K, fiber_length, failed_IP_transponders_num)
#     println("solving restoration wavelength assignment ILP considering wavelength continuity")

#     nFibers = length(Fibers)
#     nfailedIPedges = length(failedIPedges)
#     nfailedIPedgeBranchAll = length(failedIPbranckIndexAll)  # this number can be small than nfailedIPedges * nfailedIPedgeBranchPerLink
#     nfailedIPedgeBranchPerLink = rerouting_K
#     nwavelength = size(FibercapacityCode, 2)
#     uni_failedIPedges = []
#     reverse_failedIPedges = []
#     for edge_index in 1:nfailedIPedges
#         e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
#         if edge_index < e
#             push!(uni_failedIPedges, edge_index)
#             push!(reverse_failedIPedges, e)
#         end
#     end

#     flexgrid_optical = readdlm("./data/flexgrid_optical_v2.txt", header=true)[1]
#     reach = flexgrid_optical[:,4]
#     u = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #max capacity of a wavelength under length constraints
#     s = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #Spectrum width of a wavelength in 𝑢_𝑒^𝑘
#     # z = zeros(nfailedIPedgeBranchAll, nFibers, nwavelength)

#     # 计算IP link 的 k条 fiper path的长度, 然后据此计算flexgrid最大的 波长的宽度和capacity
#     for l in 1:nfailedIPedges
#         for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index   
#             current_branch_length = 0
#             for f in failedIPBranchRoutingFiber[t]
#                 current_branch_length +=  fiber_length[f]
#             end
#             println("l,t,current_branch_length:",l,",",t,",",current_branch_length)
#             max_capacity = 0.0
#             max_spectrum = 0.0
#             for i in 1:length(reach)
#                 if reach[i] >= current_branch_length && flexgrid_optical[i,1]>max_capacity && flexgrid_optical[i,1]<=failed_IP_initialbw[l]
#                     max_capacity = flexgrid_optical[i,1]
#                     max_spectrum = floor(Int64, flexgrid_optical[i,2]/6.25) # slots num
#                 end
#             end
#             u[l,t] = max_capacity
#             s[l,t] = max_spectrum
#         end
#     end

#     println("u[l,t]:",u)

#     # how each IP branch is routed on fibers
#     L = zeros(nfailedIPedgeBranchAll, nFibers)
#     for t in 1:nfailedIPedgeBranchAll  # nfailedIPedgeBranchAll is global indexed
#         for f in 1:nFibers
#             if in(f, failedIPBranchRoutingFiber[t])
#                 L[t,f] = 1
#             end
#         end
#     end

#     if length(failedIPBranchRoutingFiber) > 0  # if this scenario has failures
#         model = Model(() -> Gurobi.Optimizer(GRB_ENV))
#         set_optimizer_attribute(model, "OutputFlag", 0)
#         set_optimizer_attribute(model, "Threads", 32)

#         @variable(model, restored_bw[1:nfailedIPedges] >= 0, Int)  
#         @variable(model, restored_capacity[1:nfailedIPedges] >= 0, Int)  
#         @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink] >= 0, Int)  # bandwidth allocation for all IP branches
#         @variable(model, lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] >=0, Bin)  # if IP link's branch use fiber and wavelength
#         @variable(model, z[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength-1] >=0, Bin)

#         # Equation 14, wavelength resource used only once if the resource is usable
#         for w in 1:nwavelength 
#             for f in 1:nFibers
#                 @constraint(model, sum(lambda[t,f,w] for t in 1:nfailedIPedgeBranchAll) <= FibercapacityCode[f,w])
#             end
#         end

#         # Equation 15, translate wavelength usage to IPBranch_bw
#         for l in 1:nfailedIPedges
#             for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
#                 if t <= length(failedIPbrachIndexGroup[l]) 
#                     for f in 1:nFibers 
#                         @constraint(model, s[l,t]*IPBranch_bw[l,t]*L[failedIPbrachIndexGroup[l][t],f] == sum(lambda[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength))
#                     end
#                 else
#                     @constraint(model, IPBranch_bw[l,t] == 0)
#                 end
#             end
#         end

#         # Equation 16, wavelength continuity
#         for t in 1:nfailedIPedgeBranchAll
#             for f in failedIPBranchRoutingFiber[t]
#                 for ff in failedIPBranchRoutingFiber[t]
#                     for w in 1:nwavelength
#                         @constraint(model, lambda[t,f,w]*L[t,f] == lambda[t,ff,w]*L[t,ff])
#                     end
#                 end
#             end
#         end

#         # Equation 17, restored bw(transponders_num) should no larger than initial bw, 100 is per wavelength gbps
#         for l in 1:nfailedIPedges
#             @constraint(model, restored_bw[l] <= failed_IP_transponders_num[l])
#             @constraint(model, restored_bw[l] == sum(IPBranch_bw[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Equation 18, restored capacity should no larger than initial capacity
#         for l in 1:nfailedIPedges
#             @constraint(model, restored_capacity[l] <= failed_IP_initialbw[l])
#             @constraint(model, restored_capacity[l] == sum(IPBranch_bw[l,t]*u[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Equation 19, spectrum slots must be continuity
#         for l in 1:nfailedIPedges
#             for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
#                 if t <= length(failedIPbrachIndexGroup[l]) 
#                     for f in failedIPBranchRoutingFiber[failedIPbrachIndexGroup[l][t]]
#                         for w in 1:nwavelength-1
#                             # if lambda[t,f,w+1] - lambda[t,f,w]>0
#                             @constraint(model, z[failedIPbrachIndexGroup[l][t],f,w] == (lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w])*(lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w]))
#                             # else
#                                 # @constraint(model, z[t,f,w] == -(lambda[t,f,w+1] - lambda[t,f,w]))
#                             # end
#                         end
#                         # if lambda[failedIPbrachIndexGroup[l][t],f,1]==1 || lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1]==1
#                         #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1)
#                         # else
#                         #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
#                         # end
#                         println("restoration test3")
#                         @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
#                         @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
#                         # @constraint(model, lambda_type == lambda[failedIPbrachIndexGroup[l][t],f,1]+lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])
#                         @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
#                     end
#                 end
#             end
#         end


#         for l in 1:nfailedIPedges
#             @constraint(model, restored_capacity[l] <= failed_IP_initialbw[l])
#             @constraint(model, restored_capacity[l] == sum(IPBranch_bw[l,t]*u[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Auxiliary: bidirectional link bandwidth equal
#         for e in 1:length(uni_failedIPedges)
#             @constraint(model, restored_bw[uni_failedIPedges[e]] == restored_bw[reverse_failedIPedges[e]])
#         end

#         @objective(model, Max, sum(IPBranch_bw[l,t]*u[l,t] for l in 1:nfailedIPedges, t in 1:nfailedIPedgeBranchPerLink))  # maximizing total restorable bandwidth capacity
#         optimize!(model)
#         println("restoration test")
#         println("value.(IPBranch_bw)",value.(IPBranch_bw))
#         return value.(restored_capacity), objective_value(model), (value.(IPBranch_bw)).*u

#     else
#         # restored_bw = zeros(nfailedIPedges)
#         restored_capacity = zeros(nfailedIPedges)
#         IPBranch_bw = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
        
#         # return restored_bw, 0, IPBranch_bw
#         return restored_capacity, 0, IPBranch_bw
#     end
# end




# ## wavelength assignment of restored wavelength, generating restoration link options that maximize restored capacity, this is a LP relaxed from previous ILP
# function RestoreLP(GRB_ENV, Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K, fiber_length, failed_IP_transponders_num)
#     println("solving restoration wavelength assignment relaxed LP considering wavelength continuity")

#     nFibers = length(Fibers)
#     nfailedIPedges = length(failedIPedges)
#     nfailedIPedgeBranchAll = length(failedIPbranckIndexAll)  # this number can be small than nfailedIPedges * nfailedIPedgeBranchPerLink
#     nfailedIPedgeBranchPerLink = rerouting_K
#     nwavelength = size(FibercapacityCode, 2)
#     uni_failedIPedges = []
#     reverse_failedIPedges = []
#     for edge_index in 1:nfailedIPedges
#         e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
#         if edge_index < e
#             push!(uni_failedIPedges, edge_index)
#             push!(reverse_failedIPedges, e)
#         end
#     end

#     flexgrid_optical = readdlm("./data/flexgrid_optical_v2.txt", header=true)[1]
#     reach = flexgrid_optical[:,4]
#     u = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #max capacity of a wavelength under length constraints
#     s = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink) #Spectrum width of a wavelength in 𝑢_𝑒^𝑘
#     # z = zeros(nfailedIPedgeBranchAll, nFibers, nwavelength)

#     # 计算IP link 的 k条 fiper path的长度, 然后据此计算flexgrid最大的 波长的宽度和capacity
#     for l in 1:nfailedIPedges
#         for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index   
#             current_branch_length = 0
#             for f in failedIPBranchRoutingFiber[t]
#                 current_branch_length +=  fiber_length[f]
#             end
#             max_capacity = 0.0
#             max_spectrum = 0.0
#             for i in 1:length(reach)
#                 if reach[i] >= current_branch_length && flexgrid_optical[i,1]>max_capacity
#                     max_capacity = flexgrid_optical[i,1]
#                     max_spectrum = floor(Int64, flexgrid_optical[i,2]/6.25) # slots num
#                 end
#             end
#             u[l,t] = max_capacity
#             s[l,t] = max_spectrum
#         end
#     end

#     # how each IP branch is routed on fibers
#     L = zeros(nfailedIPedgeBranchAll, nFibers)
#     for t in 1:nfailedIPedgeBranchAll  # nfailedIPedgeBranchAll is global indexed
#         for f in 1:nFibers
#             if in(f, failedIPBranchRoutingFiber[t])
#                 L[t,f] = 1
#             end
#         end
#     end

#     if length(failedIPBranchRoutingFiber) > 0  # if this scenario has failures
#         model = Model(() -> Gurobi.Optimizer(GRB_ENV))
#         set_optimizer_attribute(model, "OutputFlag", 0)
#         set_optimizer_attribute(model, "Threads", 32)

#         @variable(model, restored_bw[1:nfailedIPedges] >= 0)  # integer constraint relaxed
#         @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink] >= 0)  # integer constraint relaxed, bandwidth allocation for all IP branches
#         @variable(model, 0 <= lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] <=1)  # integer constraint relaxed, if IP link's branch use fiber and wavelength

#         # @variable(model, restored_bw[1:nfailedIPedges] >= 0, Int)  
#         @variable(model, restored_capacity[1:nfailedIPedges] >= 0, Int)  
#         # @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink] >= 0, Int)  # bandwidth allocation for all IP branches
#         # @variable(model, lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] >=0, Bin)  # if IP link's branch use fiber and wavelength
#         @variable(model, z[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength-1] >=0, Bin)

#         # Equation 14, wavelength resource used only once if the resource is usable
#         for w in 1:nwavelength 
#             for f in 1:nFibers
#                 @constraint(model, sum(lambda[t,f,w] for t in 1:nfailedIPedgeBranchAll) <= FibercapacityCode[f,w])
#             end
#         end

#         # Equation 15, translate wavelength usage to IPBranch_bw
#         for l in 1:nfailedIPedges
#             for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
#                 if t <= length(failedIPbrachIndexGroup[l]) 
#                     for f in 1:nFibers 
#                         @constraint(model, s[l,t]*IPBranch_bw[l,t]*L[failedIPbrachIndexGroup[l][t],f] == sum(lambda[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength))
#                     end
#                 else
#                     @constraint(model, IPBranch_bw[l,t] == 0)
#                 end
#             end
#         end

#         # Equation 16, wavelength continuity
#         for t in 1:nfailedIPedgeBranchAll
#             for f in failedIPBranchRoutingFiber[t]
#                 for ff in failedIPBranchRoutingFiber[t]
#                     for w in 1:nwavelength
#                         @constraint(model, lambda[t,f,w]*L[t,f] == lambda[t,ff,w]*L[t,ff])
#                     end
#                 end
#             end
#         end

#         # Equation 17, restored bw(transponders_num) should no larger than initial bw, 100 is per wavelength gbps
#         for l in 1:nfailedIPedges
#             @constraint(model, restored_bw[l] <= failed_IP_transponders_num[l])
#             @constraint(model, restored_bw[l] == sum(IPBranch_bw[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Equation 18, restored capacity should no larger than initial capacity
#         for l in 1:nfailedIPedges
#             @constraint(model, restored_capacity[l] <= failed_IP_initialbw[l])
#             @constraint(model, restored_capacity[l] == sum(IPBranch_bw[l,t]*u[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Equation 19, spectrum slots must be continuity
#         for l in 1:nfailedIPedges
#             for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
#                 for f in failedIPBranchRoutingFiber[failedIPbrachIndexGroup[l][t]]
#                     for w in 1:nwavelength-1
#                         # if lambda[t,f,w+1] - lambda[t,f,w]>0
#                         @constraint(model, z[failedIPbrachIndexGroup[l][t],f,w] == (lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w])*(lambda[failedIPbrachIndexGroup[l][t],f,w+1] - lambda[failedIPbrachIndexGroup[l][t],f,w]))
#                         # else
#                             # @constraint(model, z[t,f,w] == -(lambda[t,f,w+1] - lambda[t,f,w]))
#                         # end
#                     end
#                     # if lambda[failedIPbrachIndexGroup[l][t],f,1]==1 || lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1]==1
#                     #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1)
#                     # else
#                     #     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
#                     # end
#                     println("restoration test3")
#                     @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
#                     @constraint(model, (lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])=>{sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t]-1})
#                     # @constraint(model, lambda_type == lambda[failedIPbrachIndexGroup[l][t],f,1]+lambda[failedIPbrachIndexGroup[l][t],f,nwavelength-1])
#                     @constraint(model, sum(z[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength-1) <= 2*IPBranch_bw[l,t])
#                 end
#             end
#         end


#         for l in 1:nfailedIPedges
#             @constraint(model, restored_capacity[l] <= failed_IP_initialbw[l])
#             @constraint(model, restored_capacity[l] == sum(IPBranch_bw[l,t]*u[l,t] for t in 1:nfailedIPedgeBranchPerLink))
#         end

#         # Auxiliary: bidirectional link bandwidth equal
#         for e in 1:length(uni_failedIPedges)
#             @constraint(model, restored_bw[uni_failedIPedges[e]] == restored_bw[reverse_failedIPedges[e]])
#         end

#         @objective(model, Max, sum(IPBranch_bw[l,t]*u[l,t] for l in 1:nfailedIPedges, t in 1:nfailedIPedgeBranchPerLink))  # maximizing total restorable bandwidth capacity
#         optimize!(model)
#         println("restoration test")
#         return value.(restored_capacity), objective_value(model), (value.(IPBranch_bw)).*u

#     else
#         # restored_bw = zeros(nfailedIPedges)
#         restored_capacity = zeros(nfailedIPedges)
#         IPBranch_bw = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
        
#         # return restored_bw, 0, IPBranch_bw
#         return restored_capacity, 0, IPBranch_bw
#     end
# end

function RestoreLP(GRB_ENV, Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K)
    println("solving restoration wavelength assignment relaxed LP considering wavelength continuity")

    nFibers = length(Fibers)
    nfailedIPedges = length(failedIPedges)
    nfailedIPedgeBranchAll = length(failedIPbranckIndexAll)  # this number can be small than nfailedIPedges * nfailedIPedgeBranchPerLink
    nfailedIPedgeBranchPerLink = rerouting_K
    nwavelength = size(FibercapacityCode, 2)
    # println(nwavelength)
    uni_failedIPedges = []
    reverse_failedIPedges = []
    for edge_index in 1:nfailedIPedges
        e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
        if edge_index < e
            push!(uni_failedIPedges, edge_index)
            push!(reverse_failedIPedges, e)
        end
    end

    # how each IP branch is routed on fibers
    L = zeros(nfailedIPedgeBranchAll, nFibers)
    for t in 1:nfailedIPedgeBranchAll  # nfailedIPedgeBranchAll is global indexed
        for f in 1:nFibers
            if in(f, failedIPBranchRoutingFiber[t])
                L[t,f] = 1
            end
        end
    end

    if length(failedIPBranchRoutingFiber) > 0  # if this scenario has failures
        model = Model(() -> Gurobi.Optimizer(GRB_ENV))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "Threads", 32)

        @variable(model, restored_bw[1:nfailedIPedges] >= 0)  # integer constraint relaxed
        @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink] >= 0)  # integer constraint relaxed, bandwidth allocation for all IP branches
        @variable(model, 0 <= lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] <=1)  # integer constraint relaxed, if IP link's branch use fiber and wavelength

        # Equation 14, wavelength resource used only once if the resource is usable
        for w in 1:nwavelength 
            for f in 1:nFibers
                @constraint(model, sum(lambda[t,f,w] for t in 1:nfailedIPedgeBranchAll) <= FibercapacityCode[f,w])
            end
        end

        # Equation 15, translate wavelength usage to IPBranch_bw
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
                if t <= length(failedIPbrachIndexGroup[l]) 
                    for f in 1:nFibers 
                        @constraint(model, IPBranch_bw[l,t]*L[failedIPbrachIndexGroup[l][t],f] == sum(lambda[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength))
                    end
                else
                    @constraint(model, IPBranch_bw[l,t] == 0)
                end
            end
        end

        # Equation 16, wavelength continuity
        for t in 1:nfailedIPedgeBranchAll
            for f in failedIPBranchRoutingFiber[t]
                for ff in failedIPBranchRoutingFiber[t]
                    for w in 1:nwavelength
                        @constraint(model, lambda[t,f,w]*L[t,f] == lambda[t,ff,w]*L[t,ff])
                    end
                end
            end
        end

        # Equation 17, restored bw should no larger than initial bw, 100 is per wavelength gbps
        for l in 1:nfailedIPedges
            @constraint(model, restored_bw[l]*100 <= failed_IP_initialbw[l])
            @constraint(model, restored_bw[l] == sum(IPBranch_bw[l,t] for t in 1:nfailedIPedgeBranchPerLink))
        end

        # Auxiliary: bidirectional link bandwidth equal
        for e in 1:length(uni_failedIPedges)
            @constraint(model, restored_bw[uni_failedIPedges[e]] == restored_bw[reverse_failedIPedges[e]])
        end

        @objective(model, Max, sum(restored_bw[l] for l in 1:nfailedIPedges))  # maximizing total restorable bandwidth capacity
        optimize!(model)

        return value.(restored_bw), objective_value(model), value.(IPBranch_bw)

    else
        restored_bw = zeros(nfailedIPedges)
        IPBranch_bw = zeros(nfailedIPedges, nfailedIPedgeBranchPerLink)
        
        return restored_bw, 0, IPBranch_bw
    end
end


## check if a particular ticket satisfy the RWA constraints
function RestoreRWACheck(GRB_ENV, ticket_restored_bw, Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K, verbose)
    if verbose println("[Checking] randomized rounding solution feasibility with optical-layer restoration ILP") end
    nFibers = length(Fibers)
    nfailedIPedges = length(failedIPedges)
    nfailedIPedgeBranchAll = length(failedIPbranckIndexAll)  # this number can be small than nfailedIPedges * nfailedIPedgeBranchPerLink
    nfailedIPedgeBranchPerLink = rerouting_K
    nwavelength = size(FibercapacityCode, 2)
    uni_failedIPedges = []
    reverse_failedIPedges = []
    for edge_index in 1:nfailedIPedges
        e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
        if edge_index < e
            push!(uni_failedIPedges, edge_index)
            push!(reverse_failedIPedges, e)
        end
    end

    # how each IP branch is routed on fibers
    L = zeros(nfailedIPedgeBranchAll, nFibers)
    for t in 1:nfailedIPedgeBranchAll  # nfailedIPedgeBranchAll is global indexed
        for f in 1:nFibers
            if in(f, failedIPBranchRoutingFiber[t])
                L[t,f] = 1
            end
        end
    end

    if length(failedIPBranchRoutingFiber) > 0  # if this scenario has failures
        model = Model(() -> Gurobi.Optimizer(GRB_ENV))
        set_optimizer_attribute(model, "OutputFlag", 0)
        set_optimizer_attribute(model, "Threads", 32)

        @variable(model, restored_bw[1:nfailedIPedges] >= 0, Int)  
        @variable(model, IPBranch_bw[1:nfailedIPedges, 1:nfailedIPedgeBranchPerLink] >= 0, Int)  # bandwidth allocation for all IP branches
        @variable(model, lambda[1:nfailedIPedgeBranchAll, 1:nFibers, 1:nwavelength] <= 0, Bin)  # if IP link's branch use fiber and wavelength

        # Equation 14, wavelength resource used only once if the resource is usable
        for w in 1:nwavelength 
            for f in 1:nFibers
                @constraint(model, sum(lambda[t,f,w] for t in 1:nfailedIPedgeBranchAll) <= FibercapacityCode[f,w])
            end
        end

        # Equation 15, translate wavelength usage to IPBranch_bw
        for l in 1:nfailedIPedges
            for t in 1:nfailedIPedgeBranchPerLink  # t is the index for branches of the failIP link, not global branch index
                if t <= length(failedIPbrachIndexGroup[l]) 
                    for f in 1:nFibers 
                        @constraint(model, IPBranch_bw[l,t]*L[failedIPbrachIndexGroup[l][t],f] == sum(lambda[failedIPbrachIndexGroup[l][t],f,w] for w in 1:nwavelength))
                    end
                else
                    @constraint(model, IPBranch_bw[l,t] == 0)
                end
            end
        end

        # Equation 16, wavelength continuity
        for t in 1:nfailedIPedgeBranchAll
            for f in failedIPBranchRoutingFiber[t]
                for ff in failedIPBranchRoutingFiber[t]
                    for w in 1:nwavelength
                        @constraint(model, lambda[t,f,w]*L[t,f] == lambda[t,ff,w]*L[t,ff])
                    end
                end
            end
        end

        # Equation 17, restored bw should no larger than initial bw, 100 is per wavelength gbps
        for l in 1:nfailedIPedges
            @constraint(model, restored_bw[l]*100 <= failed_IP_initialbw[l])
            @constraint(model, restored_bw[l] == sum(IPBranch_bw[l,t] for t in 1:nfailedIPedgeBranchPerLink))
        end

        # Auxiliary: bidirectional link bandwidth equal
        for e in 1:length(uni_failedIPedges)
            @constraint(model, restored_bw[uni_failedIPedges[e]] == restored_bw[reverse_failedIPedges[e]])
        end

        # do not solve the model, but just check the solution feasibility
        result_dict = Dict(restored_bw[1] => ticket_restored_bw[1])
        for l in 2:nfailedIPedges
            result_dict = merge!(result_dict, Dict(restored_bw[l] => ticket_restored_bw[l]))
        end
        # println("result_dict: ", result_dict)
        feasibility = primal_feasibility_report(model, result_dict, skip_missing = true)
        # println("feasibility: ", feasibility)

        if length(feasibility) == 0
            if verbose 
                printstyled(" - $(ticket_restored_bw) feasibility true - ", color=:green)
                println(feasibility)
            end
            return true
        else
            if verbose
                printstyled(" - $(ticket_restored_bw) feasibility false - ", color=:yellow)
                println(feasibility)
            end
            return false
        end
    
    else
        return true  # non failure scenario
    end
end


## randomized rounding based on relaxed LP solution
function RandomRounding(GRB_ENV, LP_restored_bw, restored_bw_rwa, failedIPedges, failed_IP_initialbw, ticket_set_size, option_gap, OpticalTopo, rehoused_IProutingEdge, failedIPbranckindex, failedIPbrachGroup, optical_rerouting_K, verbose) 
    # println("Randomized rounding gap: ", option_gap)
    ilp_check = 1
    initial_wavelength_num = failed_IP_initialbw ./ 100  # 1 wavelength = 100 Gbps
    probabilities_up = []
    nrestored = size(LP_restored_bw, 1)
    nfailedIPedges = length(failedIPedges)
    # identify bidirectional IP relationship
    uni_failedIPedges = []
    reverse_failedIPedges = []
    for edge_index in 1:nfailedIPedges
        e = findfirst(x -> x == (failedIPedges[edge_index][2], failedIPedges[edge_index][1], failedIPedges[edge_index][3]), failedIPedges)
        if edge_index < e
            push!(uni_failedIPedges, edge_index)
            push!(reverse_failedIPedges, e)
        end
    end

    for i in 1:length(uni_failedIPedges)
        push!(probabilities_up, LP_restored_bw[uni_failedIPedges[i]] - floor(Int, LP_restored_bw[uni_failedIPedges[i]]))
    end

    outer_iteration = min(ticket_set_size*nrestored*10) # a large number for generating options
    theoretical_max_ticket = floor(Int128, sqrt(prod(initial_wavelength_num)))
    if sqrt(prod(initial_wavelength_num)) - floor(sqrt(prod(initial_wavelength_num))) > 0.001 && verbose
        println("initial_wavelength_num $(initial_wavelength_num)")
    end
    if verbose println("The max number of possible ticket in this failure scenario: $(theoretical_max_ticket)") end
    restored_bw = zeros(outer_iteration, nrestored)
    real_restored_bw = zeros(ticket_set_size, nrestored)  # generated tickets for this scenario, restorable bw for each failed IP link
    
    # have the first randoized rounding result to be the planning (arrow naive) result
    rounded_index = 1
    for b in 1:length(uni_failedIPedges)
        real_restored_bw[rounded_index,uni_failedIPedges[b]] = restored_bw_rwa[uni_failedIPedges[b]]
        real_restored_bw[rounded_index,reverse_failedIPedges[b]] = restored_bw_rwa[reverse_failedIPedges[b]]
    end

    # have the second randomized rouding result to be the generic rounding results from LP
    if ticket_set_size >= 2
        rounded_index = 2
        for b in 1:length(uni_failedIPedges)
            real_restored_bw[rounded_index,uni_failedIPedges[b]] = floor(LP_restored_bw[uni_failedIPedges[b]])
            real_restored_bw[rounded_index,reverse_failedIPedges[b]] = floor(LP_restored_bw[reverse_failedIPedges[b]])
        end
    end

    # starting from the third ticket, randomized generation
    progress = ProgressMeter.Progress(min(ticket_set_size,theoretical_max_ticket), .1, "Running randomized rounding $(ticket_set_size) tickets (this scenario of $(nrestored/2) failed links has max $(outer_iteration) trials)...\n", 50)
    if ticket_set_size > 2
        for m in 1:outer_iteration
            # m'th rounding attempt to get restored_bw[outer_iteration, nrestored]
            for b in 1:length(uni_failedIPedges)  # for each failed link to restore
                rounding_range = max(initial_wavelength_num[uni_failedIPedges[b]], floor(LP_restored_bw[uni_failedIPedges[b]]))  # rouding stride
                # rounding_range = initial_wavelength_num[uni_failedIPedges[b]] - floor(LP_restored_bw[uni_failedIPedges[b]])  # rouding stride
                rd = rand(1) # generate a random number between 0 and 1
                # probability of the b'th failed link
                if probabilities_up[b] == 0  ## handling integer LP solution
                    if rd[1] < 0.3  # round up
                        restored_bw[m,uni_failedIPedges[b]] = min(initial_wavelength_num[uni_failedIPedges[b]], ceil(Int, LP_restored_bw[uni_failedIPedges[b]]) + rand(1:rounding_range))
                        restored_bw[m,reverse_failedIPedges[b]] = restored_bw[m,uni_failedIPedges[b]]
                    elseif rd[1] < 0.7  # stay still
                        restored_bw[m,uni_failedIPedges[b]] = LP_restored_bw[uni_failedIPedges[b]]
                        restored_bw[m,reverse_failedIPedges[b]] = restored_bw[m,uni_failedIPedges[b]]
                    else  # round down
                        restored_bw[m,uni_failedIPedges[b]] = max(0, floor(LP_restored_bw[uni_failedIPedges[b]]) - rand(1:rounding_range))
                        restored_bw[m,reverse_failedIPedges[b]] = restored_bw[m,uni_failedIPedges[b]]
                    end
                else
                    if rd[1] < probabilities_up[b]  # round up
                        restored_bw[m,uni_failedIPedges[b]] = min(initial_wavelength_num[uni_failedIPedges[b]], ceil(Int, LP_restored_bw[uni_failedIPedges[b]]) + rand(1:rounding_range) - 1)
                        restored_bw[m,reverse_failedIPedges[b]] = restored_bw[m,uni_failedIPedges[b]]
                    else  # round down
                        restored_bw[m,uni_failedIPedges[b]] = max(0, floor(Int, LP_restored_bw[uni_failedIPedges[b]]) - rand(1:rounding_range) + 1)
                        restored_bw[m,reverse_failedIPedges[b]] = restored_bw[m,uni_failedIPedges[b]]
                    end
                end
            end
            
            # filter out bad options
            if round(Int, sum(restored_bw[m,:])) <= round(Int, sum(LP_restored_bw)) && round(Int, sum(restored_bw[m,:])) > option_gap*round(Int, sum(LP_restored_bw))  # make sure the tickets are within reasonable range of total restorable capacity
                # distill randomized tickets by removing duplicates
                duplicate_sign = 0
                for r in 1:rounded_index
                    if real_restored_bw[r,:] == restored_bw[m,:]
                        duplicate_sign = 1
                        # println("duplicate_sign")
                        break
                    end
                end
                if duplicate_sign == 0  # this is an unique ticket generated from randomized rounding
                    ## if all the restorable links happens to round down from LP, then it is feasible no need to check (this is probably not a good ticket)
                    weak_ticket = 1
                    for b in 1:nrestored
                        if restored_bw[m,b] > real_restored_bw[2,b]  # second ticket is LP result
                            weak_ticket = 0
                            break
                        end
                    end
                    if ilp_check == 1 && weak_ticket == 0  # not a weak ticket and need to run feasibility check
                        Fibers = OpticalTopo["links"]
                        FibercapacityCode = OpticalTopo["capacityCode"]
                        failedIPBranchRoutingFiber = rehoused_IProutingEdge
                        failedIPbranckIndexAll = failedIPbranckindex
                        failedIPbrachIndexGroup = failedIPbrachGroup
                        rerouting_K = optical_rerouting_K
                        check_time = @timed check_sign = RestoreRWACheck(GRB_ENV, restored_bw[m,:], Fibers, FibercapacityCode, failedIPedges, failedIPBranchRoutingFiber, failedIPbranckIndexAll, failedIPbrachIndexGroup, failed_IP_initialbw, rerouting_K, verbose)
                        if verbose println("check time $(check_time[2])") end
                        if check_sign  # feasibility check passed
                            rounded_index += 1  # append this ticket to real_restored_bw as feasible ticket
                            if verbose println("Get one feasible ticket $(restored_bw[m,:])") end
                            for b in 1:nrestored
                                real_restored_bw[rounded_index,b] = restored_bw[m,b]
                            end
                            ProgressMeter.next!(progress, showvalues = [])
                        end
                    else
                        rounded_index += 1  # append this ticket to real_restored_bw as feasible ticket
                        if verbose println("Get one feasible ticket $(restored_bw[m,:])") end
                        for b in 1:nrestored
                            real_restored_bw[rounded_index,b] = restored_bw[m,b]
                        end
                        ProgressMeter.next!(progress, showvalues = [])
                    end
                end
            end

            # we get desired number of rounded results or get the theoretical max number of tickets
            if rounded_index >= min(ticket_set_size, theoretical_max_ticket)
                if verbose println("Get desired number $(rounded_index) of tickets") end
                break
            end
        end
    end

    return real_restored_bw
end


## convert failure scenarios to IP link failure information
function ReadFailureScenario(scenario, IPedges, IPcapacity, IPlink_spectrum_center_flexgrid)
    nedges = size(IPedges,1)
    failed_IPedge = []
    failed_IP_initialindex = []
    failed_IP_initialbw = []
    failed_IP_transponders_num = []
    for x in 1:nedges
        if scenario[x] < 1   # link failure
            push!(failed_IPedge, IPedges[x])
            push!(failed_IP_initialindex, x)
            push!(failed_IP_initialbw, IPcapacity[x])
            push!(failed_IP_transponders_num, length(IPlink_spectrum_center_flexgrid[x]))
        end
    end

    return failed_IPedge, failed_IP_initialindex, failed_IP_initialbw, failed_IP_transponders_num
end


## routing of restored wavelength for all IP links as a database only for OPTIMAL cross-layer formulation
function AllIPWaveRerouting(OpticalTopo, IPedges, rerouting_K)
    nIPedges = size(IPedges, 1)
    rehoused_IProutingEdge = []
    rehoused_IProutingPaths = []
    IPbranckIndexAll = []
    IPbrachIndexGroup = []

    ## an optical topology without fiber cut 
    num_nodes = length(OpticalTopo["nodes"])
    optical_graph = LightGraphs.SimpleDiGraph(num_nodes)
    distances = Inf*ones(num_nodes, num_nodes)
    
    num_edges = length(OpticalTopo["links"])
    for i in 1:num_edges
        LightGraphs.add_edge!(optical_graph, OpticalTopo["links"][i][1], OpticalTopo["links"][i][2])
        distances[OpticalTopo["links"][i][1], OpticalTopo["links"][i][2]] = OpticalTopo["fiber_length"][i]
        distances[OpticalTopo["links"][i][2], OpticalTopo["links"][i][1]] = OpticalTopo["fiber_length"][i]
    end

    # find rerouting_K paths for each IP links, pay attention: IP links are bidirectional!
    global_IPbranch = 1
    for w in 1:nIPedges
        state = LightGraphs.yen_k_shortest_paths(optical_graph, IPedges[w][1], IPedges[w][2], distances, rerouting_K)
        paths = state.paths
        # println("paths: ", paths)
        if length(paths) <= rerouting_K
            path_edges = []
            for p in 1:length(paths)
                k_path_edges = []
                for i in 1:length(paths[p])-1
                    e = findfirst(x -> x == (paths[p][i], paths[p][i+1]), OpticalTopo["links"])
                    append!(k_path_edges, e)
                end
                push!(path_edges, k_path_edges)
            end
            
            append!(rehoused_IProutingEdge, path_edges)
            append!(rehoused_IProutingPaths, paths)
            append!(IPbranckIndexAll, range(global_IPbranch, length=length(paths), step=1))
            push!(IPbrachIndexGroup, range(global_IPbranch, length=length(paths), step=1))
            global_IPbranch += length(paths)
        end
    end

    return rehoused_IProutingEdge, rehoused_IProutingPaths, IPbranckIndexAll, IPbrachIndexGroup
end