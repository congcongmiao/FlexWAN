## PATE TE
function PATE_Benders(GRB_ENV, edges, capacity, flows, demand, beta, T, Tf, scenarios, scenario_probs; average=false)
    
    printstyled("\n** solving PATE_Benders LP at beta $(beta)..\n", color=:yellow)    
    nedges = length(edges)
    nflows = length(flows)
    ntunnels = length(T)
    nscenarios = length(scenarios)
    p = scenario_probs
    
    tunnel_num = 0
    for x in 1:length(Tf)
        if size(Tf[x],1) > tunnel_num
            tunnel_num = size(Tf[x],1)
        end
    end

    #CREATE TUNNEL SCENARIO MATRIX --> ytq
    X  = ones(nscenarios,ntunnels)
    for s in 1:nscenarios
        for t in 1:ntunnels
            if size(T[t],1) == 0
                X[s,t] = 0
            else
                for e in 1:nedges
                    if scenarios[s][e] == 0
                        back_edge = findfirst(x -> x == (edges[e][2],edges[e][1], edges[e][3]), edges)
                        if in(e, T[t]) || in(back_edge, T[t])
                        # if in(e, T[t])
                            X[s,t] = 0
                        end
                    end
                end
            end
        end
    end

    #CREATE TUNNEL EDGE MATRIX
    L = zeros(ntunnels, nedges)
    for t in 1:ntunnels
        for e in 1:nedges
            if in(e, T[t])
                L[t,e] = 1
            end
        end
    end

    model_def_time = @elapsed begin

    model_mas = Model(() -> Gurobi.Optimizer(GRB_ENV))
    set_optimizer_attribute(model_mas, "OutputFlag", 0)
    set_optimizer_attribute(model_mas, "Threads", 32)

    @variable(model_mas, MaxFlowPctLoss >= 0) # MaxFlowPctLoss
    @variable(model_mas, z[1:nflows, 1:nscenarios] >= 0, Bin) # Equation 7, zfq is 0/1

    for f in 1:nflows
        @constraint(model_mas, sum(z[f,s] * p[s] for s in 1:nscenarios) >= beta)
    end

    @objective(model_mas, Min, MaxFlowPctLoss)

    function solve_master()
        optimize!(model_mas)
        return value.(z)
    end

    function solve_sub(zfq)
        model_sub = Model(() -> Gurobi.Optimizer(GRB_ENV))
        set_optimizer_attribute(model_sub, "OutputFlag", 0)
        set_optimizer_attribute(model_sub, "Threads", 32)

        @variable(model_sub, w[1:nflows, 1:nscenarios] >= 0)
        @variable(model_sub, v[1:nflows, 1:nscenarios] >= 0)
        @variable(model_sub, u[1:nedges] >= 0)
        @variable(model_sub, o[1:nflows, 1:nscenarios] >= 0)

        @constraint(model_sub, sum(w[f,s] for f in 1:nflows for s in 1:nscenarios) <= 1) 
        
        for f in 1:nflows
            for s in 1:nscenarios
                @constraint(model_sub, demand[f]*v[f,s] - w[f,s] - o[f,s] <= 0) 
            end
        end

        for f in 1:nflows 
            for t in 1:size(Tf[f],1)
                @constraint(model_sub, sum(v[f,s] * X[s,Tf[f][t]] for s in 1:nscenarios) - sum(L[Tf[f][t],e] * u[e] for e in 1:nedges) <= 0) 
            end
        end
        
        @objective(model_sub, Max, sum((zfq[f,s] - 1) * w[f,s] + demand[f] * v[f,s] - o[f,s] for f in 1:nflows for s in 1:nscenarios) - sum(capacity[e] * u[e] for e in 1:nedges))

        optimize!(model_sub)
        return objective_value(model_sub), value.(w), value.(v), value.(u), value.(o)
    end

    # Benders Main
    zfq = ones(nflows, nscenarios)
    for epoch in 1:100   
        meiyong, wfq, vfq, ue, ofq = solve_sub(zfq)
        @constraint(model_mas, sum((z[f,s] - 1) * wfq[f,s] + demand[f] * vfq[f,s] - ofq[f,s] for f in 1:nflows for s in 1:nscenarios) - sum(capacity[e] * ue[e] for e in 1:nedges) <= MaxFlowPctLoss)
        zfq = solve_master()
        #println("epoch",epoch)
        #println(sum(wfq), sum(vfq), sum(ue), sum(ofq))
        #println(model_mas)
    end

    model = Model(() -> Gurobi.Optimizer(GRB_ENV))
    set_optimizer_attribute(model, "OutputFlag", 0)
    set_optimizer_attribute(model, "Threads", 32)
    
    @variable(model, x[1:nflows, 1:tunnel_num] >= 0) # Equation 5, xtq >= 0  af,t
    @variable(model, alpha >= 0)
    @variable(model, l[1:nflows, 1:nscenarios] >= 0) # Equation 8, 0 <= lfq <= 1
    # @variable(model, smax[1:nscenarios] >= 0)
    # println("====p====", p)
 
    # Equation 3, a>= lfq - 1 + zfq
    for s in 1:nscenarios
        for f in 1:nflows
            @constraint(model, alpha >= l[f,s] - 1 + zfq[f,s]) 
        end
    end

    # Equation 4, a>= lfq - 1 + zfq
    # ensures that there is enough bandwidth allocated to each pair
    for s in 1:nscenarios
        for f in 1:nflows
            @constraint(model, (1-l[f,s]) * demand[f] <= sum(x[f,t] * X[s,Tf[f][t]] for t in 1:size(Tf[f],1))) 
        end
    end
    
    # Equation 5, sum(xtq) <= ce 
    for e in 1:nedges
        @constraint(model, sum(x[f,t] * L[Tf[f][t],e] for f in 1:nflows for t in 1:size(Tf[f],1)) <= capacity[e])   #overlapping flows cannot add up to the capacity of that link 
    end

    # Equation 6, lfq <= 1 
    for f in 1:nflows
        for s in 1:nscenarios
            @constraint(model, l[f,s] <= 1)  
        end
    end

    # println("----nscenarios----- ", nscenarios)
    # println("----satisfied----- ", satisfied)
    # println("----demand----- ", demand)

    # for s in 1:nscenarios
    #     for f in 1:nflows
    #         @constraint(model, a == maximum(l[s,f] for f in 1:nflows))
    #     end
    # end

    
    @objective(model, Min, alpha)
    end  # model_def_time end

    optimize!(model)

    solve_runtime = solve_time(model)
    opt_runtime = solve_runtime + model_def_time
    # println("----scenario----- ", scenarios)
    # # println("----scenario_loss----- ", value.(smax))
    # println("----flow loss----- ", value.(l))
    #umax: scenario_loss, u: flow loss

    #compute loss for flow f
    lfq = value.(l)
    #zfq = value.(z)
    loss = zeros(nflows)
    for f in 1:nflows
        for s in 1:nscenarios
            if zfq[f,s] == 1
                loss[f] = max(loss[f],lfq[f,s])
                # println(f,' ',s,' ',lfq[f,s])
                # if lfq[f,s] != 0
                #     println("flag1111",lfq[f,s])
                # end
            end
        end
    end
    println(loss)

    return objective_value(model), value.(x), loss, solve_runtime, opt_runtime
end