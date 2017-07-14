#!/usr/bin/python2
# -*- coding: euc-jp -*-

import argparse, os, re, subprocess, urllib2, sys, pickle
import urllib, time, ftplib

PKG_PATH = "/var/log/packages/"

def get_args():
    parser = argparse.ArgumentParser(description="Plamo Linux update "
            "packages check and download")
    parser.add_argument("-v", "--verbose", action="store_true",
            help="verbose messages (not implemented yet)")
    parser.add_argument("-u", "--url",
            help="set URL to download")
    megrp1 = parser.add_mutually_exclusive_group()
    megrp1.add_argument("-d", "--download", action="store_true",
            help="download package(s)")
    megrp1.add_argument("-s", "--dlsubdir", action="store_true",
            help="download package(s) with subdir(s)")
    parser.add_argument("-o", "--downtodir",
            help="directory to save package(s)")
    parser.add_argument("-c", "--category",
            help="set category(ies) to check")
    parser.add_argument("-b", "--blocklist", action="store_false",
            help="ignore block list")
    parser.add_argument("-l", "--localblock",
            help="set pkgname(s) to block")
    megrp2 = parser.add_mutually_exclusive_group()
    megrp2.add_argument("-a", "--autoinstall", action="store_true",
            help="install downloaded package(s) automatically")
    megrp2.add_argument("-i", "--interactive", action="store_true",
            help="install downloaded package(s) interactively")
    parser.add_argument("-r", "--reverse", action="store_true",
            help="find un-selected package(s)")
    return parser.parse_args()

def get_file_confs(conf_file):
    confs = {}
    if os.path.isfile(conf_file):
        lines = open(conf_file, "r").readlines()
        for l in lines:
            if not l.startswith("#"):
                try:
                    (key, val) = l.strip().split("=")
                except ValueError:
                    pass
                else:
                    key = key.strip(" \"'")
                    val = val.strip(" \"'")
                    confs[key] = True if val == "True" \
                            else False if val == "False" else val
    return confs

def url_completion(url):
    if not url.endswith("/"):
        url += "/"      # ǰ�Τ���
    current = "6.x"
    if os.path.isfile("/etc/plamo-release"):
        # format: Plamo Linux release x.y
        info = open("/etc/plamo-release", "r").readline()
        version = info.split(" ")[-1].strip()
    elif os.path.isdir("/usr/lib/setup"):
        # format: /usr/lib/setup/Plamo-x.y
        info = sorted(os.listdir("/usr/lib/setup"))
        version = info[-1].split("-")[-1]
    else:
        print("Cannot find valid version tag.  "
                "Suppose you use Plamo current({})".format(current))
        version = current
    version = re.sub("\..*", ".x", version)
    arch = subprocess.check_output("uname -m".split()).strip()
    arch = "x86" if arch == "i686" else "arm" if arch == "armv7l" else arch
    try:
        urllib2.urlopen(url + "allpkgs.pickle").close()
        return url
    except urllib2.URLError:
        try:
            urllib2.urlopen(url + arch + "/allpkgs.pickle").close()
            return url + arch + "/"
        except urllib2.URLError:
            return url + "Plamo-" + version + "/" + arch + "/"

def get_confs():
    param = get_args()
    confs = {}
    confs["VERBOSE"]    = True             if param.verbose     else False
    confs["URL"]        = param.url        if param.url         else \
                          "http://circle2.org/pub/"
    confs["DOWNLOAD"]   = "linear"         if param.download    else \
                          "subdir"         if param.dlsubdir    else ""
    confs["DOWNTODIR"]  = param.downtodir  if param.downtodir   else ""
    confs["CATEGORY"]   = param.category   if param.category    else ""
    confs["BLOCKLIST"]  = True             if param.blocklist   else False
    confs["LOCALBLOCK"] = param.localblock if param.localblock  else ""
    confs["INSTALL"]    = "auto"           if param.autoinstall else \
                          "manual"         if param.interactive else ""
    confs["REVERSE"]    = True             if param.reverse     else False
    """
    �Ƽ�����ϡ�
    ���� > ������(~/.pkginfo) > �����ƥ�(/etc/pkginfo.conf)
    �ν��ɾ�����롥
    """
    loc_confs = get_file_confs(os.path.expanduser("~/.pkginfo"))
    sys_confs = get_file_confs("/etc/pkginfo.conf")
    for i in confs.keys():
        if i in loc_confs:
            confs[i] = loc_confs[i]
        elif i in sys_confs:
            confs[i] = sys_confs[i]
    """
    ������� Plamo �С������ȥ�����̾���������URL ���䴰���롥
    """
    confs["URL"] = url_completion(confs["URL"])
    """
    ������ǥ֥�å��������ѥå��������ɲä�����������������
    """
    confs["LOCALBLOCK"] = param.localblock if param.localblock else ""
    if "LOCALBLOCK" in loc_confs:
        confs["LOCALBLOCK"] += " " + loc_confs["LOCALBLOCK"]
    if "LOCALBLOCK" in sys_confs:
        confs["LOCALBLOCK"] += " " + sys_confs["LOCALBLOCK"]
    """
    confs["INSTALL"] �����ꤵ��Ƥ���� sudo ����ݤ�ٹ𤹤롥
    """
    if confs["INSTALL"]:
        sys.stderr.write("You need sudo to install package(s).  "
                "Are you sure? [y/N] ")
        s = raw_input().lower()
        if not s or s[0] != "y":
            sys.stderr.write("Interrupted.\n")
            sys.exit()
        confs["DOWNLOAD"] = "subdir"
    return confs

def get_local_pkgs():
    pkglist = {}
    for file in os.listdir(PKG_PATH):
        line = open(PKG_PATH + file, "r").readline()
        try:
            (base, vers, p_arch, build) = line[18:].strip().split("-")
        except ValueError:
            pass
        else:
            pkglist[base] = (vers, p_arch, build)
    return pkglist

def get_ftp_pkgs(confs):
    return pickle.load(urllib2.urlopen(confs["URL"] + "allpkgs.pickle"))

def check_replaces(orig_list, replaces):
    for ck in replaces.keys():
        if ck in orig_list:
            (ver, arch, build) = orig_list[ck]
            del(orig_list[ck])
            orig_list[replaces[ck]] = (ver, arch, build)
    return orig_list

def rev_replaces(replaces):
    rev_list = {}
    for i in replaces.keys():
        rev_list[replaces[i]] = i
    return rev_list

def get_category(pkgs, confs):
    if confs["CATEGORY"]:
        if confs["CATEGORY"] == "all":
            category = ["00_base", "01_minimum", "02_x11", "03_xclassics",
                    "04_xapps", "05_ext", "06_xfce", "07_kde", "08_tex",
                    "09_kernel", "10_lof", "11_mate"]
        else:
            category = []
            for i in confs["CATEGORY"].split():
                category.append(i)
        return category
    """
    �ƥ��ƥ������ɽŪ�ʥѥå������Υꥹ�ȡ������Υѥå�����������
    �ȡ���Ѥߤʤ�С����Υ��ƥ�������򤵤�Ƥ����ȹͤ��롥
    """
    category = ["00_base"]
    reps = {"01_minimum": "gcc",      "02_x11": "xorg_server",
            "03_xclassics": "kterm",  "04_xapps": "firefox",
            "05_ext": "mplayer",      "06_xfce": "xfwm4",
            "07_kde": "kde_baseapps", "08_tex": "ptexlive",
            "09_kernel": "kernelsrc", "10_lof": "libreoffice_base",
            "11_mate": "mate_desktop"}
    for i in sorted(reps.keys()):
        if reps[i] in pkgs:
            category.append(i)
    return category

def download_file_url(url, file):
    opener = urllib.FancyURLopener()
    fi = opener.open(url)
    for l in str(fi.info()).splitlines():
        if "content-length: " in l.lower():
            fsize = int(l[16:])
        elif "last-modified: " in l.lower():
            mtime = l[15:]
    count = 0
    data = fi.read(1024)
    sys.stdout.write("[ %10d / %10d ]" % (0, fsize))
    sys.stdout.flush()
    with open(file, "w") as fo:
        while data:
            fo.write(data)
            count += len(data)
            data = fi.read(1024)
            sys.stdout.write("\r[ %10d / %10d ]" % (count, fsize))
            sys.stdout.flush()
    sys.stdout.write("\n")
    fi.close()
    return time.strptime(mtime, "%a, %d %b %Y %H:%M:%S GMT")

def download_file_ftp(host, path, file):
    ftp = ftplib.FTP(host)
    ftp.login()
    ftp.cwd(path)
    ftp.sendcmd("TYPE I")
    fsize = ftp.size(file)
    mtime = ftp.sendcmd("MDTM %s" % file)[4:18]
    count = [0]
    sys.stdout.write("[ %10d / %10d ]" % (0, fsize))
    sys.stdout.flush()
    with open(file, "w") as fo:
        def callback(data):
            fo.write(data)
            if count[0] < fsize:
                count[0] += 1024
            if count[0] > fsize:
                count[0] = fsize
            sys.stdout.write("\r[ %10d / %10d ]" % (count[0], fsize))
            sys.stdout.flush()
        ftp.retrbinary("RETR %s" % file, callback, blocksize=1024)
    sys.stdout.write("\n")
    ftp.quit()
    return time.strptime(mtime, "%Y%m%d%H%M%S")

def download_file(urlbase, subpath, file):
    print("downloading: {}".format(file))
    if urlbase.split(":")[0] == "ftp":
        path = "/".join(urlbase.split("/")[3:]) + "/".join(subpath.split("/"))
        st = download_file_ftp(urlbase.split("/")[2], path, file)
    else:
        st = download_file_url("{}{}/{}".format(urlbase, subpath, file), file)
    mtime = time.mktime(st) - time.timezone
    os.utime(file, (mtime, mtime))

def prepare_subdir(urlbase, topdir, subdir):
    for dir in subdir.split("/"):
        topdir += "/" + dir
        if not os.path.isdir(dir):
            os.makedirs(dir)
            os.chdir(dir)
            if dir == subdir.split("/")[0]:
                cat = dir[3:] if "_" in dir else dir
            else:
                cat = dir[:-4] if "." in dir else dir
            download_file(urlbase, topdir, "disk" + cat)
            download_file(urlbase, topdir, "edisk" + cat)
        else:
            os.chdir(dir)

def download_pkg(urlbase, subpath, pkgname, confs):
    if confs["DOWNTODIR"]:
        if not os.path.isdir(confs["DOWNTODIR"]):
            os.makedirs(confs["DOWNTODIR"])
        os.chdir(confs["DOWNTODIR"])
    if confs["DOWNLOAD"] == "subdir":
        topdir = "/".join(subpath.split("/")[:1])
        subdir = "/".join(subpath.split("/")[1:])
        prepare_subdir(urlbase, topdir, subdir)
    download_file(urlbase, subpath, pkgname)
    return os.getcwd()

def install_pkg(pkgname, ftp_pkgs, rev_list, confs):
    base = pkgname.split("-")[0]
    if base in ftp_pkgs["__no_install"]:
        print("{} needs some tweaks to install.  "
                "Auto installation skipped.".format(base))
        return False
    if base in rev_list:
        if confs["INSTALL"] == "manual":
            sys.stderr.write("Remove {}? [y/N] ".format(rev_list[base]))
            s = raw_input().lower()
            if not s or s[0] != "y":
                sys.stderr.write("Skipped.\n")
                return False
        print("removing {}".format(rev_list[base]))
        cmd = "sudo /sbin/removepkg {}".format(rev_list[base])
        print("invoking: {}".format(cmd))
        print(subprocess.check_call(cmd.split()))
    if confs["INSTALL"] == "manual":
        sys.stderr.write("Install {}? [y/N] ".format(base))
        s = raw_input().lower()
        if not s or s[0] != "y":
            sys.stderr.write("Skipped.\n")
            return False
    print("installing: {}".format(pkgname))
    cmd = "sudo /sbin/updatepkg -f {}".format(pkgname)
    print("invoking: {}".format(cmd))
    return subprocess.check_call(cmd.split())

def main():
    confs = get_confs()
    """
    local_pkgs: ���δĶ��˥��󥹥ȡ���Ѥߥѥå������Υꥹ��
    ftp_pkgs: FTP�����о�ˤ���ѥå������Υꥹ��
    """
    local_pkgs = get_local_pkgs()
    ftp_pkgs = get_ftp_pkgs(confs)
    """
    -b ���ץ�������ꤷ�ƥ֥�å��ꥹ�Ȥ����������⡤�󥤥󥹥ȡ�
    ��ꥹ��(ftp_pkgs["__no_install"])��ͭ���Ǥ���٤��ʤΤǡ������ƥ�
    �Υ֥�å����Ȥ��󥤥󥹥ȡ���ꥹ�Ȥ��ɲä��Ƥ�����
    """
    for i in ftp_pkgs["__blockpkgs"]:
        ftp_pkgs["__no_install"].append(i)
    """
    LOCALBLOCK (--localblock) ���ץ����ǻ��ꤷ���ѥå�����̾��
    blockpkgs ���ɲä��롥
    """
    if confs["LOCALBLOCK"]:
        for i in confs["LOCALBLOCK"].split():
            ftp_pkgs["__blockpkgs"].append(i)
    """
    -b ���ץ�������ꤷ�ʤ���С��֥�å��ꥹ�Ȥ˻��ꤷ���ѥå�����
    (ftp_pkgs["__blockpkgs"])��ɽ�����ʤ�(= local_pkgs �ꥹ�Ȥ������)
    """
    if confs["BLOCKLIST"] and not confs["REVERSE"]:
        for bp in ftp_pkgs["__blockpkgs"]:
            if bp in local_pkgs:
                del(local_pkgs[bp])
            if bp in ftp_pkgs:
                del(ftp_pkgs[bp])
    """
    ��̾�����ѥå����������פ��뤿��ν�����ftp_pkgs["__replaces"] �ˤϡ�
    ��������ѥå������� replace_list["old_name"] = "new_name" �Ȥ�����
    �����äƤ��ꡤcheck_replaces() �ǡ�local_pkgs["old_name"] ��
    local_pkgs["new_name"] = (ver, arch, build) �η����Ȥ�ľ����
    ftp_pkgs["new_name"] ����Ӥ��ƹ����оݤˤ��롥
    ���κݡ�local_pkgs �� old_name �ϼ��ʤ���Τǡ�ɽ���Ѥ�
    replace_list[] ��հ����ˤ��� rev_list[] ��Ȥ���
    """
    check_pkgs = check_replaces(local_pkgs, ftp_pkgs["__replaces"])
    rev_list = rev_replaces(ftp_pkgs["__replaces"])
    if confs["REVERSE"]:
        not_installed = []
        for i in ftp_pkgs.keys():
            if i in ["__blockpkgs", "__replaces", "__no_install"]:
                continue
            if not check_pkgs.has_key(i):
                (ver, p_arch, build, ext, path) = ftp_pkgs[i]
                pkgname = "{}-{}-{}-{}.{}".format(i, ver, p_arch, build, ext)
                path_list = "{}/{}".format(path, pkgname).split("/")[1:]
                not_installed.append((path_list, path, pkgname))
        print("un-selected package(s):")
        """
        ���ƥ��꡼�̤ˡ����ƥ��꡼��Υѥå������� Plamo ���󥹥ȡ��餬
        ���󥹥ȡ��뤹����֤˥����Ȥ���ɽ�����롥
        """
        print("category: {}".format(sorted(not_installed)[0][0][0]))
        ct_prev = sorted(not_installed)[0][0][0]
        for i in sorted(not_installed):
            if i[0][0] != ct_prev:
                print("category: {}".format(i[0][0]))
            ct_prev = i[0][0]
            print("\t{}".format("/".join(i[0][1:])))
        return
    category = get_category(local_pkgs, confs)
    need_install = []
    for i in ftp_pkgs.keys():
        if i in ["__blockpkgs", "__replaces", "__no_install"]:
            continue
        (ver, p_arch, build, ext, path) = ftp_pkgs[i]
        if confs["CATEGORY"]:
            if path.split("/")[1] not in category:
                continue
        else:
            if not (path.split("/")[1] in category or check_pkgs.has_key(i)):
                continue
        if not check_pkgs.has_key(i) or check_pkgs[i] != (ver, p_arch, build):
            pkgname = "{}-{}-{}-{}.{}".format(i, ver, p_arch, build, ext)
            path_list = "{}/{}".format(path, pkgname).split("/")[1:]
            need_install.append((path_list, path, pkgname))
    for i in sorted(need_install):
        base = i[2].split("-")[0]
        (ver, p_arch, build, ext, path) = ftp_pkgs[base]
        if not check_pkgs.has_key(base):
            pkgname = "{}-{}-{}-{}".format(base, ver, p_arch, build)
            print("** {} should be a new package in {} category."
                    .format(pkgname, path.split("/")[1]))
        elif base in rev_list:
            (local_ver, local_arch, local_build) = check_pkgs[base]
            print("** local package: {}-{}-{}-{} was renamed to"
                    .format(rev_list[base], local_ver, local_arch, local_build))
            print("** new   package: {}-{}-{}-{}".format(base, ver, p_arch,
                    build))
            print("** You should manually remove old package "
                    "(# removepkg {}) to update new one."
                    .format(rev_list[base]))
        else:
            (local_ver, local_arch, local_build) = check_pkgs[base]
            print("local package: {}-{}-{}-{}"
                    .format(base, local_ver, local_arch, local_build))
            print("new   package: {}-{}-{}-{}"
                    .format(base, ver, p_arch, build))
        print("URL: {}{}/{}".format(confs["URL"], i[1], i[2]))
        if confs["DOWNLOAD"]:
            cwd = os.getcwd()
            mwd = download_pkg(confs["URL"], i[1], i[2], confs)
            if confs["INSTALL"]:
                print(install_pkg(i[2], ftp_pkgs, rev_list, confs))
            if mwd != cwd:
                os.chdir(cwd)
        print("")

if __name__ == "__main__":
    main()
