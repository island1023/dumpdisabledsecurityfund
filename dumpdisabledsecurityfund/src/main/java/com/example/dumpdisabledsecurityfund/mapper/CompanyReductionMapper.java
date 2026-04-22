package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyReduction;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyReductionMapper {
    int insert(CompanyReduction reduction);

    CompanyReduction selectById(@Param("id") Long id);

    List<CompanyReduction> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyReduction> selectByCompanyIdAndYear(@Param("companyId") Long companyId, @Param("year") Integer year);

    List<CompanyReduction> selectByAuditStatus(@Param("auditStatus") Integer auditStatus);

    Double sumApplyAmountByYear(@Param("year") Integer year);

    int updateById(CompanyReduction reduction);

    int updateAuditStatus(@Param("id") Long id, @Param("auditStatus") Integer auditStatus,
                          @Param("auditorId") Long auditorId, @Param("auditOpinion") String auditOpinion,
                          @Param("auditTime") String auditTime, @Param("updateTime") String updateTime);

    int deleteById(@Param("id") Long id);
}
