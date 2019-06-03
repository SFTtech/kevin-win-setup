# VirtIO driuver image download URL
driver_url=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso


# Microsoft VM settings
vm_url=https://az792536.vo.msecnd.net/vms/VMBuild_20171019/VirtualBox/MSEdge/MSEdge.Win10.VirtualBox.zip
initial_pw=Passw0rd!  # default password of the VM
port=22022  # host binding port for SSH to VM


# Configuration to be applied to the VM
hostname=win10
username=chantal
password=Passw0rd!  # you probably want to override this...


# Shorthands
d=downloaded
t=temporary
privkey=ssh_host_ed25519_key
pubkey=$(privkey).pub


# Test for dependencies. Not sure if this is the right way to handle them.
# TODO: 7z, wget qemu
sshpass:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
	touch $@


# SSH hostkey generation. If not explicitly listed as target or aleady existent,
# the private key will be deleted automatically after ist is deployed to the VM.
$(privkey) $(pubkey):
	ssh-keygen -f $(privkey) -t ed25519 -N ''


# Download and unpacking section
$d:
	mkdir $@

.PHONY: $d/virtio.iso
$d/virtio.iso:
	# Google for RedHat Windows virtio drivers
	wget -c -O $@ $(driver_url)

$d/win10.zip: | $d
	# New URLS to be found at modern.ie
	wget -c -O $@ $(vm_url)

$d/win10.ova: $d/win10.zip
	unzip -p $^ > $@

$d/win10.vmdk: $d/win10.ova
	tar xOf $^ "MSEdge - Win10-disk001.vmdk" > $@


# converted image
win10.qcow2: $d/win10.vmdk
	qemu-img convert -O qcow2 $^ $@


# helper files. cheap to create, will be automatically deleted when no longer needed
$t:
	mkdir $@

$t/helper.qcow2: | $t
	qemu-img create -f qcow2 $@ 1G

$t/ssh_host_ecdsa_key.pub: $d/win10.vmdk | $t
	7z e -so $^ 'Program Files/OpenSSH/etc/ssh_host_ecdsa_key.pub' > $@


# Initial preparations in the VM. Includes changing hostname, username, password, disabling updates and installing viostor drivers
.ONESHELL: stage1-complete
stage1-complete: | $d/virtio.iso sshpass $t/ssh_host_ecdsa_key.pub $(pubkey) $(privkey) win10.qcow2 $t/helper.qcow2
	set -m
	echo "[localhost]:$(port) $$(cut -d' ' -f1,2 $t/ssh_host_ecdsa_key.pub)" > $t/known_host
	qemu-system-x86_64 \
	-drive file=win10.qcow2,if=ide \
	-drive file=$t/helper.qcow2,if=virtio \
	-drive file=$d/virtio.iso,media=cdrom \
	-machine type=q35,accel=kvm \
	-m 8G -smp cores=2,threads=1 \
	-net nic -net user -redir tcp:$(port)::22 \
	-vga std -display sdl &
	while ! nc -z localhost $(port); do sleep 1; done
	while ! sshpass -p 'Passw0rd!' ssh -p $(port) -o UserKnownHostsFile=$t/known_host -o ConnectTimeout=1 IEUser@localhost 'echo "Machine is up"' 2> /dev/null; do sleep 1; done
	sshpass -p '$(initial_pw)' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'mkdir -p /cygdrive/c/stage1'
	sshpass -p '$(initial_pw)' scp -P $(port) -o UserKnownHostsFile=$t/known_host stage1.ps1 $(pubkey) $(privkey) IEUser@localhost:/cygdrive/c/stage1
	sshpass -p '$(initial_pw)' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'powershell C:\\stage1\\stage1.ps1 -Hostname $(hostname) -Username $(username) -Password $(password)'
	fg
	touch $@


# This will install cmake, git, MSVC, vcpkg, python and all the other stuff.
# Since this is project specific, we should have this in a script.
# We don't touch stage2-complete to just use this as a run target right now.
.ONESHELL: stage2-complete
stage2-complete: stage1-complete | win10.qcow2 $(pubkey) $t
	set -m
	echo "[localhost]:$(port) $$(cut -d' ' -f1,2 $(pubkey))" > $t/known_host
	qemu-system-x86_64 \
	-drive file=win10.qcow2,if=virtio \
	-machine type=q35,accel=kvm \
	-m 8G -smp cores=2,threads=1 \
	-net nic -net user -redir tcp:$(Port)::22 \
	-vga std -display sdl &
	fg



.INTERMEDIATE: $d/win10.zip $d/win10.ova $d/win10.vmdk $d/virtio.iso $t/helper.qcow2 $(privkey) $t/ssh_host_ecdsa_key.pub

.PRECIOUS: $d/win10.vmdk $d/virtio.iso
