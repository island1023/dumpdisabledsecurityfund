import { ColorConstants } from '../../common/constants/ColorConstants';
import { promptAction } from '@kit.ArkUI';

interface NoticeItem {
  id: string;
  companyName: string;
  noticeType: string; // '缴款通知书' 或 '征收决定书'
  year: string;
  amount: number;
  status: string; // '未生成', '已生成', '已打印'
  generateDate?: string;
  pdfUrl?: string; // PDF文档URL
}

// 弹窗类型枚举
enum NoticeSheetType {
  NONE,
  PREVIEW
}

@Component
export struct NoticePage {
  @State searchKeyword: string = '';
  @State noticeType: string = 'payment'; // 'payment'-缴款通知书, 'decision'-征收决定书
  @State selectedItems: string[] = [];
  @State isSheetShow: boolean = false;
  @State activeSheet: NoticeSheetType = NoticeSheetType.NONE;
  @State selectedNotice: NoticeItem | null = null;
  @State previewContent: string = ''; // 预览内容

  @State noticeList: NoticeItem[] = [
    {
      id: '1',
      companyName: '成都科技发展有限公司',
      noticeType: '缴款通知书',
      year: '2025年',
      amount: 180000,
      status: '已生成',
      generateDate: '2025-04-15'
    },
    {
      id: '2',
      companyName: '珠江商贸集团',
      noticeType: '缴款通知书',
      year: '2025年',
      amount: 150000,
      status: '未生成'
    },
    {
      id: '3',
      companyName: '白云制造有限公司',
      noticeType: '征收决定书',
      year: '2025年',
      amount: 210000,
      status: '已生成',
      generateDate: '2025-04-14'
    },
    {
      id: '4',
      companyName: '天河建设集团',
      noticeType: '缴款通知书',
      year: '2025年',
      amount: 240000,
      status: '已打印',
      generateDate: '2025-04-13'
    },
    {
      id: '5',
      companyName: '越秀金融服务有限公司',
      noticeType: '征收决定书',
      year: '2025年',
      amount: 90000,
      status: '未生成'
    },
    {
      id: '6',
      companyName: '黄埔实业有限公司',
      noticeType: '缴款通知书',
      year: '2025年',
      amount: 160000,
      status: '已生成',
      generateDate: '2025-04-12'
    }
  ];

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

        Button('批量打印')
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
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 列表 - 可滚动
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
                    this.selectedNotice = item;
                    this.generatePreviewContent(item);
                    this.openSheet(NoticeSheetType.PREVIEW);
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
    // TODO: 调用后端API生成通知单
    console.log('调用API生成通知单:', item.companyName, item.noticeType);
    
    const index = this.noticeList.findIndex(n => n.id === item.id);
    if (index !== -1) {
      const updatedList = this.noticeList.slice();
      updatedList[index] = {
        id: updatedList[index].id,
        companyName: updatedList[index].companyName,
        noticeType: updatedList[index].noticeType,
        year: updatedList[index].year,
        amount: updatedList[index].amount,
        status: '已生成',
        generateDate: new Date().toISOString().split('T')[0],
        pdfUrl: `https://api.example.com/notices/${item.id}.pdf` // 模拟PDF URL
      };
      this.noticeList = updatedList;
      
      promptAction.showToast({ message: '通知单生成成功，已发送至单位用户系统' });
    }
  }

  private handlePrint(item: NoticeItem) {
    const index = this.noticeList.findIndex(n => n.id === item.id);
    if (index !== -1) {
      const updatedList = this.noticeList.slice();
      updatedList[index] = {
        id: updatedList[index].id,
        companyName: updatedList[index].companyName,
        noticeType: updatedList[index].noticeType,
        year: updatedList[index].year,
        amount: updatedList[index].amount,
        status: '已打印'
      };
      this.noticeList = updatedList;
    }
  }

  private handlePreview(item: NoticeItem) {
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
    if (this.selectedItems.length === 0) {
      promptAction.showToast({ message: '请选择要生成的通知单' });
      return;
    }
    
    // 保存选中数量用于提示
    const generateCount = this.selectedItems.length;
    
    // TODO: 调用后端API批量生成
    console.log('批量生成通知单:', this.selectedItems);
    
    const updatedList = this.noticeList.slice();
    this.selectedItems.forEach(id => {
      const index = updatedList.findIndex(n => n.id === id);
      if (index !== -1) {
        updatedList[index] = {
          id: updatedList[index].id,
          companyName: updatedList[index].companyName,
          noticeType: updatedList[index].noticeType,
          year: updatedList[index].year,
          amount: updatedList[index].amount,
          status: '已生成',
          generateDate: new Date().toISOString().split('T')[0],
          pdfUrl: `https://api.example.com/notices/${id}.pdf`
        };
      }
    });
    this.noticeList = updatedList;
    this.selectedItems = [];
    
    promptAction.showToast({ message: `已成功生成${generateCount}份通知单` });
  }

  private handleBatchPrint() {
    if (this.selectedItems.length === 0) {
      promptAction.showToast({ message: '请选择要打印的通知单' });
      return;
    }
    
    // 保存选中数量用于提示
    const printCount = this.selectedItems.length;
    
    const updatedList = this.noticeList.slice();
    this.selectedItems.forEach(id => {
      const index = updatedList.findIndex(n => n.id === id);
      if (index !== -1) {
        updatedList[index] = {
          id: updatedList[index].id,
          companyName: updatedList[index].companyName,
          noticeType: updatedList[index].noticeType,
          year: updatedList[index].year,
          amount: updatedList[index].amount,
          status: '已打印'
        };
      }
    });
    this.noticeList = updatedList;
    this.selectedItems = [];
    
    promptAction.showToast({ message: `已成功打印${printCount}份通知单` });
  }
}
