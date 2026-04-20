/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80037 (8.0.37)
 Source Host           : localhost:3306
 Source Schema         : disabled_security_fund

 Target Server Type    : MySQL
 Target Server Version : 80037 (8.0.37)
 File Encoding         : 65001

 Date: 20/04/2026 09:06:21
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for calculation_rule
-- ----------------------------
DROP TABLE IF EXISTS `calculation_rule`;
CREATE TABLE `calculation_rule`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '规则名称',
  `apply_year` int NOT NULL COMMENT '适用年度',
  `required_ratio` decimal(5, 2) NOT NULL COMMENT '应安置比例（如1.5表示1.5%）',
  `formula_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '计算公式（JSON格式）',
  `is_active` tinyint NOT NULL COMMENT '是否启用：0-否，1-是',
  `effective_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '生效时间',
  `expire_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '失效时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_apply_year`(`apply_year` ASC) USING BTREE,
  INDEX `idx_is_active`(`is_active` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '应缴金额计算规则表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of calculation_rule
-- ----------------------------

-- ----------------------------
-- Table structure for company
-- ----------------------------
DROP TABLE IF EXISTS `company`;
CREATE TABLE `company`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `unified_social_credit_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '统一社会信用代码',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '单位全称',
  `region_id` bigint NOT NULL COMMENT '所属地区id，关联region.id',
  `legal_person` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '法人',
  `contact_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '联系电话',
  `industry` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '所属行业',
  `establish_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '成立日期',
  `address` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '注册地址',
  `employee_count` int NULL DEFAULT 0 COMMENT '在职职工总数',
  `status` tinyint NOT NULL COMMENT '状态：0-注销，1-正常',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_credit_code`(`unified_social_credit_code` ASC) USING BTREE,
  INDEX `idx_region_id`(`region_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  CONSTRAINT `fk_company_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of company
-- ----------------------------

-- ----------------------------
-- Table structure for company_disabled_employee
-- ----------------------------
DROP TABLE IF EXISTS `company_disabled_employee`;
CREATE TABLE `company_disabled_employee`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '残疾人职工姓名',
  `id_card` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '身份证号',
  `disability_cert_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '残疾证号',
  `disability_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '残疾类别',
  `disability_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '残疾等级',
  `job_position` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '入职时间',
  `is_active` tinyint NOT NULL COMMENT '是否在职：0-否，1-是',
  `audit_pass_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审核通过时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_id_card`(`id_card` ASC) USING BTREE,
  INDEX `idx_disability_cert_no`(`disability_cert_no` ASC) USING BTREE,
  CONSTRAINT `fk_disabled_employee_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位在职残疾人职工信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of company_disabled_employee
-- ----------------------------

-- ----------------------------
-- Table structure for company_employee
-- ----------------------------
DROP TABLE IF EXISTS `company_employee`;
CREATE TABLE `company_employee`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '职工姓名',
  `id_card` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '身份证号',
  `job_position` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '入职时间',
  `is_active` tinyint NOT NULL COMMENT '是否在职：0-否，1-是',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_id_card`(`id_card` ASC) USING BTREE,
  CONSTRAINT `fk_company_employee_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位普通职工信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of company_employee
-- ----------------------------

-- ----------------------------
-- Table structure for company_reduction
-- ----------------------------
DROP TABLE IF EXISTS `company_reduction`;
CREATE TABLE `company_reduction`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '申请年度',
  `apply_type` tinyint NOT NULL COMMENT '申请类型：1-减，2-免，3-缓',
  `apply_amount` decimal(12, 2) NULL DEFAULT NULL COMMENT '申请金额（减免时填写）',
  `reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '申请理由',
  `audit_status` tinyint NOT NULL COMMENT '审批状态：0-待审，1-通过，2-驳回',
  `auditor_id` bigint NULL DEFAULT NULL COMMENT '审批人id，关联sys_user.id',
  `audit_opinion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '审批意见',
  `audit_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审批时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_year`(`year` ASC) USING BTREE,
  INDEX `idx_audit_status`(`audit_status` ASC) USING BTREE,
  INDEX `idx_auditor_id`(`auditor_id` ASC) USING BTREE,
  CONSTRAINT `fk_reduction_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_reduction_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '减、免、缓交保障金申请/审批记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of company_reduction
-- ----------------------------

-- ----------------------------
-- Table structure for company_user
-- ----------------------------
DROP TABLE IF EXISTS `company_user`;
CREATE TABLE `company_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '所属单位id，关联company.id',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码（加密存储）',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '联系人姓名',
  `mobile` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '邮箱',
  `status` tinyint NOT NULL COMMENT '状态：0-禁用，1-启用',
  `last_login_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '最后登录时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  CONSTRAINT `fk_company_user_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位子账号表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of company_user
-- ----------------------------

-- ----------------------------
-- Table structure for data_backup
-- ----------------------------
DROP TABLE IF EXISTS `data_backup`;
CREATE TABLE `data_backup`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `backup_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '备份文件名',
  `backup_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '备份路径',
  `backup_size` int NULL DEFAULT NULL COMMENT '备份大小（KB）',
  `backup_type` tinyint NOT NULL COMMENT '备份类型：1-全量，2-增量',
  `operator_id` bigint NULL DEFAULT NULL COMMENT '操作人id，关联sys_user.id',
  `backup_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '备份时间',
  `restore_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '恢复时间',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_backup_time`(`backup_time` ASC) USING BTREE,
  INDEX `idx_operator_id`(`operator_id` ASC) USING BTREE,
  CONSTRAINT `fk_backup_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '数据备份记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of data_backup
-- ----------------------------

-- ----------------------------
-- Table structure for disabled_audit
-- ----------------------------
DROP TABLE IF EXISTS `disabled_audit`;
CREATE TABLE `disabled_audit`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '审核年度',
  `employee_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '残疾人职工姓名',
  `id_card` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '身份证号',
  `audit_status` tinyint NOT NULL COMMENT '审核状态：0-待审，1-通过，2-不通过',
  `auditor_id` bigint NULL DEFAULT NULL COMMENT '审核人id，关联sys_user.id',
  `audit_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_year`(`company_id` ASC, `year` ASC) USING BTREE,
  INDEX `idx_id_card`(`id_card` ASC) USING BTREE,
  INDEX `idx_audit_status`(`audit_status` ASC) USING BTREE,
  INDEX `idx_auditor_id`(`auditor_id` ASC) USING BTREE,
  CONSTRAINT `fk_audit_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_audit_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '残疾人职工审核记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of disabled_audit
-- ----------------------------

-- ----------------------------
-- Table structure for disabled_employee
-- ----------------------------
DROP TABLE IF EXISTS `disabled_employee`;
CREATE TABLE `disabled_employee`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `company_id` bigint NULL DEFAULT NULL COMMENT '单位ID',
  `company_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '单位名称',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '职工姓名',
  `id_card` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '身份证号',
  `disability_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '残疾类型',
  `disability_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '残疾等级',
  `hire_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '入职日期',
  `year` int NULL DEFAULT NULL COMMENT '年度',
  `status` tinyint NULL DEFAULT 0 COMMENT '状态：0-待审核, 1-已通过, 2-已驳回',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '残疾职工表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of disabled_employee
-- ----------------------------
INSERT INTO `disabled_employee` VALUES (1, 1, '广州科技发展有限公司', '李明', '440106199001011234', '肢体残疾', '三级', '2024-06-15', 2025, 0, '2026-04-18 20:27:28', '2026-04-18 20:27:28');
INSERT INTO `disabled_employee` VALUES (2, 2, '白云制造有限公司', '王芳', '440106198805122345', '听力残疾', '二级', '2024-09-01', 2025, 0, '2026-04-18 20:27:28', '2026-04-18 20:27:28');

-- ----------------------------
-- Table structure for employee_registration
-- ----------------------------
DROP TABLE IF EXISTS `employee_registration`;
CREATE TABLE `employee_registration`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '年度',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '职工姓名',
  `id_card` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '身份证号',
  `is_disabled` tinyint NOT NULL COMMENT '是否残疾：0-否，1-是',
  `disability_cert_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '残疾证号（is_disabled=1时必填）',
  `job_position` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '入职时间',
  `status` tinyint NOT NULL COMMENT '登记状态：0-待审核，1-审核通过，2-审核不通过',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_year`(`company_id` ASC, `year` ASC) USING BTREE,
  INDEX `idx_id_card`(`id_card` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  CONSTRAINT `fk_registration_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位职工登记表（年度申报）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of employee_registration
-- ----------------------------

-- ----------------------------
-- Table structure for external_data_import
-- ----------------------------
DROP TABLE IF EXISTS `external_data_import`;
CREATE TABLE `external_data_import`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `source` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '数据来源：财政局、税务局、中国人民银行',
  `import_type` tinyint NOT NULL COMMENT '导入类型：1-Excel导入，2-API接口同步',
  `file_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '文件名（Excel导入时记录）',
  `api_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '接口地址（API同步时记录）',
  `record_count` int NOT NULL COMMENT '导入记录数',
  `status` tinyint NOT NULL COMMENT '导入状态：0-进行中，1-成功，2-失败，3-部分成功',
  `error_msg` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '错误信息（失败时记录）',
  `operator_id` bigint NULL DEFAULT NULL COMMENT '操作人id，关联sys_user.id',
  `import_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '导入时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_source`(`source` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_import_time`(`import_time` ASC) USING BTREE,
  INDEX `idx_operator_id`(`operator_id` ASC) USING BTREE,
  CONSTRAINT `fk_import_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '外部数据导入记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of external_data_import
-- ----------------------------

-- ----------------------------
-- Table structure for fund_usage
-- ----------------------------
DROP TABLE IF EXISTS `fund_usage`;
CREATE TABLE `fund_usage`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `project_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '支出项目名称',
  `amount` decimal(12, 2) NOT NULL COMMENT '金额',
  `usage_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '支出日期',
  `region_id` bigint NOT NULL COMMENT '使用地区id，关联region.id',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '用途说明',
  `audit_status` tinyint NOT NULL COMMENT '审批状态：0-待审，1-已通过，2-已驳回',
  `auditor_id` bigint NULL DEFAULT NULL COMMENT '审批人id，关联sys_user.id',
  `audit_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审批时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_region_id`(`region_id` ASC) USING BTREE,
  INDEX `idx_usage_date`(`usage_date` ASC) USING BTREE,
  INDEX `idx_audit_status`(`audit_status` ASC) USING BTREE,
  INDEX `idx_auditor_id`(`auditor_id` ASC) USING BTREE,
  CONSTRAINT `fk_fund_usage_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_fund_usage_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '残保金支出项目及用途表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fund_usage
-- ----------------------------

-- ----------------------------
-- Table structure for notice
-- ----------------------------
DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '目标单位id，关联company.id',
  `notice_type` tinyint NOT NULL COMMENT '通知单类型：1-缴款通知书，2-征收决定书，3-催缴提醒函，4-数据核对通知',
  `notice_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '通知书编号（唯一）',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '通知单内容（最终打印版）',
  `print_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '打印时间',
  `print_count` int NOT NULL DEFAULT 0 COMMENT '打印次数',
  `send_status` tinyint NULL DEFAULT 0 COMMENT '送达状态：0-未送达，1-已送达，2-退回',
  `operator_id` bigint NOT NULL COMMENT '操作人id，关联sys_user.id',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_notice_number`(`notice_number` ASC) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_notice_type`(`notice_type` ASC) USING BTREE,
  INDEX `idx_send_status`(`send_status` ASC) USING BTREE,
  INDEX `idx_operator_id`(`operator_id` ASC) USING BTREE,
  CONSTRAINT `fk_notice_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_notice_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '通知单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of notice
-- ----------------------------

-- ----------------------------
-- Table structure for operation_log
-- ----------------------------
DROP TABLE IF EXISTS `operation_log`;
CREATE TABLE `operation_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `user_id` bigint NOT NULL COMMENT '操作人id，关联sys_user.id（单位操作可关联company_user.id，此处设计为可空，兼容）',
  `operation_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作类型：增、删、改、查、导出、登录等',
  `target_table` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '操作表名',
  `target_id` bigint NULL DEFAULT NULL COMMENT '操作记录id',
  `detail` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '变更详情（JSON格式）',
  `ip_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '客户端IP',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE,
  INDEX `idx_operation_type`(`operation_type` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 41 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '操作日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of operation_log
-- ----------------------------
INSERT INTO `operation_log` VALUES (1, 1, '创建系统用户', 'sys_user', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 12:59:06');
INSERT INTO `operation_log` VALUES (2, 1, '创建系统用户', 'sys_user', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 13:25:28');
INSERT INTO `operation_log` VALUES (3, 1, '创建系统用户', 'sys_user', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 13:25:40');
INSERT INTO `operation_log` VALUES (4, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:09');
INSERT INTO `operation_log` VALUES (5, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:10');
INSERT INTO `operation_log` VALUES (6, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:11');
INSERT INTO `operation_log` VALUES (7, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:12');
INSERT INTO `operation_log` VALUES (8, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:13');
INSERT INTO `operation_log` VALUES (9, 1, '切换角色状态', 'role', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 13:40:55');
INSERT INTO `operation_log` VALUES (10, 1, '更新角色', 'role', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 13:50:32');
INSERT INTO `operation_log` VALUES (11, 1, '更新角色', 'role', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 13:50:38');
INSERT INTO `operation_log` VALUES (12, 1, '更新角色', 'role', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:26:51');
INSERT INTO `operation_log` VALUES (13, 1, '重置用户密码', 'sys_user', 3, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:27:17');
INSERT INTO `operation_log` VALUES (14, 1, '重置用户密码', 'sys_user', 1, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:27:25');
INSERT INTO `operation_log` VALUES (15, 1, '删除系统用户', 'sys_user', 2, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:27:29');
INSERT INTO `operation_log` VALUES (16, 1, '删除系统用户', 'sys_user', 3, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:27:37');
INSERT INTO `operation_log` VALUES (17, 1, '创建系统用户', 'sys_user', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:27:52');
INSERT INTO `operation_log` VALUES (18, 1, '重置用户密码', 'sys_user', 4, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:36:24');
INSERT INTO `operation_log` VALUES (19, 1, '重置用户密码', 'sys_user', 1, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:36:27');
INSERT INTO `operation_log` VALUES (20, 1, '切换用户状态', 'sys_user', 4, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:37:13');
INSERT INTO `operation_log` VALUES (21, 1, '切换用户状态', 'sys_user', 4, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:37:14');
INSERT INTO `operation_log` VALUES (22, 1, '切换用户状态', 'sys_user', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:37:19');
INSERT INTO `operation_log` VALUES (23, 1, '切换用户状态', 'sys_user', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:37:20');
INSERT INTO `operation_log` VALUES (24, 1, '创建系统用户', 'sys_user', NULL, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:45:43');
INSERT INTO `operation_log` VALUES (25, 1, '重置用户密码', 'sys_user', 4, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:45:47');
INSERT INTO `operation_log` VALUES (26, 1, '删除系统用户', 'sys_user', 4, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:46:28');
INSERT INTO `operation_log` VALUES (27, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:46:29');
INSERT INTO `operation_log` VALUES (28, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 14:48:34');
INSERT INTO `operation_log` VALUES (29, 1, '切换用户状态', 'sys_user', 5, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:49:07');
INSERT INTO `operation_log` VALUES (30, 1, '切换用户状态', 'sys_user', 1, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:49:19');
INSERT INTO `operation_log` VALUES (31, 1, '切换用户状态', 'sys_user', 5, '{\"argsCount\":2,\"success\":false}', '127.0.0.1', '2026-04-19 14:54:09');
INSERT INTO `operation_log` VALUES (32, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:03:16');
INSERT INTO `operation_log` VALUES (33, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:03:16');
INSERT INTO `operation_log` VALUES (34, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:03:20');
INSERT INTO `operation_log` VALUES (35, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:04:34');
INSERT INTO `operation_log` VALUES (36, 1, '重置用户密码', 'sys_user', 1, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:11:54');
INSERT INTO `operation_log` VALUES (37, 1, '重置用户密码', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:11:56');
INSERT INTO `operation_log` VALUES (38, 1, '删除系统用户', 'sys_user', 5, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 15:37:28');
INSERT INTO `operation_log` VALUES (39, 1, '重置用户密码', 'sys_user', 1, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 16:02:13');
INSERT INTO `operation_log` VALUES (40, 1, '删除系统用户', 'sys_user', 1, '{\"argsCount\":1,\"success\":false}', '127.0.0.1', '2026-04-19 16:44:51');

-- ----------------------------
-- Table structure for payable_amount
-- ----------------------------
DROP TABLE IF EXISTS `payable_amount`;
CREATE TABLE `payable_amount`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '所属年份',
  `total_employee_count` int NOT NULL COMMENT '在职职工总数',
  `disabled_employee_count` int NOT NULL COMMENT '已安置残疾人职工数（审核通过）',
  `required_ratio` decimal(5, 2) NOT NULL COMMENT '应安置比例',
  `calculated_amount` decimal(12, 2) NOT NULL COMMENT '系统核算应缴金额',
  `reduction_amount` decimal(12, 2) NULL DEFAULT 0.00 COMMENT '减免金额',
  `payable_amount` decimal(12, 2) GENERATED ALWAYS AS ((`calculated_amount` - `reduction_amount`)) STORED COMMENT '实际应缴金额' NULL,
  `paid_amount` decimal(12, 2) NULL DEFAULT 0.00 COMMENT '已缴金额',
  `payment_status` tinyint NULL DEFAULT 0 COMMENT '缴费状态：0-未缴，1-部分缴，2-已缴',
  `status` tinyint NOT NULL COMMENT '状态：0-待确认，1-已确认',
  `confirm_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '确认时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_year`(`company_id` ASC, `year` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_payment_status`(`payment_status` ASC) USING BTREE,
  CONSTRAINT `fk_payable_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '单位年度应缴保障金表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of payable_amount
-- ----------------------------

-- ----------------------------
-- Table structure for payment_record
-- ----------------------------
DROP TABLE IF EXISTS `payment_record`;
CREATE TABLE `payment_record`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `payable_id` bigint NOT NULL COMMENT '应缴记录id，关联payable_amount.id',
  `actual_amount` decimal(12, 2) NOT NULL COMMENT '实际缴纳金额',
  `payment_date` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '缴款日期',
  `voucher_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '缴款凭证号',
  `remark` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '核销备注',
  `source` tinyint NOT NULL COMMENT '数据来源：1-税务接口，2-人工核销',
  `confirm_user_id` bigint NULL DEFAULT NULL COMMENT '核销操作人id，关联sys_user.id',
  `status` tinyint NOT NULL COMMENT '核销状态：0-待核销，1-已核销，2-异常',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_payable_id`(`payable_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_confirm_user`(`confirm_user_id` ASC) USING BTREE,
  INDEX `idx_voucher_no`(`voucher_no` ASC) USING BTREE,
  CONSTRAINT `fk_payment_confirm_user` FOREIGN KEY (`confirm_user_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_payment_payable` FOREIGN KEY (`payable_id`) REFERENCES `payable_amount` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '缴款核销记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of payment_record
-- ----------------------------

-- ----------------------------
-- Table structure for reduction_application
-- ----------------------------
DROP TABLE IF EXISTS `reduction_application`;
CREATE TABLE `reduction_application`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `company_id` bigint NULL DEFAULT NULL COMMENT '单位ID',
  `company_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '单位名称',
  `reduction_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '申请类型：减免/缓缴',
  `apply_year` int NULL DEFAULT NULL COMMENT '申请年度',
  `apply_amount` decimal(12, 2) NULL DEFAULT NULL COMMENT '申请金额',
  `apply_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '申请理由',
  `attachment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '附件路径',
  `status` tinyint NULL DEFAULT 0 COMMENT '状态：0-待审核, 1-已通过, 2-已驳回',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_company_id`(`company_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '减免缓申请表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of reduction_application
-- ----------------------------
INSERT INTO `reduction_application` VALUES (1, 2, '白云制造有限公司', '减免', 2025, 60000.00, '因经营困难申请减免，已上传财务报表', NULL, 0, '2026-04-18 20:27:28', '2026-04-18 20:27:28');
INSERT INTO `reduction_application` VALUES (2, 4, '天河建设集团', '缓缴', 2025, 80000.00, '由于项目延期回款，公司短期资金周转困难，申请缓缴残保金6个月。', NULL, 0, '2026-04-18 20:27:28', '2026-04-18 20:27:28');

-- ----------------------------
-- Table structure for region
-- ----------------------------
DROP TABLE IF EXISTS `region`;
CREATE TABLE `region`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '地区名称',
  `code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '地区代码（行政区划代码）',
  `level` tinyint NOT NULL COMMENT '级别：1-市级，2-区县级',
  `parent_id` bigint NOT NULL COMMENT '上级地区id，市级为0',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_level`(`level` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '地区表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of region
-- ----------------------------
INSERT INTO `region` VALUES (1, '锦江区', '510104', 2, 1);
INSERT INTO `region` VALUES (2, '青羊区', '510105', 2, 1);
INSERT INTO `region` VALUES (3, '金牛区', '510106', 2, 1);
INSERT INTO `region` VALUES (4, '武侯区', '510107', 2, 1);
INSERT INTO `region` VALUES (5, '成华区', '510108', 2, 1);
INSERT INTO `region` VALUES (6, '龙泉驿区', '510112', 2, 1);
INSERT INTO `region` VALUES (7, '青白江区', '510113', 2, 1);
INSERT INTO `region` VALUES (8, '新都区', '510114', 2, 1);
INSERT INTO `region` VALUES (9, '温江区', '510115', 2, 1);
INSERT INTO `region` VALUES (10, '双流区', '510116', 2, 1);
INSERT INTO `region` VALUES (11, '郫都区', '510117', 2, 1);
INSERT INTO `region` VALUES (12, '新津区', '510118', 2, 1);
INSERT INTO `region` VALUES (13, '金堂县', '510121', 2, 1);
INSERT INTO `region` VALUES (14, '大邑县', '510129', 2, 1);
INSERT INTO `region` VALUES (15, '蒲江县', '510131', 2, 1);
INSERT INTO `region` VALUES (16, '都江堰市', '510181', 2, 1);
INSERT INTO `region` VALUES (17, '彭州市', '510182', 2, 1);
INSERT INTO `region` VALUES (18, '邛崃市', '510183', 2, 1);
INSERT INTO `region` VALUES (19, '崇州市', '510184', 2, 1);
INSERT INTO `region` VALUES (20, '简阳市', '510185', 2, 1);

-- ----------------------------
-- Table structure for role
-- ----------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色名称',
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色标识',
  `role_type` tinyint NOT NULL COMMENT '角色类型：1-管理员，2-领导，3-单位',
  `data_scope` tinyint NOT NULL COMMENT '数据范围：1-全市，2-本区县，3-本单位',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_role_code`(`role_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of role
-- ----------------------------
INSERT INTO `role` VALUES (1, '系统管理员', 'admin_system', 1, 1, 1, '拥有所有权限', NULL, '2026-04-19 14:26:51');
INSERT INTO `role` VALUES (2, '市级管理员', 'CITY_ADMIN', 1, 2, 1, '市级残联管理员，管理本市范围内所有区级数据和审批', '2026-04-19 14:12:43', '2026-04-19 14:12:43');
INSERT INTO `role` VALUES (3, '区级管理员', 'DISTRICT_ADMIN', 1, 3, 1, '区级残联管理员，管理本区范围内单位信息、征收核算、通知单等', '2026-04-19 14:12:43', '2026-04-19 14:12:43');
INSERT INTO `role` VALUES (4, '市级领导', 'CITY_LEADER', 2, 2, 1, '市级残联领导，查看全市统计报表、资金使用情况', '2026-04-19 14:12:43', '2026-04-19 14:12:43');
INSERT INTO `role` VALUES (5, '区级领导', 'DISTRICT_LEADER', 2, 3, 1, '区级残联领导，查看本区统计报表、资金使用情况', '2026-04-19 14:12:43', '2026-04-19 14:12:43');
INSERT INTO `role` VALUES (6, '单位用户', 'UNIT', 3, 4, 1, '用人单位负责人，申报本单位残疾人信息、缴纳保障金', '2026-04-19 14:12:43', '2026-04-19 14:12:43');
INSERT INTO `role` VALUES (7, '系统管理员', 'SYSTEM_ADMIN', 1, 3, 1, '系统管理员，拥有所有权限', '2026-04-19 17:21:26', '2026-04-19 17:21:26');

-- ----------------------------
-- Table structure for sys_user
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码（加密存储）',
  `real_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '真实姓名',
  `user_type` tinyint NOT NULL COMMENT '用户类型：1-管理员，2-领导',
  `admin_level` tinyint NULL DEFAULT NULL COMMENT '管理员级别：1-系统管理员，2-市级管理员，3-区县管理员（仅user_type=1时有效）',
  `region_id` bigint NULL DEFAULT NULL COMMENT '管辖地区id，关联region.id',
  `status` tinyint NOT NULL COMMENT '状态：0-禁用，1-启用',
  `last_login_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '最后登录时间',
  `create_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE,
  INDEX `idx_region_id`(`region_id` ASC) USING BTREE,
  INDEX `idx_user_type`(`user_type` ASC) USING BTREE,
  CONSTRAINT `fk_sys_user_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统用户表（管理员、领导）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', '系统管理员', 1, 1, NULL, 1, NULL, '2026-04-19 16:40:00', '2026-04-19 21:33:21');

-- ----------------------------
-- Table structure for user_role
-- ----------------------------
DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '鐢ㄦ埛ID',
  `role_id` bigint NOT NULL COMMENT '瑙掕壊ID',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '鐢ㄦ埛瑙掕壊鍏宠仈琛' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_role
-- ----------------------------
INSERT INTO `user_role` VALUES (1, 1, 7, '2026-04-19 17:28:38');

SET FOREIGN_KEY_CHECKS = 1;
