#!/usr/bin/env bash
# This script is intended to be used as a main program
# for measuring overhead implied by integration of OpenTracing
# into the Narayana transaction manager.
set -eux

# Narayana sources defitions
N_PATCHED=${HOME}"/git/narayana"

function prepareEnv {
    # create a folder into which all the perf test results will be dumped into
    printf ${YELLOW}"##### Preparing the environment #####\n"
    printf $COLOR_OFF
    pushd $N_PATCHED && git reset --hard && popd
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
    printf "Location of Narayana sources: '"${narayanaLoc}"'\n"
    printf $COLOR_OFF
}

function printPerftestSuiteFooter {
    printf ${YELLOW}"###########\n"${COLOR_OFF}
}

function buildNarayana {
    name=$1
    loc=$2
    printPerftestSuiteHeader "$loc" "$name"
    # if we are not on vanilla Narayana, we must get a fresh install of it from local sources
    if [ "x"$name != "xvanilla" ] ; then pushd $loc ; mvn clean install -DskipTests ; fi

    # next, compile JMH perf test suite jar with the most fresh version of Narayana
    pushd ${HOME}"/git/narayana-performance/narayana"
    # the default version of Narayana is equal to the version used in the traced version of Naryana
    # (see narayana/ArjunaCore perftest pom for the specific version)
    mvnProp=" "
    if [ "x"$name == "xvanilla" ] ; then mvnProp=" -Dorg.jboss.narayana.version=5.10.0.Final "; fi
    mvn clean install -DskipTests $mvnProp
    popd
    # we're finished with our build, let's clean up the repository for other runs
    if [ "x"$name != "xvanilla" ] ; then git reset --hard ; popd ; fi   
    printPerftestSuiteFooter
}

# Run the whole shenanigan.
function build {    
    prepareEnv    

    #Narayana which is cloned from the repo and is left untouched. The second argument will be ignored.
    buildNarayana "vanilla" " "
 
    # Narayana which is patched with a series of logging statements
    # on the exact same places as tracing. The logger is set up so
    # that everything is written to a log file, no other log statements
    # are produced.
    filtered=""
    pushd $N_PATCHED
    readarray -d '' filtered < <(find ${PWD}/Arjuna* -type f -name "*.java" -exec sh -c "grep -q tracing {} 2> /dev/null && echo {}" \;)
    popd
    cp BenchmarkLogger.java ${N_PATCHED}"/ArjunaCore/arjuna/classes/com/arjuna/ats/arjuna/logging/"
    java -jar transformer.jar $filtered
    buildNarayana "file-logged" "$N_PATCHED"

    buildNarayana "tracing-off" "$N_PATCHED"

    buildNarayana "jaeger" "$N_PATCHED"

    # Narayana patched with tracing. No tracers are registered, so this
    # suite will show us how much overhead is caused just by introducing
    # the OpenTracing API (a no-op tracer is still registered)
    buildNarayana "noop" "$N_PATCHED"
}

build
