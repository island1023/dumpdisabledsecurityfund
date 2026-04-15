package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class CompanyUser {
    private Long id;
    private Long companyId;
    private String username;
    private String password;
    private String name;
    private String mobile;
    private String email;
    private Integer status;
    private String lastLoginTime;
    private String createTime;
    private String updateTime;
}