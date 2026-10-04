// GigaNas Control Center - Complete Enterprise Client Logic

let memoryDonutChart = null;
let ws = null;
let sidebarCollapsed = false;
let raidDefinitions = {};
let availableDisks = [];

document.addEventListener('DOMContentLoaded', () => {
    lucide.createIcons();
    initMemoryDonut();
    initWebSocket();
    refreshAll();

    setInterval(loadSystemStatus, 4000);
});

function toggleSidebar() {
    const sidebar = document.getElementById('main-sidebar');
    sidebarCollapsed = !sidebarCollapsed;
    if (sidebarCollapsed) {
        sidebar.classList.add('w-16');
        sidebar.classList.remove('w-56');
        sidebar.querySelectorAll('span').forEach(s => s.classList.add('hidden'));
    } else {
        sidebar.classList.remove('w-16');
        sidebar.classList.add('w-56');
        sidebar.querySelectorAll('span').forEach(s => s.classList.remove('hidden'));
    }
}

// ==========================================
// Tab Navigation
// ==========================================
function switchTab(tabId) {
    const tabs = ['dashboard', 'accounts', 'system', 'storage', 'shares', 'apps', 'remote', 'optimizer'];
    const titles = {
        'dashboard': 'Dashboard General',
        'accounts': 'Cuentas de Usuario y Permisos (RBAC)',
        'system': 'Configuración del Sistema y Energía',
        'storage': 'Almacenamiento (ZFS Pools & FlexPool)',
        'shares': 'Sharing (Carpetas SMB / Samba)',
        'apps': 'Apps (Docker Compose 1-Click Store)',
        'remote': 'Túnel Móvil Seguro & VPN (Zero-Trust QR)',
        'optimizer': 'Optimizador de Núcleo GigaNas'
    };

    tabs.forEach(t => {
        const el = document.getElementById(`tab-${t}`);
        const nav = document.getElementById(`nav-${t}`);
        if (el) el.classList.add('hidden');
        if (nav) nav.classList.remove('active');
    });

    const activeEl = document.getElementById(`tab-${tabId}`);
    const activeNav = document.getElementById(`nav-${tabId}`);
    if (activeEl) activeEl.classList.remove('hidden');
    if (activeNav) activeNav.classList.add('active');

    if (titles[tabId]) {
        document.getElementById('view-title').innerText = titles[tabId];
    }

    if (tabId === 'accounts') loadAccounts();
    if (tabId === 'system') loadSystemSettings();
    if (tabId === 'storage') { loadStorage(); loadRaidDefinitions(); }
    if (tabId === 'shares') loadShares();
    if (tabId === 'apps') loadApps();
    if (tabId === 'remote') loadTunnelDevices();
    if (tabId === 'optimizer') loadOptimizer();

    lucide.createIcons();
}

// ==========================================
// Chart.js Memory Donut (TrueNAS Authentic)
// ==========================================
function initMemoryDonut() {
    const ctx = document.getElementById('chart-memory-donut').getContext('2d');
    memoryDonutChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Free', 'ZFS Cache', 'Services'],
            datasets: [{
                data: [60, 25, 15],
                backgroundColor: [
                    '#0095d5', // TrueNAS Blue (Free)
                    '#9b59b6', // TrueNAS Purple (ZFS Cache)
                    '#e67e22'  // TrueNAS Orange (Services)
                ],
                borderWidth: 0,
                hoverOffset: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '68%',
            plugins: {
                legend: { display: false }
            }
        }
    });
}

// ==========================================
// WebSocket Realtime Telemetry
// ==========================================
function initWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/telemetry`;

    try {
        ws = new WebSocket(wsUrl);
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            updateRealtimeUI(data);
        };
        ws.onclose = () => setTimeout(initWebSocket, 3000);
    } catch (e) {
        console.warn("WebSocket fallback");
    }
}

function updateRealtimeUI(data) {
    const cpuPct = Math.round(data.cpu_percent);
    const cpuEl = document.getElementById('cpu-percent-text');
    if (cpuEl) cpuEl.innerText = `${cpuPct}%`;

    const highestEl = document.getElementById('cpu-highest');
    if (highestEl) highestEl.innerText = `${Math.min(cpuPct + 3, 100)}% (Core #2)`;

    const netIn = document.getElementById('net-in-rate');
    const netOut = document.getElementById('net-out-rate');
    if (netIn) netIn.innerText = `${data.net_rx_kbps.toFixed(2)} KB/s`;
    if (netOut) netOut.innerText = `${data.net_tx_kbps.toFixed(2)} KB/s`;

    renderThreadBars(cpuPct);
}

function renderThreadBars(avgPct) {
    const container = document.getElementById('cpu-threads-bars');
    if (!container) return;
    
    let barsHtml = '';
    for (let i = 0; i < 8; i++) {
        const jitter = (Math.sin(i * 1.5) * 6);
        const h = Math.max(15, Math.min(100, avgPct + jitter + 10));
        barsHtml += `<div class="flex-1 bg-[#1a1e24] rounded-t-sm h-full relative overflow-hidden">
            <div class="bg-tnblue w-full absolute bottom-0 transition-all duration-300" style="height: ${h}%"></div>
        </div>`;
    }
    container.innerHTML = barsHtml;
}

// ==========================================
// System Status Fetcher
// ==========================================
async function refreshAll() {
    await loadSystemStatus();
    await loadStorage();
    await loadShares();
    await loadApps();
    await loadOptimizer();
}

async function loadSystemStatus() {
    try {
        const res = await fetch('/api/system/status');
        const data = await res.json();

        document.getElementById('sys-hostname').innerText = data.hostname + ".local";
        document.getElementById('sys-uptime').innerText = data.uptime + " as of " + new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        document.getElementById('sys-version').innerText = "GigaNas-25.10 (Linux 6.12 OpenZFS)";
        document.getElementById('sys-platform').innerText = "Generic x86_64";

        document.getElementById('cpu-model').innerText = `${data.cpu.cores_physical} Cores / ${data.cpu.cores_logical} Threads @ ${data.cpu.frequency_mhz} MHz`;
        document.getElementById('cpu-threads').innerText = `${data.cpu.cores_logical} Threads`;
        document.getElementById('cpu-temp').innerText = `${data.temperature || 36}°C`;

        const total = data.memory.total_gb;
        const used = data.memory.used_gb;
        const arc = data.memory.zfs_arc_allocated_gb || 4.2;
        const free = Math.max(0.5, total - used);
        const services = Math.max(1.0, used - (arc * 0.4));

        document.getElementById('mem-total-text').innerHTML = `${total.toFixed(1)} <span class="text-sm font-normal text-tnmuted">GiB</span>`;
        document.getElementById('mem-free-text').innerText = `${free.toFixed(1)} GiB`;
        document.getElementById('mem-arc-text').innerText = `${arc.toFixed(1)} GiB`;
        document.getElementById('mem-services-text').innerText = `${services.toFixed(1)} GiB`;

        if (memoryDonutChart) {
            const pctFree = Math.round((free / total) * 100);
            const pctArc = Math.round((arc / total) * 100);
            const pctServ = Math.max(5, 100 - pctFree - pctArc);
            memoryDonutChart.data.datasets[0].data = [pctFree, pctArc, pctServ];
            memoryDonutChart.update('none');
        }
    } catch (e) {
        console.error("Error loading system status", e);
    }
}

// ==========================================
// 1. CUENTAS & USUARIOS (RBAC)
// ==========================================
async function loadAccounts() {
    try {
        const [usersRes, groupsRes] = await Promise.all([
            fetch('/api/accounts/users'),
            fetch('/api/accounts/groups')
        ]);
        const users = await usersRes.json();
        const groups = await groupsRes.json();

        const tbody = document.getElementById('accounts-users-table');
        if (tbody) {
            tbody.innerHTML = users.map(u => `
                <tr class="hover:bg-tncardsub/80 transition-all">
                    <td class="p-3 font-bold text-white flex items-center gap-2">
                        <i data-lucide="user" class="w-3.5 h-3.5 text-tnblue"></i> ${u.username}
                    </td>
                    <td class="p-3 text-slate-300">${u.full_name}</td>
                    <td class="p-3">
                        <span class="px-2 py-0.5 rounded text-[10px] font-bold ${
                            u.role === 'Administrador' ? 'bg-amber-950 text-amber-400 border border-amber-800' :
                            (u.role === 'Solo Lectura' ? 'bg-slate-800 text-slate-400' : 'bg-tnblue/20 text-tnblue')
                        }">${u.role}</span>
                    </td>
                    <td class="p-3 text-tnmuted">${u.shell}</td>
                    <td class="p-3 text-slate-300">${u.quota_gb > 0 ? u.quota_gb + ' GB' : 'Ilimitada'}</td>
                    <td class="p-3">
                        <span class="px-1.5 py-0.5 rounded text-[10px] font-bold ${u.status === 'Activo' ? 'text-tngreen bg-emerald-950/40' : 'text-rose-400 bg-rose-950/40'}">
                            ${u.status}
                        </span>
                    </td>
                    <td class="p-3 text-right">
                        ${u.username !== 'root' ? `
                            <button onclick="toggleUser('${u.username}')" class="px-2 py-1 rounded bg-tnborder hover:bg-slate-700 text-white text-[10px] mr-1">
                                ${u.status === 'Activo' ? 'Suspender' : 'Activar'}
                            </button>
                            <button onclick="deleteUser('${u.username}')" class="p-1 rounded bg-rose-950/40 hover:bg-rose-900/60 text-rose-400">
                                <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                            </button>
                        ` : '<span class="text-tnmuted text-[10px]">Inmutable</span>'}
                    </td>
                </tr>
            `).join('');
        }

        const groupsList = document.getElementById('accounts-groups-list');
        if (groupsList) {
            groupsList.innerHTML = groups.map(g => `
                <div class="p-2.5 bg-tncardsub border border-tnborder rounded mb-2 flex justify-between items-center text-xs font-mono">
                    <div>
                        <span class="text-white font-bold">${g.name}</span> <span class="text-tnmuted text-[11px]">(GID: ${g.gid})</span>
                        <div class="text-[11px] text-tnmuted">${g.description}</div>
                    </div>
                    <div class="text-tnblue text-[11px]">Miembros: ${g.members.join(', ')}</div>
                </div>
            `).join('');
        }
        lucide.createIcons();
    } catch (e) {
        console.error("Error loading accounts", e);
    }
}

function openNewUserModal() {
    document.getElementById('modal-new-user').classList.remove('hidden');
}

function closeNewUserModal() {
    document.getElementById('modal-new-user').classList.add('hidden');
}

async function submitNewUser() {
    const username = document.getElementById('user-input-username').value.trim();
    const full_name = document.getElementById('user-input-fullname').value.trim();
    const role = document.getElementById('user-input-role').value;
    const quota_gb = parseInt(document.getElementById('user-input-quota').value) || 0;

    if (!username) return alert("Por favor escribe un nombre de usuario.");

    try {
        const res = await fetch('/api/accounts/users', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, full_name, role, quota_gb })
        });
        const data = await res.json();
        if (data.success) {
            closeNewUserModal();
            loadAccounts();
        } else {
            alert("Error: " + data.error);
        }
    } catch (e) {
        alert("Error: " + e);
    }
}

async function toggleUser(username) {
    try {
        await fetch(`/api/accounts/users/${username}/toggle`, { method: 'POST' });
        loadAccounts();
    } catch (e) {
        alert("Error: " + e);
    }
}

async function deleteUser(username) {
    if (!confirm(`¿Eliminar al usuario '${username}' del sistema?`)) return;
    try {
        await fetch(`/api/accounts/users/${username}`, { method: 'DELETE' });
        loadAccounts();
    } catch (e) {
        alert("Error: " + e);
    }
}

// ==========================================
// 2. SISTEMA & CONTROL DE ENERGÍA
// ==========================================
async function loadSystemSettings() {
    try {
        const res = await fetch('/api/system/settings');
        const data = await res.json();
        if (data) {
            document.getElementById('sys-input-hostname').value = data.hostname || 'gigarnas';
            document.getElementById('sys-input-port').value = data.webui_port || 8080;
        }
        checkForUpdates();
    } catch (e) {
        console.error("Error loading system settings", e);
    }
}

async function saveSystemSettings() {
    const hostname = document.getElementById('sys-input-hostname').value.trim();
    const webui_port = parseInt(document.getElementById('sys-input-port').value) || 8080;

    try {
        const res = await fetch('/api/system/settings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ hostname, webui_port })
        });
        const data = await res.json();
        alert(data.message || "Ajustes guardados");
    } catch (e) {
        alert("Error guardando ajustes: " + e);
    }
}

function confirmPowerAction(action) {
    const text = action === 'reboot' ? '¿Reiniciar el servidor GigaNas ahora?' : '¿Apagar el servidor GigaNas por completo?';
    if (!confirm(text)) return;
    fetch(`/api/system/${action}`, { method: 'POST' })
        .then(res => res.json())
        .then(d => alert(d.message));
}

// ==========================================
// 3. STORAGE, CREAR POOL & EXPLICACIÓN RAID
// ==========================================
async function loadStorage() {
    try {
        const [poolsRes, flexRes, disksRes] = await Promise.all([
            fetch('/api/storage/pools'),
            fetch('/api/storage/flexpools'),
            fetch('/api/storage/disks')
        ]);
        const pools = await poolsRes.json();
        const flexpools = await flexRes.json();
        availableDisks = await disksRes.json();

        renderStoragePools(pools);
        renderFlexpools(flexpools);
    } catch (e) {
        console.error("Error loading storage", e);
    }
}

async function loadRaidDefinitions() {
    try {
        const res = await fetch('/api/storage/raid-types');
        raidDefinitions = await res.json();

        const grid = document.getElementById('raid-definitions-grid');
        if (!grid) return;

        grid.innerHTML = Object.values(raidDefinitions).map(r => `
            <div class="p-3 bg-tncardsub border border-tnborder rounded space-y-1.5 font-mono">
                <div class="flex justify-between items-center">
                    <span class="font-bold text-white text-xs">${r.name}</span>
                    <span class="px-1.5 py-0.5 rounded text-[9px] font-bold bg-tnblue/20 text-tnblue">Min ${r.min_disks} Discos</span>
                </div>
                <div class="text-[11px] text-slate-300 leading-tight">${r.explanation}</div>
                <div class="pt-1.5 border-t border-tnborder/50 text-[10px] space-y-0.5">
                    <div><strong class="text-tngreen">Tolerancia:</strong> ${r.fault_tolerance}</div>
                    <div><strong class="text-amber-400">Eficiencia:</strong> ${r.efficiency}</div>
                    <div><strong class="text-sky-400">Ideal para:</strong> ${r.use_case}</div>
                </div>
            </div>
        `).join('');
    } catch (e) {
        console.error("Error loading raid defs", e);
    }
}

function openNewPoolModal() {
    document.getElementById('modal-new-pool').classList.remove('hidden');
    onRaidSelectionChange();

    // Populate disk checkboxes
    const container = document.getElementById('pool-disks-checkboxes');
    if (container && availableDisks.length > 0) {
        container.innerHTML = availableDisks.map((d, i) => `
            <label class="flex items-center gap-2 p-1.5 hover:bg-tncard/60 rounded cursor-pointer">
                <input type="checkbox" value="${d.id}" ${i < 3 ? 'checked' : ''} onchange="updateEstimatedSize()" class="pool-disk-checkbox rounded bg-tncard border-tnborder text-tnblue">
                <span class="text-white font-bold">${d.id}</span>
                <span class="text-tnmuted font-normal">(${d.model} &bull; ${d.size_human} &bull; ${d.type})</span>
            </label>
        `).join('');
    }
    updateEstimatedSize();
}

function closeNewPoolModal() {
    document.getElementById('modal-new-pool').classList.add('hidden');
}

function onRaidSelectionChange() {
    const sel = document.getElementById('select-pool-raid').value;
    const r = raidDefinitions[sel];
    const box = document.getElementById('raid-explainer-box');
    if (!box || !r) return;

    box.innerHTML = `
        <div class="text-white font-bold flex items-center justify-between">
            <span>${r.name}</span>
            <span class="text-tnblue">Mínimo: ${r.min_disks} discos</span>
        </div>
        <div class="text-slate-300">${r.explanation}</div>
        <div class="grid grid-cols-2 gap-2 pt-1 border-t border-tnborder/50 text-[10px]">
            <div><span class="text-tnmuted">Tolerancia a fallos:</span> <strong class="text-tngreen">${r.fault_tolerance}</strong></div>
            <div><span class="text-tnmuted">Eficiencia:</span> <strong class="text-amber-400">${r.efficiency}</strong></div>
        </div>
        <div class="text-[10px] text-sky-400">✓ ${r.use_case}</div>
    `;

    document.getElementById('pool-min-disks-text').innerText = r.min_disks;
    updateEstimatedSize();
}

function updateEstimatedSize() {
    const checked = Array.from(document.querySelectorAll('.pool-disk-checkbox:checked')).map(c => c.value);
    const sel = document.getElementById('select-pool-raid').value;
    const count = checked.length;
    let sizeText = '0 GB';

    if (sel === 'stripe') sizeText = `${count * 4.0} TB Útiles (100% Espacio)`;
    else if (sel === 'mirror') sizeText = `${(count * 4.0) / 2} TB Útiles (50% Espejo)`;
    else if (sel === 'raidz1') sizeText = `${Math.max(0, (count - 1) * 4.0)} TB Útiles (1 Paridad)`;
    else if (sel === 'raidz2') sizeText = `${Math.max(0, (count - 2) * 4.0)} TB Útiles (2 Paridades)`;
    else if (sel === 'raidz3') sizeText = `${Math.max(0, (count - 3) * 4.0)} TB Útiles (3 Paridades)`;
    else if (sel === 'flexpool') sizeText = `${Math.max(0, (count - 1) * 4.0)} TB Útiles (Paridad Dedicada)`;

    document.getElementById('pool-estimated-size').innerText = sizeText;
}

async function submitNewPool() {
    const name = document.getElementById('input-pool-name').value.trim();
    const raid_type = document.getElementById('select-pool-raid').value;
    const compression = document.getElementById('select-pool-compression').value;
    const disks = Array.from(document.querySelectorAll('.pool-disk-checkbox:checked')).map(c => c.value);

    if (!name) return alert("Por favor escribe un nombre para el pool.");

    try {
        const res = await fetch('/api/storage/pools/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, raid_type, disks, compression })
        });
        const data = await res.json();
        if (data.success) {
            alert(data.message);
            closeNewPoolModal();
            loadStorage();
        } else {
            alert("Error: " + data.error);
        }
    } catch (e) {
        alert("Error: " + e);
    }
}

function renderStoragePools(pools) {
    const container = document.getElementById('storage-pools-table');
    if (!container) return;

    container.innerHTML = pools.map(p => `
        <div class="p-3 bg-tncardsub border border-tnborder rounded mb-3 flex justify-between items-center text-xs font-mono">
            <div>
                <div class="text-white font-bold text-sm">${p.name} <span class="text-[10px] text-tngreen font-normal">(${p.status})</span></div>
                <div class="text-tnmuted mt-0.5">${p.type} &bull; Compresión: ${p.compression_ratio || 'zstd'}</div>
            </div>
            <div class="text-right">
                <div class="text-white font-bold">${p.allocated} / ${p.size} (${p.capacity_percent}% usado)</div>
                <div class="text-[10px] text-tnmuted">${p.scrub_status}</div>
            </div>
        </div>
    `).join('');
}

function renderFlexpools(flexpools) {
    const container = document.getElementById('storage-flexpools-container');
    if (!container) return;

    container.innerHTML = flexpools.map(f => `
        <div class="p-3 bg-tncardsub border border-tnborder rounded text-xs font-mono space-y-2">
            <div class="flex justify-between items-center">
                <span class="text-white font-bold">${f.name}</span>
                <span class="text-tngreen">${f.status}</span>
            </div>
            <div class="text-tnmuted">${f.description}</div>
            <div class="grid grid-cols-2 gap-2 text-[11px] pt-1 border-t border-tnborder/50">
                <div>Paridad: <span class="text-white">${f.parity_disk}</span></div>
                <div>Discos de Datos: <span class="text-white">${f.data_disks.join(', ')}</span></div>
            </div>
        </div>
    `).join('');
}

// ==========================================
// 4. TÚNEL MÓVIL SEGURO & CÓDIGO QR
// ==========================================
async function loadTunnelDevices() {
    try {
        const res = await fetch('/api/tunnels/devices');
        const devices = await res.json();
        const tbody = document.getElementById('tunnel-devices-table');
        if (!tbody) return;

        tbody.innerHTML = devices.map(d => `
            <tr class="hover:bg-tncardsub/80 transition-all">
                <td class="p-3 font-bold text-white flex items-center gap-2">
                    <i data-lucide="smartphone" class="w-3.5 h-3.5 text-sky-400"></i> ${d.name}
                </td>
                <td class="p-3 text-tnblue">${d.assigned_ip}</td>
                <td class="p-3 text-slate-300">${d.access_scope}</td>
                <td class="p-3">
                    <span class="px-1.5 py-0.5 rounded text-[10px] font-bold ${d.status === 'Conectado' ? 'text-tngreen bg-emerald-950/40' : 'text-slate-400 bg-slate-800'}">
                        ${d.status}
                    </span>
                </td>
                <td class="p-3 text-tnmuted">${d.last_handshake}</td>
                <td class="p-3 text-slate-300">${d.bytes_rx_mb.toFixed(1)} MB / ${d.bytes_tx_mb.toFixed(1)} MB</td>
                <td class="p-3 text-right">
                    <button onclick="revokeTunnelDevice('${d.id}')" class="px-2 py-1 rounded bg-rose-950/40 hover:bg-rose-900/60 border border-rose-800 text-rose-300 text-[10px]">
                        Revocar
                    </button>
                </td>
            </tr>
        `).join('');
        lucide.createIcons();
    } catch (e) {
        console.error("Error loading tunnel devices", e);
    }
}

function openMobileTunnelModal() {
    document.getElementById('modal-qr-tunnel').classList.remove('hidden');
    document.getElementById('qr-step-input').classList.remove('hidden');
    document.getElementById('qr-step-display').classList.add('hidden');
}

function closeMobileTunnelModal() {
    document.getElementById('modal-qr-tunnel').classList.add('hidden');
}

async function submitGenerateQr() {
    const name = document.getElementById('tunnel-input-name').value.trim() || 'Celular';
    const scope = document.getElementById('tunnel-input-scope').value;

    try {
        const res = await fetch('/api/tunnels/mobile/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, scope })
        });
        const data = await res.json();
        if (data.success && data.qr_code_image) {
            document.getElementById('qr-image-display').src = data.qr_code_image;
            document.getElementById('qr-step-input').classList.add('hidden');
            document.getElementById('qr-step-display').classList.remove('hidden');
            loadTunnelDevices();
        } else {
            alert("Error al generar túnel.");
        }
    } catch (e) {
        alert("Error: " + e);
    }
}

async function revokeTunnelDevice(id) {
    if (!confirm("¿Revocar el acceso inmediato a este dispositivo móvil?")) return;
    try {
        await fetch(`/api/tunnels/devices/${id}`, { method: 'DELETE' });
        loadTunnelDevices();
    } catch (e) {
        alert("Error: " + e);
    }
}

// ==========================================
// 5. SHARING (SAMBA SMB)
// ==========================================
async function loadShares() {
    try {
        const res = await fetch('/api/shares/smb');
        const shares = await res.json();
        const container = document.getElementById('smb-shares-table');
        if (!container) return;

        container.innerHTML = shares.map(s => `
            <div class="p-3 bg-tncardsub border border-tnborder rounded flex justify-between items-center text-xs font-mono">
                <div>
                    <div class="text-white font-bold">\\\\GIGANAS\\${s.name}</div>
                    <div class="text-tnmuted">${s.path}</div>
                </div>
                <div class="flex items-center gap-3">
                    <span class="text-tnmuted">${s.guest_ok ? 'Acceso Libre' : 'Credenciales'}</span>
                    <button onclick="deleteShare('${s.id}')" class="text-rose-400 hover:text-white p-1">
                        <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                    </button>
                </div>
            </div>
        `).join('');
        lucide.createIcons();
    } catch (e) {
        console.error("Error loading shares", e);
    }
}

function openNewShareModal() {
    document.getElementById('modal-new-share').classList.remove('hidden');
}

function closeNewShareModal() {
    document.getElementById('modal-new-share').classList.add('hidden');
}

async function submitNewShare() {
    const name = document.getElementById('input-share-name').value.trim();
    const path = document.getElementById('input-share-path').value.trim();
    const guest_ok = document.getElementById('input-share-guest').checked;

    if (!name) return alert("Por favor escribe un nombre para la compartición.");

    try {
        await fetch('/api/shares/smb', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, path, guest_ok, comment: "Recurso GigaNas" })
        });
        closeNewShareModal();
        await loadShares();
    } catch (e) {
        alert("Error: " + e);
    }
}

async function deleteShare(id) {
    if (!confirm("¿Deseas eliminar este recurso compartido?")) return;
    try {
        await fetch(`/api/shares/smb/${id}`, { method: 'DELETE' });
        await loadShares();
    } catch (e) {
        alert("Error: " + e);
    }
}

// ==========================================
// 6. APPS (DOCKER)
// ==========================================
async function loadApps() {
    try {
        const res = await fetch('/api/apps/catalog');
        const apps = await res.json();
        const container = document.getElementById('apps-catalog-grid');
        if (!container) return;

        container.innerHTML = apps.map(app => `
            <div class="p-3 bg-tncardsub border border-tnborder rounded flex flex-col justify-between space-y-3 text-xs">
                <div>
                    <div class="flex justify-between items-start">
                        <span class="font-bold text-white text-sm">${app.name}</span>
                        <span class="text-[10px] font-mono ${app.installed ? 'text-tngreen font-bold' : 'text-tnmuted'}">
                            ${app.installed ? 'ONLINE' : 'DISPONIBLE'}
                        </span>
                    </div>
                    <p class="text-tnmuted text-[11px] mt-1 leading-relaxed">${app.description}</p>
                </div>
                <div class="flex gap-2 pt-2 border-t border-tnborder/50">
                    ${app.installed ? `
                        <button onclick="toggleApp('${app.id}')" class="flex-1 py-1 rounded bg-[#2e3440] hover:bg-[#3e4756] text-white font-mono text-[10px]">
                            ${app.status === 'running' ? 'DETENER' : 'INICIAR'}
                        </button>
                        ${app.webui_port > 0 ? `
                            <a href="http://${window.location.hostname}:${app.webui_port}" target="_blank" class="px-3 py-1 rounded bg-tnblue text-white font-mono text-[10px] flex items-center gap-1">
                                ABRIR
                            </a>
                        ` : ''}
                    ` : `
                        <button onclick="installApp('${app.id}')" class="w-full py-1 tn-btn-primary">
                            INSTALAR
                        </button>
                    `}
                </div>
            </div>
        `).join('');
        lucide.createIcons();
    } catch (e) {
        console.error("Error loading apps", e);
    }
}

async function installApp(id) {
    try {
        await fetch(`/api/apps/${id}/install`, { method: 'POST' });
        await loadApps();
    } catch (e) {
        alert("Error: " + e);
    }
}

async function toggleApp(id) {
    try {
        await fetch(`/api/apps/${id}/toggle`, { method: 'POST' });
        await loadApps();
    } catch (e) {
        alert("Error: " + e);
    }
}

// ==========================================
// 7. OPTIMIZADOR
// ==========================================
async function loadOptimizer() {
    try {
        const res = await fetch('/api/optimizer/status');
        const data = await res.json();
        document.getElementById('opt-arc-profile').innerText = data.arc_tuning.profile;
        document.getElementById('opt-arc-min').innerText = `${data.arc_tuning.arc_min_mb} MB`;
        document.getElementById('opt-arc-max').innerText = `${data.arc_tuning.arc_max_mb} MB`;
    } catch (e) {
        console.error("Error loading optimizer", e);
    }
}

async function triggerOptimization() {
    try {
        const res = await fetch('/api/optimizer/apply', { method: 'POST' });
        const data = await res.json();
        alert("Afinación completada:\n\n" + data.message);
        await loadOptimizer();
    } catch (e) {
        alert("Error: " + e);
    }
}

// ==========================================
// 8. ACTUALIZACIÓN AUTOMÁTICA DEL SISTEMA (OTA)
// ==========================================
let updatePollTimer = null;

async function checkForUpdates() {
    const channelSelect = document.getElementById('update-channel-select');
    const channel = channelSelect ? channelSelect.value : 'stable';

    const banner = document.getElementById('ota-update-banner');
    const modalContent = document.getElementById('modal-update-content');
    
    if (banner) banner.innerHTML = '<div class="text-tnblue flex items-center gap-2"><i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i> Consultando servidores oficiales de GigaNas...</div>';
    if (modalContent) modalContent.innerHTML = '<div class="text-tnblue flex items-center gap-2"><i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i> Consultando actualizaciones disponibles...</div>';
    lucide.createIcons();

    try {
        const res = await fetch(`/api/system/updates/check?channel=${channel}`);
        const data = await res.json();

        const currentVerEl = document.getElementById('ota-current-version');
        if (currentVerEl) currentVerEl.innerText = `v${data.current_version}`;

        const lastCheckEl = document.getElementById('ota-last-checked');
        if (lastCheckEl) lastCheckEl.innerText = new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

        if (data.update_available) {
            const upd = data.details;
            const html = `
                <div class="space-y-3">
                    <div class="flex justify-between items-start">
                        <div>
                            <div class="text-tngreen font-bold text-sm flex items-center gap-1.5">
                                <i data-lucide="sparkles" class="w-4 h-4"></i> Nueva Versión Disponible: v${upd.version}
                            </div>
                            <div class="text-slate-300 text-xs mt-0.5">${upd.summary}</div>
                        </div>
                        <span class="px-2 py-0.5 rounded bg-tnblue/20 text-tnblue font-bold text-[10px] border border-tnblue/30">
                            ${upd.size_mb} MB
                        </span>
                    </div>

                    <div class="p-3 bg-tncard border border-tnborder rounded space-y-1.5 text-[11px]">
                        <div class="text-white font-bold mb-1">Novedades y Mejoras Incluidas:</div>
                        ${upd.changelog.map(item => `
                            <div class="flex items-start gap-1.5 text-slate-300">
                                <i data-lucide="check-circle" class="w-3.5 h-3.5 text-tngreen shrink-0 mt-0.5"></i>
                                <span>${item}</span>
                            </div>
                        `).join('')}
                    </div>

                    <div class="pt-2 flex gap-2">
                        <button onclick="startSystemUpdate()" class="tn-btn-primary flex-1 py-2 text-xs flex items-center justify-center gap-2">
                            <i data-lucide="download" class="w-4 h-4"></i> DESCARGAR E INSTALAR ACTUALIZACIÓN AHORA (1-CLIC)
                        </button>
                    </div>
                </div>
            `;
            if (banner) banner.innerHTML = html;
            if (modalContent) modalContent.innerHTML = html;
        } else {
            const html = `
                <div class="p-3 bg-emerald-950/30 border border-emerald-800 rounded flex items-center gap-2 text-tngreen">
                    <i data-lucide="check-circle-2" class="w-5 h-5"></i>
                    <div>
                        <div class="font-bold">El sistema está actualizado</div>
                        <div class="text-[11px] text-slate-300">Ya cuentas con la versión oficial más reciente (v${data.current_version}).</div>
                    </div>
                </div>
            `;
            if (banner) banner.innerHTML = html;
            if (modalContent) modalContent.innerHTML = html;
        }
        lucide.createIcons();
    } catch (e) {
        alert("Error al buscar actualizaciones: " + e);
    }
}

async function startSystemUpdate() {
    if (!confirm("¿Deseas iniciar la actualización del sistema operativo ahora?\n\nEl sistema descargará los paquetes oficiales, creará un snapshot de seguridad y aplicará las mejoras automáticamente.")) return;

    try {
        await fetch('/api/system/updates/install', { method: 'POST' });

        // Show progress boxes
        const progBox = document.getElementById('ota-progress-box');
        const modalProgBox = document.getElementById('modal-update-progress-box');
        if (progBox) progBox.classList.remove('hidden');
        if (modalProgBox) modalProgBox.classList.remove('hidden');

        // Poll progress
        if (updatePollTimer) clearInterval(updatePollTimer);
        updatePollTimer = setInterval(pollUpdateProgress, 400);
    } catch (e) {
        alert("Error al iniciar actualización: " + e);
    }
}

async function pollUpdateProgress() {
    try {
        const res = await fetch('/api/system/updates/status');
        const st = await res.json();

        // Update percent and steps in page
        const pctText = document.getElementById('ota-progress-percent');
        const bar = document.getElementById('ota-progress-bar');
        const stepText = document.getElementById('ota-progress-step-text');

        if (pctText) pctText.innerText = `${st.progress_percent}%`;
        if (bar) bar.style.width = `${st.progress_percent}%`;
        if (stepText) stepText.innerText = st.current_step;

        // Update modal progress
        const modalPct = document.getElementById('modal-update-percent');
        const modalBar = document.getElementById('modal-update-bar');
        const modalStep = document.getElementById('modal-update-step-text');

        if (modalPct) modalPct.innerText = `${st.progress_percent}%`;
        if (modalBar) modalBar.style.width = `${st.progress_percent}%`;
        if (modalStep) modalStep.innerText = st.current_step;

        if (st.status === 'completed') {
            clearInterval(updatePollTimer);
            updatePollTimer = null;
            
            const currentVerEl = document.getElementById('ota-current-version');
            if (currentVerEl) currentVerEl.innerText = `v${st.current_version}`;

            const sysVer = document.getElementById('sys-version');
            if (sysVer) sysVer.innerText = `GigaNas-${st.current_version} (Actualizado)`;

            setTimeout(() => {
                alert("🎉 ¡Sistema Operativo Actualizado con Éxito!\n\nSe ha aplicado la versión " + st.current_version + " con éxito sin necesidad de usar comandos ni tocar GitHub.");
                checkForUpdates();
            }, 600);
        } else if (st.status === 'error') {
            clearInterval(updatePollTimer);
            updatePollTimer = null;
            alert("Error en la actualización: " + st.error_message);
        }
    } catch (e) {
        console.error("Polling error", e);
    }
}

async function rollbackUpdate() {
    if (!confirm("¿Deseas revertir el sistema a la versión previa anterior al último update?")) return;
    try {
        const res = await fetch('/api/system/updates/rollback', { method: 'POST' });
        const data = await res.json();
        alert(data.message || data.error);
        checkForUpdates();
        loadSystemStatus();
    } catch (e) {
        alert("Error: " + e);
    }
}

function openUpdatesModal() {
    document.getElementById('modal-system-update').classList.remove('hidden');
    checkForUpdates();
}

function closeUpdatesModal() {
    document.getElementById('modal-system-update').classList.add('hidden');
}
