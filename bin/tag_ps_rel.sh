#!/bin/bash
#
# Author:      Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:	      13-June-2012 
#
# Description: Tagging of PS_REL after all components are successfully tested
#
#####################################################################################

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
   echo -e "\t${PROG} -r <release to be tagged> [-th]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to tag a PS_REL after its components are tested successfully."
   echo ""
   echo -e "\t-t  must be set for test run"
   echo -e "\t-h  help text"
   echo ""
   echo "EXAMPLE"
   echo -e "\t${PROG} -r PS_REL_2012_06_00"
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

   FCT_PTR="read_revisions"
}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   while getopts :r:th OPTION; 
   do
      case ${OPTION} in
         r) REL_TO_BE_TAGGED=${OPTARG};;
         t) TEST=echo;;
         h) local_usage;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done
}

function handle_xml()
{
   log "STARTED"
   findPsRelRepo ${REL_TO_BE_TAGGED}
   local FNAME=${REL_TO_BE_TAGGED}_releasenote.xml
   local FILE=${RELEASEDIR}/${REL_TO_BE_TAGGED}/${FNAME}
   local PS_REL_DST="${PSRELREPO}/branches/${REL_TO_BE_TAGGED}"
   mkdir ${RELEASEDIR}/${REL_TO_BE_TAGGED}
   log "wget -O ${FILE} ${WFT_XML}/${REL_TO_BE_TAGGED} --no-check-certificate"
   wget -O ${FILE} ${WFT_XML}/${REL_TO_BE_TAGGED} --no-check-certificate
   [ "$?" != "0" ] && fatal "wget ${WFT_XML}/${REL_TO_BE_TAGGED} failed"

   # insert date/time
   local DATE_NOW=`date +%Y-%m-%d`
   local TIME_NOW=`date +%H:%M:%SZ -u`
   sed -i "s|<releaseDate></releaseDate>|<releaseDate>${DATE_NOW}</releaseDate>|" ${FILE}
   sed -i "s|<releaseTime></releaseTime>|<releaseTime>${TIME_NOW}</releaseTime>|" ${FILE}
   sed -i "s|<repositoryRevision></repositoryRevision>|<repositoryRevision>HEAD</repositoryRevision>|" ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/Documents/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/Documents/${FNAME} failed"
   log "DONE"
}

function tag_ps_rel ()
{
   log "STARTED"
   [ -z "${REL_TO_BE_TAGGED}" ] && fatal "Parameter '-r' not defined"
   local SRC="${PSRELREPO}/branches/${REL_TO_BE_TAGGED}"
   local DST="${PSRELREPO}/tags/${REL_TO_BE_TAGGED}" 
   log "SRC: ${SRC}"
   log "DST: ${DST}"
   ${SVN} ls ${SRC} 1>/dev/null 2>/dev/null || fatal "branch ${SRC} does not exist"
   ${SVN} ls ${DST} 1>/dev/null 2>/dev/null && fatal "tag ${DST} already exists"
   ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      fatal "svn cp ${SRC} ${DST} failed"
   log "DONE"
}

# write revision number of tag to WFT
function update_revision_number ()
{
   log "STARTED"
   local REV=`${SVN} info ${PSRELREPO}/tags/${REL_TO_BE_TAGGED} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   log "curl -k ${WFT_PORT}/builds/${REL_TO_BE_TAGGED} -F \"access_key=WFT_KEY\" -F \"build[repository_revision]=${REV}\" -X PUT"
   curl -k ${WFT_PORT}/builds/${REL_TO_BE_TAGGED} -F "access_key=${WFT_KEY}" -F "build[repository_revision]=${REV}" -X PUT
   log "DONE"
}

function update_ecl_rp () 
{
   log "STARTED"
   local RP_ECL_PATH=
   local BRANCH=`${SVN} cat ${PSRELREPO}/branches/${REL_TO_BE_TAGGED}/CI2RM | grep CI2RM_ECL | sed -e "s,.*/ECL/\(.*\)/ECL_HWAPI/.*,\1,"` || fatal "svn cat failed"
   log "BRANCH=${BRANCH}"
   if [[ "${BRANCH}" == "MAINBRANCH" ]]; then
      RP_ECL_PATH=trunk/ECL_PS
   elif  [[ "${BRANCH}" =~ "20M[3-9]_0[1-9]|20M[2-9]_1[0-2]" ]]; then
      local FB=`echo ${BRANCH} | sed "s/20M/FB1/" | sed "s/_//"`
      RP_ECL_PATH=branches/maintenance/${FB}/ECL_PS
   else
      RP_ECL_PATH=branches/maintenance/${BRANCH}/ECL_PS
   fi

   ${SVN} ls ${SVNRPECL}/${RP_ECL_PATH} 1>/dev/null 2>/dev/null 
   if [ "$?" != "0" ] ; then
      log "$RP_ECL_PATH does not exist -> no action for ${SVNRPECL} required"
      return 0
   fi
   log "Update ECL File on RP-Repository: ${SVNRPECL}/${RP_ECL_PATH}"

   local GLOBAL_ENV=`${SVN} cat ${PSRELREPO}/branches/${REL_TO_BE_TAGGED}/BTS_PS_versionfile.txt | grep "^GLOBAL_ENV=" | sed "s/.*=//"` || fatal "svn cat failed"
   local PS_ENV=`${SVN} cat ${PSRELREPO}/branches/${REL_TO_BE_TAGGED}/BTS_PS_versionfile.txt | grep "^PS_ENV=" | sed "s/.*=//"` || fatal "svn cat failed"
   local DST="${RELEASEDIR}/${REL_TO_BE_TAGGED}/ECL_RP"
   mkdir -p ${DST}
   ${SVN} co --ignore-externals ${SVNRPECL}/${RP_ECL_PATH} ${DST} || return 0
   log "svn co ${SVNRPECL}/${RP_ECL_PATH} ${DST}"
   echo "ECL_GLOBAL_ENV=${GLOBAL_ENV}" > ${DST}/ECL
   echo "ECL_PS_ENV=${PS_ENV}" >> ${DST}/ECL
   echo "ECL_PS_REL=${REL_TO_BE_TAGGED}" >> ${DST}/ECL
   log "RP_ECL updated"
   ${SVN} ci -m "${GLOBAL_ENV} ${PS_ENV} ${REL_TO_BE_TAGGED}" ${DST}/ECL || warn "svn ci ${DST}/ECL failed"
   log "DONE"
}

# fill platform components into database
function fill_db ()
{
   log "STARTED"

   local BRANCH=`${SVN} cat ${PSRELREPO}/branches/${REL_TO_BE_TAGGED}/CI2RM | grep CI2RM_ECL | sed -e "s,.*/ECL/\(.*\)/ECL_HWAPI/.*,\1,"`
   local FILE=${RELEASEDIR}/${REL_TO_BE_TAGGED}/ECL.txt
   local ENV_REV=`cat ${FILE} | grep ECL_PS_ENV= | sed "s/.*@//"`
   local CCS_REV=`cat ${FILE} | grep ECL_CCS= | sed "s/.*@//"`
   local MCU_REV=`cat ${FILE} | grep ECL_MCUHWAPI= | sed "s/.*@//"`
   local DSP_REV=`cat ${FILE} | grep ECL_UPHWAPI= | sed "s/.*@//"`

   curl "http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=PS_ENV&Revision=${ENV_REV}"
   curl "http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=CCS&Revision=${CCS_REV}"
   curl "http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=MCUHWAPI&Revision=${MCU_REV}"
   curl "http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=DSPHWAPI&Revision=${DSP_REV}"

   log "curl http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=PS_ENV&Revision=${ENV_REV}"
   log "curl http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=CCS&Revision=${CCS_REV}"
   log "curl http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=MCUHWAPI&Revision=${MCU_REV}"
   log "curl http://relsearch_RW:h9839prgseurg@ulegcppsmon1.emea.nsn-net.net/cgi-bin/relsearch_add.pl?Branch=${BRANCH}&RelID=${REL_TO_BE_TAGGED}&SysComp=DSPHWAPI&Revision=${DSP_REV}"

   log "DONE"
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
sleep 60 # some time for wft updating their info
handle_xml
tag_ps_rel
update_revision_number
update_ecl_rp        
fill_db

exit 0

#########################################################################
# eof
#########################################################################
