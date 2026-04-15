package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class SysUser {
    private Long id;
    private String username;
    private String password;
    private String realName;
    private Integer userType;
    private Integer adminLevel;
    private Long regionId;
    private Integer status;
    private String createTime;
    private String updateTime;
}