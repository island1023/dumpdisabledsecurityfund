// entry/src/main/ets/pages/ImagePreviewPage.ets
import { ColorConstants } from '../common/constants/ColorConstants';
import { router } from '@kit.ArkUI';

// 🔴 定义路由参数接口，解决 "Property does not exist on type 'Object'"
interface PreviewParams {
  imageUrl: string;
  fileName: string;
}

@Entry
@Component
struct ImagePreviewPage { // 🔴 在 @Entry 页面通常不使用 export 关键字
  @State imageUrl: string = '';
  @State fileName: string = '';

  aboutToAppear() {
    // 🔴 显式转换路由参数类型
    const params = router.getParams() as PreviewParams;
    if (params) {
      this.imageUrl = params.imageUrl;
      this.fileName = params.fileName;
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          // 🔴 检查 ColorConstants 是否有 TEXT_PRIMARY，若没有请改为 TEXT_TITLE 或其他已有常量
          .fontColor(ColorConstants.TEXT_TITLE)
          .backgroundColor(Color.Transparent) // 使按钮背景透明
          .margin({ left: 16 })
          .onClick(() => {
            router.back();
          })

        Text(this.fileName || '图片预览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 占位，保持标题居中
        Blank().width(40).margin({ right: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(ColorConstants.BG_CARD)
      .border({ width: { bottom: 1 }, color: ColorConstants.BORDER })

      // 🔴 修正组件名：使用 Scroll 而非 ScrollView
      Scroll() {
        Column() {
          Image(this.imageUrl)
            .width('90%')
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
            .margin({ top: 20, bottom: 20 })
            // 🔴 增加同步占位图，防止加载失败
            //.alt($r('app.media.app_icon'))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto) // 替代 ScrollerController 的部分功能
      .backgroundColor(ColorConstants.BG_PAGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
  }
}