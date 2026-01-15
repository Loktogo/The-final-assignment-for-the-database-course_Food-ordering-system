/*
 Navicat Premium Dump SQL

 Source Server         : food_ordering_system
 Source Server Type    : MySQL
 Source Server Version : 80043 (8.0.43)
 Source Host           : localhost:3306
 Source Schema         : campus_ordering

 Target Server Type    : MySQL
 Target Server Version : 80043 (8.0.43)
 File Encoding         : 65001

 Date: 15/01/2026 18:19:02
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for dishes
-- ----------------------------
DROP TABLE IF EXISTS `dishes`;
CREATE TABLE `dishes`  (
  `dish_id` int NOT NULL AUTO_INCREMENT,
  `shop_id` int NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '菜名',
  `price` decimal(10, 2) NOT NULL COMMENT '价格',
  `sales_volume` int NULL DEFAULT 0 COMMENT '销量',
  `is_available` tinyint(1) NULL DEFAULT 1 COMMENT '1上架, 0下架',
  PRIMARY KEY (`dish_id`) USING BTREE,
  INDEX `fk_dish_shop`(`shop_id` ASC) USING BTREE,
  CONSTRAINT `fk_dish_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`shop_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '菜品表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of dishes
-- ----------------------------
INSERT INTO `dishes` VALUES (1, 1, '孜然土豆包菜饭', 14.00, 201, 1);
INSERT INTO `dishes` VALUES (2, 1, '洋葱炒牛肉饭', 18.00, 122, 1);
INSERT INTO `dishes` VALUES (3, 2, '自选打卤面', 12.00, 200, 1);
INSERT INTO `dishes` VALUES (4, 2, '自选米饭', 12.00, 150, 1);
INSERT INTO `dishes` VALUES (5, 2, '牛腩面', 18.00, 500, 1);
INSERT INTO `dishes` VALUES (6, 2, '肉酱面', 15.00, 800, 1);
INSERT INTO `dishes` VALUES (7, 3, '原味鸡汤米线', 16.00, 300, 1);
INSERT INTO `dishes` VALUES (8, 3, '番茄肥牛米线', 20.00, 121, 1);
INSERT INTO `dishes` VALUES (9, 3, '土豆泥肉酱拌米线', 17.00, 600, 1);
INSERT INTO `dishes` VALUES (10, 3, '小酥肉米线', 15.00, 80, 1);

-- ----------------------------
-- Table structure for order_items
-- ----------------------------
DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items`  (
  `item_id` bigint NOT NULL AUTO_INCREMENT,
  `order_id` bigint NOT NULL,
  `dish_id` int NOT NULL,
  `quantity` int NOT NULL COMMENT '购买数量',
  `price_snapshot` decimal(10, 2) NOT NULL COMMENT '下单时单价',
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `fk_item_order`(`order_id` ASC) USING BTREE,
  INDEX `fk_item_dish`(`dish_id` ASC) USING BTREE,
  CONSTRAINT `fk_item_dish` FOREIGN KEY (`dish_id`) REFERENCES `dishes` (`dish_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '订单详情表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of order_items
-- ----------------------------
INSERT INTO `order_items` VALUES (1, 1, 1, 1, 14.00);
INSERT INTO `order_items` VALUES (2, 2, 2, 1, 18.00);
INSERT INTO `order_items` VALUES (3, 3, 2, 1, 18.00);
INSERT INTO `order_items` VALUES (4, 4, 8, 1, 20.00);

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders`  (
  `order_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '下单用户',
  `shop_id` int NOT NULL COMMENT '目标店铺',
  `courier_id` int NULL DEFAULT NULL COMMENT '配送员ID',
  `total_amount` decimal(10, 2) NOT NULL COMMENT '总金额',
  `status` int NULL DEFAULT 0 COMMENT '0未发货, 1配送中, 2已完成, 4已取消',
  `address_snapshot` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '地址快照',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`) USING BTREE,
  INDEX `fk_order_user`(`user_id` ASC) USING BTREE,
  INDEX `fk_order_shop`(`shop_id` ASC) USING BTREE,
  INDEX `fk_order_courier`(`courier_id` ASC) USING BTREE,
  CONSTRAINT `fk_order_courier` FOREIGN KEY (`courier_id`) REFERENCES `sys_users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_order_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`shop_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '订单主表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of orders
-- ----------------------------
INSERT INTO `orders` VALUES (1, 1, 1, 2, 14.00, 2, '默认宿舍地址', '2026-01-14 15:56:07');
INSERT INTO `orders` VALUES (2, 1, 1, 2, 18.00, 2, '默认宿舍地址', '2026-01-14 17:34:18');
INSERT INTO `orders` VALUES (3, 1, 1, 2, 18.00, 2, '东园五栋', '2026-01-14 17:46:10');
INSERT INTO `orders` VALUES (4, 1, 3, 2, 20.00, 2, '东园五栋', '2026-01-15 04:42:44');

-- ----------------------------
-- Table structure for shops
-- ----------------------------
DROP TABLE IF EXISTS `shops`;
CREATE TABLE `shops`  (
  `shop_id` int NOT NULL AUTO_INCREMENT,
  `owner_id` int NOT NULL COMMENT '关联商家用户ID',
  `shop_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '店铺名称',
  `location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '店铺位置',
  `status` tinyint(1) NULL DEFAULT 1 COMMENT '1营业, 0休息',
  PRIMARY KEY (`shop_id`) USING BTREE,
  INDEX `fk_shop_owner`(`owner_id` ASC) USING BTREE,
  CONSTRAINT `fk_shop_owner` FOREIGN KEY (`owner_id`) REFERENCES `sys_users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '店铺表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of shops
-- ----------------------------
INSERT INTO `shops` VALUES (1, 3, '湘小悦', '东饭三楼201档口', 1);
INSERT INTO `shops` VALUES (2, 4, '一凡打卤面', '西园食堂一楼101', 1);
INSERT INTO `shops` VALUES (3, 5, '蒙自源', '东园食堂二楼205', 1);

-- ----------------------------
-- Table structure for sys_users
-- ----------------------------
DROP TABLE IF EXISTS `sys_users`;
CREATE TABLE `sys_users`  (
  `user_id` int NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '电话',
  `address` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '收货地址(消费者用)',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色: consumer/merchant/courier',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '昵称/真实姓名',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户综合表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_users
-- ----------------------------
INSERT INTO `sys_users` VALUES (1, 'student', '123456', '19512345678', '东园五栋', 'consumer', '2026-01-14 15:33:22', '小明');
INSERT INTO `sys_users` VALUES (2, 'rider', '123456', '13987654321', NULL, 'courier', '2026-01-14 15:33:22', '闪电');
INSERT INTO `sys_users` VALUES (3, 'boss', '123456', '13700137000', NULL, 'merchant', '2026-01-14 15:33:22', '富贵');
INSERT INTO `sys_users` VALUES (4, 'boss1', '123456', '13623041051', NULL, 'merchant', '2026-01-14 20:31:50', '一凡打卤面');
INSERT INTO `sys_users` VALUES (5, 'boss2', '123456', '18087960152', NULL, 'merchant', '2026-01-14 20:31:50', '蒙自源');

-- ----------------------------
-- View structure for v_order_details
-- ----------------------------
DROP VIEW IF EXISTS `v_order_details`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `v_order_details` AS select `o`.`order_id` AS `order_id`,`o`.`user_id` AS `user_id`,`u_customer`.`nickname` AS `customer_nickname`,`s`.`shop_name` AS `shop_name`,`s`.`location` AS `shop_address`,`o`.`courier_id` AS `courier_id`,`u_courier`.`nickname` AS `courier_nickname`,`u_courier`.`phone` AS `courier_phone`,`d`.`name` AS `dish_name`,`o`.`total_amount` AS `total_amount`,`o`.`status` AS `status`,(case `o`.`status` when 0 then '待发货' when 1 then '配送中' when 2 then '已完成' when 4 then '已取消' else '未知' end) AS `status_text`,`o`.`address_snapshot` AS `user_address`,`o`.`create_time` AS `create_time` from (((((`orders` `o` join `shops` `s` on((`o`.`shop_id` = `s`.`shop_id`))) join `order_items` `oi` on((`o`.`order_id` = `oi`.`order_id`))) join `dishes` `d` on((`oi`.`dish_id` = `d`.`dish_id`))) join `sys_users` `u_customer` on((`o`.`user_id` = `u_customer`.`user_id`))) left join `sys_users` `u_courier` on((`o`.`courier_id` = `u_courier`.`user_id`)));

-- ----------------------------
-- Triggers structure for table order_items
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_add_sales`;
delimiter ;;
CREATE TRIGGER `trg_add_sales` AFTER INSERT ON `order_items` FOR EACH ROW BEGIN
    UPDATE `dishes` 
    SET `sales_volume` = `sales_volume` + NEW.quantity
    WHERE `dish_id` = NEW.dish_id;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table order_items
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_rollback_sales`;
delimiter ;;
CREATE TRIGGER `trg_rollback_sales` AFTER DELETE ON `order_items` FOR EACH ROW BEGIN
    UPDATE `dishes` 
    SET `sales_volume` = `sales_volume` - OLD.quantity
    WHERE `dish_id` = OLD.dish_id;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
