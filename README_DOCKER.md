# Docker支持 for KernelSU

本文档说明如何在内核中启用Docker容器支持。

## 🚀 快速开始

### 1. 应用Docker配置

```bash
# 进入内核源码目录
cd /path/to/kernel/source

# 运行配置脚本
./scripts/docker_support.sh your_device_defconfig
```

### 2. 编译内核

```bash
# 加载配置
make your_device_defconfig

# 编译内核
make -j$(nproc)
```

### 3. 刷入设备

按照你设备的常规刷机流程刷入编译好的内核。

## 📋 验证Docker支持

刷入内核后，在设备上验证：

```bash
# 检查命名空间支持
cat /proc/filesystems | grep nsfs

# 检查cgroup支持
cat /proc/cgroups

# 检查用户命名空间
cat /proc/sys/kernel/unprivileged_userns_clone

# 检查overlayfs支持
cat /proc/filesystems | grep overlay
```

## 🔧 在Android上安装Docker

### 方法1: 使用Termux

```bash
# 在Termux中
pkg update && pkg install root-repo
pkg install docker

# 启动Docker服务
dockerd &
```

### 方法2: 使用Magisk模块

1. 安装 `Docker-Android` Magisk模块
2. 重启设备
3. 通过终端使用Docker

### 方法3: 手动安装

```bash
# 下载静态Docker二进制文件
wget https://download.docker.com/linux/static/stable/aarch64/docker-20.10.9.tgz
tar xzvf docker-20.10.9.tgz
cp docker/* /system/bin/

# 配置Docker守护进程
dockerd --storage-driver=overlay2 &
```

## ⚠️ 注意事项

1. **性能影响**: 容器化会增加系统资源消耗
2. **电池寿命**: 长时间运行容器可能影响电池续航
3. **安全性**: 确保只在可信环境使用容器功能
4. **兼容性**: 某些Docker功能可能在ARM架构上受限

## 🔍 故障排除

### 常见问题

**Q: Docker无法启动**
A: 检查内核配置是否正确应用，特别是命名空间和cgroup支持。

**Q: 容器网络不可用**
A: 确保网络命名空间和网桥支持已启用。

**Q: 存储驱动问题**
A: 尝试使用不同的存储驱动：`overlay2`, `vfs`, 或 `fuse-overlayfs`。

### 调试命令

```bash
# 检查内核功能
dmesg | grep -i docker
dmesg | grep -i namespace

# 验证容器运行
docker run --rm alpine echo "Hello Docker on Android!"
```

## 📚 参考资源

- [Docker官方文档](https://docs.docker.com/)
- [KernelSU文档](https://kernelsu.org/)
- [Android容器化项目](https://github.com/maruos/blueprints)
