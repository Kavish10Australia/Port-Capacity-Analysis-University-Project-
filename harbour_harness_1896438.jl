using Pkg
Pkg.update()
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("DataStructures")
Pkg.add("StableRNGs")
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Statistics")
Pkg.add("Distributions")
Pkg.add("Plots")
Pkg.add("StatsPlots")

using CSV, DataFrames, Statistics, Distributions, Test, Plots, StatsPlots
# [1896438]
include("harbour_fns_1896438.jl")


rng = StableRNG(1896438)

# folder to save figures
mkpath(pwd() * "/figures" * "/interarrival times")
mkpath(pwd() * "/figures" * "/lock times")
mkpath(pwd() * "/figures" * "/unload times")
mkpath(pwd() * "/figures" * "/burnin times")

mkpath(pwd() * "/zeros")

# file to save data of terminal
mkpath(pwd() * "/terminal data") 
filename = "terminal data/Terminal_output.txt"
file_terminal = open(filename, "w")

historical_data = CSV.read("harbour_times.csv", DataFrame)


##################################################################################################################
zeros = map(col -> count(x -> x == 0, col), eachcol(historical_data))
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "count of zeros in interarrival_times,lock_times,unload_times are $(zeros[1]), $(zeros[2]), $(zeros[3]) respectively")

# removing all zeros values from lock times as this is only column containing zeros
final_cleaned_data = filter(row -> row.lock_times != 0, historical_data)

teeprint(file_terminal, stdout, "After removing zeros from lock_times column, the number of observations left are $(length(final_cleaned_data[:, 1]))")
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")




##################################################################################################################
# For the first distribution interarrival times 
interarrival_hist = histogram(final_cleaned_data[:, 1], xlabel = "distribution values (in hours)", ylabel = "Frequency", title = "Histogram for interarrival times", dpi = 600)
savefig(interarrival_hist, "figures/interarrival times/Histogram.png")


# From this we can say that this can either belong to normal distribution or uniform distribution 
# calculating the first two moments 
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Moments for interarrival times are m1, m2")
m1, m2 = moments(final_cleaned_data[:, 1])
teeprint(file_terminal, stdout, "m1: $(m1), m2: $(m2)")
teeprint(file_terminal, stdout, )


teeprint(file_terminal, stdout, "min and max values used for uniform distribution are calculated in report.")
teeprint(file_terminal, stdout, "mean used for normal distribution mean = $(m1), standard deviation = $((m2 - (m1^2))^0.5)")
teeprint(file_terminal, stdout, )



# using normal distribution with mean 35 and std = 14 to generate a qqplot
norm_intarr_sample = rand(rng, Normal(35, 14), 965)
qqplot_norm = qqplot(norm_intarr_sample, final_cleaned_data[:, 1], xlabel = "Theoretical Quantile", ylabel = "Sample Quantile", title = "Plot of interarrival times vs Norm(35, 14)", dpi = 600)
savefig(qqplot_norm, "figures/interarrival times/VsNorm(35, 14).png")



# using uniform distribution 
unif_interr_sample = rand(rng, Uniform(11, 59), 965)
qqplot_unif = qqplot(unif_interr_sample, final_cleaned_data[:, 1], xlabel = "Theoretical Quantile", ylabel = "Sample Quantile", title = "Plot of interarrival times vs Uniform(11, 59)", dpi = 600)
savefig(qqplot_unif, "figures/interarrival times/VsUniform(11, 59).png")
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")
##################################
################################################################################







##################################################################################################################
# For lock times 
lock_hist = histogram(final_cleaned_data[:, 2], xlabel = "distribution values", ylabel = "Frequency", title = "Histogram for lock times")
savefig(lock_hist, "figures/lock times/Histogram.png")


# From this we can say that this can either belong to exponential distribution or pareto distribution 
# calculating the first two moments 
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Moments for lock times are m1, m2")
m1, m2 = moments(final_cleaned_data[:, 2])
teeprint(file_terminal, stdout, "m1: $(m1), m2: $(m2)")
teeprint(file_terminal, stdout, )



# using exponential distribution with theta 11 to generate a qqplot
exp_lock_sample = rand(rng, Exponential(11), 965)
qqplot_exp = qqplot(exp_lock_sample, final_cleaned_data[:, 2], xlabel = "Theoretical Quantile", ylabel = "Sample Quantile", title = "Plot of lock times vs Exp(11)")
savefig(qqplot_exp, "figures/lock times/VsExp(11).png")



# using pareto distribution with alpha = 2 and beta = 6
par_lock_sample = rand(rng, Pareto(2, 6), 965)
qqplot_par = qqplot(par_lock_sample, final_cleaned_data[:, 2], xlabel = "Theoretical Quantile", ylabel = "Sample Quantile", title = "Plot of lock times vs Pareto(2, 6)")
savefig(qqplot_par, "figures/lock times/VsPareto(2, 6).png")
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")
##################################################################################################################








##################################################################################################################
# For unload times 
unload_hist = histogram(final_cleaned_data[:, 3], xlabel = "distribution values", ylabel = "Frequency", title = "Histogram for unload times")
savefig(unload_hist, "figures/unload times/Histogram.png")


# From this we can say that this belongs to normal distribution
# calculating the first two moments 
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Moments for unload times are m1, m2")
m1, m2 = moments(final_cleaned_data[:, 3])
teeprint(file_terminal, stdout, "m1: $(m1), m2: $(m2)")



# using normal distribution with mean 16 and std = 3 to generate a qqplot
norm_unload_sample = rand(rng, Normal(16, 3), 965)
qqplot_norm = qqplot(norm_unload_sample, final_cleaned_data[:, 3], xlabel = "Theoretical Quantile", ylabel = "Sample Quantile", title = "Plot of unload times vs Norm(16, 3)")
savefig(qqplot_norm, "figures/unload times/VsNorm(16, 3).png")



teeprint(file_terminal, stdout, "mean used for normal distribution mean = $(m1), standard deviation = $((m2 - (m1^2))^0.5)")
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")
##################################################################################################################


#############################################################################################################################################################################
#############################################################################################################################################################################
################################################################################# TESTING HERE ##############################################################################
#############################################################################################################################################################################
#############################################################################################################################################################################

# Unit testing 
# This section can be completely run at a time
begin 
    # inititialise
    seed = 1896438
    T = 30000.0
    lower_interarrival = 11.00          ###    units here are hours
    upper_interarrival = 59.00
    mean_process_times = [11, 16]
    max_queue = [typemax(Int64), 4]
    time_units = "hours"
    P = Parameters(
        seed,
        T,
        lower_interarrival,
        upper_interarrival,
        mean_process_times,
        max_queue,
        time_units,
    )
end



# Here are some unit tests
# Checking random number generators
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Unit testing RandomNGs() function")
@testset "RandomNGs check" begin
    rngs =  RandomNGs(P) 
    interarrival_time = rngs.interarrival_time()

    @test interarrival_time >= P.lower_interarrival && interarrival_time <= P.upper_interarrival

    sample_pt1 = [rngs.process_times[1]() for _ in 1:1000]
    @test all(x -> x > 0, sample_pt1)
    mean_sample1 = mean(sample_pt1)

    @test isapprox(mean_sample1, 11, atol=0.5)  

    sample_pt2 = [rngs.process_times[2]() for _ in 1:1000]
    mean_sample = mean(sample_pt2)
    var_sample = var(sample_pt2)

    @test isapprox(mean_sample, 16, atol=0.5)
    @test isapprox(var_sample, 9, atol=0.5)
end 
teeprint(file_terminal, stdout, "Unit testing RandomNGs() function passed")


# Testing Ship function
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Unit testing Ship() function")
@testset "Check ship function" begin 
    ship = Ship(1, 0.0)
    @test ship.id == 1
    @test ship.arrival_time == 0.0
    @test length(ship.start_service_times) == 2
    @test ship.completion_time == Inf

    ship.start_service_times[1] = 10.90 
    @test ship.start_service_times[1] == 10.90 

    ship.start_service_times[2] = 18.81 
    @test ship.start_service_times[2] == 18.81

    ship.completion_time = 30.67 
    @test ship.completion_time == 30.67
end
teeprint(file_terminal, stdout, "Unit testing Ship() function passed")



teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Testing SystemState() function")
@testset "Checking system state function" begin
    system = SystemState(P)
    
    @test system.time == 0.0
    @test system.n_entities == 0
    @test system.n_events == 0
    @test isempty(system.event_queue)
    @test length(system.ship_queues) == 2
    @test all(isequal(Queue{Ship}()), system.ship_queues)
    @test length(system.in_service) == 2
    @test system.in_service[1] === nothing
    @test system.in_service[2] === nothing
end
teeprint(file_terminal, stdout, "Testing SystemState() function passed")


teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Checking initialise() function")
@testset "Checking initialise function" begin
    state, rnums = initialise(P)
    @test state.time == 0.000 
    @test length(state.event_queue) == 1 

    event, time = peek(state.event_queue)
    @test typeof(event) == Arrival 
    @test time == 0.000 

    @test length(state.ship_queues) == 2
    @test all(isequal(Queue{Ship}()), state.ship_queues)

    @test state.in_service[1] === nothing
    @test state.in_service[2] === nothing

    @test typeof(rnums) == RandomNGs
end
teeprint(file_terminal, stdout, "Checking initialise() function passed")


# Integration testing
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "Checking move_to_server() function") 
@testset "Checking move_to_server function" begin
    state, rnums = initialise(P)

    # checking for lock
    ship = Ship(1, 18.00)
    enqueue!(state.ship_queues[1], ship)
    move_to_server!(state, rnums, 1)

    @test typeof(state.in_service[1]) == Ship
    @test state.in_service[1].id == 1 
    @test state.in_service[1].arrival_time == 18.00 
    @test state.in_service[1].start_service_times[1] == state.time
    @test state.in_service[1].completion_time == Inf

    # checking for dock
    ship = Ship(2, 20.00)
    enqueue!(state.ship_queues[2], ship)
    move_to_server!(state, rnums, 2)

    @test typeof(state.in_service[2]) == Ship
    @test state.in_service[2].id == 2 
    @test state.in_service[2].arrival_time == 20.00 
    @test state.in_service[2].start_service_times[2] == state.time
    @test state.in_service[2].completion_time == Inf
end
teeprint(file_terminal, stdout, "Checking move_to_server() function passed")
teeprint(file_terminal, stdout, )



# performance testing
teeprint(file_terminal, stdout, "Performing performance test on simulation run")
@time begin
    state, rnums = initialise(P)
    
    dir = pwd() * "./testing/performance_testing" * "/seed" * string(P.seed)
    mkpath(dir)                        
    file_entities = dir * "/entities.csv"  
    file_state = dir * "/state.csv"        
    fid_entities = open(file_entities, "w") 
    fid_state = open(file_state, "w")       

    write_metadata(fid_entities)
    write_metadata(fid_state)
    write_parameters(fid_entities, P)
    write_parameters(fid_state, P)

    run!(state, P, rnums, fid_state, fid_entities)

    close(fid_entities)
    close(fid_state)

end

teeprint(file_terminal, stdout, "Performance test complete")
teeprint(file_terminal, stdout, )
teeprint(file_terminal, stdout, "------------------------------------------------------------------------------------------------")


#############################################################################################################################################################################
#############################################################################################################################################################################
####################################################################### SIMULATION HERE #####################################################################################
#############################################################################################################################################################################
#############################################################################################################################################################################
begin
    rerun = false
    seed_start = 1896438
    seed_end = 1896637

    # inititialise
    T = 30000.0
    lower_interarrival = 11.00          ###    units here are hours
    upper_interarrival = 59.00
    mean_process_times = [11, 16]
    max_queue = [typemax(Int64), 4]
    time_units = "hours"
end 

for seed in seed_start:seed_end

    Params = Parameters(
        seed,
        T,
        lower_interarrival,
        upper_interarrival,
        mean_process_times,
        max_queue,
        time_units,
    )
    # file directory and name; * concatenates strings.
    dir1 = pwd() * "./data" * "/seed" * string(Params.seed) # directory name
    mkpath(dir1)                          # this creates the directory
    file_entities_1 = dir1 * "/entities.csv"  # the name of the data file (informative)
    file_state_1 = dir1 * "/state.csv"        # the name of the data file (informative)
    fid_entities_1 = open(file_entities_1, "w") # open the file for writing
    fid_state_1 = open(file_state_1, "w")       # open the file for writing

    write_metadata(fid_entities_1)
    write_metadata(fid_state_1)
    write_parameters(fid_entities_1, Params)
    write_parameters(fid_state_1, Params)

    # headers
    write_entity_header(fid_entities_1, Ship(0, 0.0))
    println(
        fid_state_1,
        "time,event_id,event_type,timing,length_event_list,length_queue1,length_queue2,in_service1,in_service2",
    )


    # run the actual simulation
    (system, R) = initialise(Params)
    run!(system, Params, R, fid_state_1, fid_entities_1)

    # remember to close the files
    close(fid_entities_1)
    close(fid_state_1)
end


# creating the increase by 10 percent in arrival rate
begin
    rerun = false
    seed_start = 1896438
    seed_end = 1896637

    # inititialise
    T = 30000.0
    lower_interarrival = 7.8         
    upper_interarrival = 55.8
    mean_process_times = [11, 16]
    max_queue = [typemax(Int64), 4]
    time_units = "hours"
end 

for seed in seed_start:seed_end

    Params = Parameters(
        seed,
        T,
        lower_interarrival,
        upper_interarrival,
        mean_process_times,
        max_queue,
        time_units,
    )
    
    dir1 = pwd() * "./data_10%" * "/seed" * string(Params.seed) 
    mkpath(dir1)                         
    file_entities_1 = dir1 * "/entities.csv"  
    file_state_1 = dir1 * "/state.csv"        
    fid_entities_1 = open(file_entities_1, "w") 
    fid_state_1 = open(file_state_1, "w")      

    write_metadata(fid_entities_1)
    write_metadata(fid_state_1)
    write_parameters(fid_entities_1, Params)
    write_parameters(fid_state_1, Params)

    # headers
    write_entity_header(fid_entities_1, Ship(0, 0.0))
    println(
        fid_state_1,
        "time,event_id,event_type,timing,length_event_list,length_queue1,length_queue2,in_service1,in_service2",
    )


    # run the actual simulation
    (system, R) = initialise(Params)
    run!(system, Params, R, fid_state_1, fid_entities_1)

    # remember to close the files
    close(fid_entities_1)
    close(fid_state_1)
end



##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################


# window_average_write(start seed, end seed, total time units, window size, directories)
window_average_write(1896438, 1896537, 30000, 80, ["data", "data_10%"])


# plots burnin plot uses 100 seeds
plot_burnin = burnin_time(1896438, 1896537)
savefig(plot_burnin, "figures/burnin times/burnin_time.png")


##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################

# QUESTION 1
mkpath(pwd() * "/figures" * "/QUESTIONS")

# calculating harbour occupancy over time 50000 after 5000 and for 500 realizations
harbour_occupancy = Vector{Float64}() 
for seed in 1896438:1896637
    fz1 = "data/seed$(seed)/state.csv"

    z1 = CSV.read(fz1, DataFrame, comment = "#")
    z1 = filter(row -> row.time > 3000 && row.time <= 30000 && row.timing == " after", z1)
    # This pushes time average value in the vector
    push!(harbour_occupancy, sum(z1.length_queue2)/length(z1.length_queue2))
end
h1 = histogram(harbour_occupancy, xlabel = "Time average occupancy (in hours)", ylabel = "Frequency")
# 99% confidence interval 
lower, upper = cf(harbour_occupancy, 0.01)

# plotting confidence interval line
vline!(h1, [lower, upper], xlabel = "Time average occupancy (in hours)", ylabel = "Frequency", color=:red, linewidth=2, linestyle=:dash)
savefig(h1, "figures/QUESTIONS/Question1A.png")

teeprint(file_terminal, stdout, "----------------------------------------------------------------------------------------")
teeprint(file_terminal, stdout, "Time average occupancy of harbour queue is $(mean(harbour_occupancy)) hours")
teeprint(file_terminal, stdout, "Value of lower and upper confidence interval for time average harbour queue size is $lower and $upper")
teeprint(file_terminal, stdout, "----------------------------------------------------------------------------------------")
ensem = q1(1896438, 1896637) # 200 seeds
savefig(ensem, "figures/QUESTIONS/Question1B.png")

# QUESTION 2

# calculating sea occupancy over time 30000 after 3000 and for 200 realizations
sea_occupancy = Vector{Float64}() 
for seed in 1896438:1896637
    fq1 = "data/seed$(seed)/state.csv"

    y1 = CSV.read(fq1, DataFrame, comment = "#")
    y1 = filter(row -> row.time > 3000 && row.time <= 30000 && row.timing == " after", y1)
    # This pushes time average value in the vector
    push!(sea_occupancy, sum(y1.length_queue1)/length(y1.length_queue1))
end
h1 = histogram(sea_occupancy, xlabel = "Time average occupancy (in hours)", ylabel = "Frequency")
# 99% confidence interval 
lower1, upper1 = cf(sea_occupancy, 0.01)

# plotting confidence interval line
vline!(h1, [lower1, upper1], xlabel = "Time average occupancy (in hours)", ylabel = "Frequency", color=:red, linewidth=2, linestyle=:dash)
savefig(h1, "figures/QUESTIONS/Question2A.png")

teeprint(file_terminal, stdout, "----------------------------------------------------------------------------------------")
teeprint(file_terminal, stdout, "Time average occupancy of sea queue is $(mean(sea_occupancy)) hours")
teeprint(file_terminal, stdout, "Value of lower and upper confidence interval for time average sea queue size is $lower1 and $upper1")
teeprint(file_terminal, stdout, "----------------------------------------------------------------------------------------")
ensem2 = q2(1896438, 1896637) # 200 seeds
savefig(ensem2, "figures/QUESTIONS/Question2B.png")

# QUESTION 3

data_10 = DataFrame(time = 1:24:30000)
for seed in 1896438:1896637 
    state_seed = Vector()
    data_11 = CSV.read("data/seed$(seed)/state.csv", DataFrame, comment = "#")
    data_11 = filter(x -> x.timing == " after" && x.time <= 30000, data_11)
    for i in 1:24:30000
        df_11 = filter(x -> x.time < i, data_11)
        push!(state_seed, df_11[end, :length_queue1] + df_11[end, :length_queue2] + df_11[end, :in_service1] + df_11[end, :in_service2])
    end
    data_10[!, "$(seed)"] = state_seed
end
row_means_10 = [mean(row) for row in eachrow(data_10[:, 2:end])]
data_10.mean_all = row_means_10

# for 10 percent increase in arrivals
data_increase_10 = DataFrame(time = 1:24:30000)
for seed in 1896438:1896637 
    state_seed = Vector()
    data_111 = CSV.read("data_10%/seed$(seed)/state.csv", DataFrame, comment = "#")
    data_111 = filter(x -> x.timing == " after" && x.time <= 30000, data_111)
    for i in 1:24:30000
        df_111 = filter(x -> x.time < i, data_111)
        push!(state_seed, df_111[end, :length_queue1] + df_111[end, :length_queue2] + df_111[end, :in_service1] + df_111[end, :in_service2])
    end
    data_increase_10[!, "$(seed)"] = state_seed
end
row_means_increase = [mean(row) for row in eachrow(data_increase_10[:, 2:end])]
data_increase_10.mean_all = row_means_increase 

plot_10_increase = plot(dpi = 600, xlabel = "Time (in hours)", ylabel = "Ships in the system", xlims = (3000, 30000))
plot!(plot_10_increase, data_increase_10.time, data_increase_10.mean_all, label = "10 percent increase")
plot!(plot_10_increase, data_10.time, data_10.mean_all, label = "BAU")
savefig(plot_10_increase, "figures/QUESTIONS//Question3A.png")


close(file_terminal)
