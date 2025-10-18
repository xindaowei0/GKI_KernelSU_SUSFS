# GKI 内核 Docker 支持集成指南

## 概述

此文档说明如何在现有 GKI 内核构建流程中集成 Docker 支持，无需修改原有核心配置。

## 文件结构

```
GKI_KernelSU_SUSFS/
├── arch/arm64/configs/
│   └── docker_gki_defconfig          # Docker 专用配置
├── scripts/
│   ├── docker-integration.sh         # Docker 集成脚本
│   └── docker-feature-check.sh       # 功能验证脚本
├── .github/workflows/
│   └── gki-kernel.yml                # 已集成 Docker 支持的工作流
└── docs/
    └── DOCKER_INTEGRATION.md         # 本文档
```

## 使用方法

### 1. 编译带 Docker 支持的 GKI 内核

```bash
# 启用 Docker 支持编译
make gki_defconfig
./scripts/docker-integration.sh apply
make olddefconfig
make -j$(nproc)

# 验证 Docker 支持
./scripts/docker-feature-check.sh
```

### 2. 使用 GitHub Actions

在 GitHub Actions 界面中：
1. 选择 "Build GKI Kernel with Docker Support" 工作流
2. 设置 `enable_docker` 为 `true`
3. 选择内核配置
4. 运行工作流

### 3. 验证编译结果

检查生成的报告文件：
- `docker_support_report.txt` - Docker 支持详情
- `artifacts/docker_support_report.txt` - CI/CD 产物中的报告

## 配置说明

### 核心 Docker 功能

| 功能 | 配置选项 | 重要性 |
|------|----------|--------|
| 命名空间 | `CONFIG_NAMESPACES` | 必需 |
| 用户命名空间 | `CONFIG_USER_NS` | 必需 |
| 控制组 | `CONFIG_CGROUPS` | 必需 |
| OverlayFS | `CONFIG_OVERLAY_FS` | 必需 |
| 网络命名空间 | `CONFIG_NET_NS` | 必需 |

### 可选功能

| 功能 | 配置选项 | 用途 |
|------|----------|------|
| 设备映射器 | `CONFIG_BLK_DEV_DM` | 存储后端 |
| 网络桥接 | `CONFIG_BRIDGE` | 容器网络 |
| 安全模块 | `CONFIG_SECCOMP` | 安全限制 |

## 故障排除

### 常见问题

1. **配置冲突**
   - 症状：编译错误或配置验证失败
   - 解决：检查 `docker_gki_defconfig` 与原有配置的兼容性

2. **功能缺失**
   - 症状：Docker 启动失败
   - 解决：运行 `./scripts/docker-feature-check.sh` 验证支持情况

3. **性能问题**
   - 症状：系统响应变慢
   - 解决：考虑禁用不必要的 Docker 相关配置

## 参考资源

- [Docker 官方内核要求](https://docs.docker.com/engine/install/linux-postinstall/#kernel-compatibility)
- [KernelSU 文档](https://kernelsu.org/)
- [GKI 内核开发指南](https://source.android.com/docs/core/architecture/kernel/gki)
