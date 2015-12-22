#!/bin/bash

if [ -z "$1" ] ; then
	echo 'ERROR!! filename no specified!'
	exit 1
fi

basename=${1##*/}
srcname=${basename%.*}

# 余分な先頭行削除
cat ${1} | grep -A 100000 '^[=]*$' > ./001
if [ $? -ne 0 ]; then
	exit 1
fi

# ダブルクォート" を削除する
cat ./001 | sed 's/"/###/g' > ./002
if [ $? -ne 0 ]; then
        exit 1
fi

# ページ番号を除去する
cat ./002 | grep -v '^ページ([0-9]*)$' > ./003
if [ $? -ne 0 ]; then
        exit 1
fi

# 案件情報〜.txtを除去する
cat ./003 | grep -v '^案件情報.*20.*$' > ./004
if [ $? -ne 0 ]; then
        exit 1
fi

# データ元ファイルと案件番号と担当 
cat ./004 | sed 's/【\(.*\)\(.*201[0-9]\{5\}-[0-9]\{2\}-[0-9]\{3\}\)】.*\(◆担当：\)\(.*\)$/\2,\n\4,/g' > ./005
if [ $? -ne 0 ]; then
        exit 1
fi

# 掲載日
cat ./005 | sed 's/^掲載日：\(.*\)/\1,/g' > ./006
if [ $? -ne 0 ]; then
        exit 1
fi

# 最終桁が "," じゃない行に仮想改行コード "↓"を入れる
cat ./006 | sed 's/\([^,]\)$/\1↓↓/g' > ./007
if [ $? -ne 0 ]; then
        exit 1
fi

# レコードの区切り行を削除する。
cat ./007 | grep -v '^=*↓↓$' > ./008
if [ $? -ne 0 ]; then
        exit 1
fi

# 一旦、改行コードを全削除
cat ./008 | tr -d '\n' > ./009
if [ $? -ne 0 ]; then
        exit 1
fi

# 案件番号の前に改行を挿入
cat ./009 | sed 's/\(201[0-9]\{5\}-[0-9]\{2\}-[0-9]\{3\}\)/\n\1/g' > ./010
if [ $? -ne 0 ]; then
        exit 1
fi

# 先頭行にも改行が付いてしまうので削除する（空行は削除する）
cat ./010 | grep -v '^$' > ./011
if [ $? -ne 0 ]; then
        exit 1
fi

# 掲載日が存在しないレコードがあるため、"2000/01/01"として補完する
cat ./011 | sed 's/\(201[0-9][0-1][0-2][0-3][0-9]-[0-9]\{2\}-[0-9]\{3\},[^,]*,\)\([^2][^0]\)/\12000\/01\/01,\2/g' > ./012
if [ $? -ne 0 ]; then
        exit 1
fi

# @srcname@、①案件番号、②担当者、③掲載日、それ以降を「④案件情報」として "" で括る
cat ./012 | sed 's/^\([^,]*,[^,]*,[^,]*,\)\(.*$\)/@srcname@,\1"\2"/g' > ./013
if [ $? -ne 0 ]; then
        exit 1
fi

# @srcname を データ元ファイル名に置換する
cat ./013 | sed "s/@srcname@/${srcname}/g" > 014
if [ $? -ne 0 ]; then
        exit 1
fi

# 仮想改行コード(↓↓)を本当の改行コードに置換する
cat ./014 | sed 's/↓↓/\n/g' > ./015
if [ $? -ne 0 ]; then
        exit 1
fi


cp -p ./015 ./new_list.csv
if [ $? -ne 0 ]; then
        exit 1
fi

mysqlimport -u job -pstrgzr --local --delete --columns=jsource,jid,jauthor,jupdate,jcontent --fields-terminated-by=',' --lines-terminated-by='\n' --fields-enclosed-by='"' job ./new_list.csv
if [ $? -ne 0 ]; then
        exit 1
fi

cat ./014
if [ $? -ne 0 ]; then
        exit 1
fi
