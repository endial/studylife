# 简介
自 1970 年埃德加·科德提出关系模型之后，关系型数据库便开始出现，经过了 40 多年的演化，如今的关系型数据库种类繁多，功能强大，使用广泛。面对如此之多的关系型数据库，我们应该如何权衡找出适合自己应用场景的数据库系统呢？[ O.S. Tezer ](https://twitter.com/ostezer)最近在 DigitalOcean 上发表了一篇博文，[对比了SQLite、MySQL 和PostgreSQL 这三个常用的、流行的关系型数据库管理系统（RDBMS）](https://www.digitalocean.com/community/articles/sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems)，希望能对你有所帮助。

[O.S. Tezer ](https://twitter.com/ostezer)分别从数据库支持的数据类型、优势、劣势、何时应该使用以及何时不应该使用该数据库这 5 个方面对 SQLite、MySQL 和 PostgreSQL 做了比较。

## **SQLite**
SQLite 是一款轻型数据库，它遵守 ACID，能够嵌入到使用它的应用程序中。作为一个自包含的、基于文件的数据库，SQLite 提供了非常出色的工具集能够处理所有类型的数据，与托管在服务器上基于进程的关系型数据库相比它的约束更少，也更易用。

当应用程序使用 SQLite 时，SQLite 并非作为一个独立进程通过某种通信协议（例如 socket）与应用程序通信，而是作为应用程序的一部分，应用程序通过调用 SQLite 的接口直接访问数据文件。感谢类库的底层技术，它让 SQLite 变得非常快速、高效并且十分强大。

### SQLite 支持的数据类型
SQLite 支持的数据类型包括：NULL、INTEGER、REAL、TEXT、BLOB。

**注意**：如果你想了解与 SQLite 数据类型相关的更多内容，可以参阅[官方文档](http://www.sqlite.org/datatype3.html)。

### SQLite 的优点
- **基于文件**：整个数据库完全由磁盘上的一个文件构成，这使得它的可移植性非常好。
- **标准化**：尽管它看起来像一个“简化版”的数据库实现，但是 SQLite 确实支持 SQL。它省略了一些功能（RIGHT OUTER JOIN 和 FOR EACH STATEMENT），但同时也增加了一些额外的功能。
- **非常适合开发甚至是测试**：在大多数应用程序的开发阶段，大部分开发人员可能都非常需要一个能够支持并发扩展的解决方案。SQLite 包含丰富的功能，所能提供的特性超乎开发所需，使用起来也非常简洁——只需要一个文件和一个 C 链接库。

### SQLite 的缺点
- **没有用户管理**：高级数据库都支持用户系统，例如管理连接对数据库和表的访问权限。鉴于 SQLite 的目的和性质（没有多客户端并发的高层设计），它并不包含这些功能。
- **缺少通过优化获得额外性能的空间**：还是由于设计方面的原因，无法通过优化 SQLite 获得大量的额外性能。这个类库非常容易调整、也非常容易使用。它并不复杂，所以从技术上无法让它变得更快，因为它已经很快了。

### 何时应该使用 SQLite
- **嵌入式应用程序**：所有需要可移植性、不需要扩展的应用程序，例如单用户的本地应用、移动应用或者游戏。
- **替代磁盘访问**：在很多情况下，需要直接读写磁盘文件的应用程序可以切换到 SQLite 从而受益于 SQLite 提供的额外功能以及使用结构化查询语言（SQL）所带来的简便性。
- **测试**：对大部分应用程序而言没必要使用额外的进程测试业务逻辑（例如应用程序的主要目标：功能）。

### 何时不应该使用 SQLite
- **多用户应用程序**：如果有多个客户端需要访问并使用同一个数据库，那么最好使用功能完整的关系型数据库（例如 MySQL），而不是选择 SQLite。
- **需要高写入量的应用程序**：写操作是 SQLite 的一个局限。该 DBMS 在同一时刻仅允许一个写操作，因而也限制了其吞吐量。



## **MySQL**
MySQL 是最受欢迎的一个大规模数据库服务器。它是一款功能丰富的开源产品，许多网站和在线应用程序都使用该数据库。MySQL 的入门相对比较简单，开发者可以从 Internet 上获取到大量与该数据库相关的信息。

**注意:** 鉴于该产品的受欢迎程度，使用该数据库可以让我们受益于大量第三方应用程序、工具以及集成类库。

尽管 MySQL 并没有尝试实现完整的 SQL 标准，但是它依然为用户提供了大量功能。作为一个独立的数据库服务器，应用程序需要与 MySQL 守护进程通信才能访问数据库——不同于 SQLite。

### MySQL 支持的数据类型
MySQL 支持的数据类型包括 TINYINT、SMALLINT、MEDIUMINT、INT 或 INTEGER、BIGINT、FLOAT、DOUBLE、DOUBLE PRECISION、REAL、DECIMAL、NUMERIC、DATE、DATETIME、TIMESTAMP、TIME、YEAR、CHAR、VARCHAR、TINYBLOB, TINYTEXT、BLOB, TEXT、MEDIUMBLOB、MEDIUMTEXT、LONGBLOB, LONGTEXT、ENUM、SET。

### MySQL 的优点
- **易用**：很容易安装。第三方工具，包括可视化工具，让用户能够很容易入门。
- **功能丰富**：MySQL 支持关系型数据库应该有的大部分功能——或者直接支持、或者间接支持。
- **安全**：支持很多安全特性，有些非常高级，并且是内置于 MySQL 中。
- **可扩展也非常强大**：MySQL 能够处理大量数据，并且在需要的时候可以规模化使用。
- **快速**：放弃某些标准让 MySQL 能够非常高效、简捷地工作，因而速度更快。

### MySQL 的缺点
- **已知限制**：MySQL 从一开始就没有打算做所有事情，因而它在功能方面有一定的局限性，并不能满足一些先进应用程序的要求。
- **可靠性问题**：MySQL 对某些功能（例如引用、事务、审计等）的实现方式使得它与其他的关系型数据库相比缺少了一些可靠性。
- **开发停滞**：尽管 MySQL 依然是一款开源产品，但是自从它被收购之后人们就对其开发进展有很多抱怨。需要注意的是有一些基于 MySQL 的、完整集成的数据库在标准的 MySQL 之上附加了其他价值，例如 MariaDB。

### 何时应该使用 MySQL
- **分布式操作**：如果 SQLite 不能满足你的需求，那么将 MySQL 引入到开发栈中，就像任何其他独立的数据库服务器一样，它能够给你带来大量的操作自由度以及一些先进的功能。
- **高安全性**：MySQL 的安全机制通过一种简单的方式为数据的访问和使用提供了可靠的保护。
- **网站和Web应用**：尽管有一些约束，但是绝大部分网站和 Web 应用都可以简单地运行在 MySQL 上。相关的灵活可扩展的工具非常易于使用和管理——事实证明这些工具在长期运行时非常有用。
- **定制解决方案**：MySQL 有丰富的配置项和运行模式，如果你需要一个高度量身定制的解决方案，那么 MySQL 能够非常容易地尾随并执行你的规则。

### 何时不应该使用 MySQL
- **SQL遵从性**：因为 MySQL 并没有打算实现完整的 SQL 标准，所以它并不完全符合 SQL。如果你可能需要与这样的关系型数据库集成，那么从 MySQL 切换过去可能并不容易。
- **并发性**：尽管 MySQL 和一些其他的存储引擎能够非常好地执行读操作，但是并发读写可能会有问题。
- **缺少功能**：MySQL 缺少某些功能，例如全文本搜索。



## **PostgreSQL**
PostgreSQL 是一款先进的、开源的对象关系型数据库管理系统，它的主要目标是遵从标准和可扩展。PostgreSQL，或者说 Postgres，试图将 ANSI/ISO SQL 标准及其修正结合起来。

与其他关系型数据库相比，PostgreSQL 独特的地方是它支持高度需要的、完整的面向对象以及关系型数据库的功能，例如完全支持可靠性事务。

由于其强大的底层技术，PostgreSQL 能够非常高效地处理很多任务。得益于多版本并发控制（MVCC），它能够在没有读锁的情况下实现并发并保证 ACID。

PostgreSQL 是高度可编程的，因此扩展性非常好，它支持称为“存储过程”的自定义程序。用户可以创建这种函数简化重复的、复杂的以及经常需要的数据库操作的执行。

尽管该数据库非常强大，但是它却没有像 MySQL 那么流行，即便如此依然有很多优秀的第三方工具和类库可以让我们更容易地使用它。

### PostgreSQL 支持的数据类型
PostgreSQL 支持的数据类型包括：bigint、bigserial、bit [(n)]、bit varying [(n)]、boolean、box、bytea、character varying [(n)]、character [(n)]、cidr、circle、date、double precision、inet、integer、interval [fields] [§]、line、lseg、macaddr、money、numeric [(p,s)]、path、point、polygon、real、smallint、serial、text、time、timestamp、tsquery、tsvector、txid_snapshot、uuid、xml

### PostgreSQL 的优点
- **开源且遵从SQL标准**：PostgreSQL 是一款开源的、免费的、功能非常强大的关系型数据库。
- **强大的社区**：由一个忠实的、经验丰富的社区支持，用户可以通过知识库和 Q&A 网站获得全天候的免费服务。
- **强有力的第三方支持**：除了非常先进的特性之外，PostgreSQL 还有很多优秀的、开源的第三方工具可以辅助系统的设计、管理和使用。
- **可扩展**：可以通过存储过程扩展 PostgreSQL 的功能。
- **面向对象**：PostgreSQL 不仅是一个关系型数据库，它还是一个面向对象的数据库——支持嵌套等功能。

### PostgreSQL 的缺点
- **性能**：对于简单繁重的读取操作，使用 PostgreSQL 可能有点小题大做，同时性能也比 MySQL 这样的同类产品要差。
- **流行程度**：尽管有大量的部署，但是鉴于该数据库的性质，它的受欢迎程序并不高。
- **托管**：由于上面提到的几点，很难找到提供托管 PostgreSQL 实例的主机或者服务提供商。

### 何时应该使用 PostgreSQL
- **数据完整性**：当绝对需要可靠性和数据完整性的时候，PostgreSQL 是更好的选择。
- **复杂的定制程序**：如果需要数据库执行定制程序，那么可扩展的 PostgreSQL 是更好的选择。
- **集成**：如果将来可能需要将整个数据库迁移到其他合适的解决方案上（例如 Oracle），那么 PostgreSQL 可能兼容性最好也更容易切换。
- **复杂的设计**：与其他开源且免费的数据库相比，对于复杂的数据库设计 PostgreSQL 在功能方面最全面，潜力最大，不需要你放弃其他有价值的资产。

### 何时不应该使用 PostgreSQL
- **速度**：如果你只需要快速读取操作，那么 PostgreSQL 并不合适。
- **简单**：除非你需要绝对的数据完整性，ACID 遵从性或者设计复杂，否则 PostgreSQL 对于简单的场景而言有点多余。
- **复制**：对于缺少数据库和系统管理经验的人而言使用 MySQL 实现复制要更简单，除非你愿意花费时间、精力和资源。

## 参考
- [SQLite vs MySQL vs PostgreSQL：关系型数据库比较](https://www.infoq.cn/news/2014/04/sqlite-mysql-postgresql?utm_source=related_read_bottom&utm_medium=article)

----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
