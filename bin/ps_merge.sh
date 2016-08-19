#!/bin/bash
#
# Author:      Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:        01-Jun-2015
# Description: merge a platform component from one branch to another one
#
######################################################################################

PROG=`basename ${0}`
DATE_NOW="date +%Y/%m/%d"
TIME_NOW="date +%H:%M:%S"
TIMEZONE="date +%Z"

# signal handler for interrupts ...
trap 'echo ""; echo "${PROG}: ABORTED"; echo ""; exit 0' SIGHUP SIGINT SIGTERM

# Function: Usage
function local_usage()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG} - Merge a platform component from one branch to another one"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -b <base branch> -m <new branch> -c <repository of component> [-th]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to generate a mirror of a platform branch usable for specific tests"
   echo ""
   echo -e "\t-b  name of the branch on which the new branch is based"
   echo -e "\t-m  name of the mirror branch"
   echo -e "\t-c  name of the component to merge [ CCS | MCUHWAPI | DSPHWAPI | ENV | ECL]"
   echo -e "\t-t  run in test mode without execution of svn commands"
   echo -e "\t-h  print this help and exit"
   echo ""
   echo "EXAMPLES"
   echo -e "\t${PROG} -b MAINBRANCH -m MAINBRANCH_K314 -c CCS -t"
   echo ""
   exit 0
}

# Source environment
function sourceEnv()
{
  WORKAREA=`dirname ${0}`/..
  cd ${WORKAREA}
  WORKAREA=`pwd`
  cd -

  ENV=${WORKAREA}/etc/env
  [ -r "${ENV}" ] || ( echo "${PROG}: Unable to source ${ENV} - bailing out!"; exit 1 )
  source ${ENV}

  FCT=${WORKAREA}/bin/ps_functions.sh
  [ -r "${FCT}" ] || ( echo "${PROG}: Unable to source ${FCT} - bailing out!"; exit 1 )
  source ${FCT}

  sourceRest
}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   while getopts ":b:m:c:th" OPTION; 
   do
      case "${OPTION}" in
         b) BASEBRANCH=${OPTARG};;
         m) MIRROR=${OPTARG};;
         c) COMPONENT=${OPTARG};;
         t) TEST=echo;;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done

   [ -z "${BASEBRANCH}" ] && fatal "Parameter '-b' not defined"
   [ -z "${MIRROR}" ] && fatal "Parameter '-m' not defined"
   [ -z "${COMPONENT}" ] && fatal "Parameter '-c' not defined"
   [ "${TEST}" ] && log "T E S T   R U N  -  N O   S V N   C O M M I T S   W I L L   B E   E X E C U T E D !!!"

   if [[ "${COMPONENT}" == "CCS" || "${COMPONENT}" == "MCUHWAPI" || "${COMPONENT}" == "DSPHWAPI" ]]; then REPONAME=BTS_SC_${COMPONENT}
   elif [[ "${COMPONENT}" == "ENV" ]]; then REPONAME=BTS_I_PS
   elif [[ "${COMPONENT}" == "ECL" ]]; then REPONAME=BTS_SCM_PS
   else fatal "name of component '${COMPONENT}' not valid"
   fi

   log "BASEBRANCH: ${BASEBRANCH}"
   log "MIRROR    : ${MIRROR}"
   log "COMPONENT : ${COMPONENT}"
   log "REPONAME  : ${REPONAME}"

   WORKING_COPY=${RELEASEDIR}/${MIRROR}/${COMPONENT}

}

function prepare_working_copy ()
{
   log "STARTED"
   log "MIRROR URL  : ${SVNURL}/${REPONAME}/${MIRROR}/trunk"
   log "WORKING COPY: ${WORKING_COPY}"

   ${SVN} ls ${WORKING_COPY} 1>/dev/null 2>/dev/null ||
      ${TEST} ${SVN} co ${SVNURL}/${REPONAME}/${MIRROR}/trunk ${WORKING_COPY} || fatal "svn co failed"

   log "DONE"
}

function merge_component ()
{
   log "STARTED"

   log "svn update ${WORKING_COPY}"
   ${TEST} ${SVN} update ${WORKING_COPY} || fatal "svn update failed"

   log "svn merge ${SVNURL}/${REPONAME}/${BASEBRANCH}/trunk ${WORKING_COPY}"
   ${TEST} ${SVN} merge --accept tf ${SVNURL}/${REPONAME}/${BASEBRANCH}/trunk ${WORKING_COPY} || fatal "svn merge failed"
   [ -z "${TEST}" ] && [[ `${SVN} status ${WORKING_COPY} |grep '^C '` ]] && fatal "svn merge conflict detected"

   if [ -z "${TEST}" ]; then
      log "revert internal ECL"
      ${SVN} ls ${SVNURL}/${REPONAME}/${MIRROR}/trunk/ECL/ECL && ${SVN} cat ${SVNURL}/${REPONAME}/${MIRROR}/trunk/ECL/ECL > ${WORKING_COPY}/ECL/ECL
   fi

   log "DONE"
}

function commit_working_copy ()
{
   log "STARTED"

   local COMMENT="automatic update"
   log "svn ci ${WORKING_COPY} -m ${COMMENT}"
   ${TEST} ${SVN} ci ${WORKING_COPY} -m "${COMMENT}" || fatal "svn ci ${WORKING_COPY} failed"

   log "DONE"
}

##################################################
# MAIN
##################################################

echo ""
echo "##########################################"
echo " ${PROG}: `${DATE_NOW}` - `${TIME_NOW}` `${TIMEZONE}`"
echo "##########################################"

set -o pipefail

sourceEnv
local_process_cmd_line "$@"

prepare_working_copy
merge_component
commit_working_copy

echo "${PROG}: All Done `${TIME_NOW}` `${TIMEZONE}`"
echo ""
exit 0

##################################################
# EOF
##################################################
