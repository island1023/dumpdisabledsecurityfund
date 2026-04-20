package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PaymentRecordMapper {
    int insert(PaymentRecord record);

    PaymentRecord selectById(@Param("id") Long id);

    List<PaymentRecord> selectByPayableId(@Param("payableId") Long payableId);

    List<PaymentRecord> selectByStatus(@Param("status") Integer status);

    int updateById(PaymentRecord record);

    int deleteById(@Param("id") Long id);

    /**
     * 根据公司ID查询缴费记录
     * @param companyId 公司ID
     * @return 缴费记录列表
     */
    List<PaymentRecord> selectByCompanyId(@Param("companyId") Long companyId);

    /**
     * 分页查询缴费记录
     * @param companyId 公司ID
     * @param offset 偏移量
     * @param limit 每页数量
     * @return 缴费记录列表
     */
    List<PaymentRecord> selectRecordsWithPage(@Param("companyId") Long companyId, @Param("offset") int offset, @Param("limit") int limit);

    /**
     * 统计缴费记录总数
     * @param companyId 公司ID
     * @return 总数
     */
    long countRecords(@Param("companyId") Long companyId);
}
