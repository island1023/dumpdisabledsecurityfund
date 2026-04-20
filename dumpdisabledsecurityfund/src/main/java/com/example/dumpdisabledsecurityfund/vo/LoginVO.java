package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class LoginVO {
    private String token;
    private UserInfo user;
    
    @Data
    public static class UserInfo {
        private String id;
        private String username;
        private String realName;
        private String role;
        private String roleName;
        private String districtCode;
        private String districtName;
        private String status;
        private String createTime;
        private String lastLoginTime;
    }
}