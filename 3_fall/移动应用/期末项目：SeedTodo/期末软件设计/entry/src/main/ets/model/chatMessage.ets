export  class chatMessage{

  sender:'User'|'Robot'
  message:string

  constructor( sender:'User'|'Robot', message:string) {
    this.sender=sender
    this.message=message
  }
}