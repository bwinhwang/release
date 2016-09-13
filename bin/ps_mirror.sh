#!/bin/bash
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     12-Feb-2015
#
# Description:
#           merge a platform branch to another one
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
   echo -e "\t${PROG} - Merge a Platform branch to another one"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -b <base branch> -m <new branch> -c <revision ci2rm> [-th]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to generate a mirror of a platform branch usable for specific tests"
   echo ""
   echo -e "\t-b  name of the release on which the new branch is based on"
   echo -e "\t-m  name of the mirror branch"
   echo -e "\t-c  path/revision of CI2RM-file"
   echo -e "\t-t  run in test mode without svn commits"
   echo -e "\t-h  print this help and exit"
   echo ""
   echo "EXAMPLES"
   echo -e "\t${PROG} -b MAINBRANCH -m MAINBRANCH_GCC -c https://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH/CI2RM@52057"
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
         c) CI2RM=${OPTARG};;
         t) TEST=echo;;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done

   [ -z "${BASEBRANCH}" ] && fatal "Parameter '-b' not defined"
   [ -z "${MIRROR}" ] && fatal "Parameter 'm' not defined"
   [ -z "${CI2RM}" ] && fatal "Parameter 'c' not defined"
   [ "${TEST}" ] && log "TEST MODE - no svn commits"

   log "${BASEBRANCH}"
   log "${MIRROR}"
   log "${CI2RM}"
}

function prepare_working_copy ()
{
   log "STARTED"
   log "working copy: ${RELEASEDIR}/${MIRROR}"

   ${SVN} ls ${RELEASEDIR}/${MIRROR}/ENV 1>/dev/null 2>/dev/null || 
      ${TEST} ${SVN} co ${SVNENV}/${MIRROR}/trunk ${RELEASEDIR}/${MIRROR}/ENV || fatal "svn co ${SVNENV}/${MIRROR}/trunk failed"

   ${SVN} ls ${RELEASEDIR}/${MIRROR}/CCS 1>/dev/null 2>/dev/null ||
      ${TEST} ${SVN} co ${SVNCCS}/${MIRROR}/trunk ${RELEASEDIR}/${MIRROR}/CCS || fatal "svn co ${SVNCCS}/${MIRROR}/trunk failed"

   ${SVN} ls ${RELEASEDIR}/${MIRROR}/MCU 1>/dev/null 2>/dev/null || 
      ${TEST} ${SVN} co ${SVNMCU}/${MIRROR}/trunk ${RELEASEDIR}/${MIRROR}/MCU || fatal "svn co ${SVNMCU}/${MIRROR}/trunk failed"

   ${SVN} ls ${RELEASEDIR}/${MIRROR}/DSP 1>/dev/null 2>/dev/null || 
      ${TEST} ${SVN} co ${SVNDSP}/${MIRROR}/trunk ${RELEASEDIR}/${MIRROR}/DSP || fatal "svn co ${SVNDSP}/${MIRROR}/trunk failed"

   log "DONE"
}

function find_revisions ()
{
   log "STARTED"

   local ECL_VER=`${SVN} cat ${CI2RM} |grep "CI2RM_ECL="` || fatal "svn cat ci2rm failed"
   ECL_VER=`echo "${ECL_VER}" |sed "s/.*=//"` 
   log "ECL=${SVNSERVER}${ECL_VER}"
   ECL_ENV=`${SVN} cat ${SVNSERVER}${ECL_VER} |grep ECL_PS_ENV= |sed "s/.*=//"` || fatal "svn cat ${SVNSERVER}${ECL_VER} failed"
   ECL_CCS=`${SVN} cat ${SVNSERVER}${ECL_VER} |grep ECL_CCS= |sed "s/.*=//"` || fatal "svn cat ${SVNSERVER}${ECL_VER} failed"
   ECL_MCU=`${SVN} cat ${SVNSERVER}${ECL_VER} |grep ECL_MCUHWAPI= |sed "s/.*=//"` || fatal "svn cat ${SVNSERVER}${ECL_VER} failed"
   ECL_DSP=`${SVN} cat ${SVNSERVER}${ECL_VER} |grep ECL_UPHWAPI= |sed "s/.*=//"` || fatal "svn cat ${SVNSERVER}${ECL_VER} failed"
   log "ECL_ENV=${ECL_ENV}"
   log "ECL_CCS=${ECL_CCS}"
   log "ECL_MCU=${ECL_MCU}"
   log "ECL_DSP=${ECL_DSP}"

   log "DONE"
}

function merge_components ()
{
   log "STARTED"

   ${SVN} update ${RELEASEDIR}/${MIRROR}/ENV || fatal "svn update ${RELEASEDIR}/${MIRROR}/ENV failed"
   ${SVN} merge --accept tf ${SVNSERVER}${ECL_ENV} ${RELEASEDIR}/${MIRROR}/ENV || fatal "svn merge ${SVNSERVER}${ECL_ENV} ${RELEASEDIR}/${MIRROR}/ENV failed"
   [[ `${SVN} status ${RELEASEDIR}/${MIRROR}/ENV |grep '^C '` ]] && fatal "svn merge ${SVNSERVER}${ECL_ENV} ${RELEASEDIR}/${MIRROR}/ENV conflict detected"

   ${SVN} update ${RELEASEDIR}/${MIRROR}/CCS || fatal "svn update ${RELEASEDIR}/${MIRROR}/CCS failed"
   ${SVN} merge --accept tf ${SVNSERVER}${ECL_CCS} ${RELEASEDIR}/${MIRROR}/CCS || fatal "svn merge ${SVNSERVER}${ECL_CCS} ${RELEASEDIR}/${MIRROR}/CCS failed"
   [[ `${SVN} status ${RELEASEDIR}/${MIRROR}/CCS |grep '^C '` ]] && fatal "svn merge ${SVNSERVER}${ECL_CCS} ${RELEASEDIR}/${MIRROR}/CCS conflict detected"

   ${SVN} update ${RELEASEDIR}/${MIRROR}/MCU || fatal "svn update ${RELEASEDIR}/${MIRROR}/MCU failed"
   ${SVN} merge --accept tf ${SVNSERVER}${ECL_MCU} ${RELEASEDIR}/${MIRROR}/MCU || fatal "svn merge ${SVNSERVER}${ECL_MCU} ${RELEASEDIR}/${MIRROR}/MCU failed"
   [[ `${SVN} status ${RELEASEDIR}/${MIRROR}/MCU |grep '^C '` ]] && fatal "svn merge ${SVNSERVER}${ECL_MCU} ${RELEASEDIR}/${MIRROR}/MCU conflict detected"
   ls $RELEASEDIR/${MIRROR}/MCU/ECL/ECL 1>/dev/null 2>/dev/null && svn revert $RELEASEDIR/${MIRROR}/MCU/ECL/ECL # do not change mcu-internal ECL-file

   ${SVN} update ${RELEASEDIR}/${MIRROR}/DSP || fatal "svn update ${RELEASEDIR}/${MIRROR}/DSP failed"
   ${SVN} merge --accept tf ${SVNSERVER}${ECL_DSP} ${RELEASEDIR}/${MIRROR}/DSP || fatal "svn merge ${SVNSERVER}${ECL_DSP} ${RELEASEDIR}/${MIRROR}/DSP failed"
   [[ `${SVN} status ${RELEASEDIR}/${MIRROR}/DSP |grep '^C '` ]] && fatal "svn merge ${SVNSERVER}${ECL_DSP} ${RELEASEDIR}/${MIRROR}/DSP conflict detected"
   ls $RELEASEDIR/${MIRROR}/DSP/ECL/ECL 1>/dev/null 2>/dev/null && svn revert $RELEASEDIR/${MIRROR}/DSP/ECL/ECL # do not change dsp-internal ECL-file

   log "DONE"
}

function commit_working_copy ()
{
   log "STARTED"

   local COMMENT=`echo "${CI2RM}" | sed -e "s|.*/||"`
   ${TEST} ${SVN} ci ${RELEASEDIR}/${MIRROR}/ENV -m "${COMMENT}" || fatal "svn ci ${RELEASEDIR}/${MIRROR}/ENV failed"
   ${TEST} ${SVN} ci ${RELEASEDIR}/${MIRROR}/CCS -m "${COMMENT}" || fatal "svn ci ${RELEASEDIR}/${MIRROR}/CCS failed"
   ${TEST} ${SVN} ci ${RELEASEDIR}/${MIRROR}/MCU -m "${COMMENT}" || fatal "svn ci ${RELEASEDIR}/${MIRROR}/MCU failed"
   ${TEST} ${SVN} ci ${RELEASEDIR}/${MIRROR}/DSP -m "${COMMENT}" || fatal "svn ci ${RELEASEDIR}/${MIRROR}/DSP failed"

   log "DONE"
}

function send_mail ()
{
   log "STARTED"

   TO="scm-ps-int@mlist.emea.nsn-intra.net"
   CC="scm-ps-prod@mlist.emea.nsn-intra.net"
   SUB="${MIRROR} has been updated from ${BASEBRANCH}"
   FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
   MSG="${MIRROR} has been updated from ${BASEBRANCH}: 

    ${CI2RM} 
    ${SVNSERVER}${ECL_ENV}
    ${SVNSERVER}${ECL_CCS}
    ${SVNSERVER}${ECL_MCU}
    ${SVNSERVER}${ECL_DSP}

Best regards
PS SCM

"
   ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"

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
find_revisions
merge_components
commit_working_copy
send_mail

echo "${PROG}: All Done `${TIME_NOW}` `${TIMEZONE}`"
echo ""
exit 0

##################################################
# EOF
##################################################
