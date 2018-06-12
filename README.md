# Tencent Tars 的 一键安装 脚本

* [MySQL](#mysql)
* [变量](#变量)
  * [TZ](#tz)
  * [DBIP, DBPort, DBUser, DBPassword](#dbip-dbport-dbuser-dbpassword)
  * [DBTarsPass](#dbtarspass)
  * [MOUNT_DATA](#mount_data)
  * [INET_NAME](#inet_name)
  * [MASTER](#master)
  * [框架普通基础服务](#框架普通基础服务)
* [Docker镜像](#docker镜像)


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
缺省为 `eth0` 。如果是虚拟机或者多网卡机器，需要确定网卡名称，如果不是 `eth0`，那么需要设定**变量** `INET_NAME` 的值为主机网卡名称，例如 `ens160`。


### 框架普通基础服务
另外安装脚本把构建成功的 tarslog.tgz、tarsnotify.tgz、tarsproperty.tgz、tarsqueryproperty.tgz、tarsquerystat.tgz 和 tarsstat.tgz 都放到了 `/data` 目录之下，脚本本身会自动安装这些服务。你也可以参考Tars官方文档的 [安装框架普通基础服务](https://github.com/Tencent/Tars/blob/master/Install.md#44-%E5%AE%89%E8%A3%85%E6%A1%86%E6%9E%B6%E6%99%AE%E9%80%9A%E5%9F%BA%E7%A1%80%E6%9C%8D%E5%8A%A1) 来了解这些服务。


Docker镜像
-----------

如果你想尝试容器化的Tars，请参考 https://github.com/tangramor/docker-tars 

