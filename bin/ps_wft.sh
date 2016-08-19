#!/bin/bash
#
# Description:
#       functions for creating release note and handle WFT
#
# Function:                  Description:
#
#
################################################################################################

# get svn log information (output formatted plane text)
function getLogInfoCore ()
{
   local REPOSITORY=${1}
   local NEW_PATH=${2}
   local LAST_PATH=${3}
   local SELECTOR=${4}
   log "${REPOSITORY}"
   log "tags: ${NEW_PATH} : ${LAST_PATH}"

   local NEW_REV=`${SVN} info ${REPOSITORY}/${NEW_PATH} | grep "Last Changed Rev:" | sed 's/Last Changed Rev: //'`
   local LAST_REV=`${SVN} info ${REPOSITORY}/${LAST_PATH} | grep "Last Changed Rev:" | sed 's/Last Changed Rev: //'`
   log "revisions: ${LAST_REV} : ${NEW_REV}"
   CI_COMMENTS="No changes since last tag"
   [[ ${NEW_REV} -lt ${LAST_REV} ]] && CI_COMMENTS="Fallback since last tag"
   if [[ ${NEW_REV} -gt ${LAST_REV} ]] ; then
      LAST_REV=$(getBaseRevision ${REPOSITORY}/${LAST_PATH} ${REPOSITORY}/${NEW_PATH})
      CI_COMMENTS=`${PARSE_SVNLOG} ${NEW_REV} $[ ++LAST_REV ] ${REPOSITORY}/${NEW_PATH} ${SELECTOR}` || 
         fatal "svn error in ${PARSE_SVNLOG}"
      [ -z "${CI_COMMENTS}" ] && CI_COMMENTS="\nNo interface changes since last tag"
   fi
}

# get svn log information (output formatted plane text)
function getLogInfo ()
{
   local REPOSITORY=${1}
   local NEW_TAG=${2}
   local LAST_TAG=${3}
   log "${REPOSITORY}"
   log "tags: ${NEW_TAG} : ${LAST_TAG}"
   for NEWBRANCH in ${BRANCHES} ; do
      ${SVN} ls ${REPOSITORY}/${NEWBRANCH}/tags/${NEW_TAG} 1>/dev/null 2>/dev/null && break
   done
   ${SVN} ls ${REPOSITORY}/${NEWBRANCH}/tags/${NEW_TAG} 1>/dev/null 2>/dev/null ||
     fatal "${REPOSITORY}/${NEWBRANCH}/tags/${NEW_TAG} does not exist in subversion";
   for OLDBRANCH in ${BRANCHES} ; do
      ${SVN} ls ${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} 1>/dev/null 2>/dev/null && break
   done
   ${SVN} ls ${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} 1>/dev/null 2>/dev/null ||
     fatal "${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} does not exist in subversion";
   getLogInfoCore ${REPOSITORY} ${NEWBRANCH}/tags/${NEW_TAG} ${OLDBRANCH}/tags/${LAST_TAG}
}

# get svn log information (output formatted plane text)
function getSelectedLogInfo ()
{
   local REPOSITORY=${1}
   local NEW_PATH=${2}
   local LAST_TAG=${3}
   log "${REPOSITORY}"
   log "tags: ${NEW_PATH} : ${LAST_TAG}"
   for OLDBRANCH in ${BRANCHES} ; do
      ${SVN} ls ${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} 1>/dev/null 2>/dev/null && break
   done
   ${SVN} ls ${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} 1>/dev/null 2>/dev/null ||
     fatal "${REPOSITORY}/${OLDBRANCH}/tags/${LAST_TAG} does not exist in subversion";
   getLogInfoCore ${REPOSITORY} ${NEW_PATH} ${OLDBRANCH}/tags/${LAST_TAG} select
}

function RmEntryInArrayAdd ()
{
   DELETED="NO"
   local ITEM=`echo "${1}" |sed 's/.*\(id=\"[a-zA-Z0-9._-]*\).*/\1/'`
   for (( i=0; i<${#ADD[@]}; i++ )); do
      [[ "${ADD[$i]}" =~ "${ITEM}" ]] && ADD=( "${ADD[@]:0:$i}" "${ADD[@]:$(($i+1))}" ) && DELETED="YES"
   done
}

function RmEntryInArraySub ()
{
   DELETED="NO"
   local ITEM=`echo "${1}" |sed 's/.*\(id=\"[a-zA-Z0-9._-]*\).*/\1/'`
   for (( i=0; i<${#SUB[@]}; i++ )); do
      [[ "${SUB[$i]}" =~ "${ITEM}" ]] && SUB=( "${SUB[@]:0:$i}" "${SUB[@]:$(($i+1))}" ) && DELETED="YES"
   done
}

# find 'Item line' with Pronto and convert it to xml format
function PRToXml ()
{
   local TMP
   local -a ITEMS   # all lines beginning with: 'Item    :' 
   OLD_IFS=${IFS}
   IFS='
'
   ITEMS=( `echo "${1}" | grep "^Item    :"` )
   IFS=${OLD_IFS}
   unset ADD
   unset SUB
   for line in "${ITEMS[@]}"; do
      if [[ "${line}" =~ "\%FIN" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %FIN *%PR=[A-Z0-9]*" | sed 's/^Item    : %FIN *%PR=\([A-Z0-9]*\)\(.*\)$/      <fault id=\"\1\" info=\"FINISHED">PR \1 \2<\/fault>/'`
         if [[ "${TMP}" ]]; then
            ADD=( "${ADD[@]}" "${TMP}" )
            RmEntryInArraySub "${TMP}"
         fi
      elif [[ "${line}" =~ "\%BCK" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %BCK *%PR=[A-Z0-9]*" | sed 's/^Item    : %BCK *%PR=\([A-Z0-9]*\)\(.*\)$/      <fault id=\"\1\" info=\"ROLLBACK">PR \1 \2<\/fault>/'`
         if [[ "${TMP}" ]]; then
            RmEntryInArrayAdd "${TMP}"
            [[ "${DELETED}" == "NO" ]] && SUB=( "${SUB[@]}" "${TMP}" )
         fi
      fi
   done 
}

# ---------------------------------------------------------------------------------------------

# find 'Item line' with New Features and convert it to xml format
function NFToXml ()
{
   local TMP
   local -a ITEMS   # all lines beginning with: 'Item    :' 
   OLD_IFS=${IFS}
   IFS='
'
   ITEMS=( `echo "${1}" | grep "^Item    :"` )
   IFS=${OLD_IFS}
   unset ADD
   unset SUB
   for line in "${ITEMS[@]}"; do
      if [[ "${line}" =~ "\%FIN" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %FIN *%NF=[a-zA-Z0-9._-]*" | sed 's/^Item    : %FIN *%NF=\([a-zA-Z0-9._-]*\)\(.*\)$/      <feature id=\"\1\"> \1: NF \2<\/feature>/'`
         if [[ "${TMP}" ]]; then 
            ADD=( "${ADD[@]}" "${TMP}" )
            RmEntryInArraySub "${TMP}" 
         fi
      elif [[ "${line}" =~ "\%BCK" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %BCK *%NF=[a-zA-Z0-9._-]*" | sed 's/^Item    : %BCK *%NF=\([a-zA-Z0-9._-]*\)\(.*\)$/      <feature id=\"\1\"> \1: NF \2<\/feature>/'`
         if [[ "${TMP}" ]]; then
            RmEntryInArrayAdd "${TMP}"
            [[ "${DELETED}" == "NO" ]] && SUB=( "${SUB[@]}" "${TMP}" )
         fi
      fi
   done
}

# ---------------------------------------------------------------------------------------------

# find 'Item line' with Change Note and convert it to xml format
function CNToXml ()
{
   local TMP
   local -a ITEMS   # all lines beginning with: 'Item    :' 
   OLD_IFS=${IFS}
   IFS='
'
   ITEMS=( `echo "${1}" | grep "^Item    :"` )
   IFS=${OLD_IFS}
   unset ADD
   unset SUB
   for line in "${ITEMS[@]}"; do
      if [[ "${line}" =~ "\%FIN" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %FIN *%CN=[a-zA-Z0-9._-]*" | sed 's/^Item    : %FIN *%CN=\([a-zA-Z0-9._-]*\)\(.*\)$/      <changenote id=\"\1\"> \1: CN \2<\/changenote>/'`
         if [[ "${TMP}" ]]; then
            ADD=( "${ADD[@]}" "${TMP}" )
            RmEntryInArraySub "${TMP}"
         fi
      elif [[ "${line}" =~ "\%BCK" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %BCK *%CN=[a-zA-Z0-9._-]*" | sed 's/^Item    : %BCK *%CN=\([a-zA-Z0-9._-]*\)\(.*\)$/      <changenote id=\"\1\"> \1: CN \2<\/changenote>/'`
         if [[ "${TMP}" ]]; then
            RmEntryInArrayAdd "${TMP}"
            [[ "${DELETED}" == "NO" ]] && SUB=( "${SUB[@]}" "${TMP}" )
         fi
      fi
   done
}

# ---------------------------------------------------------------------------------------------

# find 'REM line' and convert it to xml format
function REMToXml ()
{
   local TMP
   local REVB="https://psreviewboard.emea.nsn-net.net/r/"
   local -a ITEMS   # all lines beginning with: 'Item    :' 
   OLD_IFS=${IFS}
   IFS='
'
   ITEMS=( `echo "${1}" | grep "^Item    :"` )
   IFS=${OLD_IFS}
   unset ADD
   unset SUB
   for line in "${ITEMS[@]}"; do
      if [[ "${line}" =~ "\%REM" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %REM *.*" | sed 's/^Item    : %REM *\(.*\)$/\1/'`
         [[ "${TMP}" ]] && ADD=( "${ADD[@]}" "${TMP}" )
      fi
      if [[ "${line}" =~ "\%RB" ]]; then
         TMP=`echo "${line}" | grep "^Item    : %RB=" | sed -e "s|^Item    : %\(RB=\)\([0-9]*\).*$|\1\2 ${REVB}\2/|"`
         [[ "${TMP}" ]] && ADD=( "${ADD[@]}" "${TMP}" )
      fi
   done
}

# creation of txt-file
function createTxtFile ()
{
   log "Started"
   local NEW=${1}
   local OLD=${2}
   local RELNOTETXT=${3}
   echo "Release : ${NEW}" > ${RELNOTETXT}
   echo "Based on: ${OLD}" >> ${RELNOTETXT}
   echo "Date    : ${DATE_NOW}" >> ${RELNOTETXT}
   echo "Time    : ${TIME_NOW}" >> ${RELNOTETXT}
   echo "" >> ${RELNOTETXT}
   echo "Corrections: " >> ${RELNOTETXT}
   echo "============" >> ${RELNOTETXT}
   echo "${CI_COMMENTS}" >> ${RELNOTETXT}
   chmod 755 ${RELNOTETXT}
   log "Done"
}

# creation of html-file 
function createHtmlFile ()
{
   log "Started"
   RELNOTEXML=${1}
   RELNOTEHTML=${2}
   # convert xml to html
   SAXO="/build/ltesdkroot/Tools/Tools/saxon/saxon9/saxon9.jar"
   java -cp ${SAXO} net.sf.saxon.Transform -xi -s ${RELNOTEXML} -o ${RELNOTEHTML} ${RELEASENOTE_XSL}
   # substitute the pronto id with the link to the pronto tool 
   TMPHTML="${RELEASEDIR}/${RELEASE}/relnote.xml"
   [ -e ${TMPHTML} ] && rm ${TMPHTML}
   while read line; do
      if [[ "${line}" =~ "<td>[0-9]{5,6}ESPE[0-9]{2}<\/td>" ]]; then
         echo -e "${line}" | sed 's/<td>\(.*\)<\/td>/<td><a href=\"http:\/\/eslpe004.emea.nsn-net.net\/nokia\/pronto\/pronto.nsf\/PRID\/\1?OpenDocument\" target=\"_blank\">\1<\/a>/g' >> ${TMPHTML}
      else
        echo -e "${line}" >> ${TMPHTML}
      fi
   done < "${RELNOTEHTML}"
   # clean up tmporary files
   mv ${TMPHTML} ${RELNOTEHTML}
   chmod 755 ${RELNOTEHTML}
   log "Done"
}

# Send delivery notification to WFT
function triggerWft ()
{
   local OLD=${1}
   local NEW=${2}
   local TESTING=${3}
   local RELNOTEXML=${4}
   shift; shift; shift; shift;
   if [[ "${NEW}" != "${OLD}" ]]; then
      RET=`${TEST} curl -s -k ${WFT_API}/xml_validate -F "access_key=${WFT_KEY}" -F "file=@${RELNOTEXML}"`
      [[ "${RET}" =~ "XML valid" ]] || fatal "curl validation failed: ${RELNOTEXML} not valid: ${RET}"
      log "curl validation successful for ${NEW}"
      if [ -z ${TEST} ]; then
         if [ "${TESTING}" ]; then
            RET=`${TEST} curl -k ${WFT_API}/xml -F "access_key=${WFT_KEY}" -F "file=@${RELNOTEXML}" -F "testing=yes"`
         else
            RET=`${TEST} curl -k ${WFT_API}/xml -F "access_key=${WFT_KEY}" -F "file=@${RELNOTEXML}"`
         fi
         log "RET: ${RET}"
         [[ "${RET}" =~ "XML valid" ]] || fatal "wft creation of '${NEW}' failed, ${RET}"
         log "curl create has been executed for ${NEW}"
         for i in $* ; do
            ${TEST} curl -k ${WFT_API}/upload/${NEW} -F "access_key=${WFT_KEY}" -F "file=@${i}"
         done
         log "curl uploads has been executed for ${NEW}"
      fi
   fi
}

# write baselines to variable
function getBaselinesForXml ()
{
   [[ -z ${ECL_GLOBAL_ENV} ]] && fatal "GLOBAL_ENV not defined"
   XMLBASELINES=`echo "      <baseline auto_create=\"true\" name=\"GLOBAL_ENV\">${ECL_GLOBAL_ENV}</baseline>"`
   [[ ${NEW_PS_ENV} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"PS_ENV\">${NEW_PS_ENV}</baseline>"`
   [[ ${ECL_PS_LFS_SDK1} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LINUX_SDK1\">${ECL_PS_LFS_SDK1}</baseline>"`
   [[ ${ECL_PS_LFS_SDK2} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LINUX_SDK2\">${ECL_PS_LFS_SDK2}</baseline>"`
   [[ ${ECL_PS_LFS_SDK3} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LINUX_SDK3\">${ECL_PS_LFS_SDK3}</baseline>"`
   [[ ${ECL_PS_LFS_OS} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"PS_LINUX_OS\">${ECL_PS_LFS_OS}</baseline>"`
   [[ ${ECL_PS_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"PS_LINUX_REL\">${ECL_PS_LFS_REL}</baseline>"`
   [[ ${ECL_PS_PNS_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"PNS_LFS\">${ECL_PS_PNS_LFS_REL}</baseline>"`
   [[ ${ECL_PS_LFS_SDK_YOCTO} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_SDK\">${ECL_PS_LFS_SDK_YOCTO}</baseline>"`
   [[ ${ECL_PS_LRC_LFS_OS} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LFS_OS\">${ECL_PS_LRC_LFS_OS}</baseline>"`
   [[ ${ECL_PS_LRC_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LFS_REL\">${ECL_PS_LRC_LFS_REL}</baseline>"`
   [[ ${ECL_PS_LRC_LCP_LFS_OS} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LCP_LFS_OS\">${ECL_PS_LRC_LCP_LFS_OS}</baseline>"`
   [[ ${ECL_PS_LRC_LCP_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LCP_LFS_REL\">${ECL_PS_LRC_LCP_LFS_REL}</baseline>"`
   [[ ${ECL_PS_LRC_LSP_LFS_OS} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LSP_LFS_OS\">${ECL_PS_LRC_LSP_LFS_OS}</baseline>"`
   [[ ${ECL_PS_LRC_LSP_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"LRC_LSP_LFS_REL\">${ECL_PS_LRC_LSP_LFS_REL}</baseline>"`
   [[ ${ECL_PS_FZM_LFS_OS} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"FZM_LFS_OS\">${ECL_PS_FZM_LFS_OS}</baseline>"`
   [[ ${ECL_PS_FZM_LFS_REL} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"FZM_LFS_REL\">${ECL_PS_FZM_LFS_REL}</baseline>"`
   [[ ${ECL_OSE_53} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSE_53_BL\">${ECL_OSE_53}</baseline>"`
   [[ ${ECL_OSE_461} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSE_461_BL\">${ECL_OSE_461}</baseline>"`
   [[ ${ECL_TI_CGT} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_CGT_BL\">${ECL_TI_CGT}</baseline>"`
   [[ ${ECL_TI_CGT_WCDMA} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_CGT_BL_WCDMA\">${ECL_TI_CGT_WCDMA}</baseline>"`
   [[ ${ECL_TI_CGT_FSPB} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_CGT_FSPB_BL\">${ECL_TI_CGT_FSPB}</baseline>"`
   [[ ${ECL_TI_CSL_FSPB} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_CSL_FSPB_BL\">${ECL_TI_CSL_FSPB}</baseline>"`
   [[ ${ECL_TI_DCI_FSPB} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_DCI_FSPB_BL\">${ECL_TI_DCI_FSPB}</baseline>"`
   [[ ${ECL_TI_AET_FSPB} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_AET_FSPB_BL\">${ECL_TI_AET_FSPB}</baseline>"`
   [[ ${ECL_OSECK_4} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSECK_4_BL\">${ECL_OSECK_4}</baseline>"`
   [[ ${ECL_DSP_BGT} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"DSP_BGT\">${ECL_DSP_BGT}</baseline>"`
   [[ ${ECL_SWBUILD} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"SWBUILD\">${ECL_SWBUILD}</baseline>"`
   [[ ${ECL_OSECK_4_1_NY} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSECK_4_1_NY_BL\">${ECL_OSECK_4_1_NY}</baseline>"`
   [[ ${ECL_OSECK_4_1_NY_WCDMA} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSECK_4_1_NY_BL_WCDMA\">${ECL_OSECK_4_1_NY_WCDMA}</baseline>"`
   [[ ${ECL_TI_CGT_NYQUIST} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"DSP_NYQUIST1\">${ECL_TI_CGT_NYQUIST}</baseline>"`
   [[ ${ECL_TI_AET_NYQUIST} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"DSP_NYQUIST2\">${ECL_TI_AET_NYQUIST}</baseline>"`
   [[ ${ECL_TI_NYQUIST_PDK} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_NYQUIST_PDK\">${ECL_TI_NYQUIST_PDK}</baseline>"`
   [[ ${ECL_TI_K2_MCSDK} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_K2_MCSDK\">${ECL_TI_K2_MCSDK}</baseline>"`
   [[ ${ECL_TI_KEPLER_PDK} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_KEPLER_PDK\">${ECL_TI_KEPLER_PDK}</baseline>"`
   [[ ${ECL_OSECK_4_1_K2} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"OSECK_4_1_K2\">${ECL_OSECK_4_1_K2}</baseline>"`
   [[ ${ECL_TI_CGT_K2} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_CGT_K2\">${ECL_TI_CGT_K2}</baseline>"`
   [[ ${ECL_TI_AET_K2} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"TI_AET_K2\">${ECL_TI_AET_K2}</baseline>"`
   [[ ${ROTOCI_VERSION} ]] && XMLBASELINES=`echo "${XMLBASELINES}
      <baseline auto_create=\"true\" name=\"ROTOCI\">${ROTOCI_VERSION}</baseline>"`
   echo "${XMLBASELINES}"
}

################################################################################################
