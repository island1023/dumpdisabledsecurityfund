package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

/**
 * 领导端统计报表外部平台同步数据（本地落库模拟）
 */
@Data
public class LeaderExternalReport {
    private Long id;
    private String reportType;
    private Integer statYear;
    private Integer statMonth;
    private Integer sortOrder;
    private String payloadJson;
}
