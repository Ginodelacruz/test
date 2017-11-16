#!/bin/ksh
#
#       Procedure: JUMP_PBRUN
#
PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
#
if [[ -z "$1" ]]
then
    echo "Usage : jump <server-name>"
    exit
else
    HOST=$1
fi
typeset -u HOST_ADDR
HOST_ADDR=`dig +search +short $HOST | grep -v '^;;' | grep '^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$'`
if [[ -z $HOST_ADDR ]]
then
    echo -e "Jump error - DNS lookup error\n"
    echo -e "Please ensure that the supplied parameter is a valid host name."
    echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
    exit
fi
typeset -u HOST_NAME
HOST_NAME=`dig +short -x $HOST_ADDR | grep -v '^;;'`
if [[ -z $HOST_NAME ]]
then
    echo -e "Jump error - DNS reverse lookup error\n"
    echo -e "Please ensure that the supplied parameter is a valid host name."
    echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
    exit
fi
case $HOST_NAME in
    AMRNDHS013.PFIZER.COM.|AMRNDHS014.PFIZER.COM.)
        echo -e "Jump error - Invalid jump host\n"
        echo -e "You are not authorized to jump to DBA Matrix legacy servers."
        echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
        exit
        ;;
    AMRNDHL503.PFIZER.COM.|EMAEDCL040.PFIZER.COM.)
        echo -e "Jump error - Invalid jump host\n"
        echo -e "You are not authorized to jump to DBA Matrix jump servers."
        echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
        exit
        ;;
    AMRNDHL201.PFIZER.COM.)
        echo -e "Jump error - Invalid jump host\n"
        echo -e "You are not authorized to jump to DBA Matrix audit servers."
        echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
        exit
        ;;
esac
case $2 in
    dbaadmin|oracle)
        echo -e "Jump error - Invalid jump user\n"
        echo -e "You must only use jump from your personal active directory account."
        echo -e "Please contact DL-DBA-Matrix-Team if you need assistance.\n"
        exit
        ;;
esac
if [[ "$( ( cat /proc/$3/cmdline ; echo ) | tr "\000" " " )" \
        != "pbrun -u dbaadmin /app/dbaadmin/admin/bin/jump_pbrun $1 $2 $3 " ]]
then
    echo "Error : Jump internal error type 1, please report to DL-DBA-Matrix-Team."
    exit
fi
if [[ "$( ( cat /proc/$$/cmdline ; echo ) | tr "\000" " " )" \
        != "/bin/ksh /app/dbaadmin/admin/bin/jump_pbrun $1 $2 $3 " ]]
then
    echo "Error : Jump internal error type 2, please report to DL-DBA-Matrix-Team."
    exit
fi
if [[ "$( ps -p $3 -o user= )" != "$2" ]]
then
    echo "Error : Jump internal error type 3, please report to DL-DBA-Matrix-Team."
    exit
fi
JUMP_LOG=/oramisc/jump_logs/$( date +\%Y\%m\%d\%H\%M\%S )_$( echo $1 | awk -F. '{ print $1 }' )_$2_$3.log
if [[ -f $JUMP_LOG ]]
then
    echo "Error : Jump internal error type 4, please report to DL-DBA-Matrix-Team."
    exit
fi
umask 077
touch $JUMP_LOG 2> /dev/null
if [[ ! -f $JUMP_LOG ]]
then
    echo "Error : Jump internal error type 5, please report to DL-DBA-Matrix-Team."
    exit
fi
stty -noflsh
ssh -o BatchMode=yes -o GSSAPIAuthentication=no -o StrictHostKeyChecking=no $1 | tee -a $JUMP_LOG