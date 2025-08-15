import { prompt, router } from '@kit.ArkUI';
import { CommonConstants } from '../common/constants/CommonConstants';

@Entry
@Component
struct Login{
  @State myWidth:number=400;
  @State myHeight:number=400;
  @State top:number=10;

  @State flag:boolean=false;
  private inputUsername='';
  private inputPassword='';


  build() {
  Column(){
    Image($rawfile('user.png'))
      .width(this.myWidth)
      .height(this.myHeight)
      .margin({top:this.top,bottom:20})
      .onClick(()=>{
        animateTo({duration:1000,curve:Curve.Ease},()=>{
          if(this.flag){
            this.myWidth=400;
            this.myHeight=400;
            this.top=10;
          }else{
            this.myWidth=150;
            this.myHeight=150;
            this.top=80;
          }
          this.flag=!this.flag;
        });
      })
    if(this.flag==false){

      Image($rawfile('title.png'))
        .width('70%')
      Image($rawfile('bottom.png'))
        .width('100%')
        .borderRadius('10vp')
        .margin({top:145})
    }
    Text("欢迎登录")
      .fontSize(28)
      .fontColor(Color.Black)

    TextInput({placeholder:"账号"})
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
      Text('还没有账号？去注册')
        .fontSize(18)
        .fontColor('#734f0d')
        .decoration({type:TextDecorationType.Underline,color:('#734f0d')})
        .textAlign(TextAlign.Start)
        .onClick(()=>{
          router.pushUrl({url:'pages/RegisterPage'})
        })
      Blank(120)
      Text('忘记密码')
        .fontSize(18)
        .fontColor('#734f0d')
        .decoration({type:TextDecorationType.Underline,color:('#734f0d')})
        .textAlign(TextAlign.Start)
        .onClick(()=>{
          router.pushUrl({url:'pages/ForgetPage'})
        })
    }
    Button('登录',{type:ButtonType.Capsule})
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
        if(this.inputPassword!='123'){
          prompt.showToast({message:'用户名与密码不匹配',bottom:'70vp'});
        }
        else {
          router.pushUrl({ url: 'pages/Index' })
        }
      })
    }.width('100%').height('100%').backgroundColor('#deb887')
  }
}
