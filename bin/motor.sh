#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           Build the Platform ENV Release
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
#
###################################################################################################

PROG=`basename ${0}`

# signal handler for interrupts ...
trap 'echo ""; echo "${PROG}: ABORTED"; echo ""; exit 0' SIGHUP SIGINT SIGTERM

# Help
function local_usage()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG}"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -b <Base PS_REL> [-l <LFS PS_REL>] [-c <CCS PS_REL>] [-m <MCU PS_REL>] [-d <DSP PS_REL>] [-th]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tMOTOR: Mixing On Top Of Release"
   echo -e "\tThe purpose of this script is to patch an existing PS Release with the components of other PS Releases"
   echo -e "\tIt combines the PS Environment to a new one (if needed) and creates a new PS Release in subversion and workflow tool"
   echo -e "\tThe new PS Release can be used in the same way as every official PS Release, e.g. knifes, ENB loads"
   echo -e "\tIt is ensured that the new PS Release is complete and that each component is consistent to their own PS Environment"
   echo -e "\tIt is not sure that the components fit to the environment of the other components. It is not sure how much is working with the release"
   echo ""
   echo -e "\t-t  must be set for test run"
   echo -e "\t-h  help text"
   echo ""
   echo "EXAMPLE"
   echo -e "\t${PROG} -b PS_REL_2012_12_00 -d PS_REL_20M2_11_07"
   echo -e "\t${PROG} -b PS_REL_2012_12_01 -l PS_REL_2012_12_00 -c PS_REL_2012_12_00 -m PS_REL_2012_12_00"
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
   while getopts :b:l:c:m:d:th OPTION; 
   do
      case ${OPTION} in
         b) BASE=${OPTARG};;
         l) LFS_BASE=${OPTARG};;
         c) CCS_BASE=${OPTARG};;
         m) MCU_BASE=${OPTARG};;
         d) DSP_BASE=${OPTARG};;
         t) TEST=echo;;
         h) local_usage;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done
   [ -z "${BASE}" ] && fatal "Parameter '-b' not defined"
   [ -z "${LFS_BASE}" ] && LFS_BASE=${BASE}
   [ -z "${CCS_BASE}" ] && CCS_BASE=${BASE}
   [ -z "${MCU_BASE}" ] && MCU_BASE=${BASE}
   [ -z "${DSP_BASE}" ] && DSP_BASE=${BASE}
}

# Check SVN access, define start point
function local_prepare_start()
{
   log "STARTED"
   RESULT=`${SVN} --username psprod list ${SVNAUTH}`
   [ "${RESULT}" = "Your_iSource_Auth_Works_OK" ] || fatal "iSource Authentication FAILED"
   log "iSource Authentication is OK"

   RESULT=`curl -k ${WFT_CHECK} 2>/dev/null`
   [ "${RESULT}" = "File not found" ] || fatal "WFT check FAILED"
   log "WFT access is OK"

   PATCH=true

   findPsRelRepo ${BASE}
   BASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${BASEPSRELREPO}/branches/${BASE} 1>/dev/null 2>/dev/null || fatal "${BASEPSRELREPO}/branches/${BASE} does not exist"
   findPsRelRepo ${LFS_BASE}
   LFS_BASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${LFS_BASEPSRELREPO}/branches/${LFS_BASE} 1>/dev/null 2>/dev/null || fatal "${LFS_BASEPSRELREPO}/branches/${LFS_BASE} does not exist"
   findPsRelRepo ${CCS_BASE}
   CCS_BASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${CCS_BASEPSRELREPO}/branches/${CCS_BASE} 1>/dev/null 2>/dev/null || fatal "${CCS_BASEPSRELREPO}/branches/${CCS_BASE} does not exist"
   findPsRelRepo ${MCU_BASE}
   MCU_BASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${MCU_BASEPSRELREPO}/branches/${MCU_BASE} 1>/dev/null 2>/dev/null || fatal "${MCU_BASEPSRELREPO}/branches/${MCU_BASE} does not exist"
   findPsRelRepo ${DSP_BASE}
   DSP_BASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${DSP_BASEPSRELREPO}/branches/${DSP_BASE} 1>/dev/null 2>/dev/null || fatal "${DSP_BASEPSRELREPO}/branches/${DSP_BASE} does not exist"
   RELEASE=MOTOR_${BASE}
   findPsRelRepo ${RELEASE}
   RELEASEPSRELREPO=${PSRELREPO}
   addPatchNumber ${RELEASE}
   RELEASE=${PATCHVERSION}
   while [ "1" ]; do
      ! ${SVN} ls ${RELEASEPSRELREPO}/tags/${RELEASE} 1>/dev/null 2>/dev/null && break;
      incBuildVersion ${RELEASE}
      RELEASE=${INCVERSION}
   done
   log "RELEASE=${RELEASE}"

   ${SVN} ls ${RELEASEPSRELREPO}/tags/${RELEASE} 1>/dev/null 2>/dev/null && fatal "${PSRELREPO}/tags/${RELEASE} exists already"

   [ -d ${RELEASEDIR}/${RELEASE} ] || mkdir ${RELEASEDIR}/${RELEASE}

   local ECL_FILE=${RELEASEDIR}/${RELEASE}/ECL
   ${SVN} cat ${BASEPSRELREPO}/branches/${BASE}/ECL > ${ECL_FILE} || fatal "svn cat ${BASEPSRELREPO}/branches/${BASE}/ECL > ${ECL_FILE} failed"
   source ${ECL_FILE}

   PS_ENV=`${SVN} cat ${BASEPSRELREPO}/branches/${BASE}/BTS_PS_versionfile.txt | grep PS_ENV= | sed 's/PS_ENV=//'`

   ECL_PS_LFS_OS=`${SVN} cat ${LFS_BASEPSRELREPO}/branches/${LFS_BASE}/ECL | grep ECL_PS_LFS_OS= | sed 's/ECL_PS_LFS_OS=//' | sed 's/-ci.*//'`
   ECL_PS_LFS_REL=`${SVN} cat ${LFS_BASEPSRELREPO}/branches/${LFS_BASE}/ECL | grep ECL_PS_LFS_REL= | sed 's/ECL_PS_LFS_REL=//' | sed 's/-ci.*//'`
   ECL_PS_PNS_LFS_REL=`${SVN} cat ${LFS_BASEPSRELREPO}/branches/${LFS_BASE}/ECL | grep ECL_PS_PNS_LFS_REL= | sed 's/ECL_PS_PNS_LFS_REL=//' | sed 's/-ci.*//'`

   PS_ENV_CCS=`${SVN} cat ${CCS_BASEPSRELREPO}/branches/${CCS_BASE}/BTS_PS_versionfile.txt | grep PS_ENV= | sed 's/PS_ENV=//'`
   NEW_BRANCH_PS_ENV_CCS=`${SVN} cat ${CCS_BASEPSRELREPO}/branches/${CCS_BASE}/ECL | grep ECL_PS_ENV= | sed 's/.*BTS_I_PS\///' | sed 's/\/trunk.*//'`
   NEW_PS_CCS_SW=`${SVN} cat ${CCS_BASEPSRELREPO}/branches/${CCS_BASE}/BTS_PS_versionfile.txt | grep PS_CCS= | sed 's/PS_CCS=//'`
   NEW_BRANCH_PS_CCS_SW=`${SVN} cat ${CCS_BASEPSRELREPO}/branches/${CCS_BASE}/BTS_PS_src_baselines.txt | grep CCS_SRC= | sed 's/.*BTS_SC_CCS\///' | sed 's/\/tags.*//'`
   NEW_PS_CCS_BUILD=`${SVN} cat ${CCS_BASEPSRELREPO}/branches/${CCS_BASE}/BTS_PS_versionfile.txt | grep CCS_BUILD= | sed 's/CCS_BUILD=//'`

   PS_ENV_MCU=`${SVN} cat ${MCU_BASEPSRELREPO}/branches/${MCU_BASE}/BTS_PS_versionfile.txt | grep PS_ENV= | sed 's/PS_ENV=//'`
   NEW_BRANCH_PS_ENV_MCU=`${SVN} cat ${MCU_BASEPSRELREPO}/branches/${MCU_BASE}/ECL | grep ECL_PS_ENV= | sed 's/.*BTS_I_PS\///' | sed 's/\/trunk.*//'`
   NEW_PS_MCU_SW=`${SVN} cat ${MCU_BASEPSRELREPO}/branches/${MCU_BASE}/BTS_PS_versionfile.txt | grep PS_MCUHWAPI= | sed 's/PS_MCUHWAPI=//'`
   NEW_BRANCH_PS_MCU_SW=`${SVN} cat ${MCU_BASEPSRELREPO}/branches/${MCU_BASE}/BTS_PS_src_baselines.txt | grep MCU_SRC= | sed 's/.*BTS_SC_MCUHWAPI\///' | sed 's/\/tags.*//'`
   NEW_PS_MCU_BUILD=`${SVN} cat ${MCU_BASEPSRELREPO}/branches/${MCU_BASE}/BTS_PS_versionfile.txt | grep MCUHWAPI_BUILD= | sed 's/MCUHWAPI_BUILD=//'`

   PS_ENV_DSP=`${SVN} cat ${DSP_BASEPSRELREPO}/branches/${DSP_BASE}/BTS_PS_versionfile.txt | grep PS_ENV= | sed 's/PS_ENV=//'`
   NEW_BRANCH_PS_ENV_DSP=`${SVN} cat ${DSP_BASEPSRELREPO}/branches/${DSP_BASE}/ECL | grep ECL_PS_ENV= | sed 's/.*BTS_I_PS\///' | sed 's/\/trunk.*//'`
   NEW_PS_DSP_SW=`${SVN} cat ${DSP_BASEPSRELREPO}/branches/${DSP_BASE}/BTS_PS_versionfile.txt | grep PS_DSPHWAPI= | sed 's/PS_DSPHWAPI=//'`
   NEW_BRANCH_PS_DSP_SW=`${SVN} cat ${DSP_BASEPSRELREPO}/branches/${DSP_BASE}/BTS_PS_src_baselines.txt | grep DSP_SRC= | sed 's/.*BTS_SC_DSPHWAPI\///' | sed 's/\/tags.*//'`
   NEW_PS_DSP_BUILD=`${SVN} cat ${DSP_BASEPSRELREPO}/branches/${DSP_BASE}/BTS_PS_versionfile.txt | grep DSPHWAPI_BUILD= | sed 's/DSPHWAPI_BUILD=//'`

   NEW_BRANCH_PS_ENV=`${SVN} cat ${BASEPSRELREPO}/branches/${BASE}/ECL | grep ECL_PS_ENV= | sed 's/.*BTS_I_PS\///' | sed 's/\/trunk.*//'`
   BRANCH=${NEW_BRANCH_PS_ENV}

   if [[ "${PS_ENV_CCS}" != "${PS_ENV}" || "${PS_ENV_MCU}" != "${PS_ENV}" || "${PS_ENV_DSP}" != "${PS_ENV}" ]]; then
      NEW_PS_ENV=MOTOR_${PS_ENV}
      addPatchNumber ${NEW_PS_ENV}
      NEW_PS_ENV=${PATCHVERSION}
      while [ "1" ]; do
         ! ${SVN} ls ${SVNENV}/${BRANCH}/tags/${NEW_PS_ENV} 1>/dev/null 2>/dev/null && break;
         incBuildVersion ${NEW_PS_ENV}
         NEW_PS_ENV=${INCVERSION}
      done
   else
      NEW_PS_ENV=${PS_ENV}
   fi
# todo find an unused PS_ENV


   ROTOCI_VERSION=`${SVN} info ${WORKAREA} | grep ^URL | sed 's/.*\///'`

   FCT_PTR_FILE=${RELEASEDIR}/${RELEASE}/fctptr_${PROG}

   log "NEW_BRANCH_PS_ENV=${NEW_BRANCH_PS_ENV}"
   log "NEW_BRANCH_PS_CCS_SW=${NEW_BRANCH_PS_CCS_SW}"
   log "NEW_BRANCH_PS_MCU_SW=${NEW_BRANCH_PS_MCU_SW}"
   log "NEW_BRANCH_PS_DSP_SW=${NEW_BRANCH_PS_DSP_SW}"

   log "LFS_OS=${ECL_PS_LFS_OS}"
   log "LFS_REL=${ECL_PS_LFS_REL}"
   log "PS_ENV=${NEW_PS_ENV}"
   log "PS_CCS=${NEW_PS_CCS_SW}"
   log "CCS_BUILD=${NEW_PS_CCS_BUILD}"
   log "PS_MCUHWAPI=${NEW_PS_MCU_SW}"
   log "MCUHWAPI_BUILD=${NEW_PS_MCU_BUILD}"
   log "PS_DSPHWAPI=${NEW_PS_DSP_SW}"
   log "DSPHWAPI_BUILD=${NEW_PS_DSP_BUILD}"
}

function combine_env ()
{
   if [[ "${NEW_PS_ENV}" != "${PS_ENV}" ]]; then
      ${SVN} ls ${SVNENV}/${NEW_BRANCH_PS_ENV}/branches/${NEW_PS_ENV} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV}/branches/${NEW_PS_ENV}
      local DESTINATION=${SVNENV}/${NEW_BRANCH_PS_ENV}/branches/${NEW_PS_ENV}/I_Interface/Platform_Env
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${PS_ENV}/I_Interface/Platform_Env/Definitions ${DESTINATION}/Definitions ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${PS_ENV}/I_Interface/Platform_Env/Definitions ${DESTINATION}/Definitions failed"
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${PS_ENV}/I_Interface/Platform_Env/Messages ${DESTINATION}/Messages ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${PS_ENV}/I_Interface/Platform_Env/Messages ${DESTINATION}/Messages failed"
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV_CCS}/tags/${PS_ENV_CCS}/I_Interface/Platform_Env/CCS_ENV ${DESTINATION}/CCS_ENV ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV_CCS}/tags/${PS_ENV_CCS}/I_Interface/Platform_Env/CCS_ENV ${DESTINATION}/CCS_ENV failed"
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV_MCU}/tags/${PS_ENV_MCU}/I_Interface/Platform_Env/MCUHWAPI_ENV ${DESTINATION}/MCUHWAPI_ENV ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV_MCU}/tags/${PS_ENV_MCU}/I_Interface/Platform_Env/MCUHWAPI_ENV ${DESTINATION}/MCUHWAPI_ENV failed"
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV_DSP}/tags/${PS_ENV_DSP}/I_Interface/Platform_Env/DSPHWAPI_ENV ${DESTINATION}/DSPHWAPI_ENV ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV_DSP}/tags/${PS_ENV_DSP}/I_Interface/Platform_Env/DSPHWAPI_ENV ${DESTINATION}/DSPHWAPI_ENV failed"
      ${TEST} ${SVN} cp --parents -m "${ROTOCI_VERSION}" ${SVNENV}/${NEW_BRANCH_PS_ENV}/branches/${NEW_PS_ENV} ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV} ||
         fatal "svn cp ${SVNENV}/${NEW_BRANCH_PS_ENV}/branches/${NEW_PS_ENV} ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV} failed"

      local RELNOTEXMLPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.xml"
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      create_xml_file_env
      triggerWft ${PS_ENV} ${NEW_PS_ENV} "" ${RELNOTEXMLPSENV}
   fi
}

################################################################################################
# MAIN
################################################################################################

PROG=`basename $0`
echo "${PROG}: main: STARTED (`date +%d-%B-%Y\ %H:%M:%S`)"
trap 'echo "${PROG}: interrupt signal - bailing out"; exit 0' 1 2 15   # sig handler for interrupts ...
echo "LINSEE_VERSION=${LINSEE_VERSION}"
unset http_proxy ALL_PROXY ftp_proxy      # reset proxies for using wft

sourceEnv
local_process_cmd_line $@
local_prepare_start                             # this function sets the FCT_PTR
combine_env
calc_ver_num
combine_psrel
create_vcf_old
create_vcf
create_ptsw_fsmr3_vcf
create_ptsw_urec_vcf
create_bts_ps_versionfile
create_bts_ps_src_baselines
create_psrel_versionstrings
create_externals_psrel
#ROTOCI_VERSION=ROTOCI_0.007
trigger_wft_psrel

exit 0

################################################################################################
#EOF
################################################################################################
