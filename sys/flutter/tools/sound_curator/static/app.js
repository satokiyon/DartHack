// static/app.js
let soundList = [];
let currentFilter = 'all';
let currentCategory = 'all';
let currentCombatSub = 'all';
let searchQuery = '';

let volumeDataMap = {};
let currentVolFilter = 'all';
let isAuditing = false;

let activeTargetItem = null;
let activeSelectedFile = null;

// URLクエリパラメータの初期解析 (?category=combat 等)
const urlParams = new URLSearchParams(window.location.search);
const initialCategoryParam = urlParams.get('category');
if (initialCategoryParam) {
  currentCategory = initialCategoryParam;
}

// キーワード抽出ヘルパー
function extractKeywords(item) {
  // アイテム固有の特化キーワードが定義されていれば最優先
  if (item.keywords_ja || item.keywords_en) {
    return {
      ja: item.keywords_ja || item.description,
      en: item.keywords_en || item.id.replace(/^(se_|sound_|ach_|sa2_|voice_)/, '').replace(/_/g, ' ')
    };
  }

  const desc = item.description || '';
  const id = item.id || '';

  // 括弧内を除去
  let cleanDesc = desc.replace(/（.*?）/g, '').replace(/\(.*?\)/g, '').trim();
  // 「〜の音」「〜する音」などを整理
  cleanDesc = cleanDesc.replace(/の音$/, '').replace(/する音$/, '').replace(/音$/, '').trim();

  // 英語IDから英単語を抽出 (se_door_open -> door open)
  let cleanId = id.replace(/^(se_|sound_|ach_|sa2_|voice_)/, '').replace(/_/g, ' ');

  return {
    ja: cleanDesc || desc,
    en: cleanId
  };
}

// 13サイトの外部検索URL生成
function getSearchUrls(item) {
  const kw = extractKeywords(item);
  const qJa = encodeURIComponent(kw.ja);
  const qEn = encodeURIComponent(kw.en);

  return {
    // 国内サイト (日本語検索)
    lab: `https://soundeffect-lab.info/?s=${qJa}`,
    onjin: `https://www.google.com/search?q=site:on-jin.com+${qJa}`,
    otologic: `https://otologic.jp/free/se/search?keyword=${qJa}`,
    dict: `https://sounddictionary.info/?s=${qJa}`,
    springin: `https://www.springin.org/sound-stock/`,
    maou: `https://maou.audio/?s=${qJa}`,
    pocket: `https://pocket-se.info/?s=${qJa}`,
    amacha: `https://amachamusic.chagasi.com/`,

    // 海外・オープン素材サイト (英語検索)
    pixabay: `https://pixabay.com/sound-effects/search/${qEn}/`,
    sounddino: `https://sounddino.com/search/?q=${qEn}`,
    freesound: `https://freesound.org/search/?q=${qEn}&f=license:%22Creative+Commons+0%22+OR+license:%22Attribution%22`,
    zapsplat: `https://www.zapsplat.com/?s=${qEn}&post_type=music&sound-effect-category-id=`,
    oga: `https://opengameart.org/art-search-advanced?keys=${qEn}&title=&field_art_tags_tid_op=and&name=&sort_by=score&sort_order=DESC&items_per_page=24&Collection=`
  };
}

async function loadData() {
  try {
    const [soundsRes, statsRes] = await Promise.all([
      fetch('/api/sounds'),
      fetch('/api/stats')
    ]);
    soundList = await soundsRes.json();
    const stats = await statsRes.json();
    updateStats(stats);
    renderCards();
  } catch (err) {
    console.error('Failed to load data:', err);
  }
}

function updateStats(stats) {
  document.getElementById('statsReadyCount').textContent = stats.ready;
  document.getElementById('statsTotalCount').textContent = stats.total;
  document.getElementById('statsPercent').textContent = stats.percent;
  document.getElementById('progressBar').style.width = `${stats.percent}%`;

  if (stats.by_category) {
    const catLabels = {
      combat: '⚔️ 戦闘',
      effect: '効果音',
      achievement: '実績',
      instrument: '楽器',
      voice: '声音'
    };
    for (const [cat, info] of Object.entries(stats.by_category)) {
      const btn = document.querySelector(`.filter-btn[data-cat="${cat}"]`);
      if (btn) {
        const label = catLabels[cat] || cat;
        btn.textContent = `${label} (${info.total})`;
      }
    }
  }
}

function renderCards() {
  const grid = document.getElementById('cardGrid');
  grid.innerHTML = '';

  const filtered = soundList.filter(item => {
    // 状態フィルタ
    if (currentFilter === 'ready' && item.status !== 'ready') return false;
    if (currentFilter === 'pending' && item.status !== 'pending') return false;

    // カテゴリフィルタ
    if (currentCategory !== 'all' && item.category !== currentCategory) return false;

    // 戦闘サブカテゴリフィルタ
    if (currentCategory === 'combat' && currentCombatSub !== 'all' && item.sub_category !== currentCombatSub) return false;

    // 音量診断フィルタ
    if (currentVolFilter !== 'all') {
      const vol = volumeDataMap[item.filename];
      if (!vol) return false;
      if (currentVolFilter === 'issues' && !['WARN', 'ERROR', 'CLIP'].includes(vol.status)) return false;
      if (currentVolFilter === 'ok' && vol.status !== 'OK') return false;
      if (currentVolFilter === 'warn' && vol.status !== 'WARN') return false;
      if (currentVolFilter === 'error' && vol.status !== 'ERROR') return false;
      if (currentVolFilter === 'clip' && vol.status !== 'CLIP') return false;
    }

    // 検索クエリ
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      const matchName = item.filename.toLowerCase().includes(q);
      const matchId = item.id.toLowerCase().includes(q);
      const matchDesc = item.description.toLowerCase().includes(q);
      const matchCaller = (item.caller || '').toLowerCase().includes(q);
      const matchKwJa = (item.keywords_ja || '').toLowerCase().includes(q);
      const matchKwEn = (item.keywords_en || '').toLowerCase().includes(q);
      if (!matchName && !matchId && !matchDesc && !matchCaller && !matchKwJa && !matchKwEn) return false;
    }

    return true;
  });

  filtered.forEach(item => {
    const card = document.createElement('div');
    card.className = `sound-card ${item.status}`;

    const isReady = item.status === 'ready';
    const urls = getSearchUrls(item);

    // サブカテゴリバッジ
    let subcatBadge = '';
    if (item.sub_category) {
      const subNames = {
        melee: '🗡️ 近接',
        ranged: '🏹 遠隔',
        magic: '✨ 魔法',
        monster: '🐾 モンスター'
      };
      const label = subNames[item.sub_category] || item.sub_category;
      subcatBadge = `<span class="subcat-tag ${escapeHtml(item.sub_category)}">${escapeHtml(label)}</span>`;
    }

    // 特化検索キーワード表示
    let keywordHintHtml = '';
    if (item.keywords_ja || item.keywords_en) {
      keywordHintHtml = `
        <div class="keywords-hint">
          <span>🔍 推奨検索語:</span>
          <strong>${escapeHtml(item.keywords_ja || '')}</strong>
          <span style="color:#64748b;">/</span>
          <span>${escapeHtml(item.keywords_en || '')}</span>
        </div>
      `;
    }

    // 音量診断情報表示
    let volBoxHtml = '';
    const volInfo = volumeDataMap[item.filename];
    if (isReady && volInfo) {
      const needsFix = ['WARN', 'ERROR', 'CLIP'].includes(volInfo.status);
      const fixBtnHtml = `
        <button class="btn-fix" onclick="fixVolume('${escapeJs(item.filename)}')">
          🔧 適正化 (Fix)
        </button>
      `;
      volBoxHtml = `
        <div class="vol-box">
          <div class="vol-header">
            <span class="vol-badge ${escapeHtml(volInfo.status)}">${escapeHtml(volInfo.status)}</span>
            <span style="color: var(--text-muted);">${escapeHtml(volInfo.message || '')}</span>
            ${fixBtnHtml}
          </div>
          <div class="vol-details">
            <span>ピーク: <strong>${volInfo.max_volume.toFixed(1)} dBFS</strong></span>
            <span>平均: <strong>${volInfo.mean_volume.toFixed(1)} dBFS</strong></span>
            <span>長さ: <strong>${volInfo.duration.toFixed(2)}s</strong></span>
          </div>
        </div>
      `;
    }

    let bodyHtml = '';
    if (isReady) {
      bodyHtml = `
        <div class="audio-player-box">
          <audio controls preload="none" id="audio_${escapeHtml(item.id)}" src="/sounds/${encodeURIComponent(item.filename)}?t=${Date.now()}"></audio>
        </div>
        ${volBoxHtml}
        <div class="meta-info">
          出典: <strong>${escapeHtml(item.source_site || '不明')}</strong> |
          作者: <strong>${escapeHtml(item.author || '不明')}</strong> |
          ライセンス: <strong>${escapeHtml(item.license || '不明')}</strong>
          ${item.source_url ? `<br>URL: <a href="${escapeHtml(item.source_url)}" target="_blank" rel="noopener">リンク</a>` : ''}
          ${item.notes ? `<br>備考: ${escapeHtml(item.notes)}` : ''}
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <button class="btn-badge badge-lab" onclick="openUploadModalFor('${escapeJs(item.id)}')">🔄 上書き更新</button>
          <button class="btn-delete" onclick="deleteSound('${escapeJs(item.id)}')">🗑 割り当て解除</button>
        </div>
      `;
    } else {
      bodyHtml = `
        <div class="search-badges-container">
          <!-- 国内サイト (8件) -->
          <div class="badge-group">
            <span class="badge-group-label">🇯🇵国内:</span>
            <a class="btn-badge badge-lab" href="${urls.lab}" target="_blank" rel="noopener" title="効果音ラボ (商用フリー・クレジット不要)">効果音ラボ</a>
            <a class="btn-badge badge-onjin" href="${urls.onjin}" target="_blank" rel="noopener" title="On-Jin ～音人～ (老舗ゲーム効果音)">音人</a>
            <a class="btn-badge badge-otologic" href="${urls.otologic}" target="_blank" rel="noopener" title="OtoLogic (高品質・CC BY 4.0)">OtoLogic</a>
            <a class="btn-badge badge-dict" href="${urls.dict}" target="_blank" rel="noopener" title="効果音辞典 (完全フリー)">効果音辞典</a>
            <a class="btn-badge badge-springin" href="${urls.springin}" target="_blank" rel="noopener" title="Springin' Sound Stock">Springin'</a>
            <a class="btn-badge badge-maou" href="${urls.maou}" target="_blank" rel="noopener" title="魔王魂 (RPG戦闘・魔法)">魔王魂</a>
            <a class="btn-badge badge-pocket" href="${urls.pocket}" target="_blank" rel="noopener" title="ポケットサウンド">ポケットSE</a>
            <a class="btn-badge badge-amacha" href="${urls.amacha}" target="_blank" rel="noopener" title="甘茶の音楽工房 (ジングル・実績)">甘茶</a>
          </div>

          <!-- 海外・オープン素材 (5件) -->
          <div class="badge-group">
            <span class="badge-group-label">🌐海外:</span>
            <a class="btn-badge badge-pixabay" href="${urls.pixabay}" target="_blank" rel="noopener" title="Pixabay (膨大・高品質・クレジット不要)">Pixabay</a>
            <a class="btn-badge badge-sounddino" href="${urls.sounddino}" target="_blank" rel="noopener" title="SoundDino (ロイヤリティフリー)">SoundDino</a>
            <a class="btn-badge badge-freesound" href="${urls.freesound}" target="_blank" rel="noopener" title="Freesound (CC0/CC-BY)">Freesound</a>
            <a class="btn-badge badge-zapsplat" href="${urls.zapsplat}" target="_blank" rel="noopener" title="ZapSplat (世界最大級10万音)">ZapSplat</a>
            <a class="btn-badge badge-oga" href="${urls.oga}" target="_blank" rel="noopener" title="OpenGameArt (ゲーム用オープン素材)">OpenGameArt</a>
          </div>
        </div>
        <div class="drop-zone" id="dropZone_${item.id}">
          📥 音声ファイル（WAV/MP3/OGG）をここにドロップ<br>またはクリックして選択
        </div>
      `;
    }

    card.innerHTML = `
      <div class="card-header">
        <div style="display:flex; align-items:center; flex-wrap:wrap;">
          <div class="card-title">${escapeHtml(item.filename)}</div>
          ${subcatBadge}
        </div>
        <span class="status-tag ${item.status}">${isReady ? '確定済' : '未設定'}</span>
      </div>
      <div class="card-desc">${escapeHtml(item.description)}</div>
      ${keywordHintHtml}
      <div class="card-caller">呼び出し: ${escapeHtml(item.caller || '-')} (ID: ${escapeHtml(item.id)})</div>
      ${bodyHtml}
    `;

    grid.appendChild(card);

    // ドロップゾーンのイベント設定
    if (!isReady) {
      const dropZone = card.querySelector(`#dropZone_${CSS.escape(item.id)}`);
      if (dropZone) {
        setupDropZone(dropZone, item);
      }
    }
  });
}

function setupDropZone(dropZone, item) {
  ['dragenter', 'dragover'].forEach(eventName => {
    dropZone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropZone.classList.add('dragover');
    }, false);
  });

  ['dragleave', 'drop'].forEach(eventName => {
    dropZone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropZone.classList.remove('dragover');
    }, false);
  });

  dropZone.addEventListener('drop', (e) => {
    const dt = e.dataTransfer;
    const files = dt.files;
    if (files.length > 0) {
      handleFileSelected(item, files[0]);
    }
  });

  dropZone.addEventListener('click', () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'audio/*';
    input.onchange = (e) => {
      if (e.target.files.length > 0) {
        handleFileSelected(item, e.target.files[0]);
      }
    };
    input.click();
  });
}

function handleFileSelected(item, file) {
  activeTargetItem = item;
  activeSelectedFile = file;

  document.getElementById('modalTitle').textContent = `音源の確定: ${item.filename}`;
  document.getElementById('modalFilename').value = `${item.filename} (${item.description})`;
  document.getElementById('modalSelectedFileName').value = `${file.name} (${Math.round(file.size / 1024)} KB)`;

  // 自動推定
  const siteSelect = document.getElementById('modalSourceSite');
  const licenseSelect = document.getElementById('modalLicense');
  const authorInput = document.getElementById('modalAuthor');
  const urlInput = document.getElementById('modalSourceUrl');

  const fn = file.name.toLowerCase();

  if (fn.includes('soundeffect-lab') || fn.includes('効果音ラボ')) {
    siteSelect.value = '効果音ラボ';
    licenseSelect.value = '効果音ラボ利用規約（商用可・ゲーム組込可・クレジット任意）';
    authorInput.value = '効果音ラボ';
    urlInput.value = 'https://soundeffect-lab.info/';
  } else if (fn.includes('pixabay')) {
    siteSelect.value = 'Pixabay';
    licenseSelect.value = 'Pixabay Content License（商用可・ゲーム組込可・クレジット不要）';
    authorInput.value = 'Pixabay Creator';
    urlInput.value = 'https://pixabay.com/sound-effects/';
  } else if (fn.includes('sounddino')) {
    siteSelect.value = 'SoundDino';
    licenseSelect.value = 'SoundDino Royalty-Free（商用可・クレジット不要）';
    authorInput.value = 'SoundDino';
    urlInput.value = 'https://sounddino.com/';
  } else if (fn.includes('on-jin') || fn.includes('onjin') || fn.includes('音人')) {
    siteSelect.value = 'On-Jin ～音人～';
    licenseSelect.value = 'On-Jin利用規約（商用可・ゲーム組込可・クレジット表記）';
    authorInput.value = 'On-Jin ～音人～';
    urlInput.value = 'https://on-jin.com/';
  } else if (fn.includes('otologic')) {
    siteSelect.value = 'OtoLogic';
    licenseSelect.value = 'OtoLogic利用規約（CC BY 4.0 / クレジット表記）';
    authorInput.value = 'OtoLogic';
    urlInput.value = 'https://otologic.jp/';
  } else if (fn.includes('sounddictionary') || fn.includes('効果音辞典')) {
    siteSelect.value = '効果音辞典';
    licenseSelect.value = '効果音辞典利用規約（商用可・クレジット不要）';
    authorInput.value = '効果音辞典';
    urlInput.value = 'https://sounddictionary.info/';
  } else if (fn.includes('springin')) {
    siteSelect.value = 'Springin\' Sound Stock';
    licenseSelect.value = 'Springin\'利用規約（商用可・クレジット不要）';
    authorInput.value = 'Springin\' Sound Stock';
    urlInput.value = 'https://www.springin.org/sound-stock/';
  } else if (fn.includes('maoudamashii') || fn.includes('maou') || fn.includes('魔王魂')) {
    siteSelect.value = '魔王魂';
    licenseSelect.value = '魔王魂利用規約（商用可・クレジット表記）';
    authorInput.value = '魔王魂';
    urlInput.value = 'https://maou.audio/';
  } else if (fn.includes('pocket')) {
    siteSelect.value = 'ポケットサウンド';
    licenseSelect.value = 'ポケットサウンド利用規約（商用可・クレジット表記）';
    authorInput.value = 'ポケットサウンド';
    urlInput.value = 'https://pocket-se.info/';
  } else if (fn.includes('amacha') || fn.includes('甘茶')) {
    siteSelect.value = '甘茶の音楽工房';
    licenseSelect.value = '甘茶の音楽工房利用規約（商用可・ゲーム組込可・クレジット任意）';
    authorInput.value = '甘茶の音楽工房';
    urlInput.value = 'https://amachamusic.chagasi.com/';
  } else if (fn.includes('zapsplat')) {
    siteSelect.value = 'ZapSplat';
    licenseSelect.value = 'ZapSplat Standard License（商用可・クレジット表記）';
    authorInput.value = 'ZapSplat';
    urlInput.value = 'https://www.zapsplat.com/';
  } else if (fn.includes('freesound') || /^\d+__/.test(fn)) {
    siteSelect.value = 'Freesound.org';
    licenseSelect.value = 'CC-BY 4.0';
    authorInput.value = '';
    urlInput.value = 'https://freesound.org/';
  }

  document.getElementById('uploadModal').classList.add('active');
}

function openUploadModalFor(id) {
  const item = soundList.find(x => x.id === id);
  if (!item) return;

  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'audio/*';
  input.onchange = (e) => {
    if (e.target.files.length > 0) {
      handleFileSelected(item, e.target.files[0]);
    }
  };
  input.click();
}

document.getElementById('modalSourceSite').addEventListener('change', (e) => {
  const site = e.target.value;
  const siteDefaults = {
    '効果音ラボ': { author: '効果音ラボ', url: 'https://soundeffect-lab.info/', license: '効果音ラボ利用規約（商用可・ゲーム組込可・クレジット任意）' },
    'On-Jin ～音人～': { author: 'On-Jin ～音人～', url: 'https://on-jin.com/', license: 'On-Jin利用規約（商用可・ゲーム組込可・クレジット表記）' },
    'OtoLogic': { author: 'OtoLogic', url: 'https://otologic.jp/', license: 'OtoLogic利用規約（CC BY 4.0 / クレジット表記）' },
    '効果音辞典': { author: '効果音辞典', url: 'https://sounddictionary.info/', license: '効果音辞典利用規約（商用可・クレジット不要）' },
    'Springin\' Sound Stock': { author: 'Springin\' Sound Stock', url: 'https://www.springin.org/sound-stock/', license: 'Springin\'利用規約（商用可・クレジット不要）' },
    '魔王魂': { author: '魔王魂', url: 'https://maou.audio/', license: '魔王魂利用規約（商用可・クレジット表記）' },
    'ポケットサウンド': { author: 'ポケットサウンド', url: 'https://pocket-se.info/', license: 'ポケットサウンド利用規約（商用可・クレジット表記）' },
    '甘茶の音楽工房': { author: '甘茶の音楽工房', url: 'https://amachamusic.chagasi.com/', license: '甘茶の音楽工房利用規約（商用可・ゲーム組込可・クレジット任意）' },
    'Pixabay': { author: 'Pixabay Creator', url: 'https://pixabay.com/sound-effects/', license: 'Pixabay Content License（商用可・ゲーム組込可・クレジット不要）' },
    'SoundDino': { author: 'SoundDino', url: 'https://sounddino.com/', license: 'SoundDino Royalty-Free（商用可・クレジット不要）' },
    'Freesound.org': { author: '', url: 'https://freesound.org/', license: 'CC-BY 4.0' },
    'ZapSplat': { author: 'ZapSplat', url: 'https://www.zapsplat.com/', license: 'ZapSplat Standard License（商用可・クレジット表記）' },
    'OpenGameArt.org': { author: '', url: 'https://opengameart.org/', license: 'CC0 (Public Domain)' }
  };

  if (siteDefaults[site]) {
    const d = siteDefaults[site];
    document.getElementById('modalAuthor').value = d.author;
    document.getElementById('modalSourceUrl').value = d.url;
    document.getElementById('modalLicense').value = d.license;
  }
});

document.getElementById('btnModalCancel').addEventListener('click', () => {
  document.getElementById('uploadModal').classList.remove('active');
  activeTargetItem = null;
  activeSelectedFile = null;
});

document.getElementById('btnModalSubmit').addEventListener('click', async () => {
  if (!activeTargetItem || !activeSelectedFile) return;

  const btn = document.getElementById('btnModalSubmit');
  btn.disabled = true;
  btn.textContent = '正規化 & Opus変換中...';

  const formData = new FormData();
  formData.append('id', activeTargetItem.id);
  formData.append('source_site', document.getElementById('modalSourceSite').value);
  formData.append('author', document.getElementById('modalAuthor').value);
  formData.append('source_url', document.getElementById('modalSourceUrl').value);
  formData.append('license', document.getElementById('modalLicense').value);
  formData.append('notes', document.getElementById('modalNotes').value);
  formData.append('file', activeSelectedFile);

  try {
    const res = await fetch('/api/upload_and_assign', {
      method: 'POST',
      body: formData
    });
    const data = await res.json();
    if (data.success) {
      document.getElementById('uploadModal').classList.remove('active');
      await loadData();
    } else {
      alert('エラー: ' + (data.error || 'アップロードに失敗しました'));
    }
  } catch (e) {
    alert('通信エラー: ' + e);
  } finally {
    btn.disabled = false;
    btn.textContent = '正規化 & 確定 (Opus変換)';
  }
});

async function deleteSound(id) {
  if (!confirm(`サウンド ${id} の割り当てを解除しますか？`)) return;

  try {
    const res = await fetch('/api/delete_assign', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id })
    });
    const data = await res.json();
    if (data.success) {
      await loadData();
    }
  } catch (e) {
    alert('解除エラー: ' + e);
  }
}

// 戦闘サブコントロールバーの表示/非表示同期
function updateCombatSubControlsVisibility() {
  const subControls = document.getElementById('combatSubControls');
  if (subControls) {
    subControls.style.display = (currentCategory === 'combat') ? 'flex' : 'none';
  }
}

// フィルタ・検索イベントリスナー
document.querySelectorAll('.filter-btn[data-filter], .filter-btn[data-cat]').forEach(btn => {
  btn.addEventListener('click', () => {
    if (btn.dataset.filter) {
      document.querySelectorAll('.filter-btn[data-filter]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentFilter = btn.dataset.filter;
    } else if (btn.dataset.cat) {
      const isAlready = btn.classList.contains('active');
      document.querySelectorAll('.filter-btn[data-cat]').forEach(b => b.classList.remove('active'));
      if (!isAlready) {
        btn.classList.add('active');
        currentCategory = btn.dataset.cat;
      } else {
        currentCategory = 'all';
      }
      updateCombatSubControlsVisibility();
    }
    renderCards();
  });
});

// 戦闘サブカテゴリ切り替えボタン
document.querySelectorAll('.subcat-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.subcat-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentCombatSub = btn.dataset.combatSub || 'all';
    renderCards();
  });
});

document.getElementById('searchInput').addEventListener('input', (e) => {
  searchQuery = e.target.value.trim();
  renderCards();
});

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function escapeJs(str) {
  if (!str) return '';
  return str.replace(/'/g, "\\'");
}

// 音量診断・適正化ハンドラ
async function runVolumeAudit() {
  const btn = document.getElementById('btnAuditVolumes');
  if (!btn) return;
  const origText = btn.textContent;
  btn.disabled = true;
  btn.textContent = '⏳ 診断中...';

  try {
    const res = await fetch('/api/volume_check');
    if (!res.ok) {
      const text = await res.text();
      if (res.status === 404) {
        throw new Error('APIが見つかりません (404)。サウンドキュレーターのローカルサーバー (server.py) を再起動してください。');
      }
      throw new Error(`サーバーエラー (HTTP ${res.status}): ${text.slice(0, 150)}`);
    }

    let data;
    try {
      data = await res.json();
    } catch (e) {
      throw new Error('サーバーからの応答が不正です（JSONではありません）。server.py を再起動してください。');
    }
    
    // volumeDataMap に保存
    volumeDataMap = {};
    for (const item of (data.results || [])) {
      volumeDataMap[item.filename] = item;
    }

    const counts = data.counts || { OK: 0, WARN: 0, ERROR: 0, CLIP: 0 };
    const issueCount = (counts.WARN || 0) + (counts.ERROR || 0) + (counts.CLIP || 0);

    // カウント表示の更新
    document.getElementById('volOkCount').textContent = counts.OK || 0;
    document.getElementById('volWarnCount').textContent = counts.WARN || 0;
    document.getElementById('volErrorCount').textContent = counts.ERROR || 0;
    document.getElementById('volClipCount').textContent = counts.CLIP || 0;
    document.getElementById('volIssueCount').textContent = issueCount;

    // コントロール行の表示
    const volControls = document.getElementById('volumeControls');
    if (volControls) volControls.style.display = 'flex';

    const fixAllBtn = document.getElementById('btnFixAllVolumes');
    if (fixAllBtn) {
      fixAllBtn.style.display = issueCount > 0 ? 'inline-block' : 'none';
    }

    renderCards();
  } catch (err) {
    alert('音量診断に失敗しました:\n' + err.message);
  } finally {
    btn.disabled = false;
    btn.textContent = origText;
  }
}

async function fixVolume(filename) {
  if (!confirm(`${filename} の音量を適正化（無音トリム＋コンプレッション＋ピーク -1.5 dBFS）しますか？`)) {
    return;
  }

  try {
    const res = await fetch('/api/volume_fix', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ target: filename })
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`サーバーエラー (HTTP ${res.status}): ${text.slice(0, 150)}`);
    }
    const data = await res.json();
    if (data.success && data.results && data.results.length > 0) {
      const updated = data.results[0];
      volumeDataMap[filename] = updated;

      // カウントの再集計
      updateVolumeCountsFromMap();

      renderCards();

      // オーディオタグのキャッシュバスター更新
      setTimeout(() => {
        const item = soundList.find(x => x.filename === filename);
        if (item) {
          const audioElem = document.getElementById(`audio_${item.id}`);
          if (audioElem) {
            audioElem.src = `/sounds/${encodeURIComponent(item.filename)}?t=${Date.now()}`;
          }
        }
      }, 100);
    } else {
      alert('音量適正化に失敗しました: ' + (data.error || '不明なエラー'));
    }
  } catch (err) {
    alert('通信エラー:\n' + err.message);
  }
}

async function fixAllProblemVolumes() {
  if (!confirm('検出された要修正音源（WARN, ERROR, CLIP）を一括で適正化（ピーク -1.5 dBFS）しますか？\n※処理には数秒〜数十秒かかる場合があります。')) {
    return;
  }

  const btn = document.getElementById('btnFixAllVolumes');
  if (btn) {
    btn.disabled = true;
    btn.textContent = '⏳ 一括適正化中...';
  }

  try {
    const res = await fetch('/api/volume_fix', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ target: 'warn_or_error' })
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`サーバーエラー (HTTP ${res.status}): ${text.slice(0, 150)}`);
    }
    const data = await res.json();
    if (data.success) {
      for (const r of (data.results || [])) {
        volumeDataMap[r.filename] = r;
      }
      updateVolumeCountsFromMap();
      renderCards();
      alert(`完了しました！ ${data.fixed_count} 件の音源を適正化しました。`);
    } else {
      alert('一括適正化に失敗しました: ' + (data.error || '不明なエラー'));
    }
  } catch (err) {
    alert('通信エラー:\n' + err.message);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.textContent = '⚠️ 要修正音源を一括適正化';
    }
  }
}

function updateVolumeCountsFromMap() {
  let ok = 0, warn = 0, err = 0, clip = 0;
  for (const k in volumeDataMap) {
    const st = volumeDataMap[k].status;
    if (st === 'OK') ok++;
    else if (st === 'WARN') warn++;
    else if (st === 'ERROR') err++;
    else if (st === 'CLIP') clip++;
  }
  const issues = warn + err + clip;
  document.getElementById('volOkCount').textContent = ok;
  document.getElementById('volWarnCount').textContent = warn;
  document.getElementById('volErrorCount').textContent = err;
  document.getElementById('volClipCount').textContent = clip;
  document.getElementById('volIssueCount').textContent = issues;

  const fixAllBtn = document.getElementById('btnFixAllVolumes');
  if (fixAllBtn) {
    fixAllBtn.style.display = issues > 0 ? 'inline-block' : 'none';
  }
}

// 音量フィルタ切り替えボタン
document.querySelectorAll('.vol-filter-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.vol-filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentVolFilter = btn.dataset.volFilter || 'all';
    renderCards();
  });
});

// URLパラメータによる初期アクティブボタン状態の復元
if (initialCategoryParam) {
  const targetCatBtn = document.querySelector(`.filter-btn[data-cat="${initialCategoryParam}"]`);
  if (targetCatBtn) {
    document.querySelectorAll('.filter-btn[data-cat]').forEach(b => b.classList.remove('active'));
    targetCatBtn.classList.add('active');
  }
}
updateCombatSubControlsVisibility();

// 初期ロード
loadData();


