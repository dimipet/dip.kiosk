# dip.kiosk

## Introduction
dip.kiosk is a guide and script(s), that demonstrate a way to build a **dual boot kiosk system** with Lubuntu 18 x64 and Porteus Kiosk 4.8.0 x64 which can be administered and updated through cloud storage (Google Drive). **Triple boot** (or more) can be supported with light modifications, as long as: the second OS is Lubuntu and third is Porteus Kiosk (e.g. first OS: Microsoft Windows). 

In this guide we use [Google Drive](https://www.google.com/drive/) as our storage source.
[Lubuntu](https://lubuntu.net/) is a full featured lightweight linux distro running on low end hardware. [Porteus Kiosk](https://porteus-kiosk.org/) is a fantastic solution for kiosks running on low end hardware too and its web site provides all the details to build a kiosk. Both distros have a great community and as such they make an ideal choice to build a **hard disk driven, dual boot kiosk** system. 

However information on how to build and administer a **dual boot** system running Porteus Kiosk from hard disk is spread in various areas. Furthermore information on how to update you kiosk installation remotely is difficult to find. 

Below we show draftly how to build a Lubuntu 18 x64 and prepare it for Porteus Kiosk 4.8.0 x64. Up next we demonstrate how to deploy Porteus Kiosk on a hard disk partition using a script and a Google Drive shared folder. Lastly we show how a typical remote update procedure should be issued.

## Limitations, Security and damage precautions
* Default booting is Porteus
* Learn how to lock your `GRUB2` with a password and letting only Porteus Kiosk boot
* Although full automation of remote update can be possible (needs some research) it imposes security risks (you need to make Porteus `GRUB2` aware by customizing your kiosk ISO, install `grub-set-default` and `grub-reboot` on both systems or/and you may have timetables to switch `GRUB2` configurations files and automate the script to run as service on Lubuntu etc)  
* Having Porteus kiosk run, as intended, **securely from RAM, you need someone to boot to Lubuntu before you `ssh` to it and perform an update**
* In my use case scenario kiosks were at the same place I work, I only needed not to unscrew the kiosk, install CD/USB etc. to perform an update, thus I didn't bother designing a secure solution to *fully automate remote updating* (if I find myself some free time that I don't want to spend with my beloved ones, I will research it and propose another guide)
* Setting wrong values in properties file can damage your kiosk system irreversibly. You need to do 3 things: backup, backup and backup you system before proceeding.
* I am not responsible for what happens 
* READ all of my texts and script source, disclaimers etc
* Read the previous 3 lines 3 times aloud then continue reading this guide 
* OK you have been warned

## Prerequisites
* PC with [Lubuntu minimum requirements](https://docs.lubuntu.net/)
* Google Drive account
* Lubuntu 18 installation CD/USB [link](https://lubuntu.net/downloads/ "Get Lubuntu")
* Porteus Kiosk 4.8 installation ISO/USB [link](https://porteus-kiosk.org/download.html "Get Porteus")
* familiar with `GRUB2`, `ssh`, `openssh-server`, `ufw`

## 1. Lubuntu 18 x64: typical installation
* Boot Lubuntu 18 x64 installation CD
* Install in one primary partition: `/dev/sda1`
* Leave space 500MB for a second primary partition
* Create second partition `/dev/sda2` as FAT32 and format it 
* Make sure `GRUB2` gets installed in `/dev/sda`
* Finish Lubuntu installation
* Make sure you can boot Lubuntu from hard disk using `GRUB2`

## 2. Lubuntu 18 x64: dual boot preperation
* Boot to Lubuntu
* Install the following

~~~~	
$ sudo apt-get install syslinux, git
$ sudo apt-get install syslinux-utils
~~~~

* Install `openssh-server` and start it

~~~~
$ sudo apt-get install openssh-server
$ sudo service ssh restart
~~~~

* Maybe you need to allow your `ufw` to accept `ssh` incoming requests

~~~~
$ sudo ufw allow ssh
~~~~

* Edit custom `GRUB2` config files, check `--id` you assign. You will need it to set your default boot OS

~~~~
$ sudo nano /etc/grub.d/40_custom
~~~~

* Add the `GRUB2` menuentry below at the end of the file and save

~~~~
menuentry "Porteus-Kiosk-hybrid.iso" --id porteus-kiosk-hybrid-iso {
        set isofile="/boot/isos/Porteus-Kiosk-hybrid.iso"
        loopback loop (hd0,1)$isofile
        linux (loop)/boot/vmlinuz boot=boot iso-scan/filename=$isofile noprompt noeject
        initrd (loop)/boot/initrd.xz
}	
~~~~

* Edit your `GRUB2` defaults 

~~~~
$ sudo nano /etc/default/grub
~~~~

* Set your default boot, use the `--id` value above

~~~~
GRUB_DEFAULT=porteus-kiosk-hybrid-iso
~~~~

* Update your `GRUB2` boot loader

~~~~
$ sudo update-grub2
~~~~

## 3. Porteus Kiosk 4.8.0 x64: ISO image creation
The ISO image creation can vary from case to case (due to different functional requirements), from system to system (due to non-functional requirements). As such it is out of scope of this document to explain how you should build your *own* system. It is implied that *you know exactly how to create a USB or CD with a running Porteus Kiosk*. Play around and create it, Porteus Kioks wizard is self-explanatory  and you will have no problem, if different Google and use Porteus fantastic community.

Please find below listed the main steps to follow along with some links to read/watch etc.

* Boot your Porteus Kiosk 4.8 CD/USB
* Follow wizard, make your choices [(read parameters here)](https://porteus-kiosk.org/parameters.html)
* Make sure you add `ssh` support and enabled firewall *
* Choose to "Save ISO" to USB as `Porteus-Kiosk.iso`
* The above can be tricky, if having trouble to Save ISO [check the videos here](https://porteus-kiosk.org/videos.html)

*In order to access your Porteus Kiosk remotely (e.g. to reboot) you have to make sure that after completing this guide, you can access your running kiosk using `ssh` through the Internet. That probably means having your network's router/gateway with static ip (or dynamic DNS) and port forward some port to kiosk's port 22.*

## 4. Porteus-Kiosk.iso: Google Drive upload
* Reboot to Lubuntu (hold shift during POST so `GRUB2` shows up)
* Upload your `Porteus-Kiosk.iso` to a Google shared folder
* Left click the uploaded ISO file and "Get Sharable link", e.g. `https://drive.google.com/open?id=3Kk2iOUUh485etmsOIa7sTDGoNrjQdY8M` 

## 5. dip.kiosk: script(s) download
Run the following 

~~~~
$ cd ~/Desktop
$ git clone https://github.com/dimipet/dip.kiosk.git
$ chmod u+x ~/Desktop/dip.kiosk/updateKioskCloud.sh
~~~~

## 6. dip.kiosk: `updateKioskCloud.properties` edit and upload

This is a key/value file with a TAB between key and value.
** When editing be careful ** 
There is a one single space between each key (e.g. `tmp_folder`) and its value (e.g. `/tmp/porteus`). 
This single space is a TAB hidden character used as a delimiter between keys and their values.
If in doubt use a descent text editor (notepad++, atom, vim [see here](http://www.chrispian.com/quick-vi-tip-show-hidden-characters/) that can show hidden control characters. Below I use `nano` but take care not to delete anything.

First things first: make a copy of your properties sample file

~~~~
$ cp -p ~/Desktop/dip.kiosk/updateKioskCloud.properties.sample ~/Desktop/dip.kiosk/updateKioskCloud.properties
~~~~

Now edit your file

~~~~
$ nano ~/Desktop/dip.kiosk/updateKioskCloud.properties
~~~~

You should see the following content, edit it to suit your needs, again make sure not to delete TABs

~~~~
isoCD_filename	Porteus-Kiosk.iso
isoCD_MD5	9354d22bac456e1168769ef0d0f251eb
isoCD_URL	https://drive.google.com/open?id=3Kk2iOUUh485etmsOIa7sTDGoNrjQdY8M
hybrid_filename	Porteus-Kiosk-hybrid.iso
tmp_folder	/tmp/porteus
boot_folder	/boot/isos
target_partition	/dev/sda2
~~~~

* Set `isoCD_URL` with the sharable link you copied from Google Drive when you uploaded your `Porteus-Kiosk.iso`
* Find the MD5 of the `Porteus-Kiosk.iso` you created above (step 3). One way to do that is  

~~~~
$ ms5sum Porteus-Kiosk.iso
9354d22bac456e1168769ef0d0f251eb  Porteus-Kiosk.iso
~~~~

* Set `isoCD_MD5` with the MD5 value found above 

* In case you don't install on `/dev/sda2`, set `target_partition` to your desired target partition
* Upload your `updateKioskCloud.properties` to a Google shared folder and make sure you uploaded it correclty, use (connect) an online text editor for that like AnyFile
* Delete your local `updateKioskCloud.properties` file, you wont need it anymore, you should be editing with extra care from now the file online, as the online properties file is the file that the script uses

~~~~
$ rm ~/Desktop/dip.kiosk/updateKioskCloud.properties
~~~~

* Head to your uploaded `updateKioskCloud.properties` file, left click it and "Get Sharable link", a link like the following should be copied to your clipboard e.g. `https://drive.google.com/open?id=1Aa1oKJ6df89phsuOIa7sUGDoRVSqoP9Q`

## 7. dip.kiosk: edit `updateKioskCloud.sh` edit
* Edit the script `updateKioskCloud.sh`, 
	
~~~~
$ nano ~/Desktop/dip.kiosk/updateKioskCloud.sh
~~~~

* Find the line `google_properties_link="https://drive.google.com/open?id=1dFfAw9tm95ok0JTskyvt6Lsl8y1NHMDT"` 
* Delete the whole link between the two double quotes
* Paste the link you copied from Google Drive above 

You should now see something like the following (but with your own copied link)

~~~~
google_properties_link="https://drive.google.com/open?id=1Aa1oKJ6df89phsuOIa7sUGDoRVSqoP9Q"
~~~~

## 8. dip.kiosk: install Porteus Kiosk
* Run

~~~~
$ sudo nano ~/Desktop/dip.kiosk/updateKioskCloud.sh
~~~~

The script will 
* download `updateKioskCloud.properties`, 
* read its values, 
* download and validate the ISO from Google drive 
* `dd` the ISO to your `/dev/sda2` partition
* update your `GRUB2`
* reboot

After reboot you should be able to watch your Porteus Kiosk running !

## 9. Typical Update Scenario
You decide that you need to update your your kiosk. 
* Create your new `Porteus-Kiosk.iso` 
* Test your `Porteus-Kiosk.iso` on VirtualBox, if OK proceed
* Upload it to a Google shared folder (follow step 4)
* Direct edit `updateKioskCloud.properties` in Google Drive with some connected app e.g. Anyfile and follow step 6 on how to fill values for `isoCD_MD5` and `isoCD_URL` 
* Have someone to hold SHIFT keyboard key (after POST before `GRUB2` menu shows up) and select to boot Lubuntu
* `ssh` to Lubuntu and run as step 8 above

~~~~
$ sudo updateKioskCloud.sh
~~~~

## License

Each library is released under its own license. This adjusticeKiosk repository is published under [GNU/GPL Version 3](LICENSE).
