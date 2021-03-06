#!/bin/sh

BIN_SH=`realpath $0`
BIN_PATH=`dirname $BIN_SH`
tmp_chroot_env="/tmp/oe-chroot-env"
work_dir=`pwd`

if [ $# != 1 ]; then
    echo "usage: $BIN_SH <path_to_rpms>"
    echo ""
    exit 0
fi

RPM_DIR=$1

# get an empty dir for chroot env
sudo /bin/rm -rf $tmp_chroot_env
mkdir -p $tmp_chroot_env

# get a package list for the chroot env
$BIN_PATH/get_dep.pl -be 2>/dev/null > $tmp_chroot_env/.palist

# change work dir to chroot dir then find rpm and extract
cd $tmp_chroot_env
rm -f .alist
rm -f .msplist
for t in `cat .palist `; do
    #find $RPM_DIR -name  "$t-[0-9]*rpm" | grep -v 'src.rpm' | grep -v debuginfo | grep -v debugsource >> .alist
    rpmf=`find $RPM_DIR -name  "$t-[0-9]*rpm"`
    if [ "x$rpmf" = "x" ]; then
        echo $t >> .msplist
    else
        for j in $rpmf; do
            echo $j >> .alist
        done
    fi
done 

sed -i -e '/src.rpm/d' .alist

for i in `cat .alist`; do
    rpm2cpio $i | sudo cpio -id 2>/dev/null
done

# hack/fix symlinks stuff
if [ -e lib ]; then
    sudo rsync -a lib/* usr/lib
fi
if [ -e lib64 ]; then
    sudo rsync -a lib64/* usr/lib64
fi
if [ -e bin ]; then
    sudo rsync -a bin/* usr/bin
fi
if [ -e sbin ]; then
    sudo rsync -a sbin/* usr/sbin
fi

sudo rm -rf lib lib64 bin sbin
sudo ln -s usr/lib .
sudo ln -s usr/lib64 .
sudo ln -s usr/bin .
sudo ln -s usr/sbin .
cd lib64; sudo ln -s ../lib/lib*so* . ;  cd -;
cd bin; sudo ln -s ld.bfd ld ; cd -;

# pack the chroot env into image
cd $work_dir
sudo $BIN_PATH/pack-chroot-env.sh $tmp_chroot_env

echo "done."
