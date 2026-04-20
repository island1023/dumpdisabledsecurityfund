package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class UserRole {
    private Long id;
    private Long userId;
    private Long roleId;
    private String createTime;
}