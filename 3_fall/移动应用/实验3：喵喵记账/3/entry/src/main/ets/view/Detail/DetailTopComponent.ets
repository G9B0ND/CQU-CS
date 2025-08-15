
import { HomeStore } from '../../Viewmodel/HomeViewModel';
import { CommonConstants as Const, DetailType } from '../../common/constants/CommonConstants';
import DayInfo from '../../Viewmodel/DayInfo';
import { IncomeList } from '../../model/CategoryInitList';

// 明细页展示结余信息
@Component
@Preview
export default struct DetailTopView {
  @Link homeStore: HomeStore;
  @Link detailType: string;


  build() {
    Column() {
      Column() {
        Row() {
          Text(this.getTitle() + '结余')
            .fontSize(Const.DEFAULT_24)
          Text('￥ ' + this.homeStore.getCustomBalance())
            .fontSize(Const.DEFAULT_24)
            .fontColor(Color.Red)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width(Const.THOUSANDTH_900)
        .margin({right:'2%'})
        .layoutWeight(2)

        Row() {
          Text(this.getTitle() + '支出')
            .width(Const.THOUSANDTH_250)
            .fontSize(Const.DEFAULT_16)
            .fontColor(Color.Gray)
          Row() {
            Row()
              .width(this.getExpense('expense'))
              .height(Const.DEFAULT_6)
              .backgroundColor('rgba(255, 195, 0, 1.00)')
              .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
          }
          .backgroundColor('#F1F3F5')
          .width(Const.THOUSANDTH_500)

          Text(this.homeStore.getExpense())
            .width(Const.THOUSANDTH_200)
            .fontSize(Const.DEFAULT_16)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.End)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width(Const.THOUSANDTH_900)
        .margin({right:'4%',bottom:'20%'})
        .layoutWeight(1)

        Row() {
          Text(this.getTitle() + '收入')
            .width(Const.THOUSANDTH_250)
            .height(Const.DEFAULT_16)
            .fontSize(Const.DEFAULT_16)
            .fontColor(Color.Gray)
          Row() {
            Row()
              .width(this.getExpense('income'))
              .height(Const.DEFAULT_6)
              .backgroundColor('rgba(255, 62, 62, 1.00)')
              .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
          }
          .backgroundColor('#F1F3F5')
          .width(Const.THOUSANDTH_500)

          Text(this.homeStore.getIncome())
            .width(Const.THOUSANDTH_200)
            .fontSize(Const.DEFAULT_16)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.End)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width(Const.THOUSANDTH_900)
        .margin({right:'4%',bottom:'20%'})
        .layoutWeight(1)

      }
      .height('85%')
      .borderRadius($r('app.float.default_24'))
      .backgroundImage($r('app.media.bianqian'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      /*.backgroundColor($r('app.color.white'))*/
      //.margin({top: Const.DEFAULT_56})
      .width('85%')
      .margin({top:'10%'})
      .shadow({
        radius: 5, // 模糊半径
        color: "gray", // 阴影颜色
        offsetX: 0, // X轴偏移量
        offsetY: 5 // Y轴偏移量
      })
    }
    .width(Const.THOUSANDTH_1000)
    .height('45%')
    .padding('1%')
    .margin({bottom:'2%'})
    .justifyContent(FlexAlign.End)
    .backgroundImagePosition({x: 0, y: 0})
    .backgroundImage($r('app.media.back_groundd'))
    .backgroundImageSize({ width: Const.THOUSANDTH_1000, height: '80%' })

  }

  getTitle() {
    switch (this.detailType) {
      case DetailType[0]:
        return '本月'
        break;
      case DetailType[1]:
        return '本年'
        break;
      case DetailType[2]:
        return '总'
        break;
      case DetailType[3]:
        return ''
        break;
      default:
        return ''
        break;
    }
  }

  getExpense(type: string): ESObject {
    let expense:number = parseInt(this.homeStore.getExpense());
    let income:number = parseInt(this.homeStore.getIncome());
    let sum:number = expense + income;

    if (type === 'expense') {
      let length = (expense / sum) * 100;
      return length.toFixed(0)+'%';
    }
    else if (type === 'income') {
      let length = (income / sum) * 100;
      return length.toFixed(0)+'%';
    }

  }

}