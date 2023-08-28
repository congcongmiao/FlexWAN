using DelimitedFiles
using Debugger
using LightGraphs
using JLD
using Dates
include("./interface.jl")


## 光纤flexgrid的规划
function optical_network_planning(topology, tofile = true, scaling = 5,  k_paths = 3, demand_scale = 1)
    topodir="../data/topology/$(topology)"
    input_ip_nodes = readdlm("$(topodir)/IP_nodes.txt", header=true)[1]
    input_optical_nodes = readdlm("$(topodir)/optical_nodes.txt", header=true)[1]
    input_topology_o = readdlm("$(topodir)/optical_topo.txt", header=true)[1]
    
    
    ignore = ()

    #读取光学层拓扑中每一条光纤的起节点，终节点，和光纤长度信息，每一维是一个数组
    fromNodesOptical = input_topology_o[:,1]
    toNodesOptical = input_topology_o[:,2]
    lengthOptical = input_topology_o[:,3]
    # println(lengthOptical)
    failureprobOptical = input_topology_o[:,4]
    fiberlinks = []
    bidirect_links = []
    fiberlinkslength = []
    fiberlinksSpectrum = []
    fiberlinksFailure = []
    bidirect_fiberlinksFailure = []
    fixgrid_slot_spectrum = 50 #fixgrid_slot的频谱，50GHZ
    flexgrid_slot_spectrum = 12.5 #6.25 #fixgrid_slot的频谱，6.25 GHZ; 这里要先使用flexgrid生成IPlink路由和fiber path上的capacity，所以还是使用6.25

    for i in 1:size(fromNodesOptical, 1)
        if (!(fromNodesOptical[i] in ignore) && !(toNodesOptical[i] in ignore))
            #插入fiberlinks数组(光纤链路，i.e[起节点，终节点])
            push!(fiberlinks, (Int(fromNodesOptical[i]), Int(toNodesOptical[i])))
            #插入 光纤链路长度 数组
            push!(fiberlinkslength, lengthOptical[i])
            #初始化 光纤链路频谱 数组
            push!(fiberlinksSpectrum, [])
            #插入 光纤链路cutoff概率 数组
            push!(fiberlinksFailure, failureprobOptical[i])
            #形成 双向的光纤链路长度 双向的光纤链路cutoff概率 数组 (i.e不区分链路方向)
            if !in((Int(fromNodesOptical[i]), Int(toNodesOptical[i])), bidirect_links) && !in((Int(toNodesOptical[i]), Int(fromNodesOptical[i])), bidirect_links)
                push!(bidirect_links, (Int(fromNodesOptical[i]), Int(toNodesOptical[i])))
                push!(bidirect_fiberlinksFailure, failureprobOptical[i])
            end
        end
    end

    # parsed_wavelength = []
    parsed_optical_route = []
    links_length = []       #每个IP link通过的光纤总长
    links_length_max = []   #每个IP link通过的光纤中 最长的那条光纤

    #从文件中读取IP
    input_topology_ip = readdlm("$(topodir)/IP_topo_1/IP_topo_1.txt", header=true, Int64)[1] #cernet used
    
    ignore = ()
    
    src_node = input_topology_ip[:,1]
    dst_node = input_topology_ip[:,2]

    #读取光层拓扑文件，格式为[to_node  from_node   metric  failure_prob]
    data = readdlm("$(topodir)/optical_topo.txt", header=true)
    #读取光层节点，包含IP节点名
    opticalnode = readdlm("$(topodir)/optical_nodes.txt", header=true)
    #计算光层节点数量 max_optical_node
    max_optical_node = Int(length(opticalnode[1][:,1]))
    # topology
    #构造一个包含光层节点数量的图
    graph = LightGraphs.SimpleDiGraph(max_optical_node)
    #构造一个max_optical_node X max_optical_node维的距离矩阵
    distances = Inf*ones(max_optical_node, max_optical_node)
    fiberlinks = []

    IPlink_num = length(src_node)
    nFibers = length(fromNodesOptical)

    flexgrid_optical = readdlm("../data/flexgrid_optical_v3.txt", header=true)[1]
    reach = flexgrid_optical[:,4]
    # candi_waves_d = flexgrid_optical[:,1]
    # candi_waves_l = flexgrid_optical[:,4]
    # candi_waves_Y = floor(Int64, flexgrid_optical[:,2]/flexgrid_slot_spectrum)
    
    candi_waves_d = []
    candi_waves_l = []
    candi_waves_Y = []
    for i in 1:length(reach)
        push!(candi_waves_d,flexgrid_optical[i,1])
        push!(candi_waves_l,reach[i])
        push!(candi_waves_Y,floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum))
    end
    candi_wavenum = length(candi_waves_d)
  

    u = [] #max capacity of a wavelength under length constraints
    s = [] #Spectrum width of a wavelength in 𝑢_𝑒^𝑘
    for i in 1:length(src_node)
        push!(u,[])
        push!(s,[])
    end

    #data是光层拓扑文件，格式为[to_node  from_node   metric  failure_prob]
    for i in 1:length(data[1][:,1])
        #将边<to_node  from_node>加入到graph图中
        LightGraphs.add_edge!(graph, Int(data[1][:,1][i]), Int(data[1][:,2][i]))
        #将边<to_node  from_node>的 长度metric 加入到distances数组之中
        distances[Int(data[1][:,1][i]), Int(data[1][:,2][i])] = Int(data[1][:,3][i])
        println(Int(data[1][:,1][i]), Int(data[1][:,2][i]),Int(data[1][:,3][i]))
        #将边<to_node  from_node>加入到fiberlinks数组中
        push!(fiberlinks, (Int(data[1][:,1][i]), Int(data[1][:,2][i])))
    end


    optical_links_storage = Dict()
    reverse_optical_links_storage = Dict()
    optical_links_length_storage = Dict()
    reverse_optical_links_length_storage = Dict()
    optical_links_u_storage = Dict() #planning MLP u
    optical_links_s_storage = Dict() #planning MLP s
    for i in 1:length(src_node) #遍历每一个IP link，计算每一个link对应的k个fiber最短路
        # println("test:",i)
        src = src_node[i] #IP link src node
        dst = dst_node[i] #IP link dst node
        println("KSP paths - i,src,dst:",i,",",src,",",dst)
        if src < dst
            # 可相交path start, cernet used
            state = LightGraphs.yen_k_shortest_paths(graph, src, dst, distances, k_paths)
            paths = state.paths
            println("IP link's paths: ", paths)
            for k in 1:k_paths
                optical_links = []
                reverse_optical_links = []
                optical_links_length = 0
                reverse_optical_links_length = 0
                for n in 2:length(paths[k])
                    #e是IP link的每一条正向的光纤路由在fiberlinks中的索引index，存入optical_links
                    e = findfirst(x -> x == (paths[k][n-1], paths[k][n]), fiberlinks)  # this is the fiber
                    push!(optical_links, e)
                    optical_links_length += Int(data[1][:,3][e])
                    #r是IP link的每一条 反向 的光纤路由在fiberlinks中的索引index，存入reverse_optical_links
                    r = findfirst(x -> x == (paths[k][n], paths[k][n-1]), fiberlinks)  # this is the fiber
                    push!(reverse_optical_links, r)
                    reverse_optical_links_length += Int(data[1][:,3][r])
                end

                println("optical_links:",optical_links)
                println("reverse_optical_links:",reverse_optical_links)

                if haskey(optical_links_storage, string(src)*"."*string(dst))
                    push!(optical_links_storage[string(src)*"."*string(dst)], optical_links)
                    push!(reverse_optical_links_storage[string(src)*"."*string(dst)], reverse_optical_links)
                    push!(optical_links_length_storage[string(src)*"."*string(dst)], optical_links_length)
                    push!(reverse_optical_links_length_storage[string(src)*"."*string(dst)], reverse_optical_links_length)
                    
                    max_capacity = 0.0
                    max_spectrum = 0.0
                    for i in 1:length(reach)
                        if reach[i] >= optical_links_length && flexgrid_optical[i,1]>max_capacity
                            max_capacity = flexgrid_optical[i,1]
                            max_spectrum = floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum)
                        end
                    end
                    push!(optical_links_u_storage[string(src)*"."*string(dst)], max_capacity)
                    push!(optical_links_s_storage[string(src)*"."*string(dst)], max_spectrum)
                else
                    optical_links_storage[string(src)*"."*string(dst)] = [optical_links]
                    reverse_optical_links_storage[string(src)*"."*string(dst)] = [reverse_optical_links]
                    optical_links_length_storage[string(src)*"."*string(dst)] = [optical_links_length]
                    reverse_optical_links_length_storage[string(src)*"."*string(dst)] = [reverse_optical_links_length]

                    max_capacity = 0.0
                    max_spectrum = 0.0
                    for i in 1:length(reach)
                        if reach[i] >= optical_links_length && flexgrid_optical[i,1]>max_capacity
                            max_capacity = flexgrid_optical[i,1]
                            max_spectrum = floor(Int64, flexgrid_optical[i,2]/flexgrid_slot_spectrum)
                        end
                    end
                    optical_links_u_storage[string(src)*"."*string(dst)] = [max_capacity]
                    optical_links_s_storage[string(src)*"."*string(dst)] = [max_spectrum]

                end
            end
        elseif src > dst  # just look up for the other direction
            optical_links_storage[string(src)*"."*string(dst)] = reverse_optical_links_storage[string(dst)*"."*string(src)]
            optical_links_length_storage[string(src)*"."*string(dst)] = reverse_optical_links_length_storage[string(dst)*"."*string(src)]
            
            optical_links_u_storage[string(src)*"."*string(dst)] =  optical_links_u_storage[string(dst)*"."*string(src)]
            optical_links_s_storage[string(src)*"."*string(dst)] =  optical_links_s_storage[string(dst)*"."*string(src)]
        end
        
        u[i] = optical_links_u_storage[string(src)*"."*string(dst)]
        s[i] = optical_links_s_storage[string(src)*"."*string(dst)]
    
    end

    

    dir = "../data/topology"

    capacity_demand = readdlm("$(dir)/$(topology)/IP_topo_1/capacity_demand.txt")
    capacity_demand = capacity_demand*demand_scale
    println("capacity_demand:", capacity_demand)


    Cband = 96*(floor(Int, fixgrid_slot_spectrum / flexgrid_slot_spectrum))
    println("cband is :",Cband)
    
    

    #创建一个Gurobi环境
    GRB_ENV = Gurobi.Env()
    # IP link e的k个 path 是否经过fiber f 
    L = zeros(IPlink_num, k_paths, nFibers)
    for e in 1:IPlink_num  # IPlink_num is global indexed
        src = src_node[e] #IP link src node
        dst = dst_node[e] #IP link dst node
        for k in 1:k_paths
            for f in 1:nFibers
                if in(f, optical_links_storage[string(src)*"."*string(dst)][k])
                    L[e, k, f] = 1
                end
            end
        end
    end
    # println("L[e, k, f]:", L)

    uni_IPedges = []
    reverse_IPedges = []
    for e in 1:IPlink_num
        src = src_node[e] #IP link src node
        dst = dst_node[e] #IP link dst node
        edge_index = 0
        for e_reverse in 1:IPlink_num
            if src==dst_node[e_reverse] && dst==src_node[e_reverse]
                edge_index = e_reverse
                break
            end
        end
        if edge_index > e
            push!(uni_IPedges, e)
            push!(reverse_IPedges, edge_index)
        end
    end

    println("uni_IPedges:", uni_IPedges)
    println("reverse_IPedges:", reverse_IPedges)
    # W为transponder价格，V为单位频谱价格
    W = 1000
    V = 20
    FibercapacityCode = ones(nFibers, Cband)
    IPlink_path_length = []
    for i in 1:length(src_node)
        push!(IPlink_path_length,[])
    end

    for e in 1:IPlink_num
        for k in 1:k_paths
                src = src_node[e] #IP link src node
                dst = dst_node[e] #IP link dst node
                push!(IPlink_path_length[e], optical_links_length_storage[string(src)*"."*string(dst)][k])
        end
    end

    
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


    # MLP进行线性规划计算planning
    model = Model(() -> Gurobi.Optimizer(GRB_ENV))
    set_optimizer_attribute(model, "OutputFlag", 0)
    set_optimizer_attribute(model, "Threads", 32)
    
    #capacity of optical path 𝑘 of link 𝑒
    @variable(model, w[1:IPlink_num, 1:k_paths] >= 0, Int)  
    #number of transponder of optical path 𝑘 of link 𝑒
    @variable(model, N[1:IPlink_num, 1:k_paths, 1:candi_wavenum] >= 0, Int)  
    @variable(model, lambda[1:IPlink_num, 1:k_paths, 1:nFibers, 1:Cband] >=0, Bin)  # if IP link's branch use fiber and wavelength
    @variable(model, gamma[1:IPlink_num, 1:k_paths, 1:candi_wavenum, 1:Cband] >=0, Bin)
    
    # Equation 
    for e in 1:IPlink_num 
        @constraint(model, sum(w[e,k] for k in 1:k_paths) == capacity_demand[e])
    end

    # Equation 
    for e in 1:IPlink_num
        for k in 1:k_paths
            @constraint(model, sum(candi_waves_d[j]*N[e,k,j] for j in 1:candi_wavenum) >= w[e,k])
        end
    end

    # Equation 
    for e in 1:IPlink_num
        for k in 1:k_paths
            for j in 1:candi_wavenum
                @constraint(model, (candi_waves_l[j]-IPlink_path_length[e][k])*N[e,k,j] >= 0)
            end
        end
    end

    # 正反向IPlink的paths的capacity相等
    for i in 1:length(uni_IPedges)
        for k in 1:k_paths
            @constraint(model, w[uni_IPedges[i],k] == w[reverse_IPedges[i],k])
        end
    end

    # Equation, wavelength resource used only once if the resource is usable
    for w in 1:Cband 
        for f in 1:nFibers
            @constraint(model, sum(lambda[e,k,f,w] for e in 1:IPlink_num, k in 1:k_paths) <= FibercapacityCode[f,w])
        end
    end

    # Equation, wavelength continuity
    for e in 1:IPlink_num
        for k in 1:k_paths
            for f in nFibers
                for ff in nFibers
                    for w in 1:Cband
                        @constraint(model, lambda[e,k,f,w]*L[e,k,f] == lambda[e,k,ff,w]*L[e,k,ff])
                    end
                end
            end
        end
    end

    # Equation, channel sum on slot equal to lambda slot state
    for l in 1:IPlink_num
        for t in 1:k_paths  # t is the index for branches of the failIP link, not global branch index
                for f in 1:nFibers 
                    for w in 1:Cband
                        @constraint(model, sum(channel_set[j][q][w]*gamma[l,t,j,q] for j in 1:candi_wavenum, q in 1:Cband-candi_waves_Y[j]+1)*L[l,t,f] == lambda[l,t,f,w])
                    end
                end
        end
    end

    # Equation, lambda equal to gamma sum on q
    for e in 1:IPlink_num
        for k in 1:k_paths
            for j in 1:candi_wavenum
                @constraint(model, N[e,k,j] == sum(gamma[e,k,j,q] for q in 1:Cband-candi_waves_Y[j]+1))
            end
        end
    end

    #最大化总可恢复带宽容量
    @objective(model, Min, sum(N[e,k,j]*(W+candi_waves_Y[j]*V) for e in 1:IPlink_num, k in 1:k_paths, j in 1:candi_wavenum))  # maximizing total restorable bandwidth capacity
    optimize!(model)

    println("w,N:", value.(w), value.(N))

    w = value.(w)
    N = value.(N)
    gamma = value.(gamma)


    spectrum_center_storage = Dict()
    spectrum_width_storage = Dict()
    capacity_storage = Dict()
    failure_probability_storage = Dict()
    spectrum_used_flexgrid_storage = Dict()

    occupied_spectrum = []
    for i in 1:length(input_topology_o[:,1])
        #初始化占据的频谱
        push!(occupied_spectrum, [])
    end

    length_gap = []
    link_spec_efficiency = []

    openstyle = "w"  
    open("../plot/channel/$(topology)/IP_topo_1_flexgrid_test_scale_"*string(demand_scale)*".txt", openstyle) do io 
        #文件写入行首，即["src" "dst" "index" "capacity" "fiberpath_index" "wavelength" "failure"]
        writedlm(io, ["src" "dst" "path_index" "fiberpath_index" "failure_flexgrid" "spectrum_center" "spectrum_width" "spectrum_used_flexgrid_storage" "capacity_flexgrid"])
        for e in 1:IPlink_num
            src = src_node[e] #IP link src node
            dst = dst_node[e] #IP link dst node
            println("src,dst:",src," ",dst)
            for k in 1:k_paths
                optical_links = optical_links_storage[string(src)*"."*string(dst)][k]
                if src < dst
                    spectrum_center = [] #flexgrid表示方法，[中心值，宽度]，中心值
                    spectrum_width = []  #flexgrid表示方法，[中心值，宽度]，宽度
                    IPlink_path_capacity = 0
                    spectrum_used = 0 
                    #IP link经过的光纤路由hop数量越多，光纤cutff 概率越大
                    failure_probability = 0.001*length(optical_links)  # depend on fiber path hops, assume equal failure per fiber
                    for j in 1:candi_wavenum
                        if N[e,k,j]!=0
                            IPlink_path_capacity = IPlink_path_capacity + N[e,k,j]*candi_waves_d[j]
                            for q in 1:Cband-candi_waves_Y[j]+1
                                if gamma[e,k,j,q] == 1
                                    println(gamma[e,k,j,q])
                                    push!(length_gap, candi_waves_l[j] - IPlink_path_length[e][k])
                                    push!(link_spec_efficiency, candi_waves_d[j] / (candi_waves_Y[j] * flexgrid_slot_spectrum))
                                    push!(spectrum_center, (q-1)*flexgrid_slot_spectrum + candi_waves_Y[j] * flexgrid_slot_spectrum / 2)
                                    push!(spectrum_width, candi_waves_Y[j] * flexgrid_slot_spectrum)
                                    spectrum_used = spectrum_used + candi_waves_Y[j] * flexgrid_slot_spectrum
                                    for f in optical_links
                                        #已使用的slots
                                        reverse_f = findfirst(x -> x == (fiberlinks[f][2],fiberlinks[f][1]), fiberlinks)
                                        for w in 1:Cband
                                            if channel_set[j][q][w]==1
                                                push!(occupied_spectrum[f], w)
                                                push!(occupied_spectrum[reverse_f], w)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    spectrum_center_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_center
                    spectrum_width_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_width
                    capacity_storage[string(src)*"."*string(dst)*"."*string(k)] = IPlink_path_capacity
                    failure_probability_storage[string(src)*"."*string(dst)*"."*string(k)] = failure_probability
                    spectrum_used_flexgrid_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_used
                else
                    spectrum_center_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_center_storage[string(dst)*"."*string(src)*"."*string(k)]
                    spectrum_width_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_width_storage[string(dst)*"."*string(src)*"."*string(k)]
                    capacity_storage[string(src)*"."*string(dst)*"."*string(k)] = capacity_storage[string(dst)*"."*string(src)*"."*string(k)]
                    failure_probability_storage[string(src)*"."*string(dst)*"."*string(k)] = failure_probability_storage[string(dst)*"."*string(src)*"."*string(k)]
                    spectrum_used_flexgrid_storage[string(src)*"."*string(dst)*"."*string(k)] = spectrum_used_flexgrid_storage[string(dst)*"."*string(src)*"."*string(k)]
                end

                #判断是否写入文件，格式为[src  dst  initialIndex(常量，为1, 隧道的index?)  length(spectrum)  string(optical_links) string(spectrum) failure_probability]
                if spectrum_used_flexgrid_storage[string(src)*"."*string(dst)*"."*string(k)] > 0
                    writedlm(io, [src  dst  k  filter(x -> !isspace(x), string(optical_links)[4:end]) failure_probability_storage[string(src)*"."*string(dst)*"."*string(k)] filter(x -> !isspace(x), string(spectrum_center_storage[string(src)*"."*string(dst)*"."*string(k)])[4:end]) filter(x -> !isspace(x), string(spectrum_width_storage[string(src)*"."*string(dst)*"."*string(k)])[4:end]) spectrum_used_flexgrid_storage[string(src)*"."*string(dst)*"."*string(k)] capacity_storage[string(src)*"."*string(dst)*"."*string(k)]])
                end
            end
            
        end
    end

end



topology="Cernet" #B4 Custom Cernet Custom_2 Case Case_6 Case_8
tofile = true
scaling = 5
capacity_demand_generate = 1 #和fixgrid的capacity一样，不随机生成
k_paths = 2

for demand_scale in [1]#case-8 [1,2,3,4,5,6,7,8] cernet[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3] #custom_2[5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5] [5,8,10,13,14,15]
# demand_scale = 15
    optical_network_planning(topology, tofile, scaling, k_paths, demand_scale) 
    println("demand_scale-",demand_scale,"done")
end

