-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: disabled_security_fund
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `calculation_rule`
--

DROP TABLE IF EXISTS `calculation_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `calculation_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `apply_year` int NOT NULL COMMENT '适用年度',
  `required_ratio` decimal(5,2) NOT NULL COMMENT '应安置比例（如1.5表示1.5%）',
  `formula_json` text NOT NULL COMMENT '计算公式（JSON格式）',
  `is_active` tinyint NOT NULL COMMENT '是否启用：0-否，1-是',
  `effective_time` varchar(20) NOT NULL COMMENT '生效时间',
  `expire_time` varchar(20) DEFAULT NULL COMMENT '失效时间',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_apply_year` (`apply_year`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='应缴金额计算规则表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `calculation_rule`
--

LOCK TABLES `calculation_rule` WRITE;
/*!40000 ALTER TABLE `calculation_rule` DISABLE KEYS */;
/*!40000 ALTER TABLE `calculation_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `unified_social_credit_code` varchar(50) NOT NULL COMMENT '统一社会信用代码',
  `name` varchar(200) NOT NULL COMMENT '单位全称',
  `region_id` bigint NOT NULL COMMENT '所属地区id，关联region.id',
  `legal_person` varchar(100) DEFAULT NULL COMMENT '法人',
  `contact_phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `status` tinyint NOT NULL COMMENT '状态：0-注销，1-正常',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_credit_code` (`unified_social_credit_code`),
  KEY `idx_region_id` (`region_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_company_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company`
--

LOCK TABLES `company` WRITE;
/*!40000 ALTER TABLE `company` DISABLE KEYS */;
/*!40000 ALTER TABLE `company` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_disabled_employee`
--

DROP TABLE IF EXISTS `company_disabled_employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_disabled_employee` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `name` varchar(100) NOT NULL COMMENT '残疾人职工姓名',
  `id_card` varchar(18) NOT NULL COMMENT '身份证号',
  `disability_cert_no` varchar(50) NOT NULL COMMENT '残疾证号',
  `disability_type` varchar(50) DEFAULT NULL COMMENT '残疾类别',
  `disability_level` varchar(20) DEFAULT NULL COMMENT '残疾等级',
  `job_position` varchar(100) DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) DEFAULT NULL COMMENT '入职时间',
  `is_active` tinyint NOT NULL COMMENT '是否在职：0-否，1-是',
  `audit_pass_time` varchar(20) DEFAULT NULL COMMENT '审核通过时间',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_id_card` (`id_card`),
  KEY `idx_disability_cert_no` (`disability_cert_no`),
  CONSTRAINT `fk_disabled_employee_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位在职残疾人职工信息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_disabled_employee`
--

LOCK TABLES `company_disabled_employee` WRITE;
/*!40000 ALTER TABLE `company_disabled_employee` DISABLE KEYS */;
/*!40000 ALTER TABLE `company_disabled_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_employee`
--

DROP TABLE IF EXISTS `company_employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_employee` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `name` varchar(100) NOT NULL COMMENT '职工姓名',
  `id_card` varchar(18) NOT NULL COMMENT '身份证号',
  `job_position` varchar(100) DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) DEFAULT NULL COMMENT '入职时间',
  `is_active` tinyint NOT NULL COMMENT '是否在职：0-否，1-是',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_id_card` (`id_card`),
  CONSTRAINT `fk_company_employee_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位普通职工信息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_employee`
--

LOCK TABLES `company_employee` WRITE;
/*!40000 ALTER TABLE `company_employee` DISABLE KEYS */;
/*!40000 ALTER TABLE `company_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_reduction`
--

DROP TABLE IF EXISTS `company_reduction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_reduction` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '申请年度',
  `apply_type` tinyint NOT NULL COMMENT '申请类型：1-减，2-免，3-缓',
  `apply_amount` decimal(12,2) DEFAULT NULL COMMENT '申请金额（减免时填写）',
  `reason` text NOT NULL COMMENT '申请理由',
  `audit_status` tinyint NOT NULL COMMENT '审批状态：0-待审，1-通过，2-驳回',
  `auditor_id` bigint DEFAULT NULL COMMENT '审批人id，关联sys_user.id',
  `audit_opinion` text COMMENT '审批意见',
  `audit_time` varchar(20) DEFAULT NULL COMMENT '审批时间',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_year` (`year`),
  KEY `idx_audit_status` (`audit_status`),
  KEY `idx_auditor_id` (`auditor_id`),
  CONSTRAINT `fk_reduction_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reduction_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='减、免、缓交保障金申请/审批记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_reduction`
--

LOCK TABLES `company_reduction` WRITE;
/*!40000 ALTER TABLE `company_reduction` DISABLE KEYS */;
/*!40000 ALTER TABLE `company_reduction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_user`
--

DROP TABLE IF EXISTS `company_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '所属单位id，关联company.id',
  `username` varchar(50) NOT NULL COMMENT '登录账号',
  `password` varchar(255) NOT NULL COMMENT '密码（加密存储）',
  `name` varchar(100) NOT NULL COMMENT '联系人姓名',
  `mobile` varchar(20) DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `status` tinyint NOT NULL COMMENT '状态：0-禁用，1-启用',
  `last_login_time` varchar(20) DEFAULT NULL COMMENT '最后登录时间',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_company_user_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位子账号表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_user`
--

LOCK TABLES `company_user` WRITE;
/*!40000 ALTER TABLE `company_user` DISABLE KEYS */;
/*!40000 ALTER TABLE `company_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_backup`
--

DROP TABLE IF EXISTS `data_backup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_backup` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `backup_name` varchar(200) NOT NULL COMMENT '备份文件名',
  `backup_path` varchar(500) NOT NULL COMMENT '备份路径',
  `backup_size` int DEFAULT NULL COMMENT '备份大小（KB）',
  `backup_type` tinyint NOT NULL COMMENT '备份类型：1-全量，2-增量',
  `operator_id` bigint DEFAULT NULL COMMENT '操作人id，关联sys_user.id',
  `backup_time` varchar(20) NOT NULL COMMENT '备份时间',
  `restore_time` varchar(20) DEFAULT NULL COMMENT '恢复时间',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_backup_time` (`backup_time`),
  KEY `idx_operator_id` (`operator_id`),
  CONSTRAINT `fk_backup_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='数据备份记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_backup`
--

LOCK TABLES `data_backup` WRITE;
/*!40000 ALTER TABLE `data_backup` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_backup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `disabled_audit`
--

DROP TABLE IF EXISTS `disabled_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `disabled_audit` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '审核年度',
  `employee_name` varchar(100) NOT NULL COMMENT '残疾人职工姓名',
  `id_card` varchar(18) NOT NULL COMMENT '身份证号',
  `audit_status` tinyint NOT NULL COMMENT '审核状态：0-待审，1-通过，2-不通过',
  `auditor_id` bigint DEFAULT NULL COMMENT '审核人id，关联sys_user.id',
  `audit_time` varchar(20) DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_year` (`company_id`,`year`),
  KEY `idx_id_card` (`id_card`),
  KEY `idx_audit_status` (`audit_status`),
  KEY `idx_auditor_id` (`auditor_id`),
  CONSTRAINT `fk_audit_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_audit_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='残疾人职工审核记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `disabled_audit`
--

LOCK TABLES `disabled_audit` WRITE;
/*!40000 ALTER TABLE `disabled_audit` DISABLE KEYS */;
/*!40000 ALTER TABLE `disabled_audit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee_registration`
--

DROP TABLE IF EXISTS `employee_registration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_registration` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '年度',
  `name` varchar(100) NOT NULL COMMENT '职工姓名',
  `id_card` varchar(18) NOT NULL COMMENT '身份证号',
  `is_disabled` tinyint NOT NULL COMMENT '是否残疾：0-否，1-是',
  `disability_cert_no` varchar(50) DEFAULT NULL COMMENT '残疾证号（is_disabled=1时必填）',
  `job_position` varchar(100) DEFAULT NULL COMMENT '工作岗位',
  `entry_date` varchar(20) DEFAULT NULL COMMENT '入职时间',
  `status` tinyint NOT NULL COMMENT '登记状态：0-待审核，1-审核通过，2-审核不通过',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_year` (`company_id`,`year`),
  KEY `idx_id_card` (`id_card`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_registration_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位职工登记表（年度申报）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee_registration`
--

LOCK TABLES `employee_registration` WRITE;
/*!40000 ALTER TABLE `employee_registration` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee_registration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `external_data_import`
--

DROP TABLE IF EXISTS `external_data_import`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `external_data_import` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `source` varchar(50) NOT NULL COMMENT '数据来源：财政局、税务局、中国人民银行',
  `import_type` tinyint NOT NULL COMMENT '导入类型：1-Excel导入，2-API接口同步',
  `file_name` varchar(200) DEFAULT NULL COMMENT '文件名（Excel导入时记录）',
  `api_url` varchar(500) DEFAULT NULL COMMENT '接口地址（API同步时记录）',
  `record_count` int NOT NULL COMMENT '导入记录数',
  `status` tinyint NOT NULL COMMENT '导入状态：0-进行中，1-成功，2-失败，3-部分成功',
  `error_msg` text COMMENT '错误信息（失败时记录）',
  `operator_id` bigint DEFAULT NULL COMMENT '操作人id，关联sys_user.id',
  `import_time` varchar(20) NOT NULL COMMENT '导入时间',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_source` (`source`),
  KEY `idx_status` (`status`),
  KEY `idx_import_time` (`import_time`),
  KEY `idx_operator_id` (`operator_id`),
  CONSTRAINT `fk_import_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='外部数据导入记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `external_data_import`
--

LOCK TABLES `external_data_import` WRITE;
/*!40000 ALTER TABLE `external_data_import` DISABLE KEYS */;
/*!40000 ALTER TABLE `external_data_import` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fund_usage`
--

DROP TABLE IF EXISTS `fund_usage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fund_usage` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `project_name` varchar(200) NOT NULL COMMENT '支出项目名称',
  `amount` decimal(12,2) NOT NULL COMMENT '金额',
  `usage_date` varchar(20) NOT NULL COMMENT '支出日期',
  `region_id` bigint NOT NULL COMMENT '使用地区id，关联region.id',
  `description` text COMMENT '用途说明',
  `audit_status` tinyint NOT NULL COMMENT '审批状态：0-待审，1-已通过，2-已驳回',
  `auditor_id` bigint DEFAULT NULL COMMENT '审批人id，关联sys_user.id',
  `audit_time` varchar(20) DEFAULT NULL COMMENT '审批时间',
  PRIMARY KEY (`id`),
  KEY `idx_region_id` (`region_id`),
  KEY `idx_usage_date` (`usage_date`),
  KEY `idx_audit_status` (`audit_status`),
  KEY `idx_auditor_id` (`auditor_id`),
  CONSTRAINT `fk_fund_usage_auditor` FOREIGN KEY (`auditor_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_fund_usage_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='残保金支出项目及用途表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fund_usage`
--

LOCK TABLES `fund_usage` WRITE;
/*!40000 ALTER TABLE `fund_usage` DISABLE KEYS */;
/*!40000 ALTER TABLE `fund_usage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notice`
--

DROP TABLE IF EXISTS `notice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notice` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '目标单位id，关联company.id',
  `notice_type` tinyint NOT NULL COMMENT '通知单类型：1-缴款通知书，2-征收决定书，3-催缴提醒函，4-数据核对通知',
  `notice_number` varchar(50) NOT NULL COMMENT '通知书编号（唯一）',
  `content` text NOT NULL COMMENT '通知单内容（最终打印版）',
  `print_time` varchar(20) NOT NULL COMMENT '打印时间',
  `print_count` int NOT NULL DEFAULT '0' COMMENT '打印次数',
  `send_status` tinyint DEFAULT '0' COMMENT '送达状态：0-未送达，1-已送达，2-退回',
  `operator_id` bigint NOT NULL COMMENT '操作人id，关联sys_user.id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notice_number` (`notice_number`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_notice_type` (`notice_type`),
  KEY `idx_send_status` (`send_status`),
  KEY `idx_operator_id` (`operator_id`),
  CONSTRAINT `fk_notice_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_notice_operator` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='通知单表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notice`
--

LOCK TABLES `notice` WRITE;
/*!40000 ALTER TABLE `notice` DISABLE KEYS */;
/*!40000 ALTER TABLE `notice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_log`
--

DROP TABLE IF EXISTS `operation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `user_id` bigint NOT NULL COMMENT '操作人id，关联sys_user.id（单位操作可关联company_user.id，此处设计为可空，兼容）',
  `operation_type` varchar(50) NOT NULL COMMENT '操作类型：增、删、改、查、导出、登录等',
  `target_table` varchar(100) DEFAULT NULL COMMENT '操作表名',
  `target_id` bigint DEFAULT NULL COMMENT '操作记录id',
  `detail` text COMMENT '变更详情（JSON格式）',
  `ip_address` varchar(50) DEFAULT NULL COMMENT '客户端IP',
  `create_time` varchar(20) NOT NULL COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_operation_type` (`operation_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='操作日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_log`
--

LOCK TABLES `operation_log` WRITE;
/*!40000 ALTER TABLE `operation_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payable_amount`
--

DROP TABLE IF EXISTS `payable_amount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payable_amount` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `company_id` bigint NOT NULL COMMENT '单位id，关联company.id',
  `year` int NOT NULL COMMENT '所属年份',
  `total_employee_count` int NOT NULL COMMENT '在职职工总数',
  `disabled_employee_count` int NOT NULL COMMENT '已安置残疾人职工数（审核通过）',
  `required_ratio` decimal(5,2) NOT NULL COMMENT '应安置比例',
  `calculated_amount` decimal(12,2) NOT NULL COMMENT '系统核算应缴金额',
  `status` tinyint NOT NULL COMMENT '状态：0-待确认，1-已确认',
  `confirm_time` varchar(20) DEFAULT NULL COMMENT '确认时间',
  PRIMARY KEY (`id`),
  KEY `idx_company_year` (`company_id`,`year`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_payable_company` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='单位年度应缴保障金表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payable_amount`
--

LOCK TABLES `payable_amount` WRITE;
/*!40000 ALTER TABLE `payable_amount` DISABLE KEYS */;
/*!40000 ALTER TABLE `payable_amount` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment_record`
--

DROP TABLE IF EXISTS `payment_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `payable_id` bigint NOT NULL COMMENT '应缴记录id，关联payable_amount.id',
  `actual_amount` decimal(12,2) NOT NULL COMMENT '实际缴纳金额',
  `payment_date` varchar(20) NOT NULL COMMENT '缴款日期',
  `source` tinyint NOT NULL COMMENT '数据来源：1-税务接口，2-人工核销',
  `confirm_user_id` bigint DEFAULT NULL COMMENT '核销操作人id，关联sys_user.id',
  `status` tinyint NOT NULL COMMENT '核销状态：0-待核销，1-已核销，2-异常',
  PRIMARY KEY (`id`),
  KEY `idx_payable_id` (`payable_id`),
  KEY `idx_status` (`status`),
  KEY `idx_confirm_user` (`confirm_user_id`),
  CONSTRAINT `fk_payment_confirm_user` FOREIGN KEY (`confirm_user_id`) REFERENCES `sys_user` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payment_payable` FOREIGN KEY (`payable_id`) REFERENCES `payable_amount` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='缴款核销记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_record`
--

LOCK TABLES `payment_record` WRITE;
/*!40000 ALTER TABLE `payment_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `payment_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `region`
--

DROP TABLE IF EXISTS `region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `region` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `name` varchar(100) NOT NULL COMMENT '地区名称',
  `level` tinyint NOT NULL COMMENT '级别：1-市级，2-区县级',
  `parent_id` bigint NOT NULL COMMENT '上级地区id，市级为0',
  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='地区表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `region`
--

LOCK TABLES `region` WRITE;
/*!40000 ALTER TABLE `region` DISABLE KEYS */;
/*!40000 ALTER TABLE `region` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `role_name` varchar(50) NOT NULL COMMENT '角色名称',
  `role_code` varchar(50) NOT NULL COMMENT '角色标识',
  `role_type` tinyint NOT NULL COMMENT '角色类型：1-管理员，2-领导，3-单位',
  `data_scope` tinyint NOT NULL COMMENT '数据范围：1-全市，2-本区县，3-本单位',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_code` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role`
--

LOCK TABLES `role` WRITE;
/*!40000 ALTER TABLE `role` DISABLE KEYS */;
INSERT INTO `role` VALUES (1,'系统管理员','admin_system',1,1,'拥有所有权限',NULL,NULL);
/*!40000 ALTER TABLE `role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_user`
--

DROP TABLE IF EXISTS `sys_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `username` varchar(50) NOT NULL COMMENT '登录账号',
  `password` varchar(255) NOT NULL COMMENT '密码（加密存储）',
  `real_name` varchar(100) NOT NULL COMMENT '真实姓名',
  `user_type` tinyint NOT NULL COMMENT '用户类型：1-管理员，2-领导',
  `admin_level` tinyint DEFAULT NULL COMMENT '管理员级别：1-系统管理员，2-市级管理员，3-区县管理员（仅user_type=1时有效）',
  `region_id` bigint DEFAULT NULL COMMENT '管辖地区id，关联region.id',
  `status` tinyint NOT NULL COMMENT '状态：0-禁用，1-启用',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` varchar(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_region_id` (`region_id`),
  KEY `idx_user_type` (`user_type`),
  CONSTRAINT `fk_sys_user_region` FOREIGN KEY (`region_id`) REFERENCES `region` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统用户表（管理员、领导）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user`
--

LOCK TABLES `sys_user` WRITE;
/*!40000 ALTER TABLE `sys_user` DISABLE KEYS */;
INSERT INTO `sys_user` VALUES (1,'admin','123456','系统管理员',1,1,NULL,1,'2026-04-14 15:55:21',NULL);
/*!40000 ALTER TABLE `sys_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键自增id',
  `user_id` bigint NOT NULL COMMENT '用户id，关联sys_user.id',
  `role_id` bigint NOT NULL COMMENT '角色id，关联role.id',
  `create_time` varchar(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_role` (`user_id`,`role_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_role_id` (`role_id`),
  CONSTRAINT `fk_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户-角色关联表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_role`
--

LOCK TABLES `user_role` WRITE;
/*!40000 ALTER TABLE `user_role` DISABLE KEYS */;
INSERT INTO `user_role` VALUES (1,1,1,'2026-04-14 15:55:21');
/*!40000 ALTER TABLE `user_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'disabled_security_fund'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-14 15:57:26
