import { get, put } from './HttpUtil';

/**
 * 缴费统计
 */
export interface PaymentStatistics {
  paidAmount: number;
  pendingAmount: number;
}

export interface TaxPlatformSummary {
  source: string;
  companyId: number;
  year: number;
  payableAmount: number;
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
  id?: string;
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

  /**
   * 模拟税务平台返回的本年度应缴数据
   */
  static async getTaxPlatformSummary(): Promise<TaxPlatformSummary> {
    const response = await get<TaxPlatformSummary>('/unit/payment/tax-platform');
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
  private static asRecord(value: Object | null | undefined): Record<string, Object> | null {
    if (value === null || value === undefined) {
      return null;
    }
    return value as Record<string, Object>;
  }

  private static readString(source: Record<string, Object> | null, keys: string[], fallback: string = ''): string {
    if (!source) {
      return fallback;
    }
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = source[key];
      if (typeof value === 'string' && value.trim().length > 0) {
        return value;
      }
      if (typeof value === 'number') {
        return `${value}`;
      }
    }
    return fallback;
  }

  private static readBoolean(source: Record<string, Object> | null, keys: string[], fallback: boolean = false): boolean {
    if (!source) {
      return fallback;
    }
    for (let i = 0; i < keys.length; i++) {
      const value = source[keys[i]];
      if (typeof value === 'boolean') {
        return value;
      }
      if (typeof value === 'number') {
        return value !== 0;
      }
      if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === 'true' || normalized === '1' || normalized === '已读') {
          return true;
        }
        if (normalized === 'false' || normalized === '0' || normalized === '未读') {
          return false;
        }
      }
    }
    return fallback;
  }

  private static normalizeNoticeItem(raw: Object): NoticeListItem {
    const obj = NoticeService.asRecord(raw);
    const typeName = NoticeService.readString(obj, ['type', 'noticeTypeName', 'noticeType'], '通知单');
    const contentText = NoticeService.readString(obj, ['content'], '');
    const firstLine = contentText ? contentText.split('\n')[0] : '';
    const cleanedFirstLine = firstLine
      .replace('【', '')
      .replace('】', '')
      .replace('[', '')
      .replace(']', '')
      .trim();
    const fallbackTitle = cleanedFirstLine || '通知详情';
    return {
      id: NoticeService.readString(obj, ['id', 'noticeId'], ''),
      title: NoticeService.readString(obj, ['title', 'noticeTitle'], fallbackTitle),
      date: NoticeService.readString(obj, ['date', 'printTime', 'createTime'], ''),
      type: typeName,
      read: NoticeService.readBoolean(obj, ['read', 'isRead', 'sendStatus'], false)
    };
  }

  private static normalizeNoticeDetail(raw: Object): NoticeDetail {
    const obj = NoticeService.asRecord(raw);
    const typeName = NoticeService.readString(obj, ['type', 'noticeTypeName', 'noticeType'], '通知单');
    const content = NoticeService.readString(obj, ['content'], '');
    const firstLine = content ? content.split('\n')[0] : '';
    const cleanedFirstLine = firstLine
      .replace('【', '')
      .replace('】', '')
      .replace('[', '')
      .replace(']', '')
      .trim();
    const fallbackTitle = cleanedFirstLine || '通知详情';
    return {
      id: NoticeService.readString(obj, ['id', 'noticeId'], ''),
      title: NoticeService.readString(obj, ['title', 'noticeTitle'], fallbackTitle),
      date: NoticeService.readString(obj, ['date', 'printTime', 'createTime'], ''),
      type: typeName,
      content: content || '暂无通知内容'
    };
  }

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
      const data = response.data as Object;
      const obj = NoticeService.asRecord(data);
      const listObj = obj ? (obj['list'] as Object[] | undefined) : undefined;
      const normalizedList: NoticeListItem[] = [];
      if (listObj && Array.isArray(listObj)) {
        for (let i = 0; i < listObj.length; i++) {
          normalizedList.push(NoticeService.normalizeNoticeItem(listObj[i]));
        }
      }
      const totalRaw = obj ? obj['total'] : 0;
      const totalValue = typeof totalRaw === 'number' ? totalRaw : Number(totalRaw);
      return {
        total: Number.isFinite(totalValue) ? totalValue : normalizedList.length,
        list: normalizedList
      };
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取通知单详情
   */
  static async getNoticeDetail(noticeId: string): Promise<NoticeDetail> {
    const response = await get<NoticeDetail>(`/unit/notices/${noticeId}`);
    
    if (response.code === 200) {
      return NoticeService.normalizeNoticeDetail(response.data as Object);
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
