# 简述

### 传统数据库缺点

- 大数据场景下I/O较高
  因为数据是按行存储，即使只针对其中某一列进行运算，关系型数据库也会将整行数据从存储设备中读入内存，导致I/O较高
- 存储的是行记录，无法存储数据结构
- 表结构schema扩展不方便
  如要需要修改表结构，需要执行执行DDL(data definition language)，语句修改，修改期间会导致锁表，部分服务不可用
- 全文搜索功能较弱
  关系型数据库下只能够进行子字符串的匹配查询，当表的数据逐渐变大的时候，like查询的匹配会非常慢，即使在有索引的情况下。况且关系型数据库也不应该对文本字段进行索引
- 存储和处理复杂关系型数据功能较弱
  许多应用程序需要了解和导航高度连接数据之间的关系，才能启用社交应用程序、推荐引擎、欺诈检测、知识图谱、生命科学和 IT/网络等用例。然而传统的关系数据库并不善于处理数据点之间的关系。它们的表格数据模型和严格的模式使它们很难添加新的或不同种类的关联信息。



### NoSQL解决方案

NoSQL，泛指非关系型的数据库，可以理解为SQL的一个有力补充。

在NoSQL许多方面性能大大优于非关系型数据库的同时，往往也伴随一些特性的缺失，比较常见的，是事务库事务功能的缺失。

- 列式数据库：如 HBase
- K-V数据库： 如 Redis
- 文档数据库： 如 MongoDB



## SQL数据库

- [MySQL](./MySQL/README.md)
- [MariaDB](./MariaDB/README.md)
- [PostgreSQL](./PostgreSQL/README.md)
- [SQLite](./SQLite/README.md)



### NoSQL数据库

- [MongoDB](./MongoDB/README.md)
- [Redis](./Redis/README.md)



## 参考

- [NoSQL 还是 SQL](https://www.jianshu.com/p/296bacba3510)

----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
