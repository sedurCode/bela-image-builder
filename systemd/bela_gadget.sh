#!/bin/bash -e
 
modprobe libcomposite
 
cd /sys/kernel/config/usb_gadget/
mkdir g && cd g
 
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB 2.0
 
mkdir -p strings/0x409
echo "__bela__" > strings/0x409/serialnumber
echo "Augmented Instruments Ltd" > strings/0x409/manufacturer
echo "Bela" > strings/0x409/product
 
mkdir -p functions/rndis.usb0  # network
 
mkdir -p configs/c.1
echo 500 > configs/c.1/MaxPower
ln -s functions/rndis.usb0 configs/c.1/
 
udevadm settle -t 5 || :
ls /sys/class/udc/ > UDC

ifup usb0
echo "" > /var/lib/dhcp/dhcpd.leases