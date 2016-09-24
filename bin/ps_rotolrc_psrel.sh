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

   FCT_PTR_DEFAULT="calc_ver_num"
}

# Functions to be executed
function call_function ()
{
   case "$1" in
      calc_ver_num )                  calc_ver_num;                  FCT_PTR="combine_psrel";;
      combine_psrel )                 combine_psrel;                 FCT_PTR="create_trbl_log_list";;
      create_trbl_log_list )          create_trbl_log_list;          FCT_PTR="create_vcf_combined";;
      create_vcf_combined )           create_vcf_combined;           FCT_PTR="create_ptsw_fsmr3_vcf";;
      create_ptsw_fsmr3_vcf )         create_ptsw_fsmr3_vcf;         FCT_PTR="create_ptsw_fsmr4_vcf";;
      create_ptsw_fsmr4_vcf )         create_ptsw_fsmr4_vcf;         FCT_PTR="create_ptsw_urec_vcf";;
      create_ptsw_urec_vcf )          create_ptsw_urec_vcf;          FCT_PTR="create_bts_ps_versionfile";;
      create_bts_ps_versionfile )     create_bts_ps_versionfile;     FCT_PTR="create_bts_ps_versionfile_ext";;
      create_bts_ps_versionfile_ext ) create_bts_ps_versionfile_ext; FCT_PTR="create_bts_ps_src_baselines";;
      create_bts_ps_src_baselines )   create_bts_ps_src_baselines;   FCT_PTR="create_psrel_versionstrings";;
      create_psrel_versionstrings )   create_psrel_versionstrings;   FCT_PTR="create_ci2rm";;
      create_ci2rm )                  create_ci2rm;                  FCT_PTR="create_ecl";;
      create_ecl )                    create_ecl;                    FCT_PTR="create_part_list";;
      create_part_list )              create_part_list;              FCT_PTR="create_externals_psrel";;
      create_externals_psrel )        create_externals_psrel;        FCT_PTR="trigger_wft_pspit";;
      trigger_wft_pspit )             trigger_wft_pspit;             FCT_PTR="trigger_wft_psrel";; 
      trigger_wft_psrel )             trigger_wft_psrel;             FCT_PTR="create_pit_file";;
      create_pit_file )               create_pit_file;               FCT_PTR="completed";;
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
check_mcu
check_dsp
check_env_completed
check_ccs_completed
check_mcu_completed
check_dsp_completed

# call functions
while [ $FCT_PTR != "END" ]; do
   call_function $FCT_PTR
done

exit 0

################################################################################################
#EOF
################################################################################################
