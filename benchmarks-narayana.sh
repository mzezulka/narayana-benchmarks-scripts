#!/usr/bin/env bash
# This script is intended to be used as a main program
# for measuring overhead implied by integration of OpenTracing
# into the Narayana transaction manager.
# TODO: be a bit more chatty about what it does (also script flags?)
set -eu

PERF_SUITE_LOC=${HOME}"/git/narayana-performance/narayana/ArjunaCore/arjuna/target/benchmarks.jar"
PERF_SUITE_DUMP_LOC="/tmp/narayana-performance-tests-dump"

# this configuration string is used for the benchmark itself
# -f = how many number of forks will be run?
# -wi = number of warmup iterations for each benchmark
BENCHMARK_COMMON_CONFIG=" -f 4 -wi 10  "

# Narayana sources defitions
N_VANILLA=${HOME}"/git/narayana-vanilla"
N_TRACED=${HOME}"/git/narayana"
N_NOOP_TRACED=${HOME}"/git/narayana"
N_FILE_LOGGED=${HOME}"/git/narayana"

function prepareEnv {
    # create a folder into which all the perf test results will be dumped into
    printf ${YELLOW}"##### Preparing the environment #####\n"
    printf $COLOR_OFF
    
    rm -rf $PERF_SUITE_DUMP_LOC
    mkdir -p $PERF_SUITE_DUMP_LOC
    pushd ${HOME}"/git/narayana-performance/narayana"
    mvn clean install -DskipTests
    popd
}

function displayPerftestResults {
    echo 'Benchmarking done. Do you wish to see the results (you can view the results in a web browser)?'
    read a
    if [ ${a}"x" = "yx" ]
    then
        ./csv_to_graph.py ${PERF_SUITE_DUMP_LOC}/*.csv
    fi
}

# Run the whole shenanigan.
function run {
    prepareEnv    

    #Narayana which is cloned from the repo and is left untouched.
    runSuite "$N_VANILLA" "narayana-vanilla" 
    
    # Narayana which is patched with a series of logging statements
    # on the exact same places as tracing. The logger is set up so
    # that everything is written to a log file, no other log statements
    # are produced.
    runSuite "$N_FILE_LOGGED"  "narayana-file-logged" "file-log-benchmark"
    
    TRACING=jaeger
    runSuite "$N_TRACED" "narayana-traced-jaeger"
    unset TRACING

    # Narayana patched with tracing. No tracers are registered, so this
    # suite will show us how much overhead is caused just by introducing
    # the OpenTracing API (a no-op tracer is still registered)
    # TODO - this might include running several variants of tests
    # (various configurations and tracing implementations)
    runSuite "$N_NOOP_TRACED" "narayana-noop-traced"

    displayPerftestResults
}

# color definitions
COLOR_OFF='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

function printPerftestSuiteHeader {
    narayanaLoc=$1
    perftestSuiteName=$2
    printf ${YELLOW}"#####Test suite "${perftestSuiteName}" #####\n"
    printf "Location of Narayana sources: "${narayanaLoc}"\n"
    printf $COLOR_OFF
}

function printPerftestSuiteFooter {
    printf ${YELLOW}"###########\n"${COLOR_OFF}
}

function runSuite {
    loc=$1
    name=$2
    # which repository branch will we use? use the third optional argument if it's present
    if [ $# -eq 3 ] ; then branch=$3 ; else branch="master" ; fi
    printPerftestSuiteHeader "$loc" "$name"
    pushd $loc
    git checkout $branch
    mvn clean install -DskipTests
    pushd $PERF_SUITE_DUMP_LOC
    touch ${name}".csv"
    java -jar "$PERF_SUITE_LOC" -rff ${name}".csv" $BENCHMARK_COMMON_CONFIG
    popd
    popd
    printPerftestSuiteFooter
}

run
