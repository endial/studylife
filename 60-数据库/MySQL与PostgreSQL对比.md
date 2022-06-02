# MySQL与PostgreSQL对比


本文参考网络文章，整理 MySQL 和 PostgreSQL 的对比分析信息，方便使用时选择。

PostgreSQL 和 MySQL 都是最流行的开源数据库。MySQL 被认为是世界上最流行的数据库，而 PostgreSQL 被认为是世界上最先进的数据库。MySQL 并不完全符合 SQL 标准，并且很多 PG 上的特性并不支持。这就是为什么 PG 受到大量开发者喜欢的原因，并且现在 PG 越来越流行。

前几年，Oracle 收购了 MySQL，导致 MySQL 的出现两个版本：商业版和社区版。对于后者，由于 Oracle 控制了 MySQL 的开发，受到了广大使用者的批评。

PostgreSQL 是世界上最受欢迎的数据库：他支持大量企业级特性和功能。PG 由 postgresql 全球社区开发，该社区由一批优秀的开发人员组成，几十年来一直努力确保 PG 具有丰富的功能，并与其他开源、商业数据库竞争。社区也从世界各地的公司得到巨大贡献。

## 为什么使用PG

PG 作为开源、功能丰富的数据库，可与 Oracle 展开竞争。开发者也会将 PG 当做 NoSQL 数据库来使用。在云中和本地部署使用 PG 非常简单，也可以在 docker 容器等各个平台使用。

PG 完全支持 ACID，对开发人员和 DBA 非常友好，是跨任何域的高并发事务、复杂应用程序最佳选择，可以满足基于 WEB 和移动的各种应用程序服务。PG 也是一个非常好的数据仓库，用于大数据上运行复杂的报告查询。

## 为什么使用MySQL

MySQL 具有社区版和商业版。商业版由 Oracle 管理。作为关系型数据库，部署和使用非常简单。但是对于 SQL 标准要求很高的应用不太合适。MySQL 的集成能力也有限，很难成为异构数据库环境的一部分。

MySQL 适用于简单 web 应用程序或者需要简单 schema、SQL 执行数据库操作的应用。对于处理大量数据的复杂应用来说，MySQL 并不是一个很好的选择。

## 易用性

PG 能够处理结构化和非结构化的数据、具备关系型数据库所有的特性。
MySQL 在 SQL 和特性方面的局限性可能会为其构建高效的 RDBMS 应用程序带来挑战。

## 语法

大部分数据库的 SQL 语法都比较相似。然而，MySQL 并不支持所有的 SQL。对于支持的 SQL 和其他数据库都比较相似。例如查询，PG 和 MySQL 都是：

```SQL
SELECT * FROM employees;
```

## 数据类型

MySQL 和 PG 都支持许多数据类型，从传统的数据类型（integer、date、timestamp）到复杂类型（json、xml、text）。然而，在复杂实时数据查询下又有所不同。

PG 不止支持传统数据类型：numeric、strings、date、decimal等，还支持非结构的数据类型：json、xml、hstore 等以及网络数据类型、bit 字符串，还有 ARRAYS，地理数据类型。

MySQL 不支持地理数据类型。

从9.2开始，PG 支持 json 数据类型。相对于 MySQL 来说，PG 对 json 的支持比较先进。他有一些 json 指定的操作符和函数，是的搜索 json 文本非常高效。9.4开始，可以以二进制的格式存储 json 数据，支持在该列上进行全文索引（GIN索引），从而在 json 文档中进行快速搜索。

从5.7开始，MySQL 支持 json 数据类型，比 PG 晚。也可以在 json 列上建立索引。然而对 json 相关的函数的支持比较有限。不支持在 json 列上全文索引。由于 MySQL 对 SQL 支持的限制，在存储和处理 json 数据方面，MySQL 不是一个很好的选择。

## 复制和集群

MySQL 和 PG 都具有复制和集群的能力，能够确保数据操作水平分布。

MySQL 支持主-备、一主多备的复制机制，通过 SQLs 即 binlog 保证将所有的数据传输到备机上。这也是复制只能是异步、半同步的原因。

优点：备机可以写。这就意味着一旦 master 崩溃了，slave 可以马上接管，确保应用正常工作。DBAs 需要确保 slave 变成主了，并且新的 binlog 复制到原主。当有很多长 SQL 时，复制会变得慢。

MySQL 也支持 NDB 集群，即多主的复制机制。这种类型的复制对要求水平扩展的事务有利。

PG 的复制和 MySQL 不同，他是基于 WAL 文件，使复制更加可靠、更快、更有利于管理。他也支持主备和一主多从的模式，包括级联复制形式。PG 的复制成为流复制或物理复制，可以异步也可以同步。

默认情况下，复制时异步，Slave 能够满足读请求。如果要求在备机上读到的数据和主机上一样，就需要设置同步复制。但是缺点是一旦备机上事务没有提交，主机就会 hang 住。

可以使用第三方工具 Slony、Bucardo、Londiste、RubyRep 等对表级别的复制进行归档。这些工具都是基于触发器的复制。PG 也支持逻辑复制。最初通过 pglogical 扩展支持逻辑复制，从10开始内核支持逻辑复制。

## 视图

MySQL 支持视图，视图下面通过 SQL 使用的表的个数限制为 61。视图不存储物理数据，也不支持物化视图。简单 SQL 语句创建的视图可以更新，复杂 SQL 创建的视图不可以更新。

PG 和 MySQL 类似。简单 SQL 创建的视图可更新，复杂的不行。但是可以通过 RULES 更新复杂的视图。PG 支持物化视图和 REFRESHED。

## 触发器

MySQL 支持 INSERT、UPDATE、DELETE 上 AFTER 和 BEFORE 事件的触发器。触发器不同执行动态 SQL 语句和存储过程。

PG 的触发器比较先进。支持 AFTER、BEFORE、INSTEAD OF 事件的触发器。如果在触发器唤醒时执行一个复杂的 SQL，可以通过函数来完成。PG 中的触发器可以动态执行函数：

```SQL
CREATE TRIGGER audit

AFTER INSERT OR UPDATE OR DELETE ON employee

  FOR EACH ROW EXECUTE FUNCTION employee_audit_func();
```

## 存储过程

MySQL 和 PG 都支持存储过程，但 MySQL 仅支持标准的 SQL 语法，而 PG 支持非常先进的存储过程。

PG 以带 RETURN VOID 子句的函数形式完成存储过程。PG 支持的语言有很多：Ruby、Perl、Python、TCL、PL/pgSQL、SQL 和 JavaScript。

而 MySQL 则没有这么多。

### **10、查询**

使用 MySQL 时需要考虑的限制：

- 某些UPDATE SQL的返回值不符合SQL标准
```MYSQL
mysql> select * from test;

+------+------+

| c | c1  |

+------+------+

|  10 |  100 |

+------+------+

1 row in set (0.01 sec)

mysql> update test set c=c+1, c1=c;

Query OK, 1 row affected (0.01 sec)

Rows matched: 1  Changed: 1  Warnings: 0

mysql>  select * from test;

+------+------+

| c | c1  |

+------+------+

|  11 |  11 |

+------+------+

1 row in set (0.00 sec)

预期的标准形式：

mysql>  select * from test;

+------+------+

| c | c1  |

+------+------+

|  11 |  10 |

+------+------+
```


- 不能执行的UPDATE或DELETE语句：
```MYSQL
mysql> delete from test where c in (select t1.c from test t1, test t2 where t1.c=t2.c);

ERROR 1093 (HY000): 
```


- 子查询中不能使用LIMIT子句
```MYSQL
mysql> select * from test where c in (select c from test2 where c<3 limit 1);

ERROR 1235 (42000): 
```


- MySQL也不支持“LIMIT & IN/ALL/ANY/SOME子句”。同样也不支持FULL OUTER JOINS、INTERSECT、EXCEPT等。也不支持Partial索引、bitmap索引、表达式索引等。PG支持所有SQL标准的特性。

对于需要写复杂SQL的开发者来说，PG是一个很好的选择。

## 分区

MySQL 和 PG 都支持表分区，然而双方都有一些限制。

MySQL 支持的分区类型有 RANGE、LIST、HASH、KEY 和 COLUMNS（RANGE和LIST），也支持 SUBPARTITIONING。然而 DBA 在使用时可能不太易用。
- MySQL8.0，只有innodb和NDB存储引擎支持表分区，其他存储引擎不支持。
- 如果分区key的列不是主键或者唯一键的一部分，那么就不可能对表进行分区。
- 从5.7.24开始，逐步取消支持将表分区放在表空间上，这意味着DBA无法平衡表分区和磁盘IO。
```MYSQL
mysql> create table emp (id int not null, fname varchar (30), lname varchar(30), store_id int not null ) partition by range (store_id) ( partition p0 values less than (6) tablespace tbs, partition p1 values less than(20) tablespace tbs1, partition p2 values less than (40) tablespace tbs2);

ERROR 1478 (HY000): InnoDB : A partitioned table is not allowed in a shared tablespace.

mysql>
```

PG 支持表分区继承和声明表分区。声明表分区在`10`引入，和 MySQL 类似，而表分区继承通过使用触发器和规则来完成。分区类型支持 RANGE、LIST、HASH。限制：
- 和MySQL类似，声明表分区只能在主键和唯一键上。
- 继承表分区，子表不能继承主键和唯一键。
- INSERT和UPDATE不能自动恒信到字表。

## 表的扩展性

表段变得越来越大时会造成性能问题，在这个表上的查询会占用更多资源，花费更多时间。MySQL 和 PG 需考虑不同因素。

MySQL 支持 B+tree 索引和分区，这些可以对大表提升性能。然而，由于不支持 bitmap、partial 和函数索引，DBA 不能更好的进行调优。而且分区表不能放到不同表空间上，这也造成 IO 不能更好平衡。

PG 的表达式索引、partial 索引、bitmap 索引和全文索引都可以提升大表的性能。PG 的表分区和索引可以放到不同的磁盘上，能够更好提升表的扩展性。为实现水平表级别的扩展，可以使用citusdb、Greenplum、Netezza 等。开源的 PG 不支持水平表分区，PostgresXC 支持，但是他的性能不好。

## 存储

数据存储是数据库的一个关键能力。PG 和 MySQL 都提供多种选项存储数据。

PG 有一个通用的存储特性：表空间能够容纳表、索引、物化视图等物理对象。通过表空间，可以将对象进行分组并存储到不同物理位置，可以提升 IO 能力。PG12 之前版本，不支持可拔插存储，`12`只支持可拔插架构。

MySQL 和PG 类似，未来具有表空间特性。他支持可拔插存储引擎。这是 MySQL 的一个优点。

## 支持的数据模型

关系型数据库的 NoSQL 能力能够帮助处理非结构化的数据，例如 json、xml、text 等。

MySQL 的 NoSQL 能力比较有限。`5.7`引入了 json 数据类型，需要很长时间才能变得更加成熟。

PG 具有丰富的 json 能力，未来 3 年内是需要 NoSQL 能力的开发者的一个很好的选择。Json 和 jsonb 数据类型，使得 PG 对 json 操作更快更有效。同样可以在 json 数据列上建立 B-tree 索引和 GIN 索引。XML 和 HSTORE 数据类型可以处理 XML 格式以及其他复杂 text 格式的数据。对空间数据类型的支持，使得 PG 是一个完整的多模型数据库。

## 安全性

数据库安全在未认证即可访问的数据库中扮演者很重要的角色。安全包括对象级别和连接级别。

MySQL 通过 ROLES 和 PRIVILEGES 将访问权限付给数据库、对象和连接。每个用户都需要赋予连接权限。
```MYSQL
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser@'192.168.1.1’ IDENTIFIED BY 'newpassword';

GRANT ALL PRIVILEGES ON testdb.* TO 'testuser@'192.168.1.*’ IDENTIFIED BY 'newpassword';
```

每次赋权时都需要指定密码，否则用户将不能连接。

MySQL 同样支持 SSL 连接。可以和外部认证系统 LDAP 和 PAM 集成。**是其企业版一部分**。

PG 使用 GRANT 命令通过 ROLES 和 PRIVILEGES 提供访问权限。连接认证比较简单，通过pg_hba.conf 认证文件设置：
```POSTGRESQL
host  database  user  address  auth-method  [md5 or trust or reject]
```

PG 开源版本同样支持 SSL 连接，可以和外部认证系统集成。

解析函数对一组行数据进行聚合。有两种类型的解析函数：窗口函数和聚合函数。聚合函数执行聚合并返回记录集合的一个聚合值（sum,avg,min,max等）；而解析函数返回每个记录的聚合值。MySQL 和 PG 都支持多种聚合函数。MySQL8.0 才支持窗口函数，PG 很早就已经支持了。

PG 支持的窗口函数：

| 函数名       | 描述                                                         |
| :----------- | :----------------------------------------------------------- |
| CUME_DIST    | Return the relative rank of the current row.                 |
| DENSE_RANK   | Rank the current row within its partition without gaps.      |
| FIRST_VALUE  | Return a value evaluated against the first row within its partition. |
| LAG          | Return a value evaluated at the row that is at a specified physical offset row before the current row within the partition. |
| LAST_VALUE   | Return a value evaluated against the last row within its partition. |
| LEAD         | Return a value evaluated at the row that is offset rows after the current row within the partition. |
| NTILE        | Divide rows in a partition as equally as possible and assign each row an integer starting from 1 to the argument value. |
| NTH_VALUE    | Return a value evaluated against the nth row in an ordered partition. |
| PERCENT_RANK | Return the relative rank of the current row (rank-1) / (total rows-1) |
| RANK         | Rank the current row within its partition with gaps.         |
| ROW_NUMBER   | Number the current row within its partition starting from 1. |

MySQL 支持 PG 所有的窗口函数，除了以下限制：
- 窗口函数不能出现在UPDATE和DELETE中
- 窗口函数不支持DISTINCT
- 窗口函数不支持NESTED

## 图形界面工具

MySQL 有 Oracle 的 SQL Developer、MySQL workbench、dbeaver、omnidb 等，监控工具有 nagios、cacti、zabbix 等。

PG 也可以使用 Oracle 的 SQL Developer、pgAdmin、omnidb、dbeaver。监控工具有Nagios、Zabbix、Cacti。

## 性能

MySQL 数据库性能调优选项比较有限，很多索引类型都不支持。写一个高效的 SQL 语句具有挑战性。对于大规模数据，MySQL 也不是个很好的选择。表空间仅支持 innodb，并且无法容纳表分区。

PG 非常适合任何类型的负载：OLTP，OLAP，数据仓库等。由于支持的索引类型比较多，可以更好的提升性能。PG 也有选项采集数据库内存使用，分区表可以放到不同表空间平衡 IO。

## Adoption

PG 是世界上最先进的开源数据库。 EnterpriseDB 和 2ndQuadrant 公司能够保证 PG 在世界范围上被更多用户使用。

MySQL 表示 RDBMS 和 ORDBMS 应用的最佳选择。因为自从 Oracle 收购 MySQL 依赖，MySQL 的采用率明显下降，开源领域的开发进度也受到冲击，招致 MySQL 用户的批评。

## 最佳环境

MySQL 流行于 LAMP 栈，PG 流行于 LAPP 栈。
- LAPP 栈代表 Linux、Apache、Postgres、Php/Python，并且越来越流行。
- LAMP 栈代表 Linux、Apache、MySQL/MongoDB、Php/Python。


## 参考
- [PostgreSQL vs. MySQL: A 360-degree Comparison [Syntax, Performance, Scalability and Features]](https://www.enterprisedb.com/blog/postgresql-vs-mysql-360-degree-comparison)

----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
