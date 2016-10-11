#!/bin/sh

BTRFS_DEVICE="`cat /tmp/btrfs_device`"
BTRFS_MOUNT_POINT="`cat /tmp/btrfs_mount_point`"

#BTRFS_DEVICE="/dev/sdb2"
#BTRFS_MOUNT_POINT="/"

# btrfs��subvolume�ϥޥ���Ȥ��Ƥ�����Τǡ����� /tmp/btrfs_tmp �˲�
# �ޥ���Ȥ��Ƥ���

mkdir -p /tmp/btrfs_tmp
mount -t btrfs $BTRFS_DEVICE /tmp/btrfs_tmp

# ��¸��subvolume��õ���������/ ľ����subvolume�Τߤ�ɽ������褦��
# ���Ƥ���Ĥ��

btrfs subvolume list /tmp/btrfs_tmp  | cut -f7 -d' ' | cut -f1 -d'/' |sort | uniq > /tmp/volume_list
if [ ! -s /tmp/volume_list ]; then
    echo "(None)" > /tmp/volume_list
fi

# root��subvolume������dialog(/tmp/BtrfsCreateSubvolume.sh)����������
# BtrfsCreateSubvolume.sh��root_subvolume_name�����Ϥ����ޤǥ롼�פ���

echo > /tmp/root_subvolume_name
cat <<'EOF' > /tmp/BtrfsCreateSubvolume.sh
#!/bin/sh
root_subvolume_name=`cat /tmp/root_subvolume_name | sed "s|^/||"`
while [ "$root_subvolume_name.x" = ".x" ]; do
    dialog --title "rootfs�Ѥ�subvolume�����" --inputbox \
"Btrfs�ϥե����륷���ƥ����ʣ����subvolume���ꡤ���줾��� \n\
subvolume����Ω�����ѡ��ƥ������Τ褦�˰��äơ�\n\
�ۤʤ�Ķ��򥤥󥹥ȡ��륤�󥹥ȡ��뤹�뤳�Ȥ���ǽ�Ǥ���\n\
���ߡ��ʲ���subvolume�����ꤵ��Ƥ��ޤ��� \n\n\
EOF
cat /tmp/volume_list >> /tmp/BtrfsCreateSubvolume.sh
cat <<'EOF' >> /tmp/BtrfsCreateSubvolume.sh
\n\n\
��¸��subvolume��˥��󥹥ȡ��뤹��ȥ��顼�ˤʤ��ǽ��������Τǡ� \n\
���󥷥��ƥ�򥤥󥹥ȡ��뤹��subvolume��̾�Τϡ��嵭�Ȱۤʤ�̾�Τ� \n\
���ꤷ�Ƥ��������� \n\
(���פ�subvolume�ϺƵ�ư�� btrfs subvol del ���ޥ�ɤǺ���Ǥ��ޤ�) \n\n\
subvolume��̾�Τϡ�" 22 74 2> /tmp/root_subvolume_name
    root_subvolume_name=`cat /tmp/root_subvolume_name | sed "s|^/||"`
done
EOF
chmod +x /tmp/BtrfsCreateSubvolume.sh
/tmp/BtrfsCreateSubvolume.sh
if [ $? = 255 -o $? = 1 ]; then 
        # �ɤ��ؽ������֤����׸�Ƥ
    exit 1
fi
# ���ޥ���Ȥ��Ƥ���btrfs�ѡ��ƥ������˿�����root�Ѥ�subvolume����
root_subvolume_name=`cat /tmp/root_subvolume_name | sed "s|^/||"`
echo "btrfs subvolume create /tmp/btrfs_tmp/$root_subvolume_name"
btrfs subvolume create /tmp/btrfs_tmp/$root_subvolume_name
umount /tmp/btrfs_tmp
echo "mount -t btrfs $BTRFS_DEVICE /tmp/btrfs_tmp -o subvol=$root_subvolume_name"
mount -t btrfs $BTRFS_DEVICE /tmp/btrfs_tmp -o subvol=$root_subvolume_name
sleep 5

dialog --yesno \
"btrfs�Ǥ�subvolume���Ǥ�դ�subvolume���뤳�Ȥ��Ǥ��ޤ��� \n\
subvolume�ϥե����륷���ƥ��Ǥϥǥ��쥯�ȥ�Τ褦�˸����ޤ�����\n\
btrfs��COW��ǽ��Ȥäơ���ñ��snapshot���뤳�Ȥ���ǽ�Ǥ���\n\
(�㤨�� /home ��subvolume�ˤ��Ƥ����С����̥桼���Υǡ����ΥХå����å� \n\
�����ޥ�ɰ�Ĥǲ�ǽ�ˤʤ�ޤ�) \n\n\
Plamo Linux�Ǥϡ�btrfs�Υѡ��ƥ��������� / �Ѥ�subvolume�� \n\
��äƥ��󥹥ȡ��뤹��褦�ˤ��Ƥ��ꡢ���������ˤϿ�����subvolume���ä� \n\
�ǥ��쥯�ȥꤴ�Ȥ�subvolume��ʬ���뤳�Ȥ���ǽ�Ǥ��� \n\n\
$BTRFS_DEVICE��˿�����subvolume����ޤ�����" 18 76
if [ $? = 0 ]; then
    SUBVOLUME=1
else
    SUBVOLUME=0
fi

if [ "$SUBVOLUME" = "0" ]; then
   umount /tmp/btrfs_tmp
   exit
fi

# $subvolume_list�������˴ޤॹ����ץ�(BtrfsSubVolume.sh)��
# �������롥�֤����Τ� /tmp/subvolume �˵��ܤ��줿subvolume��
# �ޥ������ǥ��쥯�ȥ�

echo > /tmp/subvolume
subvolume=`cat /tmp/subvolume`
while [ "$subvolume.x" = ".x" ]; do
    dialog --title "Btrfs��subvolume���ɲ�" --inputbox \
"Btrfs�ϥե����륷���ƥ����ʣ����subvolume���ꡤ \n\
���줾���subvolume��ǥ��쥯�ȥ�Τ褦�˰������Ȥ���ǽ�Ǥ��� \n\
(/var��/opt/htdocs��subvolume�ˤ��Ƥ����С� \n\
���줾��Υǥ��쥯�ȥꤴ�Ȥ�snapshot���뤳�Ȥ���ǽ�ˤʤ�ޤ�) \n\n\
�ɤΤ褦��subvolume����ޤ�����" 15 74 2> /tmp/subvolume
if [ $? = 255 -o $? = 1 ]; then 
        # �ɤ��ؽ������֤����׸�Ƥ
    exit 1
fi
    subvolume=`cat /tmp/subvolume`
done

echo "subvolume:$subvolume"
# ���ޥ���Ȥ��Ƥ���btrfs�ѡ��ƥ������˿�����subvolume($subvolume)����
echo "btrfs subvolume create /tmp/btrfs_tmp/$subvolume"
btrfs subvolume create /tmp/btrfs_tmp/$subvolume
sleep 5

# subvolume�Υꥹ�Ȥ���
echo "$subvolume\n" > /tmp/subvolume_list

SUBVOLUME=0
dialog --yesno "�⤦���btrfs��subvolume����ޤ�����" 10 70
if [ $? = 0 ]; then
    SUBVOLUME=1
fi

rm -f /tmp/BtrfsSubVolume.sh
echo > /tmp/subvolume
while [ $SUBVOLUME -eq 1 ]  ; do
    cat <<'__EOF' > /tmp/BtrfsSubVolume.sh
#!/bin/sh
subvolume=`cat /tmp/subvolume`
while [ "$subvolume.x" = ".x" ]; do

    dialog --title "Btrfs��subvolume���ɲ�" --inputbox \
"Btrfs�ϥե����륷���ƥ����ʣ����subvolume���ꡤ \
���줾���subvolume��ǥ��쥯�ȥ�Τ褦�˰������Ȥ���ǽ�Ǥ��� \
���ߡ����Υե����륷���ƥ�ˤϰʲ���subvolume�����ꤵ��Ƥ��ޤ� \
\n\n
__EOF
    cat /tmp/subvolume_list >> /tmp/BtrfsSubVolume.sh
    cat <<'__EOF' >> /tmp/BtrfsSubVolume.sh
\n
�ɤΤ褦��subvolume����ޤ�����" 15 74 2> /tmp/subvolume
subvolume=`cat /tmp/subvolume`
done 
__EOF
    chmod +x /tmp/BtrfsSubVolume.sh
    sh /tmp/BtrfsSubVolume.sh
    if [ $? = 255 -o $? = 1 ]; then 
        # �ɤ��ؽ������֤����׸�Ƥ
	exit 1
    fi
    subvolume=`cat /tmp/subvolume`

# ���ޥ���Ȥ��Ƥ���btrfs�ѡ��ƥ������˿�����subvolume����
    echo "subvolume:$subvolume"
    echo "btrfs subvolume create /tmp/btrfs_tmp/$subvolume"
    btrfs subvolume create /tmp/btrfs_tmp/$subvolume
    sleep 5
# subvolume�Υꥹ�Ȥ���
    echo "$subvolume\n" >> /tmp/subvolume_list
    SUBVOLUME=0
    echo > /tmp/subvolume
    dialog --yesno "�⤦���btrfs��subvolume����ޤ�����" 10 70
    if [ $? = 0 ]; then
	SUBVOLUME=1
    fi
done

# ��λ���ˤϲ��ޥ���Ȥ�������
# �ºݤΥޥ���ȥݥ���Ȥؤ� SeTpartitionj �ǥޥ���Ȥ���
# /etc/fstab �θ���(/tmp/SeTnative)����

umount /tmp/btrfs_tmp
