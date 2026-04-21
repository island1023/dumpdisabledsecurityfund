package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

import java.io.Serializable;

@Data
public class CompanyUser implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private Long companyId;
    private String username;
    private String password;
    private String name;
    private String mobile;
    private String email;
    private Integer status;
    private String createTime;
    private String updateTime;
}
