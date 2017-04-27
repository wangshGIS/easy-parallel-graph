#!/bin/bash
USAGE="usage: real-datasets.sh [--libdir=<dir>] [--ddir=<dir>] <num_threads>
	--libdir: repositories directory. Default: ./lib
	--ddir: dataset directory. Default: ./datasets"

DDIR="$(pwd)/datasets" # Dataset directory
LIBDIR="$(pwd)/lib"
for arg in "$@"; do
	case $arg in
	--libdir=*)
		LIBDIR=${arg#*=}
		shift
	;;
	--ddir=*)
		DDIR=${arg#*=}
		shift
	;;
	-h|--help|-help)
		echo "$USAGE"
		exit 2
	;;
	*)	# Default
		# Do nothing
	esac
done
if [ "$#" -lt 1 ]; then
	echo 'Please provide <num_threads>'
	echo $USAGE
	exit 2
fi

# Choose the datasets. This is a space-separated list.
DATA="dota-league cit-Patents"

# The reasoning behind these values are explained in run-experiment.sh
MAXITER=50 # Maximum iterations for PageRank
TOL=0.00000006
NRT=32 # Number of roots
export SKIP_VALIDATION=1
if [ "$#" -ne 1 -o "$1" = "-h" -o "$1" = "--help" ]; then
	echo "$USAGE"
	exit 2
fi
export OMP_NUM_THREADS=$1
GAPDIR="$LIBDIR/gapbs"
GRAPHBIGDIR="$LIBDIR/graphBIG"
GRAPH500DIR="$LIBDIR/graph500"
GRAPHMATDIR="$LIBDIR/GraphMat"
POWERGRAPHDIR="$LIBDIR/PowerGraph"

# icpc required for GraphMat
module load intel/17

# Build notes for arya:
# see run-experiment.sh

# GraphMat doesn't currently work
# "$GRAPHMATDIR/bin/graph_converter" --selfloops 1 --duplicatededges 0 --inputformat 1 --outputformat 0 --inputheader 0 --outputheader 1 --edgeweighttype 1 --inputedgeweights 1 --outputedgeweights 1 "$DDIR/$DATA.wel" "$DDIR/$DATA.graphmat"
# # Run GraphMat PageRank
# # PageRank stops when none of the vertices change
# # GraphMat has been modified so alpha = 0.15
# for ROOT in $(head -n $NRT "$DDIR/$DATA-roots.v"); do
# 	"$GRAPHMATDIR/bin/PageRank" "$DDIR/$DATA.graphmat"
# done
# 
# # Run the GraphMat SSSP
# for ROOT in $(head -n $NRT "$DDIR/$DATA-roots.v"); do
# 	echo "SSSP root: $ROOT"
# 	"$GRAPHMATDIR/bin/SSSP" "$DDIR/$DATA.graphmat" $ROOT
# done
# 
# # Run the GraphMat BFS
# for ROOT in $(head -n $NRT "$DDIR/$DATA-roots.v"); do
# 	echo "BFS root: $ROOT"
# 	"$GRAPHMATDIR/bin/BFS" "$DDIR/$DATA.graphmat" $ROOT
# done
# 
# # Run PowerGraph PageRank
# for ROOT in $(head -n $NRT "$DDIR/$DATA-roots.v"); do
# 	"$POWERGRAPHDIR/release/toolkits/graph_analytics/pagerank" --graph "$DDIR/$DATA.wel" --tol "$TOL" --format tsv
# done

echo Starting experiment at $(date)
# TODO: for d in $DATA; do
# ...
# done
# Run for GAP BFS
# It would be nice if you could read in a file for the roots
# Just do one trial to be the same as the rest of the experiments
for ROOT in $(head -n $NRT "$DDIR/$d/${d}-roots.v"); do
	"$GAPDIR"/bfs -r $ROOT -f "$DDIR/$d/${d}.wel" -n 1
done

# Run the GraphBIG BFS
# For this, one needs a vertex.csv file and and an edge.csv.
head -n $NRT "$DDIR/$d/${d}-roots.v" > "$DDIR/$d/${d}-${NRT}roots.v"
"$GRAPHBIGDIR/benchmark/bench_BFS/bfs" --dataset "$DDIR/$d" --rootfile "$DDIR/$d/${d}-${NRT}roots.v" --threadnum $OMP_NUM_THREADS

# Run the GAP SSSP for each root
for ROOT in $(head -n $NRT "$DDIR/$d/${d}.v"); do
	"$GAPDIR"/sssp -r $ROOT -f "$DDIR/$d/${d}.wel" -n 1
done

# Run the GraphBIG SSSP
"$GRAPHBIGDIR/benchmark/bench_shortestPath/sssp" --dataset "$DDIR/$d" --rootfile "$DDIR/$d/${d}-${NRT}roots.v" --threadnum $OMP_NUM_THREADS

# Run PowerGraph SSSP
if [ "$OMP_NUM_THREADS" -gt 64 ]; then
    export GRAPHLAB_THREADS_PER_WORKER=64
	echo "WARNING: PowerGraph does not work with > 64 threads. Running on 64 threads."
else
    export GRAPHLAB_THREADS_PER_WORKER=$OMP_NUM_THREADS
fi
for ROOT in $(head -n $NRT "$DDIR/$d/${d}-roots.v"); do
	"$POWERGRAPHDIR/release/toolkits/graph_analytics/sssp" --graph "$DDIR/$d/${d}.wel" --format tsv --source $ROOT
done

# PageRank Note: ROOT is a dummy variable to ensure the same # of trials
# Run GAP PageRank
# error = sum(|newPR - oldPR|)
for ROOT in $(head -n $NRT "$DDIR/$d/${d}-roots.v"); do
	"$GAPDIR"/pr -f "$DDIR/$d/${d}.wel" -i $MAXITER -t $TOL -n 1
done

# Run GraphBIG PageRank
# The original GraphBIG has --quad = sqrt(sum((newPR - oldPR)^2))
# GraphBIG error has been modified to now be sum(|newPR - oldPR|)
for ROOT in $(head -n $NRT "$DDIR/$d/${d}-roots.v"); do
	"$GRAPHBIGDIR/benchmark/bench_pageRank/pagerank" --dataset "$DDIR/$d" --maxiter $MAXITER --quad $TOL --threadnum $OMP_NUM_THREADS
done

echo Finished experiment at $(date)

