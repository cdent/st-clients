import NLWSOAP.*;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CharacterCodingException;

public class Main {
    static final String new_page_name = "TGV to M\u00FClhausen";
    static final String new_page_content =
        "You can take the Train \u00E1 Gran Vitesse "
        + "to M\u00FClhausen for \u20AC77.\n";

    public static void print_encoded(String enc, String s)
        throws CharacterCodingException
    {
        CharsetEncoder encoder = Charset.forName(enc).newEncoder();
        byte[] bytes = encoder.encode(CharBuffer.wrap(s + "\n")).array();
        System.out.write(bytes, 0, bytes.length);
    }

    // By default, this uses 'System.out.println', which uses Java's built-in
    // facility to try to discover an appropriate 'default encoding' for your
    // platform.  See http://www.jorendorff.com/articles/unicode/java.html.
    //
    // However, Java often gets this wrong.  For example, regardless of locale
    // settings on OS X, the default encoding is MacRoman.  If you set the
    // property 'stdout_encoding' on the command line (e.g., java
    // -Dstdout_encoding=UTF-8), strings will be thus encoded on stdout.
    public static void println(String s) throws CharacterCodingException {
        String encoding = System.getProperty("stdout_encoding");

        if ((null == encoding) || (encoding.equals(""))) {
            System.out.println(s);
        } else {
            print_encoded(encoding, s);
        }
    }

    public static void main (String[] args) throws Exception {
        NLWSOAPPort nlw = new NLWSOAPServiceLocator().getNLWSOAPPort();

        // Simple way to get the args out of the ant file
        String workspace    = args[0];
        String username     = args[1];
        String password     = args[2];
        String page_name    = args[3];
        String act_as_user  = args[4];

        println("=== HEARTBEAT ===");
        println(nlw.heartBeat());

        // Auth
        String token = nlw.getAuth(username, password, workspace, "");

        // Get a page
        println("=== GET PAGE " + page_name + " ===");
        PageFull page = nlw.getPage(token, page_name, "wikitext");
        String content = page.getPageContent();
        println(content);

        // Set a page
        println("=== SET Page " + page_name + " ===");
        page = nlw.setPage(token, page_name, "this is tensegrity");
        content = page.getPageContent();
        println(content);

        // New page
        println("=== MAKE " + new_page_name + " ===");
        page = nlw.setPage(
            token,
            new_page_name,
            new_page_content
        );
        content = page.getPageContent();
        println(content);

        // Sleep to wait for search
        sleep(10);

        // Search
        println("=== SEARCH tensegrity ===");
        PageMetadata[] searchResults = nlw.getSearch(token, "tensegrity");
        printPageMetadata(searchResults);

        // Recent changes
        println("=== RECENT CHANGES ===");
        PageMetadata[] recentChanges = nlw.getChanges(
                token, "recent changes", 4);
        printPageMetadata(recentChanges);
        
        // Auth as someone else, set a page and see the changes
        String actAsToken = nlw.getAuth(username, password, workspace,
                act_as_user);
        println("=== SET Page " + page_name + " as someone else ===");
        page = nlw.setPage(actAsToken, page_name, "this is eleven");
        content = page.getPageContent();
        println("author: " + new String(page.getAuthor()));
        println(content);

        
    }

    private static void printPageMetadata(PageMetadata[] results)
        throws CharacterCodingException
    {
        for (int i = 0 ; i < results.length; i++) {
            String subject = new String(results[i].getSubject());
            String author  = new String(results[i].getAuthor());
            String date    = new String(results[i].getDate());
            println(subject + " " + author + " " + date);
        }
    }
    
    private static void sleep(int seconds) {
        try {
            Thread.sleep(seconds * 1000);
        }
        catch ( InterruptedException e) {
        }
    }
}

