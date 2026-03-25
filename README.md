# 实训项目九：线上图书借阅平台

## 演示视频

[点击观看项目演示](https://www.bilibili.com/video/BV1DyQmBEEuz/?spm_id_from=333.1387.homepage.video_card.click&vd_source=1ff96076ef65cddcd556fca3d3bcb99b)

## 要求

项目定位：面向社区/校园读者，提供纸质图书的在线检索、预约借阅、续借与逾期管理，打造便捷的微型图书馆服务。

**用户端模块（读者）：**

    账号与个人中心：绑定紧急联系人，查看借阅记录，评价图书。

    图书浏览与借阅：按分类浏览图书，搜索ISBN，提交借阅申请。

    借阅跟踪与反馈：接收取书通知，在线续借，提交阅读反馈。



**管理端模块（图书馆管理员）：**

    图书管理：录入图书信息，设置热门图书，标记预约状态。

    借阅处理：审核借阅资格，发送逾期提醒，处理续借申请。

    数据统计：分析借阅数据，优化采购与陈列。

## 项目结构

```
BookBorrowSystem/
├── WEB-INF/
│   ├── web.xml
│   └── lib/ (数据库驱动等jar包)
├── index.jsp (首页)
├── login.jsp (登录)
├── register.jsp (注册)
├── user/ (用户端)
│   ├── dashboard.jsp (个人中心)
│   ├── book_list.jsp (图书列表)
│   ├── borrow_list.jsp (借阅记录)
│   └── feedback.jsp (反馈评价)
├── admin/ (管理端)
│   ├── dashboard.jsp (管理首页)
│   ├── book_manage.jsp (图书管理)
│   ├── borrow_manage.jsp (借阅管理)
│   └── statistics.jsp (数据统计)
└── database.jsp (数据库连接)
```

## 数据库

```cmd
E:\mysql\mysql\bin>mysql -uroot -p
mysql> show databases
    -> ;
+-------------------------+
| Database                |
+-------------------------+
| animal_db               |
| information_schema      |
| mysql                   |
| performance_schema      |
| pethospital             |
| rjgc_book_borrow_system |
| sys                     |
+-------------------------+
7 rows in set (0.020 sec)

mysql> use rjgc_book_borrow_system;
Database changed
mysql> SHOW TABLES;
+-----------------------------------+
| Tables_in_rjgc_book_borrow_system |
+-----------------------------------+
| rjgc_books                        |
| rjgc_borrow_records               |
| rjgc_borrow_requests              |
| rjgc_feedbacks                    |
| rjgc_notifications                |
| rjgc_renew_requests               |
| rjgc_users                        |
| rjgc_view_popular_books           |
+-----------------------------------+
8 rows in set (0.018 sec)

mysql> DESC rjgc_books;
+------------------+--------------+------+-----+----------------------------+-------------------+
| Field            | Type         | Null | Key | Default                    | Extra             |
+------------------+--------------+------+-----+----------------------------+-------------------+
| id               | int          | NO   | PRI | NULL                       | auto_increment    |
| isbn             | varchar(20)  | NO   | UNI | NULL                       |                   |
| title            | varchar(200) | NO   |     | NULL                       |                   |
| author           | varchar(100) | YES  |     | NULL                       |                   |
| publisher        | varchar(100) | YES  |     | NULL                       |                   |
| publish_date     | date         | YES  |     | NULL                       |                   |
| category         | varchar(50)  | YES  |     | NULL                       |                   |
| total_copies     | int          | YES  |     | 1                          |                   |
| available_copies | int          | YES  |     | 1                          |                   |
| location         | varchar(100) | YES  |     | NULL                       |                   |
| is_hot           | tinyint(1)   | YES  |     | 0                          |                   |
| is_reserved      | tinyint(1)   | NO   |     | 0                          |                   |
| reserved_until   | date         | YES  |     | NULL                       |                   |
| created_at       | timestamp    | YES  |     | CURRENT_TIMESTAMP          | DEFAULT_GENERATED |
| cover_url        | varchar(255) | YES  |     | ../images/default-book.jpg |                   |
+------------------+--------------+------+-----+----------------------------+-------------------+
15 rows in set (0.052 sec)

mysql> DESC rjgc_books;
+------------------+--------------+------+-----+----------------------------+-------------------+
| Field            | Type         | Null | Key | Default                    | Extra             |
+------------------+--------------+------+-----+----------------------------+-------------------+
| id               | int          | NO   | PRI | NULL                       | auto_increment    |
| isbn             | varchar(20)  | NO   | UNI | NULL                       |                   |
| title            | varchar(200) | NO   |     | NULL                       |                   |
| author           | varchar(100) | YES  |     | NULL                       |                   |
| publisher        | varchar(100) | YES  |     | NULL                       |                   |
| publish_date     | date         | YES  |     | NULL                       |                   |
| category         | varchar(50)  | YES  |     | NULL                       |                   |
| total_copies     | int          | YES  |     | 1                          |                   |
| available_copies | int          | YES  |     | 1                          |                   |
| location         | varchar(100) | YES  |     | NULL                       |                   |
| is_hot           | tinyint(1)   | YES  |     | 0                          |                   |
| is_reserved      | tinyint(1)   | NO   |     | 0                          |                   |
| reserved_until   | date         | YES  |     | NULL                       |                   |
| created_at       | timestamp    | YES  |     | CURRENT_TIMESTAMP          | DEFAULT_GENERATED |
| cover_url        | varchar(255) | YES  |     | ../images/default-book.jpg |                   |
+------------------+--------------+------+-----+----------------------------+-------------------+
15 rows in set (0.025 sec)

mysql> DESC rjgc_borrow_requests;
+--------------+---------------------------------------------------+------+-----+-------------------+-------------------+
| Field        | Type                                              | Null | Key | Default           | Extra             |
+--------------+---------------------------------------------------+------+-----+-------------------+-------------------+
| id           | int                                               | NO   | PRI | NULL              | auto_increment    |
| user_id      | int                                               | NO   | MUL | NULL              |                   |
| book_id      | int                                               | NO   | MUL | NULL              |                   |
| request_date | timestamp                                         | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| status       | enum('PENDING','APPROVED','REJECTED','CANCELLED') | NO   | MUL | PENDING           |                   |
| review_date  | timestamp                                         | YES  |     | NULL              |                   |
| reviewer_id  | int                                               | YES  |     | NULL              |                   |
| remark       | varchar(255)                                      | YES  |     | NULL              |                   |
+--------------+---------------------------------------------------+------+-----+-------------------+-------------------+
8 rows in set (0.015 sec)

mysql> DESC rjgc_feedbacks;
+-------------+-----------+------+-----+-------------------+-------------------+
| Field       | Type      | Null | Key | Default           | Extra             |
+-------------+-----------+------+-----+-------------------+-------------------+
| id          | int       | NO   | PRI | NULL              | auto_increment    |
| user_id     | int       | NO   | MUL | NULL              |                   |
| book_id     | int       | NO   | MUL | NULL              |                   |
| rating      | int       | YES  |     | NULL              |                   |
| comment     | text      | YES  |     | NULL              |                   |
| created_at  | timestamp | YES  |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| submit_date | datetime  | YES  |     | NULL              |                   |
+-------------+-----------+------+-----+-------------------+-------------------+
7 rows in set (0.019 sec)

mysql> DESC rjgc_notifications;
+-------------------+--------------+------+-----+-------------------+-------------------+
| Field             | Type         | Null | Key | Default           | Extra             |
+-------------------+--------------+------+-----+-------------------+-------------------+
| id                | int          | NO   | PRI | NULL              | auto_increment    |
| user_id           | int          | NO   | MUL | NULL              |                   |
| notification_type | varchar(100) | YES  |     | NULL              |                   |
| title             | varchar(255) | YES  |     | NULL              |                   |
| content           | text         | YES  |     | NULL              |                   |
| is_read           | tinyint(1)   | YES  |     | 0                 |                   |
| related_record_id | int          | YES  |     | NULL              |                   |
| sent_at           | timestamp    | YES  |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
+-------------------+--------------+------+-----+-------------------+-------------------+
8 rows in set (0.023 sec)

mysql> DESC renew_requests;
ERROR 1146 (42S02): Table 'rjgc_book_borrow_system.renew_requests' doesn't exist
mysql> DESC rjgc_renew_requests;
+----------------+---------------------------------------+------+-----+-------------------+-------------------+
| Field          | Type                                  | Null | Key | Default           | Extra             |
+----------------+---------------------------------------+------+-----+-------------------+-------------------+
| id             | int                                   | NO   | PRI | NULL              | auto_increment    |
| borrow_id      | int                                   | NO   | MUL | NULL              |                   |
| request_date   | timestamp                             | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| status         | enum('PENDING','APPROVED','REJECTED') | NO   | MUL | PENDING           |                   |
| processed_date | timestamp                             | YES  |     | NULL              |                   |
| remark         | varchar(255)                          | YES  |     | NULL              |                   |
+----------------+---------------------------------------+------+-----+-------------------+-------------------+
6 rows in set (0.022 sec)

mysql> DESC rjgc_users;
+-------------------+----------------------+------+-----+-------------------+-------------------+
| Field             | Type                 | Null | Key | Default           | Extra             |
+-------------------+----------------------+------+-----+-------------------+-------------------+
| id                | int                  | NO   | PRI | NULL              | auto_increment    |
| username          | varchar(50)          | NO   | UNI | NULL              |                   |
| password          | varchar(100)         | NO   |     | NULL              |                   |
| email             | varchar(100)         | YES  |     | NULL              |                   |
| phone             | varchar(20)          | YES  |     | NULL              |                   |
| user_type         | enum('user','admin') | YES  |     | user              |                   |
| emergency_contact | varchar(100)         | YES  |     | NULL              |                   |
| borrow_limit      | int                  | YES  |     | 5                 |                   |
| created_at        | timestamp            | YES  |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| avatar_url        | varchar(255)         | YES  |     | NULL              |                   |
+-------------------+----------------------+------+-----+-------------------+-------------------+
10 rows in set (0.022 sec)

mysql> DESC rjgc_view_popular_books;
+--------------+---------------+------+-----+---------+-------+
| Field        | Type          | Null | Key | Default | Extra |
+--------------+---------------+------+-----+---------+-------+
| 图书ID       | int           | NO   |     | 0       |       |
| ISBN号       | varchar(20)   | NO   |     | NULL    |       |
| 图书名称     | varchar(200)  | NO   |     | NULL    |       |
| 作者         | varchar(100)  | YES  |     | NULL    |       |
| 分类         | varchar(50)   | YES  |     | NULL    |       |
| 可借数量     | int           | YES  |     | 1       |       |
| 是否热门     | tinyint(1)    | YES  |     | 0       |       |
| 借阅次数     | bigint        | NO   |     | 0       |       |
| 平均评分     | decimal(14,4) | NO   |     | 0.0000  |       |
+--------------+---------------+------+-----+---------+-------+
9 rows in set (0.022 sec)

mysql>
```

## 已实现功能：

### 1.用户端模块（读者）

账号与个人中心：
LoginServlet.java 和 RegisterServlet.java 实现用户注册登录
EditProfileServlet.java 支持个人资料编辑，包含紧急联系人功能
dashboard.jsp 展示个人中心信息
borrow_list.jsp 查看借阅记录
图书浏览与借阅：
book_list.jsp 按分类浏览图书，支持搜索功能
BorrowServlet.java 处理借阅申请，验证借阅上限和库存
ISBN搜索功能已实现
借阅跟踪与反馈：
ReturnBookServlet.java 支持在线归还功能
RenewServlet.java 支持在线续借功能
OverdueReminderServlet.java 处理逾期提醒
FeedbackServlet.java 支持提交阅读反馈

### 2.管理端模块（图书馆管理员）

图书管理：
UpdateBookServlet.java 实现图书信息录入和编辑
ToggleHotServlet.java 设置热门图书
ToggleReserveServlet.java 标记预约状态
DeleteBookServlet.java 删除图书功能
借阅处理：
HandleRenewServlet.java 处理续借申请
SendOverdueReminderServlet.java 发送逾期提醒
借阅审核功能已实现
数据统计：
statistics.jsp 实现借阅数据统计分析
dashboard.jsp 显示系统统计数据

## 详细文件分析

### 1.配置文件

.gitignore：定义了IDE（IntelliJ IDEA、Eclipse等）生成的临时文件和输出目录的忽略规则
WebDemo.iml：IntelliJ IDEA项目配置文件，定义了模块类型、源码目录、依赖库等
web.xml：Web应用部署描述符，定义了Servlet规范版本

### 2.源码目录 (src/com/bookborrow/)

**Servlet包 (servlet/)：**
LoginServlet.java：用户登录处理，验证用户名密码并设置session
LogoutServlet.java：用户退出登录，销毁session
BorrowServlet.java：处理图书借阅业务，验证借阅上限和库存，插入借阅记录并更新库存
ReturnBookServlet.java：处理图书归还业务，更新借阅记录状态并增加图书库存，计算逾期罚金
RenewServlet.java：处理图书续借申请，验证续借条件并提交申请记录
FeedbackServlet.java：处理用户反馈评价，验证图书ID并提交反馈信息
EditProfileServlet.java：处理用户资料编辑，支持头像上传和用户信息更新
OverdueReminderServlet.java：处理逾期提醒，将到期未还图书状态更新为逾期
**管理员Servlet包 (servlet/admin/)：**
DeleteBookServlet.java：管理员删除图书功能，验证是否有未归还借阅记录
HandleRenewServlet.java：管理员处理续借申请，审批或拒绝用户续借请求
ToggleReserveServlet.java：管理员设置图书预约状态
ToggleHotServlet.java：管理员设置图书热门推荐状态
UpdateBookServlet.java：管理员更新图书信息
SendOverdueReminderServlet.java：管理员发送逾期提醒
工具包 (util/)：
DBUtil.java：数据库连接工具类，提供数据库连接池和连接获取方法

### 3.Web页面目录 (web/)

**根目录页面：**
index.jsp：网站首页，展示平台特色和功能介绍
login.jsp：用户登录页面
register.jsp：用户注册页面
**用户功能页面 (web/user/)：**
dashboard.jsp：用户个人中心主页，显示用户信息和借阅统计
book_list.jsp：图书浏览页面，显示可借阅图书列表和借阅按钮
borrow_list.jsp：借阅记录页面，显示用户借阅历史和归还按钮
feedback.jsp：反馈评价页面，允许用户对已归还图书进行评价
**管理员功能页面 (web/admin/)：**
dashboard.jsp：管理员仪表盘，显示系统统计信息
book_manage.jsp：图书管理页面，支持图书增删改查
borrow_manage.jsp：借阅管理页面，处理借阅审核和续借申请
statistics.jsp：数据统计页面，展示借阅趋势和热门图书分析
_navbar.jsp：管理员导航栏公共组件
**公共资源：**
images/：存放项目图片资源（头像、封面、背景等）
css/：样式文件
js/：JavaScript脚本文件

### 4.数据库设计

系统包含以下主要数据表：
rjgc_users：用户信息表（包含借阅上限、联系方式等）
rjgc_books：图书信息表（包含库存、分类、位置等）
rjgc_borrow_records：借阅记录表（包含借阅状态、日期等）
rjgc_renew_requests：续借申请表
rjgc_feedback：用户反馈表

### 5.项目功能特点

这是一个完整的图书借阅管理系统，支持：
用户管理：注册、登录、个人资料编辑
图书管理：图书浏览、借阅、归还、续借
管理员功能：图书管理、借阅审核、数据统计
逾期管理：自动逾期检测、罚金计算
反馈系统：用户评价和反馈收集

## 运行说明

### 环境要求：

1. **Java JDK 8+**
2. **Tomcat 9+**
3. **MySQL 5.7+**
4. **MySQL JDBC驱动**（mysql-connector-java-8.0.x.jar）

### 部署步骤：

1. 创建数据库并执行SQL脚本
2. 将项目文件放到Tomcat的`webapps/BookBorrowSystem`目录
3. 将MySQL驱动jar包放到`WEB-INF/lib/`目录
4. 修改`database.jsp`中的数据库连接信息
5. 启动Tomcat，访问`http://localhost:8080/BookBorrowSystem/`

### 测试账户：

- 管理员：admin / admin123
- 普通用户：reader1 / 123456



# 问题（还没解决）：

1.user/edit_profile.jsp没法实现更换头像

2.java程序user部分单独搞个文件夹

​	注意：这个java程序需要连接mysql的这个jar包需要单独下载，这个jar包相当于mysql的驱动要不然没法使用mysql

