import { get, post } from './HttpUtil';
import {
  CollectionRecord,
  PaymentRecord,
  CollectionListResponse,
  CollectionQueryParams,
  CollectionStatistics
} from '../models/CollectionModel';

class VerifyPaymentRequestData {
  collectionId: string = '';
  amount: number = 0;
  voucherNo?: string;
  remark?: string;
}

/**
 * 征收核算服务
 */
export class CollectionService {
  private static asRecord(value: Object | undefined): Record<string, Object> {
    if (value && typeof value === 'object') {
      return value as Record<string, Object>;
    }
    return {};
  }

  private static readNumber(source: Record<string, Object>, keys: string[], fallback: number = 0): number {
    for (let i = 0; i < keys.length; i++) {
      const value = source[keys[i]];
      if (typeof value === 'number') {
        return value;
      }
      if (typeof value === 'string' && value.trim().length > 0) {
        const num = Number(value);
        if (!Number.isNaN(num)) {
          return num;
        }
      }
    }
    return fallback;
  }

  private static readString(source: Record<string, Object>, keys: string[], fallback: string = ''): string {
    for (let i = 0; i < keys.length; i++) {
      const value = source[keys[i]];
      if (typeof value === 'string' && value.trim().length > 0) {
        return value;
      }
      if (typeof value === 'number') {
        return `${value}`;
      }
    }
    return fallback;
  }
  /**
   * 获取征收记录列表
   */
  static async getCollectionList(params: CollectionQueryParams): Promise<CollectionListResponse> {
    const queryParams: Record<string, string | number | boolean> = {};
    if (params.pageNum) {
      queryParams.pageNum = params.pageNum;
    }
    if (params.pageSize) {
      queryParams.pageSize = params.pageSize;
    }

    if (params.year) {
      queryParams.year = params.year;
    }

    if (params.status) {
      queryParams.status = params.status;
    }

    if (params.keyword) {
      queryParams.keyword = params.keyword;
    }
    if (params.regionId && params.regionId > 0) {
      queryParams.regionId = params.regionId;
    }

    const response = await get<CollectionListResponse>('/collection/list', queryParams);

    if (response.code === 200) {
      const data = response.data as Object;
      const root = CollectionService.asRecord(data);
      const listValue = root['list'] as Object[] | undefined;
      const normalizedList: CollectionRecord[] = [];
      if (listValue && Array.isArray(listValue)) {
        for (let i = 0; i < listValue.length; i++) {
          const row = CollectionService.asRecord(listValue[i]);
          normalizedList.push({
            id: CollectionService.readString(row, ['id']),
            unitId: CollectionService.readString(row, ['companyId', 'unitId']),
            unitName: CollectionService.readString(row, ['unitName', 'companyName'], '未知单位'),
            year: CollectionService.readNumber(row, ['year']),
            totalEmployeeCount: CollectionService.readNumber(row, ['totalEmployeeCount', 'employeeCount']),
            employeeCount: CollectionService.readNumber(row, ['employeeCount']),
            disabledEmployeeCount: CollectionService.readNumber(row, ['disabledEmployeeCount', 'disabledCount']),
            standardAmount: CollectionService.readNumber(row, ['standardAmount', 'calculatedAmount']),
            reductionAmount: CollectionService.readNumber(row, ['reductionAmount']),
            payableAmount: CollectionService.readNumber(row, ['payableAmount']),
            paidAmount: CollectionService.readNumber(row, ['paidAmount']),
            status: CollectionService.readString(row, ['status'], 'UNPAID') as 'UNPAID' | 'PAID' | 'PARTIAL',
            creditCode: CollectionService.readString(row, ['creditCode']),
            legalPerson: CollectionService.readString(row, ['legalPerson']),
            registerAddress: CollectionService.readString(row, ['registerAddress']),
            establishDate: CollectionService.readString(row, ['establishDate']),
            phone: CollectionService.readString(row, ['phone']),
            createTime: CollectionService.readString(row, ['createTime']),
            updateTime: CollectionService.readString(row, ['updateTime'])
          });
        }
      }
      return {
        total: CollectionService.readNumber(root, ['total'], normalizedList.length),
        list: normalizedList
      };
    }

    throw new Error(response.message);
  }

  /**
   * 获取征收统计数据
   */
  static async getCollectionStatistics(year?: number, regionId?: number): Promise<CollectionStatistics> {
    const queryParams: Record<string, string | number | boolean> = {};
    if (year) {
      queryParams.year = year;
    }
    if (regionId && regionId > 0) {
      queryParams.regionId = regionId;
    }

    const response = await get<CollectionStatistics>('/collection/statistics', queryParams);

    if (response.code === 200) {
      return response.data;
    }

    throw new Error(response.message);
  }

  /**
   * 缴款核销
   */
  static async verifyPayment(collectionId: string, amount: number, voucherNo: string, remark?: string): Promise<boolean> {
    const requestData = new VerifyPaymentRequestData();
    requestData.collectionId = collectionId;
    requestData.amount = amount;

    if (voucherNo) {
      requestData.voucherNo = voucherNo;
    }

    if (remark) {
      requestData.remark = remark;
    }

    const response = await post('/collection/verify', requestData);
    return response.code === 200;
  }

  /**
   * 获取缴款记录
   */
  static async getPaymentRecords(companyId: string): Promise<PaymentRecord[]> {
    const response = await get<PaymentRecord[]>(`/collection/payment-records/${companyId}`);

    if (response.code === 200) {
      return response.data;
    }

    throw new Error(response.message);
  }
}
