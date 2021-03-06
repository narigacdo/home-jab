#!/bin/bash

hostnamectl set-hostname $proxy_hostname

get_so -s | grep CentOS && {
	setenforce permissive
	sed -i.bak "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config
	systemctl stop firewalld
	systemctl disable firewalld
}

grep $foreman_hostname /etc/hosts || echo "$ip_foreman $foreman_hostname" >> /etc/hosts
grep $proxy_hostname /etc/hosts || echo "$ip_proxy $proxy_hostname" >> /etc/hosts

ssh -t $ip_foreman "grep $proxy_hostname /etc/hosts || echo \"$ip_proxy $proxy_hostname\" >> /etc/hosts"
ssh -t $ip_foreman "ls /etc/puppetlabs/puppet/ssl/certs/$proxy_hostname.pem || /opt/puppetlabs/bin/puppet cert generate $proxy_hostname"

mkdir -p /etc/puppetlabs/puppet/ssl/certs/
mkdir -p /etc/puppetlabs/puppet/ssl/private_keys/
scp root@$ip_foreman:/etc/puppetlabs/puppet/ssl/certs/ca.pem \
  /etc/puppetlabs/puppet/ssl/certs/ca.pem
scp root@$ip_foreman:/etc/puppetlabs/puppet/ssl/certs/$proxy_hostname.pem \
  /etc/puppetlabs/puppet/ssl/certs/$proxy_hostname.pem
scp root@$ip_foreman:/etc/puppetlabs/puppet/ssl/private_keys/$proxy_hostname.pem \
  /etc/puppetlabs/puppet/ssl/private_keys/$proxy_hostname.pem

consumer_key="$(ssh -t $ip_foreman 'foreman-installer --help | grep foreman-proxy-oauth-consumer-key | cut -d \" -f 2' | dos2unix)"
consumer_secret="$(ssh -t $ip_foreman 'foreman-installer --help | grep foreman-proxy-oauth-consumer-secret | cut -d \" -f 2' | dos2unix)"
