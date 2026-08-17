# 安装命令

有网：脚本从 `https://dl.mkstore.life` 下包。
没网：把包放到对应 `*/packages/`，或指定目录。

```bash
MK_PACKAGES=/U盘路径 ./codex/install.sh
```

```powershell
.\codex\install.ps1 -PackagesDir D:\pkgs
```

先 `cd` 进 `install` 目录。

## Windows（PowerShell）

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\node\install.ps1
.\git\install.ps1
.\vcredist\install.ps1
.\codex\install.ps1
.\codex\install-app.ps1
.\claude-code\install.ps1
.\claude-code\install-app.ps1
```

配 key：

```powershell
.\codex\configure.ps1 -ApiKey 'sk-xxx' -BaseUrl 'https://api.example.com/v1' -Model 'deepseek-chat'
.\claude-code\configure.ps1 -ApiKey 'sk-ant-xxx' -BaseUrl 'https://api.example.com'
```

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
