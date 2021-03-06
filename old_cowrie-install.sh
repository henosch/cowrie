#!/usr/bin/bash

########################################
# Customize and fake Pi 4 with cowrie. #
########################################


# error
# output_mysql: got error InterfaceError(2003, "2003: Can't connect to MySQL server on 'localhost:3306' (111 Connection refused)"
# server was not running on localhost

# check root
if [ $EUID -ne 0 ]; then
   echo "$0 is not running as root. Login with sudo -i."
   echo "sudo don't work. You must be root"
  exit 2
fi


# package needed
apt install git libssl-dev libffi-dev libmariadb-dev-compat libmariadb-dev \
 build-essential libpython3-dev python3-minimal authbind virtualenv python-virtualenv -y

# crypt pw
# python3 -c 'import crypt; print(crypt.crypt("password"))'

adduser --disabled-password --gecos "" cowrie

git clone https://github.com/cowrie/cowrie /home/cowrie/cowrie
cd /home/cowrie/cowrie
mkdir -p honeyfs/home/pi/
wget -O honeyfs/home/pi/.bash_logout https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/home/pi/.bash_logout
wget -O honeyfs/home/pi/.bashrc https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/home/pi/.bashrc
wget -O honeyfs/home/pi/.profile https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/home/pi/.profile
wget -O honeyfs/home/pi/data.iso https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/home/pi/data.iso          
wget -O honeyfs/home/pi/mypw.zip https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/home/pi/mypw.zip         
wget -O honeyfs/etc/group https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/group
wget -O honeyfs/etc/hostname https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/hostname
wget -O honeyfs/etc/issue https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/issue
wget -O honeyfs/etc/passwd https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/passwd
wget -O honeyfs/etc/resolv.conf https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/resolv.conf
wget -O honeyfs/etc/shadow https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/etc/shadow
wget -O honeyfs/proc/cpuinfo https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/cpuinfo
wget -O honeyfs/proc/meminfo https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/meminfo
wget -O honeyfs/proc/modules https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/modules
wget -O honeyfs/proc/mounts https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/mounts
wget -O honeyfs/proc/version https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/version
wget -O honeyfs/proc/net/arp https://raw.githubusercontent.com/henosch/cowrie/main/honeyfs/proc/net/arp
wget -O share/cowrie/fs.pickle https://github.com/henosch/cowrie/raw/main/share/cowrie/fs.pickle
wget -O share/cowrie/txtcmds/bin/dmesg https://raw.githubusercontent.com/henosch/cowrie/main/share/cowrie/txtcmds/bin/dmesg
wget -O share/cowrie/txtcmds/bin/mount https://raw.githubusercontent.com/henosch/cowrie/main/share/cowrie/txtcmds/bin/mount
wget -O share/cowrie/txtcmds/usr/bin/lscpu https://raw.githubusercontent.com/henosch/cowrie/main/share/cowrie/txtcmds/usr/bin/lscpu
wget -O share/cowrie/txtcmds/usr/bin/nproc https://raw.githubusercontent.com/henosch/cowrie/main/share/cowrie/txtcmds/usr/bin/nproc
wget -O etc/cowrie.cfg https://raw.githubusercontent.com/henosch/cowrie/main/etc/cowrie.cfg
wget -O etc/userdb.txt https://raw.githubusercontent.com/henosch/cowrie/main/etc/userdb.txt

chown cowrie:cowrie -R /home/cowrie/cowrie

# rename default user
# python3 bin/fsctl share/cowrie/fs.pickle
# fs.pickle:/$ mv /home/phil /home/pi

# set mysql root password
echo . 
echo . 
echo -e "Please enter your root mysql password"
read root_pw

# Please do not change the data, as they are in cowrie.cfg.
# Access is only available locally. No security holes
#
# mysql settings

sql_user=cowrie
sql_user_pw=gjzhr5bDbrbtjr@gkrTtbekl
database=cowrie

mysql -u root -p$root_pw -e "CREATE DATABASE $database;"
mysql -u root -p$root_pw -e "CREATE USER '$sql_user'@'localhost' IDENTIFIED BY '$sql_user_pw'";
mysql -u root -p$root_pw $database < /home/cowrie/cowrie/docs/sql/mysql.sql
mysql -u root -p$root_pw -e "GRANT ALL PRIVILEGES ON $database.* TO '$sql_user'@'localhost' IDENTIFIED BY '$sql_user_pw';FLUSH PRIVILEGES;"
mysql -u root -p$root_pw -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$root_pw';FLUSH PRIVILEGES;"
mysql -u root -p$root_pw -e "ALTER DATABASE $database CHARACTER SET utf8 COLLATE utf8_general_ci;"

CHARACTER_SET="utf8" # your default character set
COLLATE="utf8_general_ci" # your default collation

tables=`mysql -u root -p$root_pw -e "SELECT tbl.TABLE_NAME FROM information_schema.TABLES tbl WHERE tbl.TABLE_SCHEMA = '$database' AND tbl.TABLE_TYPE='BASE TABLE'"`

for tableName in $tables; do
    if [[ "$tableName" != "TABLE_NAME" ]] ; then
        mysql -u root -p$root_pw -e "ALTER TABLE $database.$tableName DEFAULT CHARACTER SET $CHARACTER_SET COLLATE $COLLATE;"
        echo "$tableName - done"
    fi
done

su - cowrie
exit

##################################
# This is where the script ends. #
# Please manually from here.     #
##################################

cd cowrie
virtualenv --python=python3 cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements.txt
pip install mysql-connector-python
bin/cowrie start
