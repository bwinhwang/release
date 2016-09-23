#!/bin/bash
###################################################################################################
#
# Author:   Binhong-Jason Wang      <binhwang@nokia.com>
# Date:     10-Sep-2016
#
# Description:
#           Convert CI2RM and ECL file in LRC repos
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

   local FCT=${WORKAREA}/bin/ps_functions.sh
   [ -r "${FCT}" ] ||  fatal "${PROG}: Unable to source ${FCT} - bailing out!"
   source ${FCT}

}


PROG=`basename $0`
echo "${PROG}: main: STARTED (`date +%d-%B-%Y\ %H:%M:%S`)"
trap 'echo "${PROG}: interrupt signal - bailing out"; exit 0' 1 2 15   # sig handler for interrupts ...

unset http_proxy ALL_PROXY ftp_proxy      # reset proxies for using wft

sourceEnv

echo "SVN_REVISION: $SVN_REVISION"
# check if fast_track changed
FAST=""
${SVN} log -v -r${SVN_REVISION} http://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH_LRC/ | grep FastTrack && FAST="_FastTrack"

if [ -z ${FAST} ]
then
echo "CI2RM file changed"
else
echo "CI2RM_FastTrack file changed"
fi

ECL_REVISION=`${SVN} cat http://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH_LRC/CI2RM${FAST}@${SVN_REVISION} | grep  'CI2RM_ECL' | sed 's/CI2RM_ECL=//'`

if [ -z ${FAST} ]
then 
	echo "ECL update skipped, find the revision in BTS2LRC.txt"
	source /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/ECL/BTS2LRC.txt
	REVISION=`echo $ECL_REVISION | sed 's/.*@//'`
	echo "REVISION=${REVISION}"
	NEW_ECL_REVISION=r${REVISION}
	echo "NEW_ECL_REVISION=${!NEW_ECL_REVISION}"
	if [ -z ${!NEW_ECL_REVISION} ]
	then 
		echo "No such ECL revision" && exit 1
	fi
	${SVN} checkout http://beisop60.china.nsn-net.net/isource/svnroot/LRC_SCM_PS/CI2RM/MAINBRANCH_LRC/ CI2RM

	${SVN} export --force https://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH_LRC/CI2RM${FAST} CI2RM/

	sed -i "s/@.*/@${!NEW_ECL_REVISION}/" CI2RM/CI2RM${FAST}
	sed -i "s/BTS/LRC/" CI2RM/CI2RM${FAST}

	NEW_CI2RM_REVISION=`${SVN} commit CI2RM/CI2RM${FAST} -m "CI2RM${FAST} automatical update"`
	echo "CI2RM${FAST} updated: ${NEW_CI2RM_REVISION}"

	CI2RM=`echo ${NEW_CI2RM_REVISION} | grep "Committed revision" | sed 's/.*Committed revision //' | sed 's/\.//'`
	
else
	
${SVN} export http://svne1.access.nsn.com/${ECL_REVISION} 
source ECL
cp ECL ECL.bts.bak

source /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/CCS/BTS2LRC.txt
source /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/ENV/BTS2LRC.txt
source /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/UPHWAPI/BTS2LRC.txt
source /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/MCUHWAPI/BTS2LRC.txt

# we convert the revision of ECL_CCS, ECL_PS_ENV, ECL_MCUHWAPI, ECL_DSPHWAPI( rename to ECL_UPHWAPI )

OLD=`echo $ECL_CCS | sed 's/.*@//'`
NEW=r${OLD}
sed -i "s|ECL_CCS=/isource/svnroot/BTS_SC_CCS/MAINBRANCH_LRC/trunk@.*|ECL_CCS=/isource/svnroot/LRC_SC_CCS/MAINBRANCH_LRC/trunk@${!NEW}|" ECL

OLD=`echo $ECL_PS_ENV | sed 's/.*@//'`
NEW=r${OLD}
sed -i "s|ECL_PS_ENV=/isource/svnroot/BTS_I_PS/MAINBRANCH_LRC/trunk@.*|ECL_PS_ENV=/isource/svnroot/LRC_I_PS/MAINBRANCH_LRC/trunk@${!NEW}|" ECL

OLD=`echo $ECL_MCUHWAPI | sed 's/.*@//'`
NEW=r${OLD}
sed -i "s|ECL_MCUHWAPI=/isource/svnroot/BTS_SC_MCUHWAPI/MAINBRANCH_LRC/trunk@.*|ECL_MCUHWAPI=/isource/svnroot/LRC_SC_MCUHWAPI/MAINBRANCH_LRC/trunk@${!NEW}|" ECL

OLD=`echo $ECL_DSPHWAPI | sed 's/.*@//'`
NEW=r${OLD}
sed -i "s|ECL_DSPHWAPI=/isource/svnroot/BTS_SC_DSPHWAPI/MAINBRANCH_LRC/trunk@.*|ECL_UPHWAPI=/isource/svnroot/LRC_SC_UPHWAPI/MAINBRANCH_LRC/trunk@${!NEW}|" ECL


mkdir -p CI2RM ECL_HWAPI
${SVN} checkout http://beisop60.china.nsn-net.net/isource/svnroot/LRC_SCM_PS/ECL/MAINBRANCH_LRC/ECL_HWAPI ECL_HWAPI
cp ECL_HWAPI/ECL ECL.lrc.bak
cp ECL ECL_HWAPI

RET=`${SVN} commit ECL_HWAPI/ECL -m "Convert from ${ECL_REVISION}"`
echo "ECL updated: ${RET}"

NEW_ECL_REVISION=`echo "$RET" | grep "Committed revision" | sed 's/.*Committed revision //' | sed 's/\.//'`

REVISION=`echo ${ECL_REVISION} | sed 's/.*@//'`
echo "r${REVISION}=${NEW_ECL_REVISION}" >> /var/fpwork/work/jenkins/workspace/workingDirSync/MAINBRANCH_LRC/ECL/BTS2LRC.txt

${SVN} checkout http://beisop60.china.nsn-net.net/isource/svnroot/LRC_SCM_PS/CI2RM/MAINBRANCH_LRC/ CI2RM

${SVN} export --force https://svne1.access.nsn.com/isource/svnroot/BTS_SCM_PS/CI2RM/MAINBRANCH_LRC/CI2RM${FAST} CI2RM/

sed -i "s/@.*/@${NEW_ECL_REVISION}/" CI2RM/CI2RM${FAST}
sed -i "s/BTS/LRC/" CI2RM/CI2RM${FAST}

NEW_CI2RM_REVISION=`${SVN} commit CI2RM/CI2RM${FAST} -m "CI2RM${FAST} automatical update"`
echo "CI2RM${FAST} updated: ${NEW_CI2RM_REVISION}"

CI2RM=`echo ${NEW_CI2RM_REVISION} | grep "Committed revision" | sed 's/.*Committed revision //' | sed 's/\.//'`
fi
echo "SCMSYNCOUT: LRC:$CI2RM <- BTS:$SVN_REVISION"


