SRC_DIR="/home/archives/source/"
ver=$1
base_ver=${1%.*}
echo '### clone raspberry pi kernel source ###'
git clone --depth=1 --branch rpi-$base_ver.y https://github.com/raspberrypi/linux rpi-$ver
hash=`(cd rpi-$ver; git rev-parse --short HEAD)`

echo '### extract original kernel ###'
rm -rf linux-$base_ver
tar xf $SRC_DIR/linux-$base_ver.tar.xz
(cd linux-$base_ver; xz -dc $SRC_DIR/patch-$ver.xz | patch -p1)

echo '### make raspbery pi kernel diff file ###'
diff -Nrc --exclude .git --exclude include-prefixes linux-$base_ver rpi-$ver > rpi-$ver-`date +%Y%m%d`-$hash.diff
