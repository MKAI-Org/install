# Codex CLI + 桌面客户端
#
#   Mac/Linux CLI:  ./install.sh
#   Windows CLI:    .\install.ps1
#   Mac 客户端:     ./install-app.sh     （装 GitHub 的 .dmg）
#   Windows 客户端: .\install-app.ps1    （Store / 已打包的 MSIX；国内常失败则用 CLI）
#
# 装完再配 key（不要跟安装混在一起）:
#   ./configure.sh --key sk-xxx --base-url https://api.example.com/v1 --model xxx
#   .\configure.ps1 -ApiKey sk-xxx -BaseUrl https://api.example.com/v1 -Model xxx
#
# 国内优先用本目录 packages/ 里已经下载好的包。没有包就走 gh 镜像。
