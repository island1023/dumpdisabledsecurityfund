import { ColorConstants } from '../../common/constants/ColorConstants';
import { CollectionService } from '../../services/CollectionService';

interface CollectionItem {
  id: string;
  companyName: string;
  year: string;
  disabledCount: number;
  payableAmount: number;
  paidAmount: number;
  status: string;
  taxDataMatch: boolean;
  voucher?: string;
  creditCode?: string;
  registerAddress?: string;
  legalPerson?: string;
  employeeCount?: number;
  establishDate?: string;
  phone?: string;
}

interface TabItem { id: string; name: string; }

interface StatisticsData {
  totalUnits: number;
  paidUnits: number;
  unpaidUnits: number;
  totalAmount: number;
  paidAmount: number;
}

enum CollectionSheetType {
  NONE,
  DETAIL,
  VERIFY
}

@Component
export struct CollectionPage {
  @State searchKeyword: string = '';
  @State selectedYear: number = new Date().getFullYear();
  @State isSheetShow: boolean = false;
  @State activeSheet: CollectionSheetType = CollectionSheetType.NONE;
  @State selectedCollection: CollectionItem | null = null;
  @State voucherInput: string = '';
  @State verifyReason: string = '';
  @State filterStatus: string = 'all';
  @State collectionList: CollectionItem[] = [];
  @State isLoading: boolean = false;
  @State statistics: StatisticsData = { totalUnits: 0, paidUnits: 0, unpaidUnits: 0, totalAmount: 0, paidAmount: 0 };

  aboutToAppear() {
    this.loadCollectionList();
    this.loadStatistics();
  }

  async loadCollectionList() {
    this.isLoading = true;
    try {
      const result = await CollectionService.getCollectionList({
        year: this.selectedYear,
        status: this.filterStatus === 'all' ? undefined : this.filterStatus,
        keyword: this.searchKeyword || undefined,
        pageNum: 1,
        pageSize: 50
      });
      const mappedList: CollectionItem[] = [];
      for (let i = 0; i < result.list.length; i++) {
        const item = result.list[i];
        mappedList.push({
          id: item.id,
          companyName: item.unitName,
          year: item.year + '年',
          disabledCount: item.disabledEmployeeCount,
          payableAmount: item.payableAmount,
          paidAmount: item.paidAmount,
          status: this.convertStatus(item.status),
          taxDataMatch: item.status === 'PAID',
          voucher: item.paidAmount >= item.payableAmount ? 'TX' + Date.now() : undefined
        });
      }
      this.collectionList = mappedList;
    } catch (error) {
      console.error('加载征收列表失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async loadStatistics() {
    try {
      const stats = await CollectionService.getCollectionStatistics(this.selectedYear);
      const statsData: StatisticsData = {
        totalUnits: stats.totalUnits,
        paidUnits: stats.paidUnits,
        unpaidUnits: stats.unpaidUnits,
        totalAmount: stats.totalAmount,
        paidAmount: stats.paidAmount
      };
      this.statistics = statsData;
    } catch (error) {
      console.error('加载统计数据失败:', error);
    }
  }

  private convertStatus(status: string): string {
    const statusMap: Record<string, string> = {
      'PAID': '已缴',
      'UNPAID': '未缴',
      'PARTIAL': '部分缴纳'
    };
    return statusMap[status] || status;
  }

  private openSheet(type: CollectionSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    Column() {
      // 统计卡片
      Row() {
        this.buildStatCard('应缴单位', this.statistics.totalUnits, '家', ColorConstants.PRIMARY)
        this.buildStatCard('已缴单位', this.statistics.paidUnits, '家', ColorConstants.SUCCESS)
        this.buildStatCard('应缴金额', this.statistics.totalAmount / 10000, '万元', ColorConstants.WARNING)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 筛选条件
      Row() {
        Text('筛选：')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ right: 8 })

        Row() {
          Text('全部')
            .fontSize(14)
            .fontColor(this.filterStatus === 'all' ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .fontWeight(this.filterStatus === 'all' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.filterStatus === 'all' ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.filterStatus = 'all';
              this.loadCollectionList();
            })

          Text('未缴完')
            .fontSize(14)
            .fontColor(this.filterStatus === 'unpaid' ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .fontWeight(this.filterStatus === 'unpaid' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.filterStatus === 'unpaid' ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
            .borderRadius(16)
            .onClick(() => {
              this.filterStatus = 'unpaid';
              this.loadCollectionList();
            })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 年度选择和搜索
      Row() {
        Row() {
          Text('年度：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ right: 8 })

          Row() {
            ForEach([2025, 2024, 2023], (year: number) => {
              Text(year.toString())
                .fontSize(14)
                .fontColor(this.selectedYear === year ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
                .fontWeight(this.selectedYear === year ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.selectedYear === year ? 'rgba(199, 28, 34, 0.1)' : ColorConstants.BG_PAGE)
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedYear = year;
                  this.loadCollectionList();
                  this.loadStatistics();
                })
            })
          }
        }
        .layoutWeight(1)

        TextInput({ placeholder: '搜索单位名称...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .width(200)
          .height(40)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_CARD)
          .border({ width: 1, color: ColorConstants.BORDER })
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ left: 16 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 列表
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.collectionList.length === 0) {
        Column() {
          Text('暂无数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.collectionList, (item: CollectionItem) => {
              Column() {
                Row() {
                  Text(item.companyName)
                    .fontSize(16)
                    .fontColor(ColorConstants.TEXT_TITLE)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)

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
                    Text('残疾职工')
                      .fontSize(12)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                      .margin({ bottom: 4 })
                    Text(`${item.disabledCount}人`)
                      .fontSize(14)
                      .fontColor(ColorConstants.TEXT_TITLE)
                      .fontWeight(FontWeight.Medium)
                  }
                  .layoutWeight(1)

                  Column() {
                    Text('税务匹配')
                      .fontSize(12)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                      .margin({ bottom: 4 })
                    Text(item.taxDataMatch ? '已匹配' : '未匹配')
                      .fontSize(14)
                      .fontColor(item.taxDataMatch ? ColorConstants.SUCCESS : ColorConstants.WARNING)
                      .fontWeight(FontWeight.Medium)
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 16 })

                Row() {
                  Column() {
                    Text('应缴金额')
                      .fontSize(12)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                      .margin({ bottom: 4 })
                    Text(`¥${(item.payableAmount / 10000).toFixed(1)}万`)
                      .fontSize(16)
                      .fontColor(ColorConstants.PRIMARY)
                      .fontWeight(FontWeight.Bold)
                  }
                  .layoutWeight(1)

                  Column() {
                    Text('已缴金额')
                      .fontSize(12)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                      .margin({ bottom: 4 })
                    Text(`¥${(item.paidAmount / 10000).toFixed(1)}万`)
                      .fontSize(16)
                      .fontColor(item.paidAmount === item.payableAmount ? ColorConstants.SUCCESS : ColorConstants.WARNING)
                      .fontWeight(FontWeight.Bold)
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(16)
                .backgroundColor(ColorConstants.BG_PAGE)
                .borderRadius(8)
                .margin({ bottom: 16 })

                Row() {
                  Button('查看')
                    .layoutWeight(1)
                    .height(36)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .backgroundColor(ColorConstants.BG_PAGE)
                    .border({ width: 1, color: ColorConstants.BORDER })
                    .borderRadius(6)
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.selectedCollection = item;
                      this.openSheet(CollectionSheetType.DETAIL);
                    })

                  if (item.status !== '已缴') {
                    Button('核销')
                      .layoutWeight(1)
                      .height(36)
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor(ColorConstants.SUCCESS)
                      .borderRadius(6)
                      .margin({ left: 8 })
                      .onClick(() => {
                        this.selectedCollection = item;
                        this.voucherInput = '';
                        this.verifyReason = '';
                        this.openSheet(CollectionSheetType.VERIFY);
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
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = CollectionSheetType.NONE;
        this.selectedCollection = null;
        this.voucherInput = '';
      }
    })
  }

  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === CollectionSheetType.DETAIL) {
        this.buildDetailDialog()
      } else if (this.activeSheet === CollectionSheetType.VERIFY) {
        this.buildVerifyDialog()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildStatCard(title: string, value: number, unit: string, color: string) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .margin({ bottom: 8 })

      Row() {
        Text(value.toFixed(1))
          .fontSize(24)
          .fontColor(color)
          .fontWeight(FontWeight.Bold)
        Text(unit)
          .fontSize(12)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ left: 2, bottom: 4 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildVerifyDialog() {
    Scroll() {
      Column() {
        if (this.selectedCollection) {
          Text('缴款核销')
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
              Text(this.selectedCollection.companyName)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('应缴金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(this.selectedCollection.payableAmount / 10000).toFixed(1)}万元`)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('已缴金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(this.selectedCollection.paidAmount / 10000).toFixed(1)}万元`)
                .fontSize(14)
                .fontColor(ColorConstants.SUCCESS)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('待核销金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${((this.selectedCollection.payableAmount - this.selectedCollection.paidAmount) / 10000).toFixed(1)}万元`)
                .fontSize(14)
                .fontColor(ColorConstants.WARNING)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 16 })

          Text('缴款凭证号（可选）')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入缴款凭证号', text: this.voucherInput })
            .onChange((value: string) => {
              this.voucherInput = value;
            })
            .width('100%')
            .height(44)
            .fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .margin({ bottom: 16 })

          Text('核销理由（必填）')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ bottom: 8 })

          TextArea({ placeholder: '请输入核销理由，例如：根据XX政策减免、企业经营困难缓缴等', text: this.verifyReason })
            .onChange((value: string) => {
              this.verifyReason = value;
            })
            .width('100%')
            .height(100)
            .fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .backgroundColor(ColorConstants.BG_PAGE)
              .border({ width: 1, color: ColorConstants.BORDER })
              .borderRadius(8)
              .margin({ right: 8 })
              .onClick(() => {
                this.isSheetShow = false;
              })

            Button('确认核销')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor(ColorConstants.SUCCESS)
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.handleConfirmVerify();
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
    }
    .width('100%')
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case '已缴':
        return ColorConstants.SUCCESS;
      case '未缴':
        return ColorConstants.WARNING;
      case '部分缴纳':
        return ColorConstants.PRIMARY;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case '已缴':
        return 'rgba(0, 158, 95, 0.1)';
      case '未缴':
        return 'rgba(245, 158, 11, 0.1)';
      case '部分缴纳':
        return 'rgba(199, 28, 34, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  private async handleConfirmVerify() {
    if (!this.verifyReason.trim()) {
      console.log('请填写核销理由');
      return;
    }

    if (this.selectedCollection) {
      try {
        await CollectionService.verifyPayment(
          this.selectedCollection.id,
          this.selectedCollection.payableAmount - this.selectedCollection.paidAmount,
          this.voucherInput
        );
        this.loadCollectionList();
        this.loadStatistics();
        this.isSheetShow = false;
      } catch (error) {
        console.error('核销失败:', error);
      }
    }
  }

  @Builder
  buildDetailDialog() {
    Scroll() {
      Column() {
        if (this.selectedCollection) {
          Column() {
            Text('单位基本信息')
              .fontSize(16)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 12 })

            Row() {
              Text('单位名称：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.companyName)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('统一社会信用代码：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.creditCode || '-')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('法定代表人：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.legalPerson || '-')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('注册地：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.registerAddress || '-')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('成立日期：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.establishDate || '-')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('联系电话：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.phone || '-')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('在职职工数：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`${this.selectedCollection.employeeCount || 0}人`)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('残疾职工数：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`${this.selectedCollection.disabledCount}人`)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('征收年度：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.year)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('税务数据匹配：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedCollection.taxDataMatch ? '已匹配' : '未匹配')
                .fontSize(14)
                .fontColor(this.selectedCollection.taxDataMatch ? ColorConstants.SUCCESS : ColorConstants.WARNING)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 16 })

          Column() {
            Text('金额信息')
              .fontSize(16)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 12 })

            Row() {
              Text('应缴金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(this.selectedCollection.payableAmount / 10000).toFixed(1)}万元`)
                .fontSize(16)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('已缴金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(this.selectedCollection.paidAmount / 10000).toFixed(1)}万元`)
                .fontSize(16)
                .fontColor(ColorConstants.SUCCESS)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('未缴金额：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${((this.selectedCollection.payableAmount - this.selectedCollection.paidAmount) / 10000).toFixed(1)}万元`)
                .fontSize(16)
                .fontColor(this.selectedCollection.payableAmount === this.selectedCollection.paidAmount ? ColorConstants.SUCCESS : ColorConstants.WARNING)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 16 })

          if (this.selectedCollection.voucher) {
            Column() {
              Text('缴款凭证号')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
                .margin({ bottom: 8 })
              Text(this.selectedCollection.voucher)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
          }
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
    }
    .width('100%')
  }
}
