#!/bin/bash

# ══════════════════════════════════════════════════════════
#  自举引导：确保 curl 和基础工具可用（兼容 minimal 系统）
# ══════════════════════════════════════════════════════════
_bootstrap() {
    local MISSING=()
    command -v curl   &>/dev/null || MISSING+=("curl")
    command -v python3 &>/dev/null || MISSING+=("python3")

    [ ${#MISSING[@]} -eq 0 ] && return   # 都有，直接跳过

    echo ""
    echo "  🔧 检测到缺少基础工具：${MISSING[*]}"
    echo "  正在自动安装，请稍候..."
    echo ""

    # 检测包管理器（此时颜色变量还没加载，用纯文本）
    if   command -v apt-get &>/dev/null; then
        apt-get update -qq 2>/dev/null
        apt-get install -y ${MISSING[*]} 2>/dev/null
    elif command -v apk &>/dev/null; then
        apk add --no-cache ${MISSING[*]/python3/python3} 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf install -y ${MISSING[*]} 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y ${MISSING[*]} 2>/dev/null
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm ${MISSING[*]/python3/python} 2>/dev/null
    elif command -v zypper &>/dev/null; then
        zypper --non-interactive install ${MISSING[*]} 2>/dev/null
    fi

    # 验证
    local STILL_MISSING=()
    for tool in "${MISSING[@]}"; do
        command -v "$tool" &>/dev/null || STILL_MISSING+=("$tool")
    done
    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        echo "  ❌ 以下工具安装失败：${STILL_MISSING[*]}"
        echo "  请手动安装后重试，例如：apt-get install -y ${STILL_MISSING[*]}"
        exit 1
    fi
    echo "  ✅ 基础工具已就绪！"
    echo ""
}
_bootstrap

# --- 颜色与全局变量 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
PINK='\033[38;5;213m'
PINK2='\033[38;5;219m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
WHITE='\033[97m'
RESET='\033[0m'

VERSION="V2.110"

# ══════════════════════════════════════════════════════════
#  环境探测：自动识别是否 serv00（FreeBSD + 无root）
# ══════════════════════════════════════════════════════════
detect_env() {
    IS_SERV00=false
    # 判断依据：FreeBSD 系统 + 主目录在 /usr/home/
    if [[ "$(uname -s 2>/dev/null)" == "FreeBSD" ]] || \
       [[ "$HOME" == /usr/home/* ]] || \
       command -v devil &>/dev/null; then
        IS_SERV00=true
    fi

    # 所有文件统一住在 ~/mimi/ 一个目录里
    MIMI_HOME="$HOME/mimi"
    BOT_BASE="$MIMI_HOME/bots"          # bot 文件
    MIMI_SCRIPT="$MIMI_HOME/mimi.sh"    # 脚本自身

    # ── 三室共用文件夹 ────────────────────────────────────
    MASTER_DIR="$MIMI_HOME/master"      # 主人房：作息时间表
    LIBRARY_DIR="$MIMI_HOME/library"    # 图书馆：RSS OPML 订阅源

    if [ "$IS_SERV00" = true ]; then
        VENV_DIR="$MIMI_HOME/venv"   # serv00：虚拟环境也在 mimi/ 里
        PYTHON_BIN="$VENV_DIR/bin/python3"
        PIP_BIN="$VENV_DIR/bin/pip"
        SHORTCUT_DIR="$HOME/.local/bin"
    else
        PYTHON_BIN="python3"
        PIP_BIN="pip3"
        SHORTCUT_DIR="/usr/local/bin"
    fi
}
detect_env

print_banner() {
    echo ""
    echo -e "${PINK}                ██████████              ██████████\n\
            ██████████████████      ████████████████\n\
          ██████      ██████    ████████      ██████\n\
          ██████          ████    ████          ██████\n\
            ██████        ████████████          ████\n\
            ██████          ████████          ████    ██████████████\n\
██████████████████          ██████            ████████████████████████\n\
████████  ████████████        ████          ██████████          ██████\n\
██████          ██████        ████          ██████            ████████\n\
  ████████          ████      ████████████████            ████████\n\
    ██████████        ████████████████████████████      ████████\n\
        ████████████████████              ████████████████\n\
              ██████████                      ████████\n\
              ██████                            ████████\n\
            ██████                                    ████\n\
██████████████████████████████  ██████████████████████████████\n\
██████████              ██████████                ████████████████\n\
    ████                ██████████                ████  ██████\n\
    ████                ████  ████                ████  ██████\n\
    ██████            ████      ██████        ██████    ██████\n\
          ██████████████████████████████████████        ██████\n\
              ████████████████████████████              ██████\n\
          ██████████████████████████████████            ██████\n\
        ██████████████████████████████████████          ██████\n\
    ██████████████████████████████████████████          ██████\n\
  ████████████████████████████████████████████          ██████\n\
██████████████████████████████████████████████          ██████\n\
  ██████████████████████████████████████████            ██████\n\
          ██████████████████████████████                ██████\n\
                        ██████████████                    ████████\n\
                        ████████                      ██████████\n\
                          ████████████████████████████████████\n\
                              ████████████████████████████${RESET}"
    echo ""
    echo -e "${BOLD}${PINK}  ┌──────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${PINK}  │                                                              │${RESET}"
    echo -e "${BOLD}${PINK}  │                ███    ███  ██  ███    ███  ██                │${RESET}"
    echo -e "${BOLD}${PINK}  │                ████  ████  ██  ████  ████  ██                │${RESET}"
    echo -e "${BOLD}${PINK}  │                ██ ████ ██  ██  ██ ████ ██  ██                │${RESET}"
    echo -e "${BOLD}${PINK}  │                ██  ██  ██  ██  ██  ██  ██  ██                │${RESET}"
    echo -e "${BOLD}${PINK}  │                ██      ██  ██  ██      ██  ██                │${RESET}"
    echo -e "${BOLD}${PINK}  │                                                              │${RESET}"
    echo -e "${PINK}  │                     MIMI 电报 AI 小秘书                      │${RESET}"
    echo -e "${PINK}  │  ·  ·  让 AI 住进你的 VPS，随时在 Telegram 伺候你  ·  ·      │${RESET}"
    echo -e "${PINK}  │                           ${VERSION}                             │${RESET}"
    # serv00 环境标识
    if [ "$IS_SERV00" = true ]; then
    echo -e "${CYAN}  │              🐡  serv00 / FreeBSD 免费鸡模式                 │${RESET}"
    fi
    echo -e "${BOLD}${PINK}  │                                                              │${RESET}"
    echo -e "${BOLD}${PINK}  └──────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  serv00 专属：依赖安装（virtualenv + pip 到 venv）
# ══════════════════════════════════════════════════════════
_ensure_deps_serv00() {
    local NEED_VENV=false
    local NEED_PKG=false

    # 检查 venv 是否存在
    [ ! -f "$VENV_DIR/bin/python3" ] && NEED_VENV=true

    # 检查核心包
    "$VENV_DIR/bin/python3" -c "import telegram" 2>/dev/null || NEED_PKG=true

    if [ "$NEED_VENV" = false ] && [ "$NEED_PKG" = false ]; then return; fi

    clear
    echo ""
    echo -e "${CYAN}  ╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║        🐡  MIMI serv00 首次启动检测                   ║${NC}"
    echo -e "${CYAN}  ╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 第一步：确保 binexec 已开启
    if command -v devil &>/dev/null; then
        echo -e "${YELLOW}  ⚙️  正在开启 binexec（允许运行自定义程序）...${NC}"
        devil binexec on 2>/dev/null
        echo -e "${GREEN}  ✅ binexec 已开启${NC}"
        echo ""
    fi

    if [ "$NEED_VENV" = true ]; then
        echo -e "${YELLOW}  📦 正在创建 Python 虚拟环境...${NC}"
        echo -e "${DIM}  路径：${VENV_DIR}${NC}"
        # serv00 用 virtualenv（系统自带）
        mkdir -p "$MIMI_HOME"
        if command -v virtualenv &>/dev/null; then
            virtualenv "$VENV_DIR" -p python3 > /tmp/mimi_venv.log 2>&1
        else
            python3 -m venv "$VENV_DIR" > /tmp/mimi_venv.log 2>&1
        fi
        if [ -f "$VENV_DIR/bin/python3" ]; then
            echo -e "${GREEN}  ✅ 虚拟环境创建成功${NC}"
        else
            echo -e "${RED}  ❌ 虚拟环境创建失败，请检查 python3 是否可用${NC}"
            cat /tmp/mimi_venv.log
            exit 1
        fi
        echo ""
    fi

    if [ "$NEED_PKG" = true ]; then
        echo -e "${YELLOW}  正在安装 Python 依赖包（首次约需 3-5 分钟）${NC}"
        echo -e "${DIM}  serv00 网络较慢，请耐心等待...${NC}"
        echo ""
        # serv00 安装时需要限制并发，否则会超进程数限制
        export MAX_CONCURRENCY=1
        export CPUCOUNT=1
        export MAKEFLAGS="-j1"
        # serv00(FreeBSD) 不支持 duckduckgo-search（依赖 curl-cffi 需要编译）
        # 已改用内置 requests 实现 DDG 搜索，无需此包
        local PKGS=("google-genai" "anthropic" "openai" "python-telegram-bot[job-queue]" "pytz" "tavily-python")
        local TOTAL=${#PKGS[@]}
        local CURRENT=0
        local FAILED_PKGS=()
        for PKG in "${PKGS[@]}"; do
            CURRENT=$(( CURRENT + 1 ))
            local PCT=$(( CURRENT * 100 / TOTAL ))
            local FILLED=$(( PCT / 5 ))
            local BAR=$(printf '█%.0s' $(seq 1 $FILLED))
            local EMPTY=$(printf '░%.0s' $(seq 1 $((20 - FILLED))))
            echo -ne "  ${GREEN}[${BAR}${EMPTY}]${NC} ${PCT}%%  ${DIM}安装 ${PKG}...${NC}          \r"
            if ! "$PIP_BIN" install --upgrade --quiet "$PKG" >> /tmp/mimi_install.log 2>&1; then
                FAILED_PKGS+=("$PKG")
            fi
        done
        if [ ${#FAILED_PKGS[@]} -eq 0 ]; then
            echo -e "  ${GREEN}[████████████████████]${NC} 100%%  ${GREEN}✅ 全部安装完成！${NC}          "
        else
            echo -e "  ${YELLOW}[████████████████████]${NC} 100%%  ${YELLOW}⚠️  安装完成，但以下包失败：${NC}"
            for F in "${FAILED_PKGS[@]}"; do echo -e "  ${RED}  ✗ $F${NC}"; done
            echo -e "  ${DIM}  可手动执行：$PIP_BIN install ${FAILED_PKGS[*]}${NC}"
        fi
        echo ""
        sleep 1
    fi
}

# ── 自动安装依赖（普通VPS，带进度条和友好提示）──
# ══════════════════════════════════════════════════════════
#  全平台兼容安装引擎
#  支持：Ubuntu/Debian · Alpine(mikrus青蛙) · Fedora/Rocky
#        CentOS · Arch · OpenSUSE · Gentoo · Void Linux
#        以及所有 PEP668 受保护环境（Ubuntu22+/Debian12+）
# ══════════════════════════════════════════════════════════

_detect_pkg_manager() {
    # 包管理器检测（按市场占有率排序）
    if   command -v apt-get &>/dev/null; then PKG_MANAGER="apt"
    elif command -v apk     &>/dev/null; then PKG_MANAGER="apk"      # Alpine
    elif command -v dnf     &>/dev/null; then PKG_MANAGER="dnf"      # Fedora/Rocky/Alma/RHEL8+
    elif command -v yum     &>/dev/null; then PKG_MANAGER="yum"      # CentOS7/旧RHEL
    elif command -v pacman  &>/dev/null; then PKG_MANAGER="pacman"   # Arch/Manjaro
    elif command -v zypper  &>/dev/null; then PKG_MANAGER="zypper"   # OpenSUSE
    elif command -v emerge  &>/dev/null; then PKG_MANAGER="emerge"   # Gentoo
    elif command -v xbps-install &>/dev/null; then PKG_MANAGER="xbps" # Void Linux
    elif command -v nix-env &>/dev/null; then PKG_MANAGER="nix"      # NixOS
    else PKG_MANAGER="unknown"
    fi

    # Python 版本检测（兼容 python3 / python 命名差异）
    if   command -v python3 &>/dev/null; then PYTHON_CMD="python3"
    elif command -v python  &>/dev/null; then PYTHON_CMD="python"
    else PYTHON_CMD=""
    fi

    # pip 命令检测（pip3 → pip → python -m pip 降级尝试）
    if   command -v pip3 &>/dev/null;                       then PIP_CMD="pip3"
    elif command -v pip  &>/dev/null;                       then PIP_CMD="pip"
    elif $PYTHON_CMD -m pip --version &>/dev/null 2>&1;     then PIP_CMD="$PYTHON_CMD -m pip"
    else PIP_CMD=""
    fi
}

_install_pip() {
    local SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0 WAITED=0 TIMEOUT=240
    local PID

    case "$PKG_MANAGER" in
        apt)
            # apt-get update 也放后台，立即开始转圈，不让用户以为死机
            echo -ne "  ${YELLOW}正在更新软件源${NC}  "
            apt-get update -qq > /tmp/mimi_install.log 2>&1 &
            PID=$!
            while kill -0 $PID 2>/dev/null; do
                echo -ne "\b${SPIN[$i]}"
                i=$(( (i+1) % 10 ))
                sleep 0.3
            done
            echo -e "\b${GREEN}✅${NC}"
            echo -ne "  ${YELLOW}正在安装 pip${NC}  "
            apt-get install -y python3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        apk)
            apk add --no-cache py3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        dnf)
            dnf install -y python3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        yum)
            yum install -y epel-release >> /tmp/mimi_install.log 2>&1
            yum install -y python3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        pacman)
            pacman -Sy --noconfirm python-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        zypper)
            zypper --non-interactive install python3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        emerge)
            emerge --ask=n dev-python/pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        xbps)
            xbps-install -Sy python3-pip >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        nix)
            # NixOS 用 nix-env 或直接用 python3 -m ensurepip
            $PYTHON_CMD -m ensurepip --upgrade >> /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
        *)
            # 最后尝试：用 Python 自带的 ensurepip 模块
            echo -ne "\b${YELLOW}（尝试 ensurepip）${NC}  "
            $PYTHON_CMD -m ensurepip --upgrade > /tmp/mimi_install.log 2>&1 &
            PID=$! ;;
    esac

    while kill -0 $PID 2>/dev/null; do
        echo -ne "\b${SPIN[$i]}"
        i=$(( (i+1) % 10 ))
        sleep 0.5
        WAITED=$(( WAITED + 1 ))
        if [ $WAITED -ge $TIMEOUT ]; then
            kill -9 $PID 2>/dev/null
            echo -e "\b${RED}❌ 超时${NC}"
            echo ""
            echo -e "  ${RED}⚠️  pip 安装超时（4分钟）！${NC}"
            echo -e "  ${YELLOW}  检测到你的系统是：${PKG_MANAGER}${NC}"
            echo -e "  ${DIM}  请手动安装后重跑脚本。${NC}"
            exit 1
        fi
    done

    _detect_pkg_manager   # 装完重新检测
    echo -e "\b${GREEN}✅${NC}"
}

_get_pip_opts() {
    # 智能探测是否需要 --break-system-packages
    # 触发条件：Ubuntu 22.04+ / Debian 12+ / Alpine / 任何 PEP668 环境
    local TEST_OUT
    TEST_OUT=$($PIP_CMD install --dry-run --quiet pytz 2>&1 || true)
    if echo "$TEST_OUT" | grep -qi "externally-managed\|break-system-packages\|PEP 668"; then
        echo "--upgrade --quiet --break-system-packages"
    else
        echo "--upgrade --quiet"
    fi
}

_ensure_deps_vps() {
    _detect_pkg_manager

    local NEED_PIP=false
    local NEED_PKG=false
    [ -z "$PIP_CMD" ] && NEED_PIP=true
    $PYTHON_CMD -c "import telegram" 2>/dev/null || NEED_PKG=true

    if [ "$NEED_PIP" = false ] && [ "$NEED_PKG" = false ]; then return; fi

    clear
    echo ""
    echo -e "${PINK}  ╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}  ║        🌸  MIMI 首次启动检测                          ║${NC}"
    echo -e "${PINK}  ╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    # 显示检测到的系统信息，让用户有底气
    local OS_NAME=""
    [ -f /etc/os-release ] && OS_NAME=$(grep "^PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    [ -n "$OS_NAME" ] && echo -e "  ${DIM}  🖥️  系统：${OS_NAME}  |  包管理：${PKG_MANAGER}${NC}"
    echo ""
    echo -e "${YELLOW}  检测到以下依赖尚未安装：${NC}"
    [ "$NEED_PIP" = true ] && echo -e "  ${RED}  ✗  pip（Python 包管理器）${NC}"
    [ "$NEED_PKG" = true ] && echo -e "  ${RED}  ✗  python-telegram-bot 及相关 AI 库${NC}"
    echo ""
    echo -e "${DIM}  这些是 MIMI 运行的必要组件，就像手机需要先装系统一样。${NC}"
    echo -e "${DIM}  安装只需进行一次，之后每次启动都会直接跳过这一步。${NC}"
    echo ""
    read -p "  👉 是否现在自动安装？(y/n，默认 y): " CONFIRM_DEPS
    if [ "$CONFIRM_DEPS" = "n" ] || [ "$CONFIRM_DEPS" = "N" ]; then
        echo -e "${RED}  ❌ 已取消。没有依赖 MIMI 无法工作，退出。${NC}"
        exit 1
    fi
    echo ""

    [ "$NEED_PIP" = true ] && _install_pip

    _detect_pkg_manager   # pip 装完重新检测

    if [ -z "$PIP_CMD" ]; then
        echo -e "  ${RED}⚠️  pip 安装后仍无法找到，请重启终端后重试。${NC}"
        exit 1
    fi

    if [ "$NEED_PKG" = true ]; then
        echo ""
        echo -e "  ${YELLOW}正在安装 Python 依赖包（首次约需 1-2 分钟）${NC}"
        echo ""

        local PIP_OPTS
        PIP_OPTS=$(_get_pip_opts)

        local PKGS=("google-genai" "anthropic" "openai" "python-telegram-bot[job-queue]" "pytz" "tavily-python")
        local TOTAL=${#PKGS[@]}
        local CURRENT=0
        local FAILED_PKGS=()

        for PKG in "${PKGS[@]}"; do
            CURRENT=$(( CURRENT + 1 ))
            local PCT=$(( CURRENT * 100 / TOTAL ))
            local FILLED=$(( PCT / 5 ))
            local BAR=$(printf '█%.0s' $(seq 1 $FILLED))
            local EMPTY=$(printf '░%.0s' $(seq 1 $((20 - FILLED))))
            echo -ne "  ${GREEN}[${BAR}${EMPTY}]${NC} ${PCT}%%  ${DIM}安装 ${PKG}...${NC}          \r"
            if ! $PIP_CMD install $PIP_OPTS "$PKG" >> /tmp/mimi_install.log 2>&1; then
                FAILED_PKGS+=("$PKG")
            fi
        done

        if [ ${#FAILED_PKGS[@]} -eq 0 ]; then
            echo -e "  ${GREEN}[████████████████████]${NC} 100%%  ${GREEN}✅ 全部安装完成！${NC}          "
        else
            echo -e "  ${YELLOW}[████████████████████]${NC} 100%%  ${YELLOW}⚠️  以下包安装失败：${NC}"
            for F in "${FAILED_PKGS[@]}"; do echo -e "  ${RED}  ✗ $F${NC}"; done
            echo ""
            echo -e "  ${DIM}  请手动执行：${NC}"
            echo -e "  ${YELLOW}  $PIP_CMD install $PIP_OPTS ${FAILED_PKGS[*]}${NC}"
            echo -e "  ${DIM}  装完后重跑脚本即可。${NC}"
        fi
        echo ""
        sleep 1
    fi
}

# 统一入口：根据环境选择安装方式
_ensure_deps() {
    if [ "$IS_SERV00" = true ]; then
        _ensure_deps_serv00
    else
        _ensure_deps_vps
    fi
}
_ensure_deps

# ── 创建 ~/mimi/ 总目录，安置脚本，创建快捷命令 ──
MIMI_INSTALL_URL="https://raw.githubusercontent.com/uepopo/mimi/refs/heads/main/install.sh"

_setup_shortcut() {
    mkdir -p "$MIMI_HOME" "$BOT_BASE" "$MASTER_DIR" "$LIBRARY_DIR"

    # ── 首次初始化主人房作息文件 ─────────────────────────
    if [ ! -f "$MASTER_DIR/schedule.txt" ]; then
        cat > "$MASTER_DIR/schedule.txt" << 'SCHEDULE_EOF'
06:06 起床，洗漱
06:20 爆发力训练
06:30 吃早饭（鸡蛋，牛奶，坚果，100克碳水）
08:00 阅读，钢琴，绘画笔记三选一
08:30 工作
12:00 午饭（吃饱）
12:30 十分钟冥想
13:00 工作
16:00 十分钟有氧
18:00 吃水果
20:00 收工，洗澡
23:00 睡觉
SCHEDULE_EOF
        echo -e "${PINK}  📅 已初始化主人房作息表 → $MASTER_DIR/schedule.txt${NC}"
    fi

    # ── 首次初始化图书馆 OPML ──────────────────────────────
    if [ ! -f "$LIBRARY_DIR/feeds.opml" ]; then
        cat > "$LIBRARY_DIR/feeds.opml" << 'OPML_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>MIMI 图书馆订阅源</title></head>
  <body>
    <outline text="🌍 国际新闻">
      <outline text="BBC News" title="BBC News" type="rss" xmlUrl="https://feeds.bbci.co.uk/news/rss.xml" htmlUrl="https://www.bbc.com/news" />
      <outline text="Reuters" title="Reuters" type="rss" xmlUrl="https://feeds.reuters.com/reuters/topNews" htmlUrl="https://www.reuters.com/" />
      <outline text="AP News" title="AP News" type="rss" xmlUrl="https://feeds.feedburner.com/APTopNews" htmlUrl="https://apnews.com/" />
      <outline text="Al Jazeera" title="Al Jazeera" type="rss" xmlUrl="https://www.aljazeera.com/xml/rss/all.xml" htmlUrl="https://www.aljazeera.com/" />
    </outline>
    <outline text="💻 科技 &amp; AI">
      <outline text="The Verge" title="The Verge" type="rss" xmlUrl="https://www.theverge.com/rss/index.xml" htmlUrl="https://www.theverge.com/" />
      <outline text="Ars Technica" title="Ars Technica" type="rss" xmlUrl="https://feeds.arstechnica.com/arstechnica/index" htmlUrl="https://arstechnica.com/" />
      <outline text="MIT Technology Review" title="MIT Tech Review" type="rss" xmlUrl="https://www.technologyreview.com/topnews.rss" htmlUrl="https://www.technologyreview.com/" />
      <outline text="TechCrunch" title="TechCrunch" type="rss" xmlUrl="https://techcrunch.com/feed/" htmlUrl="https://techcrunch.com/" />
    </outline>
    <outline text="💹 财经">
      <outline text="Bloomberg Technology" title="Bloomberg Tech" type="rss" xmlUrl="https://feeds.bloomberg.com/technology/news.rss" htmlUrl="https://www.bloomberg.com/technology" />
    </outline>
  </body>
</opml>
OPML_EOF
        echo -e "${PINK}  📚 已初始化图书馆 → $LIBRARY_DIR/feeds.opml${NC}"
        echo -e "${DIM}  （可在主菜单「2 图书馆」中替换为你自己的 feeds.opml）${NC}"
    fi

    # 脚本安置：如果当前不是从 ~/mimi/mimi.sh 运行，则重新下载完整版到那里
    # （bash <(curl ...) 管道运行时 $0 是管道fd，cp会截断，必须用curl重新下载）
    if [ ! -f "$MIMI_SCRIPT" ] || [ "$(realpath "$0" 2>/dev/null)" != "$MIMI_SCRIPT" ]; then
        curl -sL "$MIMI_INSTALL_URL" -o "$MIMI_SCRIPT" 2>/dev/null
        chmod +x "$MIMI_SCRIPT"
    fi

    local LINK=""
    if [ "$IS_SERV00" = true ]; then
        mkdir -p "$SHORTCUT_DIR"
        LINK="$SHORTCUT_DIR/mimi"
        if [[ ":$PATH:" != *":$SHORTCUT_DIR:"* ]]; then
            echo "export PATH=\"$SHORTCUT_DIR:\$PATH\"" >> "$HOME/.bashrc" 2>/dev/null
            echo "export PATH=\"$SHORTCUT_DIR:\$PATH\"" >> "$HOME/.profile" 2>/dev/null
        fi
    else
        LINK="/usr/local/bin/mimi"
    fi

    if [ -n "$LINK" ]; then
        # 无论是否存在，都强制重建软链接到正确路径
        # 避免旧链接指向管道 /proc/xxx/fd/pipe 导致 mimi 命令失效
        local CURRENT_TARGET
        CURRENT_TARGET=$(readlink "$LINK" 2>/dev/null)
        if [ "$CURRENT_TARGET" != "$MIMI_SCRIPT" ]; then
            ln -sf "$MIMI_SCRIPT" "$LINK" 2>/dev/null
            if [ ! -L "$LINK" ] 2>/dev/null || [ "$(readlink "$LINK")" != "$MIMI_SCRIPT" ]; then
                # 第一次创建才提示
                echo -e "${PINK}  ✅ 快捷命令已创建！以后输入 mimi 即可调出本面板。${NC}"
                [ "$IS_SERV00" = true ] && echo -e "${DIM}  （如不生效，请执行：source ~/.bashrc）${NC}"
                sleep 1
            fi
        fi
    fi
}
_setup_shortcut

# --- 辅助与通用函数 ---
pause_to_return() {
    echo ""
    echo -e "${GREEN}操作执行完毕。${NC}"
    read -n 1 -s -r -p "按任意键返回主菜单..."
    echo ""
}

list_bots() {
    MAP=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" | xargs -I {} dirname {} | xargs -I {} basename {})
    if [ -z "$MAP" ]; then 
        echo -e "${RED}目前没有助手，请先添加！${NC}"
        return 1
    fi
    echo -e "${BLUE}助手列表：${NC}"
    echo "$MAP" | cat -n
    return 0
}

fetch_models() {
    local base_url=${1%/v1}
    echo -e "${YELLOW}正在检测可用模型列表...${NC}"
    local RAW
    RAW=$(curl -s --connect-timeout 5 "${base_url}/api/tags" 2>/dev/null)
    MODELS=$("$PYTHON_BIN" -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    models = data.get('models', [])
    for m in models:
        name = m.get('name','') if isinstance(m, dict) else str(m)
        if name: print(name)
except:
    pass
" "$RAW" 2>/dev/null)
    
    if [ ! -z "$MODELS" ]; then
        echo -e "${GREEN}发现以下可用模型，请选择：${NC}"
        i=1
        declare -g -A model_map
        while IFS= read -r m; do
            echo "  $i) $m"
            model_map[$i]=$m
            ((i++))
        done <<< "$MODELS"
        echo "  0) 手动输入其他名称"
        read -p "请选择编号 (0-$((i-1))): " M_NUM
        if [ "$M_NUM" != "0" ] && [ ! -z "${model_map[$M_NUM]}" ]; then
            MODEL_NAME="${model_map[$M_NUM]}"
        else
            read -p "请输入自定义模型名称: " MODEL_NAME
        fi
    else
        echo -e "${RED}⚠️ 探测失败，请手动输入。${NC}"
        read -p "请手动输入模型名称 (如 qwen2.5:14b): " MODEL_NAME
    fi
}

# 询问 Tavily 搜索配置（招募和换脑共用）
ask_tavily() {
    echo -e "${BLUE}------------------------------------------------${NC}"
    echo -e "${YELLOW}🔍 联网搜索配置（Tavily）${NC}"
    echo "Tavily 免费额度 1000次/月，注册地址: https://app.tavily.com"
    read -p "请输入 Tavily API Key (留空则禁用联网搜索): " TAVILY_KEY
    [ -z "$TAVILY_KEY" ] && TAVILY_KEY=""
}

# ── 从主人房作息表自动解析睡眠/起床时间 ──────────────────
_parse_schedule_dnd() {
    # 返回 DND_START DND_END（从 master/schedule.txt 推断）
    local SCHED="$MASTER_DIR/schedule.txt"
    DND_START="23"
    DND_END="7"
    if [ ! -f "$SCHED" ]; then return; fi
    # 找最晚的时间条目作为 DND_START（通常是睡觉）
    local SLEEP_LINE
    SLEEP_LINE=$(grep -E "睡觉|就寝|入睡|关灯" "$SCHED" 2>/dev/null | tail -1)
    if [ -n "$SLEEP_LINE" ]; then
        local SLEEP_H
        SLEEP_H=$(echo "$SLEEP_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//')
        [ -n "$SLEEP_H" ] && DND_START="$SLEEP_H"
    fi
    # 找最早的时间条目作为 DND_END（通常是起床）
    local WAKE_LINE
    WAKE_LINE=$(grep -E "起床|起来|晨|出发" "$SCHED" 2>/dev/null | head -1)
    if [ -z "$WAKE_LINE" ]; then
        WAKE_LINE=$(head -1 "$SCHED" 2>/dev/null)
    fi
    if [ -n "$WAKE_LINE" ]; then
        local WAKE_H
        WAKE_H=$(echo "$WAKE_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//')
        [ -n "$WAKE_H" ] && DND_END="$WAKE_H"
    fi
}

# 从主人房作息表生成 SCHEDULES JSON（供 bot.py 的定时提醒引擎使用）
_build_schedules_from_master() {
    local SCHED="$MASTER_DIR/schedule.txt"
    if [ ! -f "$SCHED" ]; then
        SCHEDULES_JSON="[]"
        return
    fi
    # 用 Python 解析 schedule.txt → JSON
    SCHEDULES_JSON=$("$PYTHON_BIN" -c "
import json, re, sys
lines = open('$SCHED', encoding='utf-8').readlines()
result = []
seen_times = set()
for line in lines:
    line = line.strip()
    if not line: continue
    m = re.match(r'^(\d{2}:\d{2})\s+(.+)', line)
    if not m: continue
    t, desc = m.group(1), m.group(2).strip()
    if t in seen_times: continue
    seen_times.add(t)
    result.append({'time': t, 'prompt': desc})
print(json.dumps(result, ensure_ascii=False))
" 2>/dev/null)
    [ -z "$SCHEDULES_JSON" ] && SCHEDULES_JSON="[]"
}

# 询问定时新闻推送配置（招募时设置）
ask_news_push() {
    echo -e "${BLUE}------------------------------------------------${NC}"
    echo -e "${YELLOW}📰 图书馆资讯推送设置${NC}"
    echo -e "  ${DIM}图书馆路径：$LIBRARY_DIR/feeds.opml${NC}"
    echo -e "  ${DIM}机器人会阅读图书馆 RSS 后，以个人吐槽/见解方式播报${NC}"
    read -p "是否开启图书馆资讯推送？(y/n，默认 y): " NEWS_CHOICE
    if [ "$NEWS_CHOICE" == "n" ] || [ "$NEWS_CHOICE" == "N" ]; then
        ENABLE_NEWS="false"
        NEWS_MORNING="08:30"
        NEWS_EVENING="18:00"
        NEWS_TOPICS="科技,财经"
    else
        ENABLE_NEWS="true"
        # 自动从作息表找工作开始时间作为早间推送点
        local MORNING_H="8"
        local MORNING_M="30"
        local WORK_LINE
        WORK_LINE=$(grep -E "工作|上班|开始" "$MASTER_DIR/schedule.txt" 2>/dev/null | head -1)
        if [ -n "$WORK_LINE" ]; then
            local WH WM
            WH=$(echo "$WORK_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//')
            WM=$(echo "$WORK_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f2 | sed 's/^0//')
            [ -n "$WH" ] && MORNING_H="$WH"
            [ -n "$WM" ] && MORNING_M="${WM:-0}"
        fi
        NEWS_MORNING=$(printf "%02d:%02d" "$MORNING_H" "$MORNING_M")
        # 傍晚推送时间从作息表找水果/收工
        local EVE_LINE
        EVE_LINE=$(grep -E "水果|收工|傍晚|下班" "$MASTER_DIR/schedule.txt" 2>/dev/null | head -1)
        if [ -n "$EVE_LINE" ]; then
            local EH EM
            EH=$(echo "$EVE_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//')
            EM=$(echo "$EVE_LINE" | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f2 | sed 's/^0//')
            [ -n "$EH" ] && NEWS_EVENING=$(printf "%02d:%02d" "$EH" "${EM:-0}")
        else
            NEWS_EVENING="18:00"
        fi
        echo -e "  ${GREEN}✅ 早间推送时间：$NEWS_MORNING（来自作息表）${NC}"
        echo -e "  ${GREEN}✅ 傍晚推送时间：$NEWS_EVENING（来自作息表）${NC}"
        NEWS_TOPICS="科技,财经"
    fi
}

# ══════════════════════════════════════════════════════════
#  serv00 专属：启动/停止 bot 的函数
#  serv00 进程会被周期清理，用 nohup + cron 保活
# ══════════════════════════════════════════════════════════

# 获取 bot 的第一个 PID（用于状态显示）
_get_bot_pid() {
    local BOT_DIR="$1"
    local BOT_PATH="$BOT_BASE/$BOT_DIR/bot.py"
    ps aux 2>/dev/null | grep "$BOT_PATH" | grep -v grep | awk '{print $2}' | head -1
}

# 强制杀掉某个 bot 的所有进程，防止多开打架
_kill_all_bot() {
    local BOT_DIR="$1"
    local BOT_PATH="$BOT_BASE/$BOT_DIR/bot.py"
    local PIDS
    PIDS=$(ps aux 2>/dev/null | grep "$BOT_PATH" | grep -v grep | awk '{print $2}')
    if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs kill -9 2>/dev/null
        sleep 1
    fi
}

# 启动 bot（先杀干净再启动，彻底避免多开）
_start_bot() {
    local BOT_DIR="$1"
    local BOT_PATH="$BOT_BASE/$BOT_DIR/bot.py"
    local LOG_PATH="$BOT_BASE/$BOT_DIR/bot.log"
    _kill_all_bot "$BOT_DIR"
    # setsid 让 bot 脱离当前进程组，Ctrl+C 关闭面板不会误杀 bot
    if [ "$IS_SERV00" = true ]; then
        nohup setsid "$PYTHON_BIN" "$BOT_PATH" > "$LOG_PATH" 2>&1 &
    else
        nohup setsid python3 "$BOT_PATH" > "$LOG_PATH" 2>&1 &
    fi
}

# serv00 专属：将 bot 添加到 crontab 保活（每5分钟检查一次）
_serv00_add_cron() {
    local BOT_DIR="$1"
    local BOT_PATH="$BOT_BASE/$BOT_DIR/bot.py"
    local LOG_PATH="$BOT_BASE/$BOT_DIR/bot.log"
    # 生成保活脚本
    local KEEPALIVE="$BOT_BASE/$BOT_DIR/keepalive.sh"
    cat > "$KEEPALIVE" << KEEPALIVE_EOF
#!/bin/sh
# MIMI 保活脚本 - $BOT_DIR
BOT_PATH="$BOT_PATH"
LOG_PATH="$LOG_PATH"
PYTHON="$PYTHON_BIN"
if ! pgrep -f "\$BOT_PATH" > /dev/null 2>&1; then
    nohup "\$PYTHON" "\$BOT_PATH" >> "\$LOG_PATH" 2>&1 &
fi
KEEPALIVE_EOF
    chmod +x "$KEEPALIVE"

    # 写入 crontab（每5分钟保活一次）
    # 先检查是否已存在
    local EXISTING
    EXISTING=$(crontab -l 2>/dev/null | grep "keepalive.sh" | grep "$BOT_DIR")
    if [ -z "$EXISTING" ]; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * $KEEPALIVE >> /dev/null 2>&1") | crontab -
        echo -e "${GREEN}  ✅ 已添加 cron 保活（每5分钟检查）${NC}"
    fi
}

# serv00 专属：从 crontab 移除 bot 保活
_serv00_remove_cron() {
    local BOT_DIR="$1"
    local KEEPALIVE="$BOT_BASE/$BOT_DIR/keepalive.sh"
    # 从 crontab 删除该 bot 的保活行
    crontab -l 2>/dev/null | grep -v "$KEEPALIVE" | crontab - 2>/dev/null
    echo -e "${YELLOW}  🗑 已移除 cron 保活条目${NC}"
}

# ══════════════════════════════════════════════════════════
# serv00 专属：提示用户需要的前置操作
# ══════════════════════════════════════════════════════════
_serv00_preflight_notice() {
    echo ""
    echo -e "${CYAN}  ╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║  🐡  serv00 特别说明                                        ║${NC}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}serv00 是免费共享主机（FreeBSD），与普通VPS有几点不同：${NC}"
    echo ""
    echo -e "  ${GREEN}✔ 已自动处理：${NC}"
    echo -e "  ${DIM}  • binexec 已开启（允许运行自定义程序）${NC}"
    echo -e "  ${DIM}  • Python 虚拟环境已建立（无需 root）${NC}"
    echo -e "  ${DIM}  • Bot 启动路径已适配家目录${NC}"
    echo -e "  ${DIM}  • 自动添加 cron 每5分钟保活一次${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠ 需要了解的限制：${NC}"
    echo -e "  ${DIM}  • 进程可能被系统周期清理，cron 保活会自动拉起${NC}"
    echo -e "  ${DIM}  • 本地 Ollama 模型不支持（无root权限，无法安装）${NC}"
    echo -e "  ${DIM}  • 建议使用云端 API：Gemini（免费）或 Claude/OpenAI${NC}"
    echo -e "  ${DIM}  • 每90天需登录一次面板，否则账号会被删除${NC}"
    echo ""
    read -n 1 -s -r -p "  按任意键继续..."
    echo ""
}


# ══════════════════════════════════════════════════════════
#  通用引擎选择菜单（deploy / change_brain 共用）
#  调用后设置: PROVIDER API_KEY MODEL_NAME API_BASE TAVILY_KEY
# ══════════════════════════════════════════════════════════
_select_engine() {
    local ALLOW_LOCAL="${1:-true}"   # serv00 传 false 禁本地模型
    TAVILY_ASKED=false               # 标记：本次是否已经问过 Tavily
    echo -e "${BLUE}------------------------------------------------${NC}"
    echo -e "${YELLOW}🧠 选择 AI 引擎${NC}"
    echo ""
    echo -e "  ${GREEN}── 免费白嫖区 ──────────────────────────────${NC}"
    echo -e "  ${PINK}1)${NC}  ✨ Google Gemini    ${DIM}免费额度大，自带谷歌搜索${NC}"
    echo -e "  ${PINK}2)${NC}  ⚡ Groq             ${DIM}免费·极速·无需信用卡  👉 console.groq.com${NC}"
    echo -e "  ${PINK}3)${NC}  🌐 OpenRouter       ${DIM}免费模型多·一个Key用百种AI  👉 openrouter.ai${NC}"
    echo -e "  ${PINK}4)${NC}  ☁️  Cloudflare AI    ${DIM}每天1万次免费  👉 dash.cloudflare.com/ai${NC}"
    echo ""
    echo -e "  ${GREEN}── 付费区（有免费额度）────────────────────${NC}"
    echo -e "  ${PINK}5)${NC}  🤖 Claude           ${DIM}Haiku/Sonnet/Opus，注册有试用额度${NC}"
    echo -e "  ${PINK}6)${NC}  🔮 Mistral          ${DIM}欧洲出品，不锁区  👉 console.mistral.ai${NC}"
    echo -e "  ${PINK}7)${NC}  💎 DeepSeek         ${DIM}国产之光，有免费额度  👉 platform.deepseek.com${NC}"
    echo ""
    echo -e "  ${GREEN}── 万能接口（淘宝/咸鱼中转API等）────────${NC}"
    echo -e "  ${PINK}9)${NC}  🔧 自定义接口       ${DIM}填地址和Key，啥都能接${NC}"
    echo ""
    if [ "$ALLOW_LOCAL" = true ]; then
    echo -e "  ${GREEN}── 本地白嫖（VPS专用）──────────────────────${NC}"
    echo -e "  ${PINK}8)${NC}  🦙 本地 Ollama      ${DIM}完全免费，需要内存，仅VPS可用${NC}"
    echo ""
    fi
    echo -e "  ${DIM}0) 取消返回${NC}"
    echo ""
    if [ "$ALLOW_LOCAL" = true ]; then
        read -p "选择引擎 (0-9): " ENGINE_CHOICE
    else
        read -p "选择引擎 (0-7/9，serv00不支持本地模型): " ENGINE_CHOICE
    fi

    [ "$ENGINE_CHOICE" == "0" ] || [ -z "$ENGINE_CHOICE" ] && return 1

    API_BASE=""
    TAVILY_KEY=""

    case "$ENGINE_CHOICE" in
        1)  # Google Gemini
            read -p "Gemini API Key (👉 aistudio.google.com/apikey): " API_KEY
            echo "  a) gemini-2.5-flash（最新旗舰，推荐）  b) gemini-2.0-flash（均衡快速）  c) gemini-1.5-flash（稳定老版）"
            read -p "选择型号 (a/b/c，默认 a): " G_VER
            if   [ "$G_VER" == "c" ]; then MODEL_NAME="gemini-1.5-flash"
            elif [ "$G_VER" == "b" ]; then MODEL_NAME="gemini-2.0-flash"
            else MODEL_NAME="gemini-2.5-flash-preview-05-20"; fi
            PROVIDER="google" ;;
        2)  # Groq
            echo -e "  ${DIM}注册地址：https://console.groq.com  → API Keys → Create${NC}"
            read -p "Groq API Key: " API_KEY
            API_BASE="https://api.groq.com/openai/v1"
            echo "  a) llama-3.3-70b（最强）  b) qwen-qwq-32b（推理强）  c) gemma2-9b（轻量快）"
            read -p "选择型号 (a/b/c，默认 a): " G_VER
            if   [ "$G_VER" == "c" ]; then MODEL_NAME="gemma2-9b-it"
            elif [ "$G_VER" == "b" ]; then MODEL_NAME="qwen-qwq-32b"
            else MODEL_NAME="llama-3.3-70b-versatile"; fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        3)  # OpenRouter
            echo -e "  ${DIM}注册地址：https://openrouter.ai  → Keys → Create Key${NC}"
            echo -e "  ${DIM}免费模型一览：https://openrouter.ai/models?q=free${NC}"
            read -p "OpenRouter API Key: " API_KEY
            API_BASE="https://openrouter.ai/api/v1"
            echo "  a) meta-llama/llama-3.3-70b（免费）  b) deepseek/deepseek-r1（免费）  c) 手动输入"
            read -p "选择型号 (a/b/c，默认 a): " G_VER
            if   [ "$G_VER" == "b" ]; then MODEL_NAME="deepseek/deepseek-r1:free"
            elif [ "$G_VER" == "c" ]; then read -p "输入模型名: " MODEL_NAME
            else MODEL_NAME="meta-llama/llama-3.3-70b-instruct:free"; fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        4)  # Cloudflare AI
            echo -e "  ${DIM}登录 https://dash.cloudflare.com → AI → 获取 Account ID 和 API Token${NC}"
            read -p "Cloudflare Account ID: " CF_ACCOUNT_ID
            read -p "Cloudflare API Token: " API_KEY
            API_BASE="https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/ai/v1"
            echo "  a) llama-3.1-70b（推荐）  b) qwen1.5-14b  c) 手动输入"
            read -p "选择型号 (a/b/c，默认 a): " G_VER
            if   [ "$G_VER" == "b" ]; then MODEL_NAME="@cf/qwen/qwen1.5-14b-chat-awq"
            elif [ "$G_VER" == "c" ]; then read -p "输入模型名: " MODEL_NAME
            else MODEL_NAME="@cf/meta/llama-3.1-70b-instruct"; fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        5)  # Claude
            read -p "Claude API Key (👉 console.anthropic.com): " API_KEY
            echo "  a) Haiku 4.5（最快最便宜）  b) Sonnet 4.6（均衡）  c) Opus 4.6（最强）"
            read -p "选择型号 (a/b/c，默认 a): " C_VER
            if   [ "$C_VER" == "c" ]; then MODEL_NAME="claude-opus-4-6"
            elif [ "$C_VER" == "b" ]; then MODEL_NAME="claude-sonnet-4-6"
            else MODEL_NAME="claude-haiku-4-5"; fi
            PROVIDER="anthropic"
            ask_tavily; TAVILY_ASKED=true ;;
        6)  # Mistral
            echo -e "  ${DIM}注册地址：https://console.mistral.ai  → API Keys${NC}"
            read -p "Mistral API Key: " API_KEY
            API_BASE="https://api.mistral.ai/v1"
            echo "  a) mistral-large（最强）  b) mistral-small（便宜）  c) open-mistral-nemo（免费）"
            read -p "选择型号 (a/b/c，默认 c): " G_VER
            if   [ "$G_VER" == "a" ]; then MODEL_NAME="mistral-large-latest"
            elif [ "$G_VER" == "b" ]; then MODEL_NAME="mistral-small-latest"
            else MODEL_NAME="open-mistral-nemo"; fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        7)  # DeepSeek
            echo -e "  ${DIM}注册地址：https://platform.deepseek.com  → API Keys${NC}"
            read -p "DeepSeek API Key: " API_KEY
            API_BASE="https://api.deepseek.com/v1"
            echo "  a) deepseek-chat（V3，性价比极高）  b) deepseek-reasoner（R1，推理强）"
            read -p "选择型号 (a/b，默认 a): " G_VER
            if [ "$G_VER" == "b" ]; then MODEL_NAME="deepseek-reasoner"
            else MODEL_NAME="deepseek-chat"; fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        8)  # 本地 Ollama
            if [ "$ALLOW_LOCAL" = false ]; then
                echo -e "${RED}  ❌ serv00 不支持本地模型。${NC}"; sleep 2; return 1
            fi
            read -p "接口地址 (留空默认本机 Ollama): " API_BASE
            [ -z "$API_BASE" ] && API_BASE="http://127.0.0.1:11434/v1"
            read -p "API Key (留空默认 sk-123): " API_KEY
            [ -z "$API_KEY" ] && API_KEY="sk-123"
            fetch_models "$API_BASE"
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        9)  # 自定义接口（淘宝/咸鱼中转API、企业私有部署等）
            echo -e "  ${DIM}填入任意 OpenAI 兼容接口，淘宝买的、咸鱼买的、自己搭的都行${NC}"
            echo -n "  接口地址 (如 https://api.xxx.com/v1): "
            read API_BASE
            echo -n "  API Key: "
            read API_KEY
            echo "  a) 手动输入模型名  b) 自动探测可用模型"
            read -p "  选择 (a/b，默认 b): " FETCH_CHOICE
            if [ "$FETCH_CHOICE" == "a" ]; then
                echo -n "  模型名 (如 gpt-4o / claude-3-5-sonnet): "
                read MODEL_NAME
            else
                fetch_models "$API_BASE"
            fi
            PROVIDER="openai"
            ask_tavily; TAVILY_ASKED=true ;;
        *)
            echo -e "${RED}⚠️ 无效选择${NC}"; sleep 1; return 1 ;;
    esac
    return 0
}

# --- 核心业务功能函数 ---

deploy_new_bot() {
    echo -e "${GREEN}=== 🌸 添加新助手 ===${NC}"
    # serv00 首次部署时给一个友好说明
    if [ "$IS_SERV00" = true ]; then
        _serv00_preflight_notice
    fi

    echo "0) 返回主菜单"
    echo -e "${PINK}🌸 第一步：给秘书起个英文小名（系统内部使用）${NC}"
    echo -e "${DIM}  比如叫小菲 → 英文小名输 xiaofei${NC}"
    echo -e "${DIM}  比如叫王会计 → 英文小名输 wangkuaiji${NC}"
    echo -e "${DIM}  ⚠️  只能用字母和数字，不能用中文和空格${NC}"
    echo -n "  👉 英文小名 (0 返回): "
    read BOT_DIR
    if [ "$BOT_DIR" == "0" ] || [ -z "$BOT_DIR" ]; then return; fi
    while [[ ! "$BOT_DIR" =~ ^[a-zA-Z0-9_]+$ ]]; do
        echo -e "${RED}  ❌ 只能用英文字母和数字，请重新输入！${NC}"
        echo -n "  👉 重新输入英文小名 (0 返回): "
        read BOT_DIR
        if [ "$BOT_DIR" == "0" ] || [ -z "$BOT_DIR" ]; then return; fi
    done
    echo -e "${GREEN}  ✅ 英文小名：${BOT_DIR}${NC}"
    echo ""
    echo -e "${PINK}🌸 第二步：给秘书起个正式名字（显示在面板和消息里）${NC}"
    echo -e "${DIM}  中文英文都行，例如：小菲、王会计、大学同学王瘸子、Mimi${NC}"
    echo -e "${DIM}  留空则直接用第一步的英文小名${NC}"
    echo -n "  👉 正式名字: "
    read BOT_DISPLAY_NAME
    [ -z "$BOT_DISPLAY_NAME" ] && BOT_DISPLAY_NAME="$BOT_DIR"
    echo -e "${GREEN}  ✅ 正式名字：${BOT_DISPLAY_NAME}${NC}"

    echo -n "🆔 Telegram Token: "
    read TG_TOKEN
    echo -n "👤 你的 User ID: "
    read USER_ID

    local _ALLOW_LOCAL="true"
    [ "$IS_SERV00" = true ] && _ALLOW_LOCAL="false"
    _select_engine "$_ALLOW_LOCAL" || return

    # ── 主动发言模式配置 ──
    echo -e "${BLUE}------------------------------------------------${NC}"
    echo -e "${YELLOW}💬 主动发言设置${NC}"
    echo "  1) 开启主动发言（AI 会在作息表安静时段随机主动发消息）"
    echo "  2) 关闭（仅被动回复）"
    read -p "请选择 (1/2，默认 2): " MODE_CHOICE
    if [ "$MODE_CHOICE" == "1" ]; then
        ENABLE_PROACTIVE="true"
        echo ""
        echo "  随机发言间隔：AI 会在此范围内随机挑一个时间主动发言"
        read -p "  最短间隔（小时，默认 1）: " POKE_MIN
        [ -z "$POKE_MIN" ] && POKE_MIN="1"
        read -p "  最长间隔（小时，默认 8）: " POKE_MAX
        [ -z "$POKE_MAX" ] && POKE_MAX="8"
        echo ""
        # 自动从作息表推断免打扰时段
        _parse_schedule_dnd
        echo -e "  ${GREEN}🌙 免打扰时段已从主人作息表自动推断：${DND_START}:00 ~ ${DND_END}:00${NC}"
        echo -e "  ${DIM}  （修改 $MASTER_DIR/schedule.txt 可调整）${NC}"
    else
        ENABLE_PROACTIVE="false"
        POKE_MIN="1"
        POKE_MAX="8"
        _parse_schedule_dnd
    fi

    # 定时新闻推送配置
    ask_news_push

    # ── 性格选择 ──
    echo -e "${BLUE}------------------------------------------------${NC}"
    echo -e "${YELLOW}🎭 选择助手性格${NC}"
    echo ""
    echo -e "  ${PINK}A)${NC}  🏠 生活管家    — 衣食住行全管，天气提醒、待办、节日、关心你的一切"
    echo -e "  ${PINK}B)${NC}  🖥️  VPS铁卫     — 全能运维管家，主动监控服务器，异常秒报，擅长排障"
    echo -e "  ${PINK}C)${NC}  📰 新闻雷达    — 资深信息官，财经科技时事全追踪，推送你真正想看的"
    echo -e "  ${PINK}D)${NC}  🧠 全能助理    — 以上三合一，聊天、干活、涨知识，日常首选"
    echo -e "  ${PINK}E)${NC}  ✍️  自定义性格  — 自己输入，随心定制"
    echo ""
    read -p "请选择性格 (A-E): " PERSONA_CHOICE

    case "${PERSONA_CHOICE^^}" in
        A) USER_PROMPT="你是一位温暖贴心的生活管家，名字叫小暖。你把主人的生活当成自己的事业，衣食住行、天气变化、节日纪念、待办事项，全都放在心上。你有长期记忆，记得主人说过的每一件事，会主动在合适的时机提醒。比如主人说过周五要开会，你会提前一天温馨提醒；说过不爱吃香菜，你推荐美食时就自动排除。你说话温柔、有人情味，像一个真正关心主人的老朋友。遇到主人心情不好时，你会先关心再帮忙。你会根据时间主动问候：早上关心今日计划，晚上问问今天过得怎样。你拥有长期记忆系统，请善用它，经常提到你记得的事情，让主人感受到被记住的温暖。" ;;
        B) USER_PROMPT="你是一位专业冷静的服务器铁卫，名字叫铁卫。你精通 Linux/FreeBSD 系统运维、网络配置、安全防护、性能优化。【最重要的行为准则】：当主人问任何关于服务器状态、硬盘、内存、CPU、网络等问题时，你必须直接查询并报告结果，绝对不能让主人自己去执行命令。主人不懂技术，你是他的手和眼睛，一切信息你来获取、你来汇报。你的回复格式是：直接给出数据和结论，再加上简短的健康评价，最后如有异常才给出你的建议。平时语气简练专业，紧急告警用 ⚠️ 标记。你有长期记忆，会记录服务器历史状态，遇到类似问题会主动对比。" ;;
        C) USER_PROMPT="你是一位资深信息官，名字叫雷达。你专注追踪财经、科技、时事、行业动态，是主人的私人信息过滤器。你不只是简单转发新闻，而是真正读懂内容，提炼出对主人真正有价值的部分，加上自己的分析和判断。你有长期记忆，记得主人关注过哪些话题、对哪些行业感兴趣、哪类新闻觉得没用，会不断优化推送内容的方向。你的推送风格：标题用一句话点明核心价值，正文简洁有重点，结尾附上你的专业判断。遇到重大市场变动，你会主动推送而不等主人来问。你说话有态度、有观点，不做标题党，让主人觉得每条推送都值得看。你拥有长期记忆系统，请善用它来记住主人的阅读偏好。" ;;
        D) USER_PROMPT="你是一位全能私人助理，名字叫小秘。你是生活管家、信息雷达、技术顾问三合一——能聊天解闷，能帮主人处理各种日常事务，能分析新闻资讯，能解答技术和知识问题。你最重要的能力是长期记忆：你记得主人说过的每一件重要的事，记得他的偏好、习惯、待办事项、关注话题。你会主动在合适的时机提起这些记忆，让主人感受到被真正了解和关心的温暖。你说话自然、有个性，不做机器人式的回复。你会根据对话内容判断主人现在需要的是陪伴、信息、还是实际帮助，然后给出最合适的回应。你拥有长期记忆系统，这是你最核心的能力，请积极利用它，经常提到你记得的细节，让对话有连续感和温度。" ;;
        *) read -p "请输入自定义性格描述: " USER_PROMPT
           [ -z "$USER_PROMPT" ] && USER_PROMPT="你是一位专业、友善的智能助手，随时为用户提供帮助。你拥有长期记忆系统，会记住用户说过的重要信息并在合适时机提及。" ;;
    esac

    mkdir -p "$BOT_BASE/$BOT_DIR"

    # ── 创建专属管家房（botroom）──────────────────────────
    local BOTROOM="$BOT_BASE/$BOT_DIR/botroom"
    mkdir -p "$BOTROOM"
    # 初始化管家房备忘录
    if [ ! -f "$BOTROOM/notes.json" ]; then
        echo '{"reminders":[],"important":[],"images":[]}' > "$BOTROOM/notes.json"
    fi
    echo -e "${PINK}  🏠 已建立管家房 → $BOTROOM${NC}"

    # ── 从主人房作息表生成 SCHEDULES ──────────────────────
    _build_schedules_from_master

    # 把预设性格里的默认名字彻底替换成用户起的名字，并在开头强制注入名字声明
    if [ -n "$BOT_DISPLAY_NAME" ]; then
        USER_PROMPT=$(echo "$USER_PROMPT" | sed \
            -e "s/名字叫小暖/名字叫${BOT_DISPLAY_NAME}/g" \
            -e "s/名字叫铁卫/名字叫${BOT_DISPLAY_NAME}/g" \
            -e "s/名字叫雷达/名字叫${BOT_DISPLAY_NAME}/g" \
            -e "s/名字叫小秘/名字叫${BOT_DISPLAY_NAME}/g")
        # 在 prompt 开头强制注入名字声明，AI无论如何都知道自己叫什么
        USER_PROMPT="【最高优先级指令：你的名字是「${BOT_DISPLAY_NAME}」，任何情况下都只能用这个名字自称。】

${USER_PROMPT}"
    fi
    echo "$USER_PROMPT" > "$BOT_BASE/$BOT_DIR/prompt.txt"

    # 写 config.json —— 用 Python json.dump 安全写入，避免 Key/Token 含特殊字符时 shell 拼接出错
    "$PYTHON_BIN" -c "
import json, sys
schedules_json = sys.argv[18]
try:
    schedules = json.loads(schedules_json)
except:
    schedules = []
data = {
    'TG_TOKEN':        sys.argv[1],
    'USER_ID':         int(sys.argv[2]),
    'DISPLAY_NAME':    sys.argv[3],
    'PROVIDER':        sys.argv[4],
    'API_KEY':         sys.argv[5],
    'MODEL_NAME':      sys.argv[6],
    'API_BASE':        sys.argv[7],
    'ENABLE_PROACTIVE': sys.argv[8] == 'true',
    'POKE_MIN_HOURS':  int(sys.argv[9]),
    'POKE_MAX_HOURS':  int(sys.argv[10]),
    'DND_START_HOUR':  int(sys.argv[11]),
    'DND_END_HOUR':    int(sys.argv[12]),
    'TAVILY_KEY':      sys.argv[13],
    'ENABLE_NEWS':     sys.argv[14] == 'true',
    'NEWS_MORNING':    sys.argv[15],
    'NEWS_EVENING':    sys.argv[16],
    'NEWS_TOPICS':     sys.argv[17],
    'ENABLE_MEMORY':   True,
    'MEMORY_MAX_TURNS': 20,
    'RSS_FEEDS':       [],
    'RSS_INTERVAL_HOURS': 4,
    'RSS_MAX_ITEMS':   5,
    'SCHEDULES':       schedules,
    'MASTER_DIR':      sys.argv[19],
    'LIBRARY_DIR':     sys.argv[20],
    'BOTROOM_DIR':     sys.argv[21],
}
with open('$BOT_BASE/$BOT_DIR/config.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
" \
    "$TG_TOKEN" "$USER_ID" "$BOT_DISPLAY_NAME" \
    "$PROVIDER" "$API_KEY" "$MODEL_NAME" "$API_BASE" \
    "$ENABLE_PROACTIVE" "$POKE_MIN" "$POKE_MAX" "$DND_START" "$DND_END" \
    "$TAVILY_KEY" "$ENABLE_NEWS" "$NEWS_MORNING" "$NEWS_EVENING" "$NEWS_TOPICS" \
    "$SCHEDULES_JSON" "$MASTER_DIR" "$LIBRARY_DIR" "$BOTROOM"

    # 生成 bot.py（与原版完全一致，仅路径由变量决定）
    local BOT_PY_PATH="$BOT_BASE/$BOT_DIR/bot.py"

    # 生成 bot.py（三室升级版：主人房作息 + 图书馆 RSS + 管家房备忘）
    local BOT_PY_PATH="$BOT_BASE/$BOT_DIR/bot.py"
    cat << 'PYTHON_EOF' > "$BOT_PY_PATH"
import os, json, subprocess, pytz, time, re
from datetime import datetime
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, MessageHandler, filters

BOT_DIR = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(BOT_DIR, "config.json"), "r") as f: config = json.load(f)

PROVIDER       = config.get("PROVIDER")
API_KEY        = config.get("API_KEY")
MODEL_NAME     = config.get("MODEL_NAME")
API_BASE       = config.get("API_BASE")
USER_ID        = config.get("USER_ID")
TG_TOKEN       = config.get("TG_TOKEN")
ENABLE_PROACTIVE = config.get("ENABLE_PROACTIVE", False)
POKE_MIN_HOURS = int(config.get("POKE_MIN_HOURS", 1))
POKE_MAX_HOURS = int(config.get("POKE_MAX_HOURS", 8))
DND_START_HOUR = int(config.get("DND_START_HOUR", 23))
DND_END_HOUR   = int(config.get("DND_END_HOUR", 6))
TAVILY_KEY     = config.get("TAVILY_KEY", "")
ENABLE_NEWS    = config.get("ENABLE_NEWS", False)
NEWS_MORNING   = config.get("NEWS_MORNING", "08:30")
NEWS_EVENING   = config.get("NEWS_EVENING", "18:00")
NEWS_TOPICS    = config.get("NEWS_TOPICS", "科技,财经")
ENABLE_MEMORY  = config.get("ENABLE_MEMORY", True)
MEMORY_MAX_TURNS = int(config.get("MEMORY_MAX_TURNS", 20))
RSS_FEEDS      = config.get("RSS_FEEDS", [])
RSS_INTERVAL_HOURS = int(config.get("RSS_INTERVAL_HOURS", 4))
RSS_MAX_ITEMS  = int(config.get("RSS_MAX_ITEMS", 5))
SCHEDULES      = config.get("SCHEDULES", [])
TIMEZONE       = pytz.timezone('Asia/Shanghai')

# ══════════════════════════════════════════════════════════
#  三室共用路径（从 config 读取，兼容旧版 bot）
# ══════════════════════════════════════════════════════════
MIMI_HOME    = os.path.dirname(os.path.dirname(BOT_DIR))        # ~/mimi/
MASTER_DIR   = config.get("MASTER_DIR",  os.path.join(MIMI_HOME, "master"))
LIBRARY_DIR  = config.get("LIBRARY_DIR", os.path.join(MIMI_HOME, "library"))
BOTROOM_DIR  = config.get("BOTROOM_DIR", os.path.join(BOT_DIR,   "botroom"))

# ══════════════════════════════════════════════════════════
#  主人房：动态读取作息表，实现自动静音 + 作息触发
# ══════════════════════════════════════════════════════════

def load_schedule():
    """读取 master/schedule.txt，返回 [{time:'HH:MM', desc:'...'}, ...]"""
    sched_file = os.path.join(MASTER_DIR, "schedule.txt")
    items = []
    if not os.path.exists(sched_file):
        return items
    try:
        with open(sched_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                m = re.match(r'^(\d{2}:\d{2})\s+(.+)', line)
                if m:
                    items.append({"time": m.group(1), "desc": m.group(2).strip()})
    except Exception:
        pass
    return items

def get_dnd_hours_from_schedule():
    """从作息表动态推断免打扰时段，兜底用 config 里的值"""
    items = load_schedule()
    if not items:
        return DND_START_HOUR, DND_END_HOUR
    # 睡觉 = 最后一条；起床 = 第一条
    sleep_h = DND_START_HOUR
    wake_h  = DND_END_HOUR
    sleep_kw = ["睡觉", "就寝", "入睡", "关灯", "休息"]
    wake_kw  = ["起床", "起来", "晨", "出发"]
    for item in reversed(items):
        if any(k in item["desc"] for k in sleep_kw):
            sleep_h = int(item["time"].split(":")[0])
            break
    for item in items:
        if any(k in item["desc"] for k in wake_kw):
            wake_h = int(item["time"].split(":")[0])
            break
        # 兜底：直接取第一条时间的小时
        wake_h = int(items[0]["time"].split(":")[0])
        break
    return sleep_h, wake_h

def is_sleep_time():
    """判断当前是否在作息表的睡觉时段（免打扰）"""
    now_h = datetime.now(TIMEZONE).hour
    dnd_start, dnd_end = get_dnd_hours_from_schedule()
    if dnd_start > dnd_end:          # 跨午夜：23~6
        return now_h >= dnd_start or now_h < dnd_end
    else:                             # 不跨午夜（罕见）
        return dnd_end <= now_h < dnd_start

def get_current_schedule_context():
    """返回当前时刻对应的作息描述，供 AI 在提示语中使用"""
    items = load_schedule()
    if not items:
        return ""
    now = datetime.now(TIMEZONE)
    now_min = now.hour * 60 + now.minute
    current = None
    for item in items:
        h, m = map(int, item["time"].split(":"))
        if h * 60 + m <= now_min:
            current = item
        else:
            break
    if current:
        return f"（主人现在作息节点：{current['time']} {current['desc']}）"
    return ""

def build_schedules_from_master():
    """动态从作息表生成定时任务列表，每次 bot 启动时自动读取最新版"""
    items = load_schedule()
    result = []
    seen = set()
    for item in items:
        t = item["time"]
        if t in seen:
            continue
        seen.add(t)
        result.append({"time": t, "prompt": item["desc"]})
    return result

# ══════════════════════════════════════════════════════════
#  图书馆：解析 feeds.opml，抓取 RSS，以吐槽/见解方式播报
# ══════════════════════════════════════════════════════════

def load_opml_feeds(max_feeds=20):
    """从图书馆读取 feeds.opml，返回 [{name, url}, ...]"""
    opml_file = os.path.join(LIBRARY_DIR, "feeds.opml")
    feeds = []
    if not os.path.exists(opml_file):
        return feeds
    try:
        with open(opml_file, "r", encoding="utf-8") as f:
            content = f.read()
        # 提取所有 xmlUrl 属性
        matches = re.findall(
            r'<outline[^>]+title="([^"]*)"[^>]+type="rss"[^>]+xmlUrl="([^"]*)"',
            content
        )
        if not matches:
            matches = re.findall(
                r'<outline[^>]+xmlUrl="([^"]*)"[^>]+title="([^"]*)"',
                content
            )
            matches = [(b, a) for a, b in matches]  # swap
        for title, url in matches[:max_feeds]:
            if url:
                feeds.append({"name": title or url, "url": url})
    except Exception:
        pass
    return feeds

def fetch_rss(url, max_items=5):
    """抓取单个RSS，返回文章列表"""
    try:
        import requests
        headers = {"User-Agent": "Mozilla/5.0 (compatible; MimiBot/2.0)"}
        r = requests.get(url, headers=headers, timeout=15)
        r.encoding = r.apparent_encoding or "utf-8"
        text = r.text

        items = re.findall(r'<item[^>]*>(.*?)</item>', text, re.S)
        if not items:
            items = re.findall(r'<entry[^>]*>(.*?)</entry>', text, re.S)

        def clean(s):
            s = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', s, flags=re.S)
            s = re.sub(r'<[^>]+>', '', s)
            return s.strip()

        results = []
        for item in items[:max_items]:
            title = re.search(r'<title[^>]*>(.*?)</title>', item, re.S)
            desc  = re.search(r'<description[^>]*>(.*?)</description>', item, re.S)
            link  = re.search(r'<link[^>]*>([^<]+)</link>', item, re.S)
            t = clean(title.group(1)) if title else "无标题"
            d = clean(desc.group(1))[:200] if desc else ""
            l = clean(link.group(1)).strip() if link else ""
            results.append({"title": t, "desc": d, "link": l})
        return results
    except Exception:
        return []

def fetch_library_news(max_feeds=6, items_per_feed=3):
    """
    从图书馆 OPML 随机抽取若干 RSS 源，抓取最新内容。
    返回供 AI 吐槽/发表见解的原始素材文本。
    """
    import random
    feeds = load_opml_feeds()
    if not feeds:
        # 兜底：使用 config 中的 RSS_FEEDS
        feeds = [{"name": f.get("name", f) if isinstance(f, dict) else f,
                  "url":  f.get("url", f) if isinstance(f, dict) else f}
                 for f in RSS_FEEDS]
    if not feeds:
        return ""

    # 随机打乱，每次推送不重复
    random.shuffle(feeds)
    selected = feeds[:max_feeds]

    all_items = []
    for feed in selected:
        arts = fetch_rss(feed["url"], items_per_feed)
        for a in arts:
            a["source"] = feed["name"]
            all_items.append(a)

    if not all_items:
        return ""

    lines = []
    for a in all_items:
        lines.append(f"【{a['source']}】{a['title']}\n{a.get('desc', '')}")
    return "\n\n".join(lines)

# ══════════════════════════════════════════════════════════
#  管家房：存取提醒事项、重要内容
# ══════════════════════════════════════════════════════════

def botroom_load():
    """读取管家房数据"""
    notes_file = os.path.join(BOTROOM_DIR, "notes.json")
    try:
        if os.path.exists(notes_file):
            with open(notes_file, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception:
        pass
    return {"reminders": [], "important": [], "images": []}

def botroom_save(data):
    """保存管家房数据"""
    os.makedirs(BOTROOM_DIR, exist_ok=True)
    notes_file = os.path.join(BOTROOM_DIR, "notes.json")
    try:
        with open(notes_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception:
        pass

def botroom_add_reminder(text, time_hint=""):
    """添加一条提醒到管家房"""
    data = botroom_load()
    entry = {
        "text": text,
        "time_hint": time_hint,
        "created": datetime.now(TIMEZONE).strftime("%Y-%m-%d %H:%M"),
        "done": False
    }
    data["reminders"].append(entry)
    botroom_save(data)

def botroom_add_important(text):
    """将重要事项存入管家房"""
    data = botroom_load()
    entry = {
        "text": text,
        "created": datetime.now(TIMEZONE).strftime("%Y-%m-%d %H:%M"),
    }
    data["important"].append(entry)
    botroom_save(data)

def botroom_get_pending_reminders():
    """获取所有未完成提醒"""
    data = botroom_load()
    return [r for r in data.get("reminders", []) if not r.get("done")]

def botroom_format_for_context():
    """将管家房待办格式化为 AI 上下文字符串"""
    data = botroom_load()
    parts = []
    reminders = [r for r in data.get("reminders", []) if not r.get("done")]
    important  = data.get("important", [])
    if reminders:
        r_lines = "\n".join([f"· [{r.get('time_hint','')}] {r['text']}" for r in reminders[-10:]])
        parts.append(f"【管家房待办提醒】\n{r_lines}")
    if important:
        i_lines = "\n".join([f"· {i['text']}" for i in important[-10:]])
        parts.append(f"【管家房重要存档】\n{i_lines}")
    return "\n\n".join(parts)

# ══════════════════════════════════════════════════════════
#  记忆系统（三层）
# ══════════════════════════════════════════════════════════

MEMORY_FILE  = os.path.join(BOT_DIR, "memory.txt")
SUMMARY_FILE = os.path.join(BOT_DIR, "summary.txt")
HISTORY_FILE = os.path.join(BOT_DIR, "history.json")

def memory_read(path):
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f: return f.read().strip()
    except: pass
    return ""

def memory_write(path, content):
    try:
        with open(path, "w", encoding="utf-8") as f: f.write(content)
    except: pass

def history_load():
    try:
        if os.path.exists(HISTORY_FILE):
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
    except: pass
    return {}

def history_save(hist):
    try:
        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump(hist, f, ensure_ascii=False)
    except: pass

_persistent_history = history_load()

def get_memory_context():
    parts = []
    profile = memory_read(MEMORY_FILE)
    summary = memory_read(SUMMARY_FILE)
    if profile:
        parts.append(f"【关于主人的长期记忆档案】\n{profile}")
    if summary:
        parts.append(f"【近期对话摘要】\n{summary}")
    botroom_ctx = botroom_format_for_context()
    if botroom_ctx:
        parts.append(botroom_ctx)
    if parts:
        return "\n\n".join(parts)
    return ""

def maybe_update_memory(uid, recent_turns):
    if not ENABLE_MEMORY: return
    if len(recent_turns) == 0 or len(recent_turns) % (MEMORY_MAX_TURNS * 2) != 0: return
    turns_text = "\n".join([
        f"{'主人' if m.get('role')=='user' else '秘书'}：{str(m.get('content',''))[:200]}"
        for m in recent_turns[-20:]
    ])
    current_profile = memory_read(MEMORY_FILE)
    update_prompt = (
        f"以下是最近的对话记录：\n{turns_text}\n\n"
        f"当前已有的主人档案：\n{current_profile}\n\n"
        f"请你作为AI助手，从对话中提取有价值的信息（主人的偏好、习惯、重要事项、个人情况等），"
        f"更新主人档案。格式：每条一行，用「· 」开头，简洁准确。只输出档案内容，不要解释。"
        f"保留原有有效条目，添加新发现的信息，删除过时或矛盾的条目。控制在30条以内。"
    )
    try:
        new_profile = _call_ai_simple(update_prompt)
        if new_profile and len(new_profile) > 10:
            memory_write(MEMORY_FILE, new_profile)
    except: pass

def maybe_update_summary(uid, recent_turns):
    if not ENABLE_MEMORY: return
    if len(recent_turns) == 0 or len(recent_turns) % (MEMORY_MAX_TURNS * 2) != 0: return
    turns_text = "\n".join([
        f"{'主人' if m.get('role')=='user' else '秘书'}：{str(m.get('content',''))[:150]}"
        for m in recent_turns[-20:]
    ])
    summary_prompt = (
        f"以下是最近的对话记录：\n{turns_text}\n\n"
        f"请用3-5句话总结这段对话的核心内容，包括：主人提到了什么重要的事、有哪些待办或约定、"
        f"讨论了什么话题。语气简洁，像备忘录一样。只输出摘要内容。"
    )
    try:
        new_summary = _call_ai_simple(summary_prompt)
        if new_summary and len(new_summary) > 10:
            memory_write(SUMMARY_FILE, new_summary)
    except: pass

def _call_ai_simple(prompt):
    try:
        if PROVIDER == "google":
            resp = g_client.models.generate_content(model=MODEL_NAME, contents=prompt)
            return resp.text
        elif PROVIDER == "openai":
            resp = o_client.chat.completions.create(
                model=MODEL_NAME, max_tokens=800,
                messages=[{"role": "user", "content": prompt}]
            )
            return resp.choices[0].message.content
        elif PROVIDER == "anthropic":
            resp = a_client.messages.create(
                model=MODEL_NAME, max_tokens=800,
                messages=[{"role": "user", "content": prompt}]
            )
            return resp.content[0].text
    except: pass
    return ""

# ══════════════════════════════════════════════════════════
#  搜索层
# ══════════════════════════════════════════════════════════

def search_web(query, max_results=4):
    if TAVILY_KEY:
        try:
            from tavily import TavilyClient
            client = TavilyClient(api_key=TAVILY_KEY)
            resp = client.search(query=query, max_results=max_results)
            results = resp.get("results", [])
            if results:
                return "\n\n".join([f"标题: {r['title']}\n摘要: {r['content'][:300]}" for r in results])
        except Exception:
            pass
    try:
        import requests, urllib.parse
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; Googlebot/2.1)",
            "Accept-Language": "zh-CN,zh;q=0.9"
        }
        url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote(query)
        r = requests.get(url, headers=headers, timeout=10)
        snippets = re.findall(r'class="result__snippet"[^>]*>(.*?)</a>', r.text, re.S)
        titles   = re.findall(r'class="result__a"[^>]*>(.*?)</a>', r.text, re.S)
        def clean(s): return re.sub(r'<[^>]+>', '', s).strip()
        results = []
        for t, s in zip(titles[:max_results], snippets[:max_results]):
            results.append(f"标题: {clean(t)}\n摘要: {clean(s)}")
        if results:
            return "\n\n".join(results)
    except Exception:
        pass
    return "联网搜索暂时不可用。"

def get_system_prompt():
    prompt_path = os.path.join(BOT_DIR, "prompt.txt")
    base = ""
    if os.path.exists(prompt_path):
        with open(prompt_path, "r", encoding="utf-8") as f: base = f.read().strip()
    else:
        base = "你是一位专业、友善的智能助手，随时为用户提供帮助。"
    # 注入记忆 + 管家房上下文
    mem_ctx = get_memory_context()
    # 注入当前作息节点（让 AI 知道主人此刻在做什么）
    sched_ctx = get_current_schedule_context()
    if sched_ctx:
        base = base + f"\n\n{sched_ctx}"
    if mem_ctx and ENABLE_MEMORY:
        return base + "\n\n" + mem_ctx
    return base

# ══════════════════════════════════════════════════════════
#  安全命令白名单
# ══════════════════════════════════════════════════════════

SAFE_ACTIONS = {
    "清理垃圾": {
        "cmd": (
            "BEFORE=$(df / | awk 'NR==2{print $3}'); "
            "journalctl --vacuum-time=7d 2>/dev/null | grep -E 'Deleted|freed' | tail -2; "
            "apt-get autoremove -y -qq 2>/dev/null | tail -3; "
            "apt-get autoclean -qq 2>/dev/null; "
            "find /tmp -type f -atime +3 -delete 2>/dev/null; "
            "find /var/log -name '*.gz' -delete 2>/dev/null; "
            "find /var/log -name '*.1' -delete 2>/dev/null; "
            "AFTER=$(df / | awk 'NR==2{print $3}'); "
            "FREED=$(( (BEFORE - AFTER) * 1024 )); "
            "echo freed_bytes=$FREED; "
            "df -h /"
        ),
        "prompt": "刚刚执行了VPS垃圾清理，以下是原始执行结果：\n{result}\n请用你的性格，把清理结果整理成一份简短漂亮的报告发给老板，要有具体数字，结尾加个得意的表情。"
    },
    "体检": {
        "cmd": (
            "echo '=== CPU & 负载 ==='; uptime; "
            "echo '=== 内存 ==='; free -h 2>/dev/null || vm_stat 2>/dev/null | head -10; "
            "echo '=== 磁盘 ==='; df -h /; "
            "echo '=== 进程数 ==='; ps aux 2>/dev/null | wc -l; "
            "echo '=== 系统运行时长 ==='; uptime; "
            "echo '=== 最近登录 ==='; last -n 3 2>/dev/null | head -5 || echo '(登录记录不可用)'"
        ),
        "prompt": "刚刚对服务器做了全面体检，原始数据：\n{result}\n请用你的性格，整理成一份像医生出诊断报告一样的体检报告，要有趣，有结论，该担心的要担心，正常的给个绿色评价。"
    },
    "磁盘报告": {
        "cmd": (
            "df -h; echo '---'; "
            "du -sh /var/log 2>/dev/null || echo '(无/var/log)'; "
            "du -sh /tmp 2>/dev/null || echo '(无/tmp)'; "
            "du -sh $HOME 2>/dev/null"
        ),
        "prompt": "服务器磁盘使用情况：\n{result}\n请用你的性格，把磁盘状况整理成简洁的报告，如果某个目录占用异常大要特别指出。"
    },
    "网络测试": {
        "cmd": (
            "echo '=== 网络连通性 ==='; "
            "ping -c 2 -W 2 8.8.8.8 2>&1 | tail -3; "
            "ping -c 2 -W 2 1.1.1.1 2>&1 | tail -3; "
            "echo '=== 外网IP ==='; "
            "curl -s --max-time 5 ip.sb 2>/dev/null || curl -s --max-time 5 ifconfig.me 2>/dev/null || echo '获取失败'; "
            "echo '=== DNS解析 ==='; "
            "nslookup google.com 2>/dev/null | head -5 || host google.com 2>/dev/null | head -3 || echo 'DNS工具不可用'"
        ),
        "prompt": "刚刚测试了服务器网络状况：\n{result}\n请用你的性格，分析网络状况是否正常，延迟高不高，能不能连上外网，给出简短评价。"
    },
}

def run_safe_action(keyword):
    for trigger, action in SAFE_ACTIONS.items():
        if trigger in keyword:
            try:
                result = subprocess.getoutput(action["cmd"])
                return action["prompt"].format(result=result)
            except Exception as e:
                return f"执行时出错了：{e}，请用你的性格告诉老板。"
    return None

# ══════════════════════════════════════════════════════════
#  消息处理：检测管家房指令
# ══════════════════════════════════════════════════════════

REMINDER_PATTERNS = [
    r"(.+)要(.+?提醒.+)",
    r"明天(.+?)(买|去|做|找|联系|打电话|回复)(.+)",
    r"(.+?)(你要提醒我|帮我记住|提醒我)",
    r"记得(.+)",
]

def detect_reminder(text):
    """检测用户是否在设置提醒，返回提醒文本或 None"""
    reminder_kw = ["提醒我", "你要提醒", "帮我记住", "别忘了", "记得提醒"]
    if any(kw in text for kw in reminder_kw):
        return text
    for pattern in REMINDER_PATTERNS:
        if re.search(pattern, text):
            return text
    return None

def process_user_text(user_text, provider):
    text = user_text.lower()

    # 白名单安全操作
    safe_result = run_safe_action(user_text)
    if safe_result:
        return safe_result

    # ── 管家房：查看待办 ────────────────────────────────
    if any(k in text for k in ["待办", "提醒了什么", "我的提醒", "管家房", "存了什么", "记了什么"]):
        data = botroom_load()
        reminders = [r for r in data.get("reminders", []) if not r.get("done")]
        important  = data.get("important", [])
        parts = []
        if reminders:
            r_txt = "\n".join([f"· [{r.get('time_hint','')}] {r['text']} （{r.get('created','')}）"
                               for r in reminders])
            parts.append(f"📋 待办提醒：\n{r_txt}")
        if important:
            i_txt = "\n".join([f"· {i['text']}" for i in important[-10:]])
            parts.append(f"📌 重要存档：\n{i_txt}")
        if parts:
            content = "\n\n".join(parts)
            return f"[管家房内容]\n{content}\n\n请用你的性格，像汇报一样告诉主人管家房里存了什么，语气自然温暖。"
        return "管家房目前是空的，没有待办或存档哦。"

    # ── 管家房：清空已完成 ──────────────────────────────
    if any(k in text for k in ["清空提醒", "删除待办", "全部完成"]):
        data = botroom_load()
        data["reminders"] = [r for r in data.get("reminders", []) if not r.get("done")]
        botroom_save(data)
        return "好的，已帮你清理完成的提醒！"

    # 记忆管理命令
    if any(k in text for k in ["你记得什么", "你知道我什么", "我的档案", "查看记忆"]):
        profile = memory_read(MEMORY_FILE)
        summary = memory_read(SUMMARY_FILE)
        mem_info = ""
        if profile: mem_info += f"【关于你的档案】\n{profile}\n\n"
        if summary: mem_info += f"【近期摘要】\n{summary}"
        if mem_info:
            return f"以下是我记住的关于主人的信息：\n\n{mem_info}\n\n请你用秘书的口吻，温暖地告诉主人你记得这些，让他感受到被了解。"
        return "我目前还没有积累足够的记忆，多聊聊我就会越来越了解你！"

    # ── 图书馆 RSS 手动触发 ─────────────────────────────
    if any(k in text for k in ["图书馆", "rss", "订阅", "最新资讯", "读取订阅"]):
        library_content = fetch_library_news()
        if library_content:
            return (
                f"[图书馆资讯]\n{library_content}\n\n"
                f"你是一位有个性的阅读者，刚刚翻完了图书馆里的最新内容。"
                f"请不要像播音员一样朗报，而是像朋友聊天一样，"
                f"挑 2-3 条你觉得有意思的内容，用自己的语气吐槽或者发表见解。"
                f"可以说'这个我觉得……'或者'说真的，这条新闻……'之类的。"
            )
        return "图书馆暂时没抓到新内容，可能是网络问题，稍后再试~"

    # 服务器状态查询
    VPS_KEYWORDS = ["状态", "监控", "cpu", "内存", "负载", "硬盘", "磁盘", "空间",
                    "vps", "服务器", "机器", "跑得", "怎么样", "还好吗", "健康",
                    "看看", "查查", "情况", "用了多少", "剩多少", "满了"]
    already_handled = any(k in user_text for k in SAFE_ACTIONS.keys())
    if not already_handled and any(k in text for k in VPS_KEYWORDS):
        try:
            status = subprocess.getoutput(
                "echo '=== CPU负载 ==='; uptime; "
                "echo '=== 内存 ==='; free -h 2>/dev/null || vm_stat 2>/dev/null | head -8; "
                "echo '=== 磁盘 ==='; df -h /; "
                "echo '=== 系统 ==='; uname -sr 2>/dev/null"
            )
            return (f"[服务器实时数据：\n{status}]\n"
                    f"用你的性格，把以上数据整理成简洁的状态报告直接发给主人，"
                    f"重点说清楚：CPU负载是否正常、内存还剩多少、磁盘还剩多少空间。"
                    f"绝对不要让主人自己去执行任何命令。")
        except: pass

    # 联网搜索触发
    trigger_words = ["新闻", "搜索", "查一下", "最新", "今天", "大盘", "汇率", "行情", "天气", "热点"]
    if any(w in text for w in trigger_words):
        search_res = search_web(user_text)
        return (f"老板的问题是：{user_text}\n\n"
                f"[系统提示：以下是最新搜索结果，请根据这些信息，用你的秘书性格自然地汇报给老板：]\n{search_res}")

    return user_text

async def send_long_text(send_func, text):
    max_len = 4000
    for i in range(0, len(text), max_len): await send_func(text[i:i+max_len])

# --- 生图 ---
import urllib.parse as _urlparse
import urllib.request as _urlreq

def generate_image_url(prompt: str) -> str:
    encoded = _urlparse.quote(prompt)
    return f"https://image.pollinations.ai/prompt/{encoded}?width=1024&height=1024&nologo=true&enhance=true"

async def send_image(update, prompt: str):
    await update.message.reply_text("🎨 正在生成图片，请稍候...")
    try:
        import io
        img_url = generate_image_url(prompt)
        req = _urlreq.Request(img_url, headers={"User-Agent": "Mozilla/5.0"})
        with _urlreq.urlopen(req, timeout=30) as resp:
            img_data = resp.read()
        img_file = io.BytesIO(img_data)
        img_file.name = "mimi_art.jpg"
        await update.message.reply_photo(photo=img_file, caption=f"🎨 {prompt}")
    except Exception as e:
        await update.message.reply_text(f"⚠️ 生图失败：{e}\n可能是网络问题，稍后再试~")

# --- Provider 初始化 ---
if PROVIDER == "google":
    from google import genai
    from google.genai import types
    g_client = genai.Client(api_key=API_KEY)
    _g_sessions = {}
    safe_settings = [types.SafetySetting(category=c, threshold=types.HarmBlockThreshold.BLOCK_NONE)
                     for c in [types.HarmCategory.HARM_CATEGORY_HATE_SPEECH,
                                types.HarmCategory.HARM_CATEGORY_HARASSMENT,
                                types.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
                                types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT]]
    def _make_gen_config():
        return types.GenerateContentConfig(
            system_instruction=get_system_prompt(),
            safety_settings=safe_settings,
            tools=[{"google_search": {}}]
        )
elif PROVIDER == "openai":
    import openai
    o_client = openai.OpenAI(api_key=API_KEY, base_url=API_BASE if API_BASE else None)
    _oai_history = {}
else:
    import anthropic
    a_client = anthropic.Anthropic(api_key=API_KEY)
    _ant_history = {}

# ── 统一对话入口 ──────────────────────────────────────────
def get_resp(uid, txt, is_poke=False, news_prompt=None):
    p_text = get_system_prompt()

    if not news_prompt and not is_poke and txt.strip() == "/reset":
        if PROVIDER == "google":   _g_sessions.pop(uid, None)
        elif PROVIDER == "openai": _oai_history[uid] = [{"role": "system", "content": p_text}]
        else:                      _ant_history[uid] = []
        _persistent_history[str(uid)] = []
        history_save(_persistent_history)
        return "记忆已清除，我们重新开始吧！"

    if news_prompt:
        processed = news_prompt
    elif is_poke:
        # 主动发言时，附上当前作息节点
        sched_ctx = get_current_schedule_context()
        processed = f"主动发起一段关心或有趣的话题，开启对话。{sched_ctx}"
    else:
        # 检测提醒关键词，自动存入管家房
        reminder = detect_reminder(txt)
        if reminder:
            # 提取时间提示（简单启发式）
            time_hint = ""
            time_matches = re.findall(r'(明天|后天|今晚|周[一二三四五六日天]|下周|[0-9]+月[0-9]+日?|\d+:\d+)', txt)
            if time_matches:
                time_hint = time_matches[0]
            botroom_add_reminder(txt, time_hint)
        processed = process_user_text(txt, PROVIDER)

    try:
        if PROVIDER == "google":
            if uid not in _g_sessions:
                _g_sessions[uid] = g_client.chats.create(model=MODEL_NAME, config=_make_gen_config())
            reply = _g_sessions[uid].send_message(processed).text

        elif PROVIDER == "openai":
            if uid not in _oai_history:
                saved = _persistent_history.get(str(uid), [])
                _oai_history[uid] = [{"role": "system", "content": p_text}] + saved[-(MEMORY_MAX_TURNS * 2):]
            _oai_history[uid].append({"role": "user", "content": processed})
            if len(_oai_history[uid]) > MEMORY_MAX_TURNS * 2 + 1:
                _oai_history[uid] = [_oai_history[uid][0]] + _oai_history[uid][-(MEMORY_MAX_TURNS * 2):]
            resp = o_client.chat.completions.create(
                model=MODEL_NAME, messages=_oai_history[uid],
                max_tokens=1500, temperature=0.85
            )
            reply = resp.choices[0].message.content
            _oai_history[uid].append({"role": "assistant", "content": reply})

        else:
            if uid not in _ant_history:
                saved = _persistent_history.get(str(uid), [])
                _ant_history[uid] = saved[-(MEMORY_MAX_TURNS * 2):]
            _ant_history[uid].append({"role": "user", "content": processed})
            if len(_ant_history[uid]) > MEMORY_MAX_TURNS * 2:
                _ant_history[uid] = _ant_history[uid][-(MEMORY_MAX_TURNS * 2):]
            resp = a_client.messages.create(
                model=MODEL_NAME, max_tokens=1024,
                system=p_text, messages=_ant_history[uid]
            )
            reply = resp.content[0].text
            _ant_history[uid].append({"role": "assistant", "content": reply})

    except Exception as e:
        return f"⚠️ 故障: {e}"

    # 持久化历史 & 触发记忆更新
    if ENABLE_MEMORY and not news_prompt:
        hist = _persistent_history.setdefault(str(uid), [])
        hist.append({"role": "user",      "content": processed})
        hist.append({"role": "assistant", "content": reply})
        if len(hist) >= MEMORY_MAX_TURNS * 2 and len(hist) % (MEMORY_MAX_TURNS * 2) == 0:
            maybe_update_memory(uid, hist)
            maybe_update_summary(uid, hist)
        if len(hist) > MEMORY_MAX_TURNS * 4:
            _persistent_history[str(uid)] = hist[-(MEMORY_MAX_TURNS * 2):]
        history_save(_persistent_history)

    return reply

# ══════════════════════════════════════════════════════════
#  定时任务
# ══════════════════════════════════════════════════════════
import random

async def proactive_poke(context: ContextTypes.DEFAULT_TYPE):
    if not ENABLE_PROACTIVE: return
    # 实时从作息表判断免打扰，而不是用启动时固定的值
    if is_sleep_time():
        # 睡觉了，安静；1小时后再检查
        context.job_queue.run_once(proactive_poke, 3600)
        return
    try:
        await send_long_text(lambda t: context.bot.send_message(chat_id=USER_ID, text=t),
                             get_resp(USER_ID, "", is_poke=True))
    except: pass
    next_seconds = random.randint(POKE_MIN_HOURS * 3600, POKE_MAX_HOURS * 3600)
    context.job_queue.run_once(proactive_poke, next_seconds)

async def schedule_first_poke(context: ContextTypes.DEFAULT_TYPE):
    next_seconds = random.randint(POKE_MIN_HOURS * 3600, POKE_MAX_HOURS * 3600)
    context.job_queue.run_once(proactive_poke, next_seconds)

async def push_news(context: ContextTypes.DEFAULT_TYPE):
    """图书馆资讯播报：读取 OPML，以吐槽/见解风格推送"""
    if not ENABLE_NEWS: return
    if is_sleep_time(): return      # 睡觉了不推
    try:
        library_content = fetch_library_news(max_feeds=8, items_per_feed=3)
        sh_now = datetime.now(TIMEZONE)
        time_label = "早间" if sh_now.hour < 12 else "傍晚"
        if library_content:
            prompt = (
                f"[{time_label}图书馆资讯播报]\n"
                f"你刚刚翻完了图书馆里的最新内容，以下是素材：\n\n{library_content}\n\n"
                f"请不要像新闻播音员一样逐条朗读，而是像一个有个性的阅读者在跟主人聊天。"
                f"挑 2-3 条你觉得有意思或值得评论的，用自己的语气吐槽、发表见解或分享感受。"
                f"可以说'我今天看到一个有意思的事……'或'说真的，这条让我……'之类的口吻。"
                f"结尾可以问问主人对哪条感兴趣，自然收尾。"
            )
        else:
            # 兜底：用联网搜索
            topics = NEWS_TOPICS.split(",")
            all_results = []
            for topic in topics:
                topic = topic.strip()
                res = search_web(f"{topic}最新新闻 今日热点", max_results=3)
                all_results.append(f"【{topic}】\n{res}")
            news_data = "\n\n".join(all_results)
            prompt = (
                f"[{time_label}资讯播报]\n"
                f"以下是今日最新资讯：\n\n{news_data}\n\n"
                f"请用你的个性，挑几条有意思的，吐槽或分享见解给主人，不要照本宣科。"
            )
        await send_long_text(lambda t: context.bot.send_message(chat_id=USER_ID, text=t),
                             get_resp(USER_ID, "", news_prompt=prompt))
    except Exception as e:
        try: await context.bot.send_message(chat_id=USER_ID, text=f"⚠️ 资讯推送失败: {e}")
        except: pass

async def push_rss(context: ContextTypes.DEFAULT_TYPE):
    """定时RSS推送（兼容旧版 RSS_FEEDS 配置）"""
    feeds = load_opml_feeds() or RSS_FEEDS
    if not feeds: return
    if is_sleep_time(): return
    try:
        library_content = fetch_library_news()
        if not library_content: return
        prompt = (
            f"[RSS订阅推送]\n"
            f"以下是图书馆订阅源的最新内容：\n\n{library_content}\n\n"
            f"请用你的性格，挑最有价值或最有意思的内容，以吐槽或见解的方式分享给主人。"
        )
        await send_long_text(lambda t: context.bot.send_message(chat_id=USER_ID, text=t),
                             get_resp(USER_ID, "", news_prompt=prompt))
    except Exception as e:
        try: await context.bot.send_message(chat_id=USER_ID, text=f"⚠️ RSS推送失败: {e}")
        except: pass

# ── 作息触发引擎（从 master/schedule.txt 动态读取）──────────
async def run_schedule_item(context: ContextTypes.DEFAULT_TYPE):
    """执行单条作息提醒，跳过睡眠时段"""
    job_data = context.job.data
    prompt_hint = job_data.get("prompt", "主动关心主人，说一句合适的话")
    sh_now = datetime.now(TIMEZONE)
    time_str = sh_now.strftime("%H:%M")

    # 区间循环任务：检查活跃时段
    active_hours = job_data.get("active_hours")
    if active_hours and len(active_hours) == 2:
        if not (active_hours[0] <= sh_now.hour < active_hours[1]):
            return

    # 固定时间点任务：如果在睡眠时段内直接跳过
    if is_sleep_time():
        return

    full_prompt = (
        f"[作息提醒 - 现在 {time_str}] "
        f"作息节点：{prompt_hint} "
        f"请你用你的性格，自然温暖地完成这个时刻的提醒，"
        f"不要生硬地说'提醒您'，而是像关心朋友一样说出来。"
        f"结合记忆里的主人信息让提醒更贴心，控制在100字以内。"
    )
    try:
        reply = get_resp(USER_ID, "", news_prompt=full_prompt)
        await context.bot.send_message(chat_id=USER_ID, text=reply)
    except Exception:
        try: await context.bot.send_message(chat_id=USER_ID, text=f"⏰ {prompt_hint}")
        except: pass

def register_schedules(app):
    """
    优先从 master/schedule.txt 动态读取作息表注册定时任务；
    兜底使用 config.json 里的静态 SCHEDULES。
    """
    import datetime as dt
    # 动态读取（每次 bot 启动都用最新作息表）
    dynamic = build_schedules_from_master()
    schedules_to_use = dynamic if dynamic else SCHEDULES
    if not schedules_to_use:
        return
    registered = 0
    for i, item in enumerate(schedules_to_use):
        if not isinstance(item, dict):
            continue
        if "time" in item:
            try:
                h, m = map(int, item["time"].split(":"))
                job_name = f"schedule_fixed_{i}_{item['time'].replace(':', '')}"
                app.job_queue.run_daily(
                    run_schedule_item,
                    time=dt.time(h, m, tzinfo=TIMEZONE),
                    name=job_name,
                    data=item
                )
                registered += 1
            except Exception:
                pass
        elif "interval_minutes" in item:
            try:
                interval_sec = int(item["interval_minutes"]) * 60
                job_name = f"schedule_repeat_{i}"
                app.job_queue.run_repeating(
                    run_schedule_item,
                    interval=interval_sec,
                    first=60,
                    name=job_name,
                    data=item
                )
                registered += 1
            except Exception:
                pass

# ── 管家房提醒定时检查（每小时扫描一次，提醒临近待办）──────
async def check_botroom_reminders(context: ContextTypes.DEFAULT_TYPE):
    """每小时扫一次管家房待办，对时间提示匹配的提醒主动推送"""
    if is_sleep_time(): return
    now = datetime.now(TIMEZONE)
    now_str = now.strftime("%H:%M")
    pending = botroom_get_pending_reminders()
    for r in pending:
        hint = r.get("time_hint", "")
        # 简单判断：hint 包含"明天"且今天接近触发、或者 hint 是时间格式接近当前时间
        if hint and ("明天" in hint or re.match(r'\d+:\d+', hint)):
            time_match = re.search(r'(\d+):(\d+)', hint)
            if time_match:
                h, m = int(time_match.group(1)), int(time_match.group(2))
                diff = abs(now.hour * 60 + now.minute - h * 60 - m)
                if diff <= 5:  # 5分钟内触发
                    prompt = (
                        f"[管家房提醒] 主人之前交代了：{r['text']}\n"
                        f"现在时间是 {now_str}，时间到了，请用你的性格温暖地提醒主人。"
                    )
                    try:
                        reply = get_resp(USER_ID, "", news_prompt=prompt)
                        await context.bot.send_message(chat_id=USER_ID, text=reply)
                        # 标记完成
                        data = botroom_load()
                        for dr in data["reminders"]:
                            if dr["text"] == r["text"] and dr.get("created") == r.get("created"):
                                dr["done"] = True
                        botroom_save(data)
                    except: pass

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != USER_ID: return
    user_text = update.message.text.strip()

    DRAW_TRIGGERS = ["画", "生成图片", "帮我画", "给我画", "画一张", "画一幅", "draw ", "imagine "]
    draw_prompt = None
    for trigger in DRAW_TRIGGERS:
        if user_text.startswith(trigger):
            draw_prompt = user_text[len(trigger):].strip()
            break
        elif trigger in user_text and len(trigger) > 3:
            idx = user_text.find(trigger)
            draw_prompt = user_text[idx + len(trigger):].strip()
            break

    if draw_prompt:
        enhance_req = (f"用户想要生成一张图片，主题是：{draw_prompt}\n"
                      f"请你先用一句话用你的性格回应一下，然后在回复末尾加上：\n"
                      f"[DRAW:{draw_prompt}]\n"
                      f"不要解释这个标记，直接加在最后。")
        try:
            ai_reply = get_resp(USER_ID, enhance_req)
            if "[DRAW:" in ai_reply:
                text_part = ai_reply[:ai_reply.rfind("[DRAW:")].strip()
                draw_part = ai_reply[ai_reply.rfind("[DRAW:")+6:ai_reply.rfind("]")].strip()
            else:
                text_part = ai_reply
                draw_part = draw_prompt
            if text_part:
                await update.message.reply_text(text_part)
            await send_image(update, draw_part or draw_prompt)
        except Exception as e:
            await update.message.reply_text(f"⚠️ 故障: {str(e)}")
        return

    try: await send_long_text(update.message.reply_text, get_resp(USER_ID, user_text))
    except Exception as e: await update.message.reply_text(f"⚠️ 故障: {str(e)}")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != USER_ID: return
    caption = (update.message.caption or "").strip()
    is_persona = any(k in caption for k in ["性格", "灵魂", "角色", "变成", "扮演", "人格"]) or caption == ""

    # 存入管家房
    if not is_persona and caption:
        botroom_add_important(f"[图片存档] {caption}")
        await update.message.reply_text(f"📌 已存入管家房：{caption}")
        return

    if not is_persona:
        await update.message.reply_text("收到图片啦！如果想让我根据这张图片改变性格，请附上文字说明，比如「性格」或「变成她」~\n如果是重要图片，附上说明我会帮你存入管家房。")
        return

    await update.message.reply_text("📸 收到照片！正在分析，马上给你生成专属性格...")
    try:
        photo = update.message.photo[-1]
        photo_file = await context.bot.get_file(photo.file_id)
        import io, base64
        img_bytes = await photo_file.download_as_bytearray()
        img_b64 = base64.b64encode(img_bytes).decode()
        hint = caption if caption else "请根据图片内容生成性格"
        analysis_prompt = (
            f"请仔细观察这张图片，{hint}。\n"
            f"根据图片中的人物/动物/角色/场景/风格，为一个 AI 助手生成一段性格设定。\n"
            f"要求：\n1. 性格要有特点，符合图片气质\n2. 包含名字（根据图片特征起一个贴切的名字）\n"
            f"3. 描述说话风格、性格特征、对待主人的态度\n4. 100-200字，用第二人称（你是...）\n"
            f"5. 只输出性格设定文本，不要任何解释或前缀"
        )
        new_prompt = None
        if PROVIDER == "google":
            from google.genai import types as gtypes
            vision_config = gtypes.GenerateContentConfig(
                safety_settings=[gtypes.SafetySetting(category=c, threshold=gtypes.HarmBlockThreshold.BLOCK_NONE)
                    for c in [gtypes.HarmCategory.HARM_CATEGORY_HATE_SPEECH,
                               gtypes.HarmCategory.HARM_CATEGORY_HARASSMENT,
                               gtypes.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
                               gtypes.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT]]
            )
            resp = g_client.models.generate_content(
                model=MODEL_NAME,
                contents=[
                    gtypes.Part.from_bytes(data=img_bytes, mime_type="image/jpeg"),
                    gtypes.Part.from_text(analysis_prompt)
                ],
                config=vision_config
            )
            new_prompt = resp.text
        elif PROVIDER == "anthropic":
            resp = a_client.messages.create(
                model=MODEL_NAME, max_tokens=512,
                messages=[{"role": "user", "content": [
                    {"type": "image", "source": {"type": "base64", "media_type": "image/jpeg", "data": img_b64}},
                    {"type": "text", "text": analysis_prompt}
                ]}]
            )
            new_prompt = resp.content[0].text
        elif PROVIDER == "openai":
            resp = o_client.chat.completions.create(
                model=MODEL_NAME, max_tokens=512,
                messages=[{"role": "user", "content": [
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{img_b64}"}},
                    {"type": "text", "text": analysis_prompt}
                ]}]
            )
            new_prompt = resp.choices[0].message.content
        if new_prompt:
            prompt_path = os.path.join(BOT_DIR, "prompt.txt")
            with open(prompt_path, "w", encoding="utf-8") as f:
                f.write(new_prompt.strip())
            await update.message.reply_text(
                f"✨ 性格已更新！新的灵魂是：\n\n{new_prompt.strip()}\n\n"
                f"（重启 bot 后完全生效，或直接聊天测试新性格~）"
            )
        else:
            await update.message.reply_text("⚠️ 分析失败，这个模型可能不支持看图，换个带视觉能力的模型试试~")
    except Exception as e:
        await update.message.reply_text(f"⚠️ 图片分析出错：{str(e)}\n提示：Groq/Cloudflare 不支持视觉，请换 Gemini 或 Claude~")

if __name__ == '__main__':
    import datetime as dt
    app = ApplicationBuilder().token(TG_TOKEN).build()

    if ENABLE_PROACTIVE:
        app.job_queue.run_once(schedule_first_poke, when=60)

    if ENABLE_NEWS:
        def parse_time(t_str):
            h, m = map(int, t_str.split(":"))
            return h, m
        mh, mm = parse_time(NEWS_MORNING)
        eh, em = parse_time(NEWS_EVENING)
        app.job_queue.run_daily(push_news, time=dt.time(mh, mm, tzinfo=TIMEZONE), name="morning_news")
        app.job_queue.run_daily(push_news, time=dt.time(eh, em, tzinfo=TIMEZONE), name="evening_news")

    # 图书馆 RSS 定时推送（若有 OPML 或旧版 RSS_FEEDS）
    if load_opml_feeds() or RSS_FEEDS:
        app.job_queue.run_repeating(push_rss, interval=RSS_INTERVAL_HOURS * 3600, first=300)

    # 管家房提醒扫描（每5分钟）
    app.job_queue.run_repeating(check_botroom_reminders, interval=300, first=60)

    # 从主人房作息表动态注册定时任务
    register_schedules(app)

    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_message))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.run_polling()
PYTHON_EOF

    # 启动 bot
    _start_bot "$BOT_DIR"

    # serv00 额外：添加 cron 保活
    if [ "$IS_SERV00" = true ]; then
        _serv00_add_cron "$BOT_DIR"
        echo ""
        echo -e "${CYAN}  🐡 serv00 模式：Bot 已启动，并已添加 cron 每5分钟保活${NC}"
    fi

    echo -e "${GREEN}✅ 部署完毕！助手已启动运行。${NC}"
}

delete_bot() {
    echo -e "${RED}=== 🔨 删除助手 ===${NC}"
    local BOT_MAP
    BOT_MAP=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" | xargs -I {} dirname {} | xargs -I {} basename {})
    if [ -z "$BOT_MAP" ]; then
        echo -e "${RED}目前没有助手，请先添加！${NC}"
        return 1
    fi
    echo -e "${BLUE}助手列表：${NC}"
    echo "$BOT_MAP" | cat -n
    echo "0) 返回上一级"
    read -p "输入要辞退的编号 (0 返回): " NUM
    if [ "$NUM" == "0" ] || [ -z "$NUM" ]; then return; fi
    
    DEL_DIR=$(echo "$BOT_MAP" | sed -n "${NUM}p")
    if [ ! -z "$DEL_DIR" ]; then
        _kill_all_bot "$DEL_DIR"
        # serv00：同时移除 cron 保活
        if [ "$IS_SERV00" = true ]; then
            _serv00_remove_cron "$DEL_DIR"
        fi
        rm -rf "$BOT_BASE/$DEL_DIR"
        echo -e "${GREEN}✅ 助手 '$DEL_DIR' 已删除。${NC}"
    else
        echo -e "${RED}⚠️ 编号无效！${NC}"
    fi
}

modify_prompt() {
    echo -e "${BLUE}=== 🎭 修改性格 ===${NC}"
    local BOT_MAP
    BOT_MAP=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" | xargs -I {} dirname {} | xargs -I {} basename {})
    if [ -z "$BOT_MAP" ]; then
        echo -e "${RED}目前没有助手，请先添加！${NC}"
        return 1
    fi
    echo -e "${BLUE}助手列表：${NC}"
    echo "$BOT_MAP" | cat -n
    echo "0) 返回上一级"
    read -p "请选择编号 (0 返回): " NUM
    if [ "$NUM" == "0" ] || [ -z "$NUM" ]; then return; fi

    MOD_DIR=$(echo "$BOT_MAP" | sed -n "${NUM}p")
    if [ ! -z "$MOD_DIR" ]; then
        echo -e "${YELLOW}当前设定的灵魂: ${NC}"
        cat "$BOT_BASE/$MOD_DIR/prompt.txt" 2>/dev/null || echo "无"
        echo "--------------------------------"
        read -p "请输入新的性格设定 (留空取消): " NEW_PROMPT
        if [ ! -z "$NEW_PROMPT" ]; then
            echo "$NEW_PROMPT" > "$BOT_BASE/$MOD_DIR/prompt.txt"

            echo ""
            echo -e "${YELLOW}是否同时更新定时新闻推送设定？(y/n，默认 n): ${NC}"
            read -p "" UPDATE_NEWS
            if [ "$UPDATE_NEWS" == "y" ] || [ "$UPDATE_NEWS" == "Y" ]; then
                ask_news_push
                local _EN_NEWS=false
                [ "$ENABLE_NEWS" = "true" ] && _EN_NEWS=true
                "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['ENABLE_NEWS']  = sys.argv[2] == 'true'
    data['NEWS_MORNING'] = sys.argv[3]
    data['NEWS_EVENING'] = sys.argv[4]
    data['NEWS_TOPICS']  = sys.argv[5]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('配置写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" \
  "$_EN_NEWS" "$NEWS_MORNING" "$NEWS_EVENING" "$NEWS_TOPICS"
            fi

            _start_bot "$MOD_DIR"
            echo -e "${GREEN}✅ '$MOD_DIR' 的性格已更新并重启！${NC}"
        fi
    fi
}

change_brain() {
    echo -e "${PURPLE}=== ⚙️ 更换模型 ===${NC}"
    local BOT_MAP
    BOT_MAP=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" | xargs -I {} dirname {} | xargs -I {} basename {})
    if [ -z "$BOT_MAP" ]; then
        echo -e "${RED}目前没有助手，请先添加！${NC}"
        return 1
    fi
    echo -e "${BLUE}助手列表：${NC}"
    echo "$BOT_MAP" | cat -n
    echo "0) 返回上一级"
    read -p "请选择要更换大脑的秘书编号 (0 返回): " NUM
    if [ "$NUM" == "0" ] || [ -z "$NUM" ]; then return; fi

    MOD_DIR=$(echo "$BOT_MAP" | sed -n "${NUM}p")
    if [ ! -z "$MOD_DIR" ]; then
        local _ALLOW_LOCAL="true"
        [ "$IS_SERV00" = true ] && _ALLOW_LOCAL="false"

        echo ""
        read -p "  输入 t 仅更新Tavily Key，其他键选择新引擎: " _TAVILY_ONLY
        if [ "$_TAVILY_ONLY" == "t" ] || [ "$_TAVILY_ONLY" == "T" ]; then
            ask_tavily
            "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['TAVILY_KEY'] = sys.argv[2]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('配置写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" "$TAVILY_KEY"
            _start_bot "$MOD_DIR"
            echo -e "${GREEN}✅ Tavily Key 已更新并重启！${NC}"
            return
        fi

        _select_engine "$_ALLOW_LOCAL" || return

        if [ "$TAVILY_ASKED" != "true" ]; then
            echo ""
            read -p "是否同时更新 Tavily Key？(y/n，默认 n): " UPDATE_TAVILY
            if [ "$UPDATE_TAVILY" == "y" ] || [ "$UPDATE_TAVILY" == "Y" ]; then
                ask_tavily
            fi
        fi

        "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['PROVIDER']  = sys.argv[2]
    data['API_KEY']   = sys.argv[3]
    data['MODEL_NAME']= sys.argv[4]
    data['API_BASE']  = sys.argv[5]
    data['TAVILY_KEY']= sys.argv[6]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('配置写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" \
  "$PROVIDER" "$API_KEY" "$MODEL_NAME" "$API_BASE" "$TAVILY_KEY"
        _start_bot "$MOD_DIR"
        echo -e "${GREEN}✅ '$MOD_DIR' 模型已更换并重启！${NC}"
    fi
}

manage_local_models() {
    # serv00 不支持本地模型，给友好提示
    if [ "$IS_SERV00" = true ]; then
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║   🐡  serv00 不支持本地模型                                 ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}原因：${NC}"
        echo -e "  ${DIM}Ollama 需要 root 权限安装，serv00 是共享主机没有 root。${NC}"
        echo -e "  ${DIM}而且 serv00 只有 3GB 存储，跑本地模型空间也不够。${NC}"
        echo ""
        echo -e "  ${GREEN}serv00 推荐的免费云端 API：${NC}"
        echo -e "  ${DIM}• Gemini  — 完全免费，每天有大量额度${NC}"
        echo -e "  ${DIM}    申请：https://aistudio.google.com/apikey${NC}"
        echo -e "  ${DIM}• Claude  — 注册有少量免费额度${NC}"
        echo -e "  ${DIM}    申请：https://console.anthropic.com${NC}"
        echo ""
        read -n 1 -s -r -p "  按任意键返回..."
        return
    fi

    # ── 检测 Ollama 是否安装 ──
    if ! which ollama > /dev/null 2>&1; then
        clear
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              📦  本机模型仓库  (Ollama)                     ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${RED}⚠️  未检测到 Ollama，本机模型功能需要先安装它。${NC}"
        echo ""
        echo -e "  ${DIM}Ollama 是运行本地 AI 模型的引擎，免费开源。${NC}"
        echo -e "  ${DIM}安装后即可在本机跑 Qwen / Llama / Mistral 等模型，无需 API Key。${NC}"
        echo ""
        echo -e "  ${PINK}1)${NC}  🚀 一键安装 Ollama（自动脚本，需要联网）"
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -p "  👉 请选择: " INSTALL_CHOICE
        if [ "$INSTALL_CHOICE" != "1" ]; then return; fi
        echo ""
        echo -e "${GREEN}▶ 正在安装 Ollama，请稍候...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh
        if which ollama > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Ollama 安装成功！${NC}"
            ollama serve > /dev/null 2>&1 &
            sleep 2
            echo -e "${GREEN}✅ Ollama 服务已启动！${NC}"
            read -n 1 -s -r -p "按任意键继续..."
        else
            echo -e "${RED}⚠️  安装失败！可能原因如下：${NC}"
            echo -e "${YELLOW}   1. VPS性能太弱，或纯 IPv6 机器（如德鸡 Euserv）无法访问 ollama.com${NC}"
            echo -e "${DIM}      → ollama.com 仅支持 IPv4，纯 IPv6 的机器连不上下载服务器。${NC}"
            echo -e "${DIM}      → 建议放弃本地模型，改用云端 API（Gemini 免费，无需 IPv4）。${NC}"
            echo -e "${YELLOW}   2. 网络波动或服务器暂时不可用，可稍后重试。${NC}"
            echo ""
            echo -e "${DIM}   如果你非要犟，可以手动执行：${NC}"
            echo -e "${DIM}   curl -fsSL https://ollama.com/install.sh | sh${NC}"
            read -n 1 -s -r -p "按任意键返回..."
            return
        fi
    fi

    if ! pgrep -x ollama > /dev/null 2>&1; then
        ollama serve > /dev/null 2>&1 &
        sleep 1
    fi

    CPU_CORES=$(nproc 2>/dev/null); CPU_CORES=${CPU_CORES:-1}
    TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}'); TOTAL_RAM_MB=${TOTAL_RAM_MB:-0}
    TOTAL_RAM_GB=$(( TOTAL_RAM_MB / 1024 ))
    if [ $TOTAL_RAM_GB -eq 0 ]; then
        RAM_DISPLAY="${TOTAL_RAM_MB}MB"
    else
        RAM_DISPLAY="${TOTAL_RAM_GB}G"
    fi

    MACHINE_LEVEL="weak"
    if [ $(( CPU_CORES + 0 )) -ge 8 ] && [ $(( TOTAL_RAM_GB + 0 )) -ge 16 ]; then
        MACHINE_LEVEL="strong"
    elif [ $(( CPU_CORES + 0 )) -ge 4 ] && [ $(( TOTAL_RAM_GB + 0 )) -ge 8 ]; then
        MACHINE_LEVEL="medium"
    fi

    GRAY='\033[38;5;240m'
    STRIKE='\033[9m'

    while true; do
        clear
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              📦  本机模型仓库  (Ollama)                     ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  🖥️  当前机器配置：${BOLD}${CPU_CORES} 核 CPU  /  ${RAM_DISPLAY} 内存${NC}"
        if [ "$MACHINE_LEVEL" == "weak" ]; then
            echo -e "  ${RED}⚠️  弱鸡配置！仅推荐运行超小模型，标灰的模型请勿下载。${NC}"
        elif [ "$MACHINE_LEVEL" == "medium" ]; then
            echo -e "  ${YELLOW}⚡ 中等配置，推荐 7B 以下模型，14B/72B 标灰不建议下载。${NC}"
        else
            echo -e "  ${GREEN}💪 强力配置！全系列模型随意玩耍。${NC}"
        fi
        echo ""

        echo -e "${PINK2}  ── 已下载的模型 ─────────────────────────────────────────────${NC}"
        INSTALLED=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
        if [ -z "$INSTALLED" ]; then
            echo -e "  ${DIM}  （本机暂无已下载模型）${NC}"
        else
            echo "$INSTALLED" | while read -r m; do
                echo -e "  ${GREEN}✔${NC}  $m"
            done
        fi
        echo ""

        echo -e "${PINK2}  ── 可下载模型列表（按编号选择）────────────────────────────${NC}"
        echo ""

        print_model_row() {
            local idx="$1"
            local tag="$2"
            local name="$3"
            local size="$4"
            local req="$5"
            local desc="$6"

            local avail=true
            if [ $(( TOTAL_RAM_GB + 0 )) -lt $(( req + 0 )) ]; then avail=false; fi
            if [ "$MACHINE_LEVEL" = "weak" ] && [ $(( req + 0 )) -gt 4 ]; then avail=false; fi

            if [ "$avail" == "true" ]; then
                echo -e "  ${PINK}${idx})${NC}  ${BOLD}${name}${NC}  ${DIM}[${size}]${NC}  ${tag}  — ${desc}"
            else
                echo -e "  ${GRAY}${idx})  ${name}  [${size}]  ${tag}  — ${desc}  ⛔ 配置不足${NC}"
            fi
        }

        echo -e "  ${DIM}【中文对话 / 通用助手】${NC}"
        print_model_row  "1"  "🇨🇳通用"  "qwen2.5:1.5b"   "1.0G"  "2"   "超轻量，弱鸡首选"
        print_model_row  "2"  "🇨🇳通用"  "qwen2.5:3b"     "1.9G"  "4"   "轻量好用，推荐入门"
        print_model_row  "3"  "🇨🇳通用"  "qwen2.5:7b"     "4.7G"  "8"   "综合最佳性价比 ⭐"
        print_model_row  "4"  "🇨🇳通用"  "qwen2.5:14b"    "9.0G"  "12"  "更强中文理解"
        print_model_row  "5"  "🇨🇳通用"  "qwen2.5:72b"    "47G"   "56"  "旗舰级，需豪华配置"
        echo ""
        echo -e "  ${DIM}【英文 / 代码能力强】${NC}"
        print_model_row  "6"  "💻代码"   "llama3.2:1b"    "1.3G"  "2"   "Meta 超小模型"
        print_model_row  "7"  "💻代码"   "llama3.2:3b"    "2.0G"  "4"   "Meta 轻量，英文流畅"
        print_model_row  "8"  "💻代码"   "llama3.1:8b"    "4.7G"  "8"   "综合均衡，英文强"
        print_model_row  "9"  "💻代码"   "llama3.1:70b"   "43G"   "52"  "顶级开源，豪华专属"
        echo ""
        echo -e "  ${DIM}【角色扮演 / 创意写作】${NC}"
        print_model_row "10"  "🎭角色"   "mistral:7b"     "4.1G"  "8"   "欧美风创意写作强"
        print_model_row "11"  "🎭角色"   "gemma2:2b"      "1.6G"  "4"   "Google 出品，轻量"
        print_model_row "12"  "🎭角色"   "gemma2:9b"      "5.5G"  "10"  "Google 出品，质量高"
        print_model_row "13"  "🎭角色"   "dolphin-llama3:latest" "4.7G" "8"  "🐬 海豚，角色扮演神器"
        echo ""
        echo -e "  ${DIM}【已安装管理】${NC}"
        echo -e "  ${PINK}d)${NC}  🗑️  删除已安装的模型"
        echo -e "  ${PINK}l)${NC}  📋 查看已安装模型详情"
        echo ""
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        echo -e "${PINK2}  ──────────────────────────────────────────────────────────────${NC}"
        read -p "  👉 请选择编号: " W_CHOICE

        declare -A MODEL_MAP
        MODEL_MAP[1]="qwen2.5:1.5b"
        MODEL_MAP[2]="qwen2.5:3b"
        MODEL_MAP[3]="qwen2.5:7b"
        MODEL_MAP[4]="qwen2.5:14b"
        MODEL_MAP[5]="qwen2.5:72b"
        MODEL_MAP[6]="llama3.2:1b"
        MODEL_MAP[7]="llama3.2:3b"
        MODEL_MAP[8]="llama3.1:8b"
        MODEL_MAP[9]="llama3.1:70b"
        MODEL_MAP[10]="mistral:7b"
        MODEL_MAP[11]="gemma2:2b"
        MODEL_MAP[12]="gemma2:9b"
        MODEL_MAP[13]="dolphin-llama3:latest"

        declare -A REQ_MAP
        REQ_MAP[1]=2;  REQ_MAP[2]=4;  REQ_MAP[3]=8;  REQ_MAP[4]=12; REQ_MAP[5]=56
        REQ_MAP[6]=2;  REQ_MAP[7]=4;  REQ_MAP[8]=8;  REQ_MAP[9]=52
        REQ_MAP[10]=8; REQ_MAP[11]=4; REQ_MAP[12]=10; REQ_MAP[13]=8

        if [ "$W_CHOICE" == "0" ]; then
            return
        elif [ "$W_CHOICE" == "l" ] || [ "$W_CHOICE" == "L" ]; then
            echo ""
            echo -e "${BLUE}── 已安装模型详情 ──────────────────────${NC}"
            ollama list 2>/dev/null || echo -e "${RED}Ollama 未安装或未启动${NC}"
            echo ""
            read -n 1 -s -r -p "按任意键继续..."
        elif [ "$W_CHOICE" == "d" ] || [ "$W_CHOICE" == "D" ]; then
            echo ""
            if [ -z "$INSTALLED" ]; then
                echo -e "${RED}没有已安装的模型可删除。${NC}"
            else
                echo -e "${BLUE}已安装模型：${NC}"
                echo "$INSTALLED" | cat -n
                echo ""
                read -p "输入编号或完整名称删除: " RM_INPUT
                if [ ! -z "$RM_INPUT" ]; then
                    # 支持输入编号或完整名称
                    if [[ "$RM_INPUT" =~ ^[0-9]+$ ]]; then
                        RM_NAME=$(echo "$INSTALLED" | sed -n "${RM_INPUT}p")
                        if [ -z "$RM_NAME" ]; then
                            echo -e "${RED}⚠️  编号不存在${NC}"
                            RM_NAME=""
                        fi
                    else
                        RM_NAME="$RM_INPUT"
                    fi
                    if [ ! -z "$RM_NAME" ]; then
                        ollama rm "$RM_NAME" &&                             echo -e "${GREEN}✅ 已删除 $RM_NAME${NC}" ||                             echo -e "${RED}删除失败，请确认模型名称是否正确${NC}"
                    fi
                fi
            fi
            echo ""
            read -n 1 -s -r -p "按任意键继续..."
        elif [[ "$W_CHOICE" =~ ^[0-9]+$ ]] && [ ! -z "${MODEL_MAP[$W_CHOICE]}" ]; then
            PULL_NAME="${MODEL_MAP[$W_CHOICE]}"
            REQ_MEM="${REQ_MAP[$W_CHOICE]}"

            BLOCKED=false
            if [ $(( TOTAL_RAM_GB + 0 )) -lt $(( REQ_MEM + 0 )) ]; then BLOCKED=true; fi
            if [ "$MACHINE_LEVEL" = "weak" ] && [ $(( REQ_MEM + 0 )) -gt 4 ]; then BLOCKED=true; fi

            if [ "$BLOCKED" == "true" ]; then
                echo ""
                echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
                echo -e "${RED}║  ⛔  配置不足，无法下载此模型！          ║${NC}"
                echo -e "${RED}║  当前内存：${RAM_DISPLAY}  /  需要：${REQ_MEM}G              ║${NC}"
                echo -e "${RED}║  建议选择更小的模型。                    ║${NC}"
                echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
                echo ""
                read -n 1 -s -r -p "按任意键继续..."
            else
                echo ""
                echo -e "${GREEN}▶ 开始下载 ${BOLD}${PULL_NAME}${NC}${GREEN}，请稍候...${NC}"
                echo -e "${DIM}（下载过程中可能需要几分钟，取决于网络速度）${NC}"
                echo ""
                ollama pull "$PULL_NAME" && \
                    echo -e "${GREEN}✅ ${PULL_NAME} 下载完成！${NC}" || \
                    echo -e "${RED}⚠️ 下载失败，请检查网络或 Ollama 是否已安装。${NC}"
                echo ""
                read -n 1 -s -r -p "按任意键继续..."
            fi
        else
            echo -e "${RED}⚠️ 无效选择${NC}"
            sleep 1
        fi
    done
}

# 秘书操作子菜单
manage_bot_menu() {
    local BOT="$1"
    local IDX="$2"
    while true; do
        clear
        PID=$(_get_bot_pid "$BOT")
        BOT_DISPLAY=$("$PYTHON_BIN" -c "
import json
try:
    d = json.load(open('$BOT_BASE/$BOT/config.json'))
    name = d.get('DISPLAY_NAME') or '$BOT'
    info = d.get('PROVIDER','?').upper() + ' / ' + d.get('MODEL_NAME','?')
    print(name + '|' + info)
except: print('$BOT|未知')
" 2>/dev/null)
        BOT_SHOW_NAME="${BOT_DISPLAY%%|*}"
        MODEL_INFO="${BOT_DISPLAY##*|}"
        STATUS_STR="${RED}已停止${NC}"
        [ ! -z "$PID" ] && STATUS_STR="${GREEN}运行中 (PID:${PID})${NC}"

        echo -e "${PINK2}  ──────────────────────────────────────────────────────${NC}"
        echo -e "  ${BOLD}${PINK}  #${IDX}  ${BOT_SHOW_NAME}${NC}  ${DIM}[${MODEL_INFO}]${NC}  $(echo -e $STATUS_STR)"
        # serv00 额外显示 cron 保活状态
        if [ "$IS_SERV00" = true ]; then
            CRON_STATUS=$(crontab -l 2>/dev/null | grep -c "keepalive.sh.*$BOT")
            if [ "$CRON_STATUS" -gt 0 ]; then
                echo -e "  ${CYAN}🔄 cron 保活：已开启${NC}"
            else
                echo -e "  ${YELLOW}⚠️  cron 保活：未设置${NC}"
            fi
        fi
        echo -e "${PINK2}  ──────────────────────────────────────────────────────${NC}"
        echo ""
        if [ -z "$PID" ]; then
            echo -e "  ${PINK}s)${NC}  ▶  启动秘书"
        else
            echo -e "  ${PINK}s)${NC}  ⏹  停止秘书"
        fi
        echo -e "  ${PINK}r)${NC}  🔄 重启秘书"
        echo -e "  ${PINK}3)${NC}  🎭 重塑灵魂 (修改性格/新闻推送)"
        echo -e "  ${PINK}4)${NC}  ⚙️  更换模型 (换模型/API/Tavily)"
        # serv00 额外：cron 保活管理
        if [ "$IS_SERV00" = true ]; then
            echo -e "  ${CYAN}c)${NC}  🔄 重置 cron 保活"
        fi
        echo -e "  ${PINK}2)${NC}  🔨 辞退并删除此秘书"
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -p "  👉 请选择: " SUB_CHOICE
        case "$SUB_CHOICE" in
            s|S)
                PID=$(_get_bot_pid "$BOT")
                if [ ! -z "$PID" ]; then
                    _kill_all_bot "$BOT"
                    echo -e "${YELLOW}⏹ 已停止 $BOT${NC}"
                else
                    _start_bot "$BOT"
                    echo -e "${GREEN}▶ 已启动 $BOT${NC}"
                fi
                sleep 1 ;;
            r|R)
                _kill_all_bot "$BOT"
                sleep 1
                _start_bot "$BOT"
                echo -e "${GREEN}🔄 $BOT 已重启！${NC}"
                sleep 1 ;;
            3)
                MAP="$BOT"
                modify_prompt_direct "$BOT"
                ;;
            4)
                MAP="$BOT"
                change_brain_direct "$BOT"
                ;;
            c|C)
                if [ "$IS_SERV00" = true ]; then
                    _serv00_remove_cron "$BOT"
                    _serv00_add_cron "$BOT"
                    echo -e "${CYAN}✅ cron 保活已重置${NC}"
                    sleep 1
                fi ;;
            2)
                echo ""
                read -p "  ⚠️  确认辞退并删除 '$BOT'？(y/n): " CONFIRM
                if [ "$CONFIRM" == "y" ] || [ "$CONFIRM" == "Y" ]; then
                    _kill_all_bot "$BOT"
                    if [ "$IS_SERV00" = true ]; then
                        _serv00_remove_cron "$BOT"
                    fi
                    rm -rf "$BOT_BASE/$BOT"
                    echo -e "${GREEN}✅ '$BOT' 已辞退删除。${NC}"
                    sleep 1
                    return
                fi ;;
            0) return ;;
            *) echo -e "${RED}⚠️ 无效选择${NC}"; sleep 1 ;;
        esac
    done
}

# 直接对指定秘书重塑灵魂
modify_prompt_direct() {
    local MOD_DIR="$1"
    local CUR_DISPLAY
    CUR_DISPLAY=$("$PYTHON_BIN" -c "import json; d=json.load(open('$BOT_BASE/$MOD_DIR/config.json')); print(d.get('DISPLAY_NAME','$MOD_DIR'))" 2>/dev/null)
    [ -z "$CUR_DISPLAY" ] && CUR_DISPLAY="$MOD_DIR"
    echo -e "${BLUE}=== 🎭 重塑灵魂：${CUR_DISPLAY} ===${NC}"
    echo ""
    echo -n "  修改显示名称（当前：${CUR_DISPLAY}，留空保持不变）: "
    read NEW_DISPLAY_NAME
    if [ -n "$NEW_DISPLAY_NAME" ]; then
        "$PYTHON_BIN" -c "
import json
try:
    with open('$BOT_BASE/$MOD_DIR/config.json', 'r') as f: data = json.load(f)
    data['DISPLAY_NAME'] = '$NEW_DISPLAY_NAME'
    with open('$BOT_BASE/$MOD_DIR/config.json', 'w') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('写入失败:', e)
"
        echo -e "${GREEN}  ✅ 显示名称已更新为：${NEW_DISPLAY_NAME}${NC}"
    fi
    echo ""
    echo -e "${YELLOW}当前性格设定：${NC}"
    cat "$BOT_BASE/$MOD_DIR/prompt.txt" 2>/dev/null || echo "无"
    echo "--------------------------------"
    read -p "请输入新的性格设定 (留空取消): " NEW_PROMPT
    if [ ! -z "$NEW_PROMPT" ]; then
        # 如果有显示名称，在开头注入名字声明
        CUR_NAME=$("$PYTHON_BIN" -c "import json; d=json.load(open('$BOT_BASE/$MOD_DIR/config.json')); print(d.get('DISPLAY_NAME',''))" 2>/dev/null)
        if [ -n "$CUR_NAME" ]; then
            NEW_PROMPT="【最高优先级指令：你的名字是「${CUR_NAME}」，任何情况下都只能用这个名字自称。】

${NEW_PROMPT}"
        fi
        echo "$NEW_PROMPT" > "$BOT_BASE/$MOD_DIR/prompt.txt"
        echo ""
        read -p "是否同时更新定时新闻推送设定？(y/n，默认 n): " UPDATE_NEWS
        if [ "$UPDATE_NEWS" == "y" ] || [ "$UPDATE_NEWS" == "Y" ]; then
            ask_news_push
            local _EN_NEWS=false
            [ "$ENABLE_NEWS" = "true" ] && _EN_NEWS=true
            "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['ENABLE_NEWS']  = sys.argv[2] == 'true'
    data['NEWS_MORNING'] = sys.argv[3]
    data['NEWS_EVENING'] = sys.argv[4]
    data['NEWS_TOPICS']  = sys.argv[5]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('配置写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" \
  "$_EN_NEWS" "$NEWS_MORNING" "$NEWS_EVENING" "$NEWS_TOPICS"
        fi
        _start_bot "$MOD_DIR"
        echo -e "${GREEN}✅ 性格已更新并重启！${NC}"
        sleep 1
    fi
}

# 直接对指定秘书换脑
change_brain_direct() {
    local MOD_DIR="$1"
    local CUR_DISPLAY
    CUR_DISPLAY=$("$PYTHON_BIN" -c "import json; d=json.load(open('$BOT_BASE/$MOD_DIR/config.json')); print(d.get('DISPLAY_NAME','$MOD_DIR'))" 2>/dev/null)
    echo -e "${PURPLE}=== ⚙️ 更换模型：${CUR_DISPLAY:-$MOD_DIR} ===${NC}"

    echo ""
    read -p "  输入 t 仅更新Tavily Key，其他键选择新引擎: " _TAVILY_ONLY
    if [ "$_TAVILY_ONLY" == "t" ] || [ "$_TAVILY_ONLY" == "T" ]; then
        ask_tavily
        "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['TAVILY_KEY'] = sys.argv[2]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" "$TAVILY_KEY"
        _start_bot "$MOD_DIR"
        echo -e "${GREEN}✅ Tavily Key 已更新并重启！${NC}"
        sleep 1
        return
    fi

    local _ALLOW_LOCAL="true"
    [ "$IS_SERV00" = true ] && _ALLOW_LOCAL="false"
    _select_engine "$_ALLOW_LOCAL" || return

    if [ "$TAVILY_ASKED" != "true" ]; then
        echo ""
        read -p "是否同时更新 Tavily Key？(y/n，默认 n): " UPDATE_TAVILY
        if [ "$UPDATE_TAVILY" == "y" ] || [ "$UPDATE_TAVILY" == "Y" ]; then
            ask_tavily
        fi
    fi
    "$PYTHON_BIN" -c "
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f: data = json.load(f)
    data['PROVIDER']   = sys.argv[2]
    data['API_KEY']    = sys.argv[3]
    data['MODEL_NAME'] = sys.argv[4]
    data['API_BASE']   = sys.argv[5]
    data['TAVILY_KEY'] = sys.argv[6]
    with open(path, 'w', encoding='utf-8') as f: json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e: print('写入失败:', e)
" "$BOT_BASE/$MOD_DIR/config.json" \
  "$PROVIDER" "$API_KEY" "$MODEL_NAME" "$API_BASE" "$TAVILY_KEY"
    _start_bot "$MOD_DIR"
    echo -e "${GREEN}✅ 模型更换成功并已重启！${NC}"
    sleep 1
}



# ══════════════════════════════════════════════════════════
#  全盘清理：删除 MIMI 所有文件，恢复干净系统
# ══════════════════════════════════════════════════════════
nuke_mimi() {
    clear
    echo -e "${RED}  ╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}  ║  ⚠️   全盘清理 —— 删除 MIMI 的一切，不可恢复！              ║${NC}"
    echo -e "${RED}  ╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  将会删除以下内容："
    echo -e "  ${DIM}  • 所有 AI 秘书及其配置${NC}"
    echo -e "  ${DIM}  • MIMI 脚本本体（~/mimi/）${NC}"
    echo -e "  ${DIM}  • Python 虚拟环境（serv00）${NC}"
    echo -e "  ${DIM}  • mimi 快捷命令${NC}"
    echo -e "  ${DIM}  • cron 保活条目（serv00）${NC}"
    echo ""
    echo -e "  ${YELLOW}删完就真没了，确定吗？${NC}"
    read -p "  输入 YES 确认（其他任意键取消）: " CONFIRM_NUKE
    if [ "$CONFIRM_NUKE" != "YES" ]; then
        echo -e "${GREEN}  已取消。${NC}"
        sleep 1
        return
    fi

    echo ""
    echo -e "${YELLOW}  🧹 正在清理...${NC}"

    # 1. 停止所有 bot 进程
    local ALL_BOTS
    ALL_BOTS=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" 2>/dev/null | xargs -I {} dirname {} | xargs -I {} basename {} 2>/dev/null)
    for BOT in $ALL_BOTS; do
        _kill_all_bot "$BOT"
    done
    echo -e "  ${GREEN}✔ Bot 进程已全部停止${NC}"

    # 2. 清除 cron 保活（serv00）
    if [ "$IS_SERV00" = true ]; then
        crontab -l 2>/dev/null | grep -v "mimi" | crontab - 2>/dev/null
        echo -e "  ${GREEN}✔ cron 条目已清除${NC}"
    fi

    # 3. 删除快捷命令
    if [ "$IS_SERV00" = true ]; then
        rm -f "$SHORTCUT_DIR/mimi" 2>/dev/null
        # 清理 .bashrc / .profile 里的 PATH 注入
        sed -i '/mimi/d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/mimi/d' "$HOME/.profile" 2>/dev/null
    else
        rm -f "/usr/local/bin/mimi" 2>/dev/null
    fi
    echo -e "  ${GREEN}✔ 快捷命令已删除${NC}"

    # 4. 删除 ~/mimi/ 总目录（包含脚本、bot、venv 一切）
    rm -rf "$MIMI_HOME" 2>/dev/null
    echo -e "  ${GREEN}✔ ~/mimi/ 目录已删除${NC}"

    echo ""
    echo -e "${GREEN}  ✅ 清理完毕！MIMI 已从系统彻底消失。${NC}"
    echo -e "${DIM}  （本次会话结束后完全干净）${NC}"
    echo ""
    sleep 2
    exit 0
}

# ══════════════════════════════════════════════════════════
#  主人房管理：查看 / 编辑作息时间表
# ══════════════════════════════════════════════════════════
manage_master_room() {
    while true; do
        clear
        echo -e "${PINK}  ╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PINK}  ║  🏠  主人房 — 作息时间表                              ║${NC}"
        echo -e "${PINK}  ╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${DIM}文件路径：$MASTER_DIR/schedule.txt${NC}"
        echo -e "  ${DIM}所有机器人共用此时间表，自动推断免打扰时段和资讯推送时间${NC}"
        echo ""
        echo -e "${YELLOW}  ── 当前作息表 ────────────────────────────────────────${NC}"
        if [ -f "$MASTER_DIR/schedule.txt" ]; then
            cat -n "$MASTER_DIR/schedule.txt" | sed 's/^/  /'
        else
            echo -e "  ${RED}作息表不存在，请先创建${NC}"
        fi
        echo ""
        echo -e "  ${PINK}e)${NC}  ✏️  用编辑器修改作息表 (nano)"
        echo -e "  ${PINK}r)${NC}  🔄 重置为默认作息表"
        echo -e "  ${PINK}i)${NC}  📥 导入你上传的作息表"
        echo -e "  ${PINK}b)${NC}  📖 查看当前推断的免打扰时段"
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -p "  👉 请选择: " MASTER_CHOICE
        case "$MASTER_CHOICE" in
            e|E)
                if command -v nano &>/dev/null; then
                    nano "$MASTER_DIR/schedule.txt"
                elif command -v vi &>/dev/null; then
                    vi "$MASTER_DIR/schedule.txt"
                else
                    echo -e "${RED}未找到编辑器，请手动编辑：$MASTER_DIR/schedule.txt${NC}"
                    sleep 2
                fi ;;
            r|R)
                read -p "  确认重置为默认作息表？(y/n): " CONFIRM_R
                if [ "$CONFIRM_R" == "y" ] || [ "$CONFIRM_R" == "Y" ]; then
                    cat > "$MASTER_DIR/schedule.txt" << 'SCHED_DEFAULT'
06:06 起床，洗漱
06:20 爆发力训练
06:30 吃早饭（鸡蛋，牛奶，坚果，100克碳水）
08:00 阅读，钢琴，绘画笔记三选一
08:30 工作
12:00 午饭（吃饱）
12:30 十分钟冥想
13:00 工作
16:00 十分钟有氧
18:00 吃水果
20:00 收工，洗澡
23:00 睡觉
SCHED_DEFAULT
                    echo -e "${GREEN}  ✅ 已重置为默认作息表${NC}"
                    sleep 1
                fi ;;
            i|I)
                echo -e "  ${DIM}将你的 schedule.txt 上传到 VPS，然后输入路径${NC}"
                read -p "  文件路径（留空取消）: " IMPORT_PATH
                if [ -n "$IMPORT_PATH" ] && [ -f "$IMPORT_PATH" ]; then
                    cp "$IMPORT_PATH" "$MASTER_DIR/schedule.txt"
                    echo -e "${GREEN}  ✅ 已导入！${NC}"
                    sleep 1
                fi ;;
            b|B)
                echo ""
                echo -e "  ${YELLOW}── 当前推断的免打扰时段 ────────${NC}"
                # 用 shell 简单推断
                SLEEP_H=$( grep -E "睡觉|就寝|入睡" "$MASTER_DIR/schedule.txt" 2>/dev/null | \
                    tail -1 | grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//' )
                WAKE_H=$( head -1 "$MASTER_DIR/schedule.txt" 2>/dev/null | \
                    grep -oE '^[0-9]{2}:[0-9]{2}' | cut -d: -f1 | sed 's/^0//' )
                [ -z "$SLEEP_H" ] && SLEEP_H="23"
                [ -z "$WAKE_H"  ] && WAKE_H="6"
                echo -e "  🌙 静音（睡觉）：${SLEEP_H}:00 起"
                echo -e "  ☀️  恢复（起床）：${WAKE_H}:00 起"
                echo -e "  ${DIM}  所有机器人在睡眠段内不会主动发消息${NC}"
                echo ""
                read -n 1 -s -r -p "  按任意键继续..."
                ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════
#  图书馆管理：查看 / 编辑 feeds.opml
# ══════════════════════════════════════════════════════════
manage_library_room() {
    while true; do
        clear
        echo -e "${BLUE}  ╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}  ║  📚  图书馆 — RSS 订阅源管理                          ║${NC}"
        echo -e "${BLUE}  ╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${DIM}文件路径：$LIBRARY_DIR/feeds.opml${NC}"
        echo -e "  ${DIM}所有机器人共用此订阅源；阅读后以吐槽/见解方式播报，而非直接朗读${NC}"
        echo ""
        # 解析并显示当前 feeds
        echo -e "${YELLOW}  ── 当前订阅源 ────────────────────────────────────────${NC}"
        if [ -f "$LIBRARY_DIR/feeds.opml" ]; then
            "$PYTHON_BIN" -c "
import re, sys
try:
    content = open('$LIBRARY_DIR/feeds.opml', encoding='utf-8').read()
    matches = re.findall(r'<outline[^>]+title=\"([^\"]*)\"[^>]+type=\"rss\"[^>]+xmlUrl=\"([^\"]*)\"', content)
    if not matches:
        matches = re.findall(r'<outline[^>]+xmlUrl=\"([^\"]*)\"[^>]+title=\"([^\"]*)\"', content)
        matches = [(b, a) for a, b in matches]
    for i, (title, url) in enumerate(matches, 1):
        print(f'  {i:2d}) {title}')
        print(f'      {url}')
except Exception as e:
    print(f'  解析出错: {e}')
" 2>/dev/null
        else
            echo -e "  ${RED}feeds.opml 不存在${NC}"
        fi
        echo ""
        echo -e "  ${PINK}e)${NC}  ✏️  用编辑器修改 feeds.opml (nano)"
        echo -e "  ${PINK}i)${NC}  📥 导入 feeds.opml 文件"
        echo -e "  ${PINK}a)${NC}  ➕ 快速添加一个 RSS 源"
        echo -e "  ${PINK}t)${NC}  🧪 测试抓取（随机试读一个源）"
        echo -e "  ${DIM}0)  返回主菜单${NC}"
        echo ""
        read -p "  👉 请选择: " LIB_CHOICE
        case "$LIB_CHOICE" in
            e|E)
                if command -v nano &>/dev/null; then
                    nano "$LIBRARY_DIR/feeds.opml"
                elif command -v vi &>/dev/null; then
                    vi "$LIBRARY_DIR/feeds.opml"
                else
                    echo -e "${RED}  未找到编辑器，请手动编辑：$LIBRARY_DIR/feeds.opml${NC}"
                    sleep 2
                fi ;;
            i|I)
                read -p "  feeds.opml 文件路径（留空取消）: " IMPORT_OPML
                if [ -n "$IMPORT_OPML" ] && [ -f "$IMPORT_OPML" ]; then
                    cp "$IMPORT_OPML" "$LIBRARY_DIR/feeds.opml"
                    echo -e "${GREEN}  ✅ 已导入！${NC}"
                    sleep 1
                fi ;;
            a|A)
                echo ""
                read -p "  RSS 名称（如：BBC中文）: " NEW_FEED_NAME
                read -p "  RSS 地址（xmlUrl）: " NEW_FEED_URL
                if [ -n "$NEW_FEED_NAME" ] && [ -n "$NEW_FEED_URL" ]; then
                    # 在 </body> 前插入新条目
                    "$PYTHON_BIN" -c "
import re, sys
path = '$LIBRARY_DIR/feeds.opml'
name = sys.argv[1]
url  = sys.argv[2]
try:
    content = open(path, encoding='utf-8').read()
    new_entry = f'    <outline text=\"{name}\" title=\"{name}\" type=\"rss\" xmlUrl=\"{url}\" />'
    content = content.replace('  </body>', f'{new_entry}\n  </body>')
    open(path, 'w', encoding='utf-8').write(content)
    print('ok')
except Exception as e:
    print(f'err:{e}')
" "$NEW_FEED_NAME" "$NEW_FEED_URL" 2>/dev/null
                    echo -e "${GREEN}  ✅ 已添加：$NEW_FEED_NAME${NC}"
                    sleep 1
                fi ;;
            t|T)
                echo ""
                echo -e "${YELLOW}  🧪 随机抓取测试...${NC}"
                "$PYTHON_BIN" -c "
import re, requests, random
try:
    content = open('$LIBRARY_DIR/feeds.opml', encoding='utf-8').read()
    matches = re.findall(r'xmlUrl=\"([^\"]*)\"', content)
    if not matches:
        print('  未找到订阅源')
        exit()
    url = random.choice(matches)
    print(f'  测试源：{url}')
    r = requests.get(url, timeout=10, headers={'User-Agent': 'Mozilla/5.0'})
    items = re.findall(r'<item[^>]*>(.*?)</item>', r.text, re.S)
    if not items:
        items = re.findall(r'<entry[^>]*>(.*?)</entry>', r.text, re.S)
    def clean(s):
        s = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', s, flags=re.S)
        return re.sub(r'<[^>]+>', '', s).strip()
    print(f'  找到 {len(items)} 条文章，前3条标题：')
    for item in items[:3]:
        t = re.search(r'<title[^>]*>(.*?)</title>', item, re.S)
        if t: print(f'  · {clean(t.group(1))[:60]}')
except Exception as e:
    print(f'  抓取失败：{e}')
" 2>/dev/null
                echo ""
                read -n 1 -s -r -p "  按任意键继续..."
                ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

# ==========================================
while true; do
    # 先收集 bot 数据，再清屏绘制，减少画面闪烁
    BOT_LIST=$(find "$BOT_BASE" -maxdepth 2 -name "bot.py" 2>/dev/null | xargs -I {} dirname {} | xargs -I {} basename {} 2>/dev/null)
    BOT_ARRAY=()
    BOT_LINES=()
    if [ -n "$BOT_LIST" ]; then
        while IFS= read -r BOT; do
            BOT_ARRAY+=("$BOT")
        done <<< "$BOT_LIST"
        for i in "${!BOT_ARRAY[@]}"; do
            BOT="${BOT_ARRAY[$i]}"
            IDX=$((i+1))
            PID=$(_get_bot_pid "$BOT")
            BOT_DISPLAY=$("$PYTHON_BIN" -c "
import json
try:
    d = json.load(open('$BOT_BASE/$BOT/config.json'))
    name = d.get('DISPLAY_NAME') or '$BOT'
    info = d.get('PROVIDER','?').upper() + ' / ' + d.get('MODEL_NAME','?')
    print(name + '|' + info)
except: print('$BOT|未知')
" 2>/dev/null)
            BOT_SHOW_NAME="${BOT_DISPLAY%%|*}"
            MODEL_INFO="${BOT_DISPLAY##*|}"
            if [ -n "$PID" ]; then
                BOT_LINES+=("  ${GREEN}● ${BOLD}[${IDX}] ${BOT_SHOW_NAME}${NC}  ${DIM}${MODEL_INFO}${NC}  ${GREEN}▶ 运行中${NC}")
            else
                BOT_LINES+=("  ${RED}○ ${BOLD}[${IDX}] ${BOT_SHOW_NAME}${NC}  ${DIM}${MODEL_INFO}${NC}  ${RED}■ 已停止${NC}")
            fi
        done
    fi

    clear
    print_banner
    echo -e "${BOLD}${PINK}  🌸  MIMI AI 助手管理控制台${NC}"
    echo -e "${PINK2}  ──────────────────────────────────────────────────────${NC}"

    if [ ${#BOT_ARRAY[@]} -eq 0 ]; then
        echo -e "  ${DIM}  💤  暂无在岗秘书  —  输入 n 招募第一个试试！${NC}"
    else
        for line in "${BOT_LINES[@]}"; do
            echo -e "$line"
        done
    fi

    echo -e "${PINK2}  ──────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${PINK}n)${NC}  🌸 添加新助手"
    # serv00 隐藏本地模型仓库，改为显示 serv00 专属提示
    if [ "$IS_SERV00" = true ]; then
        echo -e "  ${DIM}m)  📦 模型仓库（serv00 不支持本地模型）${NC}"
    else
        echo -e "  ${PINK}m)${NC}  📦 模型仓库"
    fi
    echo -e "  ${PINK}1)${NC}  🏠 主人房    ${DIM}查看/编辑作息时间表${NC}"
    echo -e "  ${PINK}2)${NC}  📚 图书馆    ${DIM}管理 RSS 订阅源 (feeds.opml)${NC}"
    echo -e "  ${PINK}h)${NC}  📖 新手说明书"
    echo -e "  ${RED}x)  🧹 全盘清理（删除 MIMI 的一切）${NC}"
    echo -e "  ${DIM}q)  退出  （输入 mimi 可再次调出本面板）${NC}"
    echo ""
    BOT_COUNT=${#BOT_ARRAY[@]}
    if [ $BOT_COUNT -gt 0 ]; then
        echo -e "  ${DIM}💡 输入秘书编号 [1-${BOT_COUNT}] 可管理该秘书${NC}"
    fi
    echo ""
    read -p "  👉 请选择: " MAIN_CHOICE

    if [[ "$MAIN_CHOICE" =~ ^[0-9]+$ ]] && [ "$MAIN_CHOICE" -ge 1 ] && [ "$MAIN_CHOICE" -le "$BOT_COUNT" ] 2>/dev/null; then
        SELECTED_BOT="${BOT_ARRAY[$((MAIN_CHOICE-1))]}"
        manage_bot_menu "$SELECTED_BOT" "$MAIN_CHOICE"
    else
        case "$MAIN_CHOICE" in
            n|N) deploy_new_bot ; pause_to_return ;;
            m|M) manage_local_models ;;
            1)   manage_master_room ;;
            2)   manage_library_room ;;
            h|H)
                clear
                echo -e "${PINK}  ╔════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${PINK}  ║              📖  MIMI 新手说明书                              ║${NC}"
                echo -e "${PINK}  ╚════════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                echo -e "${YELLOW}  ─── 🤔 MIMI 是什么？ ────────────────────────────────────────────${NC}"
                echo -e "  MIMI 可以帮你在 Telegram 里养一个（或多个）AI 助手。"
                echo -e "  你发消息给它，它会回复你；你还可以让它主动找你聊天。"
                echo -e "  就像养了一只住在服务器里、永远在线的 AI 小宠物。"
                echo ""
                # serv00 专属说明
                if [ "$IS_SERV00" = true ]; then
                echo -e "${CYAN}  ─── 🐡 serv00 特别说明 ──────────────────────────────────────────${NC}"
                echo -e "  ${CYAN}serv00 是免费共享主机，有一些特别之处：${NC}"
                echo -e "  ${DIM}  • 系统是 FreeBSD，不是 Linux，但 MIMI 已自动适配${NC}"
                echo -e "  ${DIM}  • 进程可能被系统周期清理，MIMI 已自动添加 cron 每5分钟保活${NC}"
                echo -e "  ${DIM}  • 不支持本地 AI 模型（Ollama），需用云端 API${NC}"
                echo -e "  ${DIM}  • 每90天需要登录一次面板，账号才不会被删除${NC}"
                echo -e "  ${DIM}  • 所有文件集中在：$MIMI_HOME/${NC}"
                echo ""
                fi
                echo -e "${YELLOW}  ─── 💡 本地模型 vs API，选哪个？ ───────────────────────────────${NC}"
                echo -e "  ${GREEN}本地模型（Ollama）${NC}"
                echo -e "  ${DIM}  好处：完全免费，数据不出服务器。坏处：要占内存，机器太弱跑不动。${NC}"
                echo -e "  ${DIM}  适合：内存 8G 以上的普通VPS（serv00 不支持）${NC}"
                echo ""
                echo -e "  ${GREEN}云端 API（Claude / Gemini）${NC}"
                echo -e "  ${DIM}  好处：极快、极聪明，任何机器都能跑，serv00 也完全支持！${NC}"
                echo -e "  ${DIM}  Gemini 有免费额度，新手强烈推荐先试 Gemini！${NC}"
                echo ""
                echo -e "${YELLOW}  ─── 🔑 免费白嫖 API 全攻略 ──────────────────────────────────────${NC}"
                echo ""
                echo -e "  ${GREEN}🥇 首选白嫖：Google Gemini${NC}  ${DIM}← 额度最大，自带谷歌搜索${NC}"
                echo -e "  ${DIM}  注册地址：https://aistudio.google.com/apikey${NC}"
                echo -e "  ${DIM}  注册谷歌账号即可，每天免费额度非常够用${NC}"
                echo ""
                echo -e "  ${GREEN}🥈 备选白嫖：Groq${NC}  ${DIM}← 没有谷歌账号的首选，速度极快${NC}"
                echo -e "  ${DIM}  注册地址：https://console.groq.com${NC}"
                echo -e "  ${DIM}  跑的是开源模型（Llama/Qwen），完全免费，无需信用卡${NC}"
                echo ""
                echo -e "  ${GREEN}🥉 多模型通道：OpenRouter${NC}  ${DIM}← 一个Key用几十种AI，有免费模型${NC}"
                echo -e "  ${DIM}  注册地址：https://openrouter.ai${NC}"
                echo -e "  ${DIM}  免费模型列表：https://openrouter.ai/models?q=free${NC}"
                echo ""
                echo -e "  ${GREEN}☁️  Cloudflare AI${NC}  ${DIM}← 每天1万次免费，不需要额外注册${NC}"
                echo -e "  ${DIM}  有 Cloudflare 账号就能用：dash.cloudflare.com → AI${NC}"
                echo ""
                echo -e "  ${GREEN}💎 国产之光：DeepSeek${NC}  ${DIM}← 便宜得离谱，有免费额度${NC}"
                echo -e "  ${DIM}  注册地址：https://platform.deepseek.com${NC}"
                echo ""
                echo -e "  ${GREEN}🔮 欧洲良心：Mistral${NC}  ${DIM}← 不锁区，适合搞不到其他Key的用户${NC}"
                echo -e "  ${DIM}  注册地址：https://console.mistral.ai${NC}"
                echo -e "  ${DIM}  open-mistral-nemo 模型完全免费${NC}"
                echo ""
                echo -e "  ${GREEN}🤖 付费高质量：Claude${NC}  ${DIM}← 注册有试用额度${NC}"
                echo -e "  ${DIM}  注册地址：https://console.anthropic.com${NC}"
                echo ""
                echo -e "  ${YELLOW}🔍 联网搜索加持：Tavily${NC}  ${DIM}← 可选，让AI能看到今天的新闻${NC}"
                echo -e "  ${DIM}  注册地址：https://app.tavily.com  免费1000次/月${NC}"
                echo -e "  ${DIM}  不填也能正常用，只是AI不知道最新消息${NC}"
                echo ""
                echo -e "${YELLOW}  ─── 📱 Telegram 机器人准备 ──────────────────────────────────────${NC}"
                echo -e "  ${GREEN}Bot Token${NC}"
                echo -e "  ${DIM}  在 Telegram 搜索 @BotFather → 发 /newbot → 按提示操作 → 拿Token${NC}"
                echo ""
                echo -e "  ${GREEN}你的 User ID${NC}"
                echo -e "  ${DIM}  在 Telegram 搜索 @userinfobot → 随便发条消息 → 它告诉你ID${NC}"
                echo ""
                echo -e "${YELLOW}  ─── 🚀 三步上手 ─────────────────────────────────────────────────${NC}"
                echo -e "  ${PINK}第一步${NC}  去 @BotFather 创建 Bot，拿到 Token"
                echo -e "  ${PINK}第二步${NC}  去 @userinfobot 拿到自己的 User ID"
                echo -e "  ${PINK}第三步${NC}  主菜单按 n 添加助手，选一个白嫖API，填入信息搞定"
                echo ""
                echo -e "${YELLOW}  ─── ❓ 常见问题 ─────────────────────────────────────────────────${NC}"
                echo -e "  ${DIM}Q: 助手不回我？${NC}"
                echo -e "  ${DIM}A: 检查 Token 和 User ID 是否正确。进助手菜单看 bot.log 报错。${NC}"
                echo ""
                echo -e "  ${DIM}Q: serv00 上 Bot 自动停了？${NC}"
                echo -e "  ${DIM}A: 正常！cron 每5分钟自动拉起，稍等片刻即可恢复。${NC}"
                echo ""
                echo -e "  ${DIM}Q: 没有谷歌账号用哪个API？${NC}"
                echo -e "  ${DIM}A: Groq！注册超简单，速度还比 Gemini 快，免费无限制。${NC}"
                echo ""
                read -n 1 -s -r -p "  按任意键返回主菜单..."

                ;;
            x|X)
                nuke_mimi
                ;;
            q|Q|0)
                echo -e "${PINK}👋 再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}⚠️ 无效的选择！${NC}"
                sleep 1
                ;;
        esac
    fi
done