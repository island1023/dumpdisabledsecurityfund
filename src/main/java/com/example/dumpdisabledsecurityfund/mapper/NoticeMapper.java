package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Notice;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface NoticeMapper {
    int insert(Notice notice);

    Notice selectById(@Param("id") Long id);

    List<Notice> selectByIds(@Param("ids") List<Long> ids);

    List<Notice> selectByCompanyId(@Param("companyId") Long companyId);

    List<Notice> selectByNoticeType(@Param("noticeType") Integer noticeType);

    List<Notice> selectBySendStatus(@Param("sendStatus") Integer sendStatus);

    Notice selectByNoticeNumber(@Param("noticeNumber") String noticeNumber);

    int updateById(Notice notice);

    int incrementPrintCount(@Param("id") Long id, @Param("printTime") String printTime);

    int updateSendStatus(@Param("id") Long id, @Param("sendStatus") Integer sendStatus);

    int deleteById(@Param("id") Long id);
}
