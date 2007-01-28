import unittest
import atomClientAPI
import StringIO, pprint
from XmlToDictBySAX import convertNodesToDict


ENTRY = """<?xml version="1.0" encoding='utf-8'?>
<entry xmlns="http://purl.org/atom/ns#">
    <title>Unit Test 1</title> 
    <summary>This is what you get</summary> 
    <content type="text/plain" xml:lang="en-us">When you do unit testing.</content>
</entry>"""


class atomClientCreateTest(unittest.TestCase):
    def setUp(self):
        self.interface = atomClientAPI.interface()
        
    def test0(self):
        list = self.interface.getEntryList()
        print list
        self.assert_(len(list) == 10)
        
    def test1(self):
        """Do a simple create of an Entry, then do a GET to confirm
        that the Entry showed up."""
        print "Posting to: %s" % self.interface.postURI
        (status, status_text, location, content) = self.interface.createEntry(ENTRY)
        print status
        print content
        self.assertEqual(status, 201, "Returned the right status code")
        self.assertNotEqual(location, None, "Returned a proper Location header")
        (status, status_text, content) = self.interface.getEntry(location)
        self.assertEqual(status, 200)
        contentDict = convertNodesToDict(StringIO.StringIO(content), 'entry', {'http://purl.org/atom/ns#' : 'at'})
        self.assertEquals(contentDict['at:title'], "UnitTest")
        (status, reason, content) = self.interface.deleteEntry(location)
        print "Reason = %s" % (reason, )
        self.assertEqual(status, 200)
        

if __name__ == "__main__":	
    unittest.main()		

