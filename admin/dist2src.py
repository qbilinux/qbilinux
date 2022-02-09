#!/usr/bin/python3

import os
import sys
import fnmatch
import shutil
import pathlib

args=sys.argv
argc=len(args)

#print(args)
#print(argc)

def fild_all_files2(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            yield os.path.join(root, file)
        if 'build' in dirs:
            dirs.remove('build')
        if 'work' in dirs:
            dirs.remove('work')
        if 'old' in dirs:
            dirs.remove('old')
        if 'source' in dirs:
            dirs.remove('source')
        if 'admin' in dirs:
            dirs.remove('admin')
        if 'boot' in dirs:
            dirs.remove('boot')

def fild_all_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            yield os.path.join(root, file)
        if 'EFI' in dirs:
            dirs.remove('EFI')
        if 'boot' in dirs:
            dirs.remove('boot')
        if 'isolinux' in dirs:
            dirs.remove('isolinux')

def usage():
    print("")
    print("copy distribution pakege file to build source tree.")
    print("")
    print("Usage: "+args[0]+" distdir builddir arch")
    print("")
    print("   distdir:  directory contains distribution files.")
    print("   builddir: package build direcotry. (normarly git clone direcotry)")
    print("   arch:     x86_64 x86 armv7l aarch64")
    print("")
    print("   ex) "+args[0]+" qbilinux-current qbilinux-src x86_64")
    print("")
    
if (argc != 4):
    usage()
    quit()

if (args[3] != "x86_64" and args[3] != "x86" and args[3] != "armv7l" and args[3] != "aarch64"):
    usage()
    quit()

source_dir=args[1]+"/"+args[3]
dest_dir=args[2]

if (args[3] == "x86"):
    arch_def="i?86"
else:
    arch_def=args[3]
    
desclist = {}
for file in fild_all_files2(dest_dir):
    #print(file)
    if fnmatch.fnmatch(file, '*/00header.desc'):
        continue

    if fnmatch.fnmatch(file, '*.desc'):
        srcpath=os.path.dirname(file)
        srcfile=os.path.basename(file)
        # print(srcpath)
        # print(srcfile)
        base = srcfile.replace('.desc', '')
        desclist[base] = srcpath

#print(desclist)

for file in fild_all_files(source_dir):
    if fnmatch.fnmatch(file, '*-*-'+arch_def+'-*.txz') or fnmatch.fnmatch(file, '*-*-noarch-*.txz'):
        #print(file)
        errflag = False

        srcpath=os.path.dirname(file)
        srcfile=os.path.basename(file)
        basepath=srcpath.replace(source_dir, '')

        (base, vers, p_arch, tmp) = srcfile.split('-')
        (build, ext) = tmp.split('.')

        dstpath=desclist.get(base)

        # コピー先のディレクトリが存在しない時にはワーニングメッセージ skip ....
        if dstpath == None:
            print("skip (no dest dir): "+srcfile)
            errflag = True
            continue

        # 同じベースネームのファイル名のファイルが存在すればワーニングメッセージ
        files = os.listdir(dstpath)
        #print(files)
        for f in files:
            if fnmatch.fnmatch(f, '*-*-'+arch_def+'-*.txz') or fnmatch.fnmatch(f, '*-*-noarch-*.txz'):
                print("skip (file exists): "+dstpath+'/'+f)
                errflag = True
                continue

        # ファイルコピー
        if errflag == False:
            print("copy: "+file+' -> '+dstpath)
            shutil.copy2(file, dstpath)
            pathlib.Path(dstpath+'/00.make.log').touch()
