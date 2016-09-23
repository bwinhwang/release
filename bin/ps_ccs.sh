#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           ps_ccs related functions
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
#
###################################################################################################

# creation of xml-file PS_CCS
function create_xml_file_ccs_sw ()
{
   local REV=`${SVN} info ${SVNCCS}/${BRANCH}/tags/${NEW_PS_CCS_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSCCSSW}
   echo "  <name>${NEW_PS_CCS_SW}</name>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <system>CCS_SW</system>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <basedOn>${PS_CCS_SW}</basedOn>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <importantNotes></importantNotes>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <repositoryUrl>${SVNCCS}</repositoryUrl>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <repositoryBranch>${BRANCH}/tags/${NEW_PS_CCS_SW}</repositoryBranch>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSCCSSW} 
   echo "  <correctedFaults></correctedFaults>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <revertedCorrectedFaults></revertedCorrectedFaults>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <baselines>" >> ${RELNOTEXMLPSCCSSW}
   echo "    <baseline name=\"GLOBAL_ENV\">${ECL_GLOBAL_ENV}</baseline>" >> ${RELNOTEXMLPSCCSSW}
   echo "    <baseline name=\"PS_ENV\">${NEW_PS_ENV}</baseline>" >> ${RELNOTEXMLPSCCSSW}
   echo "    <baseline auto_create=\"true\" name=\"ROTOLRC\">${ROTOLRC_VERSION}</baseline>" >> ${RELNOTEXMLPSCCSSW}
   echo "  </baselines>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <changenotes></changenotes>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <download>" >> ${RELNOTEXMLPSCCSSW}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_CCS\">" >> ${RELNOTEXMLPSCCSSW}
   echo "      ${SVNCCS}/${BRANCH}/tags/${NEW_PS_CCS_SW}" >> ${RELNOTEXMLPSCCSSW}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSCCSSW}
   echo "  </download>" >> ${RELNOTEXMLPSCCSSW}
   echo "  <features></features>" >> ${RELNOTEXMLPSCCSSW}
   echo "</releasenote>" >> ${RELNOTEXMLPSCCSSW}
   chmod 755 ${RELNOTEXMLPSCCSSW}
}

# creation of xml-file PS_CCS
function create_xml_file_ccs_build ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_CCS_BUILD}/PS_CCS_Information.txt"
   local BASELINES=$(getBaselinesForXml)
   local REV=`${SVN} info ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSCCSBUILD}
   echo "  <name>${NEW_PS_CCS_BUILD}</name>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <system>CCS_BUILD</system>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <basedOn>${PS_CCS_BUILD}</basedOn>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <importantNotes>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <note name=\"${NEW_PS_CCS_BUILD}\">" >> ${RELNOTEXMLPSCCSBUILD}
   cat ${RELNOTEINFO} >> ${RELNOTEXMLPSCCSBUILD}
   REMToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "      $element" >> ${RELNOTEXMLPSCCSBUILD}
   done
   echo "    </note>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </importantNotes>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <repositoryUrl>${RELEASEPSRELREPO}</repositoryUrl>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <repositoryBranch>CCS/tags/${NEW_PS_CCS_BUILD}</repositoryBranch>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <correctedFaults> " >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <module name=\"PS_CCS_BUILD\">" >> ${RELNOTEXMLPSCCSBUILD}
   PRToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSCCSBUILD}
   done 
   echo "    </module>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </correctedFaults>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <revertedCorrectedFaults>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <module name=\"PS_CCS_BUILD\">" >>  ${RELNOTEXMLPSCCSBUILD}
   for element in "${SUB[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSCCSBUILD}
   done 
   echo "    </module>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </revertedCorrectedFaults>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <baselines>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "${BASELINES}" >> ${RELNOTEXMLPSCCSBUILD}
   echo "      <baseline auto_create=\"true\" name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </baselines>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <changenotes>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <module name=\"PS_CCS_BUILD\">" >> ${RELNOTEXMLPSCCSBUILD}
   CNToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSCCSBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </changenotes>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <download>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_CCS\">" >> ${RELNOTEXMLPSCCSBUILD}
   echo "      ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </download>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  <features>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "    <module name=\"PS_CCS_BUILD\">" >> ${RELNOTEXMLPSCCSBUILD}
   NFToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSCCSBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "  </features>" >> ${RELNOTEXMLPSCCSBUILD}
   echo "</releasenote>" >> ${RELNOTEXMLPSCCSBUILD}
   chmod 755 ${RELNOTEXMLPSCCSBUILD}
}

# creation of information file
function create_information_file_ccs_build ()
{
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_CCS_BUILD}/PS_CCS_Information.txt"
   local DELIVERY_BASELINE="${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}"
   local SW_BASELINE="${SVNCCS}/${BRANCH}/tags/${NEW_PS_CCS_SW}"
   log "RELNOTEINFO:${RELNOTEINFO}"
   log "DELIVERY_BASELINE:${DELIVERY_BASELINE}"
   log "SW_BASELINE:${SW_BASELINE}"
# strings libCCS.so | sed -ne '/@(#)/ s/.*@(#)/    / p' 
   local VERSIONSTRING=`echo -e "Version string: PS_CCS_"``echo -e ${CI2RM_CCS} | sed "s/.*REL_CCS_//" | sed "s/.zip//"`
   echo "${VERSIONSTRING}" > ${RELNOTEINFO}
   echo "" >> ${RELNOTEINFO}
   echo "" >> ${RELNOTEINFO}
   chmod 755 ${RELNOTEINFO}
}

##################
# main functions #
##################

function branch_ccs_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   ${SVN} ls ${SVNSERVER}${PS_CCS_BRANCH} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_CCS_BRANCH}
   ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_CCS} ${SVNSERVER}${PS_CCS_BRANCH} ||
     ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_CCS} ${SVNSERVER}${PS_CCS_BRANCH} ||
     fatal "svn cp ${SVNSERVER}${ECL_CCS} ${SVNSERVER}${PS_CCS_BRANCH} failed"
   log "DONE"
}

function define_ccs_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   checkChanges ${SVNCCS} ${PS_CCS_BRANCH} ${PS_CCS_SW}
   if [ "${DIFFERENCE}" != "0" ]; then
      defineTag ${SVNCCS} ${PS_CCS_SW}
      NEW_PS_CCS_SW=${UNUSEDTAG}
      NEW_BRANCH_PS_CCS_SW=${BRANCH}
   else
      log "no new ps_ccs_sw needed"
      NEW_PS_CCS_SW=${PS_CCS_SW}
      for NEW_BRANCH_PS_CCS_SW in ${BRANCHES} ; do
         ${SVN} ls ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW} 1>/dev/null 2>/dev/null && break
      done
      ${SVN} ls ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW} 1>/dev/null 2>/dev/null ||
        fatal "${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW} does not exist in subversion";
   fi
   echo "NEW_BRANCH_PS_CCS_SW=${NEW_BRANCH_PS_CCS_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   echo "NEW_PS_CCS_SW=${NEW_PS_CCS_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_ccs_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_CCS_SW}" != "${PS_CCS_SW}" ]]; then
      tagIt ${SVNCCS} ${PS_CCS_BRANCH} ${NEW_PS_CCS_SW}
      if [[ "${BRANCH}" == "MAINBRANCH" ]] ; then
         wget --no-check-certificate "https://10.151.15.201/job/TOOL_UPDATE_CCS_SPEC/buildWithParameters?token=PSWEB&CCS_SW_TAG=${NEW_PS_CCS_SW}"
      fi
   fi
   log "DONE"
}

function define_ccs_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local OLD_VERSION=`${SVN} cat ${BASEPSRELREPO}/CCS/tags/${PS_CCS_BUILD}/.version` || fatal "svn cat failed"
   findFile ${CI2RM_CCS}
   local NEW_VERSION=${ORIGFILE}
   if [[ "${NEW_VERSION}" != "${OLD_VERSION}" || "${BASEPSRELREPO}" != "${RELEASEPSRELREPO}" ]]; then
      defineTag ${BASEPSRELREPO} ${PS_CCS_BUILD} CCS
      NEW_PS_CCS_BUILD=${UNUSEDTAG}
   else
      log "no new ps_ccs_build needed"
      NEW_PS_CCS_BUILD=${PS_CCS_BUILD}
   fi
   echo "NEW_PS_CCS_BUILD=${NEW_PS_CCS_BUILD}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_ccs_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [ "${NEW_PS_CCS_BUILD}" != "${PS_CCS_BUILD}" ]; then
      unzipComponent ${CI2RM_CCS} ${NEW_PS_CCS_BUILD}
      ${SVN} info ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW} > ${RELEASEDIR}/${RELEASE}/${NEW_PS_CCS_BUILD}/C_Platform/CCS/svninfo.txt || fatal "svn info failed"
# workaround
      for i in `find ${RELEASEDIR}/${RELEASE}/${NEW_PS_CCS_BUILD} -type f -name CCS*Exe` ; do
         chmod +x $i
      done
# workaround
      importAndTagIt ${RELEASEPSRELREPO}/CCS ${NEW_PS_CCS_BUILD}
   fi
   log "DONE"
}

# create PS_CCS output files
function create_output_files_ccs_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   check_env_completed
   if [[ "${NEW_PS_CCS_SW}" != "${PS_CCS_SW}" ]]; then
      local RELNOTEXMLPSCCSSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_SW}.xml"
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      create_xml_file_ccs_sw
      local REVISIONNUMBER=`echo -e ${CI2RM_CCS} | sed "s/.*_//" | sed "s/.zip//"`
#      mysql --host="ulccsdb01.emea.nsn-net.net" --user="ccsweb" --password="f236b6ba" PS_CI_RELEASES 2>&1 <<EOF
#update Promotions SET  ccstag="${NEW_PS_CCS_SW}" where branch="${BRANCH}" and revision="${REVISIONNUMBER}"
#EOF
   fi
   log "DONE"
}

# trigger WFT PS_CCS
function trigger_wft_ccs_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSCCSSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_SW}.xml"
   triggerWft ${PS_CCS_SW} ${NEW_PS_CCS_SW} "" ${RELNOTEXMLPSCCSSW}
   log "DONE"
}

# create PS_CCS output files
function create_output_files_ccs_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_CCS_BUILD}" != "${PS_CCS_BUILD}" ]]; then
      local RELNOTEXMLPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.xml"
      local RELNOTEHTMLPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.html"
      local RELNOTETXTPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.txt"
      getLogInfo ${SVNCCS} ${NEW_PS_CCS_SW} ${PS_CCS_SW}      # result will be copied to 'CI_COMMENTS'
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      createTxtFile ${NEW_PS_CCS_SW} ${PS_CCS_SW} ${RELNOTETXTPSCCSBUILD} 
      create_information_file_ccs_build
      create_xml_file_ccs_build
      createHtmlFile ${RELNOTEXMLPSCCSBUILD} ${RELNOTEHTMLPSCCSBUILD}
   fi
   log "DONE"
}

# trigger WFT PS_CCS
function trigger_wft_ccs_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.xml"
   local RELNOTEHTMLPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.html"
   local RELNOTETXTPSCCSBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_CCS_BUILD}.txt"
#   if [[ "${BRANCH}" == "2012_02_WCDMA" ]]; then
#      triggerWft ${PS_CCS_BUILD} ${NEW_PS_CCS_BUILD} testing ${RELNOTEXMLPSCCSBUILD} ${RELNOTETXTPSCCSBUILD} ${RELNOTEHTMLPSCCSBUILD}
#   else
      triggerWft ${PS_CCS_BUILD} ${NEW_PS_CCS_BUILD} "" ${RELNOTEXMLPSCCSBUILD} ${RELNOTETXTPSCCSBUILD} ${RELNOTEHTMLPSCCSBUILD}
#   fi
   log "DONE"
}

# send mail
function send_mail_ccs ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_CCS_BUILD}" != "${PS_CCS_BUILD}" ]]; then
      FORSCT=
      SUB="CCS Release ${NEW_PS_CCS_BUILD} is ready ${FORSCT}for ${RELEASE}"
      FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
      REPLYTO="scm-ps-prod@mlist.emea.nsn-intra.net"
      TO="scm-ps-int@mlist.emea.nsn-intra.net"
      CC="scm-ps-prod@mlist.emea.nsn-intra.net"
      MSG="Dear Colleagues,

The CCS release ${NEW_PS_CCS_BUILD} is now available. Target PS release: ${RELEASE}

Sources:
${SVNCCS}/${BRANCH}/tags/${NEW_PS_CCS_SW}
(or ${SVNSERVER}${ECL_CCS})

Binaries:
${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}
(or ${CI2RM_CCS})

Interfaces:
${SVNENV}/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}
${SNVGLOBAL}/tags/${ECL_GLOBAL_ENV}

CI2RM:
${CI2RM}

ECL:
${SVNSERVER}${CI2RM_ECL}

Detailed information is stored in the Work Flow Tool:
${WFT_SHOW}/${NEW_PS_CCS_BUILD}

Best regards
PS SCM"
      ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"
   fi
   log "DONE"
}

function check_ccs ()
{
   log "STARTED"
local CCS_FILE=${RELEASEDIR}/${RELEASE}/config_ps_rotolrc_ccs.sh
   while [ ! -r "${CCS_FILE}" ]; do 
      log "waiting for ${CCS_FILE}"
      sleep 60
   done
   source ${CCS_FILE}
   [ -z "${NEW_BRANCH_PS_CCS_SW}" ] && fatal "NEW_BRANCH_PS_CCS_SW not defined"
   [ -z "${NEW_PS_CCS_SW}" ] && fatal "NEW_PS_CCS_SW not defined"
   while [ -z "${NEW_PS_CCS_BUILD}" ]; do
      log "waiting for NEW_PS_CCS_BUILD within ${CCS_FILE}"
      sleep 60
      source ${CCS_FILE}
   done
   log "DONE"
}

function check_ccs_completed ()
{
local CCS_FILE=${RELEASEDIR}/${RELEASE}/fctptr_ps_rotolrc_ccs.sh
   grep completed ${CCS_FILE} > /dev/null
   while [ "$?" != "0" ]; do
      log "waiting for CCS completed"
      sleep 60
      grep completed ${CCS_FILE} > /dev/null
   done
}
