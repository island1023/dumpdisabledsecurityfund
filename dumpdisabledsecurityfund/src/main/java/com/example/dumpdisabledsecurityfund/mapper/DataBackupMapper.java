package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.DataBackup;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DataBackupMapper {
    int insert(DataBackup backup);

    DataBackup selectById(@Param("id") Long id);

    List<DataBackup> selectAll();

    List<DataBackup> selectByOperatorId(@Param("operatorId") Long operatorId);

    List<DataBackup> selectRecentBackups(@Param("limit") Integer limit);

    int updateRestoreTime(@Param("id") Long id, @Param("restoreTime") String restoreTime);

    int deleteById(@Param("id") Long id);
}
