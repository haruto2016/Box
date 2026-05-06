// WebBox - WebRTC Streaming Engine (Client Side)

class WebBoxStreamer {
    constructor(videoElement) {
        this.video = videoElement;
        this.pc = null;
        this.ws = null;
    }

    async connect(serverUrl) {
        console.log('Connecting to WebBox Streaming Engine...');
        
        this.ws = new WebSocket(serverUrl);
        
        this.ws.onmessage = async (event) => {
            const data = JSON.parse(event.data);
            
            if (data.type === 'offer') {
                await this.handleOffer(data.sdp);
            } else if (data.type === 'candidate') {
                await this.pc.addIceCandidate(new RTCIceCandidate(data.candidate));
            }
        };

        this.pc = new RTCPeerConnection({
            iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
        });

        this.pc.ontrack = (event) => {
            console.log('Received Remote Stream (60fps)');
            this.video.srcObject = event.streams[0];
            this.video.classList.add('active');
            document.getElementById('vm-canvas').style.display = 'none';
        };

        this.pc.onicecandidate = (event) => {
            if (event.candidate) {
                this.ws.send(JSON.stringify({
                    type: 'candidate',
                    candidate: event.candidate
                }));
            }
        };

        this.attachInputListeners();
    }

    attachInputListeners() {
        // キーボード入力
        window.addEventListener('keydown', (e) => {
            if (!document.getElementById('vm-session-overlay').classList.contains('hidden')) {
                e.preventDefault();
                this.sendInput({ device: 'keyboard', action: 'down', key: e.key, code: e.code });
            }
        });

        window.addEventListener('keyup', (e) => {
            if (!document.getElementById('vm-session-overlay').classList.contains('hidden')) {
                e.preventDefault();
                this.sendInput({ device: 'keyboard', action: 'up', key: e.key, code: e.code });
            }
        });

        // マウス入力
        this.video.addEventListener('mousemove', (e) => {
            const rect = this.video.getBoundingClientRect();
            // 動画の実際の解像度に対する相対座標を計算
            const x = (e.clientX - rect.left) / rect.width;
            const y = (e.clientY - rect.top) / rect.height;
            this.sendInput({ device: 'mouse', action: 'move', x, y });
        });

        this.video.addEventListener('mousedown', (e) => {
            this.sendInput({ device: 'mouse', action: 'down', button: e.button });
        });

        this.video.addEventListener('mouseup', (e) => {
            this.sendInput({ device: 'mouse', action: 'up', button: e.button });
        });

        // 右クリックメニューの無効化
        this.video.addEventListener('contextmenu', e => e.preventDefault());
    }

    async handleOffer(sdp) {
        await this.pc.setRemoteDescription(new RTCSessionDescription({ type: 'offer', sdp }));
        const answer = await this.pc.createAnswer();
        await this.pc.setLocalDescription(answer);
        
        this.ws.send(JSON.stringify({
            type: 'answer',
            sdp: answer.sdp
        }));
    }

    sendInput(inputData) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                type: 'input',
                data: inputData
            }));
        }
    }
}

window.WebBoxStreamer = WebBoxStreamer;
