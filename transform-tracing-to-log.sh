#!/usr/bin/env bash
set -eu

#NARAYANA_SRC_ROOT=$1

# regex: try(<STATEMENT>*Scope <VAR_NAME> = Tracing.activateSpan(<SPAN_NAME>);?)\s*{.*}\s*finally\s*{<STATEMENT>*<SPAN_NAME>.close()<STATEMENT>*}
#sources=($(grep -rlw -e "import io.narayana.tracing.Tracing;" ${NARAYANA_SRC_ROOT}))
#for i in "${!sources[@]}"
#do
#    echo ${sources[$i]}
#done

file="A.java"
# try(<RES_STATEMENT>*Span varName = Tracing.activateSpan(varName2)<RES_STATEMENT>*) {
#     <BODY>
# } catch (...) {
#    ...
# } ... {
# } finally {
#   <FIN_STATEMENT>*
#   varName2.finish();
#   <FIN_STATEMENT>*
# }
#
#        ||
#        ||
#        ||
#        \/
#
# try(<RES_STATEMENT>*) {
#     <BODY>
# } catch (...) {
#    ...
# } ... {
# } finally {
#   <FIN_STATEMENT>*
# }
#
# Note: RES_STATEMENT and FIN_STATEMENT will merge into one (because there will be no longer any Span statement to divide them)
#TRY_MULTI_RES='s/try \((.*)Span (.*) = Tracing.activateSpan(.*).*\) \{(.*)finally \{(.*)\}/try\($1 $2\) \{ $3 \{/smg;'
# try(Span varName = Tracing.activateSpan(varName2)) {
#     <BODY>
# } finally {
#     varName.finish();
# }
#
#        ||
#        ||
#        ||
#        \/
#
# <BODY>
TRY_ONE_RES='s/try \(\s*Span .* = Tracing.activateSpan\((.*)\)\s*\)\s*\{(.*)\}\s*finally\s*\{.*$1\.finish\(\).*\}/$2/smg;'
perl -p00e $TRY_ONE_RES A.java 
