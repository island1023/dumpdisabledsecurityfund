package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PaymentRecordMapper {
    int insert(PaymentRecord paymentRecord);

    PaymentRecord selectById(@Param("id") Long id);

    List<PaymentRecord> selectByPayableId(@Param("payableId") Long payableId);

    List<PaymentRecord> selectByStatus(@Param("status") Integer status);

    Double sumActualAmountByYear(@Param("year") Integer year);

    int updateById(PaymentRecord paymentRecord);

    int updateStatus(@Param("id") Long id, @Param("status") Integer status, @Param("confirmUserId") Long confirmUserId);

    int deleteById(@Param("id") Long id);
}
