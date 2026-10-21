export const PROTOCOL='arena-net-11-ramis-ultimate';
export class PeerLink{
 get isOpen(){return !this.closed&&this.channel?.readyState==='open'}
 constructor({seat,signal,onData,onOpen,onFailure,RTCPeerConnectionClass=globalThis.RTCPeerConnection}){
  Object.assign(this,{seat,signal,onData,onOpen,onFailure,pendingIce:[],closed:false});
  this.pc=new RTCPeerConnectionClass({iceServers:[{urls:'stun:stun.l.google.com:19302'},{urls:'stun:stun.cloudflare.com:3478'}]});
  this.pc.onicecandidate=e=>{if(e.candidate)signal({type:'ice',candidate:e.candidate.toJSON?e.candidate.toJSON():e.candidate})};
  this.pc.onconnectionstatechange=()=>{if(!this.closed&&this.pc.connectionState==='failed')onFailure('Сеть блокирует прямую связь. Попробуйте другую Wi-Fi сеть; для некоторых сетей нужен TURN-сервер.')};
  this.pc.ondatachannel=e=>this.bind(e.channel);if(seat===0)this.bind(this.pc.createDataChannel('arena-input',{ordered:true}));
 }
 bind(channel){this.channel=channel;channel.onopen=()=>{this.send({t:'hello',protocol:PROTOCOL});this.onOpen()};channel.onmessage=e=>{if(this.closed||typeof e.data!=='string'||e.data.length>4000)return;let d;try{d=JSON.parse(e.data)}catch{return}if(d&&typeof d==='object')this.onData(d)};channel.onclose=()=>{if(!this.closed)this.onFailure('Соединение с соперником закрыто')};channel.onerror=()=>{if(!this.closed)this.onFailure('Ошибка соединения')};}
 async offer(){await this.pc.setLocalDescription(await this.pc.createOffer());this.signal({type:'offer',sdp:this.pc.localDescription.sdp})}
 async receive(m){if(this.closed)return;if(m.type==='offer'&&this.seat===1&&!this.pc.remoteDescription){await this.pc.setRemoteDescription({type:'offer',sdp:m.sdp});await this.flushIce();await this.pc.setLocalDescription(await this.pc.createAnswer());this.signal({type:'answer',sdp:this.pc.localDescription.sdp})}else if(m.type==='answer'&&this.seat===0&&!this.pc.remoteDescription){await this.pc.setRemoteDescription({type:'answer',sdp:m.sdp});await this.flushIce()}else if(m.type==='ice'){if(this.pc.remoteDescription)await this.pc.addIceCandidate(m.candidate);else this.pendingIce.push(m.candidate)}}
 async flushIce(){for(const c of this.pendingIce)await this.pc.addIceCandidate(c);this.pendingIce=[]}
 send(m){if(this.channel?.readyState!=='open')return false;if(this.channel.bufferedAmount>131072){this.onFailure('Сеть не успевает передавать управление');return false}this.channel.send(JSON.stringify(m));return true}
 close(){this.closed=true;this.channel?.close();this.pc.close()}
}
