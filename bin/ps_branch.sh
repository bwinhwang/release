#!/bin/bash
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     17-Jan-2011
#
# Description:
#           branch from a ps_rel to a new branch
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
   echo -e "\t${PROG} - Preparation of new branch for platform production"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -r <base release> | -o <base branch> -b <new branch> [-t <branch time> -d <dummy release>] -w <WFTBranches> [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to create a new branch from an tagged PS_REL or from a branch at a certain time"
   echo ""
   echo -e "\t-r  name of the release on which the new branch is based on"
   echo -e "\t-b  name of the new branch which should be created"
   echo -e "\t-o  name of the base branch (only needed in case of branching at a time)"
   echo -e "\t-t  time (YY-MM-DD_HH:MM) at which the snapshot of base branch will be done (only needed in case of branching at a time)"
   echo -e "\t-d  name of dummy release which is created for CCS CI (only needed in case of branching from release)"
   echo -e "\t-w  name(s) of related branches which are used within workflow tool"
   echo -e "\t-h  print this help and exit"
   echo ""
   echo "EXAMPLES"
   echo -e "\t${PROG} -r PS_REL_2012_11_01 -b 20M2_11 -d PS_REL_20M2_11_00 -w WMP#FB#12.11" 
   echo -e "\t${PROG} -o MAINBRANCH -b 20M2_11 -t 2012-11-30_16:00 -w WMP#FB#12.11"
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
   while getopts ":r:b:o:t:d:w:h" OPTION; 
   do
      case "${OPTION}" in
         r) RELEASE=${OPTARG};;
         b) NEWBRANCH=${OPTARG};;
         o) BASEBRANCH=${OPTARG};;
         t) BRANCHTIME=${OPTARG};;
         d) DUMMYRELEASE=${OPTARG};;
         w) WFTBRANCHES="${OPTARG}";;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done

   [ -z "${RELEASE}" ] && [ -z "${BRANCHTIME}" ] && fatal "One of Parameter '-r' or '-t' must be defined"
   [ "${RELEASE}" ] && [ "${BRANCHTIME}" ] && fatal "Only one of Parameter '-r' or '-t' must be defined"
   [ "${BRANCHTIME}" ] && [ -z "${BASEBRANCH}" ] && fatal "If '-t' the parameter '-o' must be defined"
   [ "${RELEASE}" ] && [ -z "${DUMMYRELEASE}" ] && fatal "Parameter '-d' not defined"
   [ -z "${NEWBRANCH}" ] && fatal "Parameter '-b' not defined"

   if [ "${BRANCHTIME}" ]; then 
      [[ "${BRANCHTIME}" =~ "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}" ]] || fatal "input parameter -t has invalid format" 
      DATE=`date +"%Y-%m-%d_%H:%M"`
      while [[ "$DATE" < "$BRANCHTIME" ]]; do
         log "waiting for $BRANCHTIME"
         sleep 60
         DATE=`date +"%Y-%m-%d_%H:%M"`
      done
      [ "${BRANCHTIME}" ] && BRANCHTIME=`echo -e "{\"${BRANCHTIME}\"}" | sed 's/_/ /'`
   fi

   ROTOCI_VERSION=`${SVN} info ${WORKAREA} | grep ^URL | sed 's/.*\///'`
}

function printSource ()
{
  local BRANCH=$1
  local REPOS="BTS_I_PS BTS_SC_CCS BTS_SC_MCUHWAPI BTS_SC_DSPHWAPI"
  for REPO in $REPOS
  do
    local URL=https://svne1.access.nsn.com/isource/svnroot/$REPO
    local DEST=$URL/$BRANCH/trunk
    local PAT="^   A \/$BRANCH\/trunk (from "
    echo "$DEST 
(from $URL`svn log --stop-on-copy -v $DEST | grep "$PAT" | sed "s,$PAT\(.*\)$,\1," | sed 's,:,@,'`
"
  done
}

function createBranchFromTag ()
{
   local REPO=${1}
   local SRC=${2}
   log "REPO: ${REPO}"
   log "SRC: ${SRC}"
   ${TEST} ${SVN} rm ${REPO}/${NEWBRANCH} -m "${ROTOCI_VERSION}"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH} -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH} failed"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH}/tags -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH}/tags failed"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH}/branches -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH}/branches failed"
   ${TEST} ${SVN} cp ${SVNSERVER}${SRC} ${REPO}/${NEWBRANCH}/trunk -m "${ROTOCI_VERSION}" || 
      fatal "svn cp ${SVNSERVER}${SRC} ${REPO}/${NEWBRANCH}/trunk failed"
}

function createBranchFromTime ()
{
   local REPO=${1}
   log "REPO: ${REPO}"
   log "BASEBRANCH: ${BASEBRANCH}"
   log "BRANCHTIME: ${BRANCHTIME}"

   ${SVN} ls ${REPO}/${BASEBRANCH}/trunk 1>/dev/null 2>/dev/null || fatal "${REPO}/${BASEBRANCH}/trunk does not exist in subversion";
   ${TEST} ${SVN} rm ${REPO}/${NEWBRANCH} -m "${ROTOCI_VERSION}"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH} -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH} failed"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH}/tags -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH}/tags failed"
   ${TEST} ${SVN} mkdir ${REPO}/${NEWBRANCH}/branches -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${REPO}/${NEWBRANCH}/branches failed"
   ${TEST} eval "${SVN} cp -r ${BRANCHTIME} ${REPO}/${BASEBRANCH}/trunk ${REPO}/${NEWBRANCH}/trunk -m \"${ROTOCI_VERSION}\"" || 
      fatal "svn cp -r ${BRANCHTIME} ${REPO}/${BASEBRANCH}/trunk ${REPO}/${NEWBRANCH}/trunk failed"
}

function createDummyRelease ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then
      findPsRelRepo ${RELEASE}
      ${SVN} ls ${PSRELREPO}/branches/${RELEASE} 1>/dev/null 2>/dev/null || fatal "${PSRELREPO}/branches/${RELEASE} does not exist"
      ${SVN} ls ${PSRELREPO}/tags/${DUMMYRELEASE} 1>/dev/null 2>/dev/null && fatal "${PSRELREPO}/tags/${DUMMYRELEASE} does already exist"
      ${TEST} ${SVN} cp ${PSRELREPO}/branches/${RELEASE} ${PSRELREPO}/tags/${DUMMYRELEASE} -m "${ROTOCI_VERSION}" --parents ||
         fatal "svn cp ${PSRELREPO}/branches/${RELEASE} ${PSRELREPO}/tags/${DUMMYRELEASE} failed"
      log "${PSRELREPO}/tags/${DUMMYRELEASE} created"
   fi
   log "DONE"
}

function find_baselines ()
{
   log "STARTED"
   findBranches
   local ECL_FILE=${RELEASEDIR}/${NEWBRANCH}/ECL
   local CI2RM_FILE=${RELEASEDIR}/${NEWBRANCH}/CI2RM 
   local CI2RM_FASTTRACK_FILE=${RELEASEDIR}/${NEWBRANCH}/CI2RM_FastTrack 
   mkdir -p ${RELEASEDIR}/${NEWBRANCH}
   if [ "${RELEASE}" ]; then
      findBaselines ${RELEASE}
      ${SVN} cat ${PSRELREPO}/branches/${RELEASE}/ECL > ${ECL_FILE} ||
         fatal "svn cat ${PSRELREPO}/branches/${RELEASE}/ECL > ${ECL_FILE} failed"
      ${SVN} cat ${PSRELREPO}/branches/${RELEASE}/CI2RM > ${CI2RM_FILE} ||
         fatal "svn cat ${PSRELREPO}/branches/${RELEASE}/CI2RM > ${CI2RM_FILE} failed"
      ${SVN} cat ${PSRELREPO}/branches/${RELEASE}/CI2RM > ${CI2RM_FASTTRACK_FILE} ||
         fatal "svn cat ${PSRELREPO}/branches/${RELEASE}/CI2RM > ${CI2RM_FASTTRACK_FILE} failed"
   else
      eval "${SVN} cat -r ${BRANCHTIME} ${SVNPS}/ECL/${BASEBRANCH}/ECL_BASE/ECL > ${ECL_FILE}" ||
         fatal "svn cat -r ${BRANCHTIME} ${SVNPS}/ECL/${BASEBRANCH}/ECL_BASE/ECL > ${ECL_FILE} failed"   
      eval "${SVN} cat -r ${BRANCHTIME} ${SVNPS}/CI2RM/${BASEBRANCH}/CI2RM > ${CI2RM_FILE}" ||
         fatal "svn cat -r ${BRANCHTIME} ${SVNPS}/CI2RM/${BASEBRANCH}/CI2RM > ${CI2RM_FILE} failed"   
      eval "${SVN} cat -r ${BRANCHTIME} ${SVNPS}/CI2RM/${BASEBRANCH}/CI2RM_FastTrack > ${CI2RM_FASTTRACK_FILE}" ||
         fatal "svn cat -r ${BRANCHTIME} ${SVNPS}/CI2RM/${BASEBRANCH}/CI2RM_FastTrack > ${CI2RM_FASTTRACK_FILE} failed"   
   fi
   source ${ECL_FILE}
   BASE_ENV=${ECL_PS_ENV}
   log "DONE"
}

function create_branch_env ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then 
      createBranchFromTag ${SVNENV} ${ECL_PS_ENV}
   else
      createBranchFromTime ${SVNENV}
   fi

   local REVISION=`${SVN} info ${SVNENV}/${NEWBRANCH}/trunk | grep "Last Changed Rev:" | sed 's/Last Changed Rev: //'` || fatal "svn info failed"
   ECL_PS_ENV=/isource/svnroot/BTS_I_PS/${NEWBRANCH}/trunk@${REVISION}
   log "DONE"
}

function create_branch_ccs ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then
      createBranchFromTag ${SVNCCS} ${ECL_CCS}
   else
      createBranchFromTime ${SVNCCS}
   fi
   log "DONE"
}

function create_branch_mcu ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then
      createBranchFromTag ${SVNMCU} ${ECL_MCUHWAPI}
   else
      createBranchFromTime ${SVNMCU}
   fi

   local SRC=${SVNMCU}/${NEWBRANCH}/trunk
   if [[ "`${SVN} pg svn:externals ${SRC} | wc -l`" != "0" ]]; then
      # only for old branches with externals
      local FILE=${RELEASEDIR}/${NEWBRANCH}/mcu_sw_externals.txt
      local DST=${RELEASEDIR}/${NEWBRANCH}/branch_mcu
  
      echo "/isource/svnroot/BTS_T_PS_TOOLS/StripWatcher/tags/0.6 PS_Tools/StripWatcher" > ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/common SwBuild/common" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/Definitions SwBuild/Definitions" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/doc SwBuild/doc" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/user SwBuild/user" >> ${FILE}
      echo "/isource/svnroot/BTS_E_OSE461/tags/${ECL_OSE_461}/OSE/OSE4.6.1 OSE/OSE4.6.1" >> ${FILE}
      echo "/isource/svnroot/BTS_E_OSE53/tags/${ECL_OSE_53}/E_External/OSE/OSE5.3 OSE/OSE5.3" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_I_GLOBAL/tags/${ECL_GLOBAL_ENV}/I_Interface/Global_Env I_Interface/Global_Env" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/Messages I_Interface/Platform_Env/Messages" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/Definitions I_Interface/Platform_Env/Definitions" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/CCS_ENV I_Interface/Platform_Env/CCS_ENV" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_COTS CCS_COTS" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_Daemon CCS_Daemon" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_Services CCS_Services" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_TestCases CCS_TestCases" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_Utils CCS_Utils" >> ${FILE}

      if [ "${RELEASE}" ] ; then 
         local REPO=`echo -e "${PSRELREPO}" | sed "s|https://svne1.access.nsn.com||"`
         echo "${REPO}/CCS/tags/${PS_CCS_BUILD}/C_Platform/CCS C_Platform/CCS" >> ${FILE}
      fi

      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_DSPHWAPI/${NEWBRANCH}/trunk/I_Interface/Platform_Env/DSPHWAPI_ENV I_Interface/Platform_Env/DSPHWAPI_ENV" >> ${FILE}
 
      ${SVN} co --non-recursive ${SRC} ${DST} || fatal "svn co ${SRC} ${DST} failed"
      ${SVN} propset svn:externals ${DST} -F ${FILE} || fatal "set properties 'svn:externals' failed for ${DST}"
      ${TEST} ${SVN} ci -m "${ROTOCI_VERSION}" ${DST} || fatal "svn ci ${DST} failed"
   fi
   log "DONE"
}

function create_branch_dsp ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then
      createBranchFromTag ${SVNDSP} ${ECL_DSPHWAPI}
   else
      createBranchFromTime ${SVNDSP}
   fi

   local SRC=${SVNDSP}/${NEWBRANCH}/trunk
   if [[ "`${SVN} pg svn:externals ${SRC} | wc -l`" != "0" ]]; then
      # only for old branches with externals
      local FILE=${RELEASEDIR}/${NEWBRANCH}/dsp_sw_externals.txt
      local DST=${RELEASEDIR}/${NEWBRANCH}/branch_dsp
  
      echo "/isource/svnroot/BTS_T_PS_TOOLS/Tools/common/pyparsing-1.5.5 Tools/common/pyparsing-1.5.5" > ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/common SwBuild/common" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/Definitions SwBuild/Definitions" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/doc SwBuild/doc" >> ${FILE}
      echo "/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}/SwBuild/user SwBuild/user" >> ${FILE}
      echo "/isource/svnroot/BTS_T_BGT/tags/${ECL_DSP_BGT}/Tools/DspHwapiPacketingTools Tools/DspHwapiPacketingTools" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_FSPB}/ccs_faraday/C6000/cgtools ccs_faraday/C6000/cgtools" >> ${FILE}
      echo "/isource/svnroot/BTS_E_TI_CSL/tags/${ECL_TI_CSL_FSPB}/ccs_faraday/C6000/csl_faraday ccs_faraday/C6000/csl_faraday" >> ${FILE}
      echo "/isource/svnroot/BTS_E_TI_DCI/tags/${ECL_TI_DCI_FSPB}/ccs_faraday/C6000/dci ccs_faraday/C6000/dci" >> ${FILE}
      echo "/isource/svnroot/BTS_E_TI_AET/tags/${ECL_TI_AET_FSPB}/ccs_faraday/C6000/aet ccs_faraday/C6000/aet" >> ${FILE}
      echo "/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4}/ose4xx ose4xx" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_NYQUIST}/ccs_nyquist/C6000/cgtools ccs_nyquist/C6000/cgtools" >> ${FILE}
      echo "/isource/svnroot/BTS_E_TI_AET/tags/${ECL_TI_AET_NYQUIST}/ccs_nyquist/C6000/aet ccs_nyquist/C6000/aet" >> ${FILE}
      echo "/isource/svnroot/BTS_T_TI_NYQUIST_PDK/tags/${ECL_TI_NYQUIST_PDK}/T_Tools/ccs_nyquist/packages ccs_nyquist/packages" >> ${FILE}
      echo "/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4_1_NY}/ose41x_n ose41x_n" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_I_GLOBAL/tags/${ECL_GLOBAL_ENV}/I_Interface/Global_Env I_Interface/Global_Env" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/Messages I_Interface/Platform_Env/Messages" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/Definitions I_Interface/Platform_Env/Definitions" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/I_Interface/Platform_Env/CCS_ENV I_Interface/Platform_Env/CCS_ENV" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_COTS CCS_COTS" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_Daemon CCS_Daemon" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_Services CCS_Services" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEWBRANCH}/trunk/CCS_TestCases CCS_TestCases" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_MCUHWAPI/${NEWBRANCH}/trunk/HWR/Mit Tools/common/Mit" >> ${FILE}
   
      ${SVN} co --non-recursive ${SRC} ${DST} || fatal "svn co ${SRC} ${DST} failed"
      ${SVN} propset svn:externals ${DST} -F ${FILE} || fatal "set properties 'svn:externals' failed for ${DST}"
      ${TEST} ${SVN} ci -m "${ROTOCI_VERSION}" ${DST} || fatal "svn ci ${DST} failed"
   fi
   log "DONE"
}

function create_CI2RM ()
{
   log "STARTED"
   mkdir -p ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH}
   cp ${RELEASEDIR}/${NEWBRANCH}/CI2RM ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH}/CI2RM ||
      fatal "cp ${RELEASEDIR}/${NEWBRANCH}/CI2RM ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH}/CI2RM failed"
   cp ${RELEASEDIR}/${NEWBRANCH}/CI2RM_FastTrack ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH}/CI2RM_FastTrack ||
      fatal "cp ${RELEASEDIR}/${NEWBRANCH}/CI2RM_FastTrack ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH}/CI2RM_FastTrack failed"
   ${TEST} ${SVN} import ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH} ${SVNPS}/CI2RM/${NEWBRANCH} -m "${ROTOCI_VERSION}" ||
      fatal "import ${RELEASEDIR}/${NEWBRANCH}/ci2rm/${NEWBRANCH} to ${SVNPS}/CI2RM/${NEWBRANCH} failed"
   log "DONE"
}

function create_ECL ()
{
   log "STARTED"
   local FILE=${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_BASE/ECL
   mkdir -p ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_BASE
   [[ ${ECL_DSP_BGT} ]] && echo -e "ECL_DSP_BGT=${ECL_DSP_BGT}"                                                                > ${FILE}
   [[ ${ECL_SWBUILD} ]] && echo -e "ECL_SWBUILD=${ECL_SWBUILD}"                                                               >> ${FILE}
   [[ ${ECL_HDBDE} ]] && echo -e "ECL_HDBDE=${ECL_HDBDE}"                                                                     >> ${FILE}

   [[ ${ECL_OSE_53} ]] && echo -e "ECL_OSE_53=${ECL_OSE_53}"                                                                  >> ${FILE}
   [[ ${ECL_OSE_461} ]] && echo -e "ECL_OSE_461=${ECL_OSE_461}"                                                               >> ${FILE}
   [[ ${ECL_TI_CGT} ]] && echo -e "ECL_TI_CGT=${ECL_TI_CGT}"                                                                  >> ${FILE}
   [[ ${ECL_DSP_BGT} || ${ECL_SWBUILD} || ${ECL_OSE_53} || ${ECL_OSE_461} || ${ECL_TI_CGT} ]] && echo -e ""                   >> ${FILE}

   [[ ${ECL_TI_CGT_FSPB} ]] && echo -e "ECL_TI_CGT_FSPB=${ECL_TI_CGT_FSPB}"                                                   >> ${FILE}
   [[ ${ECL_TI_CSL_FSPB} ]] && echo -e "ECL_TI_CSL_FSPB=${ECL_TI_CSL_FSPB}"                                                   >> ${FILE}
   [[ ${ECL_TI_DCI_FSPB} ]] && echo -e "ECL_TI_DCI_FSPB=${ECL_TI_DCI_FSPB}"                                                   >> ${FILE}
   [[ ${ECL_TI_AET_FSPB} ]] && echo -e "ECL_TI_AET_FSPB=${ECL_TI_AET_FSPB}"                                                   >> ${FILE}
   [[ ${ECL_OSECK_4} ]] && echo -e "ECL_OSECK_4=${ECL_OSECK_4}"                                                               >> ${FILE}
   [[ ${ECL_TI_CGT_FSPB} || ${ECL_TI_CSL_FSPB} || ${ECL_TI_DCI_FSPB} || ${ECL_TI_AET_FSPB} || ${ECL_OSECK_4} ]] && echo -e "" >> ${FILE}

   [[ ${ECL_TI_CGT_NYQUIST} ]] && echo -e "ECL_TI_CGT_NYQUIST=${ECL_TI_CGT_NYQUIST}"                                          >> ${FILE}
   [[ ${ECL_TI_AET_NYQUIST} ]] && echo -e "ECL_TI_AET_NYQUIST=${ECL_TI_AET_NYQUIST}"                                          >> ${FILE}
   [[ ${ECL_TI_NYQUIST_PDK} ]] && echo -e "ECL_TI_NYQUIST_PDK=${ECL_TI_NYQUIST_PDK}"                                          >> ${FILE}
   [[ ${ECL_OSECK_4_1_NY} ]] && echo -e "ECL_OSECK_4_1_NY=${ECL_OSECK_4_1_NY}"                                                >> ${FILE}
   [[ ${ECL_TI_CGT_NYQUIST} || ${ECL_TI_AET_NYQUIST} || ${ECL_TI_NYQUIST_PDK} || ${ECL_OSECK_4_1_NY} ]] && echo -e ""         >> ${FILE}

   [[ ${ECL_TI_K2_MCSDK} ]] && echo -e "ECL_TI_K2_MCSDK=${ECL_TI_K2_MCSDK}"                                                   >> ${FILE}
   [[ ${ECL_TI_KEPLER_PDK} ]] && echo -e "ECL_TI_KEPLER_PDK=${ECL_TI_KEPLER_PDK}"                                             >> ${FILE}
   [[ ${ECL_OSECK_4_1_K2} ]] && echo -e "ECL_OSECK_4_1_K2=${ECL_OSECK_4_1_K2}"                                                >> ${FILE}
   [[ ${ECL_TI_K2_MCSDK} || ${ECL_TI_KEPLER_PDK} || ${ECL_OSECK_4_1_K2} ]] && echo -e ""                                      >> ${FILE}

   [[ ${ECL_PS_LFS_SDK1} ]] && echo -e "ECL_PS_LFS_SDK1=${ECL_PS_LFS_SDK1}"                                                   >> ${FILE}
   [[ ${ECL_PS_LFS_SDK2} ]] && echo -e "ECL_PS_LFS_SDK2=${ECL_PS_LFS_SDK2}"                                                   >> ${FILE}
   [[ ${ECL_PS_LFS_SDK3} ]] && echo -e "ECL_PS_LFS_SDK3=${ECL_PS_LFS_SDK3}"                                                   >> ${FILE}
   [[ ${ECL_PS_LFS_OS} ]] && echo -e "ECL_PS_LFS_OS=${ECL_PS_LFS_OS}"                                                         >> ${FILE}
   [[ ${ECL_PS_LFS_REL} ]] && echo -e "ECL_PS_LFS_REL=${ECL_PS_LFS_REL}"                                                      >> ${FILE}
   [[ ${ECL_LFS} ]] && echo -e "ECL_LFS=${ECL_LFS}"                                                                           >> ${FILE}
   [[ ${ECL_PS_LFS_SRC_REV} ]] && echo -e "ECL_PS_LFS_SRC_REV=${ECL_PS_LFS_SRC_REV}"                                          >> ${FILE}
   [[ ${ECL_PS_LFS_INTERFACE_REV} ]] && echo -e "ECL_PS_LFS_INTERFACE_REV=${ECL_PS_LFS_INTERFACE_REV}"                        >> ${FILE}
   [[ ${ECL_PS_PNS_LFS_REL} ]] && echo -e "ECL_PS_PNS_LFS_REL=${ECL_PS_PNS_LFS_REL}"                                          >> ${FILE}
   [[ ${ECL_PS_LFS_SDK_YOCTO} ]] && echo -e "ECL_PS_LFS_SDK_YOCTO=${ECL_PS_LFS_SDK_YOCTO}"                                    >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_OS} ]] && echo -e "ECL_PS_LRC_LFS_OS=${ECL_PS_LRC_LFS_OS}"                                             >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_REL} ]] && echo -e "ECL_PS_LRC_LFS_REL=${ECL_PS_LRC_LFS_REL}"                                          >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_OS} ]] && echo -e "ECL_PS_LRC_LCP_LFS_OS=${ECL_PS_LRC_LCP_LFS_OS}"                                 >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && echo -e "ECL_PS_LRC_LCP_LFS_REL=${ECL_PS_LRC_LCP_LFS_REL}"                              >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_OS} ]] && echo -e "ECL_PS_LRC_LSP_LFS_OS=${ECL_PS_LRC_LSP_LFS_OS}"                                 >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && echo -e "ECL_PS_LRC_LSP_LFS_REL=${ECL_PS_LRC_LSP_LFS_REL}"                              >> ${FILE}
   [[ ${ECL_LRC_LFS} ]] && echo -e "ECL_LRC_LFS=${ECL_LRC_LFS}"                                                               >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_OS} ]] && echo -e "ECL_PS_FZM_LFS_OS=${ECL_PS_FZM_LFS_OS}"                                             >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_REL} ]] && echo -e "ECL_PS_FZM_LFS_REL=${ECL_PS_FZM_LFS_REL}"                                          >> ${FILE}
   echo -e ""                                                                                                                 >> ${FILE}

   echo -e "ECL_GLOBAL_ENV=${ECL_GLOBAL_ENV}"                                                                                 >> ${FILE}
   echo -e "ECL_PS_ENV=${ECL_PS_ENV}"                                                                                         >> ${FILE}
   echo -e ""                                                                                                                 >> ${FILE}
   mkdir -p ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_CCS
   touch ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_CCS/ECL
   mkdir -p ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_HWAPI
   touch ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH}/ECL_HWAPI/ECL
   ${TEST} ${SVN} import ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH} ${SVNPS}/ECL/${NEWBRANCH} -m "${ROTOCI_VERSION}" ||
      fatal "import ${RELEASEDIR}/${NEWBRANCH}/ecl/${NEWBRANCH} to ${SVNPS}/ECL/${NEWBRANCH} failed"
   log "DONE"
}

extend_map ()
{
   log "STARTED"
   if [ "${WFTBRANCHES}" ]; then
      echo "${NEWBRANCH}=${WFTBRANCHES}" >> ${ETCDIR}/map
   fi
   log "DONE"
}

function create_wft_branch ()
{
   log "STARTED"
   [ "${BASEBRANCH}" ] || BASEBRANCH=`echo "${BASE_ENV}" | sed "s|/isource/svnroot/BTS_I_PS/\([0-9A-Z_]*\)/.*|\1|"`
   log "BASEBRANCH=${BASEBRANCH}"
   local BRANCH_ID=`curl ${WFT_PORT}/PS/branches.xml?access_key=${WFT_KEY} |grep title=\"${BASEBRANCH}\"`
   if [ ! "${BRANCH_ID}" ]; then
      warn "BASEBRANCH ${BASEBRANCH} not found in WFT"
      warn "NEW BRANCH ${NEWBRANCH} not established in branch list of WFT" 
   else
      BRANCH_ID=`echo ${BRANCH_ID} | sed -e "s|^.*<branch id=\"\([0-9]*\)\".*$|\1|"`
      echo ""
      log "PARENT BRANCH = ${BASEBRANCH} (ID:${BRANCH_ID})"
      log "NEW BRANCH    = ${NEWBRANCH}"
      local CMD="curl ${WFT_PORT}/management/branches -X POST -F access_key=${WFT_KEY} -F branch[title]=${NEWBRANCH} -F branch[project_id]=27 -F branch[branch_type_id]=13 -F branch[visible]=1 -F branch[writable]=1 -F branch[parent_branch_id]=${BRANCH_ID}"
      log "CMD           = ${CMD}"
      local RET=`eval "${CMD}"`
      log "${RET}"
   fi
   log "DONE"
}

function calc_time () {
   local LOCAL_TIME=`echo "${1}" | sed 's/{//' | sed 's/}//' | sed 's/\"//g'`
   local SECONDS=`date -d "${LOCAL_TIME}" +%s`
   TIME_GER=`date -d @${SECONDS}`
   SECONDS=`expr ${SECONDS} + 3600`
   TIME_FIN=`date -d @${SECONDS}`
   TIME_FIN=`echo ${TIME_FIN} | sed 's/CET/EET/'| sed 's/CEST/EEST/'`
}

# send mail
function send_mail_branch ()
{
   log "STARTED"
   if [ "${RELEASE}" ]; then
      BASETEXT="release '${RELEASE}'"
   else
      calc_time "${BRANCHTIME}"
      BASETEXT="trunk '${BASEBRANCH}' at:
      ${TIME_GER}
      ${TIME_FIN}"
   fi
   SUB="new Branch ${NEWBRANCH} created"
   FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
   TO="scm-ps-int@mlist.emea.nsn-intra.net"
   CC="scm-ps-prod@mlist.emea.nsn-intra.net"
   MSG="Dear Colleagues,

new branches '${NEWBRANCH}' are created based on ${BASETEXT}

`printSource $NEWBRANCH`

ECL and CI2RM are located:
${SVNPS}/ECL/${NEWBRANCH}/ECL_BASE/ECL
${SVNPS}/ECL/${NEWBRANCH}/ECL_CCS/ECL
${SVNPS}/ECL/${NEWBRANCH}/ECL_HWAPI/ECL
${SVNPS}/CI2RM/${NEWBRANCH}/CI2RM
${SVNPS}/CI2RM/${NEWBRANCH}/CI2RM_FastTrack

Please set up the ci for this branch.

Best regards
PS SCM"

   ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"
   log "DONE"
}

##################################################
# MAIN
##################################################

START_TIME=`${TIME_NOW}`
echo ""
echo "##########################################"
echo " ${PROG}: `${DATE_NOW}` - `${TIME_NOW}` `${TIMEZONE}`"
echo "##########################################"

sourceEnv
local_process_cmd_line "$@"
createDummyRelease
find_baselines
create_branch_env
create_branch_ccs
create_branch_mcu
create_branch_dsp
create_CI2RM
create_ECL
extend_map
create_wft_branch
send_mail_branch

echo "${PROG}: All Done ${START_TIME} - `${TIME_NOW}` `${TIMEZONE}`"
echo ""
exit 0

##################################################
# EOF
##################################################
