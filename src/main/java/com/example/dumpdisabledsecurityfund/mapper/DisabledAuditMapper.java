package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.DisabledAudit;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DisabledAuditMapper {
    int insert(DisabledAudit audit);

    DisabledAudit selectById(@Param("id") Long id);

    List<DisabledAudit> selectByCompanyId(@Param("companyId") Long companyId);

    List<DisabledAudit> selectByCompanyIdAndYear(@Param("companyId") Long companyId, @Param("year") Integer year);

    List<DisabledAudit> selectByAuditStatus(@Param("auditStatus") Integer auditStatus);

    DisabledAudit selectByIdCard(@Param("idCard") String idCard);

    int updateById(DisabledAudit audit);

    int updateStatusById(@Param("id") Long id, @Param("status") Integer status,
                         @Param("auditorId") Long auditorId, @Param("auditTime") String auditTime);

    int deleteById(@Param("id") Long id);
}
