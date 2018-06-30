# Tencent Tars 的 一键安装 脚本

* [约定](#约定)
* [MySQL](#mysql)
* [变量](#变量)
  * [TZ](#tz)
  * [DBIP, DBPort, DBUser, DBPassword](#dbip-dbport-dbuser-dbpassword)
  * [DBTarsPass](#dbtarspass)
  * [INET_NAME](#inet_name)
  * [框架普通基础服务](#框架普通基础服务)
* [Docker镜像](#docker镜像)


约定
-----

脚本 `tars_install.sh` 和 `tars_install_php7_mysql8.sh` 在**CentOS7**环境上运行；脚本 `tars_install_debian_php7.sh` 在**Debian**和**Ubuntu**环境上运行。

以 **root** 用户登录，在修改完脚本预设变量后，使用 `chmod u+x` 赋予脚本运行权限，然后运行即可。


MySQL
-----

脚本会自动安装 MySQL 服务器程序并进行简单的设置。


变量
--------

在运行一键安装脚本之前，请**一定**要确定脚本里的变量定义正确。要注意的是 MysQL 5.7、8.0 对用户密码有严格要求，需要包含大小写字母、数字和特殊字符。

### TZ

时区设置，缺省为 `Asia/Shanghai` 。


### DBIP, DBPort, DBUser, DBPassword

在执行脚本前需要指定数据库的**变量**，例如：
```
DBIP localhost
DBPort 3306
DBUser root
DBPassword password
```


### DBTarsPass

因为Tars的源码里面直接设置了mysql数据库里tars用户的密码，所以为了安全起见，可以通过设定此**变量** `DBTarsPass` 来让安装脚本替换掉缺省的tars数据库用户密码。


### INET_NAME
缺省为 `eth0` 。如果是虚拟机或者多网卡机器，需要确定网卡名称，如果不是 `eth0`，那么需要设定**变量** `INET_NAME` 的值为主机网卡名称。网卡名称可以使用命令 `ip address` 来获得，例如下面的输出，可以得到网卡名称为 `enp0s17`：
```
[root@localhost ~]# ip address
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s17: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:27:c7:14 brd ff:ff:ff:ff:ff:ff
    inet 172.16.94.82/24 brd 172.16.94.255 scope global noprefixroute dynamic enp0s17
       valid_lft 691174sec preferred_lft 691174sec
    inet6 fe80::95bb:7d90:e353:253a/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```


### 框架普通基础服务
另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 `/data` 目录之下，脚本本身会自动安装这些服务。你也可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来了解这些服务。


### 重启
系统重启后，TARS服务需要手动启动：
```
cd /usr/local/app/tars
./tars_install.sh
nohup /usr/local/resin/bin/resin.sh console 1>/data/log/resin.log 2>&1 &
```

Docker镜像
-----------

如果你想尝试容器化的Tars，请参考 https://github.com/tangramor/docker-tars 

