package com.example.dumpdisabledsecurityfund.common;

import lombok.Data;
import java.util.List;

@Data
public class PageResult<T> {
    private long total;
    private int pageNum;
    private int pageSize;
    private int pages;
    private List<T> list;

    public static <T> PageResult<T> build(long total, int pageNum, int pageSize, List<T> list) {
        PageResult<T> pageResult = new PageResult<>();
        pageResult.setTotal(total);
        pageResult.setPageNum(pageNum);
        pageResult.setPageSize(pageSize);
        pageResult.setList(list);
        pageResult.setPages((int) Math.ceil((double) total / pageSize));
        return pageResult;
    }
}
