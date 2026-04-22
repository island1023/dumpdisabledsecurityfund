package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.FundUsage;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface FundUsageMapper {
    int insert(FundUsage fundUsage);

    FundUsage selectById(@Param("id") Long id);

    List<FundUsage> selectAll();

    List<FundUsage> selectByRegionId(@Param("regionId") Long regionId);

    List<FundUsage> selectByAuditStatus(@Param("auditStatus") Integer auditStatus);

    List<FundUsage> selectLeaderFundUsage(@Param("regionId") Long regionId,
                                          @Param("projectType") String projectType,
                                          @Param("keyword") String keyword);

    Double sumAmountByYear(@Param("year") Integer year);

    Double sumAmountByRegionAndYear(@Param("regionId") Long regionId, @Param("year") Integer year);

    int updateById(FundUsage fundUsage);

    int updateAuditStatus(@Param("id") Long id, @Param("auditStatus") Integer auditStatus,
                          @Param("auditorId") Long auditorId, @Param("auditTime") String auditTime);

    int deleteById(@Param("id") Long id);
}
