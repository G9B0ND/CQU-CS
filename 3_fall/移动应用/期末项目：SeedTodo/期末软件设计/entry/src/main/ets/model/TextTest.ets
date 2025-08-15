import { MessageRoleEnum, MessageVO } from '../model/MessageVO';

export class TextTest {
  static readonly Text: MessageVO[] = [
    new MessageVO(MessageRoleEnum.Mine, '请介绍一下你自己'),
    new MessageVO(
      MessageRoleEnum.Other,
      "我是百度公司开发的人工智能语言模型，我的中文名是文心一言，英文名是ERNIE-Bot，" +
        "可以协助您完成范围广泛的任务并提供有关各种主题的信息，比如回答问题，提供定义和解释及建议。如果您有任何问题，请随时向我提问。"
    ),
    new MessageVO(MessageRoleEnum.Mine, '我在上海，周末可以去哪里玩？'),
    new MessageVO(
      MessageRoleEnum.Other,
      '上海是一个充满活力和文化氛围的城市，有很多适合周末游玩的地方。以下是几个值得推荐的地方：\n\n1. 上海科技馆：上海科技馆是中国大陆最大的科技馆之一'
    )
  ];
}
