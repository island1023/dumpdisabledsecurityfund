package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class Region {
    private Long id;
    private String name;
    private Integer level;
    private Long parentId;
}