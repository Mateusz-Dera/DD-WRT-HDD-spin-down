#!/bin/sh

# DD-WRT HDD Spin Down
# Copyright © 2019 Mateusz Dera

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

echo -e "\e[92;1;48;5;239m =================== \e[0m"
echo -e "\e[92;1;48;5;240m |  HDD SPIN DOWN  | \e[0m"
echo -e "\e[92;1;48;5;241m |  \e[94;1;48;5;241mMateusz Dera  \e[92;1;48;5;241m | \e[0m"
echo -e "\e[92;1;48;5;240m | \e[94;1;48;5;240m Version:\e[92;1;48;5;240m 1.3   | \e[0m"
echo -e "\e[92;1;48;5;239m =================== \e[0m"

if ! [ -d "/jffs/.tmp" ]; then
   mkdir /jffs/.tmp || exit 1
fi
cd /jffs/.tmp || exit 1
curl -kLO https://raw.githubusercontent.com/Mateusz-Dera/DD-WRT-Easy-Optware-ng-Installer/master/install.sh || exit 1
sh ./install.sh -s 
/opt/bin/ipkg update || exit 1
rm -R /jffs/.tmp || exit 1

cd /jffs/opt || exit 1
/opt/bin/ipkg install sdparm || exit 1

cd /jffs/etc/config/ || exit 1

spin_time=18000
device="/dev/sdb"

read -p $'Spin-down time (Default 18000): ' read_time
[ -z "$read_time" ] && echo "18000" || spin_time=$read_time

read -p $'Device (Default /dev/sdb): ' read_device
[ -z "$read_device" ] && echo "/dev/sdb" || device=$read_device

[ -f ./hdd_spin_down.startup ] && rm ./hdd_spin_down.startup

echo -e '#!/bin/sh' > hdd_spin_down.startup || exit 1
echo -e '/usr/bin/logger -t START_$(basename $0) "started [$@]"' >> hdd_spin_down.startup || exit 1
echo -e 'SCRLOG=/tmp/$(basename $0).log' >> hdd_spin_down.startup || exit 1
echo -e 'touch $SCRLOG' >> hdd_spin_down.startup || exit 1
echo -e 'TIME=$(date +"%Y-%m-%d %H:%M:%S")' >> hdd_spin_down.startup || exit 1
echo -e 'echo $TIME "$(basename $0) script started [$@]" >> $SCRLOG' >> hdd_spin_down.startup || exit 1
echo -e "sdparm --flexible -6 -l --set SCT=$spin_time $device" >> hdd_spin_down.startup || exit 1
echo -e "sdparm --flexible -6 -l --set STANDBY=1 $device" >> hdd_spin_down.startup || exit 1
echo -e 'TIME=$(date +"%Y-%m-%d %H:%M:%S")' >> hdd_spin_down.startup || exit 1
echo -e 'if [ "$?" -ne 0 ]' >> hdd_spin_down.startup || exit 1
echo -e 'then' >> hdd_spin_down.startup || exit 1
echo -e 'echo $TIME "Error in script execution! Script: $0" >> $SCRLOG' >> hdd_spin_down.startup || exit 1
echo -e 'else' >> hdd_spin_down.startup || exit 1
echo -e 'echo $TIME "Script execution OK. Script: $0" >> $SCRLOG' >> hdd_spin_down.startup || exit 1
echo -e 'fi' >> hdd_spin_down.startup || exit 1
echo -e '/usr/bin/logger -t STOP_$(basename $0) "return code $?"' >> hdd_spin_down.startup || exit 1
echo -e 'exit $?' >> hdd_spin_down.startup || exit 1
echo -e "Installation complete!\nRestart router"

chmod 700 hdd_spin_down.startup || exit 1
