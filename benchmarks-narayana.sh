#!/usr/bin/env bash
# This script is intended to be used as a main program
# for measuring overhead implied by integration of OpenTracing
# into the Narayana transaction manager.
set -eux

PERF_SUITE_LOC=${HOME}"/git/narayana-performance/narayana/ArjunaCore/arjuna/target/benchmarks.jar"
PERF_SUITE_DUMP_LOC="/tmp/narayana-performance-tests-dump"

# this configuration string is used for the benchmark itself
# for more info, see java -jar <benchmarks_file.jar> -h
# -f  = no. forks
# -wi = no. warmup iterations for each benchmark
# -i  = no. real measurement iterations
# -t  = no. threads to run with 
#
# the config below is the default one which is used
# if no config string is passed to the script
BENCHMARK_COMMON_CONFIG=" -r 20 -f 1 -wi 3 -i 5 "

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
}

function displayPerftestResults {
    echo 'Benchmarking done. Do you wish to see the results (you can view the results in a web browser)?'
    read a
    if [ ${a}"x" = "yx" ]
    then
        ./csv_to_graph.py ${PERF_SUITE_DUMP_LOC}/*.csv
    fi
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
    printPerftestSuiteHeader "$loc" "$name"
    pushd $loc
    mvn clean install -DskipTests
    # compile JMH perf test tool with the most fresh version of Narayana
    # present in the Maven repository
    pushd ${HOME}"/git/narayana-performance/narayana"
    mvn clean install -DskipTests
    popd
    
    pushd $PERF_SUITE_DUMP_LOC
    tArr="01 02 04 10 50"
    for tNo in $tArr ;
    do
        dump=${name}"-"${tNo}"threads.csv"
        config="${BENCHMARK_COMMON_CONFIG} -t ${tNo}"
        touch $dump
        sysProp=""
        # there will be probably more implementations tested in the very near future
        if [ "x"$name == "xjaeger" ] ; then sysProp=" -Dtracing="$name ; fi
        java -jar $sysProp "$PERF_SUITE_LOC" -rff "$dump" $config
    done
    popd
    popd
    printPerftestSuiteFooter
}

# Run the whole shenanigan.
function run {    
    prepareEnv    

    #Narayana which is cloned from the repo and is left untouched.
    #runSuite "$N_VANILLA" "vanilla" 
 
    # Narayana which is patched with a series of logging statements
    # on the exact same places as tracing. The logger is set up so
    # that everything is written to a log file, no other log statements
    # are produced.
    filtered=""
    pushd $N_FILE_LOGGED
    git reset --hard
    readarray -d '' filtered < <(find ${PWD}/Arjuna* -type f -name "*.java" -exec sh -c "grep -q tracing {} 2> /dev/null && echo {}" \;)
    popd
    cp BenchmarkLogger.java ${N_FILE_LOGGED}"/ArjunaCore/arjuna/classes/com/arjuna/ats/arjuna/logging/"
    java -jar transformer.jar $filtered
    runSuite "$N_FILE_LOGGED"  "file-logged"    

    runSuite "$N_TRACED" "jaeger"

    # Narayana patched with tracing. No tracers are registered, so this
    # suite will show us how much overhead is caused just by introducing
    # the OpenTracing API (a no-op tracer is still registered)
    # TODO - this might include running several variants of tests
    # (various configurations and tracing implementations)
    runSuite "$N_NOOP_TRACED" "noop"

    displayPerftestResults
}

run
