module GBIO

using GBCore
using FileIO
using JLD2, CodecZlib
using GZip
using Dates
using ProgressMeter
using PrecompileTools: @compile_workload

include("fuzzy_matching.jl")
include("jld2.jl")
include("tsv.jl")
include("vcf.jl")

export levenshteindistance, isfuzzymatch
export readjld2, writejld2
export readdelimited, writedelimited
export readvcf, writevcf

# # Precompile
# @compile_workload begin
#     n = 10
#     genomes = GBCore.simulategenomes(n = n)
#     trials, effects = GBCore.simulatetrials(
#         genomes = genomes,
#         f_add_dom_epi = [
#             0.50 0.25 0.13
#             0.90 0.00 0.00
#         ],
#         n_years = 1,
#         n_seasons = 1,
#         n_harvests = 1,
#         n_sites = 1,
#         n_replications = 2,
#     )
#     phenomes = GBCore.Phenomes(n = n, t = 2)
#     phenomes.entries = trials.entries[1:n]
#     phenomes.populations = trials.populations[1:n]
#     phenomes.traits = trials.traits
#     phenomes.phenotypes = trials.phenotypes[1:n, :]
#     phenomes.mask .= true
#     # tebv = GBCore.analyse(trials, max_levels = 10)

#     fname_genomes_jld2 = writejld2(genomes)
#     fname_phenomes_jld2 = writejld2(phenomes)
#     fname_trials_jld2 = writejld2(trials)
#     fname_effects_jld2 = writejld2(effects[1])
#     # fname_tebv_jld2 = writejld2(tebv)

#     fname_genomes_tsv = writedelimited(genomes)
#     fname_phenomes_tsv = writedelimited(phenomes)
#     fname_trials_tsv = writedelimited(trials)

#     readjld2(Genomes, fname_genomes_jld2)
#     readjld2(Phenomes, fname_phenomes_jld2)
#     readjld2(Trials, fname_trials_jld2)
#     readjld2(SimulatedEffects, fname_effects_jld2)
#     # readjld2(TEBV, fname_tebv_jld2)

#     readdelimited(Genomes, fname = fname_genomes_tsv)
#     # readdelimited(Phenomes, fname=fname_phenomes_tsv)
#     # readdelimited(Trials, fname=fname_trials_tsv)

#     rm.([
#         fname_genomes_jld2,
#         fname_phenomes_jld2,
#         fname_trials_jld2,
#         fname_effects_jld2,
#         # fname_tebv_jld2,
#         fname_genomes_tsv,
#         fname_phenomes_tsv,
#         fname_trials_tsv,
#     ])
# end

end
