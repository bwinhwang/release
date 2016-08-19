#!/bin/bash
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     04-Jan-2013
#
# Description:
#           Automatic Update of GLOBAL_ENV_x in ECL_BASE
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
   echo -e "\t${PROG} - "Automatic Update of GLOBAL_ENV_x in ECL_BASE
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -b <Branch> -g <global_env family> [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to update GLOBAL_ENV in the file ECL_BASE if a new GLOBAL_ENV has been checked in."
   echo ""
   echo -e "\t-b  name of branch"
   echo -e "\t-g  name of global env family"
   echo -e "\t-h  print this help and exit"
   echo ""
   echo "EXAMPLES"
   echo -e "\t${PROG} -b MAINBRANCH -g GLOBAL_ENV_6" 
   echo ""
   exit 0
}

# Source environment
function source_env()
{
  WORKAREA=`dirname ${0}`/..
  cd ${WORKAREA}
  WORKAREA=`pwd`
  cd -

  ENV=${WORKAREA}/etc/env
  [ -r "${ENV}" ] ||  fatal "${PROG}: Unable to source ${ENV} - bailing out!"
  source ${ENV}

  FCT=${WORKAREA}/bin/ps_functions.sh
  [ -r "${FCT}" ] ||  fatal "${PROG}: Unable to source ${FCT} - bailing out!"
  source ${FCT}
}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   while getopts :b:g:h OPTION; 
   do
      case ${OPTION} in
         b) BRANCH=${OPTARG};;
         g) GLOB_ENV_FAM=${OPTARG};;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done
   [ -z "${BRANCH}" ] && fatal "Parameter '-b' not defined"
   [ -z "${GLOB_ENV_FAM}" ] && fatal "Parameter '-g' not defined"
   log "INPUT BRANCH      : ${BRANCH}"
   log "INPUT GLOB_ENV_FAM: ${GLOB_ENV_FAM}"
}

# search in svn repo BTS_I_GLOBAL for latest version of GLOBAL_ENV-family
find_new_globenv()
{
   SEPARATOR="_"
   [[ "${GLOB_ENV_FAM}" =~ ".*_.*_.*_.*" ]] && SEPARATOR="-"
   GLOB_ENV_NUM=`${SVN} ls ${SNVGLOBAL}/tags |grep -v "\-[5-9][0-9]" |grep "${GLOB_ENV_FAM}[^0-9]" |sed "s|${GLOB_ENV_FAM}||;s|^[_-]||;s|/$||" |sort -n |tail -1`
   if [[ "${GLOB_ENV_NUM}" =~ "-" ]]; then
      GLOB_ENV_NUM=`echo -e "${GLOB_ENV_NUM}" | sed -e "s|-.*$||"`
      GLOB_ENV_FAM="${GLOB_ENV_FAM}_${GLOB_ENV_NUM}"
      SEPARATOR="-"
      GLOB_ENV_NUM=`${SVN} ls ${SNVGLOBAL}/tags |grep -v "\-[5-9][0-9]" | grep "${GLOB_ENV_FAM}" |sed "s|${GLOB_ENV_FAM}||;s|^[_-]||;s|/$||" |sort -n |tail -1`
   fi
   [[ -z "${GLOB_ENV_NUM}" ]] && SEPARATOR=""
   GLOB_ENV_NEW="${GLOB_ENV_FAM}${SEPARATOR}${GLOB_ENV_NUM}"
   log "GLOB_ENV_NEW(BTS_I_GLOBAL) : ${GLOB_ENV_NEW}"
   ${SVN} ls ${SNVGLOBAL}/tags/${GLOB_ENV_NEW} 1>/dev/null 2>/dev/null || fatal "${GLOB_ENV_NEW} does not exist"
}

# find in svn repo BTS_SCM_PS/ECL the current version of GLOBAL_ENV
find_curr_globenv()
{
   GLOB_ENV_CURRENT=`${SVN} cat ${SVNPS}/ECL/${BRANCH}/ECL_BASE/ECL | grep "ECL_GLOBAL_ENV=" | sed -e "s|ECL_GLOBAL_ENV=||"`
   log "GLOB_ENV_CURRENT(${BRANCH}): ${GLOB_ENV_CURRENT}"
}

# compare versions
compare_versions_globenv()
{
   if [[ "${GLOB_ENV_NEW}" != "${GLOB_ENV_CURRENT}" ]]; then
      log "UPDATING ECL FILE"
      rm -rf ECL_BASE
      ${SVN} co ${SVNPS}/ECL/${BRANCH}/ECL_BASE || fatal "${SVN} co ${SVNPS}/ECL/${BRANCH}/ECL_BASE failed"
      sed -i "s|ECL_GLOBAL_ENV=.*|ECL_GLOBAL_ENV=${GLOB_ENV_NEW}|" ECL_BASE/ECL
      ${SVN} ci ECL_BASE -m "ECL updated"
      log "ECL FILE UPDATED"
   else
      log "VERSIONS IDENTICAL, NO UPDATE"
   fi
}

##################################################
# MAIN
##################################################

echo ""
echo "##########################################"
echo " ${PROG}: `${DATE_NOW}` - `${TIME_NOW}` `${TIMEZONE}`"
echo "##########################################"

source_env
local_process_cmd_line $@
find_new_globenv
find_curr_globenv
compare_versions_globenv
log "FINISHED"
echo ""
exit 0

##################################################
# EOF
##################################################

