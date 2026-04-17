package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Notice;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface NoticeMapper {
    Notice selectById(@Param("id") Long id);

    List<Notice> selectByIds(@Param("ids") List<Long> ids);

    List<Notice> selectByCompanyId(@Param("companyId") Long companyId);

    List<Notice> selectByCompanyIdWithPage(@Param("companyId") Long companyId,
                                           @Param("offset") int offset,
                                           @Param("limit") int limit,
                                           @Param("unreadOnly") Boolean unreadOnly);

    long countByCompanyId(@Param("companyId") Long companyId, @Param("unreadOnly") Boolean unreadOnly);

    int insert(Notice notice);

    int updateSendStatus(@Param("id") Long id, @Param("sendStatus") Integer sendStatus);

    int incrementPrintCount(@Param("id") Long id);
}
