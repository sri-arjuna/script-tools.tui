# fedora-live-mini.ks
#
# Defines the basics for all kickstarts in the fedora-mini branch

lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --enablemd5
selinux --permissive
firewall --enabled --service=mdns
xconfig --startxonboot
part / --size 4096 --fstype ext4
services --enabled=network,NetworkManager,sshd,messagebus,avahi-daemon --disabled=iscsi,iscsid,lldpad,sendmail

#repo --name=rawhide --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=$basearch
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
#repo --name=updates-testing --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-testing-f$releasever&arch=$basearch

%packages
