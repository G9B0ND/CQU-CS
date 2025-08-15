import BackgroundType from '../model/BackgroundType';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import WeatherData from '../model/WeatherData';

@CustomDialog
export default struct WeatherDialog {
  /**
   * 对话框控制器。
   */
  public controller: CustomDialogController;
  /**
   * 来源文件夹。用于获取背景颜色或背景图片。
   */
  private folder!: Folder;
  /**
   * 天气数据。
   */
  private weatherData!: WeatherData;

  public build(): void {
    Stack() {
      Column()
        .visibility(this.folder.backgroundType === BackgroundType.COLOR
          ? Visibility.Visible : Visibility.Hidden)
        .size({ width: '100%', height: '100%' })
        .backgroundColor(this.folder.background)
        .border({ radius: 12, color: $r('app.color.font_grey'), width: 1 });
      Column()
        .visibility(this.folder.backgroundType === BackgroundType.PHOTO
          ? Visibility.Visible : Visibility.Hidden)
        .size({ width: '100%', height: '100%' })
        .backgroundImage(this.folder.background)
        .backgroundImageSize(ImageSize.Cover)
        .border({ radius: 12, color: $r('app.color.font_grey'), width: 1 });
      /*Column()
        .size({ width: '100%', height: '100%' })
        .backgroundColor($r('app.color.pure_white'))
        .opacity(0.7)
        .border({ radius: 12, color: $r('app.color.font_grey'), width: 1 });
*/
      Column() {
        Row() {
          Text(this.weatherData.province! + this.weatherData.city)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'));
        }
        .padding('2%')
        //.backgroundColor($r('app.color.main_background'))
        .margin({left:'2%'})
        .border({ radius: 14 });

        Divider()
          .color($r('app.color.font_grey'))

        Row(){
          Row() {
            Text('天气：' + this.weatherData.weather)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          //.backgroundColor($r('app.color.main_background'))
          .border({ radius: 12 });

          Blank()

          Row() {
            Text('气温：' + this.weatherData.temperature_float + '摄氏度')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          //.backgroundColor($r('app.color.main_background'))
          .border({ radius: 12 });
        }.size({width:'100%',height:'25%'})
        .padding('5%')

        Row(){
          Row() {
            Text(this.weatherData.winddirection + '风' + this.weatherData.windpower + '级')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          //.backgroundColor($r('app.color.main_background'))
          .border({ radius: 12 });

          Blank()

          Row() {
            Text('空气湿度' + this.weatherData.humidity_float + '%')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          //.backgroundColor($r('app.color.main_background'))
          .border({ radius: 12 });
        }.size({width:'100%',height:'25%'})
        .padding('5%')

        Divider()
          .color($r('app.color.font_grey'))
          .margin({top:'2%'})

        Text('上一次刷新时间：' + this.weatherData.reporttime)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.font_grey'))
          .margin({top:'4%',left:'2%',right:'2%'})
      }
      .size({ width: '100%', height: '80%' })
      .padding('2%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)

    }
    .margin('2%')
    .border({ radius: 12})
    .size({ width: '85%', height: '25%' });
  }
}