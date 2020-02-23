#!/usr/bin/python
# coding=euc-jp

# Select connection (for X)

PPPDIR = u'/etc/ppp'
CONFDIR = PPPDIR + u'/peers'
DEFNAME = u'default'
DEFCOMM = unicode("標準の接続", 'euc-jp')

ERRTITLE = u"ERROR"
ERRMSG = unicode("PPP がインストールされていません。", 'euc-jp')
SELTITLE = unicode("PPP 接続", 'euc-jp')
SELMSG = unicode("接続を選択してください。", 'euc-jp')

import os
import stat
import sys
import re

if os.environ.has_key('DISPLAY') and os.environ['DISPLAY']:
	if not sys.modules.has_key('gtk'):
		try:
			import pygtk
			pygtk.require('2.0')
		except ImportError:
			pass
	import gtk
	import pango
	import gobject
	gtk.rc_parse(os.path.expanduser('~/.gtkrc-2.0'))
else:
	sys.stderr.write("Error: cannot open display!\n")
	sys.exit(1)

class Dialog:
	def __init__(self, title, use_cancel):
		self.status = 1

		self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
		self.window.set_title(title)
		self.window.set_wmclass("xpppselect", "Xpppselect")
		self.window.set_border_width(5)
		self.window.set_resizable(False)
		self.window.connect("destroy", gtk.main_quit)

		self.vbox = gtk.VBox(spacing = 3)
		self.window.add(self.vbox)

		box = gtk.HButtonBox()
		box.set_layout(gtk.BUTTONBOX_SPREAD)
		box.set_spacing(5)
		self.vbox.pack_end(box)

		self.ok_button = gtk.Button(u'OK')
		self.ok_button.connect_after("clicked", self.ok)
		box.pack_start(self.ok_button)
		self.ok_button.show()

		if use_cancel:
			self.cancel_button = gtk.Button(u'Cancel')
			self.cancel_button.connect_after("clicked", self.cancel)
			box.pack_start(self.cancel_button)
			self.cancel_button.show()

		box.show()
		self.vbox.show()

	def ok(self, *args):
		self.status = 0
		self.window.destroy()

	def cancel(self, *args):
		self.status = 1
		self.window.destroy()

	def add(self, w, expand = False):
		self.vbox.pack_start(w, expand)

	def show(self):
		self.window.show()
		self.window.window.set_decorations(gtk.gdk.DECOR_TITLE |
										   gtk.gdk.DECOR_BORDER)

	def run_modal(self):
		self.window.grab_add()
		try:
			gtk.main()
		except KeyboardInterrupt:
			pass

		return self.status

class Msgbox(Dialog):
	def __init__(self, title, msg):
		Dialog.__init__(self, title, False)

		w = gtk.Label(msg)
		self.add(w)
		w.show()

		self.show()

class Menubox(Dialog):
	def __init__(self, title, msg, max, default, default_comment, entries):
		self.select = None

		model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING)
		for entry in entries:
			if entry.name == default:
				iter = model.prepend()
				if entry.comment:
					comment = entry.comment + u' (%s)' % default_comment
				else:
					comment = default_comment
			else:
				iter = model.append()
				comment = entry.comment
			model.set_value(iter, 0, entry.name)
			model.set_value(iter, 1, comment)

		Dialog.__init__(self, title, True)
		self.ok_button.connect("clicked", self.set_select)

		w = gtk.Label(msg)
		self.add(w)
		w.show()

		swin = gtk.ScrolledWindow()
		total = len(entries)
		if total > max:
			rows = max
			scroll = True
		else:
			rows = total
			scroll = False
		swin.set_policy(gtk.POLICY_NEVER, gtk.POLICY_NEVER)
		swin.set_shadow_type(gtk.SHADOW_ETCHED_IN)
		self.add(swin, True)

		tree = gtk.TreeView(model)
		tree.set_headers_visible(False)
		tree.connect("row-activated", self.activate)
		swin.add(tree)

		self.selection = tree.get_selection()
		self.selection.set_mode(gtk.SELECTION_SINGLE)
		margin = tree.get_style().ythickness

		col = gtk.TreeViewColumn("", gtk.CellRendererText(), text = 0)
		col.set_resizable(True)
		col.set_sizing(gtk.TREE_VIEW_COLUMN_AUTOSIZE)
		tree.append_column(col)

		col = gtk.TreeViewColumn("", gtk.CellRendererText(), text = 1)
		col.set_resizable(True)
		col.set_sizing(gtk.TREE_VIEW_COLUMN_AUTOSIZE)
		tree.append_column(col)

		tree.show()
		swin.show()

		full = swin.size_request()[1]
		swin.set_size_request(-1, full / total * rows + margin)
		if scroll:
			swin.set_policy(gtk.POLICY_NEVER, gtk.POLICY_ALWAYS)

		self.show()

	def set_select(self, *args):
		selected = self.selection.get_selected()
		if selected:
			store, iter = selected
			self.select = store.get_value(iter, 0)

	def activate(self, *args):
		self.set_select()
		if self.select:
			self.ok()

	def run_modal(self):
		if Dialog.run_modal(self):
			return None
		else:
			return self.select

class Param:
	def __init__(self, name, initval):
		self.regex = re.compile('^#:' + name +
								'=(?:(["\'])(.*?)\\1|([^"\'].*))$')
		self.oldval = initval

	def parse(self, line):
		m = self.regex.match(line)
		if m:
			self.oldval = m.group(2) or m.group(3)
		return self.oldval

class Config:
	def __init__(self, dir, name):
		self.name = name
		self.comment = ''
		self.hidden = 'Off'

		ignore = re.compile('(~|\.(orig|bak))$')
		if ignore.search(name):
			self.name = None
			self.comment = None
			return

		comment = Param('COMMENT', self.comment)
		hidden = Param('HIDDEN', self.hidden)
		try:
			f = None
			f = open(dir + u'/' + name)
			for line in [unicode(l, 'euc-jp') for l in f.readlines()]:
				self.comment = comment.parse(line)
				self.hidden = hidden.parse(line)
			f.close()
		except OSError:
			self.name = None
			self.comment = None
			if f:
				f.close()
			return

	def isvalid(self):
		if self.name and self.hidden != 'On':
			return True
		else:
			return False

def main():
	try:
		st = os.stat(PPPDIR)
	except OSError:
		st = None
	if not st or not stat.S_ISDIR(st.st_mode):
		Msgbox(ERRTITLE, ERRMSG).run_modal()
		sys.exit(1)

	try:
		files = os.listdir(CONFDIR)
		files.sort()
	except OSError:
		files = []
	configs = filter(Config.isvalid, [Config(CONFDIR, name) for name in files])

	if not configs:
		sys.exit(0)

	if len(configs) == 1:
		print configs[0].name.encode('euc-jp')
		sys.exit(0)

	select = Menubox(SELTITLE, SELMSG, 16,
					 DEFNAME, DEFCOMM, configs).run_modal()

	if not select:
		sys.exit(1)

	print select.encode('euc-jp')
	sys.exit(0)

##
main()

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# py-indent-offset: 4
