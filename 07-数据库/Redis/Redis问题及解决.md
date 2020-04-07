# 简介

本文档主要记录Redis使用中常见问题及解决方法。

解决方案中相关路径为Centos系统下，使用默认方式安装时，对应的路径。如果为其他安装方式，需要酌情修改。



## 忘记管理员密码

忘记管理员密码主要包含未修改默认密码和已修改密码两种情况，以下分别做对应处理。



### 未更改管理员密码

1.进入`/var/lib/Jenkins/secrets`目录，打开`initialAdminPassword`文件，复制密码

2.访问Jenkins页面，输入管理员用户名`admin`，及刚才的密码

3.进入后可更改管理员密码



### 重置管理员密码

修改 `<JENKINS_HOME>/users/<usernamedir>` 目录下的`config.xml` 文件。这里`<usernamedir>`为需要修改密码的用户对应的目录，如 `admin` 对应的目录可能为 `admin_2702307368144028043`。

- 默认安装时，HOME为 /var/lib/jenkins
- 如果是`java -jar`方式启动的，HOME目录位于`/root/.jenkins`

在文件`config.xml`文件中，修改以下内容：

```shell
修改<passwordHash> </passwordHash>标签中内容，如：
#jbcrypt:$2a$10$DdaWzN64JgUtLdvxWIflcuQu2fgrrMSAMabF5TSrGK5nXitqK9ZMS

修改为：
#jbcrypt:$2a$10$4NW.9hNVyltZlHzrNOOjlOgfGrGUkZEpBfhkaUrb7ODQKBVmKRcmK

后者是123456的hash值
```



重启Jenkins，并使用新的密码`123456`登录，重新修改密码。



### 禁用管理员密码

修改 `<JENKINS_HOME>/users/<usernamedir>` 目录下的`config.xml` 文件。这里`<usernamedir>`为需要修改密码的用户对应的目录，如 `admin` 对应的目录可能为 `admin_2702307368144028043`。

- 默认安装时，HOME为 /var/lib/jenkins
- 如果是`java -jar`方式启动的，HOME目录位于`/root/.jenkins`

在文件`config.xml`文件中，删除以下内容：

```
<useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
    <enableCaptcha>false</enableCaptcha>
  </securityRealm>
```



1. 重启Jenkins，进入首页>`系统管理`>`Configure Global Security`；
2. 勾选`启用安全`；
3. 点选`Jenkins专有用户数据库`，并`保存`修改；
4. 重新点击首页>`系统管理`,发现此时出现`管理用户`；
5. 点击进入展示`用户列表`；
6. 点击右侧进入修改密码页面，修改后即可重新使用密码登录。



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

