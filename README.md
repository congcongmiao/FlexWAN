# FlexWAN: Software Hardware Co-design for Cost-Effective and Resilient Optical Backbones 

## 1. Overview
FlexWAN is a novel flexible WAN infrastructure designed to provision cost effective WAN capacity while ensuring resilience to optical failures. FlexWAN achieves this by incorporating spacing-variable hardware at the optical layer, enabling the generated wavelength to optimize the utilization of limited spectrum resources for the WAN capacity. FlexWAN solves the algorithmic challenges by formulating the problem of provisioning WAN capacity with the goal of minimizing hardware costs.

## 2. Artifact Structure

### 2.1. Source code for the TE simulation for FlexWAN.

|  Source Files                 |  Description                                                 |
|  -----                        |  -----                                                       |
|  `algorithms/`                |  Folder of different TE algorithms (ARROW, FFC, TeaVaR, etc.)|
|  `plotall.jl`                 |  Plotting parallel generated results                         |
|  `src/aggregatetickets.jl`    |  Aggregating parallel generated tickets                      |
|  `src/author.jl`              |  Code contributors information                               |
|  `src/controller.jl`          |  Traffic engineering controller                              |
|  `src/environment.jl`         |  Fiber cut scenario generator                                |
|  `src/evaluation.jl`          |  Evaluating TE algorithms with fiber cut scenarios           |
|  `src/getscenarionum.jl`      |  Get the number of failure scenarios in each scenario file   |
|  `src/interface.jl`           |  Parse input parameters for the simulator                    |
|  `src/main.jl`                |  Simulation main file                                        |
|  `src/nextpararun.jl`         |  Generating data folder for simulation results               |
|  `src/plotting.jl`            |  Plotting functions                                          |
|  `src/provision.jl`           |  Execute IP topology provisioning                            |
|  `src/restoration.jl`         |  Optical restoration on the optical layer under failures     |
|  `src/simulator.jl`           |  Traffic engineering simulator                               |
|  `src/topodraw.jl`            |  Visualize network topology and tunnel flows                 |
|  `src/topoprovision.jl`       |  Provision IP topology on top of given optical topology      |

### 2.2. Input and output data in the TE simulation for FlexWAN.

|  Data Files                     |  Description                                              |
|  -----                          |  -----                                                    |
|  `data/topology/`               |  Input topology data                                      |
|  `data/topology/DATAFORMATS.md` |  Explain the data format for input topology data          |
|  `data/experiment/`             |  Simulation results will be saved here                    |
|  `data/parallel_experiment/`    |  Simulation results of parallel runs will be saved here   |


### 2.3. Executable shells for the running TE simulation for FlexWAN.

|  Executable Files             |  Description                                          |
|  -----                        |  -----                                                |
|  `optical_net_planning.jl`    |  Planning                                             |
|  `abstract_optical_layer.sh`  |  Restoration                                          |

### 2.4. Running simulation
First, initialize the Julia environment by installing related packages, and prepare results directories.
```
julia initialize.jl
```

For optical planning: 
```
optical_net_planning.jl
```

For restoration: 
```
bash abstract_optical_layer.sh
```

## 3. Major Dependencies
* Julia 1.6.1
* JuMP 0.21.6
* Gurobi 9.1.2

