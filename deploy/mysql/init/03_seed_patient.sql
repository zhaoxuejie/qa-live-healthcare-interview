-- =============================================================
-- 03_seed_patient.sql —— 演示患者账号（供登录演示/测试）
-- 用户名 demo_patient / 密码 123456（BCrypt 哈希）
-- =============================================================

SET NAMES utf8mb4;

USE qa_healthcare;

INSERT IGNORE INTO patient (username, password_hash, name, birthday, phone, gender)
VALUES ('demo_patient', '$2a$10$X7Q4HJ4.BxRe8EPesc8Yp.BWp9DP127DMT7TmvQHddAUkbOI1IrSG', '演示患者', '1990-01-01', NULL, '女');