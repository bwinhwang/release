#!/bin/bash

unset http_proxy ALL_PROXY ftp_proxy
declare -r USER='admin'
declare -r PASS='123456789'
declare -r URL='http://ullink22.emea.nsn-net.net:1080'

###########################################

function local_usage ()
{
   echo "Parameter invalid!"
   echo "Usage:  `basename $0` [branch ...]"
   echo "        e.g.: `basename $0` 20M2_88 FB1403"
   echo "aborted"
   exit 1
}

function fatal ()
{
   [ "$TERM" = "xterm" ] && tput bold
   echo "${PROG} [$$]: ### ERROR ### $1 - bailing out" 1>&2
   [ "$TERM" = "xterm" ] && tput sgr0
   echo "${PROG}: FAILED `date +%Y%m%d-%H:%M:%S`"
   exit 1
}

# Check Input (structure of branch name)
function check_branch () {
   local BRANCH
   [[ "${BRANCHES}" ]] || local_usage
   for BRANCH in ${BRANCHES}; do
#      [[ "${BRANCH}" =~ "^20[0-9A-Z][0-9]_[0-9]{2}.*$|^FB[0-9]{4}.*|^MD[0-9]{5}.*|LRC[0-9]{4}.*|FZM[0-9]{4}.*|TST_.*" ]] || fatal "branch name ${BRANCH} does not fit the naming rules"
      echo "##### branch to be removed: '${BRANCH}'"
   done
}

# Remove jobs
function remove_jobs () {
   local BRANCH
   local JOB
   local ALL_JOBS
   echo ""
   for BRANCH in ${BRANCHES}; do
      ALL_JOBS="${BRANCH}-6-PS_REL ${BRANCH}-5-PS_DSP ${BRANCH}-4-PS_MCU ${BRANCH}-3-PS_CCS ${BRANCH}-2-PS_ENV ${BRANCH}-1-PS_LFS ${BRANCH}-0-PS-CI-RM"
      for JOB in ${ALL_JOBS}; do 

         echo "disbale job : wget --auth-no-challenge --no-proxy --user=${USER} --password=${PASS} -O /dev/null ${URL}/job/${JOB}/disable --post-data=NIX"
         wget --auth-no-challenge --no-proxy --user=${USER} --password=${PASS} -O /dev/null ${URL}/job/${JOB}/disable --post-data="NIX"
         [ "$?" != "0" ] && fatal "wget ${JOB} failed"

         echo "remove job : wget --auth-no-challenge --no-proxy --user=${USER} --password=${PASS} -O /dev/null ${URL}/job/${JOB}/doDelete --post-data=NIX"
         wget --auth-no-challenge --no-proxy --user=${USER} --password=${PASS} -O /dev/null ${URL}/job/${JOB}/doDelete --post-data="NIX"
         [ "$?" != "0" ] && fatal "wget ${JOB} failed"

         echo "##### job deleted"
         echo ""
         echo ""
      done
      echo "##### jobs of ${BRANCH} removed ##############################################################################################################################"
      echo ""
   done
}

###########################################
# main function
###########################################

echo "##### remove branches started"
BRANCHES=
while [ $# -gt 0 ]; do                   
  BRANCHES="${BRANCHES} $1"
  shift
done

check_branch
remove_jobs
echo "##### remove branches done"
echo ""

###########################################
# eof
###########################################
