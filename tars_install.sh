#!/bin/bash

TZ="Asia/Shanghai"

DBIP="127.0.0.1"
DBPort=3306
DBUser=root
DBPassword="P@ssw0rd"

DBTarsPass="T@rs2015"

INET_NAME=eth0

MachineIp=$(ip addr | grep inet | grep ${INET_NAME} | awk '{print $2;}' | sed 's|/.*$||')
MachineName=$(cat /etc/hosts | grep ${MachineIp} | awk '{print $2}')

build_cpp_framework(){
	yum -y install https://repo.mysql.com/mysql-community-release-el7-7.noarch.rpm
	yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	yum -y install yum-utils
	yum install -y git gcc gcc-c++ make wget cmake mysql-server mysql-devel unzip iproute which glibc-devel flex bison ncurses-devel zlib-devel kde-l10n-Chinese glibc-common expect
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
	localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
	wget -c -t 0 https://github.com/Tencent/Tars/archive/master.zip -O master.zip
	unzip -a master.zip && mv Tars-master Tars && rm -f /root/master.zip
	mkdir -p /usr/local/mysql && ln -s /usr/lib64/mysql /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include && echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf && ldconfig
	#cd /usr/local/mysql/lib/ && ln -s libmysqlclient.so.2? libmysqlclient.a
	cd /root/Tars/cpp/thirdparty && wget -c -t 0 https://github.com/Tencent/rapidjson/archive/master.zip -O master.zip
	unzip -a master.zip && mv rapidjson-master rapidjson && rm -f master.zip
	mkdir -p /data && chmod u+x /root/Tars/cpp/build/build.sh
	cd /root/Tars/cpp/build/ && ./build.sh all
	./build.sh install
	cd /root/Tars/cpp/build/ && make framework-tar
	make tarsstat-tar && make tarsnotify-tar && make tarsproperty-tar && make tarslog-tar && make tarsquerystat-tar && make tarsqueryproperty-tar
	mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/ && cp /root/Tars/cpp/build/t*.tgz /root/
	cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz
	mkdir -p /usr/local/app/patchs/tars.upload
	mkdir -p /root/init && cd /root/init/
	wget -c -t 0 --header "Cookie: oraclelicense=accept" -c --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jdk-8u172-linux-x64.rpm
	rpm -ivh /root/init/jdk-8u172-linux-x64.rpm && rm -rf /root/init/jdk-8u172-linux-x64.rpm
	echo "export JAVA_HOME=/usr/java/jdk1.8.0_172-amd64" >> /etc/profile
	echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile
	echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
	echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile
	cd /usr/local/ && wget -c -t 0 https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
	tar zxvf apache-maven-3.5.3-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.3/" >> /etc/profile
	sed -i '/<mirrors>/a\\t<mirror>\n\t\t<id>nexus-aliyun<\/id>\n\t\t<mirrorOf>*<\/mirrorOf>\n\t\t<name>Nexus aliyun<\/name>\n\t\t<url>http:\/\/maven.aliyun.com\/nexus\/content\/groups\/public<\/url>\n\t<\/mirror>' /usr/local/apache-maven-3.5.3/conf/settings.xml
	echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && source /etc/profile && mvn -v
	rm -rf apache-maven-3.5.3-bin.tar.gz 
	cd /usr/local/ && wget -c -t 0 https://dn-pd.qbox.me/resin-4.0.56.tar.gz && tar zxvf resin-4.0.56.tar.gz && mv resin-4.0.56 resin && rm -rf resin-4.0.56.tar.gz
	source /etc/profile && cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml
	cd /root/Tars/web/ && source /etc/profile && mvn clean package
	cp /root/Tars/build/conf/resin.xml /usr/local/resin/conf/
	sed -i 's/servlet-class="com.caucho.servlets.FileServlet"\/>/servlet-class="com.caucho.servlets.FileServlet">\n\t<init>\n\t\t<character-encoding>utf-8<\/character-encoding>\n\t<\/init>\n<\/servlet>/g' /usr/local/resin/conf/app-default.xml
	sed -i 's/<page-cache-max>1024<\/page-cache-max>/<page-cache-max>1024<\/page-cache-max>\n\t\t<character-encoding>utf-8<\/character-encoding>/g' /usr/local/resin/conf/app-default.xml
	cp /root/Tars/web/target/tars.war /usr/local/resin/webapps/
	cd /root/Tars/cpp/build/ && ./build.sh cleanall
	yum clean all && rm -rf /var/cache/yum
}


setup_database(){

	systemctl enable mysqld
	systemctl start mysqld

/usr/bin/expect << EOF
set timeout 30
spawn mysql_secure_installation
expect {
    "enter for none" { send "\r"; exp_continue}
    "Y/n" { send "Y\r" ; exp_continue}
    "password:" { send "$DBPassword\r"; exp_continue}
    "new password:" { send "$DBPassword\r"; exp_continue}
    "Y/n" { send "Y\r" ; exp_continue}
    eof { exit }
}
EOF

	echo "build cpp framework ...."
	##Tars数据库环境初始化
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'%' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'localhost' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineName}' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MachineIp}' identified by '${DBTarsPass}' with grant option;"
	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "flush privileges;"

	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl /root/Tars/cpp/framework/sql/*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl /root/Tars/cpp/framework/sql/*`

	cd /root/Tars/cpp/framework/sql/
	sed -i "s/proot@appinside/h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} /g" `grep proot@appinside -rl ./exec-sql.sh`
	
	chmod u+x /root/Tars/cpp/framework/sql/exec-sql.sh
	
	CHECK=$(mysqlshow --user=${DBUser} --password=${DBPassword} --host=${DBIP} --port=${DBPort} db_tars | grep -v Wildcard | grep -o db_tars)
	if [ "$CHECK" = "db_tars" ];
	then
		echo "DB db_tars already exists" > /root/DB_Exists.lock
	else
		cd /root/Tars/cpp/framework/sql && ./exec-sql.sh
	fi
}

install_base_services(){
	echo "base services ...."
	
	##框架基础服务包
	cd /root/
	mv t*.tgz /data

	echo "Get config files ...."

	mkdir confs
	cd confs
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarsnotify.config.conf
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarsstat.config.conf
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarsproperty.config.conf
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarslog.config.conf
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarsquerystat.config.conf
	wget -c -t 0 https://raw.githubusercontent.com/tangramor/docker-tars/master/confs/tars.tarsqueryproperty.config.conf

	cd /root/

	echo "Install tarsnotify,tarsstat,tarsproperty,tarslog,tarsquerystat,tarsqueryproperty ...."

	# 安装 tarsnotify、tarsstat、tarsproperty、tarslog、tarsquerystat、tarsqueryproperty
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsnotify && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsnotify/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsstat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsstat/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsproperty/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarslog && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarslog/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsquerystat && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/data
	rm -rf /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf && mkdir -p /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/data

	cd /data/ && tar zxf tarsnotify.tgz && mv /data/tarsnotify/tarsnotify /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/ && rm -rf /data/tarsnotify
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tarsnotify --config=/usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf/tars.tarsnotify.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsnotify/bin/tars_start.sh
	cp /root/confs/tars.tarsnotify.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsnotify/conf/

	cd /data/ && tar zxf tarsstat.tgz && mv /data/tarsstat/tarsstat /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/ && rm -rf /data/tarsstat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tarsstat --config=/usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/tars.tarsstat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsstat/bin/tars_start.sh
	cp /root/confs/tars.tarsstat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsstat/conf/

	cd /data/ && tar zxf tarsproperty.tgz && mv /data/tarsproperty/tarsproperty /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/ && rm -rf /data/tarsproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tarsproperty --config=/usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/tars.tarsproperty.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsproperty/bin/tars_start.sh
	cp /root/confs/tars.tarsproperty.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsproperty/conf/

	cd /data/ && tar zxf tarslog.tgz && mv /data/tarslog/tarslog /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/ && rm -rf /data/tarslog
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tarslog --config=/usr/local/app/tars/tarsnode/data/tars.tarslog/conf/tars.tarslog.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarslog/bin/tars_start.sh
	cp /root/confs/tars.tarslog.config.conf /usr/local/app/tars/tarsnode/data/tars.tarslog/conf/

	cd /data/ && tar zxf tarsquerystat.tgz && mv /data/tarsquerystat/tarsquerystat /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/ && rm -rf /data/tarsquerystat
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tarsquerystat --config=/usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/tars.tarsquerystat.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/bin/tars_start.sh
	cp /root/confs/tars.tarsquerystat.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsquerystat/conf/

	cd /data/ && tar zxf tarsqueryproperty.tgz && mv /data/tarsqueryproperty/tarsqueryproperty /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/ && rm -rf /data/tarsqueryproperty
	echo '#!/bin/sh' > /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/:/usr/local/app/tars/tarsnode/data/lib/' >> /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	echo '/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tarsqueryproperty --config=/usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf/tars.tarsqueryproperty.config.conf  &' >> /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/bin/tars_start.sh
	cp /root/confs/tars.tarsqueryproperty.config.conf /usr/local/app/tars/tarsnode/data/tars.tarsqueryproperty/conf/

	##核心基础服务配置修改

	echo "Modify configurations ...."

	cd /usr/local/app/tars

	sed -i "s/dbhost.*=.*192.168.2.131/dbhost = ${DBIP}/g" `grep dbhost -rl ./*`
	sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./*`
	sed -i "s/dbport.*=.*3306/dbport = ${DBPort}/g" `grep dbport -rl /usr/local/app/tars/*`
	sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`
	# 修改Mysql里tars用户密码
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./*`

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_adapter_conf (id, application, server_name, node_name, adapter_name, registry_timestamp, thread_num, endpoint, max_connections, allow_ip, servant, queuecap, queuetimeout, posttime, lastuser, protocol, handlegroup) VALUES (23, 'tars', 'tarsstat', '${MachineIp}', 'tars.tarsstat.StatObjAdapter', '2018-05-27 12:22:05', 5, 'tcp -h ${MachineIp} -t 60000 -p 10003 -e 0', 200000, '', 'tars.tarsstat.StatObj', 10000, 60000, '2018-05-27 20:22:05', NULL, 'tars', ''),(24, 'tars', 'tarsproperty', '${MachineIp}', 'tars.tarsproperty.PropertyObjAdapter', '2018-05-27 12:22:24', 5, 'tcp -h ${MachineIp} -t 60000 -p 10004 -e 0', 200000, '', 'tars.tarsproperty.PropertyObj', 10000, 60000, '2018-05-27 20:22:24', NULL, 'tars', ''),(25, 'tars', 'tarslog', '${MachineIp}', 'tars.tarslog.LogObjAdapter', '2018-05-27 12:22:43', 5, 'tcp -h ${MachineIp} -t 60000 -p 10005 -e 0', 200000, '', 'tars.tarslog.LogObj', 10000, 60000, '2018-05-27 20:22:43', NULL, 'tars', ''),(26, 'tars', 'tarsquerystat', '${MachineIp}', 'tars.tarsquerystat.NoTarsObjAdapter', '2018-05-27 12:23:08', 5, 'tcp -h ${MachineIp} -t 60000 -p 10006 -e 0', 200000, '', 'tars.tarsquerystat.NoTarsObj', 10000, 60000, '2018-05-27 20:23:08', NULL, 'not_tars', ''),(27, 'tars', 'tarsqueryproperty', '${MachineIp}', 'tars.tarsqueryproperty.NoTarsObjAdapter', '2018-05-27 12:23:22', 5, 'tcp -h ${MachineIp} -t 60000 -p 10007 -e 0', 200000, '', 'tars.tarsqueryproperty.NoTarsObj', 10000, 60000, '2018-05-27 20:23:22', NULL, 'not_tars', '');"

	mysql -h${DBIP} -P${DBPort} -u${DBUser} -p${DBPassword} -e "USE db_tars; INSERT INTO t_server_conf (id, application, server_name, node_group, node_name, registry_timestamp, base_path, exe_path, template_name, bak_flag, setting_state, present_state, process_id, patch_version, patch_time, patch_user, tars_version, posttime, lastuser, server_type, start_script_path, stop_script_path, monitor_script_path, enable_group, enable_set, set_name, set_area, set_group, ip_group_name, profile, config_center_port, async_thread_num, server_important_type, remote_log_reserve_time, remote_log_compress_time, remote_log_type) VALUES (23, 'tars', 'tarsstat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsstat', 0, 'active', 'inactive', 0, '59', '2018-05-29 12:28:37', '', '1.1.0', '2018-05-27 20:22:05', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(24, 'tars', 'tarsproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsproperty', 0, 'active', 'inactive', 0, '60', '2018-05-29 12:29:32', '', '1.1.0', '2018-05-27 20:22:24', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(25, 'tars', 'tarslog', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarslog', 0, 'active', 'inactive', 0, '61', '2018-05-29 12:29:54', '', '1.1.0', '2018-05-27 20:22:43', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(26, 'tars', 'tarsquerystat', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsquerystat', 0, 'active', 'inactive', 0, '62', '2018-05-29 12:30:22', '', '1.1.0', '2018-05-27 20:23:08', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0),(27, 'tars', 'tarsqueryproperty', '', '${MachineIp}', '2018-05-29 23:14:19', '', '', 'tars.tarsqueryproperty', 0, 'active', 'inactive', 0, '63', '2018-05-29 12:30:55', '', '1.1.0', '2018-05-27 20:23:22', NULL, 'tars_cpp', NULL, NULL, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, 0, 3, '0', '65', '2', 0); ALTER TABLE t_server_patchs AUTO_INCREMENT = 64;"


	echo "Init services ...."

	chmod u+x tarspatch/util/init.sh
	./tarspatch/util/init.sh

	chmod u+x tars_install.sh
	source /etc/profile
	./tars_install.sh
}

build_web_mgr(){
	echo "web manager ...."
	
	##web管理系统配置修改后重新打war包
	cd /usr/local/resin/webapps/
	mkdir tars
	cd tars
	jar -xvf ../tars.war
	
	sed -i "s/db.tars.com/${DBIP}/g" `grep db.tars.com -rl ./WEB-INF/classes/app.config.properties`
	sed -i "s/3306/${DBPort}/g" `grep 3306 -rl ./WEB-INF/classes/app.config.properties`
	sed -i "s/registry1.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./WEB-INF/classes/tars.conf`
	sed -i "s/registry2.tars.com/${MachineIp}/g" `grep registry2.tars.com -rl ./WEB-INF/classes/tars.conf`
	#sed -i "s/DEBUG/INFO/g" `grep DEBUG -rl ./WEB-INF/classes/log4j.properties`
	
	# 修改Mysql里tars用户密码
	sed -i "s/tars2015/${DBTarsPass}/g" `grep tars2015 -rl ./WEB-INF/classes/app.config.properties`

	jar -uvf ../tars.war .
	cd ..
	rm -rf tars

	nohup /usr/local/resin/bin/resin.sh console 1>/data/log/resin.log 2>&1 &

	#firewall-cmd --zone=public --add-port=80/tcp --permanent
	#firewall-cmd --zone=public --add-port=8080/tcp --permanent
	systemctl stop firewalld
	systemctl disable firewalld
}


build_cpp_framework

setup_database

install_base_services

build_web_mgr
