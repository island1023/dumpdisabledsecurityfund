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

    const response = await get<CollectionListResponse>('/collection/list', queryParams);

    if (response.code === 200) {
      return response.data;
    }

    throw new Error(response.message);
  }

  /**
   * 获取征收统计数据
   */
  static async getCollectionStatistics(year?: number): Promise<CollectionStatistics> {
    const queryParams: Record<string, string | number | boolean> = {};
    if (year) {
      queryParams.year = year;
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
