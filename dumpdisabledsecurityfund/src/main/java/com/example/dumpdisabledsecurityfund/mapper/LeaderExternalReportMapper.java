package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.LeaderExternalReport;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface LeaderExternalReportMapper {
    List<LeaderExternalReport> selectByTypeAndYearMonth(@Param("reportType") String reportType,
                                                      @Param("year") int year,
                                                      @Param("month") int month);
}
