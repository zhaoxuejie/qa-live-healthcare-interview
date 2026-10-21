-- =============================================================
-- 01_schema.sql —— QA Live Healthcare 初始化表结构
-- 由 docker compose 首次初始化（数据卷为空）时自动执行
-- 字符集统一 utf8mb4，排序规则 utf8mb4_unicode_ci
-- =============================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS qa_healthcare
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE qa_healthcare;

-- -------------------------------------------------------------
-- 医生表：对应前端 Doctor 模型（不含明文密码返回，仅库内保留演示密码）
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor (
  id          VARCHAR(32)  NOT NULL COMMENT '医生ID，如 doc001',
  username    VARCHAR(64)  NOT NULL COMMENT '登录用户名，全局唯一',
  password    VARCHAR(100) NOT NULL COMMENT '演示用密码（接口不返回）',
  name        VARCHAR(64)  NOT NULL COMMENT '姓名',
  title       VARCHAR(64)  NOT NULL COMMENT '职称',
  department  VARCHAR(64)  NOT NULL COMMENT '科室',
  avatar      VARCHAR(512) NOT NULL DEFAULT '' COMMENT '头像URL',
  experience  VARCHAR(128) NOT NULL DEFAULT '' COMMENT '从业经验描述',
  specialties JSON         NOT NULL COMMENT '擅长领域，JSON 数组',
  is_active   TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否在诊室开放',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_doctor_username (username),
  KEY idx_doctor_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='医生';

-- -------------------------------------------------------------
-- 患者表：需求 3（用户名密码登录）使用
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username      VARCHAR(64)  NOT NULL COMMENT '登录用户名，全局唯一',
  password_hash VARCHAR(100) NOT NULL COMMENT 'BCrypt 哈希，禁止明文',
  name          VARCHAR(64)  NOT NULL COMMENT '姓名',
  birthday      DATE         NULL COMMENT '生日',
  phone         VARCHAR(32)  NULL COMMENT '手机号',
  gender        VARCHAR(16)  NULL COMMENT '性别',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_patient_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='患者';

-- -------------------------------------------------------------
-- 患者登录令牌：不透明 token，服务端存储，默认 7 天有效
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_token (
  token      VARCHAR(64)    NOT NULL COMMENT '不透明令牌',
  patient_id BIGINT UNSIGNED NOT NULL COMMENT '所属患者',
  expires_at DATETIME       NOT NULL COMMENT '过期时间',
  created_at DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (token),
  KEY idx_patient_token_patient (patient_id),
  CONSTRAINT fk_patient_token_patient
    FOREIGN KEY (patient_id) REFERENCES patient (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='患者登录令牌';
