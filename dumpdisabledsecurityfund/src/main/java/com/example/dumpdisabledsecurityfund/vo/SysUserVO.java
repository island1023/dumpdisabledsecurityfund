package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class SysUserVO {
    private String id;
    private String username;
    private String realName;
    private String role;
    private String roleName;
    private String districtCode;
    private String districtName;
    private String status;
    private String createTime;
    private String updateTime;
}
