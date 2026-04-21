package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class NoticeVO {
    private Long id;
    private String companyName;
    private Integer noticeType;
    private String noticeTypeName;
    private String noticeNumber;
    private String content;
    private String printTime;
    private Integer printCount;
}