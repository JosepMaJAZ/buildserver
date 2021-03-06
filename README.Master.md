Mixxx Build Server README
=========================

* Updated 1/23/2011 by rryan

Machine and Directory Layout
============================

We use VirtualBox for virtualization. The reasons behind this are that in the
short-term we need to virtualize Mac OSX and Windows directly in order to
produce builds for them. VirtualBox has the best OSX virtualization
around as of 1/2011.

All VMs are stored in `/opt/mixxx/vms`
To save time re-downloading, all ISOs for e.g. Ubuntu versions are in `/opt/mixxx/isos`

In order to run a VM as your own user, you must be a member of the `vboxusers`
group. You can add yourself to this group like this:
```
$ sudo adduser <username> vboxusers
```

Creating a Virtual Machine
==========================

To create a virtual machine, here are the basic steps to get started. In this
case we'll create a VM called `build-ubuntu-10.04-amd64`, as per the naming
convention described below.

Let's make some environment variables to make this easier on ourselves:
```
$ export HOSTIP="18.248.3.215" # This is the IP for mixxx.mit.edu
$ export NAME="build-ubuntu-10.04-amd64"
$ export VMROOT="/opt/mixxx/vms/"
$ export VMPATH=$VMROOT$NAME
```

First, create the VM description (.vbox) file:
```
$ VBoxManage createvm --name $NAME --register --basefolder $VMROOT
```

NOTE: this will create a folder with the name in `/opt/mixxx/vms`, 
make sure a VM by the same name does not already exist.

Now, set machine characteristics like memory, networking, etc.
```
$ VBoxManage modifyvm $NAME --memory 2048 --cpus 2 --acpi on --ioapic on --boot1 dvd --nic1 nat
```
In this case, you should pick nat to start for the networking. The reason is
that MIT networking will DHCP the machine into a subnet that requires
registration. If you use NAT, then the machine will have network to start with
since it will NAT through the host. You can change this later if the VM should
have a publicly accessible IP. Later, we'll make the machine SSH port forward to
a port on the host.

Now, create a hard disk for the machine. In this case, we create a 50GB drive in
the VirtualBox VDI format. We use Split2G so that the disk is allocated in 2GB
chunks, so it does not initially take up 50GB. If you expect the machine to
potentially require a lot of disk space, you should pick a large number because
it's a pain to change later.
```
$ VBoxManage createhd --filename $VMPATH/$NAME.vdi --size 50000 --format VDI --variant Split2G
```

The machine by default does not have a storage controller. We have to add
one. Let's add a SATA controller:
```
$ VBoxManage storagectl $NAME --name "SATA-1" --add sata --sataportcount 8 --hostiocache on
```

I was reading that apparently this causes problems for earlier than Vista. You
can just replace `--add sata` with `--add ide` and drop the `--sataportcount`
parameter instead.

Now we attach the VDI we created to this storage controller:
```
$ VBoxManage storageattach $NAME --storagectl "SATA-1" --port 0 --device 0 --type hdd --medium $VMPATH/$NAME.vdi
```

Let's attach the install ISO to a virtual DVD-ROM drive:
```
$ VBoxManage storageattach $NAME --storagectl "SATA-1" --port 1 --device 0 --type dvddrive --medium /opt/mixxx/isos/ubuntu-10.10-server-amd64.iso
```

To start the machine and have it host an RDP session for initially configuring
the box, we need to configure VRDE.
```
$ VBoxManage modifyvm $NAME --vrde on --vrdeport 9000 --vrdeaddress $HOSTIP
```

To enable RDP authentication via PAM, turn on the default authentication library.
You can then login with your username and password for the host machine.
```
$ VBoxManage modifyvm $NAME --vrdeauthtype external
```

Make sure to pick a port that is not used. You can look at currently bound ports
by doing `$ netstat --listening`.

Everything should be all set. Now you can run the machine with a VRDE host like so:
```
$ VBoxHeadless --startvm $NAME
```

However, it'll shut down when that process dies. You can run it inside of
`screen` for when you'd like to administer the machine.

Once you're done installing the OS and it reboots, you can pop out the install ISO with this command:
```
$ VBoxManage storageattach $NAME --storagectl "SATA-1" --port 1 --device 0 --type dvddrive --medium none
```

To view an overview of the settings of your virtual machine:
```
$ VBoxManage showvminfo $NAME
```

After getting your machine setup using RDP, after you powerdown your machine,
`VBoxHeadless` will terminate. 
To start your machine again without RDP enabled, do the following:
```
$ VBoxManage startvm $NAME --type headless
```

This will start the VM in the background as your user. I believe it is nohup, so
you can log out. 

To force power-down your machine:
```
$ VBoxManage controlvm $NAME poweroff
```

There are more useful options. to see them, just type:
```
$ VBoxManage controlvm $NAME
```


Setting Up NAT
==============

In order for you to have SSH access to a VM, you must setup NAT port forwarding
so that a port on the host machine is forwarded to the SSH port of your VM.
```
$ VBoxManage modifyvm $NAME --natpf1 "ssh,tcp,,10000,,22"
```

`ssh` is the name of this rule, and the guest's ssh port will be available on
port `10000` of the host.

To delete this passthrough rule, use this command:
```
$ VBoxManage modifyvm $NAME --natpf1 delete ssh
```

Naming Conventions
================================================================================

To keep the naming setup sane, let's distinguish between two types of VMs:
builders and testers.

For builders, let's name stuff like this (up for debate): `build-$(OS)-$(VERSION)-$(ARCH)`

For example:
```
build-ubuntu-10.04-amd64
build-windows-XP-amd64
build-windows-7-amd64
build-osx-10.6-amd64
```

At this stage, I'm not sure if we'll have multiple build VMs for a given
OS/version/arch setup, but in that case, maybe we can say `builder1`, `builder2`,`builder3`, etc. instead of `build`.

Similarly, for test machines, let's call them `test`.

For example:
```
test-ubuntu-10.04-amd64
```

All test machines should have a checkpoint called `stable`. After a test
environment is run, they should be automatically reset to this state.

Importing a Virtual Machine
===========================

Pretty easy. Copy the VM folder with the `.vbox` and `.vdi` files into
`/opt/mixxx/vms/`. Then run
```
$ VBoxManage registervm /opt/mixxx/vms/$NAME/$NAME.vbox
```

Make sure to change the folder and files to be owned by the mixxx user and group
and setup group read/write permissions like this:
```
$ chown mixxx:mixxx -R /opt/mixxx/vms/$NAME/
$ chmod g+rw -R /opt/mixxx/vms/$NAME/
```
