#!/bin/bash
#################################################################
#20200717 更新:利用sed命令替代getN_from_stdout.py sed命令可以使用通配符 但是因为要写入文件名 还是需要分开写 
#20200724 更新:利用find_maxN_parameters函数替代 find_maxN_parameters.py 
#         更新:去掉各种检查前的file_path;用分号缩短代码 ;调用DM3_Tripletsg.4bl更换成$g4bl_script
#20200727 更新:因使用$g4bl_script 原先的位置（2700 5900 10000)出错 更改为Z1=31133 #Ze_DCB2 ; Z2=34933   #Ze_DM3B ; Z3=38533   #Z_DM3_sample
#################################################################

keep_alive_pid(){ 
    Threads=30
    PIDs=$1
    while [ ${#PIDs[*]} -eq $Threads ]
    do
        sleep 3
        runningPIDs=()        
        for pid in ${PIDs[*]}
        do         
            if ps -p $pid > /dev/null ;then runningPIDs+=($pid); fi
        done
        unset PIDs 
        PIDs=(`echo ${runningPIDs[*]}`)  
    done
    echo ${PIDs[*]}
}


extract_line_from_stdout(){
    stdout_dir=$1
    statistics_file=$2

    rm -f $statistics_file

    stdout_lst=(`ls $stdout_dir/`)
    echo "case,N" >> $statistics_file
    pid_counter=0
    for std_out in ${stdout_lst[*]}
    do
        if [ $pid_counter -lt 30 ]
        then         
            NTupleZ_line=(`sed -n "/^NTuple Z/p" $stdout_dir/$std_out`) #NTuple Z2700 1561 entries
            echo $std_out,${NTupleZ_line[2]} >> $statistics_file
            let pid_counter+=1
        else
            wait
            pid_counter=0
        fi 
    done
    wait     
}


find_maxN_parameters(){
    
    stat=$1
    settings=$2
    if (! [ -e $stat ]) || (! [ -e $settings ]);then echo missing file $stat and $settings; exit; fi 
    
    #############读统计N的文件
    old_IFS=$IFS
    IFS=,
    case_array=() ; N_array=() ; n=1
    while read case N
    do 
        if [ $n -eq 1 ];then
            n=0
        else
            IFS=. ; idx=($case) ; case_array+=(${idx[0]}) ; N_array+=($N)
            IFS=,
        fi    
    done < $stat

    #############找到最大N的序列索引
    IFS=$old_IFS
    MaxN=${N_array[0]} ; array_idx_MaxN=0
    for i in ${!N_array[*]}
    do
        if [ ${N_array[$i]} -gt $MaxN ];then MaxN=${N_array[$i]}; array_idx_MaxN=$i;fi 
    done
    #############通过序列索引找到Q的设置索引

    setting_idx_maxN=${case_array[$array_idx_MaxN]}

    #############通过设置索引找到对应的参数

    IFS=,
    while read line
    do 
        words=($line)

        if [ ${words[0]} == $setting_idx_maxN ];then  #用lt ge 等进行比较的话 右边不是整数 比较会报错 可能是因为被默认处理成字符串 尽管字符串本身的值是这个 并且还能运行 不能用 建议换成==
            #echo ${words[1]},${words[2]},${words[3]}  
            echo ${words[*]}
            IFS=$old_IFS
            break      
        fi    
    done < $settings
}

#################################################################
####    initialization 
#################################################################

Z1=31133   #Ze_DCB2       
Z2=34933   #Ze_DM3B
Z3=38533   #Z_DM3_sample

nt_nm1="Z"$Z1
nt_nm2="Z"$Z2
nt_nm3="Z"$Z3

stat1="statistics_ZeDCB2.txt"
stat2="statistics_ZeDM3B.txt"
stat3="statistics_ZDM3sample.txt"

N=13

g4bl_script=DM3_p100to45.g4bl

file_path=$(dirname $(readlink -f "$0"))
org_IFS=$IFS
#################################################################
####     
#################################################################

# stdout1 for Q1toQ3 ; stdout2 for Q4toQ6 ; stdout3 for Q7toQ9
# root_files1 for Q1toQ3 ; root_files2 for Q4toQ6 ; root_files3 for Q7toQ9
# Qsettings1.txt for Q1toQ3 ; Qsettings2.txt for Q4toQ6 ; Qsettings3.txt for Q7toQ9


#to check if the directory std_out/ root_files/ exist 
#  for dirc in stdout1 stdout2 stdout3 root_files1 root_files2 root_files3
#  do 
#      if ! [ -d $dirc ];then mkdir $dirc ;fi
#  done
#  if ! [ -e RDF_write_minimal_statistics_MFMZ_MT.py ];then echo "[*]Fatal Error: missing script "; exit 2 ;fi

##################################################################
#####     tune  Q1 Q2 Q3 
##################################################################
#  rm -f Qsettings1.txt $stat1     
#  echo index,K_DCQ1,K_DCQ2,K_DCQ3 >> Qsettings1.txt
#  PIDs=(); index=0
#  for i in $(seq $N)
#  do
#      for j in $(seq $N)
#      do
#          for k in $(seq $N)
#          do
#              K_DCQ1=$(echo "scale=4; -1.4+0.1*($i-1)" | bc)
#              K_DCQ2=$(echo "scale=4;  0.2+0.1*($j-1)" | bc)
#              K_DCQ3=$(echo "scale=4; -1.4+0.1*($k-1)" | bc)        
#  
#              let index+=1            
#              stdout_nm=$index".out"
#  
#              PIDs=(`keep_alive_pid $PIDs`) #it seems that it slower down the process
#              nohup g4bl $g4bl_script K_DCQ1=$K_DCQ1 K_DCQ2=$K_DCQ2 K_DCQ3=$K_DCQ3 \
#                                           K_DCQ4=0.9 K_DCQ5=-0.87 K_DCQ6=0.39 \
#                                           K_DM3Q1=0.72 K_DM3Q2=-1.14 K_DM3Q3=0.89 \
#                                           index=$index Znt=$Z1 > stdout1/$stdout_nm &
#              PIDs+=($!)             
#              echo $index,$K_DCQ1,$K_DCQ2,$K_DCQ3 >> Qsettings1.txt           
#          done
#      done
#  done
#  wait
#  rm -f *.root

#  extract_line_from_stdout stdout1 $stat1 ; wait #1797 -.4 1.0 -1.2

paras1=(`find_maxN_parameters $stat1 Qsettings1.txt`)

if [ ${paras1[0]} == "missing" ];then echo ${paras1[*]}; exit 1;fi
bestK_DCQ1=${paras1[1]}; bestK_DCQ2=${paras1[2]}; bestK_DCQ3=${paras1[3]}

now=$(date -d "now"); rm -f tuned_paras.txt
#转义使得换行有效
echo -e "$now\n index Q1 Q2 Q3\n ${paras1[*]}" >> tuned_paras.txt  
echo "[*]Tune Q1 Q2 Q3 Finished!"

#################################################################
####     tune  Q4 Q5 Q6 
#################################################################

PIDs=(); index=0
echo index,K_DCQ4,K_DCQ5,K_DCQ6 >> Qsettings2.txt

for i in $(seq $N)
do
    for j in $(seq $N)
    do
        for k in $(seq $N)
        do
            K_DCQ4=$(echo "scale=4;  0.2+0.1*($i-1)" | bc)
            K_DCQ5=$(echo "scale=4; -1.4+0.1*($j-1)" | bc)
            K_DCQ6=$(echo "scale=4;  0.2+0.1*($k-1)" | bc)

            let index+=1
            stdout_nm=$index".out"

            PIDs=(`keep_alive_pid $PIDs`) #it seems that it slower down the process
                        
            nohup g4bl $g4bl_script K_DCQ1=$bestK_DCQ1 K_DCQ2=$bestK_DCQ2 K_DCQ3=$bestK_DCQ3 \
                                         K_DCQ4=$K_DCQ4 K_DCQ5=$K_DCQ5 K_DCQ6=$K_DCQ6 \
                                         K_DM3Q1=0.72 K_DM3Q2=-1.14 K_DM3Q3=0.89 \
                                         index=$index Znt=$Z2 > stdout2/$stdout_nm &
            PIDs+=($!)
            echo $index,$K_DCQ4,$K_DCQ5,$K_DCQ6 >> Qsettings2.txt
        done
    done
done
wait

rm -f *.root

extract_line_from_stdout stdout2 $stat2 ; wait

paras2=(`find_maxN_parameters $stat2 Qsettings2.txt`)

if [ ${paras2[0]} == "missing" ];then echo ${paras2[*]};exit 1;fi

bestK_DCQ4=${paras2[1]}; bestK_DCQ5=${paras2[2]}; bestK_DCQ6=${paras2[3]}

echo -e " index Q4 Q5 Q6\n ${paras2[*]}">> tuned_paras.txt
echo "[*]Tune Q4 Q5 Q6 Finished!"

#################################################################
####     tune  Q7 Q8 Q9 
#################################################################
PIDs=(); index=0
echo index,K_DM3Q1,K_DM3Q2,K_DM3Q3 >> Qsettings3.txt
for i in $(seq $N)
do
    for j in $(seq $N)
    do
        for k in $(seq $N)
        do
            K_DM3Q1=$(echo "scale=4;  0.2+0.1*($i-1)" | bc)
            K_DM3Q2=$(echo "scale=4; -1.4+0.1*($j-1)" | bc)
            K_DM3Q3=$(echo "scale=4;  0.2+0.1*($k-1)" | bc)
            let index+=1
            stdout_nm=$index".out"

            PIDs=(`keep_alive_pid $PIDs`) 

            nohup g4bl $g4bl_script K_DCQ1=$bestK_DCQ1 K_DCQ2=$bestK_DCQ2 K_DCQ3=$bestK_DCQ3 \
                                    K_DCQ4=$bestK_DCQ4 K_DCQ5=$bestK_DCQ5 K_DCQ6=$bestK_DCQ6 \
                                    K_DM3Q1=$K_DM3Q1 K_DM3Q2=$K_DM3Q2 K_DM3Q3=$K_DM3Q3 \
                                    index=$index Znt=$Z3 > stdout3/$stdout_nm &
            
            PIDs+=($!)
            echo $index,$K_DM3Q1,$K_DM3Q2,$K_DM3Q3 >> Qsettings3.txt
        done
    done
done
wait

if [ -e 1.root ];then mv *.root root_files3/; else echo missing root files after tunning Q7toQ9; exit 1; fi
wait

root_lst3=(`ls root_files3/`)

echo case,N,sigma_X,sigma_Xp,sigma_Y,sigma_Yp,sigma_P >> $stat3
pid_counter=0
for out_root in ${root_lst3[*]}
do
    if [ $pid_counter -lt 30 ]
    then 
        nohup python3 RDF_write_minimal_statistics_MFMZ_MT.py root_files3/$out_root $nt_nm3 >> $stat3 & 
        let pid_counter+=1
    else
        wait
        pid_counter=0 
    fi
done
wait

echo write minimal statistics Finished
echo "[*]Tune Finished!"

