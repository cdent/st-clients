using System;
using System.Threading;

namespace soapclient

{

  class MainClass

  {

    public static void Main(string[] args)

    {
	if (args.Length < 4) 

	{
		Console.WriteLine("Usage: client.cs <username> <password> <workspace> <page_name>");
		return;
	}


	NLWSOAPService nlw = new NLWSOAPService();

	// Make an auth token to play with

	string token = nlw.getAuth(args[0],args[1],args[2],"");

	// heartBeat, of course
	Console.WriteLine("Welcome to the Socialtext C# Soap Tester!\n");
	Console.WriteLine("=== HEARTBEAT ===");
	string timeInfo = nlw.heartBeat();
	Console.WriteLine(timeInfo);

	// getPage
	Console.WriteLine("\n=== GET PAGE {0} ===",args[3]);
	pageFull getPageResult = nlw.getPage(token, args[3], "wikitext");
	string content = getPageResult.pageContent;
	Console.WriteLine(content);

	// setPage
	Console.WriteLine("=== SET PAGE {0} ===",args[3]);
	pageFull setPageResult = nlw.setPage(token, args[3],
                "this is tensegrity");
	content = setPageResult.pageContent;
	Console.WriteLine(content);

	// sleep to get the ceqlotron in there
	Thread.Sleep(10000);

	// search
	Console.WriteLine("=== SEARCH tensegrity ===");
	pageMetadata[] searchResult = nlw.getSearch(token, "tensegrity");
	string pageSubject = searchResult[0].subject;
	Console.WriteLine("{0} - {1} - {2}", pageSubject,
                searchResult[0].author, searchResult[0].date );

	// recent changes
	Console.WriteLine("\n=== RECENT CHANGES ===");
	pageMetadata[] changesResult = nlw.getChanges(token, "recent changes", 4);
	pageSubject = changesResult[0].subject;
	Console.WriteLine("{0} - {1} - {2}", pageSubject,
                changesResult[0].author, changesResult[0].date);

        // set utf8 page
        string new_page_name = "TGV to M\u00FClhausen";
        string new_page_content =
            "You can take the Train \u00E1 Gran Vitesse " 
            + "to M\u00FClhausen for \u20AC77.\n";

        Console.WriteLine("=== SET PAGE {0} ===", new_page_name);
        setPageResult = nlw.setPage(token, new_page_name,
                new_page_content);
	content = setPageResult.pageContent;
        pageSubject = setPageResult.subject;
        Console.WriteLine(pageSubject);
	Console.WriteLine(content);
    }
  }
}
