package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.OperationLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface OperationLogMapper {
    int insert(OperationLog operationLog);

    OperationLog selectById(@Param("id") Long id);

    List<OperationLog> selectAll();

    List<OperationLog> selectByUserId(@Param("userId") Long userId);

    List<OperationLog> selectByOperationType(@Param("operationType") String operationType);

    List<OperationLog> selectRecentLogs(@Param("limit") Integer limit);

    int countByUserId(@Param("userId") Long userId);

    int deleteById(@Param("id") Long id);

    int deleteBeforeDate(@Param("date") String date);
}
