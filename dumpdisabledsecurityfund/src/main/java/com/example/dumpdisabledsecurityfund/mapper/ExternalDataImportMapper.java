package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.ExternalDataImport;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ExternalDataImportMapper {
    int insert(ExternalDataImport externalDataImport);

    ExternalDataImport selectById(@Param("id") Long id);

    List<ExternalDataImport> selectAll();

    List<ExternalDataImport> selectBySource(@Param("source") String source);

    List<ExternalDataImport> selectByStatus(@Param("status") Integer status);

    List<ExternalDataImport> selectRecentImports(@Param("limit") Integer limit);

    int updateStatus(@Param("id") Long id, @Param("status") Integer status, @Param("errorMsg") String errorMsg);

    int deleteById(@Param("id") Long id);
}
