package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class LoginVO {
    private Long userId;
    private String username;
    private String name;
    private Long companyId;
    private String token;
}