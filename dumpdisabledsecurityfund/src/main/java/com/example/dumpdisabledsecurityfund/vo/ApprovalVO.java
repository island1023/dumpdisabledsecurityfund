package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class ApprovalVO {
    private Long id;
    private String companyName;
    private String applyType;
    private String applyDate;
    private String status;
    private Integer disabledCount;
    private String amount;
    private String description;
    
    // 残疾职工详情
    private String employeeName;
    private String idCard;
    private String disabilityType;
    private String disabilityLevel;
    private String hireDate;
    private String attachmentName;
    
    // 减免缓详情
    private String reductionType;
    private String applyYear;
    private String applyAmount;
    private String applyReason;
    private String reductionAttachment;
}
