"""
Gera um modelo ONNX dummy para anti-spoofing facial.

Este modelo e apenas para testes e desenvolvimento. Em producao, deve ser
substituido por um classificador PAD treinado (ex.: Silent-Face-Anti-Spoofing).

Input:  float32[N, 3, 128, 128]
Output: float32[N, 2] (logits [attack, live])
"""

from pathlib import Path

import numpy as np
import onnx
from onnx import TensorProto, helper


def create_dummy_antispoofing_model(output_path: Path) -> None:
    # Input NCHW
    input_tensor = helper.make_tensor_value_info("input", TensorProto.FLOAT, [None, 3, 128, 128])
    # Output logits [attack, live]
    output_tensor = helper.make_tensor_value_info("output", TensorProto.FLOAT, [None, 2])

    # Pesos dummy: conv simples
    conv1_w = np.random.randn(8, 3, 3, 3).astype(np.float32) * 0.01
    conv1_b = np.zeros(8, dtype=np.float32)
    fc_w = np.random.randn(8 * 126 * 126, 2).astype(np.float32) * 0.001
    fc_b = np.array([0.5, -0.5], dtype=np.float32)  # bias leve para classe live

    initializers = [
        helper.make_tensor("conv1_w", TensorProto.FLOAT, conv1_w.shape, conv1_w.flatten().tolist()),
        helper.make_tensor("conv1_b", TensorProto.FLOAT, conv1_b.shape, conv1_b.flatten().tolist()),
        helper.make_tensor("fc_w", TensorProto.FLOAT, fc_w.shape, fc_w.flatten().tolist()),
        helper.make_tensor("fc_b", TensorProto.FLOAT, fc_b.shape, fc_b.flatten().tolist()),
    ]

    nodes = [
        helper.make_node("Conv", ["input", "conv1_w", "conv1_b"], ["conv1_out"], kernel_shape=[3, 3], pads=[0, 0, 0, 0]),
        helper.make_node("Relu", ["conv1_out"], ["relu1_out"]),
        helper.make_node("Flatten", ["relu1_out"], ["flatten_out"], axis=1),
        helper.make_node("MatMul", ["flatten_out", "fc_w"], ["matmul_out"]),
        helper.make_node("Add", ["matmul_out", "fc_b"], ["output"]),
    ]

    graph = helper.make_graph(
        nodes,
        "dummy_antispoofing",
        [input_tensor],
        [output_tensor],
        initializers,
    )

    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 13)])
    model.ir_version = 8
    onnx.checker.check_model(model)
    onnx.save(model, output_path)
    print(f"Modelo dummy guardado em: {output_path}")


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parent.parent
    models_dir = project_root / "app" / "ml_models"
    models_dir.mkdir(parents=True, exist_ok=True)
    create_dummy_antispoofing_model(models_dir / "anti_spoofing.onnx")
