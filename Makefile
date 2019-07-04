# VirtIO driuver image download URL
driver_url=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso


# Microsoft VM settings
vm_url=https://az792536.vo.msecnd.net/vms/VMBuild_20171019/VirtualBox/MSEdge/MSEdge.Win10.VirtualBox.zip
# default password of the VM
initial_pw=Passw0rd!
# host binding port for SSH to VM
port=22022
rdpport=3389


# Configuration to be applied to the VM
hostname=win10-openage
username=chantal
password=wololo


# Shorthands
d=downloaded
t=temporary
privkey=ssh_host_ed25519_key
pubkey=$(privkey).pub


# Test for dependencies. Not sure if this is the right way to handle them.
.PHONY: sshpass unzip 7z wget qemu-img qemu-system-x86_64
sshpass:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
unzip:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
7z:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
wget:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
qemu-img:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
qemu-system-x86_64:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'

# SSH hostkey generation.
$(privkey):
	rm -f $(privkey) $(pubkey)
	ssh-keygen -f $(privkey) -t ed25519 -N ''

$(pubkey): $(privkey)


# Download and unpacking section
$d:
	mkdir $@

$d/virtio.iso: | wget
	# Google for RedHat Windows virtio drivers
	wget -c -O $@.tmp $(driver_url)
	mv $@.tmp $@

$d/win10.zip: | $d wget
	# New URLS to be found at modern.ie
	wget -c -O $@ $(vm_url)

$d/win10.ova: $d/win10.zip | unzip
	unzip -p $^ > $@
	rm $^

$d/win10.vmdk: $d/win10.ova
	tar xOf $^ "MSEdge - Win10-disk001.vmdk" > $@
	rm $^


# converted image
win10.base.qcow2: $d/win10.vmdk | qemu-img
	qemu-img convert -O qcow2 $^ $@

# overlay image
win10.qcow2: win10.base.qcow2 | qemu-img
	qemu-img create -f qcow2 -b $^ $@

# helper files. cheap to create, will be automatically deleted when no longer needed
$t:
	mkdir $@

$t/helper.qcow2: | $t qemu-img
	qemu-img create -f qcow2 $@ 1G

$t/vm_default_host_key.pub: $d/win10.vmdk | $t 7z
	7z e -so $^ 'Program Files/OpenSSH/etc/ssh_host_ecdsa_key.pub' > $@


# Initial preparations in the VM. Includes changing hostname, username, password, disabling updates and installing viostor drivers
.ONESHELL: vm-stage1
vm-stage1: | $d/virtio.iso $t/vm_default_host_key.pub $(pubkey) $(privkey) win10.qcow2 $t/helper.qcow2 qemu-system-x86_64 sshpass
	@set -m
	echo "[localhost]:$(port) $$(cut -d' ' -f1,2 $t/vm_default_host_key.pub)" > $t/known_host
	echo Starting VM with virtio helper disk
	qemu-system-x86_64 \
	-drive file=win10.qcow2,if=ide \
	-drive file=$t/helper.qcow2,if=virtio \
	-drive file=$d/virtio.iso,media=cdrom \
	-machine type=q35,accel=kvm \
	-m 8G -smp cores=2,threads=1 \
	-net nic -net user,hostfwd=tcp::$(port)-:22 \
	-vga std -display none &
	echo Waiting for VM to respond on port 22
	sleep 5
	while ! sshpass -p '$(initial_pw)' ssh -p $(port) -o UserKnownHostsFile=$t/known_host -o ConnectTimeout=1 IEUser@localhost 'echo "   Machine is up"' 2> /dev/null; do echo -n "."; sleep 1; done
	sshpass -p '$(initial_pw)' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'mkdir -p /cygdrive/c/stage1'
	sshpass -p '$(initial_pw)' scp -P $(port) -o UserKnownHostsFile=$t/known_host stage1.ps1 $(pubkey) $(privkey) IEUser@localhost:/cygdrive/c/stage1
	sshpass -p '$(initial_pw)' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'powershell C:\\stage1\\stage1.ps1 -Hostname $(hostname) -Username $(username) -Password $(password) -ResX 1920 -ResY 1080'
	fg
	touch $@

.PHONY: cleanvm
cleanvm:
	rm -f vm-stage1 win10.qcow2


# This will install cmake, git, MSVC, vcpkg, python and all the other stuff.
# Since this is project specific, we should have this in a script.
.ONESHELL: vm-stage2
vm-stage2: vm-stage1 | win10.qcow2 $(pubkey) $t qemu-system-x86_64
	set -m
	echo "[localhost]:$(port) $$(cut -d' ' -f1,2 $(pubkey))" > $t/known_host
	qemu-system-x86_64 \
	-drive file=win10.qcow2,if=virtio \
	-machine type=q35,accel=kvm \
	-m 8G -smp cores=2,threads=1 \
	-net nic -net user,hostfwd=tcp::$(port)-:22 \
	-vga std -display sdl &
	fg
	touch $@


run-headless: vm-stage1 | win10.qcow2 $(pubkey) $t qemu-system-x86_64
	qemu-system-x86_64 \
	-drive file=win10.qcow2,if=virtio \
	-machine type=q35,accel=kvm \
	-m 8G -smp cores=2,threads=1 \
	-vga std -display none -net nic -net user,\
	hostfwd=tcp::$(port)-:22,\
	hostfwd=tcp::$(rdpport)-:3389,\
	hostfwd=udp::$(rdpport)-:3389


.PHONY: run
run: vm-stage2
	rm -f $^


.INTERMEDIATE: $d/win10.zip $d/win10.ova $d/win10.vmdk $d/virtio.iso $t/helper.qcow2 $t/vm_default_host_key.pub $t/known_host

.PRECIOUS: $d/win10.zip $d/win10.ova $d/win10.vmdk $d/virtio.iso
