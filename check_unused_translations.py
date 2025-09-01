#!/usr/bin/env python3
"""
Bark项目本地化字符串分析工具

这个脚本会扫描整个Bark项目，找出 Localizable.xcstrings 中未使用的翻译key。
检测方式：任何在双引号内且在本地化文件中定义的字符串都会被认为是被使用的key。

使用方法:
    python3 check_unused_translations.py
    
输出:
    - 控制台显示分析结果
"""

import json
import os
import re
import sys
from pathlib import Path

class BarkLocalizationAnalyzer:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.localization_file = self.project_root / "Bark" / "Localizable.xcstrings"
        
    def extract_all_keys(self):
        """提取 Localizable.xcstrings 中的所有key"""
        try:
            with open(self.localization_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            return set(data['strings'].keys())
        except Exception as e:
            print(f"❌ 读取本地化文件失败: {e}")
            return set()
    
    def find_swift_files(self):
        """查找所有Swift源码文件"""
        swift_files = []
        for path in self.project_root.rglob("*.swift"):
            # 跳过Pods和build目录
            if "Pods" not in str(path) and "build" not in str(path):
                swift_files.append(path)
        return swift_files
    
    def extract_used_keys_from_file(self, file_path, all_defined_keys):
        """从Swift文件中提取使用的本地化key"""
        used_keys = set()
        nslocalizedstring_keys = set()  # 新增：专门收集NSLocalizedString中的key
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 方法1: 查找所有在双引号内的字符串，包括多行和转义字符
            quoted_strings = re.findall(r'"([^"]*)"', content, re.MULTILINE | re.DOTALL)
            
            # 检查哪些引号内的字符串是已定义的本地化key
            for quoted_string in quoted_strings:
                # 去掉前后空白字符
                quoted_string = quoted_string.strip()
                if quoted_string and quoted_string in all_defined_keys:
                    used_keys.add(quoted_string)
            
            # 方法2: 专门查找 NSLocalizedString("key") 模式
            nslocalizedstring_patterns = [
                r'NSLocalizedString\s*\(\s*"([^"]+)"\s*\)',     # NSLocalizedString("key")
                r'NSLocalizedString\s*\(\s*\'([^\']+)\'\s*\)',   # NSLocalizedString('key')
                r'NSLocalizedString\s*\(\s*@"([^"]+)"\s*\)',     # NSLocalizedString(@"key")
            ]
            
            for pattern in nslocalizedstring_patterns:
                matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
                for match in matches:
                    match = match.strip()
                    if match:
                        nslocalizedstring_keys.add(match)  # 收集所有NSLocalizedString中的key
                        if match in all_defined_keys:
                            used_keys.add(match)
            
        except Exception as e:
            print(f"⚠️  读取文件失败 {file_path}: {e}")
        
        return used_keys, nslocalizedstring_keys
    
    def find_all_used_keys(self, all_defined_keys):
        """在整个项目中查找所有使用的本地化 key"""
        # 查找所有Swift文件
        swift_files = self.find_swift_files()
        print(f"📁 找到 {len(swift_files)} 个Swift文件")
        
        # 提取使用的key
        used_keys = set()
        all_nslocalizedstring_keys = set()  # 新增：收集所有NSLocalizedString中的key
        files_with_keys = 0
        
        for file_path in swift_files:
            file_keys, nsl_keys = self.extract_used_keys_from_file(file_path, all_defined_keys)
            if file_keys:
                files_with_keys += 1
                used_keys.update(file_keys)
            all_nslocalizedstring_keys.update(nsl_keys)
        
        print(f"🔑 在 {files_with_keys} 个文件中找到 {len(used_keys)} 个使用的key")
        
        # 计算在NSLocalizedString中使用但未在本地化文件中定义的key
        missing_in_localization = all_nslocalizedstring_keys - all_defined_keys
        
        return used_keys, files_with_keys, missing_in_localization
    
    def analyze(self):
        """执行完整的本地化分析"""
        print("🔍 开始分析Bark项目的本地化使用情况...")
        
        # 提取所有定义的key
        print("📖 读取 Localizable.xcstrings...")
        all_keys = self.extract_all_keys()
        if not all_keys:
            return None
        
        print(f"✅ 找到 {len(all_keys)} 个本地化key")
        
        # 查找使用的key
        used_keys, files_with_keys, missing_in_localization = self.find_all_used_keys(all_keys)
        
        # 计算未使用的key
        unused_keys = all_keys - used_keys
        missing_keys = used_keys - all_keys  # 这个应该为空，因为used_keys是从all_keys中筛选的
        
        result = {
            'total_keys': len(all_keys),
            'used_keys': len(used_keys),
            'unused_keys': len(unused_keys),
            'missing_keys': len(missing_keys),
            'missing_in_localization': len(missing_in_localization),
            'all_keys': sorted(list(all_keys)),
            'used_keys_list': sorted(list(used_keys)),
            'unused_keys_list': sorted(list(unused_keys)),
            'missing_keys_list': sorted(list(missing_keys)),
            'missing_in_localization_list': sorted(list(missing_in_localization)),
            'files_scanned': len(self.find_swift_files()),
            'files_with_keys': files_with_keys
        }
        
        return result
    
    def save_results(self, result):
        """保存分析结果到文件"""
        # 已移除文件保存功能，只在控制台显示结果
        pass
    
    def print_summary(self, result):
        """打印分析摘要"""
        if not result:
            return
        
        print("\n" + "=" * 60)
        print("📊 分析结果摘要")
        print("=" * 60)
        print(f"总本地化key数量: {result['total_keys']}")
        print(f"使用中的key数量: {result['used_keys']}")
        print(f"未使用的key数量: {result['unused_keys']}")
        print(f"缺失的key数量: {result['missing_keys']} (代码中使用但未定义)")
        print(f"NSLocalizedString中缺失的key: {result['missing_in_localization']} 个")
        
        if result['unused_keys_list']:
            print(f"\n🗑️  未使用的翻译key ({result['unused_keys']} 个):")
            for i, key in enumerate(result['unused_keys_list'], 1):
                print(f"   {i:2d}. {key}")
        
        if result['missing_keys_list']:
            print(f"\n⚠️  缺失的翻译key ({result['missing_keys']} 个):")
            for i, key in enumerate(result['missing_keys_list'], 1):
                print(f"   {i:2d}. {key}")
        
        if result['missing_in_localization_list']:
            print(f"\n❌ NSLocalizedString中使用但未在Localizable.xcstrings中定义的key ({result['missing_in_localization']} 个):")
            for i, key in enumerate(result['missing_in_localization_list'], 1):
                print(f"   {i:2d}. {key}")
        
        if not result['unused_keys_list'] and not result['missing_keys_list'] and not result['missing_in_localization_list']:
            print("\n🎉 完美！所有翻译key都被正确使用和定义！")
        
        # 计算使用率
        usage_rate = (result['used_keys'] / result['total_keys']) * 100 if result['total_keys'] > 0 else 0
        print(f"\n📈 翻译使用率: {usage_rate:.1f}%")

def main():
    project_root = "/Users/huangfeng/Documents/Bark"
    
    if not os.path.exists(project_root):
        print(f"❌ 项目目录不存在: {project_root}")
        sys.exit(1)
    
    analyzer = BarkLocalizationAnalyzer(project_root)
    
    if not analyzer.localization_file.exists():
        print(f"❌ 本地化文件不存在: {analyzer.localization_file}")
        sys.exit(1)
    
    # 执行分析
    result = analyzer.analyze()
    
    if result:
        # 显示结果
        analyzer.print_summary(result)
        
        print(f"\n💡 建议:")
        if result['unused_keys'] > 0:
            print(f"   - 考虑删除 {result['unused_keys']} 个未使用的翻译key以减小包体积")
        if result['missing_keys'] > 0:
            print(f"   - 为 {result['missing_keys']} 个缺失的key添加翻译")
        if result['missing_in_localization'] > 0:
            print(f"   - 为 {result['missing_in_localization']} 个NSLocalizedString中的key添加本地化定义")
        
        print("   - 检查是否有动态构建的key名称(脚本可能无法检测)")
        print("   - 手动检查Storyboard/XIB文件中的硬编码字符串")
    
    else:
        print("❌ 分析失败")
        sys.exit(1)

if __name__ == "__main__":
    main()
