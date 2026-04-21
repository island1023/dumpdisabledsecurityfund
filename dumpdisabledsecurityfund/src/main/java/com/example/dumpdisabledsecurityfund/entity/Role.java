package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class Role {
    private Long id;
    private String roleName;
    private String roleCode;
    private Integer roleType;
    private Integer dataScope;
    private Integer status; // 0-禁用，1-启用
    private String remark;
    private String createTime;
    private String updateTime;
}