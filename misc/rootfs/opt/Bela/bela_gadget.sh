#!/bin/bash

cd /sys/kernel/config/usb_gadget/
mkdir g && cd g
 
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0101 > bcdDevice # v1.0.1
echo 0x0200 > bcdUSB    # USB 2.0
 
mkdir -p strings/0x409
echo "__bela__" > strings/0x409/serialnumber
echo "Augmented Instruments Ltd" > strings/0x409/manufacturer
echo "Bela" > strings/0x409/product
 
# Two USB-network drivers: one for Windows, one for macOS (Linux will see two distinct interfaces)
mkdir -p functions/rndis.usb0           # network, Windows compatible
mkdir -p functions/ecm.usb0             # network, macOS compatible
mkdir -p functions/mass_storage.0       # boot partition
mkdir -p functions/acm.usb0             # serial
mkdir -p functions/midi.usb0            # MIDI

# make boot partition available as mass storage
echo `cat /opt/Bela/rootfs_dev`p1 > functions/mass_storage.0/lun.0/file

# add OS specific device descriptors to force Windows to load RNDIS drivers
# =============================================================================
# Without this additional descriptors, most Windows system detect the RNDIS interface as "Serial COM port"
# To prevent this, the Microsoft specific OS descriptors are added in here
# !! Important:
#	If the device has already been connected to the Windows System without providing the
#	OS descriptor, Windows will never ask again for them and thus will never
#	install the RNDIS driver.
#	This behavior is due to the creation of a registry hive the first time a device without
#	OS descriptors is attached. The key is built like this:
#
#	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\usbflags\[idVendor+idProduct+bcdDevice\osvc
#
#	To allow Windows to read the OS descriptors again, the according registry hive has to be
#	deleted manually or USB descriptor values have to be changed(e.g.: bcdDevice).
#
#  Thanks to
#  https://github.com/mame82/P4wnP1/blob/9859a69f758ff8bdf0c1ca1bf82f26323c2d44d2/boot/init_usb.sh#L150-L163 

mkdir -p os_desc
echo 1 > os_desc/use
echo 0xbc > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

/opt/Bela/bela_mac.sh || true
cat /etc/cpsw_2_mac > functions/rndis.usb0/host_addr || true
cat /etc/cpsw_1_mac > functions/rndis.usb0/dev_addr || true
cat /etc/cpsw_4_mac > functions/ecm.usb0/host_addr || true
cat /etc/cpsw_5_mac > functions/ecm.usb0/dev_addr || true

mkdir -p functions/rndis.usb0/os_desc/interface.rndis
echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

mkdir -p configs/c.1
echo 500 > configs/c.1/MaxPower
ln -s functions/rndis.usb0 configs/c.1/ # this needs to be loaded first in order to work on Windows
ln -s functions/ecm.usb0 configs/c.1/
ln -s functions/mass_storage.0 configs/c.1/
ln -s functions/acm.usb0   configs/c.1/
ln -s functions/midi.usb0 configs/c.1

udevadm settle -t 5 || :
ls /sys/class/udc/ > UDC

# hack to ensure dhcpd has a free lease
echo "" > /var/lib/dhcp/dhcpd.leases
