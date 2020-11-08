#!/bin/bash

# We use /etc/os-release to determine if we are on a supported variant
if [ -f /etc/os-release ]; then
        ID_LIKE="$(grep ID_LIKE /etc/os-release | awk -F"=" '{print $2}' | tr '[:upper:]' '[:lower:]')"
else
        exit 22
fi


measurement="package_updates"

case $ID_LIKE in
  *"rhel"*)
      security_updates="$(yum list-sec -q | wc -l)"
      all_updates="$(yum check-update -q | wc -l)"
      tag_set="os=linux,distrofamily=redhat"
      ;;
  *"debian"*)
      updatedata="$(/usr/lib/update-notifier/apt-check 2>&1)"
      security_updates="$(echo $updatedata | cut -d";" -f2)"
      all_updates="$(echo $updatedata | cut -d";" -f1)"
      tag_set="os=linux,distrofamily=debian"
      ;;
  *)
    exit 23
    ;;
esac

printf "$measurement,$tag_set $field_set security_updates=$security_updates,all_updates=$all_updates $(date +%s%N) \n"
