/**
 * 政务系统色彩规范常量
 * 政务红主体风格，符合残联/政务系统视觉规范
 */
export class ColorConstants {
 // 主色调（红色主体）
 static readonly PRIMARY: string = '#C71C22'; // 政务标准红
 static readonly PRIMARY_LIGHT: string = '#E84C4C'; // 浅红色（选中态）
 static readonly PRIMARY_DARK: string = '#A62019'; // 深红色

 // 辅助色
 static readonly SUCCESS: string = '#009E5F'; // 审批通过、已缴、完成
 static readonly WARNING: string = '#F29900'; // 待审批、未缴、待办
 static readonly DANGER: string = '#A62019'; // 异常、未缴（仅小面积）

 // 中性色
 static readonly BG_PAGE: string = '#F7F8FA'; // 页面背景
 static readonly BG_CARD: string = '#FFFFFF'; // 卡片背景
 static readonly BORDER: string = '#E5E6EB'; // 边框/分割线
 static readonly TEXT_TITLE: string = '#1D2129'; // 标题文字
 static readonly TEXT_BODY: string = '#4E5969'; // 正文文字
 static readonly TEXT_SECONDARY: string = '#86909C'; // 次要文字

 // 按钮色
 static readonly BTN_PRIMARY: string = '#C71C22'; // 主按钮红色
 static readonly BTN_SECONDARY: string = '#86909C'; // 次按钮灰色
 static readonly BTN_DANGER: string = '#A62019'; // 危险按钮

 // 表格色
 static readonly TABLE_HEADER: string = '#F7F8FA'; // 表头背景
 static readonly TABLE_ROW_ALT: string = '#FAFBFC'; // 隔行色
 static readonly TABLE_HOVER: string = '#F2F3F5'; // hover高亮

 // 导航栏
 static readonly NAV_BG: string = '#C71C22'; // 导航栏背景
 static readonly NAV_TEXT: string = '#FFFFFF'; // 导航栏文字
 static readonly NAV_SELECTED: string = 'rgba(255,255,255,0.2)'; //选中项背景

 // 渐变色
 static readonly GRADIENT_HEADER_START: string = '#C71C22';
 static readonly GRADIENT_HEADER_END: string = '#E84C4C';
}
