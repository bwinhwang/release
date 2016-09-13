#!/bin/bash
#
# Description:
#       functions for bash needed by several ps production scripts
#
# Function:                  Description:
#   fatal, warn, log			
#   incRebuildVersion, incBuildVersion, resetBuildVersion 
#   checkoutEcl
#
#
################################################################################################

# Error handling
function fatal ()
{
   [ "$TERM" = "xterm" ] && tput bold
   echo "${PROG} [$$]: ### ERROR ### $1 - bailing out" 1>&2
   [ "$TERM" = "xterm" ] && tput sgr0
#   echo "${PROG}: killing background jobs ..."
#   pkill -15 -P $$ -u ${USER}      # SIGTERM
#   sleep 2
#   pkill -9 -P $$ -u ${USER}       # SIGKILL
   echo "${PROG}: METRICS: FAILED `date +%Y%m%d-%H:%M:%S`"
   exit 1
}

# Warning
function warn ()
{
   echo "${PROG}: ${FUNCNAME[1]}: ### WARNING ### $1" 1>&2
}

# Log
function log ()
{
   echo "${PROG}: ${FUNCNAME[1]}: $1 (`date +%H:%M:%S`)"
}

# 
function sourceRest ()
{
   local WFTFCT=${WORKAREA}/bin/ps_wft.sh
   [ -r "${WFTFCT}" ] ||  fatal "${PROG}: Unable to source ${WFTFCT} - bailing out!"
   source ${WFTFCT}

   local ENVFCT=${WORKAREA}/bin/ps_env.sh
   [ -r "${ENVFCT}" ] ||  fatal "${PROG}: Unable to source ${ENVFCT} - bailing out!"
   source ${ENVFCT}

   local CCSFCT=${WORKAREA}/bin/ps_ccs.sh
   [ -r "${CCSFCT}" ] ||  fatal "${PROG}: Unable to source ${CCSFCT} - bailing out!"
   source ${CCSFCT}

   local MCUFCT=${WORKAREA}/bin/ps_mcu.sh
   [ -r "${MCUFCT}" ] ||  fatal "${PROG}: Unable to source ${MCUFCT} - bailing out!"
   source ${MCUFCT}

   local DSPFCT=${WORKAREA}/bin/ps_dsp.sh
   [ -r "${DSPFCT}" ] ||  fatal "${PROG}: Unable to source ${DSPFCT} - bailing out!"
   source ${DSPFCT}

   local RELFCT=${WORKAREA}/bin/ps_rel.sh
   [ -r "${RELFCT}" ] ||  fatal "${PROG}: Unable to source ${RELFCT} - bailing out!"
   source ${RELFCT}
}

# find all active branches
function findBranches ()
{
   ${SVN} ls ${SVNPS}/CI2RM 1>/dev/null 2>/dev/null || fatal "${SVNPS}/CI2RM does not exist"
   BRANCHES=`${SVN} ls ${SVNPS}/CI2RM | grep -vE ${IGNORED_BRANCHES} | sed -e 's|/||'`
   ${SVN} ls ${SVNPS}/CI2RM/customize 1>/dev/null 2>/dev/null || fatal "${SVNPS}/CI2RM/customize does not exist"
   BRANCHES="${BRANCHES}
`${SVN} ls ${SVNPS}/CI2RM/customize | sed -e 's|\(.*\)/|customize/\1|'`"

   log "BRANCHES=
${BRANCHES}"
}

# calculates PS_REL repository name
function findPsRelRepo_OLD ()
{
   local PSRELRELEASE=${1}
   log "PSRELRELEASE: ${PSRELRELEASE}"
   local REG0="PS_REL_20[0-9A-Z][0-9]_"
   [[ "${PSRELRELEASE}" =~ $REG0 ]] || fatal "PSRELELEASE malformed"
   local REG1="PS_REL_20[0-9][0-9]_[0-9]{2}_[0-9]{3}(-[0-9])?$"
   local REG2="PS_REL_20[0-9A-Z][0-9]_[0-9]{2}_[0-9]{2}(-[0-9]{1,2})?$"
   [[ "${PSRELRELEASE}" =~ $REG1 ]] ||  [[ "${PSRELRELEASE}" =~ $REG2 ]] || fatal "version string malformed"

   local NUM=`echo "${PSRELRELEASE}" | sed "s/.*PS_REL_20[0-9A-Z]\([0-9]\)_.*/201\1/"`
   PSRELREPO="${SVNURL}/BTS_D_PS_REL_${NUM}"
   log "PSRELREPO: ${PSRELREPO}"
}

# calculates PS_REL repository name
function findPsRelRepo ()
{
   local PSREL=${1}
   log "PS_RELEASE: ${PSREL}"
   local REG0="PS_REL_20[0-9]{2}_[0-9]{2}_[0-9]{3}(-[0-9])?$"
   local REG1="PS_REL_20[0-9A-Z]{2}_[0-9]{2}_[0-9]{2}(-[0-9]{1,2})?$"
   [[ "${PSREL}" =~ $REG0 ]] || [[ "${PSREL}" =~ $REG1 ]] || fatal "PS_RELEASE malformed"

   local NUM=`echo "${PSREL}" | sed "s/.*PS_REL_20[0-9A-Z]\([0-9]\)_.*/201\1/"`
   PSRELREPO="${SVNURL}/BTS_D_PS_REL_${NUM}"
   log "old PSRELREPO to be checked: ${PSRELREPO}"

   ${SVN} ls ${PSRELREPO}/branches/${PSREL} 1>/dev/null 2>/dev/null || NUM=`echo "${PSREL}" | sed "s/.*PS_REL_20[0-9A-Z]\([0-9]_[0-9][0-9]\)_.*/201\1/"`
   PSRELREPO="${SVNURL}/BTS_D_PS_REL_${NUM}"

   log "new PSRELREPO to be used   : ${PSRELREPO}"
}

# calculates PTSW repository name
function findPtswRepo ()
{
   local PTSWRELEASE=${1}
   log "PTSWRELEASE: ${PTSWRELEASE}"
   local REG0="PTSW_.*_20[0-9][0-9]_"
   [[ "${PTSWRELEASE}" =~ $REG0 ]] || fatal "PTSWRELEASE malformed" 
   local NUM=`echo "${PTSWRELEASE}" | sed "s/.*PTSW_.*\(20[0-9][0-9]\)_.*/\1/"`
   PTSWREPO="${SVNURL}/BTS_D_PTSW_${NUM}"
   log "PTSWREPO: ${PTSWREPO}"
}

# calculates LFS (FZM, LRC, LSP) D-repository name
function findLfsRelRepo ()
{
   local LFSRELEASE=${1}
   local FILE=${RELEASEDIR}/${RELEASE}/lfsrepo.txt
   log "LFSRELEASE: ${LFSRELEASE}"
   local REG0="PS_LFS_REL_"
   [[ "${LFSRELEASE}" =~ $REG0 ]] || fatal "LFS RELEASE malformed"
   LFSRELREPO=$(echo ${LFSRELEASE} | sed -r -e 's/^.*PS_LFS_REL_([^_]+)_([^_]+)_.*$/BTS_D_SC_LFS_\1_\2/')
   log "${SVN} ls ${LFSSERVER}/${LFSRELREPO}/tags"
   ${SVN} ls ${SVNURL}/${LFSRELREPO}/tags > ${FILE} || fatal "${SVNURL}/${LFSRELREPO}/tags not accessible"
   grep "^${LFSRELEASE}" ${FILE} || LFSRELREPO=BTS_D_SC_LFS
   log "LFSRELREPO: ${LFSRELREPO}"
}

# 
function findBaselines ()
{
   local PSRELRELEASE=${1}
   log "PSRELRELEASE: ${PSRELRELEASE}"
   findPsRelRepo ${PSRELRELEASE}
   ${SVN} ls ${PSRELREPO}/branches/${PSRELRELEASE} 1>/dev/null 2>/dev/null ||
     fatal "${PSRELREPO}/branches/${PSRELRELEASE} does not exist"
   ${SVN} ls ${PSRELREPO}/branches/${PSRELRELEASE}/BTS_PS_versionfile.txt 1>/dev/null 2>/dev/null ||
     fatal "${PSRELREPO}/branches/${PSRELRELEASE}/BTS_PS_versionfile.txt does not exist"
   local VERSIONFILE=`${SVN} cat ${PSRELREPO}/branches/${PSRELRELEASE}/BTS_PS_versionfile.txt` || fatal "svn cat failed"
   PS_ENV=`echo "${VERSIONFILE}" | grep "^PS_ENV=.*PS_ENV_" | sed 's/PS_ENV=//'`
   PS_LFS_REL=`echo "${VERSIONFILE}" | grep "^LFS_REL=.*PS_LFS_REL_" | sed 's/LFS_REL=//'`
   PS_CCS_SW=`echo "${VERSIONFILE}" | grep "^PS_CCS=.*CCS_SW_" | sed 's/PS_CCS=//'`
   PS_CCS_BUILD=`echo "${VERSIONFILE}" | grep "^CCS_BUILD=.*CCS_BUILD_" | sed 's/CCS_BUILD=//'`
   PS_DSP_SW=`echo "${VERSIONFILE}" | grep "^PS_DSPHWAPI=.*PS_DSPHWAPI_SW_" | sed 's/PS_DSPHWAPI=//'`
   PS_DSP_BUILD=`echo "${VERSIONFILE}" | grep "^DSPHWAPI_BUILD=.*PS_DSPHWAPI_BUILD_" | sed 's/DSPHWAPI_BUILD=//'`
   PS_MCU_SW=`echo "${VERSIONFILE}" | grep "^PS_MCUHWAPI=.*PS_MCUHWAPI_SW_" | sed 's/PS_MCUHWAPI=//'`
   PS_MCU_BUILD=`echo "${VERSIONFILE}" | grep "^MCUHWAPI_BUILD=.*PS_MCUHWAPI_BUILD_" | sed 's/MCUHWAPI_BUILD=//'`
   log "PS_ENV: ${PS_ENV}"
   log "PS_LFS_REL: ${PS_LFS_REL}"
   log "PS_CCS_SW: ${PS_CCS_SW}"
   log "PS_CCS_BUILD: ${PS_CCS_BUILD}"
   log "PS_DSP_SW: ${PS_DSP_SW}"
   log "PS_DSP_BUILD: ${PS_DSP_BUILD}"
   log "PS_MCU_SW: ${PS_MCU_SW}"
   log "PS_MCU_BUILD: ${PS_MCU_BUILD}"
}

# find file
function findFile ()
{
   log "LEFT: ${1}"
   ORIGFILE=`readlink -e ${1}`
   [[ -z ${ORIGFILE} ]] && fatal "${1} does not exist"
   log "ORIG: ${ORIGFILE}"
}

# Compares two directories 
# Returns all files and directories which are existing in dir1 but not in dir2
# example: dirDiff <dir1> <dir2> |sort -r |xargs svn rm
#          dirDiff <dir2> <dir1> |sort -r |xargs svn add
function dirDiff ()
{
   local DIR1=${1}
   local DIR2=${2}
   [ -z ${DIR2} ] && fatal "parameter missing"
   [ ! -d ${DIR1} ] && fatal "directory '${DIR1}' not found"
   [ ! -d ${DIR2} ] && fatal "directory '${DIR2}' not found"
   cd ${DIR1}
   for i in `find . -type f`; do
      /bin/ls ${DIR2}/$i >/dev/null 2>&1
      if [ "$?" != "0" ]; then
         /bin/ls ${DIR2}/$i >/dev/null 2>&1  # check it again, because of nfs problem !
         if [ "$?" != "0" ]; then            # sometimes the first ls is not up to date
            echo $i
         fi
      fi
   done
   cd - > /dev/null 2>&1
   exit 0
}

# increments last one/two digits of the given string, expected input *-[0-9]{1,2} or *_[0-9]{1,2}
function incBuildVersion ()
{
   local VERSION=${1}
   log "OLDVERSION: ${VERSION}"
   local BL=
   local NUM=
   local REG0="_BL$"
   [[ "${VERSION}" =~ $REG0 ]] && BL="_BL" && VERSION=`echo ${VERSION} | sed 's/_BL//'`
   if [[ "${NEWNAMESCHEMA}" ]] ; then
      local REG1=".*[_]999$"
	  local REG2=".*[-]9$"
      [[ "${VERSION}" =~ $REG1 ]] && fatal "version string overflow"
      [[ "${VERSION}" =~ $REG2 ]] && fatal "version string overflow"
   else
      local REG3=".*[-_]99$"
      [[ "${VERSION}" =~ $REG3 ]] && fatal "version string overflow"
   fi
   local REG4=".*[-_][0-9]{3}$"
   local REG5=".*[-_][0-9]{2}$"
   local REG6=".*[-_][0-9]$"
   if [[ "${NEWNAMESCHEMA}" && "${VERSION}" =~ $REG4 ]]; then
      NUM=`echo "${VERSION}" | awk -F "" '{printf ("%03d", ($(NF-2)$(NF-1)$NF)+1)}'`
      VERSION=`echo ${VERSION} | sed 's/[0-9][0-9][0-9]$//'`
   elif [[ "${VERSION}" =~ $REG5 ]]; then
      NUM=`echo "${VERSION}" | awk -F "" '{printf ("%02d", ($(NF-1)$NF)+1)}'`
      VERSION=`echo ${VERSION} | sed 's/[0-9][0-9]$//'`
   elif [[ "${VERSION}" =~ $REG6 ]]; then
      NUM=`echo "${VERSION}" | awk -F "" '{printf ("%01d", ($NF)+1)}'`
      VERSION=`echo ${VERSION} | sed 's/[0-9]$//'`
   else
      fatal "version string malformed"
   fi
   INCVERSION="${VERSION}${NUM}${BL}"
   log "INCVERSION: ${INCVERSION}"
}

# extends the the given version string with patch number '-00'
function addPatchNumber()
{
   local VERSION=${1}
   local SUFFIX=
   local BL=
   log "VERSION: ${VERSION}"
   local REG0="^.*[-_][0-9]{1,3}(_BL)?$"
   local REG1="^.*_BL$"
   [[ "${VERSION}" =~ $REG0 ]] || fatal "version string malformed"
   [[ "${VERSION}" =~ $REG1 ]] && BL="_BL" && VERSION=`echo ${VERSION} | sed 's/_BL$//'`
   local REG2="^.*-[0-9]$"
   local REG3="^.*-[0-9]{2}$"
   if [[ "${NEWNAMESCHEMA}" ]] ; then
      [[ "${VERSION}" =~ $REG2 ]] || SUFFIX="-1"
   else
      [[ "${VERSION}" =~ $REG3 ]] || SUFFIX="-01"
   fi
   PATCHVERSION="${VERSION}${SUFFIX}${BL}"
   log "PATCHVERSION: ${PATCHVERSION}"
}

# removes for special branches patch number (if any) from a given version
function delPatchNumber()
{
   local VERSION=${1}
   local BL=
   log "VERSION: ${VERSION}"
   DELVERSION=${VERSION}
   local REG0="^.*_BL$"
   [[ "${VERSION}" =~ $REG0 ]] && BL="_BL" && VERSION=`echo ${VERSION} | sed 's/_BL$//'`
   VERSION=`echo ${VERSION} | sed 's/-..\?$//'`
   DELVERSION="${VERSION}${BL}"
   log "DELVERSION: ${DELVERSION}"
}

function switchToNewType ()
{
   local REPO=${1}
   local SC=${2}
   local RELEASETYPE=`echo -e ${RELEASE} | sed "s/_[^_]*$//"`
   if [[ "${REPO}" == "${SVNENV}" ]]; then
      NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/PS_ENV/"`
      else if [[ "${REPO}" == "${SVNCCS}" ]]; then
         NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/CCS_SW/"`
         else if [[ "${REPO}" == "${SVNMCU}" ]]; then
            NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/PS_MCUHWAPI_SW/"`
            else if [[ "${REPO}" == "${SVNDSP}" ]]; then
               NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/PS_DSPHWAPI_SW/"`
               else if [[ "${SC}" == "CCS" ]]; then
                  NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/CCS_BUILD/"`
                  else if [[ "${SC}" == "MCUHWAPI" ]]; then
                     NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/PS_MCUHWAPI_BUILD/"`
                     else if [[ "${SC}" == "DSPHWAPI" ]]; then
                        NEWTAG=`echo -e ${RELEASETYPE} | sed "s/PS_REL/PS_DSPHWAPI_BUILD/"`
                     else
                        log "REPO: ${REPO}"
                        log "SC: ${SC}"
                        log "RELEASETYPE: ${RELEASETYPE}"
                        fatal "unable to determine NEWTAG"
                     fi
                  fi
               fi
            fi
         fi
      fi
   fi
   if [[ "${NEWNAMESCHEMA}" ]] ; then
      NEWTAG=${NEWTAG}_00
   else
      NEWTAG=${NEWTAG}_0
   fi
   if [[ "${BRANCH}" == "MAINBRANCH" ]] ; then
      NEWTAG=${NEWTAG}0
   else
      NEWTAG=${NEWTAG}1
   fi
}

function switchToNewPrefix ()
{
   local TAGPREFIX=${1}
   local RELEASEPREFIX=${2}
   NEWTAG=`echo -e ${TAG} | sed "s/${TAGPREFIX}/${RELEASEPREFIX}/"`
   if [ "${PATCH}" ]; then
      addPatchNumber ${NEWTAG}
      NEWTAG=${PATCHVERSION}
   else
      delPatchNumber ${NEWTAG}
      NEWTAG=${DELVERSION}
   fi
   incBuildVersion ${NEWTAG}
   NEWTAG=${INCVERSION}
}

function incTag ()
{
   local REPO=${1}
   local TAG=${2}
   local SC=${3}
   log "REPO: ${REPO}"
   log "TAG: ${TAG}"
   log "SC: ${SC}"
   if [ "${SC}" ] ; then
      SCORBRANCHES=${SC}
   else
      SCORBRANCHES="${BRANCHES}"
   fi
   if [ "${PATCH}" ]; then
      addPatchNumber ${TAG}
      TAG=${PATCHVERSION}
   else
      delPatchNumber ${TAG}
      TAG=${DELVERSION}
   fi
   while [ "1" ]; do
      for COMPONENTORBRANCH in ${SCORBRANCHES} ; do 
         ${SVN} ls ${REPO}/${COMPONENTORBRANCH}/tags/${TAG} 1>/dev/null 2>/dev/null && break 
      done
      ! ${SVN} ls ${REPO}/${COMPONENTORBRANCH}/tags/${TAG} 1>/dev/null 2>/dev/null && 
      ! ${SVN} ls ${REPO}/${COMPONENTORBRANCH}/branches/${TAG} 1>/dev/null 2>/dev/null && break;
      incBuildVersion ${TAG}
      TAG=${INCVERSION}
   done
   UNUSEDTAG=${TAG}
}

# detects the new tag of a component on base of the old one considering patch or no patch and new branch or no new branch
function defineTag ()
{
   local REPO=${1}
   local TAG=${2}
   local SC=${3}
   log "REPO: ${REPO}"
   log "TAG: ${TAG}"
   log "SC: ${SC}"
   local RELEASETYPE=
   local TAGTYPE=
   local RELEASEPREFIX=
   local TAGPREFIX=
   if [[ "${NEWNAMESCHEMA}" ]] ; then
      RELEASETYPE=`echo -e ${RELEASE} | sed "s/_[^_]*$//" | sed "s/.*PS_REL_//"`
      TAGTYPE=`echo -e ${TAG} | sed "s/_[^_]*$//" | sed "s/.*PS_ENV_//" | sed "s/.*CCS_SW_//" | sed "s/.*PS_MCUHWAPI_SW_//" |
                     sed "s/.*PS_DSPHWAPI_SW_//" | sed "s/.*CCS_BUILD_//" | sed "s/.*PS_MCUHWAPI_BUILD_//" | sed "s/.*PS_DSPHWAPI_BUILD_//"`
      RELEASEPREFIX=`echo -e ${RELEASE} sed "s/_[^_]*$//" | sed "s/PS_REL//" | sed "s/__.*//"`
      TAGPREFIX=`echo -e ${TAG} | sed "s/_BL//" | sed "s/_[^_]*$//" | sed "s/PS_ENV//" | sed "s/CCS_SW//" | sed "s/PS_MCUHWAPI_SW//" |
                     sed "s/PS_DSPHWAPI_SW//" | sed "s/CCS_BUILD//" | sed "s/PS_MCUHWAPI_BUILD//" | sed "s/PS_DSPHWAPI_BUILD//" | sed "s/__.*//"`
   else
      RELEASETYPE=`echo -e ${RELEASE} | sed "s/_[^_]*$//" | sed "s/PS_REL//"`
      TAGTYPE=`echo -e ${TAG} | sed "s/_BL//" | sed "s/_[^_]*$//" | sed "s/PS_ENV//" | sed "s/CCS_SW//" | sed "s/PS_MCUHWAPI_SW//" |
                     sed "s/PS_DSPHWAPI_SW//" | sed "s/CCS_BUILD//" | sed "s/PS_MCUHWAPI_BUILD//" | sed "s/PS_DSPHWAPI_BUILD//"`
   fi

   log "RELEASETYPE: ${RELEASETYPE}"
   log "TAGTYPE: ${TAGTYPE}"
   log "RELEASEPREFIX: ${RELEASEPREFIX}"
   log "TAGPREFIX: ${TAGPREFIX}"
   if [[ "${RELEASETYPE}" != "${TAGTYPE}" ]]; then
      switchToNewType ${REPO} ${SC}
      incTag ${REPO} ${NEWTAG} ${SC}
      else if [[ "${RELEASEPREFIX}" != "${TAGPREFIX}" ]]; then
         switchToNewPrefix ${TAGPREFIX} ${RELEASEPREFIX}
         incTag ${REPO} ${NEWTAG} ${SC}
      else
         incTag ${REPO} ${TAG} ${SC}
      fi
   fi
   log "UNUSEDTAG: ${UNUSEDTAG}"
}

# check if some files checked in after tagging
function checkChanges ()
{
   local REPO=${1}
   local REVISION=${SVNSERVER}${2}
   local TAG=${3}
   local FOUND=

   log "REPO: ${REPO}"
   log "TAG: ${TAG}"
   log "REVISION: ${REVISION}"

   for COMPONENTORBRANCH in ${BRANCHES} ; do
      ${SVN} ls ${REPO}/${COMPONENTORBRANCH}/tags/${TAG} 1>/dev/null 2>/dev/null && FOUND=YES && break
   done
   [[ ! "${FOUND}" ]] && fatal "${TAG} does not exist in subversion repository ${REPO}"
   log "FOUND IN: ${COMPONENTORBRANCH}"

   DIFFERENCE=`${SVN} diff --summarize ${REVISION} ${REPO}/${COMPONENTORBRANCH}/tags/${TAG} | wc -l` || fatal "${SVN} diff --summarize ${REVISION} ${REPO}/${COMPONENTORBRANCH}/tags/${TAG} failed"
   log "DIFFERENCE: ${DIFFERENCE}"
}

function tagIt ()
{
   local REPOSITORY=${1}
   local RELEASE_BRANCH=${SVNSERVER}${2}
   local NEW_TAG=${3}
   log "REPOSITORY=${REPOSITORY}"
   log "RELEASE_BRANCH=${RELEASE_BRANCH}"
   log "NEW_TAG=${NEW_TAG}"
   local SRC=${RELEASE_BRANCH}
   local DST=${REPOSITORY}/${BRANCH}/tags/${NEW_TAG}
   ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      fatal "svn cp ${SRC} ${DST} failed"
}

function unzipComponent ()
{
   local ZIP=${1}
   local NEW_TAG=${2}
   log "ZIP=${ZIP}"
   log "NEW_TAG=${NEW_TAG}"
   local SOURCE=${RELEASEDIR}/${RELEASE}/${NEW_TAG}
   [ -d ${SOURCE} ] || mkdir ${SOURCE}
   unzip -o -d ${SOURCE} ${ZIP} || fatal "unzip -d ${SOURCE} ${ZIP} failed"
   findFile ${ZIP}
   echo ${ORIGFILE} > ${SOURCE}/.version
   ln -s ${ZIP} /build/home/ps_rel_ci/PS_CI_LIBS/RM/${NEW_TAG}.zip
}

function importAndTagIt ()
{
   local REPOSITORY=${1}
   local NEW_TAG=${2}
   log "REPOSITORY=${REPOSITORY}"
   log "NEW_TAG=${NEW_TAG}"
   local SOURCE=${RELEASEDIR}/${RELEASE}/${NEW_TAG}
   local SRC=${REPOSITORY}/branches/${NEW_TAG}
   ${SVN} ls ${SRC} 1>/dev/null 2>/dev/null && ${TEST} ${SVN} rm ${SRC} -m "${ROTOCI_VERSION}"
   ${TEST} ${SVN} mkdir ${SRC} -m "${ROTOCI_VERSION}" --parents ||
      ${TEST} ${SVN} mkdir ${SRC} -m "${ROTOCI_VERSION}" --parents ||
      fatal "svn mkdir ${SRC} failed"
   ${TEST} ${SVN} import ${SOURCE} ${SRC} --no-ignore -m "${ROTOCI_VERSION}" || fatal "svn import ${SOURCE} ${SRC} failed"
   local DST=${REPOSITORY}/tags/${NEW_TAG}
   ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      ${TEST} ${SVN} cp ${SRC} ${DST} -m "${ROTOCI_VERSION}" --parents || 
      fatal "svn cp ${SRC} ${DST} failed"
}

# search the first revision which is in history of both versions
function getBaseRevision ()
{
   LAST=${1}
   CURRENT=${2}
   ALL_REVISIONS_LAST=`${SVN} log -q ${LAST} | awk '/^r/{print substr($1,2)}'`
   ALL_REVISIONS_CURRENT=`${SVN} log -q ${CURRENT} | awk '/^r/{print substr($1,2)}'`
   for last_revision in $ALL_REVISIONS_LAST ; do
      for current_revision in $ALL_REVISIONS_CURRENT ; do
         [[ "${last_revision}" == "${current_revision}" ]] && break;
      done
      [[ "${last_revision}" == "${current_revision}" ]] && break;
   done
   [[ "${last_revision}" == "${current_revision}" ]] || fatal "no base revision found"
   echo "${last_revision}"
}

# map branch to branch name(s) used in workflow tool
function mapBranchName ()
{
   local BR="${1}="   # PR internal branch name (e.g.: 20M2_08)
   local MAPFILE=${ETCDIR}/map
#   [[ "${BR}" =~ "20.[0-9]_[0-9][0-9]" ]] || [[ "${BR}" =~ "MAINBRANCH" ]] || fatal "Branch name not valid"
   unset BRANCH_FOR
   PROJECTS=`cat "${MAPFILE}" | grep ${BR} | sed "s/.*=//"`
   if [[ -z ${PROJECTS} ]]; then 
      warn "No project name found in mapping table"
   else
      for PROJECT in ${PROJECTS}; do
         PROJECT=`echo -e "${PROJECT}" | sed "s/#/ /g"`
         BRANCH_FOR="${BRANCH_FOR} -F \"branch_for[]=${PROJECT}\""
      done
   fi
}

# Help
function usage()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG}"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} [-t] -b <base> -r <release> -i <ci2rm> [-f <functionpointer>] [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is releasing PS_REL."
   echo ""
   echo -e "\t-t  must be set for test run"
   echo -e "\t-b  name of the base release"
   echo -e "\t-r  name of new release"
   echo -e "\t-i  path to CI2RM"
   echo -e "\t-f  functionpointer for restart"
   echo -e "\t-h  help text"
   echo ""
   echo "EXAMPLE"
   echo -e "\t${PROG} -b PS_REL_2011_12_00 -r PS_REL_2011_12_01 -i https://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH/CI2RM@4711"
   echo ""
}

# Process the command line
function process_cmd_line()
{
   log "STARTED"
   BASE=                  # name of the base build
   RELEASE=               # name of the new build 
   FCT_PTR=               # start with this function, used in function 'call_function'
   TEST=

   while getopts :b:r:i:f:th OPTION; 
   do
      case ${OPTION} in
         b) BASE=${OPTARG};;
         r) RELEASE=${OPTARG};;
         i) CI2RM=${OPTARG};;
         f) FCT_PTR=${OPTARG};;
         t) TEST=echo;;
         h) usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; usage ;;
         \?) echo "Invalid option: -${OPTARG}"; usage ;;
      esac
   done

   [ -z "${BASE}" ] && fatal "Parameter '-b' not defined"
   [ -z "${RELEASE}" ] && fatal "Parameter '-r' not defined"
   [ -z "${CI2RM}" ] && fatal "Parameter '-i' not defined"
   log "BASE: ${BASE}"
   log "RELEASE: ${RELEASE}"
   log "CI2RM: ${CI2RM}"
   log "FCT_PTR: ${FCT_PTR}"
   log "TEST: ${TEST}"
   log "DONE"
}

# Check SVN access, define start point
function prepare_start()
{
   log "STARTED"
   set -o pipefail
   RESULT=`${SVN} --username psprod list ${SVNAUTH}`
   [ "${RESULT}" = "Your_iSource_Auth_Works_OK" ] || fatal "iSource Authentication FAILED"
   log "iSource Authentication is OK"

   RESULT=`curl -k ${WFT_CHECK} 2>/dev/null`
   [ "${RESULT}" = "File not found" ] || fatal "WFT check FAILED"
   log "WFT access is OK"

   [ -d ${RELEASEDIR}/${RELEASE} ] || mkdir ${RELEASEDIR}/${RELEASE}
   cp ${ETCDIR}/map ${RELEASEDIR}/${RELEASE}

   local REG0="-[0-9]{1,2}$"
   if [[ "${RELEASE}" =~ $REG0 ]] ; then
      PATCH=true
   else
      PATCH=
   fi

   local REG1="PS_REL_[0-9]{4}_[0-9]{2}_[0-9]{3}"
   if [[ "${RELEASE}" =~ $REG1 ]] ; then
      NEWNAMESCHEMA=true
   else
      NEWNAMESCHEMA=
   fi

   local REG2="CI2RM_FastTrack"
   if [[ "$CI2RM" =~ $REG2 ]]; then
      FAST=fast_track
   else
      FAST=no_fast_track
   fi
   log "FAST: ${FAST}"

   findBranches

   BRANCH=`echo ${CI2RM} | sed 's/.*\/isource\/svnroot\/BTS_SCM_PS\/CI2RM\///' | sed 's/\/CI2RM.*//'`
   log "BRANCH: ${BRANCH}"

   findBaselines ${BASE}
   BASEPSRELREPO=${PSRELREPO}
   findPsRelRepo ${RELEASE}
   RELEASEPSRELREPO=${PSRELREPO}
   ${SVN} ls ${RELEASEPSRELREPO}/tags/${RELEASE} 1>/dev/null 2>/dev/null && fatal "${PSRELREPO}/tags/${RELEASE} exists already"

   local CI2RM_FILE=${RELEASEDIR}/${RELEASE}/CI2RM_${PROG}
   ${SVN} cat ${CI2RM} > ${CI2RM_FILE} || fatal "svn cat ${CI2RM} > ${CI2RM_FILE} failed"
   source ${CI2RM_FILE}

   while [ ! -r "${CI2RM_CCS}" ]; do
      log "waiting for ${CI2RM_CCS}"
      sleep 60
   done
   while [ ! -r "${CI2RM_MCU}" ]; do
      log "waiting for ${CI2RM_MCU}"
      sleep 60
   done
   while [ ! -r "${CI2RM_DSP}" ]; do
      log "waiting for ${CI2RM_DSP}"
      sleep 60
   done

   local ECL_FILE=${RELEASEDIR}/${RELEASE}/ECL_${PROG}
   ${SVN} cat ${SVNSERVER}${CI2RM_ECL} > ${ECL_FILE} || fatal "svn cat ${SVNSERVER}${CI2RM_ECL} > ${ECL_FILE} failed"
   sed -i 's/-ci[0-9][0-9]*$//' ${ECL_FILE}  # remove -ci*
   source ${ECL_FILE}                        # source without -ci*
   ${SVN} cat ${SVNSERVER}${CI2RM_ECL} > ${ECL_FILE} || fatal "svn cat ${SVNSERVER}${CI2RM_ECL} > ${ECL_FILE} failed"

   PS_ENV_BRANCH=`echo -e ${ECL_PS_ENV} | sed "s/@.*//" | sed "s|[^/]*$|branches/rb_${RELEASE}|"`
   PS_CCS_BRANCH=`echo -e ${ECL_CCS} | sed "s/@.*//" | sed "s|[^/]*$|branches/rb_${RELEASE}|"`
   PS_MCU_BRANCH=`echo -e ${ECL_MCUHWAPI} | sed "s/@.*//" | sed "s|[^/]*$|branches/rb_${RELEASE}|"`
   PS_DSP_BRANCH=`echo -e ${ECL_UPHWAPI} | sed "s/@.*//" | sed "s|[^/]*$|branches/rb_${RELEASE}|"`
   ROTOCI_VERSION=`${SVN} info ${WORKAREA} | grep ^URL | sed 's/.*\///'`

   CONFIG_FILE=${RELEASEDIR}/${RELEASE}/config_${PROG}
   [ -r ${CONFIG_FILE} ] && source ${CONFIG_FILE}

   FCT_PTR_FILE=${RELEASEDIR}/${RELEASE}/fctptr_${PROG}
   [ -z "${FCT_PTR}" ] && [ -r ${FCT_PTR_FILE} ] && source ${FCT_PTR_FILE}
   [ -z "${FCT_PTR}" ] && FCT_PTR=${FCT_PTR_DEFAULT}

   log "DONE"
}

# Completion script execution
function completed()
{
   echo FCT_PTR=${FCT_PTR} > ${FCT_PTR_FILE}
   echo "${PROG}: STARTED: ALL DONE (`date +%H:%M:%S`)"
   exit 0
}

################################################################################################
