package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.DisabledEmployeeAttachment;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface DisabledEmployeeAttachmentMapper {

    @Insert("INSERT INTO disabled_employee_attachment (employee_id, file_name, file_url, file_size, file_type, upload_time, create_time) " +
            "VALUES (#{employeeId}, #{fileName}, #{fileUrl}, #{fileSize}, #{fileType}, #{uploadTime}, #{createTime})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(DisabledEmployeeAttachment attachment);

    @Select("SELECT * FROM disabled_employee_attachment WHERE employee_id = #{employeeId}")
    List<DisabledEmployeeAttachment> selectByEmployeeId(Long employeeId);

    @Select("SELECT * FROM disabled_employee_attachment WHERE id = #{id}")
    DisabledEmployeeAttachment selectById(Long id);

    @Delete("DELETE FROM disabled_employee_attachment WHERE id = #{id}")
    int deleteById(Long id);

    @Delete("DELETE FROM disabled_employee_attachment WHERE employee_id = #{employeeId}")
    int deleteByEmployeeId(Long employeeId);
}