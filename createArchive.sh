#!/bin/bash

echo $#

if [ "$#" -le "0" ]; then
    echo "Usage: $0 <executeable> <file/folder to bundle..> <file/folder to bundle..>"
    echo "Only works for 64bit (ld-linux-x86-64.so.2) .."
    exit 1
fi

IFS="
"

log=`mktemp`
log2=`mktemp`
log3=`mktemp`

function check {
#echo "check $1"
for line in `ldd $1`;do
    line=`echo $line | xargs`
    #echo $line
    file=""
    if [[ $line == *=\>* ]]; then
        file=`echo "$line" | awk '{print $3}'`
    else
        file=`echo "$line" | awk '{print $1}'` 
    fi
    #can be improved:
    #echo $file for $line
    cat $log | grep "$file" > /dev/null
    if [ $? -ne 0 ]; then
        if [ -e "$file" ]; then
            echo "$file" >> $log
            #echo $file
            check "$file"
        else
            echo "Couldn't find $file"
        fi
    #else
        #echo $file skip
    fi
done
}

echo -e "\e[7mCHECK LIBRARYS\e[0m"
check $1

echo -e "\e[7mCOPY LIB FILES TO TMP\e[0m"
echo $1 >> $log2
mkdir "/tmp/$1"
mkdir "/tmp/$1/lib"
cp -aL "$1" "/tmp/$1"
for line in `cat $log`;do
    cp -aL "$line" "/tmp/$1/lib"
    echo "lib/`basename \"$line\"`" >> $log2
done

echo -e "\e[7mCOPY FILES TO TMP\e[0m"
for item in "${@:2}"; do
    echo "$item"
    cp -arL "$item" "/tmp/$1"
    echo "$item" >> $log2
done

cat $log2 | uniq > $log3

echo -e "\e[7mCHECK FOR ld-linux-x86-64.so.2\e[0m"
if [ ! -f "/tmp/$1/lib/ld-linux-x86-64.so.2" ]; then
    echo "DOES'T EXISTS !!!"
    exit 1
fi

echo -e "\e[7mCREATE TAR ARCHIV\e[0m"
p=$PWD
cd "/tmp/$1"
find -name '*~' -exec rm {} \;
GZIP=-9 tar -zcvf "$p/archiv.tar.gz" -T $log3 > /dev/null
cd $p

echo -e "\e[7mCREATE ARCHIV\e[0m"
echo "#!/bin/bash" > archiv.sh
echo "SKIP=\`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' \$0\`" >> archiv.sh
echo "THIS=\`pwd\`/\$0" >> archiv.sh
echo "cd /tmp" >> archiv.sh
echo "mkdir \"$1\"" >> archiv.sh
echo "cd \"$1\"" >> archiv.sh
echo "echo -e \"\e[7mEXTRACT\e[0m\"" >> archiv.sh
echo "tail -n +\$SKIP \$THIS | tar -xzv" >> archiv.sh
echo "echo -e \"\e[7mEXECUTE\e[0m\"" >> archiv.sh
#echo "LD_LIBRARY_PATH=. \"./$1\" \$@" >> archiv.sh
echo "./lib/ld-linux-x86-64.so.2 --library-path ./lib \"./$1\"" >> archiv.sh
echo "res=\$?" >> archiv.sh
echo "echo -e \"\e[7mCLEAN UP\e[0m\"" >> archiv.sh
echo "rm -rf \"/tmp/$1\"" >> archiv.sh
echo "exit $res" >> archiv.sh
echo "__TARFILE_FOLLOWS__" >> archiv.sh
cat archiv.tar.gz >> archiv.sh
chmod +x archiv.sh 


echo -e "\e[7mCLEAN UP\e[0m"
rm $log
rm $log2
rm $log3
rm -rf "/tmp/$1"
