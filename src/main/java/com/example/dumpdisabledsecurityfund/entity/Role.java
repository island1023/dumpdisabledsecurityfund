package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class Role {
    private Long id;
    private String roleName;
    private String roleCode;
    private Integer roleType;
    private Integer dataScope;
    private String remark;
    private String createTime;
    private String updateTime;
}