#!/bin/sh

echo ''
echo 'Proteus Kiosk updater'
echo ''

if [ "$(id -u)" != "0" ]; then
	echo "Sorry, you are not root."
	exit 1
fi

cat << EOF

Dimitrios I. Petridis, M.Sc, M.Ed
ICT/SW Engineer, Instructor
www.linkedin.com/in/dimipetridis

WARNING: if you don't understand english DON'T use this program

ΕΙΔΟΠΟΙΗΣΙΣ: Αν δεν καταλαβαινετε αγγλικα ΜΗΝ χρησιμοποιετε
αυτο το προγραμμα. Εχετε προειδοποιηθεί.


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

EOF




RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

google_properties_link="https://drive.google.com/open?id=1dFfAw9tm95ok0JTskyvt6Lsl8y1NHMDT"
google_properties_ID=$(echo ${google_properties_link} | cut -d'=' -f2)

properties_filename="updateKioskCloud.properties"
properties_URL="https://docs.google.com/uc?export=download&id=${google_properties_ID}"

isoCD_filename=""
isoCD_MD5=""
isoCD_URL=""
hybrid_filename=""
tmp_folder=""
boot_folder=""
target_partition=""

get_variable() { 
	< "/tmp/$properties_filename" grep -w "$1" | cut -f2
}

hash isohybrid 2>/dev/null || { echo >&2 "${RED}#isohybrid not installed. Aborting.${NC}"; exit 1; }

echo ""
echo "${RED}# Trying to download ${properties_filename} ...${NC}"
wget --no-check-certificate ${properties_URL} -O "/tmp/$properties_filename"

echo "${RED}# Reading properties files ...${NC}"
isoCD_filename=$(get_variable "isoCD_filename")
echo "${GREEN}# Filename of ISO     : ${isoCD_filename} ${NC}"
isoCD_MD5=$(get_variable "isoCD_MD5")
echo "${GREEN}# MD5 of ISO          : ${isoCD_MD5} ${NC}"
isoCD_URL=$(get_variable "isoCD_URL")
echo "${GREEN}# URL of ISO          : ${isoCD_URL} ${NC}"
hybrid_filename=$(get_variable "hybrid_filename")
echo "${GREEN}# Filename for hybrid : ${hybrid_filename} ${NC}"
tmp_folder=$(get_variable "tmp_folder")
echo "${GREEN}# tmp_folder          : ${tmp_folder} ${NC}"
boot_folder=$(get_variable "boot_folder")
echo "${GREEN}# boot_folder         : ${boot_folder} ${NC}"
target_partition=$(get_variable "target_partition")
echo "${GREEN}# target_partition    : ${target_partition} ${NC}"

if [ ! -d "${tmp_folder}" ]; then
	mkdir ${tmp_folder}
fi

rm -rf "${tmp_folder}/*"

echo ""
echo "${RED}# Trying to download ${isoCD_filename} (from ${isoCD_URL}) ...${NC}"
./gdown/gdown.pl "${isoCD_URL}" "${tmp_folder}/${isoCD_filename}"

cd ${tmp_folder}

echo ""
echo "${RED}# Checking ISO MD5 downloaded correctly ...${NC}"

echo "${GREEN}# from md5sum     : $(md5sum ${isoCD_filename} | cut -d' ' -f1) ${NC}"
echo "${GREEN}# from properties : $isoCD_MD5 ${NC}"

if [ "$(md5sum ${isoCD_filename} | cut -d' ' -f1)" = "${isoCD_MD5}" ]; then
	echo "${RED}# The MD5 sum matched. Files tranferred correctly.${NC}"
	
	echo ""
	echo "${RED}# Converting ISO to hybrid ...${NC}"
	cp -p "${isoCD_filename}" "${hybrid_filename}"
	isohybrid "${hybrid_filename}"
	
	echo ""
	echo "${RED}# Copying hybrid to ${boot_folder} ...${NC}"
	if [ ! -d "${boot_folder}" ]; then
		mkdir "${boot_folder}"
	fi
	cp --verbose -rf "${hybrid_filename}" "$boot_folder/"

	echo ""
	echo "${RED}# Running dd to copy hybrid to ${target_partition} ..."
	dd if="${hybrid_filename}" of="${target_partition}"
	
	sed -i -e 's/GRUB_DEFAULT=0/GRUB_DEFAULT=porteus-kiosk-hybrid-iso/g' /etc/default/grub

	echo ""
	echo "${RED}# Updating GRUB2 ...${NC}"
	update-grub2

	echo ""
	echo "${RED}# Rebooting system ...${NC}"
	
	cd -
	reboot
	
else
	echo "${RED}# The MD5 sum didn't match. Exiting.${NC}"
	cd -
	exit 1
fi
