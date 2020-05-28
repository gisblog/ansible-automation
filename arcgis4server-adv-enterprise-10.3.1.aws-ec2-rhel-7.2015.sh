###
# see "HowTo: Run ‘ArcGIS for Server Advanced Enterprise’ (10.3.1) on Amazon EC2 Red Hat Enterprise Linux (7)" on gisblog.org
###

### Setup the stage ###
# Downloaded its AWS key from //aws.amazon.com/console/ and connected to my instance (ensured it matched the min. system requirements) using its public DNS (if you restart your instance, this will change). Note I SSHed using Cygwin instead of PuTTy.
$ ssh -i "key.pem" ec2-user@#.#.#.#.compute.amazonaws.com
$ cat /etc/redhat-release
> Red Hat Enterprise Linux Server release 7.1 (Maipo) # Even though I used RHEL-7.0_HVM_GA-20141017-x86_64-1-Hourly2-GP2 by Red Hat (I later found out that ESRI provides its own AMI)
$ sudo yum upgrade
$ sudo yum update
$ sudo yum install emacs # For that college-dorm smell, no offense Nano/Vi
$ sudo emacs ~/.bashrc
    force_color_prompt=yes # If you haven't already... (Ignored the embedded rant and uncommented this line to make the prompt colored so it was easier to read in-between)

### Setup the instance ###
# I used a M4.LARGE instance with a 20GB EBS volume (in the same Availability Zone, of course) - ensured it didn't go away if I were to terminate the instance. Then, I extended the partition to exceed the min. space requirements (took a snapshot first) - unfortunately, AWS docs didn't help much with that.
$ df -h
> ...
$ lsblk # Listed block partitions attached to the device. Since there was a gap in sizes between the partition and the device (and there were no other partitions), I resized the child partition "XVDA2" (the root file system where I would finally install ArcGIS Server) to use up the surplus space on its parent disk "XVDA".
> NAME SIZE TYPE MOUNTPOINT
> xvda 20G disk
> |_xvda2 6G part /
# First, updated its metadata in the partition table
$ sudo yum install gdisk # Since disk label was GPT
$ sudo gdisk /dev/xvda/
$     print # Noted the start sector
$     delete
$     new
$     #### # Used the same start sector so that data is preserved
$     \r # For the max. last sector
$     # # Used the same partition code
$     print
$     write
$     y
# Next, updated the actual XFS file system
$ sudo xfs_growfs / # This is the actual change for XFS. If 'df -T' reveals the older EXT4, use 'resize2fs'.
# Then, confirmed to see if the boot sector was present so that stop-start will work
$ sudo file -s /dev/xvda # Bootloader
# Finally, rebooted the instance to reflect the new size
$ sudo reboot

### Onto GIStuff ###
# WinSCPed and untarred the fresh-off-the-press 1GB release
$ tar -xvf ArcGIS_for_server_linux_1031_145870.gz
# Got the right ECP#########?
$ ./Setup # Started headless installation - try "--verbose" if you run into other issues
# Hit a diagnostics roadblock: File handle limits for the install user were required to be set to 65535 and the number of processes limits to 25059. So...
$ sudo emacs /etc/security/limits.conf
$     ec2-user soft nofile 65535
$     ec2-user hard nofile 65535
$     ec2-user soft nproc 25059
$     ec2-user hard nproc 25059
# Logged out, logged back in, verified
$ ulimit -Hn -Hu
$ ulimit -Sn -Su
$ ./Setup

### Authorize, authorize, authorize! ###
# Created and uploaded authorization.txt, and downloaded authorization.ecp from //my.esri.com/ -> "My Organization" -> "Licensing" -> "Secure Site Operations"
$ locate -i authorization.ecp
$ readlink -f authorization.ecp
$ ./authorizeSoftware -f /path/authorization.ecp
$ ./authorizeSoftware -s # s=status, not silent
$ ./startserver.sh
$ netstat -lnp | grep "6080" # Confirmed owned processes - that it was listening on the default TCP@6080 (port is only required if you don't have the Web Adapter)
# Ensured IP and domain were listed correctly in the hosts file (e.g. Single IP may be mapped to multiple hosts, both IPv4 and IPv6 may be mapped to a single host, etc.)
$ hostname
$ emacs /etc/hosts
$     127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
$     ::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
$     #.#.#.# localhost localhost.localdomain localhost4 localhost4.localdomain4
# But wait, before I could browse to my site from a public browser, I needed to add this Inbound Rule to the Security Group attached to the instance
Custom TCP rule TCP 6080 0.0.0.0/0

### Browser ahoy! ###
//#.#.#.# or machinename:6080/arcgis/manager
ArcGIS Server Setup Wizard -> Create New Site
Primary Site Administrator -> Create Account # Stored with the site, not the OS
# Must be local and accessible from every machine in your site
    Root Server Directory: /home/username/arcgis/server/usr/directories # To store output images, etc.
    Configuration Store: /home/username/arcgis/server/usr/config-store # To hold info about the server's machines, services, directories, etc.
# This is when I ran into "0x80040154 - Could not create object 'ConfigurationFactory'". So, went digging through the logs...
$ cat /home/ec2-user/arcgis/server/usr/logs/EC2/server/server-...log
> ...
> Cluster 'default' successfully created.
> Failed to create the site. com.esri.arcgis.discovery.servicelib.AGSException: java.lang.Exception: AutomationException: 0x80040154 - Could not create object 'ConfigurationFactory'.
> Disconnecting the site from the configuration store.
...
# Back to the server: File/directory permission issue? Nope. The issue turned out to be missing packages, even though the pre-installation dependencies check had passed. All 15 listed below:
$ sudo yum list installed
$ sudo yum install wget
$ wget http://vault.centos.org/6.2/os/x86_64/Packages/xorg-x11-server-Xvfb-1.10.4-6.el6.x86_64.rpm
$ sudo yum localinstall xorg-x11-server-Xvfb-1.10.4-6.el6.x86_64.rpm
sudo yum install Xvfb # Else "Unable to start Xvfb on any port in the range 6600-6619"
sudo yum install freetype
sudo yum install fontconfig
sudo yum install mesa-libGL
sudo yum install mesa-libGLU
sudo yum install redhat-lsb
sudo yum install glibc
sudo yum install libXtst
sudo yum install libXext
sudo yum install libX11
sudo yum install libXi
sudo yum install libXdmcp
sudo yum install libXrender
sudo yum install libXau
# Cleanliness is next to godliness, or so my Catholic school nuns would say
$ sudo yum clean all
$ cd /tmp/
$ sudo rm -r *
$ logout

### Back to the browser ###
//#.#.#.#:6080/arcgis/manager/
# At the end, added SSL using a self-signed certificate
//#.#.#.#:6080/arcgis/admin/
Custom TCP rule TCP 6443 0.0.0.0/0 # Added this rule to the group on AWS first

### Uninstall? ###
$ ./stopserver.sh
$ ./uninstall_ArcGISServer
# rm folders after done