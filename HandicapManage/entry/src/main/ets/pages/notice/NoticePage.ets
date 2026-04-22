import { ColorConstants } from '../../common/constants/ColorConstants';
import { promptAction } from '@kit.ArkUI';
import { buildAuthorizedGetUrlWithQuery, get, post, probeDownloadUrl } from '../../services/HttpUtil';
import { Want } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';
import { webview } from '@kit.ArkWeb';

interface NoticeItem {
  payableId: string;
  noticeId?: string;
  id: string;
  companyName: string;
  noticeType: string; // '缴款通知书' 或 '征收决定书'
  year: string;
  amount: number;
  status: string; // '未生成', '已生成', '已打印'
  generateDate?: string;
  pdfUrl?: string; // PDF文档URL
}

class NoticeListQueryParams {
  page: number = 1;
  pageSize: number = 100;
  noticeType: number = 1;
  keyword: string = '';
}

class NoticeGenerateRequest {
  payableIds: string[] = [];
  noticeType: number = 1;
}

class NoticePrintRequest {
  noticeIds: string[] = [];
}

// 弹窗类型枚举
enum NoticeSheetType {
  NONE,
  PREVIEW
}

@Component
export struct NoticePage {
  @Prop @Watch('onRegionChanged') selectedRegionId: number = 0;
  @Prop @Watch('onReloadNonceChanged') reloadNonce: number = 0;
  @State searchKeyword: string = '';
  @State noticeType: string = 'payment'; // 'payment'-缴款通知书, 'decision'-征收决定书
  @State selectedItems: string[] = [];
  @State isSheetShow: boolean = false;
  @State activeSheet: NoticeSheetType = NoticeSheetType.NONE;
  @State selectedNotice: NoticeItem | null = null;
  @State previewContent: string = ''; // 预览内容
  @State previewPdfUrl: string = '';
  private pdfWebController: webview.WebviewController = new webview.WebviewController();

  @State noticeList: NoticeItem[] = [];
  @State isLoading: boolean = false;
  @State actionLoading: boolean = false;

  aboutToAppear() {
    this.loadNoticeList();
  }

  private onRegionChanged(): void {
    console.info(`NoticePage区域筛选变更: regionId=${this.selectedRegionId}`);
    this.loadNoticeList();
  }

  private onReloadNonceChanged(): void {
    console.info(`NoticePage强制刷新: regionId=${this.selectedRegionId}, reloadNonce=${this.reloadNonce}`);
    this.loadNoticeList();
  }

  // 打开弹窗
  private openSheet(type: NoticeSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    Column() {
      // 顶部：通知单类型切换
      Row() {
        Text('缴款通知书')
          .fontSize(14)
          .fontColor(this.noticeType === 'payment' ? ColorConstants.PRIMARY : ColorConstants.TEXT_BODY)
          .fontWeight(this.noticeType === 'payment' ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.noticeType === 'payment' ? 'rgba(199, 28, 34, 0.1)' : 'transparent')
          .borderRadius(16)
          .margin({ right: 12 })
          .onClick(() => {
            this.noticeType = 'payment';
            this.loadNoticeList();
          })

        Text('征收决定书')
          .fontSize(14)
          .fontColor(this.noticeType === 'decision' ? ColorConstants.PRIMARY : ColorConstants.TEXT_BODY)
          .fontWeight(this.noticeType === 'decision' ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.noticeType === 'decision' ? 'rgba(199, 28, 34, 0.1)' : 'transparent')
          .borderRadius(16)
          .onClick(() => {
            this.noticeType = 'decision';
            this.loadNoticeList();
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 批量操作按钮
      Row() {
        Button('批量生成')
          .width(100)
          .height(36)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .onClick(() => {
            this.handleBatchGenerate();
          })
          .margin({ right: 12 })

        Button('批量打印/导出PDF')
          .width(100)
          .height(36)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorConstants.SUCCESS)
          .borderRadius(8)
          .onClick(() => {
            this.handleBatchPrint();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 16 })

      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索单位名称...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_CARD)
          .border({ width: 1, color: ColorConstants.BORDER })
          .borderRadius(8)
          .padding({ left: 12, right: 12 })

        Button('搜索')
          .width(80)
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.loadNoticeList();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 列表 - 可滚动
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
      Scroll() {
        Column() {
          ForEach(this.getFilteredList(), (item: NoticeItem) => {
            Column() {
              // 头部：单位名称和选择
              Row() {
                Row() {
                  Text(this.selectedItems.includes(item.id) ? '✓' : '○')
                    .fontSize(18)
                    .fontColor(this.selectedItems.includes(item.id) ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
                    .fontWeight(FontWeight.Bold)
                }
                .width(40)
                .height(40)
                .borderRadius(8)
                .backgroundColor(this.selectedItems.includes(item.id) ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  this.toggleSelect(item.id);
                })

                Column() {
                  Text(item.companyName)
                    .fontSize(16)
                    .fontColor(ColorConstants.TEXT_TITLE)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })
                  
                  Text(item.noticeType)
                    .fontSize(13)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })

                Text(item.status)
                  .fontSize(13)
                  .fontColor(this.getStatusColor(item.status))
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                  .backgroundColor(this.getStatusBgColor(item.status))
                  .borderRadius(12)
              }
              .width('100%')
              .margin({ bottom: 16 })

              // 详细信息
              Row() {
                Column() {
                  Text('年度')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(item.year)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)

                Column() {
                  Text('金额')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`¥${(item.amount / 10000).toFixed(1)}万`)
                    .fontSize(16)
                    .fontColor(ColorConstants.PRIMARY)
                    .fontWeight(FontWeight.Bold)
                }
                .layoutWeight(1)

                Column() {
                  Text('生成日期')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(item.generateDate || '未生成')
                    .fontSize(14)
                    .fontColor(item.generateDate ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
              .margin({ bottom: 16 })

              // 操作按钮
              Row() {
                Button('预览')
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(14)
                  .fontColor(ColorConstants.TEXT_SECONDARY)
                  .backgroundColor(ColorConstants.BG_PAGE)
                  .border({ width: 1, color: ColorConstants.BORDER })
                  .borderRadius(6)
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.handlePreview(item);
                  })

                if (item.status === '已生成' || item.status === '已打印') {
                  Button('打印')
                    .layoutWeight(1)
                    .height(36)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor(ColorConstants.PRIMARY)
                    .borderRadius(6)
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.handlePrint(item);
                    })
                } else {
                  Button('生成')
                    .layoutWeight(1)
                    .height(36)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor(ColorConstants.SUCCESS)
                    .borderRadius(6)
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.handleGenerate(item);
                    })
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorConstants.BG_CARD)
            .borderRadius(12)
            .shadow({
              radius: 4,
              color: 'rgba(0, 0, 0, 0.06)',
              offsetX: 0,
              offsetY: 2
            })
            .margin({ bottom: 12 })
          })
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .bindSheet($$this.isSheetShow, this.sheetBuilder(), {
      detents: [SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      title: { title: '通知单预览' },
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = NoticeSheetType.NONE;
        this.selectedNotice = null;
        this.previewContent = '';
        this.previewPdfUrl = '';
      }
    })
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === NoticeSheetType.PREVIEW) {
        this.buildPreviewDialog()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildPreviewDialog() {
    if (this.previewPdfUrl) {
      Column() {
        Web({ src: this.previewPdfUrl, controller: this.pdfWebController })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    } else {
      Scroll() {
        Column() {
          if (this.selectedNotice) {
            // 标题
            Text(this.selectedNotice.noticeType)
              .fontSize(20)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 24 })

            // 文档内容
            Column() {
              Text(this.previewContent)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_BODY)
                .lineHeight(24)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
            .margin({ bottom: 20 })

            // 提示信息
            Row() {
              Text('提示：此PDF文档已上传至单位用户的通知单管理系统')
                .fontSize(12)
                .fontColor(ColorConstants.TEXT_SECONDARY)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('rgba(199, 28, 34, 0.05)')
            .borderRadius(8)
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      }
      .width('100%')
    }
  }

  private getFilteredList(): NoticeItem[] {
    let list = this.noticeList;

    const targetType = this.noticeType === 'payment' ? '缴款通知书' : '征收决定书';
    list = list.filter(item => item.noticeType === targetType);

    if (this.searchKeyword) {
      list = list.filter(item => item.companyName.includes(this.searchKeyword));
    }

    return list;
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case '已生成':
        return ColorConstants.SUCCESS;
      case '已打印':
        return ColorConstants.PRIMARY;
      case '未生成':
        return ColorConstants.WARNING;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case '已生成':
        return 'rgba(0, 158, 95, 0.1)';
      case '已打印':
        return 'rgba(199, 28, 34, 0.1)';
      case '未生成':
        return 'rgba(245, 158, 11, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  private toggleSelect(id: string) {
    if (this.selectedItems.includes(id)) {
      this.selectedItems = this.selectedItems.filter(item => item !== id);
    } else {
      const newItems = this.selectedItems.slice();
      newItems.push(id);
      this.selectedItems = newItems;
    }
  }

  private handleGenerate(item: NoticeItem) {
    if (this.actionLoading) {
      return;
    }
    console.info(`点击生成: payableId=${item.payableId}, company=${item.companyName}, status=${item.status}`);
    void this.generateByPayableIds([item.payableId]);
  }

  private handlePrint(item: NoticeItem) {
    if (!item.noticeId) {
      promptAction.showToast({ message: '请先生成通知单' });
      return;
    }
    void this.printByNoticeIds([item.noticeId]);
  }

  private handlePreview(item: NoticeItem) {
    if (item.noticeId && (item.status === '已生成' || item.status === '已打印')) {
      const encodedId = encodeURIComponent(item.noticeId);
      this.previewPdfUrl = buildAuthorizedGetUrlWithQuery(`/notice/preview?id=${encodedId}`) + '#toolbar=0&navpanes=0&scrollbar=0';
      this.selectedNotice = item;
      this.openSheet(NoticeSheetType.PREVIEW);
      return;
    }
    this.previewPdfUrl = '';
    this.selectedNotice = item;
    this.generatePreviewContent(item);
    this.openSheet(NoticeSheetType.PREVIEW);
  }

  // 生成预览内容
  private generatePreviewContent(item: NoticeItem) {
    const currentDate = new Date().toISOString().split('T')[0];
    
    if (item.noticeType === '缴款通知书') {
      this.previewContent = `尊敬的${item.companyName}负责人：\n\n根据《残疾人就业条例》和相关规定，经核算，贵单位${item.year}度应缴纳残疾人就业保障金金额为：¥${(item.amount / 10000).toFixed(1)}万元。\n\n请于规定期限内完成缴纳，逾期将按规定加收滞纳金。\n\n缴款信息：\n- 单位名称：${item.companyName}\n- 征收年度：${item.year}\n- 应缴金额：¥${(item.amount / 10000).toFixed(1)}万元\n- 生成日期：${currentDate}\n\n特此通知。\n\nXX市残疾人就业保障金征收管理中心\n${currentDate}`;
    } else {
      this.previewContent = `征收决定书\n\n被征收单位：${item.companyName}\n\n根据《残疾人就业保障金征收使用管理办法》规定，经核定，贵单位${item.year}度应缴纳残疾人就业保障金金额为：¥${(item.amount / 10000).toFixed(1)}万元。\n\n现决定如下：\n一、征收金额：¥${(item.amount / 10000).toFixed(1)}万元\n二、缴纳期限：自本决定书送达之日起15日内\n三、缴纳方式：通过指定银行账户缴纳\n\n如不服本决定，可在收到本决定书之日起60日内向上一级行政机关申请行政复议，或在6个月内向人民法院提起行政诉讼。\n\n征收机关：XX市残疾人就业保障金征收管理中心\n日期：${currentDate}`;
    }
  }

  private handleBatchGenerate() {
    if (this.actionLoading) {
      return;
    }
    if (this.selectedItems.length === 0) {
      this.showToastSafe('请选择要生成的通知单');
      return;
    }
    
    const payableIds: string[] = [];
    for (let i = 0; i < this.selectedItems.length; i++) {
      const selected = this.noticeList.find(n => n.id === this.selectedItems[i]);
      if (selected) {
        payableIds.push(selected.payableId);
      }
    }
    void this.generateByPayableIds(payableIds);
  }

  private handleBatchPrint() {
    if (this.actionLoading) {
      return;
    }
    if (this.selectedItems.length === 0) {
      this.showToastSafe('请选择要打印的通知单');
      return;
    }
    
    const noticeIds: string[] = [];
    for (let i = 0; i < this.selectedItems.length; i++) {
      const selected = this.noticeList.find(n => n.id === this.selectedItems[i]);
      if (selected && selected.noticeId) {
        noticeIds.push(selected.noticeId);
      }
    }
    if (noticeIds.length === 0) {
      this.showToastSafe('请先生成通知单再打印');
      return;
    }
    void this.printByNoticeIds(noticeIds);
  }

  private async loadNoticeList(): Promise<void> {
    try {
      this.isLoading = true;
      const typeCode = this.noticeType === 'payment' ? 1 : 2;
      const params = new NoticeListQueryParams();
      params.page = 1;
      params.pageSize = 100;
      params.noticeType = typeCode;
      if (this.searchKeyword.trim().length > 0) {
        params.keyword = this.searchKeyword.trim();
      }
      let requestUrl = `/notice/list?page=${params.page}&pageSize=${params.pageSize}&noticeType=${params.noticeType}`;
      if (this.selectedRegionId > 0) {
        requestUrl += `&regionId=${this.selectedRegionId}`;
      }
      if (params.keyword.length > 0) {
        requestUrl += `&keyword=${encodeURIComponent(params.keyword)}`;
      }
      const response = await get<Object>(requestUrl);
      if (response.code === 200) {
        const data = response.data as Record<string, Object>;
        const list = (data['list'] as Object[]) || [];
        const mapped: NoticeItem[] = [];
        for (let i = 0; i < list.length; i++) {
          const row = list[i] as Record<string, Object>;
          const payableId = String(row['id'] ?? '');
          const noticeId = String(row['noticeId'] ?? '');
          mapped.push({
            id: payableId,
            payableId: payableId,
            noticeId: noticeId,
            companyName: String(row['companyName'] ?? ''),
            noticeType: String(row['noticeType'] ?? ''),
            year: String(row['year'] ?? ''),
            amount: Number(row['amount'] ?? 0),
            status: String(row['status'] ?? '未生成'),
            generateDate: String(row['generateDate'] ?? ''),
            pdfUrl: ''
          });
        }
        this.noticeList = mapped;
        if (!this.searchKeyword.trim() && mapped.length === 0) {
          const yearValue = String(data['year'] ?? '');
          if (yearValue.length > 0) {
            promptAction.showToast({ message: `${yearValue}年度暂无可生成通知单数据` });
          }
        }
      } else {
        this.noticeList = [];
        promptAction.showToast({ message: response.message || '加载通知单失败' });
      }
    } catch (error) {
      console.error('加载通知单管理列表失败:', error);
      this.noticeList = [];
      promptAction.showToast({ message: '加载通知单失败' });
    } finally {
      this.isLoading = false;
    }
  }

  private async generateByPayableIds(payableIds: string[]): Promise<void> {
    if (payableIds.length === 0) {
      this.showToastSafe('请选择要生成的通知单');
      return;
    }
    try {
      this.actionLoading = true;
      const typeCode = this.noticeType === 'payment' ? 1 : 2;
      const requestData = new NoticeGenerateRequest();
      requestData.payableIds = payableIds;
      requestData.noticeType = typeCode;
      console.info(`开始生成通知单: type=${typeCode}, payableIds=${JSON.stringify(payableIds)}`);
      const response = await post('/notice/generate', requestData);
      console.info(`生成通知单响应: code=${response.code}, message=${response.message}`);
      if (response.code === 200) {
        // 先本地更新，避免接口回刷失败时看起来“没反应”
        const now = new Date().toISOString().replace('T', ' ').substring(0, 19);
        const updated: NoticeItem[] = [];
        for (let i = 0; i < this.noticeList.length; i++) {
          const n = this.noticeList[i];
          if (payableIds.includes(n.payableId)) {
            const updatedItem: NoticeItem = {
              payableId: n.payableId,
              noticeId: n.noticeId,
              id: n.id,
              companyName: n.companyName,
              noticeType: n.noticeType,
              year: n.year,
              amount: n.amount,
              status: '已生成',
              generateDate: now,
              pdfUrl: n.pdfUrl
            };
            updated.push(updatedItem);
          } else {
            updated.push(n);
          }
        }
        this.noticeList = updated;
        this.showToastSafe(response.message || '通知单生成成功');
        this.selectedItems = [];
        await this.loadNoticeList();
      } else {
        this.showToastSafe(response.message || '生成失败');
      }
    } catch (error) {
      console.error('生成通知单失败:', error);
      this.showToastSafe('生成通知单失败');
    } finally {
      this.actionLoading = false;
    }
  }

  private async printByNoticeIds(noticeIds: string[]): Promise<void> {
    try {
      this.actionLoading = true;
      const opened = await this.openNoticeDownload(noticeIds);
      if (!opened) {
        return;
      }
      const requestData = new NoticePrintRequest();
      requestData.noticeIds = noticeIds;
      console.info(`开始打印通知单: noticeIds=${JSON.stringify(noticeIds)}`);
      const response = await post('/notice/print', requestData);
      console.info(`打印通知单响应: code=${response.code}, message=${response.message}`);
      if (response.code === 200) {
        this.showToastSafe(response.message || '打印状态已更新');
        this.selectedItems = [];
        await this.loadNoticeList();
      } else {
        this.showToastSafe(response.message || '打印失败');
      }
    } catch (error) {
      console.error('更新打印状态失败:', error);
      this.showToastSafe('更新打印状态失败');
    } finally {
      this.actionLoading = false;
    }
  }

  private async openNoticePdf(noticeId: string): Promise<boolean> {
    const encodedId = encodeURIComponent(noticeId);
    const requestPath = `/notice/preview?id=${encodedId}`;
    const probe = await probeDownloadUrl(requestPath, false);
    if (!probe.ok) {
      this.showToastSafe(probe.message || 'PDF下载校验失败');
      return false;
    }
    const url = buildAuthorizedGetUrlWithQuery(requestPath);
    return this.openUrlByBrowser(url);
  }

  private async openNoticeDownload(noticeIds: string[]): Promise<boolean> {
    if (noticeIds.length === 1) {
      return this.openNoticePdf(noticeIds[0]);
    }
    const idsParam = noticeIds.join(',');
    const encodedIds = encodeURIComponent(idsParam);
    const requestPath = `/notice/downloadBatch?ids=${encodedIds}`;
    const probe = await probeDownloadUrl(requestPath, true);
    if (!probe.ok) {
      this.showToastSafe(probe.message || 'ZIP下载校验失败');
      return false;
    }
    const url = buildAuthorizedGetUrlWithQuery(requestPath);
    return this.openUrlByBrowser(url);
  }

  private async openUrlByBrowser(url: string): Promise<boolean> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };
      await context.startAbility(want);
      return true;
    } catch (error) {
      console.error('打开浏览器失败:', error);
      return false;
    }
  }

  private showToastSafe(message: string): void {
    try {
      promptAction.showToast({ message });
    } catch (e) {
      console.error('toast失败:', e);
    }
  }

}
