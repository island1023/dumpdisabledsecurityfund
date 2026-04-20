package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class ExternalDataImport {
    private Long id;
    private String source;
    private Integer importType;
    private String fileName;
    private String apiUrl;
    private Integer recordCount;
    private Integer status;
    private String errorMsg;
    private Long operatorId;
    private String importTime;
    private String createTime;
}