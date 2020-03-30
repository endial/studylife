# 简述

YAML 是 "YAML Ain't a Markup Language"（YAML 不是一种标记语言）的递归缩写。在开发的这种语言时，YAML 的意思其实是："Yet Another Markup Language"（仍是一种标记语言）。

YAML 的语法和其他高级语言类似，并且可以简单表达清单、散列表，标量等数据形态。它使用空白符号缩进和大量依赖外观的特色，特别适合用来表达或编辑数据结构、各种配置文件、倾印调试内容、文件大纲（例如：许多电子邮件标题格式和YAML非常接近）。

YAML 的配置文件后缀为 **.yml**，如：**runoob.yml** 。



## 基本语法

- 大小写敏感
- 使用缩进表示层级关系
- 缩进不允许使用tab，只允许空格
- 缩进的空格数不重要，只要相同层级的元素左对齐即可
- '#'表示注释，YAML中只有行注释



------

## 数据类型

YAML 支持以下几种数据类型：

- 对象：键值对的集合，又称为映射（mapping）/ 哈希（hashes） / 字典（dictionary）
- 数组：一组按次序排列的值，又称为序列（sequence） / 列表（list）
- 纯量（scalars）：单个的、不可再分的值



### YAML 对象

对象键值对使用冒号结构表示 **key: value**，冒号后面要加一个空格。

```yaml
key: value
```



也可以使用 **流式(flow)语法**表示对象。

```yaml
key: {child-key: value, child-key2: value2}
```



还可以使用缩进表示层级关系；

```yaml
key: 
    child-key: value
    child-key2: value2
```



较为复杂的对象格式，可以使用问号加一个空格代表一个复杂的 key，配合一个冒号加一个空格代表一个 value：

```yaml
?  
    - complexkey1
    - complexkey2
:
    - complexvalue1
    - complexvalue2
```

意思即对象的属性是一个数组 [complexkey1,complexkey2]，对应的值也是一个数组 [complexvalue1,complexvalue2]



### YAML 数组

以 **-** 开头的行表示构成一个数组：

```yaml
- A
- B
- C
```



YAML 支持多维数组，可以使用行内表示：

```yaml
key: [value1, value2, ...]
```



数据结构的子成员是一个数组，则可以在该项下面缩进一个空格。

```yaml
-
 - A
 - B
 - C
```

可以简单理解为： [[A,B,C]]



一个相对复杂的例子：

```yaml
companies:
    -
        id: 1
        name: company1
        price: 200W
    -
        id: 2
        name: company2
        price: 500W
```

意思是 companies 属性是一个数组，每一个数组元素又是由 id、name、price 三个属性构成。



数组也可以使用流式(flow)的方式表示：

```yaml
companies: [{id: 1,name: company1,price: 200W},{id: 2,name: company2,price: 500W}]
```



#### 复合结构

数组和对象可以构成复合结构，例：

```yaml
languages:
  - Ruby
  - Perl
  - Python 
websites:
  YAML: yaml.org 
  Ruby: ruby-lang.org 
  Python: python.org 
  Perl: use.perl.org
```

转换为 json 为：

```yaml
{ 
  languages: [ 'Ruby', 'Perl', 'Python'],
  websites: {
    YAML: 'yaml.org',
    Ruby: 'ruby-lang.org',
    Python: 'python.org',
    Perl: 'use.perl.org' 
  } 
}
```



### YAML 常量

纯量是最基本的，不可再分的值，包括：

- 字符串
- 布尔值
- 整数
- 浮点数
- Null
- 时间
- 日期



使用一个例子来快速了解纯量的基本使用：

```yaml
boolean: 
    - TRUE  #true,True都可以
    - FALSE  #false，False都可以
float:
    - 3.14
    - 6.8523015e+5  #可以使用科学计数法
int:
    - 123
    - 0b1010_0111_0100_1010_1110    #二进制表示
null:
    nodeName: 'node'
    parent: ~  #使用~表示null
string:
    - 哈哈
    - 'Hello world'  #可以使用双引号或者单引号包裹特殊字符
    - newline
      newline2    #字符串可以拆成多行，每一行会被转化成一个空格
date:
    - 2018-02-17    #日期必须使用ISO 8601格式，即yyyy-MM-dd
datetime: 
    -  2018-02-17T15:02:31+08:00    #时间使用ISO 8601格式，时间和日期之间使用T连接，最后使用+代表时区
```



### 特殊符号

- `---`

YAML可以在同一个文件中，使用`---`表示一个文档的开始，比如Springboot中profile的定义：

```
server:
    address: 192.168.1.100
---
spring:
    profiles: development
    server:
        address: 127.0.0.1
---
spring:
    profiles: production
    server:
        address: 192.168.1.120
```

代表定义了两个profile，一个是development，一个production。



也常常使用`---`来分割不同的内容，比如记录日志：

```
---
Time: 2018-02-17T15:02:31+08:00
User: ed
Warning:
     This is an error message for the log file
---
Time: 2018-02-17T15:05:21+08:00
User: ed
Warning:
    A slightly different error message.
```



- `...`和`---`配合使用

在一个配置文件中代表一个文件的结束：

```
---
time: 20:03:20
player: Sammy Sosa
action: strike (miss)
...
---
time: 20:03:47
player: Sammy Sosa
action: grand slam
...
```

相当于在一个yaml文件中连续写了两个yaml配置项。



- `!!`

YAML中使用!!做类型强行转换：

```
string:
    - !!str 54321
    - !!str true
```

相当于把数字和布尔类型强转为字符串。



- `>`和`|`

`>`在字符串中折叠换行，`|`保留换行符，这两个符号是YAML中字符串经常使用的符号，比如：

```
accomplishment: >
 Mark set a major league
 home run record in 1998.
stats: |
 65 Home Runs
 0.278 Batting Average
```

要注意一点的是，每行的文本前一定要有一个空格。那么结果是：

```
accomplishment=Mark set a major league home run record in 1998.
stats=65 Home Runs
 0.278 Batting Average,
```



- `&`和`*`

重复的内容在YAML中可以使用&来完成锚点定义，使用*来完成锚点引用，例如：

```yaml
defaults: &defaults
  adapter:  postgres
  host:     localhost

development:
  database: myapp_development
  <<: *defaults

test:
  database: myapp_test
  <<: *defaults
```

相当于:

```yaml
defaults:
  adapter:  postgres
  host:     localhost

development:
  database: myapp_development
  adapter:  postgres
  host:     localhost

test:
  database: myapp_test
  adapter:  postgres
  host:     localhost
```

**&** 用来建立锚点（defaults），**<<** 表示合并到当前数据，***** 用来引用锚点。



下面是另一个例子:

```yaml
- &showell Steve 
- Clark 
- Brian 
- Oren 
- *showell 
```

转为 JavaScript 代码如下:

```yaml
[ 'Steve', 'Clark', 'Brian', 'Oren', 'Steve' ]
```



- 合并内容

主要和锚点配合使用，可以将一个锚点内容直接合并到一个对象中。例如：

```
merge:
  - &CENTER { x: 1, y: 2 }
  - &LEFT { x: 0, y: 2 }
  - &BIG { r: 10 }
  - &SMALL { r: 1 }
  
sample1: 
    <<: *CENTER
    r: 10
    
sample2:
    << : [ *CENTER, *BIG ]
    other: haha
    
sample3:
    << : [ *CENTER, *BIG ]
    r: 100
```

在merge中，定义了四个锚点，分别在sample中使用。
		sample1中，<<: *CENTER意思是引用{x: 1,y: 2}，并且合并到sample1中，那么合并的结果为：sample1={r=10, y=2, x=1}

sample2中，<<: [*CENTER, *BIG] 意思是联合引用{x: 1,y: 2}和{r: 10}，并且合并到sample2中，那么合并的结果为：sample2={other=haha, x=1, y=2, r=10}

sample3中，引入了*CENTER, *BIG，还使用了r: 100覆盖了引入的r: 10，所以sample3值为：sample3={r=100, y=2, x=1}

有了合并，我们就可以在配置中，把相同的基础配置抽取出来，在不同的子配置中合并引用即可。



## 参考

- https://www.ruanyifeng.com/blog/2016/07/yaml.html
- https://www.jianshu.com/p/97222440cd08
- https://daihainidewo.github.io/blog/yaml%E6%95%99%E7%A8%8B/
- https://www.runoob.com/w3cnote/yaml-intro.html



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))