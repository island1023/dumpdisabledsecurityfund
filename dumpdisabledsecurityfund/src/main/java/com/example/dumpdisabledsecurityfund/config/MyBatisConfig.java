package com.example.dumpdisabledsecurityfund.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@MapperScan("com.example.dumpdisabledsecurityfund.mapper")
@EnableTransactionManagement
public class MyBatisConfig {
}