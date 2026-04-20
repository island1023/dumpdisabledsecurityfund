import {
 CollectionRecord,
 PaymentRecord,
 CollectionListResponse,
 CollectionQueryParams,
 CollectionStatistics
} from '../models/CollectionModel';

/**
 * 模拟征收核算服务
 */
export class MockCollectionService {
 // 模拟征收记录数据
 private static mockRecords: CollectionRecord[] = [
 {
 id: '1',
 unitId: '1',
 unitName: '广州科技发展有限公司',
 year:2024,
 employeeCount:150,
 disabledEmployeeCount:3,
 standardAmount:75000,
 reductionAmount:15000,
 payableAmount:60000,
 paidAmount:60000,
 status: 'PAID',
 createTime: '2024-12-0110:00:00',
 updateTime: '2025-03-1514:30:00'
 },
 {
 id: '2',
 unitId: '2',
 unitName: '珠江商贸集团',
 year:2024,
 employeeCount:320,
 disabledEmployeeCount:8,
 standardAmount:160000,
 reductionAmount:40000,
 payableAmount:120000,
 paidAmount:70000,
 status: 'PARTIAL',
 createTime: '2024-12-0110:00:00',
 updateTime: '2025-04-1011:00:00'
 },
 {
 id: '3',
 unitId: '3',
 unitName: '白云制造有限公司',
 year:2024,
 employeeCount:200,
 disabledEmployeeCount:0,
 standardAmount:100000,
 reductionAmount:0,
 payableAmount:100000,
 paidAmount:0,
 status: 'UNPAID',
 createTime: '2024-12-0110:00:00',
 updateTime: '2025-04-1216:20:00'
 },
 {
 id: '4',
 unitId: '4',
 unitName: '海珠电子科技',
 year:2024,
 employeeCount:80,
 disabledEmployeeCount:2,
 standardAmount:40000,
 reductionAmount:10000,
 payableAmount:30000,
 paidAmount:30000,
 status: 'PAID',
 createTime: '2024-12-0110:00:00',
 updateTime: '2025-02-2810:15:00'
 },
 {
 id: '5',
 unitId: '5',
 unitName: '番禺物流有限公司',
 year:2024,
 employeeCount:500,
 disabledEmployeeCount:12,
 standardAmount:250000,
 reductionAmount:60000,
 payableAmount:190000,
 paidAmount:190000,
 status: 'PAID',
 createTime: '2024-12-0110:00:00',
 updateTime: '2025-04-0109:00:00'
 },
 {
 id: '6',
 unitId: '1',
 unitName: '广州科技发展有限公司',
 year:2023,
 employeeCount:140,
 disabledEmployeeCount:2,
 standardAmount:70000,
 reductionAmount:10000,
 payableAmount:60000,
 paidAmount:60000,
 status: 'PAID',
 createTime: '2023-12-0110:00:00',
 updateTime: '2024-03-1514:30:00'
 }
 ];

 // 模拟缴款记录
 private static mockPayments: PaymentRecord[] = [
 {
 id: '1',
 collectionId: '1',
 unitId: '1',
 unitName: '广州科技发展有限公司',
 amount:60000,
 paymentTime: '2025-03-1514:30:00',
 paymentMethod: 'TAX',
 voucherNo: 'TAX20250315001',
 operator: '税务系统',
 createTime: '2025-03-1514:30:00'
 },
 {
 id: '2',
 collectionId: '2',
 unitId: '2',
 unitName: '珠江商贸集团',
 amount:70000,
 paymentTime: '2025-04-1011:00:00',
 paymentMethod: 'MANUAL',
 voucherNo: 'MANUAL20250410001',
 operator: '市级管理员',
 createTime: '2025-04-1011:00:00'
 }
 ];

 /**
 * 获取征收记录列表
 */
 static async getCollectionList(params: CollectionQueryParams): Promise<CollectionListResponse> {
 await MockCollectionService.delay(300);

 let filteredList: CollectionRecord[] = MockCollectionService.mockRecords.slice();

 // 年度过滤
 if (params.year) {
 filteredList = filteredList.filter((r: CollectionRecord): boolean => r.year === params.year);
 }

 // 行政区划过滤
 if (params.districtCode) {
 // 实际应关联单位表查询
 }

 // 状态过滤
 if (params.status) {
 filteredList = filteredList.filter((r: CollectionRecord): boolean => r.status === params.status);
 }

 // 关键字过滤
 if (params.keyword) {
 const keyword: string = params.keyword.toLowerCase();
 filteredList = filteredList.filter((r: CollectionRecord): boolean =>
 r.unitName.toLowerCase().includes(keyword)
 );
 }

 const total = filteredList.length;
 const start = (params.pageNum -1) * params.pageSize;
 const list = filteredList.slice(start, start + params.pageSize);

 return { total, list };
 }

 /**
 * 获取征收统计数据
 */
 static async getCollectionStatistics(year?: number): Promise<CollectionStatistics> {
 await MockCollectionService.delay(200);

 let records: CollectionRecord[] = MockCollectionService.mockRecords;
 if (year) {
 records = records.filter((r: CollectionRecord): boolean => r.year === year);
 }

 return {
 totalUnits: records.length,
 paidUnits: records.filter(r => r.status === 'PAID').length,
 unpaidUnits: records.filter(r => r.status === 'UNPAID').length,
 totalAmount: records.reduce((sum, r) => sum + r.standardAmount,0),
 paidAmount: records.reduce((sum, r) => sum + r.paidAmount,0),
 reductionAmount: records.reduce((sum, r) => sum + r.reductionAmount,0)
 };
 }

 /**
 * 执行核算
 */
 static async calculateCollection(year: number): Promise<boolean> {
 await MockCollectionService.delay(500);
 // 模拟核算逻辑
 return true;
 }

 /**
 * 缴款核销
 */
 static async verifyPayment(collectionId: string, amount: number, voucherNo: string): Promise<boolean> {
 await MockCollectionService.delay(300);
 const record: CollectionRecord | undefined = MockCollectionService.mockRecords.find((r: CollectionRecord): boolean => r.id === collectionId);
 if (record) {
 const newPaidAmount = record.paidAmount + amount;
 record.paidAmount = newPaidAmount;
 record.status = newPaidAmount >= record.payableAmount ? 'PAID' : 'PARTIAL';
 record.updateTime = new Date().toISOString();

 // 添加缴款记录
 const newPayment: PaymentRecord = {
 id: String(MockCollectionService.mockPayments.length +1),
 collectionId: collectionId,
 unitId: record.unitId,
 unitName: record.unitName,
 amount: amount,
 paymentTime: new Date().toISOString(),
 paymentMethod: 'MANUAL',
 voucherNo: voucherNo,
 operator: '当前用户',
 createTime: new Date().toISOString()
 };
 MockCollectionService.mockPayments.push(newPayment);
 return true;
 }
 return false;
 }

 /**
 * 获取缴款记录
 */
 static async getPaymentRecords(collectionId: string): Promise<PaymentRecord[]> {
 await MockCollectionService.delay(200);
 return MockCollectionService.mockPayments.filter((p: PaymentRecord): boolean => p.collectionId === collectionId);
 }

 /**
 * 模拟延迟
 */
 private static delay(ms: number): Promise<void> {
 return new Promise(resolve => setTimeout(resolve, ms));
 }
}
