import { ColorConstants } from '../../common/constants/ColorConstants';
import {
  LeaderService,
  LeaderArchiveListItem,
  LeaderArchiveDetail,
  LeaderPaymentArchiveRow,
  LeaderReliefArchiveRow
} from '../../services/LeaderService';
import { promptAction } from '@kit.ArkUI';

type UnitBasicInfo = LeaderArchiveListItem;

// 弹窗类型枚举
enum ArchiveSheetType {
  NONE,
  PAYMENT_RECORDS
}

@Component
export struct LeaderArchivePage {
  @Prop @Watch('onScopeChanged') selectedRegionId: number = 0;
  @State searchKeyword: string = '';
  @State selectedDistrict: string = 'all';
  @State isSheetShow: boolean = false;
  @State activeSheet: ArchiveSheetType = ArchiveSheetType.NONE;
  @State selectedUnit: UnitBasicInfo | null = null;
  @State unitList: UnitBasicInfo[] = [];
  @State listLoading: boolean = false;
  @State detailLoading: boolean = false;
  @State loadedDetail: LeaderArchiveDetail | null = null;

  aboutToAppear(): void {
    this.loadCompanyList('');
  }

  private onScopeChanged(): void {
    void this.loadCompanyList(this.searchKeyword);
  }

  async loadCompanyList(keyword: string): Promise<void> {
    this.listLoading = true;
    try {
      this.unitList = await LeaderService.getArchiveCompanies(keyword, 1, 100);
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '加载失败' });
      this.unitList = [];
    } finally {
      this.listLoading = false;
    }
  }

  private openArchiveDetail(unit: UnitBasicInfo): void {
    this.selectedUnit = unit;
    this.loadedDetail = null;
    this.activeSheet = ArchiveSheetType.PAYMENT_RECORDS;
    this.isSheetShow = true;
    this.detailLoading = true;
    void this.fetchArchiveDetail(unit.id);
  }

  private async fetchArchiveDetail(companyId: string): Promise<void> {
    try {
      this.loadedDetail = await LeaderService.getArchiveDetail(companyId);
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '加载详情失败' });
    } finally {
      this.detailLoading = false;
    }
  }

  // 获取筛选后的列表
  private getFilteredList(): UnitBasicInfo[] {
    let list = this.unitList;

    if (this.selectedRegionId > 0) {
      const regionNameMap: Record<number, string> = {
        1: '锦江区',
        2: '青羊区',
        3: '金牛区',
        4: '武侯区',
        5: '成华区',
        6: '龙泉驿区',
        7: '青白江区',
        8: '新都区',
        9: '温江区',
        10: '双流区',
        11: '郫都区',
        12: '新津区',
        13: '金堂县'
      };
      const targetDistrict = regionNameMap[this.selectedRegionId] || '';
      if (targetDistrict) {
        list = list.filter(unit => unit.district === targetDistrict);
      }
    } else if (this.selectedDistrict !== 'all') {
      list = list.filter(unit => unit.district === this.selectedDistrict);
    }

    if (this.searchKeyword) {
      list = list.filter(unit => unit.companyName.includes(this.searchKeyword));
    }

    return list;
  }

  // 获取状态颜色
  private getStatusColor(status: string): string {
    switch (status) {
      case '已缴':
      case '已通过':
        return ColorConstants.SUCCESS;
      case '部分缴纳':
        return ColorConstants.WARNING;
      case '未缴':
      case '审批中':
        return ColorConstants.WARNING;
      case '已拒绝':
        return ColorConstants.DANGER;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  // 获取状态背景色
  private getStatusBgColor(status: string): string {
    switch (status) {
      case '已缴':
      case '已通过':
        return 'rgba(0, 158, 95, 0.1)';
      case '部分缴纳':
        return 'rgba(245, 158, 11, 0.1)';
      case '未缴':
      case '审批中':
        return 'rgba(245, 158, 11, 0.1)';
      case '已拒绝':
        return 'rgba(166, 32, 25, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  build() {
    Column() {
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
            this.loadCompanyList(this.searchKeyword);
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.listLoading) {
        Text('加载中…')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: 8 })
      }

      // 列表 - 可滚动
      Scroll() {
        Column() {
          if (!this.listLoading && this.getFilteredList().length === 0) {
            Text('暂无单位数据')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .width('100%')
              .padding({ top: 24 })
          }
          ForEach(this.getFilteredList(), (unit: UnitBasicInfo) => {
            Column() {
              // 单位名称和所属区
              Row() {
                Column() {
                  Text(unit.companyName)
                    .fontSize(16)
                    .fontColor(ColorConstants.TEXT_TITLE)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })

                  Text(unit.district)
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('查看档案')
                  .fontSize(13)
                  .fontColor(ColorConstants.PRIMARY)
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.openArchiveDetail(unit);
                  })
              }
              .width('100%')
              .margin({ bottom: 12 })

              // 详细信息
              Row() {
                Column() {
                  Text('在职职工')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`${unit.employeeCount}人`)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)

                Column() {
                  Text('残疾职工')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`${unit.disabledCount}人`)
                    .fontSize(14)
                    .fontColor(ColorConstants.PRIMARY)
                }
                .layoutWeight(1)

                Column() {
                  Text('征收年度')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(unit.collectionYear)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
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
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      title: { title: '单位档案详情' },
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = ArchiveSheetType.NONE;
        this.selectedUnit = null;
        this.loadedDetail = null;
      }
    })
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === ArchiveSheetType.PAYMENT_RECORDS) {
        if (this.detailLoading) {
          Text('加载档案详情…')
            .fontSize(15)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .padding({ top: 24, bottom: 24 })
        } else if (this.loadedDetail) {
          Scroll() {
            this.buildArchiveDetailBlock(this.loadedDetail)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        } else {
          Text('暂无详情')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .padding({ top: 24 })
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildArchiveDetailBlock(detail: LeaderArchiveDetail) {
    Column() {
      // 单位基本信息
      Text('单位基本信息')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        Row() {
          Text('单位名称：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.companyName)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('统一社会信用代码：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.creditCode)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('法定代表人：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.legalPerson)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('所属区县：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.district || '—')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('行业：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.industry || '—')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('注册地：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.registerAddress)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('成立日期：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.establishDate)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('联系电话：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.phone)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('在职职工数：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(`${detail.employeeCount}人`)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('残疾职工数：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(`${detail.disabledCount}人`)
            .fontSize(14)
            .fontColor(ColorConstants.PRIMARY)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('征收年度：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(detail.collectionYear)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorConstants.BG_PAGE)
      .borderRadius(8)
      .margin({ bottom: 20 })

      // 历年缴纳记录
      Text('历年缴纳记录')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        ForEach(detail.paymentRecords, (record: LeaderPaymentArchiveRow) => {
          Row() {
            Column() {
              Text(record.year)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)

            Column() {
              Text(`应缴：¥${(record.payableAmount / 10000).toFixed(1)}万`)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
            }
            .layoutWeight(1)

            Column() {
              Text(`实缴：¥${(record.paidAmount / 10000).toFixed(1)}万`)
                .fontSize(13)
                .fontColor(ColorConstants.SUCCESS)
            }
            .layoutWeight(1)

            Text(record.status)
              .fontSize(13)
              .fontColor(this.getStatusColor(record.status))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.getStatusBgColor(record.status))
              .borderRadius(12)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 减免缓状态
      Text('减免缓状态')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        ForEach(detail.reliefStatuses, (relief: LeaderReliefArchiveRow) => {
          Column() {
            Row() {
              Text(relief.type)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Medium)

              Text(relief.status)
                .fontSize(12)
                .fontColor(this.getStatusColor(relief.status))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.getStatusBgColor(relief.status))
                .borderRadius(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('原因：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(relief.reason)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('期限：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`${relief.startDate} 至 ${relief.endDate}`)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('金额：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(relief.amount / 10000).toFixed(1)}万元`)
                .fontSize(13)
                .fontColor(ColorConstants.WARNING)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }
}
