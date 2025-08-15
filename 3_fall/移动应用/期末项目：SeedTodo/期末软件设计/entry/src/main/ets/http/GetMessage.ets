import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import {ReceiveMessage} from'../model/ReceiveMessage'
class GetMessage{
  async receive(input:string){
    hilog.info(0x0000, 'testTag', 'ALiYunHttpUtils request invoke. question: %{public}s', input);
    let request = http.createHttp()
    let result=await request.request(
      `http://api.qingyunke.com/api.php?key=free&appid=0&msg=${input}`
      /*// 请求地址
      "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
      // 请求options: HttpRequestOptions
      {
        // 请求方式
        method: http.RequestMethod.POST,
        // 请求头
        header: {
          "Content-Type": "application/json",
          // 这里的Authorization 就是刚才工作台查看的 API-KEY
          "Authorization": "sk-9****c8e5" // 脱敏处理
        },
        // 请求体
        extraData: {
          "model": "qwq-32b-preview", // 指定用于对话的通义千问模型名
          "input": {
            "messages": [
              {
                "role": "user",
                "content": input // 请求发起方传入的问题
              }
            ]
          }
        }
      }, (err, data: http.HttpResponse) => {
      if (err) {
        hilog.error(0x0000, 'testTag', 'Failed to request ALiYun. Cause: %{public}s', JSON.stringify(err) ?? '');
        return
      } else {
        hilog.error(0x0000, 'testTag', 'Request ALiYun success. data: %{public}s', JSON.stringify(data));
        console.log(data.result.toString())
        let receive:ReceiveMessage = JSON.parse(data.result.toString())
        return receive.content
      }
    }*/
  )
  if(result.responseCode===200){
    console.log(result.result.toString())
    let receive:ReceiveMessage = JSON.parse(result.result.toString())
    return receive.content
  }
  return
}
}

let messageUtil=new GetMessage()
export default messageUtil as GetMessage



class ALiYunHttpUtils {

request(question: string) {
  hilog.info(0x0000, 'testTag', 'ALiYunHttpUtils request invoke. question: %{public}s', question);

  // 1 createHttp接口创建请求
  let httpRequest = http.createHttp();

  // 2 发起请求
  httpRequest.request(
    // 请求地址
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
    // 请求options: HttpRequestOptions
    {
      // 请求方式
      method: http.RequestMethod.POST,
      // 请求头
      header: {
        "Content-Type": "application/json",
        // 这里的Authorization 就是刚才工作台查看的 API-KEY
        "Authorization": "sk-0bxxxxxxxxxxxxxxxxc3" // 脱敏处理
      },
      // 请求体
      extraData: {
        "model": "qwen-plus", // 指定用于对话的通义千问模型名
        "input": {
          "messages": [
            {
              "role": "user",
              "content": question // 请求发起方传入的问题
            }
          ]
        }
      }
    }, (err, data: http.HttpResponse) => {
    if (err) {
      hilog.error(0x0000, 'testTag', 'Failed to request ALiYun. Cause: %{public}s', JSON.stringify(err) ?? '');
      httpRequest.destroy();
    } else {
      hilog.error(0x0000, 'testTag', 'Request ALiYun success. data: %{public}s', JSON.stringify(data.result));
      httpRequest.destroy();
    }
  })
}

}
