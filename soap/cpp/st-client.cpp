// -*- coding: utf-8 -*- vim:fileencoding=utf-8:
#include <iostream>
#include "soapH.h" // obtain the generated stub
#include "NLWSOAPBinding.nsmap" // obtain the generated XML namespace mapping
                                // table for Socialtext's SOAP server
#include <unistd.h>
#include "st-client.h"

// We cheat here by including 8-bit characters in a std::string and not
// telling anybody about it and pretending that we just have 'char *'.  This
// works out OK and is apparently standard practice since the STL is, AFAICT,
// unaware of UTF-8.
//
// Also, we assume that your terminal understands UTF-8.
#define NEW_PAGE_NAME "TGV to Mülhausen"
#define NEW_PAGE_BODY \
    "You can take the Train à Gran Vitesse to Mülhausen for €77.\n"

using namespace std;

string
getAuth(struct soap* soap, string user, string pass, string ws, string act_as)
{
    struct ns1__getAuthResponse key;

    if (soap_call_ns1__getAuth(soap, NULL, NULL, user, pass, ws, act_as, key) 
            != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return key.token;
}

string heartBeat(struct soap* soap) {
    struct ns1__heartBeatResponse res;

    if (soap_call_ns1__heartBeat(soap, NULL, NULL, res) != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return res.heartBeatReturn;
}

ns1__pageFull*
getPage(struct soap* soap, string key, string page, string format) {
    struct ns1__getPageResponse res;

    if (soap_call_ns1__getPage(soap, NULL, NULL, key, page, format, res)
            != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return res.page;
}

ns1__pageFull*
setPage(struct soap* soap, string key, string page, string wikitext) {
    struct ns1__setPageResponse res;

    if (soap_call_ns1__setPage(soap, NULL, NULL, key, page, wikitext, res)
            != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return res.page;
}

ArrayOf_USCOREpageMetadata*
getSearch(struct soap* soap, string key, string query) {
    struct ns1__getSearchResponse res;

    if (soap_call_ns1__getSearch(soap, NULL, NULL, key, query, res)
            != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return res.searchList;
}

ArrayOf_USCOREpageMetadata*
getChanges(struct soap* soap, string key, string category, int count)
{
    struct ns1__getChangesResponse res;

    if (soap_call_ns1__getChanges(soap, NULL, NULL, key, category, count, res)
            != SOAP_OK) {
        soap_print_fault(soap, stderr);
        exit(1);
    }

    return res.changesList;
}

ostream& operator<<(ostream &os, const ArrayOf_USCOREpageMetadata *results) {
    for (size_t ii = 0; ii < results->__size; ++ii) {
        ns1__pageMetadata *pm = (results->__ptr)[ii];

        os << ii << endl
           << pm->subject << " - " << pm->author << " - " << pm->date
           << endl;
    }

    return os;
}


int main(void) {
    struct soap *soap = soap_new();
    // This tells gSOAP not to mangle our 8-bit characters (we have UTF-8
    // Unicode strings here) into 7-bit &#N; entities.
    soap_init2(soap, SOAP_C_UTFSTRING, SOAP_C_UTFSTRING);
    string key;

    cout << endl << "=== HEARTBEAT ===" << endl;
    cout << heartBeat(soap) << endl;

    cout << endl << "=== GET AUTH ===" << endl;
    key = getAuth(soap, ST_USER, ST_PASS, ST_WS, "");
    cout << key << endl;

    cout << endl << "=== MAKE " << NEW_PAGE_NAME << " ===" << endl;
    cout << setPage(soap, key, NEW_PAGE_NAME, NEW_PAGE_BODY)->pageContent
         << endl;

    cout << endl << "=== GET PAGE " << ST_PAGE << " ===" << endl;
    cout << getPage(soap, key, ST_PAGE, "wikitext")->pageContent
         << endl;

    cout << endl << "=== SET PAGE " << ST_PAGE << " ===" << endl;
    cout << setPage(soap, key, ST_PAGE, "this is tensegrity")->pageContent
         << endl;
    sleep(10); // Let the page get indexed.

    cout << endl << "=== SEARCH tensegrity ===" << endl;
    cout << getSearch(soap, key, "tensegrity");

    cout << endl << "=== GET AUTH AS " << ST_OTHER_USER << " ===" << endl;
    key = getAuth(soap, ST_USER, ST_PASS, ST_WS, ST_OTHER_USER);
    cout << key << endl;

    cout << endl
         << "=== SET PAGE "
         << ST_OTHER_PAGE << " AS " << ST_OTHER_USER << " ===" << endl;
    cout << setPage(soap, key, ST_OTHER_PAGE, ST_OTHER_CONTENT)->pageContent
         << endl;

    cout << endl << "=== RECENT CHANGES (4) ===" << endl;
    cout << getChanges(soap, key, "", 4);

    return 0;
}
