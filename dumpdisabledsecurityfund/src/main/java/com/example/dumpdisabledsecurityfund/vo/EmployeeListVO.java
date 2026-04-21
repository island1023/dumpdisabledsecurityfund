package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class EmployeeListVO {
    private Long id;
    private String name;
    private String idCard;
    private String jobPosition;
    private String entryDate;
    private Integer isActive;
    private String isActiveName;
    private String createTime;
}
