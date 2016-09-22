#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           ps_mcu related functions
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
#
###################################################################################################

# creation of xml-file PS_MCU
function create_xml_file_mcu_sw ()
{
   local REV=`${SVN} info ${SVNMCU}/${BRANCH}/tags/${NEW_PS_MCU_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSMCUSW}
   echo "  <name>${NEW_PS_MCU_SW}</name>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <system>MCU_SW</system>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <basedOn>${PS_MCU_SW}</basedOn>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <importantNotes></importantNotes>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <repositoryUrl>${SVNMCU}</repositoryUrl>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <repositoryBranch>${BRANCH}/tags/${NEW_PS_MCU_SW}</repositoryBranch>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <correctedFaults></correctedFaults>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <baselines>" >> ${RELNOTEXMLPSMCUSW}
   echo "    <baseline name=\"GLOBAL_ENV\">${ECL_GLOBAL_ENV}</baseline>" >> ${RELNOTEXMLPSMCUSW}
   echo "    <baseline name=\"PS_ENV\">${NEW_PS_ENV}</baseline>" >> ${RELNOTEXMLPSMCUSW}
   echo "    <baseline name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>" >> ${RELNOTEXMLPSMCUSW}
   echo "    <baseline auto_create=\"true\" name=\"ROTOLRC\">${ROTOLRC_VERSION}</baseline>" >> ${RELNOTEXMLPSMCUSW}
   echo "  </baselines>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <changenotes></changenotes>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <download>" >> ${RELNOTEXMLPSMCUSW}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_MCU\">" >> ${RELNOTEXMLPSMCUSW}
   echo "      ${SVNMCU}/${BRANCH}/tags/${NEW_PS_MCU_SW}" >> ${RELNOTEXMLPSMCUSW}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSMCUSW}
   echo "  </download>" >> ${RELNOTEXMLPSMCUSW}
   echo "  <features></features>" >> ${RELNOTEXMLPSMCUSW}
   echo "</releasenote>" >> ${RELNOTEXMLPSMCUSW}
   chmod 755 ${RELNOTEXMLPSMCUSW}
}

# creation of xml-file PS_MCU
function create_xml_file_mcu_build ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_MCU_BUILD}/PS_MCUHWAPI_Information.txt"
   local BASELINES=$(getBaselinesForXml)
   local REV=`${SVN} info ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSMCUBUILD}
   echo "  <name>${NEW_PS_MCU_BUILD}</name>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <system>PS_MCUHWAPI_BUILD</system>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <basedOn>${PS_MCU_BUILD}</basedOn>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <importantNotes>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <note name=\"${NEW_PS_MCU_BUILD}\">" >> ${RELNOTEXMLPSMCUBUILD}
   cat ${RELNOTEINFO} >> ${RELNOTEXMLPSMCUBUILD}
   REMToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "      $element" >> ${RELNOTEXMLPSMCUBUILD}
   done
   echo "    </note>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </importantNotes>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <repositoryUrl>${RELEASEPSRELREPO}</repositoryUrl>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <repositoryBranch>MCUHWAPI/tags/${NEW_PS_MCU_BUILD}</repositoryBranch>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <correctedFaults> " >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <module name=\"PS_MCUHWAPI_BUILD\">" >> ${RELNOTEXMLPSMCUBUILD}
   PRToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSMCUBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </correctedFaults>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <revertedCorrectedFaults>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <module name=\"PS_MCUHWAPI_BUILD\">" >>  ${RELNOTEXMLPSMCUBUILD}
   for element in "${SUB[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSMCUBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </revertedCorrectedFaults>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <baselines>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "${BASELINES}" >> ${RELNOTEXMLPSMCUBUILD}
   echo "      <baseline name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "      <baseline name=\"CCS_BUILD\">${NEW_PS_CCS_BUILD}</baseline>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "      <baseline auto_create=\"true\" name=\"PS_MCUHWAPI_SW\">${NEW_PS_MCU_SW}</baseline>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </baselines>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <changenotes>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <module name=\"PS_MCUHWAPI_BUILD\">" >> ${RELNOTEXMLPSMCUBUILD}
   CNToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSMCUBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </changenotes>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <download>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_MCU\">" >> ${RELNOTEXMLPSMCUBUILD}
   echo "      ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </download>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  <features>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "    <module name=\"PS_MCUHWAPI_BUILD\">" >> ${RELNOTEXMLPSMCUBUILD}
   NFToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSMCUBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "  </features>" >> ${RELNOTEXMLPSMCUBUILD}
   echo "</releasenote>" >> ${RELNOTEXMLPSMCUBUILD}
   chmod 755 ${RELNOTEXMLPSMCUBUILD}
}

# creation of information file
function create_information_file_mcu_build ()
{
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_MCU_BUILD}/PS_MCUHWAPI_Information.txt"
   local DELIVERY_BASELINE="${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}"
   local SW_BASELINE="${SVNMCU}/${BRANCH}/tags/${NEW_PS_MCU_SW}"
   log "RELNOTEINFO:${RELNOTEINFO}"
   log "DELIVERY_BASELINE:${DELIVERY_BASELINE}"
   log "SW_BASELINE:${SW_BASELINE}"
   local VERSIONSTRING=`echo -e "Version string: BTS_SC_MCUHWAPI_${BRANCH}-trunk@"``echo -e ${ECL_MCUHWAPI} | sed "s/.*@//"`
   echo "${VERSIONSTRING}" > ${RELNOTEINFO}
   echo "" >> ${RELNOTEINFO}
   echo "" >> ${RELNOTEINFO}
   chmod 755 ${RELNOTEINFO}
}

##################
# main functions #
##################

function branch_mcu_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   ${SVN} ls ${SVNSERVER}${PS_MCU_BRANCH} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_MCU_BRANCH}
   ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_MCUHWAPI} ${SVNSERVER}${PS_MCU_BRANCH} ||
     ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_MCUHWAPI} ${SVNSERVER}${PS_MCU_BRANCH} ||
     fatal "svn cp ${SVNSERVER}${ECL_MCUHWAPI} ${SVNSERVER}${PS_MCU_BRANCH} failed"
   ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_MCU_BRANCH}/ECL || warn "svn rm ${SVNSERVER}${PS_MCU_BRANCH}/ECL failed"
   log "DONE"
}

function define_mcu_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   checkChanges ${SVNMCU} ${PS_MCU_BRANCH} ${PS_MCU_SW}
   if [ "${DIFFERENCE}" != "0" ]; then
      defineTag ${SVNMCU} ${PS_MCU_SW}
      NEW_PS_MCU_SW=${UNUSEDTAG}
      NEW_BRANCH_PS_MCU_SW=${BRANCH}
   else
      log "no new ps_mcu_sw needed"
      NEW_PS_MCU_SW=${PS_MCU_SW}
      for NEW_BRANCH_PS_MCU_SW in ${BRANCHES} ; do
         ${SVN} ls ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW} 1>/dev/null 2>/dev/null && break
      done
      ${SVN} ls ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW} 1>/dev/null 2>/dev/null ||
        fatal "${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW} does not exist in subversion";
   fi
   echo "NEW_BRANCH_PS_MCU_SW=${NEW_BRANCH_PS_MCU_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   echo "NEW_PS_MCU_SW=${NEW_PS_MCU_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}
 
function tag_mcu_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_MCU_SW}" != "${PS_MCU_SW}" ]]; then
      tagIt ${SVNMCU} ${PS_MCU_BRANCH} ${NEW_PS_MCU_SW}
   fi
   log "DONE"
}

function define_mcu_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local OLD_VERSION=`${SVN} cat ${BASEPSRELREPO}/MCUHWAPI/tags/${PS_MCU_BUILD}/.version` || fatal "svn cat failed"
   findFile ${CI2RM_MCU}
   local NEW_VERSION=${ORIGFILE}
   if [[ "${NEW_VERSION}" != "${OLD_VERSION}" || "${BASEPSRELREPO}" != "${RELEASEPSRELREPO}" ]]; then
      defineTag ${BASEPSRELREPO} ${PS_MCU_BUILD} MCUHWAPI
      NEW_PS_MCU_BUILD=${UNUSEDTAG}
   else
      log "no new ps_mcu_build needed"
      NEW_PS_MCU_BUILD=${PS_MCU_BUILD}
   fi
   echo "NEW_PS_MCU_BUILD=${NEW_PS_MCU_BUILD}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_mcu_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [ "${NEW_PS_MCU_BUILD}" != "${PS_MCU_BUILD}" ]; then
      unzipComponent ${CI2RM_MCU} ${NEW_PS_MCU_BUILD}
      ${SVN} info ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW} > ${RELEASEDIR}/${RELEASE}/${NEW_PS_MCU_BUILD}/C_Platform/MCUHWAPI/svninfo.txt
      importAndTagIt ${RELEASEPSRELREPO}/MCUHWAPI ${NEW_PS_MCU_BUILD}
   fi
   log "DONE"
}

# create PS_MCU output files
function create_output_files_mcu_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_MCU_BUILD}" != "${PS_MCU_BUILD}" ]]; then
      local RELNOTEXMLPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.xml"
      local RELNOTEHTMLPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.html"
      local RELNOTETXTPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.txt"
      getLogInfo ${SVNMCU} ${NEW_PS_MCU_SW} ${PS_MCU_SW}      # result will be copied to 'CI_COMMENTS'
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      createTxtFile ${NEW_PS_MCU_SW} ${PS_MCU_SW} ${RELNOTETXTPSMCUBUILD} 
      create_information_file_mcu_build
      create_xml_file_mcu_build
      createHtmlFile ${RELNOTEXMLPSMCUBUILD} ${RELNOTEHTMLPSMCUBUILD}
   fi
   log "DONE"
}

# create PS_MCU output files
function create_output_files_mcu_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   check_env_completed
   check_ccs_completed
   if [[ "${NEW_PS_MCU_SW}" != "${PS_MCU_SW}" ]]; then
      local RELNOTEXMLPSMCUSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_SW}.xml"
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      create_xml_file_mcu_sw
   fi
   log "DONE"
}

# trigger WFT PS_MCU
function trigger_wft_mcu_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSMCUSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_SW}.xml"
   triggerWft ${PS_MCU_SW} ${NEW_PS_MCU_SW} "" ${RELNOTEXMLPSMCUSW}
   log "DONE"
}

# trigger WFT PS_MCU
function trigger_wft_mcu_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.xml"
   local RELNOTEHTMLPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.html"
   local RELNOTETXTPSMCUBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_MCU_BUILD}.txt"
   local TESTING=""
   [[ "${BRANCH}" == "MAINBRANCH" || "${BRANCH}" == "MAINBRANCH_LRC" ]] && TESTING="YES"
   [[ "${FAST}" == "fast_track" ]] && TESTING="YES"
   triggerWft ${PS_MCU_BUILD} ${NEW_PS_MCU_BUILD} "${TESTING}" ${RELNOTEXMLPSMCUBUILD} ${RELNOTETXTPSMCUBUILD} ${RELNOTEHTMLPSMCUBUILD}
   log "DONE"
}

# send mail
function send_mail_mcu ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_MCU_BUILD}" != "${PS_MCU_BUILD}" ]]; then
      local MCU_TEST=`echo -e ${CI2RM_MCU} | sed "s/MCU_LIBS_/MCU_TEST_/"`

      local BWFILES=
      for i in `${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/MCUHWAPI/Bin` ; do
         for j in `${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/MCUHWAPI/Bin/${i} | grep "MC-B"` ; do
            ${SVN} ls ${BASEPSRELREPO}/MCUHWAPI/tags/${PS_MCU_BUILD}/C_Platform/MCUHWAPI/Bin/${i}/${j} 1>/dev/null 2>/dev/null ||
              BWFILES="New boot binary: ${j}
${BWFILES}"
         done
      done
      if [[ -z ${BWFILES} ]] ; then
         BWFILES="No new boot binaries
"
      fi

      local FORSCT=
      [[ "${BRANCH}" == "MAINBRANCH" ]] && FORSCT="for SCT "
      [[ "${FAST}" == "fast_track" ]] && FORSCT="for SCT (Fast Track) "

      SUB="MCUHWAPI Release ${NEW_PS_MCU_BUILD} is ready ${FORSCT}for ${RELEASE}"
      FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
      REPLYTO="scm-ps-prod@mlist.emea.nsn-intra.net"
      TO="scm-ps-int@mlist.emea.nsn-intra.net"
      CC="scm-ps-prod@mlist.emea.nsn-intra.net"
      MSG="Dear Colleagues,

The MCUHWAPI release ${NEW_PS_MCU_BUILD} is now available. Target PS release: ${RELEASE}

Sources:
${SVNMCU}/${BRANCH}/tags/${NEW_PS_MCU_SW}
(or ${SVNSERVER}${ECL_MCUHWAPI})

Binaries:
${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}
(or ${CI2RM_MCU})

Test Binaries:
${MCU_TEST}

${BWFILES}
Interfaces:
${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}
${SNVGLOBAL}/tags/${ECL_GLOBAL_ENV}

CCS:
${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}
(or ${CI2RM_CCS})

CI2RM:
${CI2RM}

ECL:
${SVNSERVER}${CI2RM_ECL}

Detailed information is stored in the Work Flow Tool:
${WFT_SHOW}/${NEW_PS_MCU_BUILD}

Best regards
PS SCM"
      ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"
   fi
   log "DONE"
}

function check_mcu ()
{
   log "STARTED"
   local MCU_FILE=${RELEASEDIR}/${RELEASE}/config_ps_ROTOLRC_mcu.sh
   while [ ! -r "${MCU_FILE}" ]; do
      log "waiting for ${MCU_FILE}"
      sleep 60
   done
   source ${MCU_FILE}
   [ -z "${NEW_BRANCH_PS_MCU_SW}" ] && fatal "NEW_BRANCH_PS_MCU_SW not defined"
   [ -z "${NEW_PS_MCU_SW}" ] && fatal "NEW_PS_MCU_SW not defined"
   while [ -z "${NEW_PS_MCU_BUILD}" ]; do
      log "waiting for NEW_PS_MCU_BUILD within ${MCU_FILE}"
      sleep 60
      source ${MCU_FILE}
   done 
   log "DONE"
}

function check_mcu_completed ()
{
   local MCU_FILE=${RELEASEDIR}/${RELEASE}/fctptr_ps_ROTOLRC_mcu.sh
   grep completed ${MCU_FILE} > /dev/null
   while [ "$?" != "0" ]; do
      log "waiting for MCU completed"
      sleep 60
      grep completed ${MCU_FILE} > /dev/null
   done
}
