#!/bin/bash


measurement="package_updates"
variant="redhat"
unameout="$(uname -a | tr '[:upper:]' '[:lower:]')"

which yum 1>/dev/null || variant="debian"

if [ "$variant" == "debian" ]; then
  which apt 1>/dev/null || variant="unsupported"
fi

case $variant in
  redhat)
      security_updates="$(yum -q updateinfo list security | wc -l)"
      all_updates="$(yum check-update -q | wc -l)"
      tag_set="os=linux,distrofamily=redhat"
      ;;
  debian)
      if [ -f "/usr/lib/update-notifier/apt-check" ]; then
        updatedata="$(/usr/lib/update-notifier/apt-check 2>&1)"
        security_updates="$(echo $updatedata | cut -d";" -f2)"
        all_updates="$(echo $updatedata | cut -d";" -f1)"
      else
        security_updates="$(apt-get upgrade -s | egrep '^Inst ' | grep -i security | wc -l)"
        all_updates="$(apt-get upgrade -s | egrep '^Inst ' | wc -l)"
      fi
      if [ x"$(echo $unameout | grep ubuntu)" == x ]; then
        tag_set="os=linux,distrofamily=debian"
      else
        tag_set="os=linux,distrofamily=ubuntu"
      fi
      ;;
  unsupported)
    exit 23
    ;;
esac

printf "$measurement,$tag_set $field_set security_updates=$security_updates,all_updates=$all_updates $(date +%s%N) \n"
