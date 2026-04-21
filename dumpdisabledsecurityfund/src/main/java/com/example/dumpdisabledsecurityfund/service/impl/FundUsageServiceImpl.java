package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.FundUsage;
import com.example.dumpdisabledsecurityfund.entity.Region;
import com.example.dumpdisabledsecurityfund.mapper.FundUsageMapper;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.service.FundUsageService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.vo.FundUsageVO;
import jakarta.annotation.Resource;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

@Service
public class FundUsageServiceImpl implements FundUsageService {
    @Resource
    private FundUsageMapper fundUsageMapper;
    @Resource
    private RegionMapper regionMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入资金使用记录", table = "fund_usage")
    public Result<?> importExcel(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            for (List<String> row : list) {
                if (row.size() < 4) {
                    continue;
                }
                FundUsage fu = new FundUsage();
                fu.setProjectName(row.get(0));
                fu.setAmount(Double.parseDouble(row.get(1)));
                fu.setUsageDate(row.get(2));
                fu.setRegionId(Long.parseLong(row.get(3)));
                fu.setAuditStatus(0);
                fu.setAuditTime(DateUtil.now());
                fundUsageMapper.insert(fu);
            }
            return Result.success("fund usage import completed");
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    @Override
    public Result<?> list(Integer year, Long regionId) {
        List<FundUsage> all = regionId == null ? fundUsageMapper.selectAll() : fundUsageMapper.selectByRegionId(regionId);
        List<FundUsageVO> result = new ArrayList<>();

        for (FundUsage item : all) {
            if (year != null) {
                String usageDate = item.getUsageDate() == null ? "" : item.getUsageDate().trim();
                if (!usageDate.startsWith(String.valueOf(year))) {
                    continue;
                }
            }
            FundUsageVO vo = new FundUsageVO();
            BeanUtils.copyProperties(item, vo);
            vo.setAuditStatus(item.getAuditStatus() != null && item.getAuditStatus() == 1 ? "已审核" : "待审核");
            if (item.getRegionId() != null) {
                Region region = regionMapper.selectById(item.getRegionId());
                vo.setRegionName(region != null ? region.getName() : "");
            } else {
                vo.setRegionName("");
            }
            result.add(vo);
        }
        return Result.success(result);
    }
}
