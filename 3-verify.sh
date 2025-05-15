#!/bin/bash
echo "Step 8: 验证 ROCm 安装是否成功"

echo "=== 检查 rocminfo 是否成功加载 ==="
/opt/rocm/bin/rocminfo | tee rocminfo.log
if grep -q "loaded" rocminfo.log; then
    echo "[PASS] rocminfo 输出包含 'loaded'"
else
    echo "[FAIL] rocminfo 输出不包含 'loaded'"
fi

echo
echo "=== 检查 clinfo 是否正常输出 ==="
/opt/rocm/opencl/bin/clinfo || echo "[WARNING] clinfo 命令执行失败"

echo
echo "=== 检查 rocm-smi 输出是否包含 '=' ==="
/opt/rocm/bin/rocm-smi | tee rocm-smi.log
if grep -q "=" rocm-smi.log; then
    echo "[PASS] rocm-smi 输出正常（包含等号）"
else
    echo "[FAIL] rocm-smi 输出异常（未检测到等号）"
fi


