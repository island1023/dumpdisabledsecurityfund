package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class DataBackup {
    private Long id;
    private String backupName;
    private String backupPath;
    private Integer backupSize;
    private Integer backupType;
    private Long operatorId;
    private String backupTime;
    private String restoreTime;
    private String remark;
}