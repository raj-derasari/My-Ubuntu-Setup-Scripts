# for debugging
DRY_MODE=0
# important
UPDATEGRUB=1
INSTALLGRUB=1

if [ $DRY_MODE -eq 1 ]; then
	dry_echo="echo "
fi

# to print disk data and sudo prompt
$dry_echo sudo fdisk -l 

# check for which partitions can be mounted.
linux_distros=`sudo fdisk -l | grep Linux | cut -d ' '  -f 1`

# if No distro found, quit. else print a hello message
if [[ -z $linux_distros ]]; then
	echo "Linux distro not found, this script cannot continue!"
	exit 1
else
	echo "=================================================================================="
	echo "Welcome to the GRUB reinstallaton script."
	echo "1 or more Linux distros were found, will attempt to:"
	[ $UPDATEGRUB -eq 1 ] && echo "Update grub with chroot && update-grub"
	[ $INSTALLGRUB -eq 1 ] && echo "Reinstall grub with sudo grub-install --root-directory /mnt "
fi
echo "=================================================================================="
# Check if multiple distro were found.
# if mount -f () exits with 0 status, it'll mount successfully.
# Else, exit code 1 from mount -f implies more than 1 argument was passed
# something like mount /dev/sda2 /dev/sda3 /mnt
# So, the else block must verify which partition to select and then mount it
$dry_echo sudo mount -f ${linux_distros} /mnt
if [ $? -eq 0 ]; then
	## can successfully mount this as the mountpoint
	target_linux=`echo $linux_distros`
	echo "Target to mount: " $target_linux
else
	echo "==================================================================================
	You have more than one linux distribution installed.
	Will go through every distro found
	Select a mount point in the following steps.
	Eventually if you haven't selected one, the first one found will be selected by default."
	for mount in $Z; do
		echo "Would you like to select mount point: " $mount
		read -p "Please enter y/Y for yes n/N for no" choice
		if [ "$choice" != "${choice#[Yy]}" ] ;then
			echo "Selected device: " $mount;
			target_linux=`echo $mount`
		else
			echo "Not selecting " $mount;
		fi
	done
	echo "=================================================================================="
	## If user trolled and entered no every time, select first one by default
	if [[ -z $target_linux ]]; then
		echo "You have not selected any distro in the prompts."
		echo "Selecting the first possible distro by default!"
		target_linux=`echo $linux_distros | cut -d' ' -f 1`
		echo "Target: " $target_linux
	fi
fi
echo "=================================================================================="
## now can successfully mount target_linux
$dry_echo sudo mount ${target_linux} /mnt

## updates grub by doing stuff.
## EFI test - haven't checked, thus disabled.
EFI_PARTITION=`sudo fdisk -l | grep EFI | cut -d ' '  -f 1`
if [[ -z $EFI_PARTITION ]]; then
	echo "NO EFI Partition to be loaded."
else
	echo "=================================================================================="
	echo "EFI Partition found: " EFI_PARTITION
	echo "Mounting EFI partition"
	sudo mount $EFI_PARTITION /mnt/boot/efi

	## not sure what the rest of this stuff does.
	# modprobe efivars
	## TODO CHECK THIS OUT:
	# sudo apt-get install grub-efi-loader
	## TODO CHECK THIS OUT:
	# sudo apt-get install --reinstall grub-efi-amd64
fi

if [ $UPDATEGRUB -eq 1 ]; then
	echo "=================================================================================="
	## to make sure that your internet connection stays alive
	## NOT SURE ABOUT THIS RIGHT NOW
	#sudo cp /etc/resolv.conf /mnt/etc/
	
	for i in /dev /dev/pts /proc /sys; do $dry_echo sudo mount -B $i /mnt$i; done
	
	# probably do it in a subshell
	`$dry_echo sudo chroot /mnt $dry_echo update-grub`

	# unmount this stuff
	for i in /sys /proc /dev/pts /dev; do $dry_echo sudo umount /mnt$i; done

	[ $INSTALLGRUB -eq 0 ] && exit 12
fi

if [ $INSTALLGRUB -eq 1 ]; then
	echo "=================================================================================="
	echo "What target device would you like to install GRUB to?"
	echo "Be sure to enter the prefix and target device alphabet"
	echo "Enter something like 'sda', 'sdb' or 'hda','hdb', - without the quotes"
	echo "You can refer to the list of partitions above!"
	$dry_echo read TARGET_DEVICE
	$dry_echo sudo grub-install --root-directory=/mnt /dev/$TARGET_DEVICE
	if [ $? -eq 0 ]; then
		echo "Seems like grub reinstalled successfully!"
	else
		echo "=================================================================================="
		echo "There was some problem when running grub-install --root-directory=/mnt $TARGET_DEVICE"
		$dry_echo exit 7
	fi
else
	[ $UPDATEGRUB -eq 0 ] && $dry_echo exit 10 || $dry_echo exit 12
	# if either was 0, this will be the ending point of the code.
fi
## if both UPDATEGRUB and INSTALLGRUB are 1 then prompt for reboot
echo "=================================================================================="
choice=y
$dry_echo read -p "Would you like to reboot after 10 seconds? Y/y:continue; N/n:dont reboot: " choice
if [ "$choice" != "${choice#[Yy]}" ]; then
	TIMER=10
	echo "=================================================================================="
	echo -e "Rebooting in $TIMER seconds, to cancel, enter:\nsudo reboot --halt"
	$dry_echo sudo shutdown -r $TIMER
fi
$dry_echo exit 0




######### DOCUMENTATION:
Script exit codes:
0	exit successfully with update-grub and grub-install
10	exit successfully with update-grub
20	exit successfully with grub-install
1	no linux distro was found
2	