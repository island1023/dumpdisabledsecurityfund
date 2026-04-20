package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class NoticeDetailVO {
    private Long id;
    private Long companyId;
    private String companyName;
    private Integer noticeType;
    private String noticeTypeName;
    private String noticeNumber;
    private String content;
    private String printTime;
    private Integer printCount;
    private Integer sendStatus;
    private String sendStatusName;
    private Long operatorId;
    private String operatorName;
}
