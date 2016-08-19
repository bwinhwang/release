#!/bin/bash
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
#           Dirk Harms       <dirk.harms.ext@nsn.com>
# Date:     14-Nov-2012
#
# Description:
#           release of factory production and test software
#
######################################################################################

PROG=`basename ${0}`
DATE_NOW="date +%Y/%m/%d"
TIME_NOW="date +%H:%M:%S"
TIMEZONE="date +%Z"
BOARD_PREP='BoardsPrepared4Factory'
BOARD_PREP_WFT="${BOARD_PREP}.txt"
BOARD_SUP='BoardsSupported4Factory'
BOARD_SUP_WFT="${BOARD_SUP}.txt"
TYPE=

# signal handler for interrupts ...
trap 'echo ""; echo "${PROG}: ABORTED"; echo ""; exit 0' SIGHUP SIGINT SIGTERM

# Function: Usage
function local_usage()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG} - release of factory, production and test software(PTSW)"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -p <PS release> -b <Base PTSW Release> -r <New PTSW Release> [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to release a new PTSW for factory"
   echo ""
   echo -e "\t-p  name of PS release"
   echo -e "\t-b  name of base PTSW release"
   echo -e "\t-r  name of new PTSW release"
   echo ""
   echo "EXAMPLES"
   echo -e "\t${PROG} -p DND3.0_PS_REL_2012_08_01 -b PTSW_UREC_2012_07_01 -r PTSW_UREC_DND30_2012_08_00" 
   echo -e "\t${PROG} -p MB_PS_REL_2012_09_01 -b PTSW_FSMR3_2012_07_01 -r PTSW_FSMR3_2012_09_00" 
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
  [ -r "${ENV}" ] ||  fatal "${PROG}: Unable to source ${ENV} - bailing out!"
  source ${ENV}

  FCT=${WORKAREA}/bin/ps_functions.sh
  [ -r "${FCT}" ] ||  fatal "${PROG}: Unable to source ${FCT} - bailing out!"
  source ${FCT}

  sourceRest
}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   while getopts :p:b:r:h OPTION; 
   do
      case ${OPTION} in
         p) PSREL=${OPTARG};;
         b) PTSW_BASE=${OPTARG};;
         r) PTSW=${OPTARG};;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done

   [ -z "${PSREL}" ] && fatal "Parameter '-p' not defined"
   [ -z "${PTSW_BASE}" ] && fatal "Parameter '-b' not defined"
   [ -z "${PTSW}" ] && fatal "Parameter '-r' not defined"
   
   ### parse the TYPE from $PTSW
#  TYPE=`echo ${PTSW} | sed 's/\(PTSW.*\)_2[0-9][^\_]*\_[0-9]*\_[0-9]*.*/\1/' | tr [A-Z] [a-z]`;
   TYPE=`echo ${PTSW} | sed 's/\(PTSW_[^_]*\).*_20[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}.*/\1/' | tr [A-Z] [a-z]`;
   log "PTSW: ${PTSW}"
   log "TYPE: ${TYPE}"
}

function local_prepare_start()
{
   log "STARTED"
   set -o pipefail
   RESULT=`${SVN} --username psprod list ${SVNAUTH}`
   [ "${RESULT}" = "Your_iSource_Auth_Works_OK" ] || fatal "iSource Authentication FAILED"
   log "iSource Authentication is OK"

   RESULT=`curl -k ${WFT_CHECK} 2>/dev/null`
   [ "${RESULT}" = "File not found" ] || fatal "WFT check FAILED"
   log "WFT access is OK"

   findPsRelRepo ${PSREL}
   findPtswRepo ${PTSW}

   [ -d ${PTSWDIR}/${PTSW} ] || mkdir ${PTSWDIR}/${PTSW}

   while [[ ! `${SVN} ls ${PSRELREPO}/branches/${PSREL}/ECL` ]]; do
      log "waiting for ${PSRELREPO}/branches/${PSREL}"
      sleep 60
   done
   ECL_PS_LFS_REL=`${SVN} cat ${PSRELREPO}/branches/${PSREL}/ECL | grep ECL_PS_LFS_REL | sed 's/ECL_PS_LFS_REL=//' | sed 's/-ci.*//'` || fatal "svn cat failed"
   ECL_PS_LFS_OS=`echo ${ECL_PS_LFS_REL} | sed "s|_LFS_REL_|_LFS_OS_|"`

#   ECL_PS_LFS_OS=`${SVN} cat ${PSRELREPO}/branches/${PSREL}/ECL | grep ECL_PS_LFS_OS | sed 's/ECL_PS_LFS_OS=//' | sed 's/-ci.*//'` || fatal "svn cat failed"
#   ECL_PS_PNS_LFS_REL=`${SVN} cat ${PSRELREPO}/branches/${PSREL}/ECL | grep ECL_PS_PNS_LFS_REL | sed 's/ECL_PS_PNS_LFS_REL=//' | sed 's/-ci.*//'` || fatal "svn cat failed"

   ROTOCI_VERSION=`${SVN} info ${WORKAREA} | grep ^URL | sed 's/.*\///'` || fatal "svn info failed"
   log "DONE"
}

function read_vcf ()
{
   local VCDIR=${1}
   local MANDATORY=${2}
   local FILE="${TYPE}_version_control.xml"
   log "VCDIR=${VCDIR}"
   log "MANDATORY=${MANDATORY}"
   log "FILE=${FILE}"

   [ -z "${MANDATORY}" ] || ${SVN} cat ${VCDIR}/${FILE} > ${PTSWDIR}/${PTSW}/${FILE} || fatal "svn cat ${VCDIR}/${FILE} > ${PTSWDIR}/${PTSW}/${FILE} failed"
   [ "${MANDATORY}" ] || ${SVN} cat ${VCDIR}/${FILE} > ${PTSWDIR}/${PTSW}/${FILE} || warn "svn cat ${VCDIR}/${FILE} > ${PTSWDIR}/${PTSW}/${FILE} failed"
   sed -i -e '/<!--.*-->/d' -e '/<!--/,/.*-->/d' ${PTSWDIR}/${PTSW}/${FILE}    # remove all comments 
   while read LINE; do
      SOURCE=`echo ${LINE} | sed 's/.*source=\"\([^\"]*\)\".*/\1/'`
      FILENAME=`echo ${SOURCE} | sed 's/.*\///'`
      DESTINATION=`echo ${LINE} | sed 's/.*destination=\"\([^\"]*\)\".*/\1/'`
      mkdir -p ${PTSWDIR}/${PTSW}/${DESTINATION}
      if [[ "${SOURCE}" =~ "\/" ]]; then
         ${SVN} export --force ${VCDIR}/${SOURCE} ${PTSWDIR}/${PTSW}/${DESTINATION}/${FILENAME} ||
           warn "svn export --force ${VCDIR}/${SOURCE} ${PTSWDIR}/${PTSW}/${DESTINATION}/${FILENAME} failed"
      else
         touch ${PTSWDIR}/${PTSW}/${DESTINATION}/${FILENAME}
      fi
   done < <(grep "file source=" ${PTSWDIR}/${PTSW}/${FILE})
   rm ${PTSWDIR}/${PTSW}/${FILE}
}

function read_lfs ()
{
   log "STARTED"
   findLfsRelRepo ${ECL_PS_LFS_REL}
   local LFS_REPO=${SVNURL}/${LFSRELREPO}
   read_vcf ${LFS_REPO}/os/tags/${ECL_PS_LFS_OS} 'MANDATORY'
   
   # export the prepare/supported Boards info 
   #
   # todo: do we need to catch warning about non existing file?
   #
#   ${SVN} export --force ${LFS_REPO}/os/tags/${ECL_PS_LFS_OS}/doc/${BOARD_PREP} ${PTSWDIR}/${PTSW}/${BOARD_PREP_WFT} || 
#		fatal "svn export ${LFS_REPO}/os/tags/${ECL_PS_LFS_OS}/doc/${BOARD_PREP} failed"
#   ${SVN} export --force ${LFS_REPO}/os/tags/${ECL_PS_LFS_OS}/doc/${BOARD_SUP}  ${PTSWDIR}/${PTSW}/${BOARD_SUP_WFT} || 
#		fatal "svn export ${LFS_REPO}/os/tags/${ECL_PS_LFS_OS}/doc/${BOARD_SUP} failed"
   
   log "DONE"
}

function read_ps ()
{
   log "STARTED"
#   read_vcf ${PSRELREPO}/tags/${PSREL}/C_Platform
   read_vcf ${PSRELREPO}/branches/${PSREL}/C_Platform 'MANDATORY'
   DST="${PTSWDIR}/${PTSW}/flash"
   mv ${DST}/FSPD-DSP-RT*.BIN ${DST}/dsprtsw.bin || warn "mv ${DST}/FSPD-DSP-RT*.BIN ${DST}/dsprtsw.bin failed"
   mv ${DST}/FSPD-DSP-BW*.BIN ${DST}/dspbootsw.bin || warn "mv ${DST}/FSPD-DSP-BW*.BIN ${DST}/dspbootsw.bin failed"

   log "DONE"
}

function read_pns ()
{
   log "STARTED"
	
   # we have to evaluate the 'external' property to get the real repository
   PNS_PATH=`${SVN} pg svn:externals ${SVNDPNS}/tags/${ECL_PS_PNS_LFS_REL} | grep ' os\s*$' | sed 's/\^\/\([^\([:space:]\)]*\)\s.*/\1/'`  
   # grep fetches the 'os' external only #
   # sed extract the repository path # "^/os/tags/PNS_LFS_OS_2012_08_01-ci2    os" => "os/tags/PNS_LFS_OS_2012_08_01-ci2"
   
   read_vcf ${SVNDPNS}/${PNS_PATH}
   log "DONE"
}


function make_tag ()
{
   log "STARTED"
   SRC=${PTSWDIR}/${PTSW}
   cd ${SRC}
   zip -r ptsw . || fatal "zip -r ptsw failed"
   ${SVN} mkdir ${PTSWREPO}/branches/${PTSW} -m "${PTSW}" --parents || fatal "svn mkdir ${PTSWREPO}/branches/${PTSW} failed"
   ${SVN} import ptsw.zip ${PTSWREPO}/branches/${PTSW}/ptsw.zip -m "${PTSW}" || fatal "svn import ptsw.zip ${PTSWREPO}/branches/${PTSW}/ptsw.zip failed"
   ${SVN} cp ${PTSWREPO}/branches/${PTSW} ${PTSWREPO}/tags/${PTSW} -m "${PTSW}" --parents || fatal "svn cp ${SRC} ${PTSWREPO}/tags/${PTSW} failed"
   cd -
   log "DONE"
}

function trigger_wft_ptsw ()
{
   log "STARTED"
   [[ ${PS_REL} ]] && SUB_BUILD="-F sub_build[]=${PS_REL}"
   [[ ${ROTOCI_VERSION} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ROTOCI_VERSION}"
   CMD="curl -s -k ${WFT_API}/increment/${PTSW} -F xml_releasenote_id=37 -F parent=${PTSW_BASE} ${SUB_BUILD} -F access_key=${WFT_KEY}"
   log "${CMD}"
   local RET=`${CMD}`
   [[ "${RET}" =~ "success" ]]                 && log "wft creation of '${PTSW}' successful"
   [[ "${RET}" =~ "Parent baseline.*" ]]       && fatal "wft creation of '${PTSW}' failed, ${RET}"
   [[ "${RET}" =~ "not found in WFT" ]]        && fatal "wft creation of '${PTSW}' failed, ${RET}"
   [[ "${RET}" =~ "Access denied" ]]           && fatal "wft creation of '${PTSW}' failed, ${RET}"
   [[ "${RET}" =~ "baseline exists already" ]] && fatal "wft creation of '${PTSW}' failed, ${RET}"
   [[ "${RET}" =~ "success" ]]                 || fatal "wft creation of '${PTSW}' failed, ${RET}"

   log "Create '${PTSW}' in WFT"
   curl -k ${WFT_API}/repository/${PTSW} -F "access_key=${WFT_KEY}" -F "repository=${PTSWREPO}/tags/${PTSW}"
   curl -k ${WFT_PORT}/builds/${PTSW} -F "access_key=${WFT_KEY}" -F "build[repository_url]=${PTSWREPO}" -X PUT
   curl -k ${WFT_PORT}/builds/${PTSW} -F "access_key=${WFT_KEY}" -F "build[repository_branch]=tags/${PTSW}" -X PUT

   if [ -r ${PTSWDIR}/${PTSW}/${BOARD_PREP_WFT} ]; then
      log "Upload '${BOARD_PREP_WFT}' to WFT"
      curl -k ${WFT_API}/upload/${PTSW} -F "access_key=${WFT_KEY}" -F "file=@${PTSWDIR}/${PTSW}/${BOARD_PREP_WFT}";
   fi;
   
   if [ -r ${PTSWDIR}/${PTSW}/${BOARD_SUP_WFT} ]; then
      log "Upload '${BOARD_SUP_WFT}' to WFT"
      curl -k ${WFT_API}/upload/${PTSW} -F "access_key=${WFT_KEY}" -F "file=@${PTSWDIR}/${PTSW}/${BOARD_SUP_WFT}";
   fi;
   
   
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
local_process_cmd_line $@
local_prepare_start
read_lfs
#read_pns
read_ps
make_tag
trigger_wft_ptsw

echo "${PROG}: All Done ${START_TIME} - `${TIME_NOW}` `${TIMEZONE}`"
echo ""
exit 0

##################################################
# EOF
##################################################
