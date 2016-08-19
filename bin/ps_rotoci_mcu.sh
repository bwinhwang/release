#!/bin/bash
###################################################################################################
#
# Author:   Ubbo Heyken      <ubbo.heyken@nsn.com>
#           Hans-Uwe Zeisler <hans-uwe.zeisler@nsn.com>
# Date:     21-Nov-2011
#
# Description:
#           Build the Platform ENV Release
#
# <Date>                            <Description>
# 21-Nov-2011: Hans-Uwe Zeisler      first version
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

   sourceRest 

   FCT_PTR_DEFAULT="branch_mcu_sw"
}

# Functions to be executed
function call_function ()
{
   case "$1" in
      branch_mcu_sw )                 branch_mcu_sw;                 FCT_PTR="create_externals_mcu_sw";;
      create_externals_mcu_sw )       create_externals_mcu_sw;       FCT_PTR="define_mcu_sw";;
      define_mcu_sw )                 define_mcu_sw;                 FCT_PTR="tag_mcu_sw";;
      tag_mcu_sw )                    tag_mcu_sw;                    FCT_PTR="define_mcu_build";;
      define_mcu_build )              define_mcu_build;              FCT_PTR="tag_mcu_build";;
      tag_mcu_build )                 tag_mcu_build;                 FCT_PTR="create_output_files_mcu_sw";;
      create_output_files_mcu_sw )    create_output_files_mcu_sw;    FCT_PTR="trigger_wft_mcu_sw";; 
      trigger_wft_mcu_sw )            trigger_wft_mcu_sw;            FCT_PTR="create_output_files_mcu_build";;
      create_output_files_mcu_build ) create_output_files_mcu_build; FCT_PTR="trigger_wft_mcu_build";; 
      trigger_wft_mcu_build )         trigger_wft_mcu_build;         FCT_PTR="send_mail_mcu";;
      send_mail_mcu )                 send_mail_mcu;                 FCT_PTR="completed";;
      completed)                      completed;                     FCT_PTR="END";;
      *)                              fatal "No correct entry point defined"
   esac
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
process_cmd_line $@
prepare_start                             # this function sets the FCT_PTR
check_env
check_ccs

# call functions
while [ $FCT_PTR != "END" ]; do
   call_function $FCT_PTR
done

exit 0

################################################################################################
#EOF
################################################################################################
