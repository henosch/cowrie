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
git clone https://github.com/henosch/cowrie /home/cowrie/custom_cowrie

cp -r /home/cowrie/custom_cowrie/* /home/cowrie/cowrie/
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

mysql -u root -p$root_pw -e "DROP USER IF EXISTS '$sql_user'@'localhost'";
mysql -u root -p$root_pw -e "DROP DATABASE IF EXISTS $database";

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
pip install mysql-connector-python==8.0.16
bin/cowrie start
