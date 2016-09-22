#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           ps_dsp related functions
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
#
###################################################################################################

# creation of xml-file PS_DSP
function create_xml_file_dsp_sw ()
{
   local REV=`${SVN} info ${SVNDSP}/${BRANCH}/tags/${NEW_PS_DSP_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSDSPSW}
   echo "  <name>${NEW_PS_DSP_SW}</name>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <system>DSP_SW</system>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <basedOn>${PS_DSP_SW}</basedOn>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <importantNotes></importantNotes>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <repositoryUrl>${SVNDSP}</repositoryUrl>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <repositoryBranch>${BRANCH}/tags/${NEW_PS_DSP_SW}</repositoryBranch>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSDSPSW} 
   echo "  <correctedFaults></correctedFaults>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <baselines>" >> ${RELNOTEXMLPSDSPSW}
   echo "    <baseline name=\"GLOBAL_ENV\">${ECL_GLOBAL_ENV}</baseline>" >> ${RELNOTEXMLPSDSPSW}
   echo "    <baseline name=\"PS_ENV\">${NEW_PS_ENV}</baseline>" >> ${RELNOTEXMLPSDSPSW}
   echo "    <baseline name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>" >> ${RELNOTEXMLPSDSPSW}
   echo "    <baseline auto_create=\"true\" name=\"ROTOLRC\">${ROTOLRC_VERSION}</baseline>" >> ${RELNOTEXMLPSDSPSW}
   echo "  </baselines>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <changenotes></changenotes>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <download>" >> ${RELNOTEXMLPSDSPSW}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_DSP\">" >> ${RELNOTEXMLPSDSPSW}
   echo "      ${SVNDSP}/${BRANCH}/tags/${NEW_PS_DSP_SW}" >> ${RELNOTEXMLPSDSPSW}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSDSPSW}
   echo "  </download>" >> ${RELNOTEXMLPSDSPSW}
   echo "  <features></features>" >> ${RELNOTEXMLPSDSPSW}
   echo "</releasenote>" >> ${RELNOTEXMLPSDSPSW}
   chmod 755 ${RELNOTEXMLPSDSPSW}
}

# updating the DSPHWAPI text files
# PS_DSPHWAPI_Faraday.txt PS_DSPHWAPI_Nyquist.txt
function create_txt_file_dsp_build ()
{
   local FNAME1=PS_DSPHWAPI_Faraday.txt
   local FNAME2=PS_DSPHWAPI_Nyquist.txt
   local DIR="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/Documents"
   local FILE1="${DIR}/${FNAME1}" 
   local FILE2="${DIR}/${FNAME2}"
   local PUBLISHER=${USER}
   local DATE_NOW=`date +%Y-%m-%d`
   local TEMP
   log "FILE1: ${FILE1}"
   log "FILE2: ${FILE2}"
   mkdir ${DIR} 
   ${SVN} ls ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME1} || fatal "file ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME1} not found"

   TEMP=`${SVN} cat ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME1}` || fatal "svn cat failed"
   echo "${TEMP}" > ${FILE1}
   ${SVN} ls ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME2} || fatal "file ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME2} not found"

   TEMP=`${SVN} cat ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/Documents/${FNAME2}` || fatal "svn cat failed"
   echo "${TEMP}" > ${FILE2}
   sed -i "s/RM_NEW_PS_DSP_BUILD_RM/${NEW_PS_DSP_BUILD}/" ${FILE1} ${FILE2}
   sed -i "s/RM_DATE_RM/${DATE_NOW}/" ${FILE1} ${FILE2}
   sed -i "s/RM_PUBLISHER_RM/${PUBLISHER}/" ${FILE1} ${FILE2}
   sed -i "s/RM_RELEASE_RM/${RELEASE}/" ${FILE1} ${FILE2}
   sed -i "s/RM_PS_DSP_BUILD_RM/${PS_DSP_BUILD}/" ${FILE1} ${FILE2}
}

# creation of xml-file PS_DSP
function create_xml_file_dsp_build ()
{
   declare -a ADD     # all new entries (finished PR/NF/CN)
   declare -a SUB     # all new entries (RollBack PR)
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/PS_DSPHWAPI_Information.txt"
   local BASELINES=$(getBaselinesForXml)
   local REV=`${SVN} info ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo "<releasenote version=\"${XML_SCHEMA}\">" > ${RELNOTEXMLPSDSPBUILD}
   echo "  <name>${NEW_PS_DSP_BUILD}</name>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <system>PS_DSPHWAPI_BUILD</system>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <releaseDate>${DATE_NOW}</releaseDate>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <releaseTime>${TIME_NOW}</releaseTime>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <basedOn>${PS_DSP_BUILD}</basedOn>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <importantNotes>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <note name=\"${NEW_PS_DSP_BUILD}\">" >> ${RELNOTEXMLPSDSPBUILD}
   REMToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "      $element" >> ${RELNOTEXMLPSDSPBUILD}
   done
   cat ${RELNOTEINFO} >> ${RELNOTEXMLPSDSPBUILD}
   echo "    </note>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </importantNotes>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <repositoryUrl>${RELEASEPSRELREPO}</repositoryUrl>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <repositoryBranch>DSPHWAPI/tags/${NEW_PS_DSP_BUILD}</repositoryBranch>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <repositoryRevision>${REV}</repositoryRevision>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <repositoryType>svn</repositoryType>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <correctedFaults>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <module name=\"PS_DSPHWAPI_BUILD\">" >> ${RELNOTEXMLPSDSPBUILD}
   PRToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSDSPBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </correctedFaults>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <revertedCorrectedFaults>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <module name=\"PS_DSPHWAPI_BUILD\">" >>  ${RELNOTEXMLPSDSPBUILD}
   for element in "${SUB[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSDSPBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </revertedCorrectedFaults>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <baselines>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "${BASELINES}" >> ${RELNOTEXMLPSDSPBUILD}
   echo "      <baseline name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "      <baseline name=\"CCS_BUILD\">${NEW_PS_CCS_BUILD}</baseline>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "      <baseline auto_create=\"true\" name=\"PS_DSPHWAPI_SW\">${NEW_PS_DSP_SW}</baseline>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </baselines>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <notes></notes>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <changenotes>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <module name=\"PS_DSPHWAPI_BUILD\">" >> ${RELNOTEXMLPSDSPBUILD}
   CNToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSDSPBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </changenotes>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <unsupportedFeatures></unsupportedFeatures>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <restrictions></restrictions>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <download>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <downloadItem storage=\"SVN\" name=\"SC_DSP\">" >> ${RELNOTEXMLPSDSPBUILD}
   echo "      ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    </downloadItem>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </download>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  <features>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "    <module name=\"PS_DSPHWAPI_BUILD\">" >> ${RELNOTEXMLPSDSPBUILD}
   NFToXml "${CI_COMMENTS}"
   for element in "${ADD[@]}"; do
      echo "${element}" >> ${RELNOTEXMLPSDSPBUILD}
   done
   echo "    </module>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "  </features>" >> ${RELNOTEXMLPSDSPBUILD}
   echo "</releasenote>" >> ${RELNOTEXMLPSDSPBUILD}
   chmod 755 ${RELNOTEXMLPSDSPBUILD}
}

# creation of information file
function create_information_file_dsp_build ()
{
   local RELNOTEINFO="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/PS_DSPHWAPI_Information.txt"
   local DELIVERY_BASELINE="${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}"
   local SW_BASELINE="${SVNDSP}/${BRANCH}/tags/${NEW_PS_DSP_SW}"
   log "RELNOTEINFO:${RELNOTEINFO}"
   log "DELIVERY_BASELINE:${DELIVERY_BASELINE}"
   log "SW_BASELINE:${SW_BASELINE}"
   local VERSIONSTRING=`echo -e "Version string: BTS_SC_DSPHWAPI_${BRANCH}-trunk@"``echo -e ${ECL_UPHWAPI} | sed "s/.*@//"`
   echo "${VERSIONSTRING}" > ${RELNOTEINFO}
   echo " " >> ${RELNOTEINFO}
   echo "Notes for changes in DSPHWAPI_BUILD regarding Common Tools, Faraday and Nyquist 
are no more explicitly supported in Important Notes.
Please find the information directly in the DSPHWAPI_BUILD delivery in WFT or SVN. " >> ${RELNOTEINFO}
   echo " " >> ${RELNOTEINFO}
   chmod 755 ${RELNOTEINFO}
}

##################
# main functions #
##################

function branch_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   ${SVN} ls ${SVNSERVER}${PS_DSP_BRANCH} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_DSP_BRANCH}
   ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_UPHWAPI} ${SVNSERVER}${PS_DSP_BRANCH} ||
     ${TEST} ${SVN} cp --parents -m "${ROTOLRC_VERSION}" ${SVNSERVER}${ECL_UPHWAPI} ${SVNSERVER}${PS_DSP_BRANCH} ||
     fatal "svn cp ${SVNSERVER}${ECL_UPHWAPI} ${SVNSERVER}${PS_DSP_BRANCH} failed"
   ${TEST} ${SVN} rm -m "${ROTOLRC_VERSION}" ${SVNSERVER}${PS_DSP_BRANCH}/ECL || warn "svn rm ${SVNSERVER}${PS_DSP_BRANCH}/ECL failed"
   log "DONE"
}

function create_externals_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local SRC=${SVNSERVER}${PS_DSP_BRANCH}
   if [[ "`${SVN} pg svn:externals ${SRC} | wc -l`" != "0" ]]; then 
      # only for old branches with externals
      local FILE=${RELEASEDIR}/${RELEASE}/dsp_sw_externals.txt
      local DST=${RELEASEDIR}/${RELEASE}/branch_dsp
   
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
      echo "/isource/svnroot/BTS_I_PS/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}/I_Interface/Platform_Env/Messages I_Interface/Platform_Env/Messages" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}/I_Interface/Platform_Env/Definitions I_Interface/Platform_Env/Definitions" >> ${FILE}
      echo "/isource/svnroot/BTS_I_PS/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}/I_Interface/Platform_Env/CCS_ENV I_Interface/Platform_Env/CCS_ENV" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/CCS_COTS CCS_COTS" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/CCS_Daemon CCS_Daemon" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/CCS_Services CCS_Services" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_CCS/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/CCS_TestCases CCS_TestCases" >> ${FILE}
      echo "" >> ${FILE}
      echo "/isource/svnroot/BTS_SC_MCUHWAPI/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW}/HWR/Mit Tools/common/Mit" >> ${FILE}
   
      ${SVN} co --non-recursive ${SRC} ${DST}
      ${SVN} propset svn:externals ${DST} -F ${FILE} || fatal "set properties 'svn:externals' failed for ${DST}"
      ${SVN} ci -m "${ROTOLRC_VERSION}" ${DST} || fatal "svn ci failed"
   fi
   log "DONE"
}

function define_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   checkChanges ${SVNDSP} ${PS_DSP_BRANCH} ${PS_DSP_SW}
   if [ "${DIFFERENCE}" != "0" ]; then
      defineTag ${SVNDSP} ${PS_DSP_SW}
      NEW_PS_DSP_SW=${UNUSEDTAG}
      NEW_BRANCH_PS_DSP_SW=${BRANCH}
   else
      log "no new ps_dsp_sw needed"
      NEW_PS_DSP_SW=${PS_DSP_SW}
      for NEW_BRANCH_PS_DSP_SW in ${BRANCHES} ; do
         ${SVN} ls ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW} 1>/dev/null 2>/dev/null && break
      done
      ${SVN} ls ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW} 1>/dev/null 2>/dev/null ||
        fatal "${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW} does not exist in subversion";
   fi
   echo "NEW_BRANCH_PS_DSP_SW=${NEW_BRANCH_PS_DSP_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   echo "NEW_PS_DSP_SW=${NEW_PS_DSP_SW}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_DSP_SW}" != "${PS_DSP_SW}" ]]; then
      tagIt ${SVNDSP} ${PS_DSP_BRANCH} ${NEW_PS_DSP_SW}
   fi
   log "DONE"
}

function define_dsp_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local OLD_VERSION=`${SVN} cat ${BASEPSRELREPO}/DSPHWAPI/tags/${PS_DSP_BUILD}/.version` || fatal "svn cat failed"

   findFile ${CI2RM_DSP}
   local NEW_VERSION=${ORIGFILE}
   if [[ "${NEW_VERSION}" != "${OLD_VERSION}" || "${BASEPSRELREPO}" != "${RELEASEPSRELREPO}" ]]; then
      defineTag ${BASEPSRELREPO} ${PS_DSP_BUILD} DSPHWAPI
      NEW_PS_DSP_BUILD=${UNUSEDTAG}
   else
      log "no new ps_dsp_build needed"
      NEW_PS_DSP_BUILD=${PS_DSP_BUILD}
   fi
   echo "NEW_PS_DSP_BUILD=${NEW_PS_DSP_BUILD}" >> ${CONFIG_FILE} || fatal "${CONFIG_FILE} not writable"
   log "DONE"
}

function tag_dsp_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [ "${NEW_PS_DSP_BUILD}" != "${PS_DSP_BUILD}" ]; then
      unzipComponent ${CI2RM_DSP} ${NEW_PS_DSP_BUILD}
# todo      create_txt_file_dsp_build
      ${SVN} info ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW} > ${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/svninfo.txt
      importAndTagIt ${RELEASEPSRELREPO}/DSPHWAPI ${NEW_PS_DSP_BUILD}
   fi
   log "DONE"
}

# create PS_DSP output files
function create_output_files_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   check_env_completed
   check_ccs_completed
   if [[ "${NEW_PS_DSP_SW}" != "${PS_DSP_SW}" ]]; then
      local RELNOTEXMLPSDSPSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_SW}.xml"
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      create_xml_file_dsp_sw
   fi
   log "DONE"
}

# trigger WFT PS_DSP
function trigger_wft_dsp_sw ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSDSPSW="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_SW}.xml"
   triggerWft ${PS_DSP_SW} ${NEW_PS_DSP_SW} "" ${RELNOTEXMLPSDSPSW}
   log "DONE"
}

# create PS_DSP output files
function create_output_files_dsp_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_DSP_BUILD}" != "${PS_DSP_BUILD}" ]]; then
      local RELNOTEXMLPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.xml"
      local RELNOTEHTMLPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.html"
      local RELNOTETXTPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.txt"
      getLogInfo ${SVNDSP} ${NEW_PS_DSP_SW} ${PS_DSP_SW}      # result will be copied to 'CI_COMMENTS'
      local DATE_NOW=`date +%Y-%m-%d`
      local TIME_NOW=`date +%H:%M:%SZ -u`
      createTxtFile ${NEW_PS_DSP_SW} ${PS_DSP_SW} ${RELNOTETXTPSDSPBUILD} 
      create_information_file_dsp_build
      create_xml_file_dsp_build
      createHtmlFile ${RELNOTEXMLPSDSPBUILD} ${RELNOTEHTMLPSDSPBUILD}
   fi
   log "DONE"
}

# trigger WFT PS_DSP
function trigger_wft_dsp_build ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local RELNOTEXMLPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.xml"
   local RELNOTEHTMLPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.html"
   local RELNOTETXTPSDSPBUILD="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_DSP_BUILD}.txt"
   local PSDSPHWAPIFARADAY="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/Documents/PS_DSPHWAPI_Faraday.txt"
   local PSDSPHWAPINYQUIST="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/Documents/PS_DSPHWAPI_Nyquist.txt"
   local RELNOTEINFOPSDSP="${RELEASEDIR}/${RELEASE}/${NEW_PS_DSP_BUILD}/PS_DSPHWAPI_Information.txt"
   local TESTING="YES"
   [[ "${BRANCH}" =~ "20M[0-9]_" || "${BRANCH}" == "FB1304_DND30" ]] && TESTING="" 
   [[ "${FAST}" == "fast_track" ]] && TESTING="YES"
   triggerWft ${PS_DSP_BUILD} ${NEW_PS_DSP_BUILD} "${TESTING}" ${RELNOTEXMLPSDSPBUILD} ${RELNOTETXTPSDSPBUILD} ${RELNOTEHTMLPSDSPBUILD} ${PSDSPHWAPIFARADAY} ${PSDSPHWAPINYQUIST} ${RELNOTEINFOPSDSP}
   log "DONE"
}

# send mail
function send_mail_dsp ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   if [[ "${NEW_PS_DSP_BUILD}" != "${PS_DSP_BUILD}" ]]; then
      local DSP_TEST=`echo -e ${CI2RM_DSP} | sed "s/DSP_LIBS_/DSP_TESTBIN_/"`

      local BWFILES=
      for i in `${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/bin` ; do
         ${SVN} ls ${BASEPSRELREPO}/DSPHWAPI/tags/${PS_DSP_BUILD}/C_Platform/DSPHWAPI/bin/${i} 1>/dev/null 2>/dev/null ||
           BWFILES="New boot binary: ${i}
${BWFILES}"
      done
      if [[ -z ${BWFILES} ]] ; then
         BWFILES="No new boot binaries
"
      fi

      local FORSCT="for SCT "
      [[ "${NEW_PS_DSP_BUILD}" =~ "_20M[0-9]_" || "${NEW_PS_DSP_BUILD}" =~ "DND3.0_PS_REL_2013_04_" ]] && FORSCT=
      [[ "${FAST}" == "fast_track" ]] && FORSCT="for SCT (Fast Track) "

      SUB="DSPHWAPI Release ${NEW_PS_DSP_BUILD} is ready ${FORSCT}for ${RELEASE}"
      FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
      REPLYTO="scm-ps-prod@mlist.emea.nsn-intra.net"
      TO="scm-ps-int@mlist.emea.nsn-intra.net"
      CC="scm-ps-prod@mlist.emea.nsn-intra.net"
      MSG="Dear Colleagues,

The DSPHWAPI release ${NEW_PS_DSP_BUILD} is now available. Target PS release: ${RELEASE}

Sources:
${SVNDSP}/${BRANCH}/tags/${NEW_PS_DSP_SW}
(or ${SVNSERVER}${ECL_UPHWAPI})

Binaries:
${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}
(or ${CI2RM_DSP})

Test Binaries:
${DSP_TEST}

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
${WFT_SHOW}/${NEW_PS_DSP_BUILD}

Best regards
PS SCM"
      ${TEST} ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || fatal "Unable to ${SEND_MSG}"
   fi
   log "DONE"
}

function check_dsp ()
{
   log "STARTED"
   local DSP_FILE=${RELEASEDIR}/${RELEASE}/config_ps_ROTOLRC_dsp.sh
   while [ ! -r "${DSP_FILE}" ]; do
      log "waiting for ${DSP_FILE}"
      sleep 60
   done
   source ${DSP_FILE}
   [ -z "${NEW_BRANCH_PS_DSP_SW}" ] && fatal "NEW_BRANCH_PS_DSP_SW not defined"
   [ -z "${NEW_PS_DSP_SW}" ] && fatal "NEW_PS_DSP_SW not defined"
   while [ -z "${NEW_PS_DSP_BUILD}" ]; do
      log "waiting for NEW_PS_DSP_BUILD within ${DSP_FILE}"
      sleep 60
      source ${DSP_FILE}
   done 
   log "DONE"
}

function check_dsp_completed ()
{
   local DSP_FILE=${RELEASEDIR}/${RELEASE}/fctptr_ps_ROTOLRC_dsp.sh
   grep completed ${DSP_FILE} > /dev/null
   while [ "$?" != "0" ]; do
      log "waiting for DSP completed"
      sleep 60
      grep completed ${DSP_FILE} > /dev/null
   done
}
