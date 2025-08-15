import { prompt, router } from '@kit.ArkUI';


@Entry
@Component
struct Login{
  private inputUsername='';
  private inputPassword='';
  private inputPassword1='';
  @State show:number=0;

  ifquel():void{
    if(this.inputPassword!==this.inputPassword1){
      this.show=1;
    }
    else if(this.inputPassword===this.inputPassword1){
      this.show=0;
    }
  }
  build() {
    Column(){
      Image($rawfile('user.png'))
        .width(150)
        .height(150)
        .margin({top:80,bottom:20})

      Text("修改密码")
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

      TextInput({placeholder:"请输入你的新密码"})
        .width('90%')
        .height(50)
        .margin(20)
        .borderRadius(0)
        .type(InputType.Password)
        .onChange((value:string)=>{
          this.inputPassword=value;
        }).backgroundColor(Color.White)

      TextInput({placeholder:"确认你的新密码"})
        .width('90%')
        .height(50)
        .margin(20)
        .borderRadius(0)
        .type(InputType.Password)
        .onChange((value:string)=>{
          this.inputPassword1=value;
          this.ifquel();
        }).backgroundColor(Color.White)

      if(this.show===1){
        Text("两次输入的密码不一致！")
          .fontSize(18)
          .fontColor(Color.Red)
      }
      Row(){
        Text('修改完成？去登录')
          .margin({top:'5vp'})
          .fontSize(18)
          .fontColor('#734f0d')
          .decoration({type:TextDecorationType.Underline,color:('#734f0d')})
          .textAlign(TextAlign.Start)
          .onClick(()=>{
            router.back();
          })
      }
      Button('设置新密码',{type:ButtonType.Capsule})
        .backgroundColor('#ecb653')
        .fontColor(Color.Black)
        .width(200)
        .height(55)
        .fontSize(30)
        .margin(30)
        .shadow({
          radius: 5, // 模糊半径
          color: "black", // 阴影颜色
          offsetX: 5, // X轴偏移量
          offsetY: 5 // Y轴偏移量
        })
        .borderRadius(30)
        .onClick(()=>{
          prompt.showToast({message:'修改密码成功',bottom:'70vp'});
          router.pushUrl({url:'pages/LoginPage'})
        })
    }.width('100%').height('100%').backgroundColor('#deb887')
  }
}
