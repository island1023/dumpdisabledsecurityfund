import { ColorConstants } from '../constants/ColorConstants';

interface FilterItem {
  id: string;
  name: string;
}

/**
 * 政务风格统计卡片组件
 */
@Component
export struct GovernmentStatCard {
  @Prop title: string = '';
  @Prop value: string | number = '';
  @Prop unit: string = '';
  @Prop icon: string = 'circle';
  @Prop color: string = ColorConstants.PRIMARY;
  @Prop trend: 'up' | 'down' | 'stable' | 'none' = 'none';
  @Prop trendValue: string = '';
  @Prop description: string = '';
  onCardClick?: () => void;

  build() {
    Column() {
      // 标题和图标区域
      Row() {
        Text(this.title)
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.' + this.icon.replace('.', '_')))
          .fontSize(20)
          .fontColor([this.color])
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 数值区域
      Row() {
        Text(typeof this.value === 'number' ? this.value.toLocaleString() : this.value)
          .fontSize(28)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)

        if (this.unit) {
          Text(this.unit)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ left: 4, top: 4 })
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 趋势和描述区域
      Row() {
        if (this.trend !== 'none') {
          Row() {
            Image(this.getTrendIcon())
              .width(12)
              .height(12)
              .fillColor(this.getTrendColor())
              .margin({ right: 4 })

            Text(this.trendValue)
              .fontSize(12)
              .fontColor(this.getTrendColor())
          }
          .margin({ right: 12 })
        }

        if (this.description) {
          Text(this.description)
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height(140)
    .padding(20)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .border({ width: 1, color: ColorConstants.BORDER })
    .shadow({
      radius: 4,
      color: '#00000008',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
  }

  private getTrendIcon(): string {
    switch (this.trend) {
      case 'up':
        return 'arrow.up';
      case 'down':
        return 'arrow.down';
      case 'stable':
        return 'minus';
      default:
        return 'minus';
    }
  }

  private getTrendColor(): string {
    switch (this.trend) {
      case 'up':
        return ColorConstants.SUCCESS;
      case 'down':
        return ColorConstants.DANGER;
      case 'stable':
        return ColorConstants.WARNING;
      default:
        return ColorConstants.TEXT_SECONDARY;
    }
  }
}

/**
 * 政务风格数据看板组件
 */
@Component
export struct GovernmentDataBoard {
  @Prop title: string = '数据看板';
  @Prop showFilter: boolean = true;
  @Prop filters: Array<FilterItem> = [];
  @Link activeFilter: string;
  @BuilderParam contentBuilder?: () => void;
  onFilterChange?: (filterId: string) => void;
  onMoreClick?: () => void;

  build() {
    Column() {
      // 标题和过滤区域
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        if (this.showFilter && this.filters.length > 0) {
          Row() {
            ForEach(this.filters, (filter: FilterItem) => {
              Text(filter.name)
                .fontSize(14)
                .fontColor(this.activeFilter === filter.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
                .fontWeight(this.activeFilter === filter.id ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.activeFilter === filter.id ? 'rgba(199, 28, 34, 0.1)' : Color.Transparent)
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => {
                  this.activeFilter = filter.id;
                  if (this.onFilterChange) {
                    this.onFilterChange(filter.id);
                  }
                })
            })
          }
        }

        if (this.onMoreClick) {
          Text('更多')
            .fontSize(14)
            .fontColor(ColorConstants.PRIMARY)
            .onClick(() => {
              if (this.onMoreClick) {
                this.onMoreClick();
              }
            })
        }
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 内容区域（由子组件填充）
      Column() {
        if (this.contentBuilder) {
          this.contentBuilder()
        }
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .border({ width: 1, color: ColorConstants.BORDER })
    .shadow({
      radius: 6,
      color: '#0000000A',
      offsetX: 0,
      offsetY: 3
    })
  }
}

/**
 * 政务风格表单卡片组件
 */
@Component
export struct GovernmentFormCard {
  @Prop title: string = '';
  @Prop required: boolean = false;
  @Prop error: boolean = false;
  @Prop errorMessage: string = '';
  @Prop showActions: boolean = false;
  @BuilderParam contentBuilder?: () => void;
  onSave?: () => void;
  onCancel?: () => void;

  build() {
    Column() {
      // 标题区域
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        if (this.required) {
          Text('*')
            .fontSize(16)
            .fontColor(ColorConstants.PRIMARY)
            .margin({ left: 4 })
        }

        if (this.error) {
          Row() {
            SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
              .fontSize(16)
              .fontColor([ColorConstants.DANGER])
              .margin({ right: 4 })

            Text(this.errorMessage)
              .fontSize(12)
              .fontColor(ColorConstants.DANGER)
          }
        }
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 表单内容区域
      Column() {
        if (this.contentBuilder) {
          this.contentBuilder()
        }
      }
      .width('100%')

      // 操作按钮区域
      if (this.showActions) {
        Row() {
          Button('取消')
            .width(120)
            .height(40)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8)
            .onClick(() => {
              if (this.onCancel) {
                this.onCancel();
              }
            })

          Blank()
            .layoutWeight(1)

          Button('保存')
            .width(120)
            .height(40)
            .fontSize(14)
            .fontColor(ColorConstants.BG_CARD)
            .backgroundColor(ColorConstants.PRIMARY)
            .borderRadius(8)
            .onClick(() => {
              if (this.onSave) {
                this.onSave();
              }
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .border({ width: 1, color: this.error ? ColorConstants.DANGER : ColorConstants.BORDER })
    .shadow({
      radius: 4,
      color: '#00000008',
      offsetX: 0,
      offsetY: 2
    })
  }
}

/**
 * 政务风格表格卡片组件
 */
@Component
export struct GovernmentTableCard {
  @Prop title: string = '';
  @Prop showHeader: boolean = true;
  @Prop showPagination: boolean = false;
  @Prop total: number = 0;
  @Prop pageSize: number = 10;
  @Prop currentPage: number = 1;
  @BuilderParam contentBuilder?: () => void;
  onPageChange?: (page: number) => void;
  onExport?: () => void;

  build() {
    Column() {
      // 标题和操作区域
      if (this.showHeader) {
        Row() {
          Text(this.title)
            .fontSize(16)
            .fontColor(ColorConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          if (this.onExport) {
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_up'))
                .fontSize(16)
                .fontColor([ColorConstants.PRIMARY])
                .margin({ right: 4 })

              Text('导出')
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(199, 28, 34, 0.1)')
            .borderRadius(8)
            .onClick(() => {
              if (this.onExport) {
                this.onExport();
              }
            })
            .margin({ right: 12 })
          }
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      // 表格内容区域
      Column() {
        if (this.contentBuilder) {
          this.contentBuilder()
        }
      }
      .width('100%')

      // 分页区域
      if (this.showPagination && this.total > 0) {
        Row() {
          Text(`共 ${this.total} 条`)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)

          Blank()
            .layoutWeight(1)

          Row() {
            // 上一页
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(20)
              .fontColor([this.currentPage > 1 ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY])
              .margin({ right: 16 })
              .onClick(() => {
                if (this.currentPage > 1 && this.onPageChange) {
                  this.onPageChange(this.currentPage - 1);
                }
              })

            // 页码显示
            Text(`${this.currentPage}`)
              .fontSize(14)
              .fontColor(ColorConstants.PRIMARY)
              .fontWeight(FontWeight.Bold)
              .margin({ right: 4 })

            Text(`/ ${Math.ceil(this.total / this.pageSize)}`)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .margin({ right: 16 })

            // 下一页
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(20)
              .fontColor([this.currentPage < Math.ceil(this.total / this.pageSize) ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY])
              .onClick(() => {
                if (this.currentPage < Math.ceil(this.total / this.pageSize) && this.onPageChange) {
                  this.onPageChange(this.currentPage + 1);
                }
              })
          }
        }
        .width('100%')
        .margin({ top: 20 })
        .padding({ top: 16 })
        .border({ width: { top: 1 }, color: ColorConstants.BORDER })
      }
    }
    .width('100%')
    .padding(24)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .border({ width: 1, color: ColorConstants.BORDER })
    .shadow({
      radius: 4,
      color: '#00000008',
      offsetX: 0,
      offsetY: 2
    })
  }
}

/**
 * 政务风格通知卡片组件
 */
@Component
export struct GovernmentNoticeCard {
  @Prop title: string = '';
  @Prop type: 'info' | 'success' | 'warning' | 'error' = 'info';
  @Prop time: string = '';
  @Prop read: boolean = false;
  onCardClick?: () => void;

  build() {
    Row() {
      // 类型图标
      Column() {
        SymbolGlyph($r('sys.symbol.' + this.getTypeIcon().replace('.', '_')))
          .fontSize(20)
          .fontColor([this.getTypeColor()])
      }
      .width(40)
      .height(40)
      .backgroundColor(this.getTypeBackground())
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // 内容区域
      Column() {
        Text(this.title)
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(this.read ? FontWeight.Normal : FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })

        if (this.time) {
          Text(this.time)
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 未读标记
      if (!this.read) {
        Column()
          .width(8)
          .height(8)
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(4)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(8)
    .border({ width: 1, color: ColorConstants.BORDER })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
  }

  private getTypeIcon(): string {
    switch (this.type) {
      case 'success':
        return 'checkmark.circle';
      case 'warning':
        return 'exclamationmark.triangle';
      case 'error':
        return 'xmark.circle';
      default:
        return 'info.circle';
    }
  }

  private getTypeColor(): string {
    switch (this.type) {
      case 'success':
        return ColorConstants.SUCCESS;
      case 'warning':
        return ColorConstants.WARNING;
      case 'error':
        return ColorConstants.DANGER;
      default:
        return ColorConstants.PRIMARY;
    }
  }

  private getTypeBackground(): string {
    switch (this.type) {
      case 'success':
        return 'rgba(0, 158, 95, 0.1)';
      case 'warning':
        return 'rgba(242, 153, 0, 0.1)';
      case 'error':
        return 'rgba(166, 32, 25, 0.1)';
      default:
        return 'rgba(199, 28, 34, 0.1)';
    }
  }
}
