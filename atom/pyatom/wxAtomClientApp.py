#!/usr/bin/env python
#Boa:App:BoaApp

__author__ = "Joe Gregorio <http://bitworking.org/>"
__version__ = "Revision: 1.00"
__copyright__ = "Copyright (c) 2003 Joe Gregorio"
__license__ = """All Rights Reserved"""


from wxPython.wx import *

import wxAtomClientFrame

modules ={u'XmlToDictBySAX': [0, '', u'XmlToDictBySAX.py'],
 u'atomClientAPI': [0, '', u'atomClientAPI.py'],
 u'config': [0, '', u'config.xml'],
 u'wxAtomClientFrame': [1,
                        'Main frame of Application',
                        u'wxAtomClientFrame.py']}

class BoaApp(wxApp):
    def OnInit(self):
        wxInitAllImageHandlers()
        self.main = wxAtomClientFrame.create(None)
        # needed when running from Boa under Windows 9X
        self.SetTopWindow(self.main)
        self.main.Show();self.main.Hide();self.main.Show()
        return True

def main():
    application = BoaApp(0)
    application.MainLoop()

if __name__ == '__main__':
    main()
