#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           ps_env related functions
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
#
###################################################################################################

function sync_env ()
{
   local SRC="${RELEASEDIR}/${RELEASE}/interfaces"
   local CODST="${RELEASEDIR}/${RELEASE}/co_env"
   local EXPORTDST="${RELEASEDIR}/${RELEASE}/export_env"
   log "Remove old elements in ${CODST}"
   for i in `dirDiff ${EXPORTDST} ${SRC} | grep -v "\.svn"`; do
      ${SVN} rm ${CODST}/${i} || fatal "svn rm ${CODST}/${i} failed"
      log "${CODST}/${i} removed"
   done
   log "Add new elements to ${CODST}"
   for i in `dirDiff ${SRC} ${EXPORTDST} | grep -v "\.svn"`; do
      mkdir --parents `dirname ${CODST}/${i}`
      cp ${SRC}/${i} ${CODST}/${i} || fatal "cp ${SRC}/${i} ${CODST}/${i} failed"
      ${SVN} add --parents ${CODST}/${i} || fatal "svn add --parents ${CODST}/${i} failed"
      log "${CODST}/${i} added"
      ${SVN} propset svn:eol-style native ${CODST}/${i} || fatal "svn propset svn:eol-style native ${CODST}/${i} failed"
      ${SVN} propset svn:keywords "HeadURL LastChangedRevision LastChangedDate Author" ${CODST}/${i} || fatal "svn propset svn:keywords HeadURL LastChangedRevision LastChangedDate Author ${CODST}/${i} failed"
   done
   log "Copy modified elements to ${CODST}"
   cd ${SRC}
   for i in `find . -type f | grep -v "\.svn"`; do
      diff --brief ${SRC}/${i} ${EXPORTDST}/${i} 
      if [ "$?" != "0" ] ; then
         log "${CODST}/${i} modified" 
         cp -r ${SRC}/${i} ${CODST}/${i} || fatal "cp ${SRC}/${i} ${CODST}/${i} failed"
      fi
   done
   cd -
   for i in `find ${CODST} -type d | grep -v "\.svn" | sort -r` ; do
      [ "$(ls ${i})" ] || ${SVN} rm ${i}
   done
}

# creation of xml-file PS_ENV
function create_xml_file_env ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   local REV=`${SVN} info ${SVNENV}/${BRANCH}/tags/${NEW_PS_ENV} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSENV}
   echo "  <name>${NEW_PS_ENV}</name>" >> ${RELNOTEXMLPSENV}
   echo "  <system>PS_ENV</system>" >> ${RELNOTEXMLPSENV}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSENV}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSENV}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSENV}
   echo "  <basedOn>${PS_ENV}</basedOn>" >> ${RELNOTEXMLPSENV}
   echo "  <importantNotes>" >> ${RELNOTEXMLPSENV}
   echo "    <note name=\"${NEW_PS_ENV}\">" >> ${RELNOTEXMLPSENV}
   REMToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "      $element" >> ${RELNOTEXMLPSENV}
   done
   echo "    </note>" >> ${RELNOTEXMLPSENV}
   echo "  </importantNotes>" >> ${RELNOTEXMLPSENV}
   echo "  <repositoryUrl>${SVNENV}</repositoryUrl>" >> ${RELNOTEXMLPSENV}
   echo "  <repositoryBranch>${BRANCH}/tags/${NEW_PS_ENV}</repositoryBranch>" >> ${RELNOTEXMLPSENV}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSENV}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSENV}
   echo "  <correctedFaults> " >> ${RELNOTEXMLPSENV}
   echo "    <module name=\"PS_ENV\">" >> ${RELNOTEXMLPSENV}
   PRToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSENV}
   done
   echo "    </module>" >> ${RELNOTEXMLPSENV}
   echo "  </correctedFaults>" >> ${RELNOTEXMLPSENV}
   echo "  <revertedCorrectedFaults>" >> ${RELNOTEXMLPSENV}
   echo "    <module name=\"PS_ENV\">" >>  ${RELNOTEXMLPSENV}
   for element in "${SUB[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSENV}
   done
   echo "    </module>" >> ${RELNOTEXMLPSENV}
   echo "  </revertedCorrectedFaults>" >> ${RELNOTEXMLPSENV}
   echo "  <baselines>" >> ${RELNOTEXMLPSENV}
   echo "    <baseline name=\"GLOBAL_ENV\">${ECL_GLOBAL_ENV}</baseline>" >> ${RELNOTEXMLPSENV}
   echo "    <baseline auto_create=\"true\" name=\"ROTOLRC\">${ROTOLRC_VERSION}</baseline>" >> ${RELNOTEXMLPSENV}
   echo "  </baselines>" >> ${RELNOTEXMLPSENV}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSENV}
   echo "  <changenotes>" >> ${RELNOTEXMLPSENV}
   echo "    <module name=\"PS_ENV\">" >> ${RELNOTEXMLPSENV}
   CNToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSENV}
   done
   echo "    </module>" >> ${RELNOTEXMLPSENV}
   echo "  </changenotes>" >> ${RELNOTEXMLPSENV}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSENV}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSENV}
   echo "  <download>" >> ${RELNOTEXMLPSENV}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_ENV\">" >> ${RELNOTEXMLPSENV}
   echo "      ${SVNENV}/${BRANCH}/tags/${NEW_PS_ENV}" >> ${RELNOTEXMLPSENV}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSENV}
   echo "  </download>" >> ${RELNOTEXMLPSENV}
   echo "  <features>" >> ${RELNOTEXMLPSENV}
   echo "    <module name=\"PS_ENV\">" >>  ${RELNOTEXMLPSENV}
   NFToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSENV}
   done
   echo "    </module>" >> ${RELNOTEXMLPSENV}
   echo "  </features>" >> ${RELNOTEXMLPSENV}
   echo "</releasenote>" >> ${RELNOTEXMLPSENV}
   chmod 755 ${RELNOTEXMLPSENV}
}

##################
# main functions #
##################

function branch_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}

   for BASEBRANCH in ${BRANCHES} ; do
      ${SVN} ls ${SVNENV}/${BASEBRANCH}/tags/${PS_ENV} 1>/dev/null 2>/dev/null && break
   done
   ${SVN} ls ${SVNENV}/${BASEBRANCH}/tags/${PS_ENV} 1>/dev/null 2>/dev/null ||
     fatal "${SVNENV}/${BASEBRANCH}/tags/${PS_ENV} does not exist in subversion";

   ${SVN} ls ${SVNSERVER}${PS_ENV_BRANCH} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_ENV_BRANCH}
   ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_PS_ENV} ${SVNSERVER}${PS_ENV_BRANCH} || 
     ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_PS_ENV} ${SVNSERVER}${PS_ENV_BRANCH} || 
     fatal "svn cp ${SVNSERVER}${ECL_PS_ENV} ${SVNSERVER}${PS_ENV_BRANCH} failed"
   for i in `${SVN} ls ${SVNENV}/${BASEBRANCH}/tags/${PS_ENV}/I_Interface/Platform_Env | grep -v Messages | grep -v Definitions` ; do
      ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNENV}/${BASEBRANCH}/tags/${PS_ENV}/I_Interface/Platform_Env/${i} ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env ||
        fatal "svn cp ${SVNENV}/${BASEBRANCH}/tags/${PS_ENV}/I_Interface/Platform_Env/${i} ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env failed"
   done

   log "DONE"
}

function co_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}

   local ECL_ENV_REVISION=`echo -e ${ECL_PS_ENV} | sed "s/.*@//"`
   local ECL_ENV_BASE=`echo -e ${ECL_PS_ENV} | sed "s/@.*//"`
   ${SVN} export --force  ${SVNSERVER}${ECL_ENV_BASE}/I_Interface/Platform_Env@${ECL_ENV_REVISION} ${RELEASEDIR}/${RELEASE}/interfaces ||
     fatal "svn export ${SVNSERVER}${ECL_ENV_BASE}/I_Interface/Platform_Env@${ECL_ENV_REVISION} failed"

   local ECL_CCS_REVISION=`echo -e ${ECL_CCS} | sed "s/.*@//"`
   local ECL_CCS_BASE=`echo -e ${ECL_CCS} | sed "s/@.*//"`
   ${SVN} export --force  ${SVNSERVER}${ECL_CCS_BASE}/I_Interface/Platform_Env@${ECL_CCS_REVISION} ${RELEASEDIR}/${RELEASE}/interfaces || 
     fatal "svn export ${SVNSERVER}${ECL_CCS_BASE}/I_Interface/Platform_Env@${ECL_CCS_REVISION} failed"

   local ECL_MCUHWAPI_REVISION=`echo -e ${ECL_MCUHWAPI} | sed "s/.*@//"`
   local ECL_MCUHWAPI_BASE=`echo -e ${ECL_MCUHWAPI} | sed "s/@.*//"`
   ${SVN} export --force  ${SVNSERVER}${ECL_MCUHWAPI_BASE}/I_Interface/Platform_Env@${ECL_MCUHWAPI_REVISION} ${RELEASEDIR}/${RELEASE}/interfaces || 
     fatal "svn export ${SVNSERVER}${ECL_MCUHWAPI_BASE}/I_Interface/Platform_Env@${ECL_MCUHWAPI_REVISION} failed"

   local ECL_UPHWAPI_REVISION=`echo -e ${ECL_UPHWAPI} | sed "s/.*@//"`
   local ECL_UPHWAPI_BASE=`echo -e ${ECL_UPHWAPI} | sed "s/@.*//"`
   ${SVN} export --force  ${SVNSERVER}${ECL_UPHWAPI_BASE}/I_Interface/Platform_Env@${ECL_UPHWAPI_REVISION} ${RELEASEDIR}/${RELEASE}/interfaces || 
     fatal "svn export ${SVNSERVER}${ECL_UPHWAPI_BASE}/I_Interface/Platform_Env@${ECL_UPHWAPI_REVISION} failed"

   for i in `find ${RELEASEDIR}/${RELEASE}/interfaces -type f | grep -v "\.svn"` ; do
      dos2unix ${i}
   done

   ${SVN} export --force  ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env ${RELEASEDIR}/${RELEASE}/export_env ||
     fatal "svn export ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env failed"

   for i in `find ${RELEASEDIR}/${RELEASE}/export_env -type f | grep -v "\.svn"` ; do
      dos2unix ${i}
   done

   ${SVN} co ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env ${RELEASEDIR}/${RELEASE}/co_env ||
     fatal "svn co ${SVNSERVER}${PS_ENV_BRANCH}/I_Interface/Platform_Env failed"

###########################################################################################
#  tmp propset until all branches are released once"
#  todo: remove it afterwards
#   for i in `find ${RELEASEDIR}/${RELEASE}/co_env -type f | grep -v "\.svn"` ; do
#      ${SVN} propset svn:keywords "HeadURL LastChangedRevision LastChangedDate Author" ${i} || fatal "svn propset svn:keywords HeadURL LastChangedRevision LastChangedDate Author ${i} failed"
#   done
###########################################################################################

   log "DONE"
}

function update_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   sync_env
   ${TEST} ${SVN} ci -m "${ROTOLRC_VERSION}" ${RELEASEDIR}/${RELEASE}/co_env || fatal "svn ci failed"
   log "DONE"
}

function define_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   checkChanges ${SVNENV} ${PS_ENV_BRANCH} ${PS_ENV}
   if [ "${DIFFERENCE}" != "0" ]; then
      defineTag ${SVNENV} ${PS_ENV}
      NEW_PS_ENV=${UNUSEDTAG}
      NEW_BRANCH_PS_ENV=${BRANCH}
   else
      log "no new ps_env needed"
      NEW_PS_ENV=${PS_ENV}
      for NEW_BRANCH_PS_ENV in ${BRANCHES} ; do
         ${SVN} ls ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV} 1>/dev/null 2>/dev/null && break
      done
      ${SVN} ls ${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV} 1>/dev/null 2>/dev/null ||
        fatal "${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV} does not exist in subversion";
   fi
   echo "NEW_BRANCH_PS_ENV=${NEW_BRANCH_PS_ENV}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   echo "NEW_PS_ENV=${NEW_PS_ENV}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_ENV}" != "${PS_ENV}" ]]; then
      tagIt ${SVNENV} ${PS_ENV_BRANCH} ${NEW_PS_ENV}
   fi
   log "DONE"
}

# create PS_ENV output files
function create_output_files_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_ENV}" != "${PS_ENV}" ]]; then
      local RELNOTEXMLPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.xml"
      local RELNOTEHTMLPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.html"
      local RELNOTETXTPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.txt"

      local ECL_CCS_STRIPPED=`echo ${ECL_CCS} | sed 's|/isource/svnroot/LRC_SC_CCS/||'`
      local ECL_MCU_STRIPPED=`echo ${ECL_MCUHWAPI} | sed 's|/isource/svnroot/LRC_SC_MCUHWAPI/||'`
      local ECL_DSP_STRIPPED=`echo ${ECL_UPHWAPI} | sed 's|/isource/svnroot/LRC_SC_UPHWAPI/||'`

      local HEADLINE="\n\n\n============================================================\n\n"

      getLogInfo ${SVNENV} ${NEW_PS_ENV} ${PS_ENV}      # result will be copied to 'CI_COMMENTS'
      local ALL_COMMENTS="${CI_COMMENTS}"
      getSelectedLogInfo ${SVNCCS} ${ECL_CCS_STRIPPED} ${PS_CCS_SW}
      ALL_COMMENTS=`echo -e "${ALL_COMMENTS}${HEADLINE}svn interface changes from CCS\n${CI_COMMENTS}"`
      getSelectedLogInfo ${SVNMCU} ${ECL_MCU_STRIPPED} ${PS_MCU_SW}
      ALL_COMMENTS=`echo -e "${ALL_COMMENTS}${HEADLINE}svn interface changes from MCUHWAPI\n${CI_COMMENTS}"`
      getSelectedLogInfo ${SVNDSP} ${ECL_DSP_STRIPPED} ${PS_DSP_SW}
      ALL_COMMENTS=`echo -e "${ALL_COMMENTS}${HEADLINE}svn interface changes from DSPHWAPI\n${CI_COMMENTS}"`
      CI_COMMENTS="${ALL_COMMENTS}"

      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      createTxtFile ${NEW_PS_ENV} ${PS_ENV} ${RELNOTETXTPSENV}
      create_xml_file_env
      createHtmlFile ${RELNOTEXMLPSENV} ${RELNOTEHTMLPSENV}
   fi
   log "DONE"
}

# trigger WFT PS_ENV
function trigger_wft_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.xml"
   local RELNOTEHTMLPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.html"
   local RELNOTETXTPSENV="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_ENV}.txt"
   triggerWft ${PS_ENV} ${NEW_PS_ENV} "" ${RELNOTEXMLPSENV} ${RELNOTETXTPSENV} ${RELNOTEHTMLPSENV}
   log "DONE"
}

# send mail
function send_mail_env ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_ENV}" != "${PS_ENV}" ]]; then
      SUB="PS_ENV Release ${NEW_PS_ENV} is ready for ${RELEASE}"
      FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
      REPLYTO="scm-ps-prod@mlist.emea.nsn-intra.net"
      TO="scm-ps-rel@mlist.emea.nsn-intra.net"
      CC="scm-ps-prod@mlist.emea.nsn-intra.net"
      MSG="Dear Colleagues,

The PS_ENV release ${NEW_PS_ENV} is now available. Target PS release: ${RELEASE}

Interfaces:
${SVNENV}/${BRANCH}/tags/${NEW_PS_ENV}
${SNVGLOBAL}/tags/${ECL_GLOBAL_ENV}

Detailed information is stored in the Work Flow Tool:
${WFT_SHOW}/${NEW_PS_ENV}

Best regards
PS SCM"
      ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"
   fi
   log "DONE"
}
function check_env ()
{
   log "STARTED"
local ENV_FILE=${RELEASEDIR}/${RELEASE}/config_ps_rotolrc_env.sh
   while [ ! -r "${ENV_FILE}" ]; do
      log "waiting for ${ENV_FILE}"
      sleep 60
   done
   source ${ENV_FILE}
   [ -z "${NEW_BRANCH_PS_ENV}" ] && fatal "NEW_BRANCH_PS_ENV not defined"
   [ -z "${NEW_PS_ENV}" ] && fatal "NEW_PS_ENV not defined"
   log "DONE"
}

function check_env_completed ()
{
local ENV_FILE=${RELEASEDIR}/${RELEASE}/fctptr_ps_rotolrc_env.sh
   grep completed ${ENV_FILE} > /dev/null
   while [ "$?" != "0" ]; do
      log "waiting for ENV completed"
      sleep 60
      grep completed ${ENV_FILE} > /dev/null
   done
}
