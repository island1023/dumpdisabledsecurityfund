import { get, put } from './HttpUtil';

/**
 * 缴费统计
 */
export interface PaymentStatistics {
  paidAmount: number;
  pendingAmount: number;
}

/**
 * 缴费记录
 */
export interface PaymentRecord {
  period: string;
  amount: string;
  date: string;
  status: string;
}

/**
 * 通知单列表项
 */
export interface NoticeListItem {
  id: string;
  title: string;
  date: string;
  type: string;
  read: boolean;
}

/**
 * 通知单详情
 */
export interface NoticeDetail {
  title: string;
  date: string;
  type: string;
  content: string;
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  total: number;
  list: T[];
}

/**
 * 缴费服务
 */
export class PaymentService {
  /**
   * 获取缴费统计
   */
  static async getPaymentStatistics(): Promise<PaymentStatistics> {
    const response = await get<PaymentStatistics>('/unit/payment/statistics');
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取缴费记录列表
   */
  static async getPayments(page: number = 1, pageSize: number = 20): Promise<PageResponse<PaymentRecord>> {
    const params: Record<string, string | number | boolean> = {};
    if (page) {
      params.page = page;
    }
    if (pageSize) {
      params.pageSize = pageSize;
    }
    const response = await get<PageResponse<PaymentRecord>>('/unit/payments', params);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }
}

/**
 * 通知单服务
 */
export class NoticeService {
  /**
   * 获取通知单列表
   */
  static async getNotices(page: number = 1, pageSize: number = 20, unreadOnly: boolean = false): Promise<PageResponse<NoticeListItem>> {
    const params: Record<string, string | number | boolean> = {};
    if (page) {
      params.page = page;
    }
    if (pageSize) {
      params.pageSize = pageSize;
    }
    if (unreadOnly) {
      params.unreadOnly = unreadOnly;
    }
    const response = await get<PageResponse<NoticeListItem>>('/unit/notices', params);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取通知单详情
   */
  static async getNoticeDetail(noticeId: string): Promise<NoticeDetail> {
    const response = await get<NoticeDetail>(`/unit/notices/${noticeId}`);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 标记通知为已读
   */
  static async markAsRead(noticeId: string): Promise<boolean> {
    const response = await put(`/unit/notices/${noticeId}/read`);
    return response.code === 200;
  }
}
