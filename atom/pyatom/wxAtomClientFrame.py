#Boa:Frame:wxAtomClient

__author__ = "Joe Gregorio <http://bitworking.org/>"
__version__ = "Revision: 1.00"
__copyright__ = "Copyright (c) 2003 Joe Gregorio"
__license__ = """All Rights Reserved"""


from wxPython.wx import *
import atomClientAPI
import libxml2
from xml.sax.saxutils import escape
import StringIO, sys

def create(parent):
    return wxAtomClient(parent)

[wxID_WXATOMCLIENT, wxID_WXATOMCLIENTCONTENT, wxID_WXATOMCLIENTDELETEBUTTON, 
 wxID_WXATOMCLIENTENTRYLISTBOX, wxID_WXATOMCLIENTSTATICTEXT2, 
 wxID_WXATOMCLIENTSTATICTEXT3, wxID_WXATOMCLIENTSTATICTEXT4, 
 wxID_WXATOMCLIENTTITLE, wxID_WXATOMCLIENTUPDATE, 
] = map(lambda _init_ctrls: wxNewId(), range(9))

class wxAtomClient(wxFrame):
    def _init_utils(self):
        # generated method, don't edit
        self.File = wxMenuBar()

        self.New = wxMenu(title='')

    def _init_ctrls(self, prnt):
        # generated method, don't edit
        wxFrame.__init__(self, id=wxID_WXATOMCLIENT, name=u'wxAtomClient',
              parent=prnt, pos=wxPoint(207, 152), size=wxSize(697, 520),
              style=wxTAB_TRAVERSAL | (wxDEFAULT_FRAME_STYLE | wxTAB_TRAVERSAL ),
              title=u'wxAtomClient')
        self._init_utils()
        self.SetClientSize(wxSize(689, 493))

        self.content = wxTextCtrl(id=wxID_WXATOMCLIENTCONTENT, name=u'content',
              parent=self, pos=wxPoint(208, 72), size=wxSize(456, 376),
              style=wxTE_RICH | wxTE_MULTILINE, value=u'')

        self.title = wxTextCtrl(id=wxID_WXATOMCLIENTTITLE, name=u'title',
              parent=self, pos=wxPoint(208, 24), size=wxSize(456, 21), style=0,
              value=u'')

        self.update = wxButton(id=wxID_WXATOMCLIENTUPDATE, label=u'Create',
              name=u'update', parent=self, pos=wxPoint(496, 456),
              size=wxSize(75, 23), style=0)
        EVT_BUTTON(self.update, wxID_WXATOMCLIENTUPDATE, self.onUpdate)

        self.deleteButton = wxButton(id=wxID_WXATOMCLIENTDELETEBUTTON,
              label=u'Delete', name=u'deleteButton', parent=self,
              pos=wxPoint(584, 456), size=wxSize(75, 23), style=0)
        EVT_BUTTON(self.deleteButton, wxID_WXATOMCLIENTDELETEBUTTON,
              self.OnDelete)

        self.entryListBox = wxListBox(choices=["fred", "barney"],
              id=wxID_WXATOMCLIENTENTRYLISTBOX, name=u'entryListBox',
              parent=self, pos=wxPoint(16, 24), size=wxSize(144, 416), style=0,
              validator=wxDefaultValidator)
        EVT_LISTBOX(self.entryListBox, wxID_WXATOMCLIENTENTRYLISTBOX,
              self.OnEntryListBox)

        self.staticText2 = wxStaticText(id=wxID_WXATOMCLIENTSTATICTEXT2,
              label=u'Title', name='staticText2', parent=self, pos=wxPoint(192,
              8), size=wxSize(20, 13), style=0)

        self.staticText3 = wxStaticText(id=wxID_WXATOMCLIENTSTATICTEXT3,
              label=u'Content', name='staticText3', parent=self,
              pos=wxPoint(192, 56), size=wxSize(37, 13), style=0)

        self.staticText4 = wxStaticText(id=wxID_WXATOMCLIENTSTATICTEXT4,
              label=u'Entries', name='staticText4', parent=self, pos=wxPoint(8,
              8), size=wxSize(32, 13), style=0)

    def __init__(self, parent):
        self._init_ctrls(parent)
        f = self.GetFont()
        f = wxFont(9, f.GetFamily(), f.GetStyle(), wxNORMAL, False, "Arial Unicode MS", wxFONTENCODING_SYSTEM)
        self.content.SetFont(f)
        self.title.SetFont(f)
 
        self.interface = atomClientAPI.interface()
        self.refreshEntryListBox()
        self.currentUrl = None
        
    def reportErrors(self, status, reason, body):
        if status >= 300:
            wxMessageBox(body, str(status) + ": " + reason, wxOK | wxICON_EXCLAMATION)
       
    def refreshEntryListBox(self):
        entryList = self.interface.getEntryList()
        self.entryListBox.Clear()
        self.entryListBox.Append("(new)")
        for uri, title in entryList:
            self.entryListBox.Append(title)
            self.entryListBox.SetClientData(self.entryListBox.GetCount()-1, uri)
        self.clearFields()
        
    def clearFields(self):
        self.title.SetValue('')
        self.content.SetValue('')
        self.currentUrl = None
        self.update.SetLabel("Create")
        self.deleteButton.Enable(False)

    def onUpdate(self, event):
        xml = """<?xml version="1.0" encoding='utf-8'?>   
        <entry xmlns="http://www.w3.org/2005/Atom">
                   <title>%s</title> 
                   <content type="text">%s</content>
                  </entry>""" % (escape(self.title.GetValue().encode('utf-8', 'replace')), escape(self.content.GetValue().encode('utf-8', 'replace')))
        if self.currentUrl == None:
            (status, reason, location, content) = self.interface.createEntry(xml)
        else:
            (status, reason, content) = self.interface.updateEntry(xml, self.currentUrl)
        self.reportErrors(status, reason, content)
        self.refreshEntryListBox()

    def OnEntryListBox(self, event):
        url = self.entryListBox.GetClientData(self.entryListBox.GetSelection())
        if url != None:
            (status, reason, content) = self.interface.getEntry(url)
            if status == 200:
                doc = libxml2.parseDoc(content)
                ctxt = doc.xpathNewContext()
                ctxt.xpathRegisterNs('atom', 'http://www.w3.org/2005/Atom')
                self.title.SetValue(unicode(ctxt.xpathEval('//atom:entry/atom:title')[0].content, "utf-8"))
                self.content.SetValue(unicode(ctxt.xpathEval('//atom:entry/atom:content')[0].content, "utf-8"))
                self.currentUrl = url
                self.update.SetLabel("Update")
                self.deleteButton.Enable(True)
            else:
                self.reportErrors(status, reason, content)
        else:
            self.clearFields()
        

    def OnDelete(self, event):
        if None != self.currentUrl:
            (status, reason, content) = self.interface.deleteEntry(self.currentUrl)
            self.reportErrors(status, reason, content)
            self.refreshEntryListBox()

