#!/bin/bash
ls ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -q -P ""

cat > $HOME/.ssh/config << EOF
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF
ssh-copy-id root@$ip_foreman

yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install https://yum.theforeman.org/releases/1.15/el7/x86_64/foreman-release.rpm
yum install -y dos2unix foreman-installer

hostnamectl set-hostname $proxy_hostname
setenforce permissive
sed -i.bak "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld

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
