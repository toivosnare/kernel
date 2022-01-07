GDB=gdb-multiarch
BIN=zig-out/bin/kernel
SRC=src
IP=`ip route | awk '/default/ { print $3 }'`
$GDB -q --symbols=$BIN --directory=$SRC -ex "target remote tcp4:$IP:1234"
