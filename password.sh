# exit out if we're not root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Checking if you read the scenario
echo "# Ubuntu Password Policy Script"
echo "# Make sure you READ THE SCENARIO"
echo "# R E A D  T H E  S C E N A R I O"
echo -n "# Are you sure you want to do this? (y/n) "
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ;then
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install libpam-cracklib --force-yes -y
  sudo apt-get install perl --force-yes -y

  # check to see if there is a pam_tally.so line - add if absent, replace if necessary
  tallyExists=$(grep pam_tally.so /etc/pam.d/common-auth|wc -l)

  if [ $tallyExists -eq 0 ]; then
    sudo bash -c 'echo "auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent" >> /etc/pam.d/common-auth'
  else
    sudo perl -pi -e 's/.*pam_tally.so.*/auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent/g' /etc/pam.d/common-auth
  fi

  # check to see if there is a pam_cracklib.so line - add if absent, replace if necessary
  cracklibExists=$(grep pam_cracklib.so /etc/pam.d/common-password|wc -l)

  if [ $cracklibExists -eq 0 ]; then
    sudo bash -c 'echo "password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1" >> /etc/pam.d/common-password'
  else
    sudo perl -pi -e 's/.*pam_cracklib.so.*/password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1/g' /etc/pam.d/common-password
  fi

  # check to see if there is a pam_pwhistory.so line - add if absent, replace if necessary
  historyExists=$(grep pam_pwhistory.so /etc/pam.d/common-password|wc -l)

  if [ $historyExists -eq 0 ]; then
    sudo bash -c 'echo "password requisite pam_pwhistory.so use_authok remember=24 enforce_for_root" >> /etc/pam.d/common-password'
  else
    sudo perl -pi -e 's/.*pam_pwhistory.so.*/password requisite pam_pwhistory.so use_authok remember=24 enforce_for_root/g' /etc/pam.d/common-password
  fi

  # check to see if there is a pam_unix.so line - add if absent, replace if necessary
  unixExists=$(grep pam_unix.so /etc/pam.d/common-password|wc -l)

  if [ $unixExists -eq 0 ]; then
    sudo bash -c 'echo "password [success=1 default=ignore] pam_unix.so obscure use_authtok sha512 shadow" >> /etc/pam.d/common-password'
  else
    sudo perl -pi -e 's/.*pam_unix.so.*/password [success=1 default=ignore] pam_unix.so obscure use_authtok sha512 shadow/g' /etc/pam.d/common-password
  fi

  # check to see if there is a PASS_MIN_DAYS line - add if absent, replace if necessary
  minDaysExists=$(cat /etc/login.defs|grep -v \#|grep PASS_MIN_DAYS|wc -l)

  if [ $minDaysExists -eq 0 ]; then
    sudo bash -c 'echo "PASS_MIN_DAYS 7" >> /etc/login.defs'
  else
    sudo perl -pi -e 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/g' /etc/login.defs
  fi

  # check to see if there is a PASS_MAX_DAYS line - add if absent, replace if necessary
  maxDaysExists=$(cat /etc/login.defs|grep -v \#|grep PASS_MAX_DAYS|wc -l)

  if [ $maxDaysExists -eq 0 ]; then
    sudo bash -c 'echo "PASS_MAX_DAYS 90" >> /etc/login.defs'
  else
    sudo perl -pi -e 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
  fi

  # check to see if there is a PASS_WARN_AGE line - add if absent, replace if necessary
  warnAgeExists=$(cat /etc/login.defs|grep -v \#|grep PASS_WARN_AGE|wc -l)

  if [ $warnAgeExists -eq 0 ]; then
    sudo bash -c 'echo "PASS_WARN_AGE 14" >> /etc/login.defs'
  else
    sudo perl -pi -e 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/g' /etc/login.defs
  fi

  cat /etc/passwd|awk -F\: '{print $1}'|xargs -I {} sudo chage -m 7 -M 90 -I 10 -W 14 {}
else
    echo "READ THE SCENARIO"
    exit
fi
