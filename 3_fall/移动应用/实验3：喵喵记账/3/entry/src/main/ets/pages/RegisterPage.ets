
import { prompt, router } from '@kit.ArkUI';


@Entry
@Component
struct Login{
  private inputUsername='';
  private inputPassword='';

  build() {
    Column(){
      Image($rawfile('user.png'))
        .width(150)
        .height(150)
        .margin({top:80,bottom:20})

      Text("欢迎注册")
        .fontSize(28)
        .fontColor(Color.Black)

      TextInput({placeholder:"请输入你的账号"})
        .width('90%')
        .height(50)
        .margin(20)
        .borderRadius(0)
        .type(InputType.Normal)
        .onChange((value:string)=>{
          this.inputUsername=value;
        }).backgroundColor(Color.White)

      TextInput({placeholder:"密码"})
        .width('90%')
        .height(50)
        .margin(20)
        .borderRadius(0)
        .type(InputType.Password)
        .onChange((value:string)=>{
          this.inputPassword=value;
        }).backgroundColor(Color.White)

      Row(){
        Text('已有账号？去登录')
          .fontSize(18)
          .fontColor('#734f0d')
          .decoration({type:TextDecorationType.Underline,color:('#734f0d')})
          .textAlign(TextAlign.Start)
          .onClick(()=>{
            router.back();
          })
      }
      Button('注册',{type:ButtonType.Capsule})
        .backgroundColor('#ecb653')
        .fontColor(Color.Black)
        .width(200)
        .height(55)
        .fontSize(30)
        .margin(30)
        .borderRadius(30)
        .shadow({
          radius: 5, // 模糊半径
          color: "black", // 阴影颜色
          offsetX: 5, // X轴偏移量
          offsetY: 5 // Y轴偏移量
        })
        .onClick(()=>{
          prompt.showToast({message:'注册成功',bottom:'70vp'});
          router.pushUrl({url:'pages/LoginPage'})
        })
    }.width('100%').height('100%').backgroundColor('#deb887')
  }
}
