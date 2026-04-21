import { ColorConstants } from '../../common/constants/ColorConstants';
import { GovernmentTableCard } from '../../common/components/GovernmentCardComponents';

/**
 * 资金监管页面
 */
@Component
export struct SupervisionPage {
  build() {
    Column() {
      GovernmentTableCard({
        title: '资金监管',
        showHeader: true,
        showPagination: false
      }) {
        Column() {
          Text('资金监管功能开发中...')
            .fontSize(16)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
    .padding({ left: 24, right: 24, top: 16, bottom: 16 })
  }
}