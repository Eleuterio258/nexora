#!/usr/bin/env python3
"""
Alinha os segmentos PT_LOAD dos .so nativos empacotados para 16 KB (0x4000),
exigido pelo Google Play desde 01/11/2025 para apps a visar API 35+.

Porque existe: bibliotecas de terceiros usadas pela app (ML Kit
barcode-scanning via mobile_scanner, MediaPipe tasks-vision, CameraX) ainda
trazem .so compilados a 4 KB — issues abertas a montante, sem previsão
(google-ai-edge/mediapipe#6028, juliansteenbakker/mobile_scanner#1560). Sem
recompilar com a NDK (-z max-page-size=16384), a única forma de corrigir já é
reescrever o cabeçalho ELF depois de compilado.

Isto só reescreve o campo p_align de cada PT_LOAD — não desloca segmentos.
Pela especificação ELF, um segmento só é seguro para mmap a um alinhamento N
se p_vaddr ≡ p_offset (mod N); por isso valida-se essa congruência ANTES de
declarar 16 KB, e qualquer .so que a viole fica de fora (reportado como
aviso), em vez de ficar silenciosamente marcado como corrigido sem o ser —
declarar p_align=16K num segmento incongruente produzia um ELF
auto-inconsistente, que podia falhar de forma pior (crash em runtime num
dispositivo real de 16 KB) do que o aviso actual do Play/instalador.
"""
import struct
import os
import sys

PT_LOAD = 1
TARGET_ALIGN = 0x4000


def _load_segments(data, cls, endian):
    """Devolve, por cada PT_LOAD: (offset do campo p_align, formato struct, p_offset, p_vaddr)."""
    segs = []
    if cls == 2:  # ELFCLASS64
        phoff = struct.unpack_from(endian + "Q", data, 32)[0]
        phesz = struct.unpack_from(endian + "H", data, 54)[0]
        phn = struct.unpack_from(endian + "H", data, 56)[0]
        for i in range(phn):
            ph = phoff + i * phesz
            if struct.unpack_from(endian + "I", data, ph)[0] != PT_LOAD:
                continue
            p_offset = struct.unpack_from(endian + "Q", data, ph + 8)[0]
            p_vaddr = struct.unpack_from(endian + "Q", data, ph + 16)[0]
            segs.append((ph + 48, "Q", p_offset, p_vaddr))
    elif cls == 1:  # ELFCLASS32
        phoff = struct.unpack_from(endian + "I", data, 28)[0]
        phesz = struct.unpack_from(endian + "H", data, 42)[0]
        phn = struct.unpack_from(endian + "H", data, 44)[0]
        for i in range(phn):
            ph = phoff + i * phesz
            if struct.unpack_from(endian + "I", data, ph)[0] != PT_LOAD:
                continue
            p_offset = struct.unpack_from(endian + "I", data, ph + 4)[0]
            p_vaddr = struct.unpack_from(endian + "I", data, ph + 8)[0]
            segs.append((ph + 28, "I", p_offset, p_vaddr))
    return segs


def patch(path):
    """Devolve True se ficou 16 KB-seguro (já estava ou foi corrigido), False se ficou algum segmento por resolver."""
    with open(path, "rb") as f:
        data = bytearray(f.read())
    if data[:4] != b"\x7fELF":
        return True
    cls = data[4]
    endian = "<" if data[5] == 1 else ">"
    segs = _load_segments(data, cls, endian)
    if not segs:
        return True

    changed = False
    unsafe = []
    for align_off, fmt, p_offset, p_vaddr in segs:
        cur_align = struct.unpack_from(endian + fmt, data, align_off)[0]
        if cur_align >= TARGET_ALIGN:
            continue
        if (p_vaddr - p_offset) % TARGET_ALIGN != 0:
            unsafe.append((p_offset, p_vaddr))
            continue
        struct.pack_into(endian + fmt, data, align_off, TARGET_ALIGN)
        changed = True

    if changed:
        with open(path, "wb") as f:
            f.write(data)
        print(f"  corrigido: {os.path.basename(path)}")
    if unsafe:
        print(
            f"  AVISO: {os.path.basename(path)} tem segmento(s) PT_LOAD que não é "
            f"seguro alinhar a 16KB sem recompilar (p_offset/p_vaddr não congruentes "
            f"mod 16KB): {unsafe} — fica por resolver, precisa de versão nova da "
            f"biblioteca de origem."
        )
    return not unsafe


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: patch_elf_16kb.py <dir_libs1> [dir_libs2 ...]")
        sys.exit(1)

    all_safe = True
    for lib_dir in sys.argv[1:]:
        if not os.path.isdir(lib_dir):
            continue
        print(f"A analisar {lib_dir}")
        for root, _dirs, files in os.walk(lib_dir):
            for fname in files:
                if fname.endswith(".so"):
                    if not patch(os.path.join(root, fname)):
                        all_safe = False

    if not all_safe:
        print(
            "\nATENÇÃO: ficaram .so por corrigir (ver avisos acima) — a app "
            "continua sujeita a falhar em dispositivos reais de 16KB para essas "
            "bibliotecas. Não bloqueia o build."
        )
    print("Concluído.")
