MYSQL_PASS=
MYSQL_IP= 
DB_PASS=
ADMIN_TOKEN=
ADMIN_PASS= 
FIXED_RANGE=
MANAGE_IP=
PUBLIC=${PUBLIC:-eth0}
BRIDGE=${BRIDGE:-br100}
INTERNAL=
GALNCE_IP=
ISCSI_PREFIX=
PUBLIC_IP=

apt-get update
apt-get install

apt-get install -y ntp
echo "server ntp.ubuntu.com iburst" >> /etc/ntp.conf
cat <<EOF >> /etc/ntp.conf
server ntp.ubuntu.com iburst
server 127.127.1.0
fudge 127.127.1.0 stratum 10
EOF
/etc/init.d/ntp restart

apt-get install -y mysql-server python-mysqldb

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

/etc/init.d/mysql restart

mysql -uroot -p$MYSQL_PASS -e 'CREATE DATABASE nova;'
mysql -uroot -p$MYSQL_PASS -e 'CREATE DATABASE glance;'
mysql -uroot -p$MYSQL_PASS -e 'CREATE DATABASE keystone;'
mysql -uroot -p$MYSQL_PASS -e 'CREATE USER novadbadmin;'
mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* to 'novadbadmin'@'%';"
mysql -uroot -p$MYSQL_PASS -e "SET PASSWORD FOR 'novadbadmin'@'%' = PASSWORD('$DB_PASS');"
mysql -uroot -p$MYSQL_PASS -e 'CREATE USER glancedbadmin;'
mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* to 'glancedbadmin'@'%';"
mysql -uroot -p$MYSQL_PASS -e "SET PASSWORD FOR 'glancedbadmin'@'%' = PASSWORD('$DB_PASS');"
mysql -uroot -p$MYSQL_PASS -e 'CREATE USER keystonedbadmin;'
mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* to 'keystonedbadmin'@'%';"
mysql -uroot -p$MYSQL_PASS -e "SET PASSWORD FOR 'keystonedbadmin'@'%' = PASSWORD('$DB_PASS');"


apt-get install rabbitmq-server memcached python-memcache


apt-get install keystone python-keystone python-keystoneclient
cp files/keystone.conf /etc/keystone/keystone.conf
sed -i 's/admin_token = ADMIN/admin_token = '"$ADMIN_TOKEN"'/' /etc/keystone/keystone.conf
sed -i 's#sqlite:////var/lib/keystone/keystone.db#mysql://keystonedbadmin:'"$DB_PASS"'@'"$MYSQL_IP"'/keystone#' /etc/keystone/keystone.conf

service keystone restart
keystone-manage db_sync
./files/keystone_data.sh

apt-get install glance glance-api glance-client glance-common glance-registry python-glance
sed -i 's/%SERVICE_TENANT_NAME%/admin/' /etc/glance/glance-api-paste.ini
sed -i 's/%SERVICE_USER%/admin/' /etc/glance/glance-api-paste.ini
sed -i 's/%SERVICE_PASSWORD%/'"$ADMIN_PASS"'/' /etc/glance/glance-api-paste.ini
sed -i 's/%SERVICE_TENANT_NAME%/admin/' /etc/glance/glance-registry-paste.ini
sed -i 's/%SERVICE_USER%/admin/' /etc/glance/glance-registry-paste.ini
sed -i 's/%SERVICE_PASSWORD%/'"$ADMIN_PASS"'/' /etc/glance/glance-registry-paste.ini
sed -i 's#sqlite:////var/lib/glance/glance.sqlite#mysql://glancedbadmin:'"$DB_PASS"'@'"$MYSQL_IP"'/glance#' /etc/glance/glance-registry.conf

cat <<EOF >> /etc/glance/glance-registry.conf
[paste_deploy] 
flavor = keystone 
EOF

cat <<EOF >> /etc/glance/glance-api.conf
[paste_deploy] 
flavor = keystone 
EOF

service glance-registry restart
service glance-api restart

sudo glance-manage version_control 0 
sudo glance-manage db_sync

apt-get install nova-api nova-cert nova-common nova-compute nova-compute-kvm nova-doc nova-network nova-scheduler novnc nova-volume python-nova python-novaclient
apt-get install nova-cert nova-consoleauth

sed -i 's/%SERVICE_TENANT_NAME%/admin/' /etc/nova/api-paste.ini
sed -i 's/%SERVICE_USER%/admin/' /etc/nova/api-paste.ini
sed -i 's/%SERVICE_PASSWORD%/'"$ADMIN_PASS"'/' /etc/nova/api-paste.ini

cp files/nova.conf /etc/nova/nova.conf
chmod 644 /etc/nova/nova.conf

echo "--fixed_range=$FIXED_RANGE" >> /etc/nova/nova.conf
sed -i 's/%MANAGE_IP%/'"$MANAGE_IP"'/g' /etc/nova/nova.conf
sed -i 's/%PUBLIC%/'"$PUBLIC"'/g' /etc/nova/nova.conf
sed -i 's/%BRIDGE%/'"$BRIDGE"'/g' /etc/nova/nova.conf
sed -i 's/%INTERNAL%/'"$INTERNAL"'/g' /etc/nova/nova.conf
sed -i 's/%MYSQL_IP%/'"$MYSQL_IP"'/g' /etc/nova/nova.conf
sed -i 's/%MYSQL_PASS%/'"$MYSQL_PASS"'/g' /etc/nova/nova.conf
sed -i 's/%PUBLIC_IP%/'"$PUBLIC_IP"'/g' /etc/nova/nova.conf
sed -i 's/%GLANCE_IP%/'"$GLANCE_IP"'/g' /etc/nova/nova.conf
sed -i 's/%ISCSI_PREFIX%/'"$ISCSI_PREFIX"'/g' /etc/nova/nova.conf

chmod 777 /usr/lib/python2.7/dist-packages/

for i in nova-api nova-scheduler nova-compute nova-network nova-volume nova-cert nova-consoleauth novnc
do
  service $i restart
done

nova-manage db sync
nova-manage network create private --fixed_range_v4=$FIXED_RANGE --num_networks=1 --bridge=$BRIDGE --bridge_interface=$INTERNAL --network_size=256

for i in nova-api nova-scheduler nova-compute nova-network nova-volume nova-cert nova-consoleauth novnc
do
  service $i status
done

apt-get install libapache2-mod-wsgi openstack-dashboard
service apache2 restart