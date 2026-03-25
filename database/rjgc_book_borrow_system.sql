/*
 Navicat Premium Dump SQL

 Source Server         : rjgc
 Source Server Type    : MySQL
 Source Server Version : 90300 (9.3.0)
 Source Host           : localhost:3306
 Source Schema         : rjgc_book_borrow_system

 Target Server Type    : MySQL
 Target Server Version : 90300 (9.3.0)
 File Encoding         : 65001

 Date: 25/12/2025 22:04:50
*/
-- 1. 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS `rjgc_book_borrow_system` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. 选中该数据库
USE `rjgc_book_borrow_system`;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for rjgc_books
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_books`;
CREATE TABLE `rjgc_books`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '图书唯一标识ID',
  `isbn` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '国际标准书号ISBN',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '图书名称',
  `author` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '图书作者',
  `publisher` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '出版社名称',
  `publish_date` date NULL DEFAULT NULL COMMENT '出版日期',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '图书分类',
  `total_copies` int NULL DEFAULT 1 COMMENT '图书馆拥有的总副本数',
  `available_copies` int NULL DEFAULT 1 COMMENT '当前可借阅的副本数',
  `location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '图书存放位置（如：A区3排2架）',
  `is_hot` tinyint(1) NULL DEFAULT 0 COMMENT '是否热门推荐图书(1=是, 0=否)',
  `is_reserved` tinyint(1) NOT NULL DEFAULT 0,
  `reserved_until` date NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '图书录入时间',
  `cover_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '../images/default-book.jpg' COMMENT '图书封面URL',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `isbn`(`isbn` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '图书信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_books
-- ----------------------------
INSERT INTO `rjgc_books` VALUES (1, '9787111421900', '深入理解Java虚拟机', '周志明', '机械工业出版社', '2013-06-01', '计算机', 5, 2, '计算机区-A排3架', 1, 0, NULL, '2025-12-24 09:55:03', '../images/jvm-book.jpg');
INSERT INTO `rjgc_books` VALUES (2, '9787544253994', '百年孤独', '加西亚·马尔克斯', '南海出版公司', '2011-06-01', '文学', 3, 4, '文学区-B排1架', 1, 0, NULL, '2025-12-24 09:55:03', '../images/bngl-book.jpg');
INSERT INTO `rjgc_books` VALUES (3, '9787115428028', 'Python编程：从入门到实践', 'Eric Matthes', '人民邮电出版社', '2016-07-01', '计算机', 4, 3, '计算机区-A排2架', 0, 0, NULL, '2025-12-24 09:55:03', '../images/python-book.jpg');
INSERT INTO `rjgc_books` VALUES (4, '9787020024759', '围城', '钱钟书', '人民文学出版社', '1991-02-01', '文学', 2, 10, '文学区-B排3架', 1, 0, NULL, '2025-12-24 09:55:03', '../images/weicheng.jpg');
INSERT INTO `rjgc_books` VALUES (5, '9787108041531', '明朝那些事儿', '当年明月', '北京联合出版公司', '2009-04-01', '历史', 3, 3, '历史区-C排1架', 1, 0, NULL, '2025-12-24 09:55:03', '../images/mcnxs.jpg');
INSERT INTO `rjgc_books` VALUES (7, '978-7-111-26350-4', 'Java编程思想', 'Bruce Eckel', NULL, NULL, NULL, 5, 5, NULL, 1, 0, NULL, '2025-12-24 17:40:42', '../images/java.jpg');
INSERT INTO `rjgc_books` VALUES (8, '978-7-115-28033-9', 'Spring实战', 'Craig Walls', NULL, NULL, NULL, 3, 3, NULL, 0, 0, NULL, '2025-12-24 17:40:42', '../images/spring.jpg');
INSERT INTO `rjgc_books` VALUES (9, '978-7-115-30853-4', '深入理解Java虚拟机', '周志明', '', NULL, '计算机', 4, 4, '', 0, 0, NULL, '2025-12-24 17:40:42', '../images/javaxnj.jpg');
INSERT INTO `rjgc_books` VALUES (20, '99999', '111', 'phy', 'imkk', '2025-12-25', '文学', 3, 1, 'A排9架', 0, 0, NULL, '2025-12-25 12:30:35', '../images/default-book.jpg');

-- ----------------------------
-- Table structure for rjgc_borrow_records
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_borrow_records`;
CREATE TABLE `rjgc_borrow_records`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `book_id` int NOT NULL,
  `apply_date` date NULL DEFAULT NULL,
  `borrow_date` date NULL DEFAULT NULL,
  `due_date` date NULL DEFAULT NULL,
  `return_date` date NULL DEFAULT NULL,
  `status` enum('待审核','借阅中','已归还','逾期') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '待审核',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `renew_fee` decimal(10, 2) NULL DEFAULT 0.00,
  `renew_count` int NULL DEFAULT 0 COMMENT '续借次数',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `book_id`(`book_id` ASC) USING BTREE,
  CONSTRAINT `rjgc_borrow_records_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `rjgc_users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `rjgc_borrow_records_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `rjgc_books` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_borrow_records
-- ----------------------------
INSERT INTO `rjgc_borrow_records` VALUES (1, 1, 1, NULL, '2025-01-01', '2025-02-01', NULL, '逾期', '2025-12-24 19:13:10', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (2, 1, 2, NULL, '2025-01-15', '2025-02-15', NULL, '已归还', '2025-12-24 19:13:10', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (3, 1, 1, NULL, '2025-01-01', '2025-02-01', NULL, '借阅中', '2025-12-24 19:13:56', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (4, 1, 2, NULL, '2025-01-15', '2025-02-15', NULL, '已归还', '2025-12-24 19:13:56', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (5, 5, 3, '2025-12-24', NULL, NULL, NULL, '待审核', '2025-12-24 19:37:22', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (6, 5, 4, '2025-12-24', '2025-12-24', '2026-01-23', '2025-12-24', '已归还', '2025-12-24 19:58:52', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (7, 10, 2, '2025-12-24', '2025-12-24', '2026-01-23', '2025-12-24', '已归还', '2025-12-24 20:09:03', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (8, 5, 3, '2025-12-24', '2025-12-24', '2026-01-20', NULL, '借阅中', '2025-12-24 20:28:18', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (9, 2, 2, '2025-12-24', '2025-12-24', '2026-01-23', '2025-12-24', '已归还', '2025-12-24 21:45:10', 0.00, 0);
INSERT INTO `rjgc_borrow_records` VALUES (10, 5, 1, '2025-12-24', '2025-12-24', '2026-01-23', NULL, '借阅中', '2025-12-24 21:45:52', 0.00, 0);

-- ----------------------------
-- Table structure for rjgc_borrow_requests
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_borrow_requests`;
CREATE TABLE `rjgc_borrow_requests`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `book_id` int NOT NULL,
  `request_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('PENDING','APPROVED','REJECTED','CANCELLED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `review_date` timestamp NULL DEFAULT NULL,
  `reviewer_id` int NULL DEFAULT NULL,
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_req_status`(`status` ASC) USING BTREE,
  INDEX `idx_req_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_req_book`(`book_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_borrow_requests
-- ----------------------------

-- ----------------------------
-- Table structure for rjgc_feedbacks
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_feedbacks`;
CREATE TABLE `rjgc_feedbacks`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `book_id` int NOT NULL,
  `rating` int NULL DEFAULT NULL,
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `submit_date` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `book_id`(`book_id` ASC) USING BTREE,
  CONSTRAINT `rjgc_feedbacks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `rjgc_users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `rjgc_feedbacks_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `rjgc_books` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `rjgc_feedbacks_chk_1` CHECK ((`rating` >= 1) and (`rating` <= 5))
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_feedbacks
-- ----------------------------
INSERT INTO `rjgc_feedbacks` VALUES (1, 1, 1, 5, '这本书非常精彩，内容深入浅出，强烈推荐！', '2025-01-10 09:00:00', NULL);
INSERT INTO `rjgc_feedbacks` VALUES (2, 5, 4, 5, '666', '2025-12-24 20:27:36', NULL);
INSERT INTO `rjgc_feedbacks` VALUES (3, 2, 2, 5, '77777777', '2025-12-24 21:45:28', NULL);

-- ----------------------------
-- Table structure for rjgc_notifications
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_notifications`;
CREATE TABLE `rjgc_notifications`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `notification_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `is_read` tinyint(1) NULL DEFAULT 0,
  `related_record_id` int NULL DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  CONSTRAINT `rjgc_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `rjgc_users` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_notifications
-- ----------------------------
INSERT INTO `rjgc_notifications` VALUES (1, 1, NULL, '图书借阅提醒', '您有一本图书即将到期，请及时归还', 0, NULL, '2025-01-20 10:00:00');
INSERT INTO `rjgc_notifications` VALUES (2, 1, NULL, '新书推荐', '我们为您推荐了新的热门图书', 1, NULL, '2025-01-18 15:30:00');
INSERT INTO `rjgc_notifications` VALUES (3, 1, NULL, '图书借阅提醒', '您有一本图书即将到期，请及时归还', 0, NULL, '2025-01-20 10:00:00');
INSERT INTO `rjgc_notifications` VALUES (4, 1, NULL, '新书推荐', '我们为您推荐了新的热门图书', 1, NULL, '2025-01-18 15:30:00');
INSERT INTO `rjgc_notifications` VALUES (5, 5, '书籍归还', '书籍归还成功', '您已成功归还书籍，请注意查收。', 0, 6, '2025-12-24 19:59:55');
INSERT INTO `rjgc_notifications` VALUES (6, 10, '书籍归还', '书籍归还成功', '您已成功归还书籍，请注意查收。', 0, 7, '2025-12-24 20:09:09');
INSERT INTO `rjgc_notifications` VALUES (7, 2, '书籍归还', '书籍归还成功', '您已成功归还书籍，请注意查收。', 0, 9, '2025-12-24 21:45:22');
INSERT INTO `rjgc_notifications` VALUES (8, 1, 'OVERDUE_REMINDER', '逾期提醒', '您借阅的《深入理解Java虚拟机》已逾期（应还日期：2025-02-01），请尽快归还或申请续借。', 0, 1, '2025-12-25 13:06:52');
INSERT INTO `rjgc_notifications` VALUES (9, 1, 'OVERDUE_REMINDER', '逾期提醒', '您借阅的《深入理解Java虚拟机》已逾期（应还日期：2025-02-01），请尽快归还或申请续借。', 0, 1, '2025-12-25 15:25:53');

-- ----------------------------
-- Table structure for rjgc_renew_requests
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_renew_requests`;
CREATE TABLE `rjgc_renew_requests`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `borrow_id` int NOT NULL,
  `request_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('PENDING','APPROVED','REJECTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `processed_date` timestamp NULL DEFAULT NULL,
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_renew_status`(`status` ASC) USING BTREE,
  INDEX `idx_renew_borrow`(`borrow_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_renew_requests
-- ----------------------------

-- ----------------------------
-- Table structure for rjgc_users
-- ----------------------------
DROP TABLE IF EXISTS `rjgc_users`;
CREATE TABLE `rjgc_users`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名（登录账号）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '登录密码（加密存储）',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户邮箱地址',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户手机号码',
  `user_type` enum('user','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'user' COMMENT '用户类型(user=普通用户, admin=管理员)',
  `emergency_contact` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '紧急联系人信息',
  `borrow_limit` int NULL DEFAULT 5 COMMENT '最大借阅数量限制',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  `avatar_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统用户表（包含读者和管理员）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of rjgc_users
-- ----------------------------
INSERT INTO `rjgc_users` VALUES (1, 'admin', 'admin123', 'admin@example.com', '13800138000', 'admin', '王先生 13800138001', 999, '2025-12-24 09:55:03', '/images/avatars/mr.jpg');
INSERT INTO `rjgc_users` VALUES (2, '张三', 'zhangsan123', 'zhangsan@example.com', '13800138002', 'user', '李女士 13800138003', 5, '2025-12-24 09:55:03', '/images/avatars/mr.jpg');
INSERT INTO `rjgc_users` VALUES (3, '李四', 'lisi123', 'lisi@example.com', '13800138004', 'user', '王先生 13800138005', 5, '2025-12-24 09:55:03', '/images/avatars/mr.jpg');
INSERT INTO `rjgc_users` VALUES (4, '王五', 'wangwu123', 'wangwu@example.com', '13800138006', 'user', '赵女士 13800138007', 3, '2025-12-24 09:55:03', '/images/avatars/mr.jpg');
INSERT INTO `rjgc_users` VALUES (5, 'phy', '1', '3491762752@qq.com', '16643793969', 'user', '18865568887', 5, '2025-12-24 15:32:06', '/images/avatars/phy.jpg');
INSERT INTO `rjgc_users` VALUES (8, 'user1', 'user123', 'user1@example.com', NULL, 'user', NULL, 5, '2025-12-24 19:04:38', '/images/avatars/mr.jpg');
INSERT INTO `rjgc_users` VALUES (10, '1', '1', '111@11', NULL, 'user', '1', 5, '2025-12-24 20:08:34', NULL);

-- ----------------------------
-- View structure for rjgc_view_popular_books
-- ----------------------------
DROP VIEW IF EXISTS `rjgc_view_popular_books`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `rjgc_view_popular_books` AS select `b`.`id` AS `图书ID`,`b`.`isbn` AS `ISBN号`,`b`.`title` AS `图书名称`,`b`.`author` AS `作者`,`b`.`category` AS `分类`,`b`.`available_copies` AS `可借数量`,`b`.`is_hot` AS `是否热门`,count(`br`.`id`) AS `借阅次数`,ifnull(avg(`f`.`rating`),0) AS `平均评分` from ((`rjgc_books` `b` left join `rjgc_borrow_records` `br` on((`b`.`id` = `br`.`book_id`))) left join `rjgc_feedbacks` `f` on((`b`.`id` = `f`.`book_id`))) where (`b`.`is_hot` = true) group by `b`.`id`,`b`.`isbn`,`b`.`title`,`b`.`author`,`b`.`category`,`b`.`available_copies`,`b`.`is_hot` order by `借阅次数` desc,`平均评分` desc;

-- ----------------------------
-- Procedure structure for rjgc_proc_renew_book
-- ----------------------------
DROP PROCEDURE IF EXISTS `rjgc_proc_renew_book`;
delimiter ;;
CREATE PROCEDURE `rjgc_proc_renew_book`(IN p_record_id INT,        -- 借阅记录ID
    IN p_user_id INT,          -- 用户ID
    IN p_extension_days INT)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_current_renew_count INT;
    DECLARE v_max_renew_count INT DEFAULT 2;  -- 最大续借次数
    
    -- 获取当前状态和续借次数
    SELECT status, renew_count INTO v_current_status, v_current_renew_count
    FROM rjgc_borrow_records 
    WHERE id = p_record_id AND user_id = p_user_id;
    
    -- 检查记录是否存在
    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '借阅记录不存在或不属于该用户';
    END IF;
    
    -- 检查是否可以续借
    IF v_current_status != '借阅中' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '只有"借阅中"的图书可以续借';
    END IF;
    
    -- 检查续借次数
    IF v_current_renew_count >= v_max_renew_count THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '已达到最大续借次数';
    END IF;
    
    -- 执行续借操作
    UPDATE rjgc_borrow_records 
    SET 
        due_date = DATE_ADD(due_date, INTERVAL p_extension_days DAY),
        renew_count = renew_count + 1,
        status = '借阅中'
    WHERE id = p_record_id;
    
    -- 记录系统日志
    INSERT INTO rjgc_system_logs (operator_id, operation_type, operation_description, target_table, target_record_id)
    VALUES (p_user_id, '续借图书', CONCAT('续借图书，延长', p_extension_days, '天'), 'rjgc_borrow_records', p_record_id);
    
    SELECT '续借成功' AS result;
    
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
