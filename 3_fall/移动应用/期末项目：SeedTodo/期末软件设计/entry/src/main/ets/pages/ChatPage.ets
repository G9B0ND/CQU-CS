import { chatMessage } from '../model/chatMessage'
import  messageUtil from '../http/GetMessage'
@Entry
@Component
struct Index{
  @State isReceive:boolean=false
  @State charList:Array<chatMessage>=[]
  @State sendMessage:string=''
  @State isPanelShow:boolean=false

  @Builder usuallyTake(message:string){
    Row(){
      Blank()
      Text(message)
        .fontSize(16)
        .onClick(()=>{
          this.sendMessage=message
          this.isPanelShow=false
          this.sendMessages()
        }).width('80%')
        .margin({top:'2%',bottom:'1%'})
      Blank()
    }
    .margin('1%')
    .width('80%')
    .height('15%')
    .backgroundImage($r('app.media.backclock'))
    .backgroundImageSize({width:'100%',height:'100%'})
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .opacity(0.7)
    .shadow({
      radius: 5,
      color: `rgba(0,0,0,0.5)`,
      offsetX:-5,
      offsetY:5
    })

  }

  aboutToAppear(): void {
    let chat=new chatMessage("Robot","你好，我是你的SeedTodo专属小助手")
    this.charList.push(chat)
  }

  async sendMessages(){
    this.isReceive=true
    let userChat: chatMessage = new chatMessage('User', this.sendMessage);
    this.charList.push(userChat)
    this.sendMessage=''
    let receiveMessage:ESObject=await messageUtil.receive(userChat.message)
    let RobotChat:chatMessage=new chatMessage('Robot',receiveMessage)
    this.isReceive=false
    this.charList.push(RobotChat)
  }

  build() {
    Stack(){
      Column(){
        /*Row(){
          Text(this.isReceive? "机器人正在输入":"机器人").fontSize(28)
            .width('100%').textAlign(TextAlign.Center)
        }.width('90%').height('5%').margin({top:'12%'})*/
        Column(){
          Blank()
          Image($r('app.media.ai'))
            .size({width:'80%'})
          Blank()
        }.backgroundImage($r('app.media.backclock'))
        .backgroundImageSize({width:'100%',height:'100%'})
        .size({width:'90%',height:'8%'})
        .border({
          radius: 12,
          style: BorderStyle.Solid,
          color: $r('app.color.font_grey')
        })
        .margin({top:'12%',bottom:'5%'})
        .opacity(0.6)

        Column(){
          List(){
            ForEach(this.charList,(chat:chatMessage)=>{
              ListItem(){
                if(chat.sender==="Robot"){
                  Row(){
                    Column(){
                      Image($r('app.media.seed'))
                        .clipShape(new Circle({ width: '125px', height: '125px' }))
                    }.width('13%')
                    .height('8%')
                    Blank()
                    Column(){
                      Text(chat.message).fontSize(16)
                    }
                    .backgroundImage($r('app.media.backmusic'))
                    .backgroundImageSize({width:'100%',height:'100%'})
                    .width('60%')
                    .padding('3%')
                    .border({
                      radius: 8,
                      style: BorderStyle.Solid,
                      color: $r('app.color.font_grey')
                    })
                    .margin({right:'22%'})
                  }.width('100%')
                  .margin({top:8})
                }
                else{
                  Row(){
                    Column(){
                      Text(chat.message).fontSize(16)
                    }
                    .backgroundImage($r('app.media.backmusic'))
                    .backgroundImageSize({width:'100%',height:'100%'})
                    .width('60%')
                    .padding('3%')
                    .border({
                      radius: 8,
                      style: BorderStyle.Solid,
                      color: $r('app.color.font_grey')
                    })
                    .margin({left:'22%'})
                    Blank()
                    Column(){
                      Image($r('app.media.User'))
                        .clipShape(new Circle({ width: '125px', height: '125px' }))
                    }.width('13%')
                    .height('8%')
                  }.width('100%')
                  .margin({top:8})
                }
              }
            })
          }
        }.width('85%').height('75%')

        Row(){
          TextInput({ text: this.sendMessage }).width('60%')
            .onChange((value:string)=>{
              this.sendMessage=value
            })
            .shadow({
              radius: 5,
              color: `rgba(0,0,0,0.5)`,
              offsetX:-5,
              offsetY:5
            })
          Text("常用语").fontSize(16)
            .onClick(()=>{
              this.isPanelShow=true
            })


          Button("发送").fontSize(16).fontColor(Color.Black)
            .onClick(()=>{
              this.sendMessages()
            })
            .backgroundImage($r('app.media.backmusic'))
            .backgroundImageSize({width:'100%',height:'100%'})
            .shadow({
              radius: 5,
              color: `rgba(0,0,0,0.5)`,
              offsetX:5,
              offsetY:5
            })
        }.width('90%').height('10%').justifyContent(FlexAlign.SpaceAround)
        .backgroundImage($r('app.media.logbackground'))
        .backgroundImageSize({width:'100%',height:'100%'})
        .size({width:'100%',height:'8%'})
        .border({
          radius:6
        })
      }
      .size({width:'100%',height:'100%'})
      .backgroundImage($r('app.media.backgroundedit'))
      .backgroundImageSize({width:'100%',height:'100%'})

      Panel(this.isPanelShow){
        Column(){
          Row(){
            Button(){
              Image($r('app.media.ic_public_back'))
                .size({ width: 20, height:20 })
                .fillColor($r('app.color.font_black'));
            }
              .backgroundColor('rgba(0,0,0,0)')
              .onClick(()=>{
                this.isPanelShow=false
              })

            Blank()
          }.width('90%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({bottom:'5%'})

          this.usuallyTake('你好')
          this.usuallyTake('你今天开心吗')
          this.usuallyTake('现在几点了')
          this.usuallyTake('讲个笑话')
        }.width('100%')
      }.backgroundColor('#F5F5F5')
    }
  }
}