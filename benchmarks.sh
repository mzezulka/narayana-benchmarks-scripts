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
#BENCHMARK_COMMON_CONFIG=" -f 1 -wi 1 -i 1"
BENCHMARK_COMMON_CONFIG=" -r 20 -f 1 -wi 5 -i 5 "

function prepareEnv {
    # create a folder into which all the perf test results will be dumped into
    printf ${YELLOW}"##### Preparing the environment #####\n"
    printf $COLOR_OFF
    
    rm -rf $PERF_SUITE_DUMP_LOC
    mkdir -p $PERF_SUITE_DUMP_LOC
}

function displayPerftestResults {
    echo 'Benchmarking done. Do you wish to see the results (new tab will be opened in a web browser)?'
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
    name=$1
    printf ${YELLOW}"#####Test suite "${name}" #####\n"
    printf $COLOR_OFF
}

function printPerftestSuiteFooter {
    printf ${YELLOW}"###########\n"${COLOR_OFF}
}

function runSuite {
    name=$1
    # cut off "suites/" prefix from the name
    nameWithExtension="${name##suites/}"
    # get rid of .jar filename extension
    name="${nameWithExtension%.*}"
    # make a second copy which won't be touched
    # we still need to know the actual path to the jar
    # to run the benchmark
    fullName=$1

    printPerftestSuiteHeader "$name"
    pushd $PERF_SUITE_DUMP_LOC
    tArr="01 02 04 08 16 32 64"
    for tNo in $tArr ;
    do
        dump=${name}"-"${tNo}"threads.csv"
        config="${BENCHMARK_COMMON_CONFIG} -t ${tNo}"
        touch $dump
        sysProp=" "
        # there will be probably more implementations tested in the very near future
        if [ "x"$name == "xjaeger" ] ; then sysProp=" -Dtracing="$name ; fi
        if [ "x"$name == "xtracing-off" ] ; then sysProp=" -Dorg.jboss.narayana.tracingActivated=false "; fi
        java -jar $sysProp "$fullName" -rff "$dump" $config
    done
    popd
    printPerftestSuiteFooter
}

function run {    
    prepareEnv    

    for suite in suites/*.jar
    do
      runSuite $suite
    done
        displayPerftestResults
}

run
