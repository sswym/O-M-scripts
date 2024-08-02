#!/bin/bash

highlight_yellow() {
    echo -e "\e[1;33m$1\e[0m"
}

highlight_red() {
    echo -e "\e[1;31m$1\e[0m"
}

highlight_green() {
    echo -e "\e[1;32m$1\e[0m"
}

hyper_threads(){
    Threads_per_core=$(lscpu | grep "Thread(s) per core" | awk '{print$4}')
    if [[ $Threads_per_core == 1 ]] ;then
        echo "----------------------"
        highlight_green "超线程已经关闭"
    else
        echo "----------------------"
        highlight_red "请关闭超线程!!!!!!!"
    fi
}

check_cores(){
    all_core=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    cpu_model=$(lscpu | grep "^Model name:" | awk '{print$3,$4,$5,$6,$7,$8,$9}')
    echo "----------------------"
    highlight_yellow "CPU型号：$cpu_model"
    highlight_yellow "核心数：$all_core"
    echo "----------------------"
}

check_memory() {
    all_memory=$(free -h | grep "Mem" | awk '{print $2}')
    slots_info=$(sudo dmidecode -t memory )
    locators=$(echo "$slots_info" | grep "Locator" | grep -v -E  "DIMM\s0|NODE|Dimm0" | awk '{print$2,$3,$4,$5}' | sed 's/Locator://')
    sizes=$(echo "$slots_info" | grep "^\sSize:" | grep -v Range | awk '{print$2,$3,$4}')
    speeds=$(echo "$slots_info" | grep "^\sSpeed:" | awk '{print$2,$3}')
    types=$(echo "$slots_info" | grep "^\sType:" | awk '{print$2}')
    ranks=$(echo "$slots_info" | grep "^\sRank:" | awk '{print$2}')
    memory_num=0

    echo "内存插槽状态："
    echo "----------------------"

    while read -r locator && read -r size <&3 && read -r type <&5; do
        if [[ $size == "No Module Installed" ]]; then
            highlight_red "$locator: 未安装内存"
        else
	    read -r speed <&4 && read -r rank <&6;
            memory_num=$((memory_num + 1))
            highlight_green "$locator: $size, $speed, $type, $rank"R
        fi
done < <(echo "$locators") 3< <(echo "$sizes") 4< <(echo "$speeds") 5< <(echo "$types") 6< <(echo "$ranks")

    echo "----------------------"
    highlight_yellow "一共有 $memory_num 根内存条被识别"
    highlight_yellow "总内存为 $all_memory"
    echo "----------------------"
}


check_motherboard(){
    model=$(sudo dmidecode -t 2 | grep "Product Name:" | awk '{print$3}')
    highlight_yellow "主板型号为：$model"
    echo "----------------------"
}

get_time(){
    # 获取运行时间
    uptime_output=$(uptime)
    uptime_info=$(echo $uptime_output | awk -F "up " '{print $2}' | awk -F ", " '{print $1}')

    # 初始化变量
    days=0
    hours=0
    minutes=0

    # 解析uptime信息
    if [[ $uptime_info == *day* ]]; then
        days=$(echo $uptime_info | awk '{print $1}')
        rest=$(echo $uptime_info | awk '{print $3}')
        if [[ $rest == *:* ]]; then
            hours=$(echo $rest | awk -F: '{print $1}')
            minutes=$(echo $rest | awk -F: '{print $2}')
        else
            hours=$(echo $rest | awk '{print $1}')
        fi
    elif [[ $uptime_info == *min* ]]; then
        minutes=$(echo $uptime_info | awk '{print $1}')
    else
        hours=$(echo $uptime_info | awk -F: '{print $1}')
        minutes=$(echo $uptime_info | awk -F: '{print $2}')
    fi

    # 格式化运行时间
    if (( days > 0 )); then
        running_time="${days} day ${hours} hours ${minutes} min"
    elif (( hours > 0 )); then
        running_time="${hours} hours ${minutes} min"
    else
        running_time="${minutes} min"
    fi

    # 获取开机时间
    boot_time=$(date -d "$(awk -F. '{print $1}' /proc/uptime) second ago" +"%Y-%m-%d %H:%M:%S")
    # 获取系统当前时间
    system_now_time=$(date +"%Y-%m-%d %H:%M:%S")

    # 获取IPMI当前时间
    ipmi_now_time=$(sudo ipmitool sel time get)

    highlight_yellow "开机时间：$boot_time"
    highlight_yellow "服务器运行时长：$running_time"
    highlight_yellow "系统当前时间：$system_now_time"
    highlight_yellow "IPMI当前时间：$ipmi_now_time"
    echo "----------------------"
}
# 检查 lspci 输出
check_lspci() {
	lspci | grep -i infiniband
	if [ $? -eq 0 ]; then
		highlight_red "IB状态：存在IB，请注意！！！！"
	else
		highlight_green "IB状态：不存在IB"
	fi
    	echo "----------------------"
}

main(){
    hyper_threads
    check_cores
    check_memory
    check_motherboard
    get_time
    check_lspci
}

main
