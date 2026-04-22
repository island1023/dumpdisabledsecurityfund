package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class Notice {
    private Long id; // Primary key
    private Long companyId; // Foreign key to the company table
    private Long unitId; // Unit ID
    private Integer year; // Year of the notice
    private Integer noticeType; // Type of the notice
    private String noticeNumber; // Unique notice number
    private String content; // Content of the notice
    private String type; // Notice type (e.g., payment or decision)
    private String status; // Status of the notice
    private String printTime; // Time when the notice was printed
    private Integer printCount; // Number of times the notice was printed
    private Integer sendStatus; // Status of sending the notice
    private Long operatorId; // ID of the operator who created/modified the notice
    private Long createTime; // Timestamp of creation
}