#!/bin/bash

unset http_proxy ALL_PROXY ftp_proxy
declare -r USER='admin'
declare -r PASS='123456789'
declare -r URL='http://ullink22.emea.nsn-net.net:1080'
declare -r JOBS_DIR='/var/fpwork/jenkins/jobs'
declare -r ALL_JOBS="TEMPLATE-6-PS_REL TEMPLATE-5-PS_DSP TEMPLATE-4-PS_MCU TEMPLATE-3-PS_CCS TEMPLATE-2-PS_ENV TEMPLATE-1-PS_LFS TEMPLATE-0-PS-CI-RM"
declare -r ALL_PROMOTIONS="0-Selected_for_release 1-PS_LFS 2-PS_ENV 3-PS_CCS 4-PS_MCU 5-PS_DSP 6-PS_REL"
declare -r TMPFILE="./tmp.xml"
declare -r DEBUG=1

###########################################

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
}

function local_usage ()
{
   echo "Parameter <name of new branch> invalid!"
   echo "Usage:  `basename $0` <name of new branch>"
   echo "        e.g.: <name of new branch>: 20M2_99"
   echo "              <name of new branch>: 2012_08_WCDMA"
   echo "              <name of new branch>: FB1303_05_03"
   echo ""
   exit 1
}

function fatal ()
{
   [ "$TERM" = "xterm" ] && tput bold
   echo "${PROG} [$$]: ### ERROR ### $1 - bailing out" 1>&2
   [ "$TERM" = "xterm" ] && tput sgr0
   echo "${PROG}: FAILED `date +%Y%m%d-%H:%M:%S`"
   exit 1
}

# debug output
function debug ()
{
   [[ ${DEBUG} ]] && echo -e "...DEBUG ${1}"
}

# Check Input (structure of branch name)
function check_branch () {
   [[ "${BRANCH}" ]] || local_usage
#   [[ "${BRANCH}" =~ "^20[0-9A-Z][0-9]_[0-9]{2}.*$|^FB[0-9]{4}.*|^MD[0-9]{5}.*|LRC[0-9]{4}.*|FZM[0-9]{4}.*|TST_.*" ]] || local_usage
   echo "##### copy job started"
   echo "##### branch name: '${BRANCH}'"
}

# Check existence of TEMPLATE jobs
function check_jobs () {
   echo -e "\n##### check jobs"
   for JOB in ${ALL_JOBS} ; do
      if [[ -r ${JOBS_DIR}/${JOB}/config.xml ]]; then
         debug "job found: ${JOBS_DIR}/${JOB}"
      else
         fatal "job does not exist: ${JOBS_DIR}/${JOB}" 
      fi
   done
   echo "##### all jobs found"
}

# Create jobs
function create_jobs () {
   echo -e "\n##### create jobs"
   for JOB in ${ALL_JOBS} ; do
      NEW_JOB=`echo ${JOB} | sed "s/TEMPLATE/${BRANCH}/g"`
      debug "copy/create job: ${JOB} --> ${NEW_JOB}" 
      cp ${JOBS_DIR}/${JOB}/config.xml ${TMPFILE} 
      sed -i "s/TEMPLATE/${BRANCH}/g" ${TMPFILE}

      # insert 'customize' into path if the branch is found in repo below 'customize'
      debug "${SVNPS}/CI2RM/customize/${BRANCH}"
      ${SVN} ls ${SVNPS}/CI2RM/customize/${BRANCH} 1>/dev/null 2>/dev/null &&
         sed -i "/\<remote\>/s/${BRANCH}/customize\/${BRANCH}/" ${TMPFILE}

      debug "wget --auth-no-challenge --no-proxy -v --user=$USER --password=PASS "${URL}/createItem?name=${NEW_JOB}" --post-file=${TMPFILE} --header='Content-type: application/xml;charset=ISO-8859-1'"
      wget --auth-no-challenge --no-proxy -v --user=$USER --password=${PASS} "${URL}/createItem?name=${NEW_JOB}" --post-file=${TMPFILE} --header='Content-type: application/xml;charset=ISO-8859-1'
      [ "$?" != "0" ] && fatal "wget createItem ${NEW_JOB} failed"
   done
   rm ${TMPFILE}
   echo "##### all jobs created"
}

# Check existence of promotions
function check_promotions () {
   echo -e "\n##### check promotion jobs"
   for PROMO in ${ALL_PROMOTIONS} ; do
      if [[ -r ${JOBS_DIR}/TEMPLATE-0-PS-CI-RM/promotions/${PROMO}/config.xml ]]; then
         debug "promotion found: ${JOBS_DIR}/TEMPLATE-0-PS-CI-RM/promotions/${PROMO}"
      else
         fatal "job not found: ${JOBS_DIR}/TEMPLATE-0-PS-CI-RM/promotions/${PROMO}"
      fi
   done
   echo "##### all promotion jobs found"
}

# Create config.xml files 
function create_promotions () {
   echo -e "\n##### copy promotion configuration"
   for PROMO in ${ALL_PROMOTIONS} ; do
      CP_SRC="${JOBS_DIR}/TEMPLATE-0-PS-CI-RM/promotions/${PROMO}"
      CP_DST="${JOBS_DIR}/${BRANCH}-0-PS-CI-RM/promotions/${PROMO}"
      mkdir -p ${CP_DST}
      debug "cp ${CP_SRC}/config.xml\n         to ${CP_DST}"
      cp ${CP_SRC}/config.xml ${CP_DST}
      sed -i "s/TEMPLATE/${BRANCH}/g" ${CP_DST}/config.xml
   done
   echo "##### all promotion jobs copied"
}

# update job (only one job with the promotions must be updated)
function update_job () {
   echo -e "\n##### update job ${BRANCH}-0-PS-CI-RM"
   JOB=${URL}/job/${BRANCH}-0-PS-CI-RM/config.xml
   XML=${JOBS_DIR}/${BRANCH}-0-PS-CI-RM/config.xml
   if [[ -r ${XML} ]]; then  
      debug "wget update job: ${JOB}\nwith job config: ${XML}"
   else
      fatal "job configuration is missing! (maybe job creation failed)"
   fi
   debug "wget --header='Content-type: application/xml; charset=ISO-8859-1' --auth-no-challenge --no-proxy -v --user=${USER} --password=PASS ${JOB} --post-file=${XML}"
   wget --header='Content-type: application/xml; charset=ISO-8859-1' --auth-no-challenge --no-proxy -v --user=${USER} --password=${PASS} ${JOB} --post-file=${XML}
   [ "$?" != "0" ] && fatal "wget update ${JOB} failed"
}

###########################################
# main function
###########################################

BRANCH=${1}
local_source_env
check_branch
check_jobs
create_jobs
check_promotions
create_promotions
update_job
echo "##### copy job done\n"

###########################################
# eof
###########################################
