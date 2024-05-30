#!/bin/bash

subnet="192.168.$1"

# 定义一个函数，用于检查IP地址是否可达
check_ip() {
    ip=$1
    ping -c 1 -W 1 $ip > /dev/null 2>&1
    if test $? -eq 0 ; then
        echo $ip
    fi
}

# 检查目录中的*.ip文件
ip_files_count=$(ls *.ip 2> /dev/null | wc -l)

if test "$ip_files_count" -ge 2 ; then
    echo "两个IP文件,清理中..."
    rm -f *.ip
fi

# 确定输出文件
if test -f "IP1.ip" ; then
    output_file="IP2.ip"
else
    output_file="IP1.ip"
fi

# 并发执行ping命令并检查IP地址可达性
> "$output_file"  # 清空输出文件
for i in $(seq 1 254); do
    ip="$subnet.$i"
    check_ip $ip >> "$output_file" &
done

# 等待所有并发任务完成
wait

# 检查目录中的*.ip文件
ip_files_count=$(ls *.ip 2> /dev/null | wc -l)

if test "$ip_files_count" -eq 2 ; then
    echo "运行比较"
    file1="IP1.ip"
    file2="IP2.ip"

    # 创建临时文件存储排序后的内容
    sorted_file1=$(mktemp)
    sorted_file2=$(mktemp)

    # 对文件内容进行排序
    sort "$file1" > "$sorted_file1"
    sort "$file2" > "$sorted_file2"

    # 比较文件内容并输出不同的行
    diff_lines=$(comm -3 "$sorted_file1" "$sorted_file2")

    # 删除临时文件
    rm "$sorted_file1" "$sorted_file2"

    if test -n "$diff_lines" ; then
        echo "不同的行有："
        echo "$diff_lines"
    else
        echo "两个文件完全相同。"
    fi
fi
