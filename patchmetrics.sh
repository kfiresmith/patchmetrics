#!/bin/bash

# We use /etc/os-release to determine if we are on a supported variant
if [ -f /etc/os-release ]; then
        ID_LIKE="$(grep ID_LIKE /etc/os-release | awk -F"=" '{print $2}' | tr '[:upper:]' '[:lower:]')"
else
        exit 22
fi


case $ID_LIKE in
  *"rhel"*)
      variant=redhat
      ;;
  *"debian"*)
      variant=debian
      ;;
  *)
    exit 23
    ;;
esac


if [ "$variant" == "redhat" ]; then
  security_updates="$(yum list-sec -q | wc -l)"
  all_updates="$(yum check-update -q | wc -l)"
else
  updatedata="$(/usr/lib/update-notifier/apt-check 2>&1)"
  security_updates="$(echo $updatedata | cut -d";" -f2)"
  all_updates="$(echo $updatedata | cut -d";" -f1)"
fi

measurement="package_updates"
tag_set="os=linux,distro=$variant"

influx_timestamp="$(date +%s%N)"


printf "$measurement,$tag_set $field_set security_updates=$security_updates,all_updates=$all_updates $(date +%s%N) \n"
