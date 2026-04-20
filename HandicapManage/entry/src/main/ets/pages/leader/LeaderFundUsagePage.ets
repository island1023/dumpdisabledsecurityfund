import { ColorConstants } from '../../common/constants/ColorConstants';

// 保障金使用项目
interface FundUsageItem {
  id: string;
  projectName: string;
  projectType: string; // '就业服务' | '职业培训' | '康复服务' | '无障碍改造' | '其他'
  district: string;
  amount: number;
  usageDate: string;
  status: string; // '已拨付' | '拨付中' | '已验收'
  description: string;
  beneficiaryCount?: number; // 受益人数
}

// 弹窗类型枚举
enum FundSheetType {
  NONE,
  DETAIL
}

@Component
export struct LeaderFundUsagePage {
  @State searchKeyword: string = '';
  @State selectedDistrict: string = 'all';
  @State isSheetShow: boolean = false;
  @State activeSheet: FundSheetType = FundSheetType.NONE;
  @State selectedFund: FundUsageItem | null = null;
  @State filterType: string = 'all'; // 筛选类型

  // 模拟数据
  @State fundList: FundUsageItem[] = [
    {
      id: '1',
      projectName: '残疾人就业技能培训项目',
      projectType: '职业培训',
      district: '天河区',
      amount: 500000,
      usageDate: '2025-03-15',
      status: '已拨付',
      description: '为残疾人提供职业技能培训，提升就业能力',
      beneficiaryCount: 150
    },
    {
      id: '2',
      projectName: '社区康复服务中心建设',
      projectType: '康复服务',
      district: '越秀区',
      amount: 800000,
      usageDate: '2025-02-20',
      status: '已拨付',
      description: '建设社区康复服务设施，提供康复训练服务',
      beneficiaryCount: 300
    },
    {
      id: '3',
      projectName: '残疾人家庭无障碍改造',
      projectType: '无障碍改造',
      district: '白云区',
      amount: 350000,
      usageDate: '2025-04-10',
      status: '拨付中',
      description: '为残疾人家庭进行无障碍设施改造',
      beneficiaryCount: 80
    },
    {
      id: '4',
      projectName: '残疾人就业援助服务',
      projectType: '就业服务',
      district: '天河区',
      amount: 200000,
      usageDate: '2025-01-25',
      status: '已验收',
      description: '提供就业咨询、职业介绍等就业援助服务',
      beneficiaryCount: 200
    },
    {
      id: '5',
      projectName: '残疾人文化体育活动',
      projectType: '其他',
      district: '黄埔区',
      amount: 150000,
      usageDate: '2025-03-30',
      status: '已拨付',
      description: '组织残疾人参与文化体育活动，丰富精神文化生活',
      beneficiaryCount: 500
    },
    {
      id: '6',
      projectName: '辅具适配与发放服务',
      projectType: '康复服务',
      district: '越秀区',
      amount: 280000,
      usageDate: '2025-04-05',
      status: '已拨付',
      description: '为残疾人适配和发放辅助器具',
      beneficiaryCount: 120
    }
  ];

  // 打开弹窗
  private openSheet(type: FundSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  // 获取筛选后的列表
  private getFilteredList(): FundUsageItem[] {
    let list = this.fundList;

    if (this.selectedDistrict !== 'all') {
      list = list.filter(item => item.district === this.selectedDistrict);
    }

    if (this.filterType !== 'all') {
      list = list.filter(item => item.projectType === this.filterType);
    }

    if (this.searchKeyword) {
      list = list.filter(item => item.projectName.includes(this.searchKeyword));
    }

    return list;
  }

  // 获取状态颜色
  private getStatusColor(status: string): string {
    switch (status) {
      case '已拨付':
      case '已验收':
        return ColorConstants.SUCCESS;
      case '拨付中':
        return ColorConstants.WARNING;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  // 获取状态背景色
  private getStatusBgColor(status: string): string {
    switch (status) {
      case '已拨付':
      case '已验收':
        return 'rgba(0, 158, 95, 0.1)';
      case '拨付中':
        return 'rgba(245, 158, 11, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  build() {
    Column() {
      // 筛选条件
      Row() {
        Text('筛选：')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ right: 8 })

        Row() {
          Text('全部')
            .fontSize(14)
            .fontColor(this.filterType === 'all' ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .fontWeight(this.filterType === 'all' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.filterType === 'all' ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.filterType = 'all';
            })

          Text('就业服务')
            .fontSize(14)
            .fontColor(this.filterType === '就业服务' ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .fontWeight(this.filterType === '就业服务' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.filterType === '就业服务' ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.filterType = '就业服务';
            })

          Text('康复服务')
            .fontSize(14)
            .fontColor(this.filterType === '康复服务' ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .fontWeight(this.filterType === '康复服务' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.filterType === '康复服务' ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
            .borderRadius(16)
            .onClick(() => {
              this.filterType = '康复服务';
            })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索项目名称...', text: this.searchKeyword })
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
          ForEach(this.getFilteredList(), (item: FundUsageItem) => {
            Column() {
              // 头部：项目名称和状态
              Row() {
                Column() {
                  Text(item.projectName)
                    .fontSize(16)
                    .fontColor(ColorConstants.TEXT_TITLE)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })

                  Text(item.district)
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(item.status)
                  .fontSize(13)
                  .fontColor(this.getStatusColor(item.status))
                  .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                  .backgroundColor(this.getStatusBgColor(item.status))
                  .borderRadius(12)
              }
              .width('100%')
              .margin({ bottom: 12 })

              // 详细信息
              Row() {
                Column() {
                  Text('项目类型')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(item.projectType)
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
                  Text('拨付日期')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(item.usageDate)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)

                Column() {
                  Text('受益人数')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`${item.beneficiaryCount || 0}人`)
                    .fontSize(14)
                    .fontColor(ColorConstants.SUCCESS)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
              .margin({ bottom: 12 })

              // 项目描述
              Text(item.description)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_BODY)
                .lineHeight(20)
                .width('100%')
                .margin({ bottom: 12 })

              // 查看详情按钮
              Button('查看详情')
                .width('100%')
                .height(36)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(ColorConstants.PRIMARY)
                .borderRadius(6)
                .onClick(() => {
                  this.selectedFund = item;
                  this.openSheet(FundSheetType.DETAIL);
                })
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
      title: { title: '项目详情' },
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = FundSheetType.NONE;
        this.selectedFund = null;
      }
    })
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === FundSheetType.DETAIL) {
        this.buildDetailDialog()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildDetailDialog() {
    if (this.selectedFund) {
      Scroll() {
        Column() {
          Text(this.selectedFund.projectName)
            .fontSize(20)
            .fontColor(ColorConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          Column() {
            Row() {
              Text('项目类型：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedFund.projectType)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('所属区域：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedFund.district)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('拨付金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(this.selectedFund.amount / 10000).toFixed(1)}万元`)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('拨付日期：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedFund.usageDate)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('当前状态：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedFund.status)
                .fontSize(14)
                .fontColor(this.getStatusColor(this.selectedFund.status))
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row() {
              Text('受益人数：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`${this.selectedFund.beneficiaryCount || 0}人`)
                .fontSize(14)
                .fontColor(ColorConstants.SUCCESS)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Text('项目描述')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ bottom: 8 })

            Text(this.selectedFund.description)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_BODY)
              .lineHeight(24)
              .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      }
      .width('100%')
    }
  }
}
