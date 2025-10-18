#!/bin/bash

# Docker 功能验证脚本
# 用于验证编译后的内核是否支持 Docker

KERNEL_IMAGE="${1:-arch/arm64/boot/Image}"
CONFIG_FILE="${2:-.config}"

check_kernel_config() {
    echo "=== 内核配置检查 ==="
    
    local docker_configs=(
        "CONFIG_NAMESPACES" "CONFIG_USER_NS" "CONFIG_PID_NS" 
        "CONFIG_NET_NS" "CONFIG_CGROUPS" "CONFIG_OVERLAY_FS"
        "CONFIG_VETH" "CONFIG_BRIDGE" "CONFIG_NETFILTER"
    )
    
    for config in "${docker_configs[@]}"; do
        if grep -q "^$config=y" "$CONFIG_FILE"; then
            echo "✅ $config"
        else
            echo "❌ $config"
        fi
    done
}

check_kernel_features() {
    echo ""
    echo "=== 内核功能检查 ==="
    
    # 检查内核版本
    if [ -f "$KERNEL_IMAGE" ]; then
        echo "✅ 内核镜像存在: $KERNEL_IMAGE"
    else
        echo "❌ 内核镜像不存在: $KERNEL_IMAGE"
    fi
}

generate_docker_readiness() {
    echo ""
    echo "=== Docker 就绪状态 ==="
    
    local essential_count=0
    local essential_total=5
    
    grep -q "^CONFIG_NAMESPACES=y" "$CONFIG_FILE" && ((essential_count++))
    grep -q "^CONFIG_CGROUPS=y" "$CONFIG_FILE" && ((essential_count++))
    grep -q "^CONFIG_USER_NS=y" "$CONFIG_FILE" && ((essential_count++))
    grep -q "^CONFIG_OVERLAY_FS=y" "$CONFIG_FILE" && ((essential_count++))
    grep -q "^CONFIG_VETH=y" "$CONFIG_FILE" && ((essential_count++))
    
    local readiness=$((essential_count * 100 / essential_total))
    
    echo "Docker 支持就绪度: $readiness%"
    echo "基础功能: $essential_count/$essential_total"
    
    if [ $readiness -ge 80 ]; then
        echo "🎉 内核已准备好运行 Docker"
    elif [ $readiness -ge 60 ]; then
        echo "⚠️ 内核基本支持 Docker，但可能有限制"
    else
        echo "❌ 内核 Docker 支持不完整"
    fi
}

# 主执行流程
echo "Docker 功能验证报告"
echo "生成时间: $(date)"
echo ""

check_kernel_config
check_kernel_features  
generate_docker_readiness
