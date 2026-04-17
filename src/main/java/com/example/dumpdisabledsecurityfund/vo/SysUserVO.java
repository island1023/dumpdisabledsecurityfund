package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class SysUserVO {
    private Long id;
    private String username;
    private String realName;
    private Integer userType;
    private String userTypeName;
    private Integer adminLevel;
    private String adminLevelName;
    private Long regionId;
    private String regionName;
    private Integer status;
    private String statusName;
    private String createTime;
    private String updateTime;
}
