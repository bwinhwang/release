#!/bin/bash
#
# Author:      Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:	       30-May-2012 
#
# Description: Collecting log information between two revisions.
#              Base is the file CI2RM.
#
#####################################################################################

PROG=`basename ${0}`

# signal handler for interrupts ...
trap 'echo ""; echo "${PROG}: ABORTED"; echo ""; exit 0' SIGHUP SIGINT SIGTERM

# Help
function local_usage ()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG}"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} [-u <promoted svn url> -p <ci2rm previous> -c <ci2rm release>] | [-1 <tag 1> -2 <tag 2>] [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is collect all completed changes."
   echo ""
   echo -e "\t-u  promoted svn url: path to current branch"
   echo -e "\t-p  previous ci2rm revision number"
   echo -e "\t-c  current ci2rm revision number"
   echo -e "\t-1  first PS_REL tag"
   echo -e "\t-2  second PS_REL tag"
   echo -e "\t-h  help text"
   echo ""
   echo "EXAMPLE"
   echo -e "\t${PROG} -u https://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH -p 4711 -c 4712"
   echo ""
   exit 0
}

# Source environment
function local_source_env()
{
   WORKAREA=`dirname ${0}`/..
   cd ${WORKAREA}
   WORKAREA=`pwd`
   cd -

   local ENV=${WORKAREA}/etc/env
   [ -r "${ENV}" ] ||  fatal "${PROG}: Unable to source ${ENV} - bailing out!"
   source ${ENV}

   local FCT=${WORKAREA}/bin/ps_functions.sh
   [ -r "${FCT}" ] ||  fatal "${PROG}: Unable to source ${FCT} - bailing out!"
   source ${FCT}

   sourceRest

}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   FAST=
   while getopts :u:p:c:1:2:fh OPTION; 
   do
      case ${OPTION} in
         u) SVN_URL=${OPTARG};;
         p) CI2RM_PREV=${OPTARG};;
         c) CI2RM_CURR=${OPTARG};;
         1) TAG1=${OPTARG};;
         2) TAG2=${OPTARG};;
         f) FAST=_FastTrack;;
         h) local_usage;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done

   MODE=
   [[ "${SVN_URL}" && "${CI2RM_PREV}" && "${CI2RM_CURR}" && -z "${TAG1}" && -z "${TAG2}" ]] && MODE=CI2RM && FCT_PTR="read_ecl_revisions"
   [[ -z "${SVN_URL}" && -z "${CI2RM_PREV}" && -z "${CI2RM_CURR}" && "${TAG1}" && "${TAG2}" ]] && MODE=TAG && FCT_PTR="read_ecl_from_tag"
   [ -z "${MODE}" ] && local_usage 
}

function read_ecl_revisions()
{
   log "STARTED"

   log "promoted URL  : ${SVN_URL}"
   BR=`echo "${SVN_URL}" | sed "s|.*/\([^/]*\)$|\1|"`
   log "Branch        : ${BR}"
   log "previous CI2RM: ${CI2RM_PREV}"
   log "current  CI2RM: ${CI2RM_CURR}"
   echo ""
   ECL_OLD=`${SVN} cat ${SVN_URL}/CI2RM${FAST}@${CI2RM_PREV} | grep CI2RM_ECL | sed "s/.*=//"` || fatal "svn cat failed"
   ECL_NEW=`${SVN} cat ${SVN_URL}/CI2RM${FAST}@${CI2RM_CURR} | grep CI2RM_ECL | sed "s/.*=//"` || fatal "svn cat failed"
   log "ECL_OLD = ${ECL_OLD}"
   log "ECL_NEW = ${ECL_NEW}"
   echo ""

   log "DONE"
}

function read_ecl_from_tag()
{
   log "STARTED"

   CI2RM_CURR=$$
   log "TAG1 ${TAG1}"
   log "TAG2 ${TAG2}"
   echo ""
   findPsRelRepo ${TAG1}
   ${SVN} ls ${PSRELREPO}/branches/${TAG1}/CI2RM || fatal "${PSRELREPO}/branches/${TAG1}/CI2RM does not exist, old fashioned PS_REL"
   ECL_OLD=`${SVN} cat ${PSRELREPO}/branches/${TAG1}/CI2RM | grep CI2RM_ECL | sed "s/.*=//"` || fatal "svn cat failed"
   findPsRelRepo ${TAG2}
   ${SVN} ls ${PSRELREPO}/branches/${TAG2}/CI2RM || fatal "${PSRELREPO}/branches/${TAG2}/CI2RM does not exist, old fashioned PS_REL"
   ECL_NEW=`${SVN} cat ${PSRELREPO}/branches/${TAG2}/CI2RM | grep CI2RM_ECL | sed "s/.*=//"` || fatal "svn cat failed"
   log "ECL_OLD = ${ECL_OLD}"
   log "ECL_NEW = ${ECL_NEW}"
   echo ""

   log "DONE"
}

function setRollback ()
{
   if [[ "${2}" -gt "${1}" ]] ; then
     ROLLBACK=
   else
      ROLLBACK="<b><FONT COLOR=\\\"red\\\"><--- rollback<\/FONT><\/b>"
   fi
}

function read_revisions()
{
   log "STARTED"

   ${SVN} cat ${SVNSERVER}${ECL_OLD} > ${TMPDIR}/ecl_old_$$ || fatal "svn cat ${ECL_OLD} to ${TMPDIR}/ecl_old_$$ failed"
   source ${TMPDIR}/ecl_old_$$
   rm ${TMPDIR}/ecl_old_$$
   ENV_OLD_REV=`echo ${ECL_PS_ENV} | sed "s/.*@//"`
   CCS_OLD_REV=`echo ${ECL_CCS} | sed "s/.*@//"`
   DSP_OLD_REV=`echo ${ECL_UPHWAPI} | sed "s/.*@//"`
   MCU_OLD_REV=`echo ${ECL_MCUHWAPI} | sed "s/.*@//"`
   LFS_OLD_VER=${ECL_PS_LFS_REL}
   [ ${ECL_PS_LRC_LSP_LFS_REL} ] && LRC_LSP_OLD_VER=${ECL_PS_LRC_LSP_LFS_REL}
   [ ${ECL_PS_LRC_LCP_LFS_REL} ] && LRC_LCP_OLD_VER=${ECL_PS_LRC_LCP_LFS_REL}
   [ ${ECL_PS_FZM_LFS_REL} ] && FZM_LFS_OLD_VER=${ECL_PS_FZM_LFS_REL}

   ${SVN} cat ${SVNSERVER}${ECL_NEW} > ${TMPDIR}/ecl_new_$$ || fatal "svn cat ${ECL_NEW} to ${TMPDIR}/ecl_new_$$ failed"
   source ${TMPDIR}/ecl_new_$$
   rm ${TMPDIR}/ecl_new_$$
   ENV_NEW_REV=`echo ${ECL_PS_ENV} | sed "s/.*@//"`
   CCS_NEW_REV=`echo ${ECL_CCS}  | sed "s/.*@//"`
   DSP_NEW_REV=`echo ${ECL_UPHWAPI} | sed "s/.*@//"`
   MCU_NEW_REV=`echo ${ECL_MCUHWAPI} | sed "s/.*@//"`
   LFS_NEW_VER=${ECL_PS_LFS_REL}
   [ ${ECL_PS_LRC_LSP_LFS_REL} ] && LRC_LSP_NEW_VER=${ECL_PS_LRC_LSP_LFS_REL}
   [ ${ECL_PS_LRC_LCP_LFS_REL} ] && LRC_LCP_NEW_VER=${ECL_PS_LRC_LCP_LFS_REL}
   [ ${ECL_PS_FZM_LFS_REL} ] && FZM_LFS_NEW_VER=${ECL_PS_FZM_LFS_REL}

   ENV_REPO=`echo ${ECL_PS_ENV} | sed "s/@.*$//"`
   CCS_REPO=`echo ${ECL_CCS} | sed "s/@.*$//"`
   DSP_REPO=`echo ${ECL_UPHWAPI} | sed "s/@.*$//"`
   MCU_REPO=`echo ${ECL_MCUHWAPI} | sed "s/@.*$//"`

   log "ENV_OLD_REV = ${ENV_OLD_REV}"
   log "ENV_NEW_REV = ${ENV_NEW_REV} (`${SVN} info ${SVNSERVER}/${ENV_REPO}@${ENV_NEW_REV} | grep 'Last Changed Date:'`)"
   log "CCS_OLD_REV = ${CCS_OLD_REV}"
   log "CCS_NEW_REV = ${CCS_NEW_REV} (`${SVN} info ${SVNSERVER}/${CCS_REPO}@${CCS_NEW_REV} | grep 'Last Changed Date:'`)"
   log "MCU_OLD_REV = ${MCU_OLD_REV}"
   log "MCU_NEW_REV = ${MCU_NEW_REV} (`${SVN} info ${SVNSERVER}/${MCU_REPO}@${MCU_NEW_REV} | grep 'Last Changed Date:'`)"
   log "DSP_OLD_REV = ${DSP_OLD_REV}"
   log "DSP_NEW_REV = ${DSP_NEW_REV} (`${SVN} info ${SVNSERVER}/${DSP_REPO}@${DSP_NEW_REV} | grep 'Last Changed Date:'`)"
   echo ""

   log "LFS_OLD_VER=${LFS_OLD_VER}"
   log "LFS_NEW_VER=${LFS_NEW_VER}"
   log "LRC_LSP_OLD_VER=${LRC_LSP_OLD_VER}"
   log "LRC_LSP_NEW_VER=${LRC_LSP_NEW_VER}" 
   log "LRC_LCP_OLD_VER=${LRC_LCP_OLD_VER}"
   log "LRC_LCP_NEW_VER=${LRC_LCP_NEW_VER}"
   log "FZM_LFS_OLD_VER=${FZM_LFS_OLD_VER}"
   log "FZM_LFS_NEW_VER=${FZM_LFS_NEW_VER}"
   echo ""

   log "ENV_REPO = ${ENV_REPO}"
   log "CCS_REPO = ${CCS_REPO}"
   log "DSP_REPO = ${DSP_REPO}"
   log "MCU_REPO = ${MCU_REPO}"
   echo ""

   log "DONE"
}

# get log information 
function get_log_info()
{
   log "STARTED"

   log "get log from env revision ${ENV_OLD_REV}-${ENV_NEW_REV}"
   [[ "${ENV_NEW_REV}" != "${ENV_OLD_REV}" ]] && ENV_COMMENTS=`${PARSE_SVNLOG} ${ENV_NEW_REV} $[ ++ENV_OLD_REV ] ${SVNSERVER}${ENV_REPO}`
   echo "${ENV_COMMENTS}" > ${TMPDIR}/env_${CI2RM_CURR}_${ENV_OLD_REV}-${ENV_NEW_REV}.txt
   log "RAW data PS_ENV:"
   cat ${TMPDIR}/env_${CI2RM_CURR}_${ENV_OLD_REV}-${ENV_NEW_REV}.txt
   echo "------------------------------------------------------------"
   echo ""

   log "get log from ccs revision ${CCS_OLD_REV}-${CCS_NEW_REV}"
   [[ "${CCS_NEW_REV}" != "${CCS_OLD_REV}" ]] && CCS_COMMENTS=`${PARSE_SVNLOG} ${CCS_NEW_REV} $[ ++CCS_OLD_REV ] ${SVNSERVER}${CCS_REPO}`
   echo "${CCS_COMMENTS}" > ${TMPDIR}/ccs_${CI2RM_CURR}_${CCS_OLD_REV}-${CCS_NEW_REV}.txt
   log "RAW data PS_CCS:"
   cat ${TMPDIR}/ccs_${CI2RM_CURR}_${CCS_OLD_REV}-${CCS_NEW_REV}.txt
   echo "------------------------------------------------------------"
   echo ""

   log "get log from mcu revision ${MCU_OLD_REV}-${MCU_NEW_REV}"
   [[ "${MCU_NEW_REV}" != "${MCU_OLD_REV}" ]] && MCU_COMMENTS=`${PARSE_SVNLOG} ${MCU_NEW_REV} $[ ++MCU_OLD_REV ] ${SVNSERVER}${MCU_REPO}`
   echo "${MCU_COMMENTS}" > ${TMPDIR}/mcu_${CI2RM_CURR}_${MCU_OLD_REV}-${MCU_NEW_REV}.txt
   log "RAW data PS_MCU:"
   cat ${TMPDIR}/mcu_${CI2RM_CURR}_${MCU_OLD_REV}-${MCU_NEW_REV}.txt
   echo "------------------------------------------------------------"
   echo ""

   log "get log from dsp revision ${DSP_OLD_REV}-${DSP_NEW_REV}"
   [[ "${DSP_NEW_REV}" != "${DSP_OLD_REV}" ]] && DSP_COMMENTS=`${PARSE_SVNLOG} ${DSP_NEW_REV} $[ ++DSP_OLD_REV ] ${SVNSERVER}${DSP_REPO}`
   echo "${DSP_COMMENTS}" > ${TMPDIR}/dsp_${CI2RM_CURR}_${DSP_OLD_REV}-${DSP_NEW_REV}.txt
   log "RAW data PS_DSP:"
   cat ${TMPDIR}/dsp_${CI2RM_CURR}_${DSP_OLD_REV}-${DSP_NEW_REV}.txt
   echo "------------------------------------------------------------"
   echo ""

   # in case of Interface Change write information to jenkins build description
   local TXT="/trunk/I_Interface/Platform_Env/"
   [[ "${ENV_COMMENTS}" =~ "${TXT}" ||
      "${CCS_COMMENTS}" =~ "${TXT}" ||
      "${MCU_COMMENTS}" =~ "${TXT}" ||
      "${DSP_COMMENTS}" =~ "${TXT}" ]] && echo "SCMPRELOGOUT:<b><FONT COLOR=\"red\">Interface changed</FONT></b>"

   log "DONE"
}

# select and echoes all PRONTOS (param1=COMMENTS, param2=SC)  
function pr_selection ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   PRToXml "${1}"
   for line in "${ADD[@]}"; do
      echo -e "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:PR \1 ${ROLLBACK}/"
   done
   for line in "${SUB[@]}"; do
      echo "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:PR \1 ROLLBACK/"
   done
}

#---------------------------------------------------------------------------------------------------------------

# select and echoes all NEW FEATURES (param1=COMMENTS, param2=SC)  
function nf_selection ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   NFToXml "${1}"
   for line in "${ADD[@]}"; do
      echo "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:NF \1 ${ROLLBACK}/"
   done
   for line in "${SUB[@]}"; do
      echo "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:NF \1 ROLLBACK/"
   done
}

#---------------------------------------------------------------------------------------------------------------

# select and echoes all CHANGES (param1=COMMENTS, param2=SC)  
function cn_selection ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   CNToXml "${1}"
   for line in "${ADD[@]}"; do
      echo "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:CN \1 ${ROLLBACK}/"
   done
   for line in "${SUB[@]}"; do
      echo "${line}" | sed "s/^ *<[^>]*id=\"\([^\"]*\)\".*/SCMPRELOGOUT:${2}:CN \1 ROLLBACK/"
   done
}

# filter the log information
function filter_log_info ()
{ 
   log "STARTED"

   if [[ "${LFS_OLD_VER}" != "${LFS_NEW_VER}" ]] ; then
      echo "SCMPRELOGOUT:${LFS_NEW_VER}"
   fi
   if [[ "${LRC_LCP_OLD_VER}" != "${LRC_LCP_NEW_VER}" ]] ; then
      echo "SCMPRELOGOUT:${LRC_LCP_NEW_VER}"
   fi
   if [[ "${LRC_LSP_OLD_VER}" != "${LRC_LSP_NEW_VER}" ]] ; then
      echo "SCMPRELOGOUT:${LRC_LSP_NEW_VER}"
   fi
   if [[ "${FZM_LFS_OLD_VER}" != "${FZM_LFS_NEW_VER}" ]] ; then
      echo "SCMPRELOGOUT:${FZM_LFS_NEW_VER}"
   fi

   setRollback ${ENV_OLD_REV} ${ENV_NEW_REV}
   ENV_PR=$(pr_selection "${ENV_COMMENTS}" "ENV")
   setRollback ${CCS_OLD_REV} ${CCS_NEW_REV}
   CCS_PR=$(pr_selection "${CCS_COMMENTS}" "CCS")
   setRollback ${MCU_OLD_REV} ${MCU_NEW_REV}
   MCU_PR=$(pr_selection "${MCU_COMMENTS}" "MCU")
   setRollback ${DSP_OLD_REV} ${DSP_NEW_REV}
   DSP_PR=$(pr_selection "${DSP_COMMENTS}" "DSP")
   PRONTOS=`echo -e "${ENV_PR}\n${CCS_PR}\n${MCU_PR}\n${DSP_PR}"`
   echo "${PRONTOS}" |sort -u

   setRollback ${ENV_OLD_REV} ${ENV_NEW_REV}
   ENV_NF=$(nf_selection "${ENV_COMMENTS}" "ENV")
   setRollback ${CCS_OLD_REV} ${CCS_NEW_REV}
   CCS_NF=$(nf_selection "${CCS_COMMENTS}" "CCS")
   setRollback ${MCU_OLD_REV} ${MCU_NEW_REV}
   MCU_NF=$(nf_selection "${MCU_COMMENTS}" "MCU")
   setRollback ${DSP_OLD_REV} ${DSP_NEW_REV}
   DSP_NF=$(nf_selection "${DSP_COMMENTS}" "DSP")
   FEATURES=`echo -e "${ENV_NF}\n${CCS_NF}\n${MCU_NF}\n${DSP_NF}"`
   echo "${FEATURES}" |sort -u

   setRollback ${ENV_OLD_REV} ${ENV_NEW_REV}
   ENV_CN=$(cn_selection "${ENV_COMMENTS}" "ENV")
   setRollback ${CCS_OLD_REV} ${CCS_NEW_REV}
   CCS_CN=$(cn_selection "${CCS_COMMENTS}" "CCS")
   setRollback ${MCU_OLD_REV} ${MCU_NEW_REV}
   MCU_CN=$(cn_selection "${MCU_COMMENTS}" "MCU")
   setRollback ${DSP_OLD_REV} ${DSP_NEW_REV}
   DSP_CN=$(cn_selection "${DSP_COMMENTS}" "DSP")
   CHANGES=`echo -e "${ENV_CN}\n${CCS_CN}\n${MCU_CN}\n${DSP_CN}"`
   echo "${CHANGES}" |sort -u

   log "DONE"
} 

# completion script execution
function local_completed()
{
   echo "${PROG}: STARTED: ALL DONE (`date +%H:%M:%S`)"
   exit 0
}

# Functions to be executed
function call_function ()
{
   case "$1" in
      read_ecl_revisions ) read_ecl_revisions; FCT_PTR="read_revisions";;
      read_ecl_from_tag )  read_ecl_from_tag;  FCT_PTR="read_revisions";;
      read_revisions )     read_revisions;     FCT_PTR="get_log_info";;
      get_log_info )       get_log_info;       FCT_PTR="filter_log_info";;
      filter_log_info )    filter_log_info;    FCT_PTR="local_completed";;
      local_completed)     local_completed;    FCT_PTR="END";;
      *)                   fatal "No correct entry point defined"
   esac
}

################################################################################################
# MAIN
################################################################################################

PROG=`basename $0`
echo "${PROG}: main: STARTED (`date +%d-%B-%Y\ %H:%M:%S`)"
trap 'echo "${PROG}: interrupt signal - bailing out"; exit 0' 1 2 15   # sig handler for interrupts ...
echo "LINSEE_VERSION=${LINSEE_VERSION}"
unset http_proxy ALL_PROXY ftp_proxy      # reset proxies for using wft

local_source_env
local_process_cmd_line $@

# call functions
while [ $FCT_PTR != "END" ]; do
   call_function $FCT_PTR
done
exit 0

#########################################################################
# eof
#########################################################################
