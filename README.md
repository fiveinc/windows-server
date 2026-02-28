# 📑 Windows Server 確定申告・NACCS 運用環境 (QEMU/KVM)

Arch Linux / NixOS (Sway) 環境で、Windows Server 評価版 (180日) を「汚さず・安全に・永続的に」運用するためのガイドです。

---

## 🏗 ディスク構成

| ディスク | ファイル名 | 役割 | GitHub管理 |
| :--- | :--- | :--- | :--- |
| **Base (C:)** | `*.vhd` | Microsoft提供の評価版 (読み取り専用) | ❌ (除外) |
| **Overlay (C:)** | `win-server-diff.qcow2` | OSの変更分・インストールしたソフト | ❌ (除外) |
| **Storage (D:)** | `data-storage.qcow2` | **確定申告・NACCSのデータ本体 (50MB)** | ✅ **対象** |

---

## 🚀 環境構築手順

### 1. 依存パッケージの導入
- **Arch Linux**: `sudo pacman -S qemu-full virtio-win aria2`
- **NixOS**: `configuration.nix` の `environment.systemPackages` に `qemu`, `virtio-win`, `aria2` を追加。

### 2. ファイルの準備
高速ダウンローダー `aria2c` を使用して、必要なイメージを取得します。

```bash
# Windows Server VHD (約10GB) のダウンロード
aria2c -x 16 -s 16 -c "https://software-download.microsoft.com/download/pr/20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd"

# Virtioドライバのダウンロード
aria2c -x 16 -s 16 -c "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
```

### 3. 仮想ディスクの初期化

```bash
# データ用ドライブの作成 (最大50MB)
qemu-img create -f qcow2 data-storage.qcow2 50M

# OS用差分レイヤーの作成
qemu-img create -f qcow2 -F vpc -b 20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd win-server-diff.qcow2
```

## 🎮 起動と運用

### 起動スクリプト (start.sh)
Sway環境に最適化した設定です。初回はドライバ未導入のため `if=ide` と `vga std` で起動します。

```bash
#!/bin/bash
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp 2 -m 4096 \
  -drive file=win-server-diff.qcow2,format=qcow2,index=0,media=disk,if=ide \
  -drive file=data-storage.qcow2,format=qcow2,index=1,media=disk,if=ide \
  -drive file=virtio-win-0.1.285.iso,media=cdrom \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0 \
  -display sdl,gl=on -vga std \
  -usb -device usb-tablet \
  -boot order=c
```
※ドライバ導入後は `if=ide` → `if=virtio`、`e1000` → `virtio-net-pci`、`vga std` → `vga virtio` に書き換えることで高速化できます。

### Windows内での初期作業
1. **Dドライブの認識**: 「ディスクの管理」から `data-storage.qcow2` をGPTで初期化し、NTFSでフォーマット。
2. **ドライバ適用**: CDドライブ内の `virtio-win-guest-tools.exe` を実行して全ドライバをインストール。
3. **データ保存**: 確定申告の控えやNACCSデータは **必ずDドライブ** に保存する。

## 🔄 GitHub同期とメンテナンス

### GitHubへのプッシュ
Windowsをシャットダウン後、ホストOS側で実行します。

```bash
git add data-storage.qcow2
git commit -m "確定申告データ更新 $(date +%Y-%m-%d)"
git push origin main
```

### 180日の評価期限が切れた場合
OSが1時間ごとに落ちるようになったら、OSレイヤーだけをリセットします。

1. `rm win-server-diff.qcow2` で削除。
2. 手順3の「OS用差分レイヤーの作成」を再実行。
3. Dドライブ(`data-storage.qcow2`)はそのまま使い続けることが可能です。

## 🛠 Sway / Wayland Tips
- **フローティング設定**: `~/.config/sway/config` に追記
  `for_window [title="QEMU"] floating enable, resize set 1280 800`
- **マウスの解放**: `Ctrl + Alt + G`
