#!/bin/bash
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     17-Jan-2011
#
# Description:
#           remove platform branches from svn 
#
######################################################################################

PROG=`basename ${0}`
DATE_NOW="date +%Y/%m/%d"
TIME_NOW="date +%H:%M:%S"
TIMEZONE="date +%Z"

# signal handler for interrupts ...
trap 'echo ""; echo "${PROG}: ABORTED"; echo ""; exit 0' SIGHUP SIGINT SIGTERM

# Function: Usage
function local_usage()
{
   echo ""
   echo "NAME"
   echo -e "\t${PROG} - Preparation of new branch for platform production"
   echo ""
   echo "SYNOPSIS"
   echo -e "\t${PROG} -r <base release> | -o <base branch> -b <new branch> [-t <branch time> -d <dummy release>] -w <WFTBranches> [-h]"
   echo ""
   echo "DESCRIPTION"
   echo -e "\tThe purpose of this script is to create a new branch from an tagged PS_REL or from a branch at a certain time"
   echo ""
   echo -e "\t-b  name of the new branch which should be created"
   echo ""
   echo "EXAMPLE"
   echo -e "\t${PROG} -b 'FB1403 FB1404'" 
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
  [ -r "${ENV}" ] || ( echo "${PROG}: Unable to source ${ENV} - bailing out!"; exit 1 )
  source ${ENV}

  FCT=${WORKAREA}/bin/ps_functions.sh
  [ -r "${FCT}" ] || ( echo "${PROG}: Unable to source ${FCT} - bailing out!"; exit 1 )
  source ${FCT}

  sourceRest
}

# Function: Taking over command line parameters
function local_process_cmd_line()
{
   while getopts ":b:h" OPTION; 
   do
      case "${OPTION}" in
         b) BRANCHES=${OPTARG};;
         h) local_usage; exit 0;;
         :) echo "Option -${OPTARG} requires an argument"; local_usage ;;
         \?) echo "Invalid option: -${OPTARG}"; local_usage ;;
      esac
   done
}

function removeBranch ()
{
   local REPO=${1}
   ${SVN} mv --parents -m "${BRANCH}" ${REPO}/${BRANCH} ${REPO}/obsolete/${BRANCH} >/dev/null || warn "svn mv ${REPO}/${BRANCH} ${REPO}/obsolete/${BRANCH} failed"
   log "svn mv ${REPO}/${BRANCH} ${REPO}/obsolete/${BRANCH} done"
}

function remove_map ()
{
   log "TBD"
}
 
function remove_branches ()
{
   log "STARTED"
   for BRANCH in ${BRANCHES} ; do
      ${SVN} ls ${SVNPS}/CI2RM/customize/${BRANCH} 1>/dev/null 2>/dev/null && BRANCH=customize/${BRANCH}
#      removeBranch ${SVNENV}
      removeBranch ${SVNCCS}
      removeBranch ${SVNMCU}
      removeBranch ${SVNDSP}
      removeBranch ${SVNPS}/CI2RM
      removeBranch ${SVNPS}/ECL
      #remove_map
   done
   log "DONE"
}

function hide_wft_branch ()
{
   log "STARTED"
   local BRANCH=
   local BRANCH_ID=
   for BRANCH in ${BRANCHES} ; do
      BRANCH_ID=`curl ${WFT_PORT}/PS/branches.xml?access_key=${WFT_KEY} |grep title=\"${BRANCH}\"`
      if [ ! "${BRANCH_ID}" ]; then
         warn "BRANCH ${BRANCH} not found in WFT"
      else
         BRANCH_ID=`echo ${BRANCH_ID} | sed -e "s|^.*<branch id=\"\([0-9]*\)\".*$|\1|"`
         log "BRANCH = ${BRANCH} (ID:${BRANCH_ID})"
         log "${WFT_PORT}/management/branches/${BRANCH_ID}/toggle.js?item=hidden&value=true&access_key=WFT_KEY"
         curl "${WFT_PORT}/management/branches/${BRANCH_ID}/toggle.js?item=hidden&value=true&access_key=${WFT_KEY}"
      fi
   done
   log "DONE"
}

function send_mail ()
{
   log "STARTED"
   SUB="Platform Branch(es) ${BRANCHES} removed"
   FROM="scm-ps-prod@mlist.emea.nsn-intra.net"
   TO="scm-ps-int@mlist.emea.nsn-intra.net"
   CC="scm-ps-prod@mlist.emea.nsn-intra.net"
   MSG="branch(es) ${BRANCHES} removed from svn repositories

      ${SVNCCS}
      ${SVNMCU}
      ${SVNDSP}
      ${SVNPS}/CI2RM
      ${SVNPS}/ECL

Best regards
PS SCM
"
   ${SEND_MSG} --from="${FROM}" --to="${TO}" --cc="${CC}" --subject="${SUB}" --body="${MSG}" || warn "Unable to ${SEND_MSG}"
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
local_process_cmd_line "$@"
remove_branches
hide_wft_branch
send_mail

echo "${PROG}: All Done ${START_TIME} - `${TIME_NOW}` `${TIMEZONE}`"
echo ""
exit 0

##################################################
# EOF
##################################################
