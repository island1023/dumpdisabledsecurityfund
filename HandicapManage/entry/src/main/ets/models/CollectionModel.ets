/**
 * 征收核算数据模型
 */
export interface CollectionRecord {
 id: string;
 unitId: string;
 unitName: string;
 year: number; // 核算年度
 employeeCount: number; // 职工总数
 disabledEmployeeCount: number; // 安置残疾人数
 standardAmount: number; // 应缴金额
 reductionAmount: number; // 减免金额
 payableAmount: number; // 实缴金额
 paidAmount: number; // 已缴金额
 status: 'UNPAID' | 'PAID' | 'PARTIAL';
 createTime: string;
 updateTime: string;
}

/**
 * 缴款核销记录
 */
export interface PaymentRecord {
 id: string;
 collectionId: string;
 unitId: string;
 unitName: string;
 amount: number;
 paymentTime: string;
 paymentMethod: 'TAX' | 'MANUAL'; // 税务对接/手动录入
 voucherNo: string; // 凭证号
 operator: string;
 createTime: string;
}

/**
 * 核算查询参数
 */
export interface CollectionQueryParams {
 year?: number;
 districtCode?: string;
 status?: string;
 keyword?: string;
 pageNum: number;
 pageSize: number;
}

/**
 * 核算列表响应
 */
export interface CollectionListResponse {
 total: number;
 list: CollectionRecord[];
}

/**
 * 征收统计数据
 */
export interface CollectionStatistics {
 totalUnits: number; // 应缴单位总数
 paidUnits: number; // 已缴单位数
 unpaidUnits: number; // 未缴单位数
 totalAmount: number; // 应缴总额
 paidAmount: number; // 已缴总额
 reductionAmount: number; // 减免总额
}
