#!/bin/bash
#
# For supported distros and versions, report unapplied available OS patches.
#  Depends on yum/apt to be in good working order with accesss to working upstream repos
#  that provide accurate security bulletins
#
# If yum/apt are broken on a host, there may be security patches that aren't applied but
#  aren't reported accurately.
#
# Output format for InfluxDB 1.x
#
# Currently supports Debian 8+, RHEL/CentOS 6+, and Ubuntu 14.04+.  Unsupported distros/versions
#  will report as EOL, with 999/999 updates to apply.  This is to make sure they show up
#  bold and red in Grafana because unsupported hosts should be decommissioned ASAP.
#
# 2020-11-11 Kodiak Firesmith <firesmith@protonmail.com> 

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
      security_updates="999"
      all_updates="999"
      tag_set="os=linux,distrofamily=eol"
      ;;
esac

printf "$measurement,$tag_set $field_set security_updates=$security_updates,all_updates=$all_updates $(date +%s%N) \n"
