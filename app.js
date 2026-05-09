// WebBox Manager - Frontend Logic
console.log("WebBox v3 Loaded - KasmVNC Mode");

const vms = {
    ubuntu: {
        name: "Ubuntu 22.04 LTS",
        desc: "高性能な開発・サーバー環境向けLinux。Wasmエンジンにより最適化済み。",
        status: "running",
        ram: "4096 MB",
        cpu: "4 Cores",
        disk: "ubuntu.vdi (20 GB)",
        iso: "None",
        icon: "terminal",
        preview: "https://images.unsplash.com/photo-1629654297299-c8506221ca97?auto=format&fit=crop&q=80&w=800"
    },
    cloudpc: {
        name: "Cloud Desktop (Native)",
        desc: "KVM不要でColabのフルスペックを使用する爆速デスクトップ環境。",
        status: "powered-off",
        ram: "12288 MB",
        cpu: "Native Cores",
        disk: "Cloud Storage",
        iso: "None",
        icon: "cloud",
        preview: "https://images.unsplash.com/photo-1661956602116-aa6865609028?auto=format&fit=crop&q=80&w=800"
    },
    kali: {
        name: "Kali Linux",
        desc: "ペネトレーションテストおよびセキュリティ監査用の専門OS。",
        status: "saved",
        ram: "2048 MB",
        cpu: "2 Cores",
        disk: "kali.vdi (40 GB)",
        iso: "None",
        icon: "shield",
        preview: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&q=80&w=800"
    }
};

let currentVmId = 'ubuntu';

// DOM Elements
const vmListItems = document.querySelectorAll('.vm-item');
const detailName = document.getElementById('detail-name');
const detailDesc = document.querySelector('.vm-desc');
const detailRam = document.getElementById('spec-ram');
const detailCpu = document.getElementById('spec-cpu');
const detailDisk = document.getElementById('spec-disk');
const detailIso = document.getElementById('spec-iso');
const detailPreview = document.getElementById('vm-preview-img');

const btnStart = document.getElementById('btn-start');
const sessionOverlay = document.getElementById('vm-session-overlay');
const btnCloseSession = document.getElementById('btn-close-session');
const bootLoader = document.getElementById('boot-loader');
const activeSessionName = document.getElementById('active-session-name');

const modalNewVm = document.getElementById('modal-new-vm');
const btnOpenNewVm = document.getElementById('btn-new-vm');
const btnCloseModal = document.querySelector('.btn-close-modal');
const btnCancelModal = document.querySelector('.btn-secondary');

const streamer = new WebBoxStreamer(document.getElementById('vm-video'));

// Initialize Lucide Icons
lucide.createIcons();

// Modal Logic
btnOpenNewVm.addEventListener('click', () => {
    modalNewVm.classList.remove('hidden');
});

[btnCloseModal, btnCancelModal].forEach(btn => {
    btn.addEventListener('click', () => {
        modalNewVm.classList.add('hidden');
    });
});

// VM Selection
vmListItems.forEach(item => {
    item.addEventListener('click', () => {
        const id = item.dataset.id;
        selectVm(id);
        
        // Update UI Active Class
        vmListItems.forEach(i => i.classList.remove('active'));
        item.classList.add('active');
    });
});

function selectVm(id) {
    currentVmId = id;
    const vm = vms[id];
    
    detailName.textContent = vm.name;
    detailDesc.textContent = vm.desc;
    detailRam.textContent = vm.ram;
    detailCpu.textContent = vm.cpu;
    detailDisk.textContent = vm.disk;
    detailIso.textContent = vm.iso;
    detailPreview.src = vm.preview;
    
    // Update action button state
    if (vm.status === 'running') {
        btnStart.querySelector('span').textContent = '表示';
        btnStart.classList.add('primary');
    } else {
        btnStart.querySelector('span').textContent = '起動';
        btnStart.classList.remove('primary');
    }
}

// Session Management
btnStart.addEventListener('click', () => {
    openSession(currentVmId);
});

// Upload Logic
let activeTunnelUrl = '';

const btnUpload = document.getElementById('btn-upload');
const btnDownload = document.getElementById('btn-download');
const btnSaveDrive = document.getElementById('btn-save-drive');
const fileInput = document.getElementById('file-upload');
const uploadContainer = document.getElementById('upload-progress-container');
const uploadBar = document.getElementById('upload-bar');
const uploadStatus = document.getElementById('upload-status');

// Admin Panel Elements
const modalAdmin = document.getElementById('modal-admin');
const btnAdminPanel = document.getElementById('btn-admin-panel');
const btnCloseAdmin = document.querySelector('.btn-close-admin');
const btnAdminSave = document.getElementById('btn-admin-save');
const btnAdminShutdown = document.getElementById('btn-admin-shutdown');

// Admin Panel Logic
btnAdminPanel.addEventListener('click', () => modalAdmin.classList.remove('hidden'));
btnCloseAdmin.addEventListener('click', () => modalAdmin.classList.add('hidden'));

// API Functions
async function callColabApi(endpoint, successMsg) {
    if (!activeTunnelUrl) {
        activeTunnelUrl = prompt("ColabのTunnel URLを入力してください:");
        if (!activeTunnelUrl) return;
    }
    
    try {
        const response = await fetch(`${activeTunnelUrl}${endpoint}`, { method: 'POST' });
        const data = await response.json();
        if (data.status === 'success') {
            alert(successMsg || data.message);
        } else {
            alert('エラーが発生しました: ' + data.message);
        }
    } catch (err) {
        alert('通信エラー: Colabサーバーが起動しているか確認してください。');
        console.error(err);
    }
}

btnSaveDrive.addEventListener('click', () => callColabApi('/api/save_to_drive', 'Google Driveへの保存が完了しました！'));
btnAdminSave.addEventListener('click', () => callColabApi('/api/save_to_drive', 'Google Driveへの保存が完了しました！'));

btnAdminShutdown.addEventListener('click', () => {
    if (confirm('本当にColabサーバーをシャットダウンしますか？（未保存のデータは失われます）')) {
        callColabApi('/api/shutdown', 'シャットダウン信号を送信しました。間もなくサーバーが停止します。');
        modalAdmin.classList.add('hidden');
    }
});

btnDownload.addEventListener('click', () => {
    if (!activeTunnelUrl) {
        activeTunnelUrl = prompt("ColabのTunnel URLを入力してください (ダウンロード元):");
        if (!activeTunnelUrl) return;
    }
    
    // バックエンドからPCへの直接ダウンロードを開始
    const downloadUrl = `${activeTunnelUrl}/api/download`;
    window.open(downloadUrl, '_blank');
});

btnUpload.addEventListener('click', () => {
    if (!activeTunnelUrl) {
        activeTunnelUrl = prompt("ColabのTunnel URLを入力してください (アップロード先):");
        if (!activeTunnelUrl) return;
    }
    fileInput.click();
});

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    uploadContainer.classList.remove('hidden');
    const formData = new FormData();
    formData.append('diskImage', file);

    const xhr = new XMLHttpRequest();
    xhr.open('POST', `${activeTunnelUrl}/api/upload`, true);

    xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
            const percentComplete = Math.round((event.loaded / event.total) * 100);
            uploadBar.style.width = percentComplete + '%';
            uploadStatus.textContent = `Uploading ${file.name}... ${percentComplete}%`;
        }
    };

    xhr.onload = () => {
        if (xhr.status === 200) {
            uploadStatus.textContent = 'Upload Complete! VM is booting...';
            uploadStatus.style.color = 'var(--accent-success)';
            
            // UIを更新して接続を開始
            vms['cloudpc'].disk = file.name;
            detailDisk.textContent = file.name;
            setTimeout(() => {
                uploadContainer.classList.add('hidden');
                openSession('cloudpc', true); // 自動起動
            }, 2000);
        } else {
            uploadStatus.textContent = 'Upload Failed: ' + xhr.statusText;
            uploadStatus.style.color = 'var(--accent-danger)';
        }
    };

    xhr.onerror = () => {
        uploadStatus.textContent = 'Network Error during upload.';
        uploadStatus.style.color = 'var(--accent-danger)';
    };

    xhr.send(formData);
});

// Update openSession to use stored URL
function openSession(id, autoConnect = false) {
    const vm = vms[id];
    activeSessionName.textContent = vm.name;
    sessionOverlay.classList.remove('hidden');
    
    const statusMsg = document.querySelector('.status-msg');

    if (id === 'cloudpc') {
        // [修正] クリック直後（同期処理）にURLを聞くことで、バックグラウンドタブでのブロックを防ぐ
        if (!autoConnect) {
            const inputUrl = prompt("Google Colabで発行された Cloudflare Tunnel のURLを入力してください。\n(例: https://xxxx-xxxx.trycloudflare.com)", activeTunnelUrl);
            if (!inputUrl) {
                // キャンセルされた場合は起動処理を中止
                return;
            }
            activeTunnelUrl = inputUrl;
        }

        statusMsg.textContent = 'Connecting to Native Cloud Engine...';
        statusMsg.style.color = '#f59e0b';
        
        const videoEl = document.getElementById('vm-video');
        const iframeEl = document.getElementById('vm-iframe');
        
        bootLoader.classList.remove('hidden');
        bootLoader.querySelector('span').textContent = 'Initializing Desktop Session...';
        
        setTimeout(() => {
            bootLoader.querySelector('span').textContent = 'Loading noVNC Client...';
            setTimeout(() => {
                bootLoader.classList.add('hidden');
                vm.status = 'running';
                statusMsg.textContent = 'Connected: Native Cloud Desktop';
                statusMsg.style.color = '#10b981';
                selectVm(id);
                simulateActivity();
                
                if (activeTunnelUrl) {
                    // [修正] KasmVNCはルートURLで直接動作するため、パスの付加を削除
                    let vncUrl = activeTunnelUrl;
                    
                    console.log('Connecting via iframe to:', vncUrl);
                    videoEl.classList.remove('active');
                    iframeEl.src = vncUrl;
                    iframeEl.classList.add('active');
                } else {
                    statusMsg.textContent = 'Connection Cancelled.';
                    statusMsg.style.color = '#ef4444';
                }
            }, 2000);
        }, 1500);
        return;
    }

    if (vm.status !== 'running') {
        statusMsg.textContent = 'Running via v86 Wasm Engine';
        statusMsg.style.color = '';
        // Start boot sequence
        bootLoader.classList.remove('hidden');
        bootLoader.querySelector('span').textContent = 'Booting Kernel...';
        setTimeout(() => {
            bootLoader.classList.add('hidden');
            vm.status = 'running';
            selectVm(id);
            // Simulate Disk Activity
            simulateActivity();
        }, 3000);
    }
}

btnCloseSession.addEventListener('click', () => {
    sessionOverlay.classList.add('hidden');
});

// Fullscreen Toggle
document.getElementById('btn-fullscreen').addEventListener('click', () => {
    if (!document.fullscreenElement) {
        sessionOverlay.requestFullscreen();
    } else {
        document.exitFullscreen();
    }
});

// Activity Simulation (Indicators)
function simulateActivity() {
    const diskInd = document.getElementById('ind-disk');
    const netInd = document.getElementById('ind-net');
    
    setInterval(() => {
        if (!sessionOverlay.classList.contains('hidden')) {
            if (Math.random() > 0.7) diskInd.classList.add('active');
            else diskInd.classList.remove('active');
            
            if (Math.random() > 0.8) netInd.classList.add('active');
            else netInd.classList.remove('active');
        }
    }, 200);
}

// Initial Selection
selectVm('ubuntu');
