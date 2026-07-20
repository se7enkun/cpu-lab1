import os
import sys
import struct

def bin_to_coe(input_bin_path, output_coe_path):
    """
    将小端二进制文件转换为 Vivado .coe 文件（每行一个32位十六进制数）
    """
    if not os.path.isfile(input_bin_path):
        print(f"错误：文件 '{input_bin_path}' 不存在")
        return False

    try:
        with open(input_bin_path, 'rb') as fin, open(output_coe_path, 'w') as fout:
            # 写入 COE 文件头
            fout.write("MEMORY_INITIALIZATION_RADIX=16;\n")
            fout.write("MEMORY_INITIALIZATION_VECTOR=\n")

            data_count = 0
            while True:
                chunk = fin.read(4)
                if not chunk:
                    break
                # 如果文件大小不是4的倍数，补零（保持对齐）
                if len(chunk) < 4:
                    chunk = chunk.ljust(4, b'\x00')
                    print(f"警告：文件大小不是4的倍数，已补零")
                
                # 小端解包为32位无符号整数
                value = struct.unpack('<I', chunk)[0]
                # 输出大写十六进制，固定8位，无0x前缀
                fout.write(f"{value:08x}")
                data_count += 1

                fout.write("\n")

        print(f"转换成功：{input_bin_path} -> {output_coe_path}")
        print(f"共输出 {data_count} 个32位数据")
        return True

    except Exception as e:
        print(f"转换失败：{e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("用法：python bin2coe.py <输入.bin文件>")
        print("示例：python bin2coe.py add.bin")
        sys.exit(1)

    input_file = sys.argv[1]

    base, _ = os.path.splitext(input_file)
    output_file = base + ".coe"

    bin_to_coe(input_file, output_file)

if __name__ == "__main__":
    main()
