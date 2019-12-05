#!/usr/bin/env bash
# This script is intended to be used as a main program
# for measuring overhead implied by integration of OpenTracing
# into the Narayana transaction manager.
#
# quick comment for each of the Narayana versions being built (and consequently tested):
#
# vanilla     - upstream version (see pom.xml for the default version) left untouched
# file-logged - patched with a series of logging statements
#               at exactly same places where tracing statements are,
#               the only appender is a file appender
# noop        - Narayana patched with tracing but with only a default, so-called
#               no-op tracer registered; the purpose of this suite is to show
#               how much overhead is caused just by introducing the OpenTracing API
# tracing-off - we completely turn off tracing via if statements and a system property
#               pseudocode: if(!TRACING_ACTIVE) return; ...
# jaeger      - the real essence of this whole perf testing, Narayana with tracing
#               and a real tracer registered
#
# script dependencies : xmlstarlet (ugly, but still better than depending on sed magic :-) )

# set -eux

# Narayana sources defitions
N_PATCHED=${HOME}"/git/narayana"

function prepareEnv {
    printf ${YELLOW}"##### Preparing the environment #####\n"
    printf $COLOR_OFF
    pushd $N_PATCHED && git reset --hard && popd
    echo $PWD
    # the folder in which all compiled perf test suites will go to
    [ -d "suites" ] && [ `ls -1 suites | wc -l` -ge 1 ] && mkdir -p suites_old && mv suites/* suites_old/
    mkdir -p suites    
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
    perftestSuiteName=$1
    printf ${YELLOW}"#####Test suite "${perftestSuiteName}" #####\n"
    printf $COLOR_OFF
}

function printPerftestSuiteFooter {
    printf ${YELLOW}"###########\n"${COLOR_OFF}
}

function buildNarayana {
    name=$1
    printPerftestSuiteHeader "$name"
    # if we are not on vanilla Narayana, we must get a fresh install of it from local sources
    if [ "x"$name != "xvanilla" ]
    then
      pushd $N_PATCHED
      mvnVer="5.9.6.benchmark."${name}
      mvn versions:set -DgenerateBackupPoms=false -DprocessAllModules=true -DnewVersion=$mvnVer
      mvn clean install -DskipTests
    fi

    # next, compile JMH perf test suite jar with the most fresh version of Narayana
    pushd ${HOME}"/git/narayana-performance/narayana"
    git reset --hard
    if [ "x"$name == "xvanilla" ]
    then
      mvn clean install -DskipTests
    else
      mvnProp=" -Dorg.jboss.narayana.version=$mvnVer "
      pushd tools
      # test utils do not declare narayana-perf as their parent but
      # narayana-all, we need to manually edit the pom.xml
      xmlstarlet ed --inplace -N x="http://maven.apache.org/POM/4.0.0" --update '/x:project/x:parent/x:version' --value $mvnVer pom.xml
      popd
      mvn -e versions:set -DgenerateBackupPoms=false -DnewVersion=$mvnVer
      mvn clean install -DskipTests $mvnProp
    fi
    popd
    # we're finished with our build, let's clean up the repository for other runs
    if [ "x"$name != "xvanilla" ] ; then git reset --hard ; popd; fi   
    cp ${HOME}"/git/narayana-performance/narayana/ArjunaCore/arjuna/target/benchmarks.jar" suites/${name}".jar"
    printPerftestSuiteFooter
}

# Run the whole shenanigan.
function build {    
    prepareEnv    

    buildNarayana "vanilla"

    filtered=""
    readarray -d '' filtered < <(find ${N_PATCHED}/Arjuna* -type f -name "*.java" -exec sh -c "grep -q tracing {} 2> /dev/null && echo {}" \;)
    cp BenchmarkLogger.java ${N_PATCHED}"/ArjunaCore/arjuna/classes/com/arjuna/ats/arjuna/logging/"
    java -jar transformer.jar $filtered
    # note: the first suite built must be file-logged because we would otherwise lose all the transformations done above
    for regularPerfTest in file-logged tracing-off jaeger noop ; do buildNarayana "$regularPerfTest" ; done
    tree -D ~/.m2/repository/org/jboss/narayana/narayana-perf
}

# Check that all built jars have the proper Narayana version in them
function versionSanityCheck {
    for jf in `ls suites/*.jar`
    do
        jfNoExt=${jf%.jar}
        jfNoExt=${jfNoExt#"suites/"}
        rm -rf $jfNoExt
        unzip -q -d $jfNoExt $jf
        pushd $jfNoExt
        find META-INF/maven/org.jboss.narayana* -name "*pom.properties" -exec sh -c "grep -e version {} | grep -ve $jfNoExt && echo {}" \;
        popd
        rm -rf $jfNoExt
    done
}

build
versionSanityCheck
