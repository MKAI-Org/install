# 安装命令

## Windows

解压后双击 `install.bat`。配 key 双击 `configure-codex.bat` / `configure-claude.bat`。

下脚本（不含安装包）：

```powershell
curl.exe -L -o install.zip https://dl.mkstore.life/scripts.zip
tar -xf install.zip
cd install
```

没网：把包放到对应 `*/packages/`，或 `-PackagesDir` / `MK_PACKAGES`。

## Mac

```bash
chmod +x */*.sh
./node/install.sh
./git/install.sh
./codex/install.sh
./codex/install-app.sh
./claude-code/install.sh
./claude-code/install-app.sh
```

配 key：

```bash
./codex/configure.sh --key sk-xxx --base-url https://api.example.com/v1 --model deepseek-chat
./claude-code/configure.sh --key sk-ant-xxx --base-url https://api.example.com
```

## Linux

```bash
chmod +x */*.sh
./node/install.sh
./git/install.sh
./codex/install.sh
./claude-code/install.sh
```

配 key：

```bash
./codex/configure.sh --key sk-xxx --base-url https://api.example.com/v1 --model deepseek-chat
./claude-code/configure.sh --key sk-ant-xxx --base-url https://api.example.com
```
