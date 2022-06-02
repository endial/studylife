# 简述
本文主要列名常见的PostgreSQL系统配置环境变量。

- PGHOST: 要联接的主机名，主机名以斜杠开头
- PGHOSTADDR：与之连接的主机的IP地址
- PGPORT： 主机服务器的端口号，或者在 Unix 域套接字联接时的套接字扩展文件名。
- PGDATABASE：数据库名
- PGUSER：要连接的PostgreSQL用户名。 缺省是与运行该应用的用户操作系统名同名的用户。 
- PGPASSWORD：如果服务器要求口令认证，所用的口令。 
- PGPASSFILE：指定密码文件的名称用于查找。如果没有设置， 默认为~/.pgpass 
- PGSERVICE： 用于额外参数的服务名
- PGSERVICEFILE： 指定连接服务的文件中每个用户的名字， 如果没有设置默认~/.pg_service.conf 
- PGREALM： 设置与PostgreSQL一起使用的 Kerberos 域， 如果该域与本地域不同的话
- PGOPTIONS： 添加命令行选项以在运行时发送到服务器。 
- PGAPPNAME： 为application_name配置参数指定一个值。 
- PGSSLMODE： 这个选项决定是否需要和服务器协商一个SSL TCP/IP连接。 
- ~~PGREQUIRESSL~~： 废弃 
- PGSSLCOMPRESSION： SSL连接进行的数据是否压缩
- PGSSLCERT： 这个参数指定客户端SSL认证的文件名
- PGSSLKEY： 这个参数指定客户端使用的秘钥的位置
- PGSSLROOTCERT： 这个参数声明一个包含SSL认证授权(CA)证书的文件名
- PGSSLCRL： 这个参数声明SSL证书撤销列表(CRL)的文件名
- PGREQUIREPEER： 这个参数声明服务器的操作系统用户名
- PGKRBSRVNAME： 使用GSSAPI认证时使用的Kerberos服务名
- PGGSSLIB： 为GSSAPI认证使用的GSS库。只在Windows上使用。 
- PGCONNECT_TIMEOUT： 连接的最大等待时间，以秒计（用十进制整数字串书写）。 
- PGCLIENTENCODING： 为这个连接设置client_encoding配置参数
- PGDATESTYLE： 设置缺省的时区。（等效于SET timezone TO …。） 
- PGTZ 设置缺省的时区。（等效于SET timezone TO …。） (libpq)
- PGSYSCONFDIR 设置包含pg_service.conf文件。 (libpq)
- PGLOCALEDIR 设置包含信息国际化的locale文件目录。

## 参考
- 

----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
