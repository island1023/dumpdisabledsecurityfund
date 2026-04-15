package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.service.RegionService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

@Service
public class RegionServiceImpl implements RegionService {
    @Resource
    private RegionMapper regionMapper;

    @Override
    public Result<?> list() {
        return Result.success(regionMapper.selectAll());
    }
}
