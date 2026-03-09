using DataStructures
using Distributions
using StableRNGs
using Printf
using Dates

### use one global variable
const n_servers = 2

###Processes:
###     i=1: lock 
###     i=2: unloading



### Entity data structure for each ship
mutable struct Ship
    id::Int64
    arrival_time::Float64    # time when the ship arrives at the lock
    start_service_times::Array{Float64,1}  # array of times when the ship starts process i
    completion_time::Float64 # time when the unloading is complete
end
# generate a newly arrived ship (where lock time and unloading time are unknown)
Ship(id::Int64, arrival_time::Float64) =
    Ship(id, arrival_time, Array{Float64,1}(undef, 2), Inf)

### Events
abstract type Event end

struct Arrival <: Event # ship arrives
    id::Int64         # a unique event id
    time::Float64     # the time of the event
end

mutable struct Finish <: Event # a ship finishes process i
    id::Int64         # a unique event id
    time::Float64     # the time of the event
    server::Int64     # ID of the server that is finishing
end

struct Null <: Event # ship arrives
    id::Int64
end

### parameter structure
struct Parameters
    seed::Int
    T::Float64
    lower_interarrival::Float64
    upper_interarrival::Float64
    mean_process_times::Array{Float64,1}
    max_queue::Array{Int64,1}          # space available in each queue
    time_units::String
end
function write_parameters(output::IO, P::Parameters) # function to writeout parameters
    T = typeof(P)
    for name in fieldnames(T)
        println(output, "# parameter: $name = $(getfield(P,name))")
    end
end
write_parameters(P::Parameters) = write_parameters(stdout, P)
function write_metadata(output::IO) # function to writeout extra metadata
    (path, prog) = splitdir(@__FILE__)
    println(output, "# file created by code in $(prog)")
    t = now()
    println(output, "# file created on $(Dates.format(t, "yyyy-mm-dd at HH:MM:SS"))")
end

### State
mutable struct SystemState
    time::Float64                               # the system time (simulation time)
    n_entities::Int64                           # the number of entities to have been served
    n_events::Int64                             # tracks the number of events to have occur + queued
    event_queue::PriorityQueue{Event,Float64}   # to keep track of future arrivals/services
    ship_queues::Array{Queue{Ship},1}         # the system queues (1 is the arrival queue)
    in_service::Array{Union{Ship,Nothing},1}   # the ship currently in service at process i if there is one
end
function SystemState(P::Parameters) # create an initial (empty) state
    init_time = 0.0
    init_n_entities = 0
    init_n_events = 0
    init_event_queue = PriorityQueue{Event,Float64}()
    init_ship_queues = Array{Queue{Ship},1}(undef, n_servers)
    for i in 1:n_servers
        init_ship_queues[i] = Queue{Ship}()
    end
    init_in_service = Array{Union{Ship,Nothing},1}(undef, n_servers)
    for i in 1:n_servers
        init_in_service[i] = nothing
    end
    return SystemState(
        init_time,
        init_n_entities,
        init_n_events,
        init_event_queue,
        init_ship_queues,
        init_in_service,
    )
end

# setup random number generators
struct RandomNGs
    rng::StableRNGs.LehmerRNG
    interarrival_time::Function
    process_times::Array{Function,1}
end

# constructor function to create all the pieces required
function RandomNGs(P::Parameters)
    rng = StableRNG(P.seed) # create a new RNG with seed set to that required
    rng_b = StableRNG(P.seed) # create a second rng to generate the extra times so the others remain the same
    interarrival_time() = rand(rng, Uniform(P.lower_interarrival, P.upper_interarrival))

    process_times = Array{Function,1}(undef, n_servers)


    ############################################################################################################
    process_times[1] = () -> rand(rng_b, Exponential(P.mean_process_times[1]))   #### changed from pareto to exponential
    process_times[2] = () -> rand(rng, Normal(P.mean_process_times[2], 3))       #### changed from exponential to Normal
    ############################################################################################################

    return RandomNGs(rng, interarrival_time, process_times)
end

# initialisation function for the simulation
function initialise(P::Parameters)
    # construct random number generators and system state
    R = RandomNGs(P)
    system = SystemState(P)

    # add an arrival at time 0.0
    t0 = 0.0
    # system.n_events += 1
    enqueue!(system.event_queue, Arrival(0, t0), t0)

    return (system, R)
end

### output functions to write out the state of the system and the entities to file
function write_state(
    event_file::IO,
    system::SystemState,
    event::Event,
    timing::AbstractString;
    debug_level::Int = 0,
)
    if typeof(event) <: Finish
        type_of_event = "Finish($(event.server))"
    else
        type_of_event = typeof(event)
    end

    @printf(
        event_file,
        "%12.3f,%6d,%9s,%6s,%4d,%4d,%4d,%4d,%4d\n",
        system.time,
        event.id,
        type_of_event,
        timing,
        length(system.event_queue),
        length(system.ship_queues[1]),
        length(system.ship_queues[2]),
        system.in_service[1] == nothing ? 0 : 1,
        system.in_service[2] == nothing ? 0 : 1,
    )
end

function write_entity_header(entity_file::IO, entity)
    T = typeof(entity)
    x = Array{Any,1}(undef, length(fieldnames(typeof(entity))))
    for (i, name) in enumerate(fieldnames(T))
        tmp = getfield(entity, name)
        if isa(tmp, Array)
            x[i] = join(repeat([name], length(tmp)), ',')
        else
            x[i] = name
        end
    end
    println(entity_file, join(x, ','))
end

function write_entity(entity_file::IO, entity; debug_level::Int = 0)
    T = typeof(entity)
    x = Array{Any,1}(undef, length(fieldnames(typeof(entity))))
    for (i, name) in enumerate(fieldnames(T))
        tmp = getfield(entity, name)
        if isa(tmp, Array)
            x[i] = join(tmp, ',')
        else
            x[i] = tmp
        end
    end
    println(entity_file, join(x, ','))
end

### Update functions
function update!(system::SystemState, P::Parameters, R::RandomNGs, e::Event)
    throw(DomainError("invalid event type"))
end

function move_to_server!(system::SystemState, R::RandomNGs, server::Integer)
    # move the ship from a queue into service
    system.in_service[server] = dequeue!(system.ship_queues[server])
    system.in_service[server].start_service_times[server] = system.time # start service 'now'
    completion_time = system.time + R.process_times[server]() # best current guess at service time

    # create a finish event for the current process
    system.n_events += 1
    finish_event = Finish(system.n_events, completion_time, server)
    enqueue!(system.event_queue, finish_event, completion_time)
    return nothing
end

function update!(system::SystemState, P::Parameters, R::RandomNGs, event::Arrival)
    # create an arriving ship and add it to the 1st queue
    system.n_entities += 1    # new entity will enter the system
    new_ship = Ship(system.n_entities, event.time)
    enqueue!(system.ship_queues[1], new_ship)

    # generate next arrival and add it to the event queue
    system.n_events += 1
    future_arrival = Arrival(system.n_events, system.time + R.interarrival_time())
    enqueue!(system.event_queue, future_arrival, future_arrival.time)

    # if space is available, the ship goes to service
    if system.in_service[1] == nothing
        move_to_server!(system, R, 1)
    end
    return nothing
end

function stall_event!(system::SystemState, event::Event)
    # defer an event until after the next event in the list
    next_event_time = peek(system.event_queue)[2]
    event.time = next_event_time + eps() # add eps() so that this event occurs just after the next event
    enqueue!(system.event_queue, event, event.time)
    return nothing
end

function update!(system::SystemState, P::Parameters, R::RandomNGs, event::Finish)
    server = event.server
    if server < n_servers &&
       length(system.ship_queues[server + 1]) >= P.max_queue[server + 1]
        # if the server finishes, but there are too many construction units in the next queue,
        # then defer the event until the queue has space, i.e, the next finish event
        # but finding the next event is easy, and next finish is hard, so we stall by one
        stall_event!(system, event)
    else
        # otherwise treat this as normal finish of service
        departing_ship = deepcopy(system.in_service[server])
        system.in_service[server] = nothing

        if !isempty(system.ship_queues[server]) # if a ship is waiting, move them to service
            move_to_server!(system, R, server)
        end

        if server < n_servers
            # move the construction unit to the next queue
            enqueue!(system.ship_queues[server + 1], departing_ship)
            if system.in_service[server + 1] === nothing
                move_to_server!(system, R, server + 1)
            end
        else
            # or return the entity when it is leaving the system for good
            departing_ship.completion_time = system.time
            return departing_ship
        end
    end
    return nothing
end

function run!(
    system::SystemState,
    P::Parameters,
    R::RandomNGs,
    fid_state::IO,
    fid_entities::IO,
)
    # main simulation loop
    while system.time < P.T
        if P.seed == 1 && system.time <= 1000.0
            println("$(system.time): ") # debug information for first few events whenb seed = 1
        end

        # grab the next event from the event queue
        (event, time) = dequeue_pair!(system.event_queue)
        system.time = time  # advance system time to the new arrival
        # system.n_events += 1      # increase the event counter

        # write out event and state data before event
        write_state(fid_state, system, event, "before")

        # update the system based on the next event, and spawn new events.
        # return arrived/departed customer.
        departure = update!(system, P, R, event)

        # write out event and state data after event
        write_state(fid_state, system, event, "after")

        # write out entity data if it was a departure from the system
        if departure !== nothing
            write_entity(fid_entities, departure)
        end
    end
    return system
end





##################################################################################
##################################################################################
############################# ADDITION OF EXTRA functions ########################
##################################################################################
##################################################################################


function moments(distn::Vector{Float64})
    length_ = length(distn)
    sum_for_ex = 0.0 
    sum_for_ex2 = 0.0
    for i in 1:length_ 
        sum_for_ex += distn[i]
        sum_for_ex2 += distn[i]^2 
    end 

    ex = sum_for_ex/length_
    ex2 = sum_for_ex2/length_

    ex = round(ex, digits = 3)
    ex2 = round(ex2, digits = 3)
    return ex, ex2 
end 

# Function to print terminal output and also save in the txt file
function teeprint(io1::IO, io2::IO, xs...)
    println(io1, xs...)
    println(io2, xs...)
end

function interarrival_rate(l, u)
    return 2/(l+u)
end


# BURN IN TIME
function burnin_time(st, se)
    mean_vector = Vector{Float64}()
    rm = Vector{Float64}()

    data = CSV.read("data/seed$(st)/wa.csv", DataFrame, comment = "#")
    data = filter(row -> row.time <= 15000, data)
    plot_object = plot(data.time, data.total_ships, xticks = (0:3000:15000), xlabel = "Time (in Hours)", ylabel = "Ships", legend = false, dpi = 600)
    df = DataFrame(st = data.total_ships)
    for seed in (st+1):se
        data = CSV.read("data/seed$(seed)/wa.csv", DataFrame, comment = "#")
        data = filter(row -> row.time <= 15000, data)
        plot!(plot_object, data.time, data.total_ships, dpi = 600)
        df.seed = data.total_ships
    end

    for i in 1:length(df[:, 1])
        push!(mean_vector, mean(df[i, :]))
    end
    
    cnt = 1
    for i in 1:length(mean_vector)
        
        if i < 80
            if i == 1 
                push!(rm, mean_vector[i]/((2*i)+1))
            else 
                push!(rm, sum(mean_vector[(i - cnt):(i + cnt)])/((2*i)+1))
                cnt += 1
            end 
        elseif i > 80 && i < length(mean_vector) - 80
            push!(rm, sum(mean_vector[(i-80):(i+80)])/((2*80)+1))
        end 
    end

    for i in 1:82
        push!(rm, rm[length(rm)])
    end

    plot!(plot_object, data.time, rm, color=:black, linewidth=3, seriestype=:steppost, dpi = 600)
    # save the plot
    return plot_object
end 



function window_average(wsize, cmptime, data, seed, d)
    total_windows = cmptime/wsize 
    if typeof(window_average) == Float64 
        println("Cannot have all windows of same size so choose a different value.")
    end

    dataframe_to_return = DataFrame(time = [], total_ships = [], harbour_ships = [])
    start_point = 0 
    end_point = wsize
    for i in 1:total_windows
        dataframe = filter(row -> row.time < end_point && row.time >= start_point, data)
        total_ships_in_the_system = dataframe.length_queue1 .+ dataframe.length_queue2 .+ dataframe.in_service1 .+ dataframe.in_service2
        ships_in_harbour = dataframe.length_queue2
        if length(total_ships_in_the_system) == 0
            row_to_add = push!(dataframe_to_return, (time = end_point, total_ships = 0.0, harbour_ships = 0.0))
        else
            row_to_add = push!(dataframe_to_return, (time = end_point, total_ships = sum(total_ships_in_the_system)/length(total_ships_in_the_system), harbour_ships = sum(ships_in_harbour)/length(ships_in_harbour)))
        end

        new_start = end_point 
        end_point = end_point + wsize 
        start_point = new_start
    end
    return dataframe_to_return
end 




function window_average_write(st, se, cmptime, wsize, dir)
    for d in dir
        for seed in st:se 
            data = CSV.read(pwd() * "/$(d)/seed$(seed)" * "/state.csv", DataFrame, comment = "#")
            data = filter(row -> row.time < cmptime && row.timing == " after", data)

            file_to_write = open(pwd() * "/$(d)/seed$(seed)/wa.csv", "w")
            wa = window_average(wsize, cmptime, data, seed, d)
            CSV.write(file_to_write, wa)
            close(file_to_write)
        end
    end
end 


function cf(v, alpha=0.05)
    lower, upper = quantile(v, alpha/2), quantile(v, 1-alpha/2)
    return lower, upper
end


function q1(st, se) 

    data_1 = DataFrame(time = 1:24:30000)
    for seed in st:se 
        state_seed = Vector()
        data = CSV.read("data/seed$(seed)/state.csv", DataFrame, comment = "#")
        data = filter(x -> x.timing == " after" && x.time <= 30000, data)
        for i in 1:24:30000
            df = filter(x -> x.time < i, data)
            push!(state_seed, df[end, :length_queue2])
        end
        data_1[!, "$(seed)"] = state_seed
    end
    row_means = [mean(row) for row in eachrow(data_1[:, 2:end])]
    data_1.mean_all = row_means

    data_1 = filter(x -> x.time > 3000, data_1)
    plt_obj = plot(dpi = 600, legend = false)
    for seed in st:se
        plot!(plt_obj, data_1.time, data_1[!, "$(seed)"])
    end 

    plot!(plt_obj, data_1.time, data_1.mean_all, color=:black, linewidth=3, seriestype=:steppost)
    plot!(xlabel = "Time", ylabel = "ships in harbour queue")
    return plt_obj 
end

function q2(st, se) 

    data_1 = DataFrame(time = 1:24:30000)
    for seed in st:se 
        state_seed = Vector()
        data = CSV.read("data/seed$(seed)/state.csv", DataFrame, comment = "#")
        data = filter(x -> x.timing == " after" && x.time <= 30000, data)
        for i in 1:24:30000
            df = filter(x -> x.time < i, data)
            push!(state_seed, df[end, :length_queue1])
        end
        data_1[!, "$(seed)"] = state_seed
    end
    row_means = [mean(row) for row in eachrow(data_1[:, 2:end])]
    data_1.mean_all = row_means

    data_1 = filter(x -> x.time > 3000, data_1)
    plt_obj = plot(dpi = 600, legend = false)
    for seed in st:se
        plot!(plt_obj, data_1.time, data_1[!, "$(seed)"])
    end 

    plot!(plt_obj, data_1.time, data_1.mean_all, color=:black, linewidth=3, seriestype=:steppost)
    plot!(xlabel = "Time", ylabel = "ships in sea queue")
    return plt_obj 
end