#gdb --args \
../../../toolchains/qemu/qemu-system-loongson32 \
            -M ls3a5k32 \
            -kernel $1 \
            -nographic \
            -d single,cpu -D single.log \
            -serial stdio \
            -m 4096  \
            -monitor tcp::12351,server,nowait \
            -fsdev local,security_model=mapped,id=fsdev0,path=./ \
            -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare,bus=ls7a.0 \
            -smp 1

			#debug 
			#-d in_asm -D in_asm.log \
            #-d int -D int.log       \
            #-d mem -D mem.log      \
            #-d single,cpu -D single.log \
            #-d single,cpu -D ./log/single.log \
			#-d in_asm -D in_asm.log \
            #-d int -D int.log     \
            #-d mem -D mem.log        \

