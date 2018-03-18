port=22022
password="Passw0rd!"
d=downloaded
t=temporary
privkey=ssh_host_ed25519_key
pubkey=$(privkey).pub


$(privkey) $(pubkey):
	ssh-keygen -f $(privkey) -t ed25519 -N ''

sshpass:
	@which $@ > /dev/null || bash -c 'echo "$@ not found, please install it" && false'
	touch $@

$d:
	mkdir $@

$d/virtio.iso:
	# Google for RedHat Windows virtio drivers
	wget -c -O $@ https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/virtio-win-0.1.141.iso

$d/win10.zip: | $d
	# New URLS to be found at modern.ie
	wget -c -O $@ https://az792536.vo.msecnd.net/vms/VMBuild_20171019/VirtualBox/MSEdge/MSEdge.Win10.VirtualBox.zip

$d/win10.ova: $d/win10.zip
	unzip -p $^ > $@

$d/win10.vmdk: $d/win10.ova
	tar xOf $^ "MSEdge - Win10-disk001.vmdk" > $@

win10.qcow2: $d/win10.vmdk
	qemu-img convert -O qcow2 $^ $@

$t:
	mkdir $@

$t/helper.qcow2: | $t
	qemu-img create -f qcow2 $@ 1G

$t/ssh_host_ecdsa_key.pub: $d/win10.vmdk | $t
	7z e -so $^ 'Program Files/OpenSSH/etc/ssh_host_ecdsa_key.pub' > $@

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
	sshpass -p 'Passw0rd!' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'mkdir -p /cygdrive/c/stage1'
	sshpass -p 'Passw0rd!' scp -P $(port) -o UserKnownHostsFile=$t/known_host stage1.ps1 $(pubkey) $(privkey) IEUser@localhost:/cygdrive/c/stage1
	sshpass -p 'Passw0rd!' ssh -p $(port) -o UserKnownHostsFile=$t/known_host IEUser@localhost 'powershell C:\\stage1\\stage1.ps1 -Password $(password)'
	fg
	touch $@

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
