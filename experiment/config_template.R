# Config template for experiment_analysis.R. This is to be run after you have
# run and parsed experiments. This gets sourced by experiment_analysis.R.

prefix <- './output/'       # Choose this to be where your parsed output is stored. Other scripts use this default.
focus_scale <- 22           # Kronecker graph size (2^scale vertices) over which analysis is done.
threads <- c(1,2,4,8,16,32,64,72)    # Select a range of threads over which to measure scalability
# THREADS="1 2 4 8 16 24 32 40 48 56 64 72" TODO:  Rerun for scale 22 and analyze
focus_thread <- 32          # Pick a thread count for more detailed analysis (generate timing plots)
algos <- c("BFS","SSSP","PageRank")  # Which algorithms you ran experiments for. (currently not "TC")

# Whether to coalese performance data into one giant CSV (useful for input to machine learning).
# Any variables following coalesce are only used if coalesce is TRUE.
coalesce <- TRUE
ignore_extra_features <- FALSE # Whether to use features.csv for realworld datasets. OFF by default
coalesce_filename <- paste0(prefix,'combined.csv')
data_dir <- "datasets"     # The directory where the datasets (and features) are stored
kron_scales <- c(10,13,18) # Select whichever scales on which you ran the synthetic datasets
realworld_datasets <- read.csv('../learn/datasets.txt', header = FALSE) # Just get the directory names which are every 3rd line
realworld_datasets <- as.character(realworld_datasets[seq(1, nrow(realworld_datasets), 3), 1])
