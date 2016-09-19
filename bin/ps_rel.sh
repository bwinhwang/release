#!/bin/bash
###################################################################################################
#
# Author:      Ubbo Heyken      <ubbo.heyken@nsn.com>
#              Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:        31-Jan-2012
#
# Description: contains functions for platform releasing
# 
# <Date>                            <Description>
# 31-Jan-2012: Hans-Uwe Zeisler      first version
#
###################################################################################################

##################
# main functions #
##################

# write xml tag to FILE, params: destination, versionnumber, module, [module, ...]
function write_xml_tag () 
{
   local DEST=${1}
   local VERS=${2}
   shift; shift;
   echo -e " <file source=\"${SOURCE}\" mandatory=\"yes\" version=\"${VERS}\" destination=\"${DEST}\">" >> ${FILE}
   for i in "$@" ; do
      echo -e "  <module>${i}</module>" >> ${FILE}
   done
   echo -e " </file>" >> ${FILE}
}

# read the MCU_VERSION and CCS_VERSION from file
function get_versions ()
{
   log "STARTED"
   local FILE=${RELEASEDIR}/${RELEASE}/versions.txt
   MCU_VERSION=`cat "${FILE}" | grep "MCU:" | sed "s/MCU://"`
   CCS_VERSION=`cat "${FILE}" | grep "CCS:" | sed "s/CCS://"`
   log "MCU version:${MCU_VERSION}"
   log "CCS version:${CCS_VERSION}"
   log "DONE"
}


# calculate 8 digit version number for CCS and MCU version files (from unix time)
function calc_ver_num ()
{
   log "STARTED"
   local FILE=${RELEASEDIR}/${RELEASE}/versions.txt
   local VERSION=$(printf '%X' `date +%s`)
   local VCF=`${SVN} cat ${BASEPSRELREPO}/branches/${BASE}/C_Platform/version_control.xml` || fatal "svn cat failed"

   local MCU_VERSION=`echo "${VCF}" | grep "MCUHWAPI/" | head -n1 | sed -e "s|.*version=\"\([0-9a-zA-Z]*\)\".*|\1|"`
   local CCS_VERSION=`echo "${VCF}" | grep "CCS/" | head -n1 | sed -e "s|.*version=\"\([0-9a-zA-Z]*\)\".*|\1|"`
   log "MCU old version number: ${MCU_VERSION}"
   log "CCS old version number: ${CCS_VERSION}"

   [[ "${NEW_PS_MCU_BUILD}" != "${PS_MCU_BUILD}" || -z ${MCU_VERSION} ]] && MCU_VERSION=${VERSION}
   [[ "${NEW_PS_CCS_BUILD}" != "${PS_CCS_BUILD}" || -z ${CCS_VERSION} ]] && CCS_VERSION=${VERSION}

   log "MCU new version number: ${MCU_VERSION}"
   log "CCS new version number: ${CCS_VERSION}"

   echo "MCU:${MCU_VERSION}" > ${FILE}
   echo "CCS:${CCS_VERSION}" >> ${FILE}

   log "DONE"
}

# create xml file for pit
function create_xml_file_pspit ()
{
   local DATE_NOW=`date +%Y-%m-%d`
   local TIME_NOW=`date +%H:%M:%SZ -u`
   local BASELINES=$(getBaselinesForXml)
   echo "<releasenote version=\"${XML_SCHEMA}\">
 <name>${NEW_PS_PIT}</name>
 <system>PS_PIT</system>
 <releaseDate>${DATE_NOW}</releaseDate>
 <releaseTime>${TIME_NOW}</releaseTime>
 <authorEmail>scm-ps-prod@mlist.emea.nsn-intra.net</authorEmail>
 <basedOn>${PS_PIT}</basedOn>
 <importantNotes>
  <note name=\"${NEW_PS_PIT}\">PIT TRIGGERED</note>
 </importantNotes>
 <repositoryUrl>dummy</repositoryUrl>
 <repositoryBranch>dummy</repositoryBranch>
 <repositoryRevision>dummy</repositoryRevision>
 <repositoryType>svn</repositoryType>
 <correctedFaults></correctedFaults>
 <revertedCorrectedFaults></revertedCorrectedFaults>
 <baselines>
${BASELINES}
      <baseline auto_create=\"true\" name=\"CCS_SW\">${NEW_PS_CCS_SW}</baseline>
      <baseline auto_create=\"true\" name=\"CCS_BUILD\">${NEW_PS_CCS_BUILD}</baseline>
      <baseline auto_create=\"true\" name=\"PS_DSPHWAPI_SW\">${NEW_PS_DSP_SW}</baseline>
      <baseline auto_create=\"true\" name=\"PS_DSPHWAPI_BUILD\">${NEW_PS_DSP_BUILD}</baseline>
      <baseline auto_create=\"true\" name=\"PS_MCUHWAPI_SW\">${NEW_PS_MCU_SW}</baseline>
      <baseline auto_create=\"true\" name=\"PS_MCUHWAPI_BUILD\">${NEW_PS_MCU_BUILD}</baseline>
 </baselines>
 <notes></notes>
 <changenotes></changenotes>
 <unsupportedFeatures></unsupportedFeatures>
 <restrictions></restrictions>
 <download>
   <downloadItem storage=\"SVN\" name=\"SC_PIT\"> </downloadItem>
 </download>
 <features></features>
</releasenote>" > ${RELNOTEXMLPSPIT}
   chmod 755 ${RELNOTEXMLPSPIT}
}

# create new psrel branch and copy psrel components to it
function combine_psrel()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}

   PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   ${SVN} ls ${PS_REL_DST} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm ${PS_REL_DST} -m "${ROTOCI_VERSION}" 
   ${TEST} ${SVN} mkdir ${PS_REL_DST} -m "${ROTOCI_VERSION}" --parents || 
      ${TEST} ${SVN} mkdir ${PS_REL_DST} -m "${ROTOCI_VERSION}" --parents || 
      fatal "mkdir ${PS_REL_DST} failed"

   local SRC="${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}"
   ${TEST} ${SVN} cp ${SRC}/C_Platform ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/C_Platform/DSPHWAPI ${PS_REL_DST}/C_Platform failed"
   ${SVN} ls ${SRC}/ccs_faraday 1>/dev/null 2>/dev/null && 
     ( ${TEST} ${SVN} cp ${SRC}/ccs_faraday ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/ccs_faraday ${PS_REL_DST} failed" )
   ${SVN} ls ${SRC}/ccs_nyquist 1>/dev/null 2>/dev/null &&
     ( ${TEST} ${SVN} cp ${SRC}/ccs_nyquist ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/ccs_nyquist ${PS_REL_DST} failed" )
   ${SVN} ls ${SRC}/T_Tools 1>/dev/null 2>/dev/null &&
     ( ${TEST} ${SVN} cp ${SRC}/T_Tools ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/T_Tools ${PS_REL_DST} failed" )
   ${TEST} ${SVN} cp ${SRC}/Documents ${PS_REL_DST} -m "${ROTOCI_VERSION}" || ${TEST} ${SVN} mkdir ${PS_REL_DST}/Documents -m "${ROTOCI_VERSION}" || fatal "svn mkdir ${PS_REL_DST}/Documents failed"

   local SRC="${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}"
   ${TEST} ${SVN} cp ${SRC}/C_Platform/MCUHWAPI ${PS_REL_DST}/C_Platform -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/C_Platform/MCUHWAPI ${PS_REL_DST}/C_Platform failed"

   ${SVN} ls ${SRC}/ApplStubs 1>/dev/null 2>/dev/null && 
     ( ${TEST} ${SVN} cp ${SRC}/ApplStubs ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/ApplStubs ${PS_REL_DST} failed" )
   ${SVN} ls ${SRC}/Build 1>/dev/null 2>/dev/null &&
     ( ${TEST} ${SVN} cp ${SRC}/Build ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/Build ${PS_REL_DST} failed" )
   ${SVN} ls ${SRC}/Hwapi 1>/dev/null 2>/dev/null &&
     ( ${TEST} ${SVN} cp ${SRC}/Hwapi ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/Hwapi ${PS_REL_DST} failed" )
   ${SVN} ls ${SRC}/OSE 1>/dev/null 2>/dev/null &&
     ( ${TEST} ${SVN} cp ${SRC}/OSE ${PS_REL_DST} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/OSE ${PS_REL_DST} failed" )

   for i in `${SVN} ls ${SRC}/C_Platform/test_autom |grep ".txt"`; do
      ${TEST} ${SVN} cp ${SRC}/C_Platform/test_autom/${i} ${PS_REL_DST}/C_Platform/test_autom/${i} -m "${ROTOCI_VERSION}" ||
         warn "svn cp ${SRC}/C_Platform/test_autom/${i} ${PS_REL_DST}/C_Platform/test_autom/${i} failed"
   done

   local SRC="${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}"
   ${SVN} ls ${PS_REL_DST}/C_Platform/CCS 1>/dev/null 2>/dev/null
   if [[ $? == 0 ]]; then
      ${TEST} ${SVN} rm ${PS_REL_DST}/C_Platform/CCS -m "${ROTOCI_VERSION}" || fatal "svn rm ${PS_REL_DST}/C_Platform/CCS failed"
      ${TEST} ${SVN} cp ${SRC}/C_Platform/CCS ${PS_REL_DST}/C_Platform -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/C_Platform/CCS ${PS_REL_DST}/C_Platform failed"
      local DSPSRC="${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/CCS"
      for i in `${SVN} ls ${DSPSRC}` ; do
         for j in `${SVN} ls ${DSPSRC}/${i}` ; do
            ${TEST} ${SVN} cp ${DSPSRC}/${i}/${j} ${PS_REL_DST}/C_Platform/CCS/${i}/${j} -m "${ROTOCI_VERSION}" || fatal "svn cp ${DSPSRC}/${i}/${j} ${PS_REL_DST}/C_Platform/CCS/${i}/${j} failed"
         done
      done
   else
      ${TEST} ${SVN} cp ${SRC}/C_Platform/CCS ${PS_REL_DST}/C_Platform -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/C_Platform/CCS ${PS_REL_DST}/C_Platform failed"
   fi
   for i in `${SVN} ls ${SRC}/T_Tools 2>/dev/null` ; do
      ${TEST} ${SVN} cp ${SRC}/T_Tools/${i} ${PS_REL_DST}/T_Tools/${i} -m "${ROTOCI_VERSION}" || fatal "svn cp ${SRC}/T_Tools/${i} ${PS_REL_DST}/T_Tools/${i} failed"
   done

   for i in `${SVN} ls ${SRC}/C_Platform/CCS/TrblLogList |grep ".txt"`; do
      ${TEST} ${SVN} cp ${SRC}/C_Platform/CCS/TrblLogList/${i} ${PS_REL_DST}/C_Platform/test_autom/${i} -m "${ROTOCI_VERSION}" ||
         warn "svn cp ${SRC}/C_Platform/CCS/TrblLogList/${i} ${PS_REL_DST}/C_Platform/test_autom/${i} failed"
   done

   log "DONE"
}

function create_trbl_log_list()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=trbl_log_list.csv
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   local TO_IGNORE="file container *; *filename *; *deployment"
   local TEMP

   # dereference symbolic link 
   local LINK=${FNAME}
   local PROP_SPECIAL=`${SVN} pg svn:special ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/${FNAME}`
   if [[ "${PROP_SPECIAL}" ]]; then
      LINK=`${SVN} cat ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/${FNAME}` # cat svn link information
      LINK=`echo ${LINK} | sed -e 's|^link\s||'`;
   fi
   log "file: ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/${LINK}"

   ${SVN} ls ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/${LINK} 1>/dev/null 2>/dev/null
   if [[ $? == 0 ]]; then
      TEMP=`${SVN} cat ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}/${LINK}` || fatal "svn cat failed"
      echo "${TEMP}" > ${FILE}
   fi

   ${SVN} ls ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW}/${FNAME} 1>/dev/null 2>/dev/null
   if [[ $? == 0 ]]; then
      TEMP=`${SVN} cat ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW}/${FNAME} |grep -iv "${TO_IGNORE}"` || fatal "svn cat failed"
      echo "${TEMP}" >> ${FILE}
   fi

   ${SVN} ls ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/${FNAME} 1>/dev/null 2>/dev/null
   if [[ $? == 0 ]]; then
      TEMP=`${SVN} cat ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}/${FNAME} |grep -iv "${TO_IGNORE}"` || fatal "svn cat failed"
      echo "${TEMP}" >> ${FILE}
   fi

   [ ! -f ${FILE} ] || ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/C_Platform/test_autom/${FNAME} -m "${ROTOCI_VERSION}" ||
      fatal "import ${FILE} to ${PS_REL_DST}/C_Platform/${FNAME} failed"

   log "DONE"
}

# refine: syntax check, format
function refine_xml_file ()
{
   local FILE=${1}
   local COMP=${2}
   log "syntax check of ${COMP} VCF"
   xmllint --format ${FILE} -o ${FILE} || ( warn "xml syntax error in component ${COMP} VCF"; echo "<!-- ${COMP} syntax error -->" > ${FILE} )
   sed -i -e '/<?.*?>/d' -e '/<versionControl*File>/d' -e '/<\/versionControl*File>/d' ${FILE}  # remove tag
   sed -i -e "s|file source=\"|file source=\"${COMP}/|" ${FILE}                                 # insert path
}

# read the given version control files and concatenate to version_control.xml
function create_vcf_combined ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}

   local FNAME=version_control.xml
   local OUTFILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   log "OUTFILE=${OUTFILE}"
   log "PS_REL_DST=${PS_REL_DST}"
   log "vcf path: '${CI2RM_CCS}'"
   log "vcf path: '${CI2RM_MCU}'"
   log "vcf path: '${CI2RM_DSP}'"

   unzip -p ${CI2RM_CCS} C_Platform/CCS/version_control.xml > ${TMPDIR}/$$_CCS.xml || echo "<!-- CCS VCF is missing -->" > ${TMPDIR}/$$_CCS.xml
   unzip -p ${CI2RM_MCU} C_Platform/MCUHWAPI/version_control.xml > ${TMPDIR}/$$_MCUHWAPI.xml || echo "<!-- MCUHWAPI VCF is missing -->" > ${TMPDIR}/$$_MCUHWAPI.xml
   unzip -p ${CI2RM_DSP} C_Platform/DSPHWAPI/version_control.xml > ${TMPDIR}/$$_DSPHWAPI.xml || echo "<!-- DSPHWAPI VCF is missing -->" > ${TMPDIR}/$$_DSPHWAPI.xml
   unzip -p ${CI2RM_DSP} C_Platform/DSPHWAPI_RT/version_control.xml > ${TMPDIR}/$$_DSPHWAPI_RT.xml || echo "<!-- DSPHWAPI_RT VCF is missing -->" > ${TMPDIR}/$$_DSPHWAPI_RT.xml
   unzip -p ${CI2RM_DSP} C_Platform/CCS_RT/version_control.xml > ${TMPDIR}/$$_CCS_RT.xml || echo "<!-- CCS_RT VCF is missing -->" > ${TMPDIR}/$$_CCS_RT.xml

   refine_xml_file ${TMPDIR}/$$_CCS.xml CCS
   refine_xml_file ${TMPDIR}/$$_MCUHWAPI.xml MCUHWAPI
   refine_xml_file ${TMPDIR}/$$_DSPHWAPI.xml DSPHWAPI
   refine_xml_file ${TMPDIR}/$$_DSPHWAPI_RT.xml DSPHWAPI_RT
   refine_xml_file ${TMPDIR}/$$_CCS_RT.xml CCS_RT

   echo '<?xml version="1.0" encoding="UTF-8"?>' > ${OUTFILE}
   echo '<versionControlFile>' >> ${OUTFILE}
   cat ${TMPDIR}/$$_*.xml >> ${OUTFILE}
   echo '</versionControlFile>' >> ${OUTFILE}
   rm ${TMPDIR}/$$_*.xml

   ${TEST} ${SVN} import ${OUTFILE} ${PS_REL_DST}/C_Platform/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${OUTFILE} to ${PS_REL_DST}/C_Platform/${FNAME} failed"
   ${TEST} ${SVN} mkdir ${PS_REL_DST}/C_Platform/versions -m "${ROTOCI_VERSION}"
   sed -i -e "s|file source=\"|file source=\"../|" ${OUTFILE}
   ${TEST} ${SVN} import ${OUTFILE} ${PS_REL_DST}/C_Platform/versions/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${OUTFILE} to ${PS_REL_DST}/C_Platform/versions/${FNAME} failed"
   log "DONE"
}

function create_ptsw_fsmr3_vcf()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   get_versions
   local FNAME=ptsw_fsmr3_version_control.xml
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > ${FILE}
   echo -e "<versionControllFile>" >> ${FILE}

   local SOURCE=DSPHWAPI/dab/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/dab | grep FSP[D-Z]-DSP-RT`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSP"
   SOURCE=DSPHWAPI/Bin/Nyquist/Lte/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/Bin/Nyquist/Lte | grep FSP[D-Z]-DSP-RT`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSP"

   SOURCE=DSPHWAPI/bin/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/bin | grep FSP[D-Z]-DSP-BW`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSP"
   SOURCE=DSPHWAPI/Bin/Nyquist/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/Bin/Nyquist | grep FSP[D-Z]-DSP-BW`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSP"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FCT/hwr.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fct" "${MCU_VERSION}" "FCT"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FSP/hwr.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fsp" "${MCU_VERSION}" "FSP"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FCT/hwmt.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fct" "${MCU_VERSION}" "FCT"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FSP/hwmt.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fsp" "${MCU_VERSION}" "FSP"

   SOURCE="CCS/Tar/LINUX_OCTEON2/CCS.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps" "${CCS_VERSION}" "FCT" "FSP"

   SOURCE="AppDef.txt"
   write_xml_tag "flash/apps/fct" "" "FCT"
   write_xml_tag "flash/apps/fsp" "" "FSP"

   echo -e "</versionControllFile>" >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/C_Platform/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/C_Platform/${FNAME} failed"
   log "DONE"
}

function create_ptsw_fsmr4_vcf()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   get_versions
   local FNAME=ptsw_fsmr4_version_control.xml
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > ${FILE}
   echo -e "<versionControllFile>" >> ${FILE}

   local SOURCE="MCUHWAPI/Exe/LINUX_CORTEXA15/FSM4_FCT_AXM/hwr.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/0/A/mcu-axm55xx/addons" "${MCU_VERSION}" "FCTJ" "FCTO" "FSCA"

   SOURCE="MCUHWAPI/Exe/LINUX_CORTEXA15/FSM4_FSP_K2/hwr.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/A/mcu-tci6638k2/addons" "${MCU_VERSION}" "FSPJ" "FSPO"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/B/mcu-tci6638k2/addons" "${MCU_VERSION}" "FSPJ" "FSPO"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/C/mcu-tci6638k2/addons" "${MCU_VERSION}" "FSPJ" "FSPO"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/D/mcu-tci6638k2/addons" "${MCU_VERSION}" "FSPJ" "FSPO"

   SOURCE="CCS/Tar/LINUX_ARM15_LE/CCS.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/A/mcu-tci6638k2/addons" "${CCS_VERSION}" "FCTJ" "FCTO" "FSCA"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/B/mcu-tci6638k2/addons" "${CCS_VERSION}" "FCTJ" "FCTO" "FSCA"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/C/mcu-tci6638k2/addons" "${CCS_VERSION}" "FCTJ" "FCTO" "FSCA"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/1/D/mcu-tci6638k2/addons" "${CCS_VERSION}" "FCTJ" "FCTO" "FSCA"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "boardcfg/0/A/mcu-axm55xx/addons" "${CCS_VERSION}" "FCTJ" "FCTO" "FSCA"

   echo -e "</versionControllFile>" >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/C_Platform/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/C_Platform/${FNAME} failed"
   log "DONE"
}

function create_ptsw_urec_vcf()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   get_versions
   local FNAME=ptsw_urec_version_control.xml
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > ${FILE}
   echo -e "<versionControllFile>" >> ${FILE}

   local SOURCE=DSPHWAPI/dab/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/dab | grep FSP[D-Z]-DSP-RT`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSPN"
   SOURCE=DSPHWAPI/Bin/Nyquist/Lte/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/Bin/Nyquist/Lte | grep FSP[D-Z]-DSP-RT`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSPN"

   SOURCE=DSPHWAPI/bin/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/bin | grep FSP[D-Z]-DSP-BW`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSPN"
   SOURCE=DSPHWAPI/Bin/Nyquist/`${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/Bin/Nyquist | grep FSP[D-Z]-DSP-BW`
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash" "" "FSPN"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FCT/hwr.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fct" "${MCU_VERSION}" "FCTE"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FCT/hwmt.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fct" "${MCU_VERSION}" "FCTE"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FSP/hwmt.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fsp" "${MCU_VERSION}" "FSPN"

   SOURCE="CCS/Tar/LINUX_OCTEON2/CCS.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/CCS/tags/${NEW_PS_CCS_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fct" "${CCS_VERSION}" "FCTE"

   SOURCE="MCUHWAPI/Exe/LINUX_OCTEON2/FSP/hwfw.tgz"
   ${SVN} ls ${RELEASEPSRELREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}/C_Platform/${SOURCE} 1>/dev/null 2>/dev/null && write_xml_tag "flash/apps/fsp" "${MCU_VERSION}" "FSPN"

   SOURCE="AppDef.txt"
   write_xml_tag "flash/apps/fct" "" "FCTE"
   write_xml_tag "flash/apps/fsp" "" "FSPN"
 
   echo -e "</versionControllFile>" >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/C_Platform/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/C_Platform/${FNAME} failed"
   log "DONE"
}

# create BTS_PS_versionfile.txt
function create_bts_ps_versionfile()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=BTS_PS_versionfile.txt
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   [[ ${ECL_DSP_BGT} ]] && echo -e "BGT=${ECL_DSP_BGT}"                     > ${FILE}
   [[ ${ECL_SWBUILD} ]] && echo -e "SW_BUILD=${ECL_SWBUILD}"               >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   [[ ${ECL_TI_CGT_FSPB} ]] && echo -e "TI_CGT=${ECL_TI_CGT_FSPB}"         >> ${FILE}
   [[ ${ECL_TI_CGT} ]] && echo -e "TI_CGT=${ECL_TI_CGT}"                   >> ${FILE}
   [[ ${ECL_TI_CGT_WCDMA} ]] && echo -e "TI_CGT_WCDMA=${ECL_TI_CGT_WCDMA}" >> ${FILE}
   [[ ${ECL_TI_CSL_FSPB} ]] && echo -e "TI_CSL=${ECL_TI_CSL_FSPB}"         >> ${FILE}
   [[ ${ECL_TI_DCI_FSPB} ]] && echo -e "TI_DCI=${ECL_TI_DCI_FSPB}"         >> ${FILE}
   [[ ${ECL_TI_AET_FSPB} ]] && echo -e "TI_AET=${ECL_TI_AET_FSPB}"         >> ${FILE}
   [[ ${ECL_OSECK_4} ]] && echo -e "OSE_CK=${ECL_OSECK_4}"                 >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   [[ ${ECL_TI_CGT_NYQUIST} ]] && echo -e "TI_CGT_N=${ECL_TI_CGT_NYQUIST}" >> ${FILE}
   [[ ${ECL_TI_CGT} ]] && echo -e "TI_CGT_N=${ECL_TI_CGT}"                 >> ${FILE}
   [[ ${ECL_TI_AET_NYQUIST} ]] && echo -e "TI_AET_N=${ECL_TI_AET_NYQUIST}" >> ${FILE}
   [[ ${ECL_TI_NYQUIST_PDK} ]] && echo -e "PDK=${ECL_TI_NYQUIST_PDK}"      >> ${FILE}
   [[ ${ECL_OSECK_4_1_NY} ]] && echo -e "OSE_CK_N=${ECL_OSECK_4_1_NY}"     >> ${FILE}
   [[ ${ECL_OSECK_4_1_NY_WCDMA} ]] && echo -e "OSE_CK_N_WCDMA=${ECL_OSECK_4_1_NY_WCDMA}"   >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   [[ ${ECL_PS_LFS_SDK1} ]] && echo -e "SDK1=${ECL_PS_LFS_SDK1}"           >> ${FILE}
   [[ ${ECL_PS_LFS_SDK2} ]] && echo -e "SDK2=${ECL_PS_LFS_SDK2}"           >> ${FILE}
   [[ ${ECL_PS_LFS_SDK3} ]] && echo -e "SDK3=${ECL_PS_LFS_SDK3}"           >> ${FILE}
   [[ ${ECL_PS_LFS_OS} ]] && echo -e "LFS=${ECL_PS_LFS_OS}"                >> ${FILE}
   [[ ${ECL_PS_LFS_REL} ]] && echo -e "LFS_REL=${ECL_PS_LFS_REL}"          >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_OS} ]] && echo -e "LRC_LFS=${ECL_PS_LRC_LFS_OS}"        >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_REL} ]] && echo -e "LRC_LFS_REL=${ECL_PS_LRC_LFS_REL}"  >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_OS} ]] && echo -e "LRC_LCP_LFS=${ECL_PS_LRC_LCP_LFS_OS}"        >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && echo -e "LRC_LCP_LFS_REL=${ECL_PS_LRC_LCP_LFS_REL}"  >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_OS} ]] && echo -e "LRC_LSP_LFS=${ECL_PS_LRC_LSP_LFS_OS}"        >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && echo -e "LRC_LSP_LFS_REL=${ECL_PS_LRC_LSP_LFS_REL}"  >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_OS} ]] && echo -e "FZM_LFS=${ECL_PS_FZM_LFS_OS}"        >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_REL} ]] && echo -e "FZM_LFS_REL=${ECL_PS_FZM_LFS_REL}"  >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   [[ ${ECL_OSECK_4_1_K2} ]] && echo -e "OSE_CK_K2=${ECL_OSECK_4_1_K2}"    >> ${FILE}
   [[ ${ECL_TI_K2_MCSDK} ]] && echo -e "TI_K2_MCSDK=${ECL_TI_K2_MCSDK}"    >> ${FILE}
   [[ ${ECL_TI_KEPLER_PDK} ]] && echo -e "TI_KEPLER_PDK=${ECL_TI_KEPLER_PDK}"  >> ${FILE}
   [[ ${ECL_TI_CGT_K2} ]] && echo -e "TI_CGT_K2=${ECL_TI_CGT_K2}"          >> ${FILE}
   [[ ${ECL_TI_AET_K2} ]] && echo -e "TI_AET_K2=${ECL_TI_AET_K2}"          >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   echo -e "GLOBAL_ENV=${ECL_GLOBAL_ENV}"                                  >> ${FILE}
   echo -e "PS_ENV=${NEW_PS_ENV}"                                          >> ${FILE}
   echo -e ""                                                              >> ${FILE}
   echo -e "PS_CCS=${NEW_PS_CCS_SW}"                                       >> ${FILE}
   echo -e "CCS_BUILD=${NEW_PS_CCS_BUILD}"                                 >> ${FILE}
   echo -e "PS_MCUHWAPI=${NEW_PS_MCU_SW}"                                  >> ${FILE}
   echo -e "MCUHWAPI_BUILD=${NEW_PS_MCU_BUILD}"                            >> ${FILE}
   echo -e "PS_DSPHWAPI=${NEW_PS_DSP_SW}"                                  >> ${FILE}
   echo -e "DSPHWAPI_BUILD=${NEW_PS_DSP_BUILD}"                            >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

# create BTS_PS_versionfile.txt
function create_bts_ps_versionfile_ext()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=BTS_PS_versionfile_ext.txt
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   local SHORTREPO=`echo "${RELEASEPSRELREPO}" | sed "s|.*/||"`

   [[ ${ECL_PS_LFS_REL} ]] && findLfsRelRepo ${ECL_PS_LFS_REL}
   local LFS_REPO=${LFSRELREPO}
   [[ ${ECL_PS_LRC_LFS_REL} ]] && findLfsRelRepo ${ECL_PS_LRC_LFS_REL}
   local LRC_REPO=${LFSRELREPO}
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && findLfsRelRepo ${ECL_PS_LRC_LCP_LFS_REL}
   local LCP_REPO=${LFSRELREPO}
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && findLfsRelRepo ${ECL_PS_LRC_LSP_LFS_REL}
   local LSP_REPO=${LFSRELREPO}
   [[ ${ECL_PS_FZM_LFS_REL} ]] && findLfsRelRepo ${ECL_PS_FZM_LFS_REL}
   local FZM_REPO=${LFSRELREPO}

   [[ ${ECL_DSP_BGT} ]] && echo -e "ECL_BGT=/isource/svnroot/BTS_T_BGT/tags/${ECL_DSP_BGT}"                                > ${FILE}
   [[ ${ECL_SWBUILD} ]] && echo -e "ECL_SW_BUILD=/isource/svnroot/BTS_T_PS_SWBUILD/tags/${ECL_SWBUILD}"                   >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   [[ ${ECL_TI_CGT_FSPB} ]] && echo -e "ECL_TI_CGT=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_FSPB}"                 >> ${FILE}
   [[ ${ECL_TI_CGT} ]] && echo -e "ECL_TI_CGT=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT}"                           >> ${FILE}
   [[ ${ECL_TI_CGT_WCDMA} ]] && echo -e "ECL_TI_CGT_WCDMA=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_WCDMA}"         >> ${FILE}
   [[ ${ECL_TI_CSL_FSPB} ]] && echo -e "ECL_TI_CSL=/isource/svnroot/BTS_E_TI_CSL/tags/${ECL_TI_CSL_FSPB}"                 >> ${FILE}
   [[ ${ECL_TI_DCI_FSPB} ]] && echo -e "ECL_TI_DCI=/isource/svnroot/BTS_E_TI_DCI/tags/${ECL_TI_DCI_FSPB}"                 >> ${FILE}
   [[ ${ECL_TI_AET_FSPB} ]] && echo -e "ECL_TI_AET=/isource/svnroot/BTS_E_TI_AET/tags/${ECL_TI_AET_FSPB}"                 >> ${FILE}
   [[ ${ECL_OSECK_4} ]] && echo -e "ECL_OSE_CK=/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4}"                         >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   [[ ${ECL_TI_CGT_NYQUIST} ]] && echo -e "ECL_TI_CGT_N=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_NYQUIST}"         >> ${FILE}
   [[ ${ECL_TI_CGT} ]] && echo -e "ECL_TI_CGT_N=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT}"                         >> ${FILE}
   [[ ${ECL_TI_AET_NYQUIST} ]] && echo -e "ECL_TI_AET_N=/isource/svnroot/BTS_E_TI_AET/tags/${ECL_TI_AET_NYQUIST}"         >> ${FILE}
   [[ ${ECL_TI_NYQUIST_PDK} ]] && echo -e "ECL_PDK=/isource/svnroot/BTS_T_TI_NYQUIST_PDK/tags/${ECL_TI_NYQUIST_PDK}"      >> ${FILE}
   [[ ${ECL_OSECK_4_1_NY} ]] && echo -e "ECL_OSE_CK_N=/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4_1_NY}"             >> ${FILE}
   [[ ${ECL_OSECK_4_1_NY_WCDMA} ]] && echo -e "ECL_OSE_CK_N_WCDMA=/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4_1_NY_WCDMA}" >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   [[ ${ECL_PS_LFS_SDK1} ]] && echo -e "ECL_SDK1=/isource/svnroot/BTS_D_SC_LFS_SDK_1/sdk/tags/${ECL_PS_LFS_SDK1}"      >> ${FILE}
   [[ ${ECL_PS_LFS_SDK2} ]] && echo -e "ECL_SDK2=/isource/svnroot/BTS_D_SC_LFS_SDK_1/sdk/tags/${ECL_PS_LFS_SDK2}"      >> ${FILE}
   [[ ${ECL_PS_LFS_SDK3} ]] && echo -e "ECL_SDK3=/isource/svnroot/BTS_D_SC_LFS_SDK_1/sdk/tags/${ECL_PS_LFS_SDK3}"      >> ${FILE}
   [[ ${ECL_PS_LFS_OS} ]] && echo -e "ECL_LFS=/isource/svnroot/${LFS_REPO}/os/tags/${ECL_PS_LFS_OS}"                      >> ${FILE}
   [[ ${ECL_PS_LFS_REL} ]] && echo -e "ECL_LFS_REL=/isource/svnroot/${LFS_REPO}/tags/${ECL_PS_LFS_REL}"                   >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_OS} ]] && echo -e "ECL_LRC_LFS=/isource/svnroot/${LRC_REPO}/os/tags/${ECL_PS_LRC_LFS_OS}"          >> ${FILE}
   [[ ${ECL_PS_LRC_LFS_REL} ]] && echo -e "ECL_LRC_LFS_REL=/isource/svnroot/${LRC_REPO}/tags/${ECL_PS_LRC_LFS_REL}"       >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_OS} ]] && echo -e "ECL_LRC_LCP_LFS=/isource/svnroot/${LCP_REPO}/os/tags/${ECL_PS_LRC_LCP_LFS_OS}"    >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && echo -e "ECL_LRC_LCP_LFS_REL=/isource/svnroot/${LCP_REPO}/tags/${ECL_PS_LRC_LCP_LFS_REL}" >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_OS} ]] && echo -e "ECL_LRC_LSP_LFS=/isource/svnroot/${LSP_REPO}/os/tags/${ECL_PS_LRC_LSP_LFS_OS}"    >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && echo -e "ECL_LRC_LSP_LFS_REL=/isource/svnroot/${LSP_REPO}/tags/${ECL_PS_LRC_LSP_LFS_REL}" >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_OS} ]] && echo -e "ECL_FZM_LFS=/isource/svnroot/${FZM_REPO}/os/tags/${ECL_PS_FZM_LFS_OS}"          >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_REL} ]] && echo -e "ECL_FZM_LFS_REL=/isource/svnroot/${FZM_REPO}/tags/${ECL_PS_FZM_LFS_REL}"       >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   [[ ${ECL_OSECK_4_1_K2} ]] && echo -e "ECL_OSE_CK_K2=/isource/svnroot/BTS_E_OSE_CK/tags/${ECL_OSECK_4_1_K2}"            >> ${FILE}
   [[ ${ECL_TI_K2_MCSDK} ]] && echo -e "ECL_TI_K2_MCSDK=/isource/svnroot/BTS_T_TI_K2_MCSDK/tags/${ECL_TI_K2_MCSDK}"       >> ${FILE}
   [[ ${ECL_TI_KEPLER_PDK} ]] && echo -e "ECL_TI_KEPLER_PDK=/isource/svnroot/BTS_T_TI_K2_MCSDK/tags/${ECL_TI_KEPLER_PDK}" >> ${FILE}
   [[ ${ECL_TI_CGT_K2} ]] && echo -e "ECL_TI_CGT_K2=/isource/svnroot/BTS_T_TI_CGT/tags/${ECL_TI_CGT_K2}"                  >> ${FILE}
   [[ ${ECL_TI_AET_K2} ]] && echo -e "ECL_TI_AET_K2=/isource/svnroot/BTS_E_TI_AET/tags/${ECL_TI_AET_K2}"                  >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   echo -e "ECL_GLOBAL_ENV=/isource/svnroot/BTS_I_GLOBAL/tags/${ECL_GLOBAL_ENV}"                                          >> ${FILE}
   echo -e "ECL_PS_ENV=/isource/svnroot/LRC_I_PS/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}"                                 >> ${FILE}
   echo -e ""                                                                                                             >> ${FILE}
   echo -e "ECL_PS_CCS=/isource/svnroot/LRC_SC_CCS/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}"                         >> ${FILE}
   echo -e "ECL_CCS_BUILD=/isource/svnroot/${SHORTREPO}/CCS/tags/${NEW_PS_CCS_BUILD}"                                     >> ${FILE}
   echo -e "ECL_PS_MCUHWAPI=/isource/svnroot/LRC_SC_MCUHWAPI/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW}"               >> ${FILE}
   echo -e "ECL_MCUHWAPI_BUILD=/isource/svnroot/${SHORTREPO}/MCUHWAPI/tags/${NEW_PS_MCU_BUILD}"                           >> ${FILE}
   echo -e "ECL_PS_DSPHWAPI=/isource/svnroot/LRC_SC_DSPHWAPI/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}"               >> ${FILE}
   echo -e "ECL_UPHWAPI_BUILD=/isource/svnroot/${SHORTREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}"                           >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

# create BTS_PS_src_baselines.txt
function create_bts_ps_src_baselines()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=BTS_PS_src_baselines.txt
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   local REVNUMBER=`${SVN} info ${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo -e "CCS_SRC=${SVNCCS}/${NEW_BRANCH_PS_CCS_SW}/tags/${NEW_PS_CCS_SW}@${REVNUMBER}"  > ${FILE}
   REVNUMBER=`${SVN} info ${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo -e "MCU_SRC=${SVNMCU}/${NEW_BRANCH_PS_MCU_SW}/tags/${NEW_PS_MCU_SW}@${REVNUMBER}" >> ${FILE}
   REVNUMBER=`${SVN} info ${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW} | grep "Last Changed Rev: " | sed "s|Last Changed Rev: ||"`
   echo -e "DSP_SRC=${SVNDSP}/${NEW_BRANCH_PS_DSP_SW}/tags/${NEW_PS_DSP_SW}@${REVNUMBER}" >> ${FILE}
   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

function create_ci2rm()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=CI2RM
   local FILE=${RELEASEDIR}/${RELEASE}/CI2RM_ps_rotoci_psrel.sh
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

function create_ecl()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=ECL
   local FILE=${RELEASEDIR}/${RELEASE}/ECL_ps_rotoci_psrel.sh
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

function create_externals_psrel()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FILE=${RELEASEDIR}/${RELEASE}/psrel_externals.txt
   local SRC=${RELEASEPSRELREPO}/branches/${RELEASE}
   local DST=${RELEASEDIR}/${RELEASE}/${RELEASE}

   [[ "${NEW_PS_ENV}" =~ "PS_ENV_" ]] || fatal "PS_ENV not defined"
   echo "/isource/svnroot/LRC_I_PS/${NEW_BRANCH_PS_ENV}/tags/${NEW_PS_ENV}/I_Interface I_Interface" > ${FILE}
   ${SVN} co --non-recursive ${SRC} ${DST}
   ${SVN} propset svn:externals ${DST} -F ${FILE} || fatal "set properties 'svn:externals' failed for ${DST}"
   ${SVN} ci -m "${ROTOCI_VERSION}" ${DST} || fatal "svn ci failed" 
   log "DONE"
}

# create file with version string of system components
function create_psrel_versionstrings ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=PSREL_versionstring.h
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"

   echo -e "#ifndef PSREL_VERSIONSTRING_H" > ${FILE}
   echo -e "#define PSREL_VERSIONSTRING_H" >> ${FILE}
   echo -e "#define PS_REL_PS_VERSION \"${RELEASE}\"" >> ${FILE}

   local LFSOS=`echo ${ECL_PS_LFS_REL} | sed "s|_LFS_REL_|_LFS_OS_|"`
   local FZMOS=`echo ${ECL_PS_FZM_LFS_REL} | sed "s|_LFS_REL_|_LFS_OS_|"`
   local LCPOS=`echo ${ECL_PS_LRC_LCP_LFS_REL} | sed "s|_LFS_REL_|_LFS_OS_|"`
   local LSPOS=`echo ${ECL_PS_LRC_LSP_LFS_REL} | sed "s|_LFS_REL_|_LFS_OS_|"`

   [[ ${ECL_PS_LFS_REL} ]] && echo -e "#define PS_REL_LFS_VERSION \"${LFSOS}\"" >> ${FILE}
   [[ ${ECL_PS_FZM_LFS_REL} ]] && echo -e "#define PS_REL_FZM_LFS_VERSION \"${FZMOS}\"" >> ${FILE}
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && echo -e "#define PS_REL_LRC_LCP_LFS_VERSION \"${LCPOS}\"" >> ${FILE}
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && echo -e "#define PS_REL_LRC_LSP_LFS_VERSION \"${LSPOS}\"" >> ${FILE}

   # VERSIONSTRING is given by name of zip file, but in case
   # of link, VERSIONSTRING is given by the original name of zip
   findFile ${CI2RM_CCS}
   local VERSIONSTRING=`echo -e ${ORIGFILE} | sed "s|.*REL_CCS_|PS_CCS_|" | sed "s|.zip||"`
   echo -e "#define PS_REL_CCS_VERSION \"${VERSIONSTRING}\"" >> ${FILE}
   VERSIONSTRING=`echo -e ${ECL_UPHWAPI} | sed "s,/isource/svnroot/,," | sed "s,/,_," | sed "s,/,-,"`
   echo -e "#define PS_REL_DSPHWAPI_VERSION \"${VERSIONSTRING}\"" >> ${FILE}
   VERSIONSTRING=`echo -e ${ECL_MCUHWAPI} | sed "s,/isource/svnroot/,," | sed "s,/,_," | sed "s,/,-,"`
   echo -e "#define PS_REL_MCUHWAPI_VERSION \"${VERSIONSTRING}\"" >> ${FILE}
   echo -e "#endif" >> ${FILE}

   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

function create_part_list ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   local FNAME=PSREL_partlist.txt
   local FILE=${RELEASEDIR}/${RELEASE}/${FNAME}
   local PS_REL_DST="${RELEASEPSRELREPO}/branches/${RELEASE}"
   ${SVN} ls -R ${PS_REL_DST} > ${FILE}
   ${TEST} ${SVN} import ${FILE} ${PS_REL_DST}/${FNAME} -m "${ROTOCI_VERSION}" || fatal "import ${FILE} to ${PS_REL_DST}/${FNAME} failed"
   log "DONE"
}

# trigger WFT PS_PIT
function trigger_wft_pspit ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   PS_PIT=`echo ${BASE} | sed 's/PS_REL/PS_PIT/'`
   NEW_PS_PIT=`echo ${RELEASE} | sed 's/PS_REL/PS_PIT/'`
   RELNOTEXMLPSPIT="${RELEASEDIR}/${RELEASE}/svn_data_${NEW_PS_PIT}.xml"
   log "PS_PIT=${PS_PIT}"
   log "NEW_PS_PIT=${NEW_PS_PIT}"
   log "RELNOTEXMLPSPIT=${RELNOTEXMLPSPIT}"
   create_xml_file_pspit
  triggerWft ${PS_PIT} ${NEW_PS_PIT} "" ${RELNOTEXMLPSPIT}
   log "DONE"
}

# register the Platform Release to WFT
function trigger_wft_psrel()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
 
   if [ -z ${TEST} ]; then
      mapBranchName ${BRANCH}    # ret: BRANCH_FOR
      local SUB_BUILD=
      [[ ${ECL_OSE_53} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSE_53}"
      [[ ${ECL_OSE_461} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSE_461}"
      [[ ${ECL_DSP_BGT} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_DSP_BGT}"
      [[ ${ECL_SWBUILD} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_SWBUILD}"
      [[ ${ECL_TI_CGT} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_CGT}"
      [[ ${ECL_TI_CGT_WCDMA} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_CGT_WCDMA}"
      [[ ${ECL_TI_CGT_FSPB} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_CGT_FSPB}"
      [[ ${ECL_TI_CSL_FSPB} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_CSL_FSPB}"
      [[ ${ECL_TI_DCI_FSPB} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_DCI_FSPB}"
      [[ ${ECL_TI_AET_FSPB} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_AET_FSPB}"
      [[ ${ECL_OSECK_4} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSECK_4}"
      [[ ${ECL_TI_CGT_NYQUIST} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_CGT_NYQUIST}"
      [[ ${ECL_TI_AET_NYQUIST} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_AET_NYQUIST}"
      [[ ${ECL_TI_NYQUIST_PDK} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_NYQUIST_PDK}"
      [[ ${ECL_OSECK_4_1_NY} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSECK_4_1_NY}"
      [[ ${ECL_OSECK_4_1_NY_WCDMA} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSECK_4_1_NY_WCDMA}"
      [[ ${ECL_TI_K2_MCSDK} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_K2_MCSDK}"
      [[ ${ECL_TI_KEPLER_PDK} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_TI_KEPLER_PDK}"
      [[ ${ECL_OSECK_4_1_K2} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_OSECK_4_1_K2}"
      [[ ${ECL_PS_LFS_SDK1} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_SDK1}"
      [[ ${ECL_PS_LFS_SDK2} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_SDK2}"
      [[ ${ECL_PS_LFS_SDK3} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_SDK3}"
      [[ ${ECL_PS_LFS_OS} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_OS}"
      [[ ${ECL_PS_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_REL}"
      [[ ${ECL_PS_PNS_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_PNS_LFS_REL}"
      [[ ${ECL_PS_LFS_SDK_YOCTO} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LFS_SDK_YOCTO}"
      [[ ${ECL_PS_LRC_LFS_OS} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LFS_OS}"
      [[ ${ECL_PS_LRC_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LFS_REL}"
      [[ ${ECL_PS_LRC_LCP_LFS_OS} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LCP_LFS_OS}"
      [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LCP_LFS_REL}"
      [[ ${ECL_PS_LRC_LSP_LFS_OS} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LSP_LFS_OS}"
      [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_LRC_LSP_LFS_REL}"
      [[ ${ECL_PS_FZM_LFS_OS} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_FZM_LFS_OS}"
      [[ ${ECL_PS_FZM_LFS_REL} ]] && SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_PS_FZM_LFS_REL}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ECL_GLOBAL_ENV}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_ENV}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_CCS_SW}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_CCS_BUILD}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_MCU_SW}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_MCU_BUILD}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_DSP_SW}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${NEW_PS_DSP_BUILD}"
      SUB_BUILD="${SUB_BUILD} -F sub_build[]=${ROTOCI_VERSION}"
      CMD="${TEST} curl -s -k ${WFT_API}/increment/${RELEASE} -F xml_releasenote_id=37 -F flags[]=${FAST} -F parent=${BASE} ${SUB_BUILD} ${BRANCH_FOR} -F access_key=${WFT_KEY}"
      log "${CMD}"
      local RET=`eval "${CMD}"`
      [[ "${RET}" =~ "success" ]]                 && log "wft creation of '${RELEASE}' successful"
      [[ "${RET}" =~ "Parent baseline.*" ]]       && fatal "wft creation of '${RELEASE}' failed, ${RET}"
      [[ "${RET}" =~ "not found in WFT" ]]        && fatal "wft creation of '${RELEASE}' failed, ${RET}"     
      [[ "${RET}" =~ "Access denied" ]]           && fatal "wft creation of '${RELEASE}' failed, ${RET}"
      [[ "${RET}" =~ "baseline exists already" ]] && fatal "wft creation of '${RELEASE}' failed, ${RET}"
      [[ "${RET}" =~ "success" ]]                 || fatal "wft creation of '${RELEASE}' failed, ${RET}"
      local CI2RMFILE=${RELEASEDIR}/${RELEASE}/CI2RM.txt
      local ECLFILE=${RELEASEDIR}/${RELEASE}/ECL.txt
      local PARTLIST=${RELEASEDIR}/${RELEASE}/PSREL_partlist.txt
      cp ${RELEASEDIR}/${RELEASE}/CI2RM_ps_rotoci_psrel.sh ${CI2RMFILE}
      cp ${RELEASEDIR}/${RELEASE}/ECL_ps_rotoci_psrel.sh ${ECLFILE}
      curl -k ${WFT_PORT}/builds/${RELEASE} -F "access_key=${WFT_KEY}" -F "build[repository_url]=${RELEASEPSRELREPO}" -X PUT
      curl -k ${WFT_PORT}/builds/${RELEASE} -F "access_key=${WFT_KEY}" -F "build[repository_branch]=tags/${RELEASE}" -X PUT
      curl -k ${WFT_PORT}/builds/${RELEASE} -F "access_key=${WFT_KEY}" -F "build[important_note]=" -X PUT  # remove Important Note
      curl -k ${WFT_API}/upload/${RELEASE} -F "access_key=${WFT_KEY}" -F "file=@${CI2RMFILE}"
      curl -k ${WFT_API}/upload/${RELEASE} -F "access_key=${WFT_KEY}" -F "file=@${ECLFILE}"
      curl -k ${WFT_API}/upload/${RELEASE} -F "access_key=${WFT_KEY}" -F "file=@${PARTLIST}"
   fi
   log "DONE"
}

function create_pit_file ()
{
   log "STARTED"
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}

   local CCSSUBPATH=
   ${SVN} ls ${RELEASEPSRELREPO}/branches/${RELEASE}/C_Platform/CCS/Tar/LINUX_OCTEON2 1>/dev/null 2>/dev/null && CCSSUBPATH=Tar/LINUX_OCTEON2

   local MCUSUBPATH=
   ${SVN} ls ${RELEASEPSRELREPO}/branches/${RELEASE}/C_Platform/MCUHWAPI/Exe/LINUX_OCTEON2 1>/dev/null 2>/dev/null && MCUSUBPATH=Exe/LINUX_OCTEON2

   local DSPSUBPATH=
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/Bin/Nyquist 1>/dev/null 2>/dev/null && DSPSUBPATH=Bin/Nyquist
   ${SVN} ls ${RELEASEPSRELREPO}/DSPHWAPI/tags/${NEW_PS_DSP_BUILD}/C_Platform/DSPHWAPI/bin 1>/dev/null 2>/dev/null && DSPSUBPATH=bin

   local FILE=/home/psapp/shared/prit_`date +%Y%m%d`_`date +%H%M`.txt
   echo "RELEASE=${RELEASE}"                                                                  > ${FILE} || fatal "no access to ${FILE}"
   echo "BASE=${BASE}"                                                                       >> ${FILE} || fatal "no access to ${FILE}"
   echo "CCS=${RELEASEPSRELREPO}/branches/${RELEASE}/C_Platform/CCS/${CCSSUBPATH}"           >> ${FILE} || fatal "no access to ${FILE}"
   echo "MCUHWAPI=${RELEASEPSRELREPO}/branches/${RELEASE}/C_Platform/MCUHWAPI/${MCUSUBPATH}" >> ${FILE} || fatal "no access to ${FILE}"
   echo "DSPHWAPI=${RELEASEPSRELREPO}/branches/${RELEASE}/C_Platform/DSPHWAPI/${DSPSUBPATH}" >> ${FILE} || fatal "no access to ${FILE}"
   echo "CI2RM=${CI2RM}"                                                                     >> ${FILE} || fatal "no access to ${FILE}"
   echo "LFS=${ECL_PS_LFS_OS}"                                                               >> ${FILE} || fatal "no access to ${FILE}"
   log "DONE"
}

###################################################################################################################
