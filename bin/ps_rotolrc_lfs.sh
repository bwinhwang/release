#!/bin/bash
###################################################################################################
#
# Author:   Binhong-Jason Wang <binhwang@nokia.com>
# Date:     25-AUG-2016
#
# Description:
#           Export from Execute shell of TEMPLATE-1-PS_LFS
#
# <Date>                            <Description>
# 25-AUG-2016: Jason		    first version
#
###################################################################################################

# Source environment
function sourceEnv()
{
   WORKAREA=`dirname ${0}`/..
   cd ${WORKAREA}
   WORKAREA=`pwd`
   cd -

   local ENV=${WORKAREA}/etc/env
   [ -r "${ENV}" ] ||  fatal "${PROG}: Unable to source ${ENV} - bailing out!"
   source ${ENV}

}


################################################################################################
# MAIN
################################################################################################

PROG=`basename $0`
echo "${PROG}: main: STARTED (`date +%d-%B-%Y\ %H:%M:%S`)"
trap 'echo "${PROG}: interrupt signal - bailing out"; exit 0' 1 2 15   # sig handler for interrupts ...
echo "LINSEE_VERSION=${LINSEE_VERSION}"
unset http_proxy ALL_PROXY ftp_proxy      # reset proxies for using wft

sourceEnv


${SVN} cat $CI2RM > CI2RM
${SVN} export  https://svne1.access.nsn.com/isource/svnroot/BTS_SC_LFS/os/trunk/ci/lfs_release/remote_release.sh 
bash remote_release.sh
if [ "$?" != "0" ]; then
  exit 1
fi
mkdir -p $JOB_NAME
echo "$PROMOTED_NUMBER TEMPLATE" > $JOB_NAME/TEMPLATE_revision.txt
mkdir -p /tmp/$NEW_RELEASE
${SVN} cat $CI2RM > /tmp/$NEW_RELEASE/CI2RM
source /tmp/$NEW_RELEASE/CI2RM
${SVN} cat https://svne1.access.nsn.com$CI2RM_ECL > /tmp/$NEW_RELEASE/ECL
source /tmp/$NEW_RELEASE/ECL
ECL_PS_LFS_REL=`echo ${ECL_PS_LFS_REL} | sed 's/-ci.*//'`

echo "OMONELASAMITLOSFETTBRAT: <nobr>$NEW_RELEASE::<a target=_new href="https://wft.inside.nsn.com/builds/show/$ECL_PS_LFS_REL">$ECL_PS_LFS_REL</nobr></a>"

exit 0

################################################################################################
#EOF
################################################################################################
