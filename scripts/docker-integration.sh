#!/bin/bash

# GKI Docker 集成脚本
# 用于在现有 GKI 内核构建流程中添加 Docker 支持

set -e

KERNEL_DIR=$(pwd)
CONFIG_FILE=".config"
DOCKER_CONFIG="$KERNEL_DIR/arch/arm64/configs/docker_gki_defconfig"

log_info() {
    echo "[DOCKER-INTEGRATION] INFO: $1"
}

log_warn() {
    echo "[DOCKER-INTEGRATION] WARN: $1"
}

# 检查并应用 Docker 配置
apply_docker_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warn "配置文件 $CONFIG_FILE 不存在，跳过 Docker 配置"
        return 0
    fi
    
    if [ ! -f "$DOCKER_CONFIG" ]; then
        log_warn "Docker 配置文件 $DOCKER_CONFIG 不存在"
        return 0
    fi
    
    log_info "应用 Docker 支持配置..."
    
    # 读取 Docker 配置并应用到当前配置
    while IFS= read -r line; do
        if [[ "$line" =~ ^CONFIG_ ]] && [[ ! "$line" =~ ^# ]]; then
            config_name=$(echo "$line" | cut -d'=' -f1)
            config_value=$(echo "$line" | cut -d'=' -f2)
            
            # 检查配置是否已存在
            if grep -q "^$config_name=" "$CONFIG_FILE"; then
                # 配置已存在，更新它
                sed -i "s/^$config_name=.*/$line/" "$CONFIG_FILE"
            else
                # 配置不存在，添加它
                echo "$line" >> "$CONFIG_FILE"
            fi
        fi
    done < "$DOCKER_CONFIG"
    
    log_info "Docker 配置应用完成"
}

# 验证 Docker 配置
validate_docker_config() {
    log_info "验证 Docker 关键配置..."
    
    local critical_configs=(
        "CONFIG_NAMESPACES"
        "CONFIG_CGROUPS" 
        "CONFIG_USER_NS"
        "CONFIG_OVERLAY_FS"
        "CONFIG_VETH"
    )
    
    local missing_configs=()
    
    for config in "${critical_configs[@]}"; do
        if ! grep -q "^$config=y" "$CONFIG_FILE"; then
            missing_configs+=("$config")
        fi
    done
    
    if [ ${#missing_configs[@]} -ne 0 ]; then
        log_warn "以下关键 Docker 配置未启用: ${missing_configs[*]}"
        return 1
    else
        log_info "所有关键 Docker 配置已启用"
        return 0
    fi
}

# 生成配置报告
generate_docker_report() {
    local report_file="$KERNEL_DIR/docker_support_report.txt"
    
    cat > "$report_file" << EOF
Docker 支持配置报告
生成时间: $(date)
内核版本: $(make kernelversion 2>/dev/null || echo "未知")

关键配置状态:
命名空间: $(grep -q "^CONFIG_NAMESPACES=y" "$CONFIG_FILE" && echo "已启用" || echo "未启用")
用户命名空间: $(grep -q "^CONFIG_USER_NS=y" "$CONFIG_FILE" && echo "已启用" || echo "未启用")
CGroup: $(grep -q "^CONFIG_CGROUPS=y" "$CONFIG_FILE" && echo "已启用" || echo "未启用")
OverlayFS: $(grep -q "^CONFIG_OVERLAY_FS=y" "$CONFIG_FILE" && echo "已启用" || echo "未启用")
网络命名空间: $(grep -q "^CONFIG_NET_NS=y" "$CONFIG_FILE" && echo "已启用" || echo "未启用")

已启用的 Docker 相关配置:
$(grep -E "^CONFIG_(NAMESPACES|CGROUPS|USER_NS|OVERLAY|VETH|BRIDGE)=y" "$CONFIG_FILE")

EOF

    log_info "Docker 支持报告已生成: $report_file"
}

case "${1:-}" in
    "apply")
        apply_docker_config
        ;;
    "validate")
        validate_docker_config
        ;;
    "report")
        generate_docker_report
        ;;
    *)
        apply_docker_config
        validate_docker_config
        generate_docker_report
        ;;
esac    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/$(basename $original_config).backup.$(date +%Y%m%d_%H%M%S)"
    cp "$original_config" "$backup_file"
    log_info "配置文件已备份到: $backup_file"
}

# 应用Docker配置
apply_docker_config() {
    local target_config=$1
    local docker_config="$CONFIG_DIR/docker_defconfig"
    
    if [ ! -f "$docker_config" ]; then
        log_error "Docker配置文件不存在: $docker_config"
        exit 1
    fi
    
    log_info "正在应用Docker支持配置..."
    
    # 合并配置
    {
        cat "$target_config"
        echo ""
        echo "# === Docker Container Support ==="
        cat "$docker_config"
    } > "${target_config}.docker"
    
    mv "${target_config}.docker" "$target_config"
    log_info "Docker配置已成功应用到: $target_config"
}

# 检查配置依赖
check_dependencies() {
    log_info "检查必要的工具..."
    
    local missing_tools=()
    
    for tool in make gcc arm-linux-gnueabi-; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_warn "缺少以下工具: ${missing_tools[*]}"
        log_warn "请确保交叉编译工具链已安装"
    fi
}

# 验证配置
validate_config() {
    local config=$1
    log_info "验证内核配置..."
    
    # 检查关键配置
    local critical_configs=(
        "CONFIG_NAMESPACES"
        "CONFIG_CGROUPS"
        "CONFIG_USER_NS"
        "CONFIG_NET_NS"
        "CONFIG_OVERLAY_FS"
        "CONFIG_VETH"
        "CONFIG_BRIDGE"
    )
    
    for config in "${critical_configs[@]}"; do
        if ! grep -q "^$config=y" "$config"; then
            log_warn "关键配置可能未启用: $config"
        fi
    done
}

# 生成配置报告
generate_report() {
    local config=$1
    local report_file="$BACKUP_DIR/docker_support_report.txt"
    
    cat > "$report_file" << EOF
Docker支持配置报告
生成时间: $(date)
目标配置: $config

已启用的关键功能:
$(grep -E "^(CONFIG_NAMESPACES|CONFIG_CGROUPS|CONFIG_USER_NS|CONFIG_OVERLAY_FS)=y" "$config" || echo "未找到")

网络支持:
$(grep -E "^(CONFIG_VETH|CONFIG_BRIDGE|CONFIG_NETFILTER)=y" "$config" || echo "未找到")

存储支持:
$(grep -E "^(CONFIG_OVERLAY_FS|CONFIG_EXT4_FS|CONFIG_DM_)=y" "$config" || echo "未找到")

EOF

    log_info "配置报告已生成: $report_file"
}

# 显示使用说明
usage() {
    cat << EOF
使用方法: $0 [选项] <目标defconfig文件>

选项:
    -b, --backup-only    仅备份配置，不修改
    -v, --validate       验证配置完整性
    -h, --help          显示此帮助信息

示例:
    $0 my_device_defconfig
    $0 --validate my_device_defconfig
    $0 --backup-only my_device_defconfig

注意: 此脚本需要在内核源码根目录下运行
EOF
}

# 主函数
main() {
    local target_config=""
    local backup_only=false
    local validate_only=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--backup-only)
                backup_only=true
                shift
                ;;
            -v|--validate)
                validate_only=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                target_config="$1"
                shift
                ;;
        esac
    done
    
    if [ -z "$target_config" ]; then
        log_error "请指定目标defconfig文件"
        usage
        exit 1
    fi
    
    local full_config_path="$CONFIG_DIR/$target_config"
    
    if [ ! -f "$full_config_path" ]; then
        log_error "配置文件不存在: $full_config_path"
        exit 1
    fi
    
    log_info "目标配置: $full_config_path"
    
    # 检查依赖
    check_dependencies
    
    # 备份配置
    backup_config "$full_config_path"
    
    if [ "$validate_only" = true ]; then
        validate_config "$full_config_path"
        exit 0
    fi
    
    if [ "$backup_only" = true ]; then
        log_info "仅备份完成"
        exit 0
    fi
    
    # 应用Docker配置
    apply_docker_config "$full_config_path"
    
    # 验证配置
    validate_config "$full_config_path"
    
    # 生成报告
    generate_report "$full_config_path"
    
    log_info "Docker支持配置完成!"
    log_info "现在可以编译内核: make $target_config && make -j\$(nproc)"
}

# 运行主函数
main "$@"
