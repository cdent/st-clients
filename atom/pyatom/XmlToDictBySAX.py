from xml.sax.handler import ContentHandler
import xml.sax

__author__ = "Joe Gregorio <http://bitworking.org/>"
__version__ = "Revision: 1.00"
__copyright__ = "Copyright (c) 2003 Joe Gregorio"
__license__ = """MIT License"""

class handler(ContentHandler):
    def __init__(self, parent, knownNamespaces, seperator = ":"):
        self.tags={}
        self.path=[""]
        self.knownNamespaces = knownNamespaces
        self.parent = parent
        self.currentElement = ""
        self.seperator = seperator

    def startElementNS(self, (uri, name), qname, attr):
        self.path.append(name)
        if self.path[-2] == self.parent and (uri == None or self.knownNamespaces.has_key(uri)):
            if (uri == None):
                self.currentElement = name
            else:
                self.currentElement = self.knownNamespaces[uri] + self.seperator + name
            self.tags[self.currentElement] = ""

    def characters(self, s):
        if self.currentElement:
            self.tags[self.currentElement] += s

    def endElementNS(self, (uri, name), qname):
        self.path.pop()
        self.currentElement = ""

def convertNodesToDict(file, parentElementName, knownNamespaces = {}, seperator = ":"):
    """Pull out all the child elements of 'parentElementName' and
       return them in a dictionary where the keys are the element names.
       Elements in namespaces besides "" will be ignored unless
       they are included in 'knownNamespaces' which is a dictionary
       that maps the namespace URI to the desired prefix.

       file - The source of the XML can be either a file name or a file stream."""
    parser = xml.sax.make_parser()
    parser.setFeature(xml.sax.handler.feature_namespaces, 1)
    h = handler(parentElementName, knownNamespaces, seperator)
    parser.setContentHandler(h)
    parser.parse(file)
    return h.tags

if __name__ == "__main__":
    import unittest
    import StringIO
    
    class ExerciseConverter(unittest.TestCase):
        def testNameSpaceRenaming(self):
            """Ensure that known namespaces are converted to have the right pre-fix."""
            sampleText = """<?xml version="1.0" ?>
<item xmlns:bc="http://purl.org/dc/elements/1.1/">
  <title>MetaData</title>
  <bc:date>2003-01-12T00:18:05-05:00</bc:date>
  <link>http://bitworking.org/news/8</link>
  <description>&lt;h1>This is a header&lt;/h1></description>
</item>"""
            dict = convertNodesToDict(StringIO.StringIO(sampleText), 'item', {'http://purl.org/dc/elements/1.1/' : 'dc'})
            self.assert_(dict.has_key("dc:date")) 
            self.assert_(dict.has_key("title")) 
            self.assert_(dict.has_key("link")) 
            self.assert_(dict.has_key("description")) 
            self.assertEquals(dict["title"], "MetaData") 
            self.assertEquals(dict["link"], "http://bitworking.org/news/8") 
            self.assertEquals(dict["description"], "<h1>This is a header</h1>") 

        def testDeeperEmbedding(self):
            """Make sure we can find the right stuff in a SOAP envelope"""
            sampleText = """<?xml version="1.0" ?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" >
<soap:Header>  </soap:Header>
  <soap:Body>
    <item xmlns:bc="http://purl.org/dc/elements/1.1/">
      <title>MetaData</title>
      <bc:date>2003-01-12T00:18:05-05:00</bc:date>
      <link>http://bitworking.org/news/8</link>
      <description>&lt;h1>This is a header&lt;/h1></description>
    </item>
  </soap:Body>
</soap:Envelope>
"""
            dict = convertNodesToDict(StringIO.StringIO(sampleText), 'item', {'http://purl.org/dc/elements/1.1/' : 'dc'})
            self.assert_(dict.has_key("dc:date")) 
            self.assert_(dict.has_key("title")) 
            self.assert_(dict.has_key("link")) 
            self.assert_(dict.has_key("description")) 
            self.assertEquals(dict["title"], "MetaData") 
            self.assertEquals(dict["link"], "http://bitworking.org/news/8") 
            self.assertEquals(dict["description"], "<h1>This is a header</h1>") 

    unittest.main()

                      
