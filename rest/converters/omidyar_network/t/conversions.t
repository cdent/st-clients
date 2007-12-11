#! /usr/bin/perl
#
# conversions.t
#

use strict;
use warnings;

use Test::More 'no_plan';
use File::Spec::Functions;

my $TMPDIR = $ENV{TEMP} || $ENV{TMP} || '/tmp';

my $TEMP_INPUT_PATHNAME  = catfile($TMPDIR, 'rst2socialtext-conversion-input.tmp');
my $TEMP_OUTPUT_PATHNAME = catfile($TMPDIR, 'rst2socialtext-conversion-output.tmp');

my $CMD_BASE = ''
    . './bin/run-prest'
    . ' -W page-prefix=xyz-'
    . ' -W source-group-name=xyz-example-group'
    . ' -W source-server=http://www.example.com/'
    . ' -w socialtext '
;

=pod

my $CMD_BASE = ''
    . $^X
    . ' -I lib'
    . ' /usr/bin/prest'
    . ' -D generator=0'
    . ' -D date=0'
    . ' -D time=0'
    . ' -D source-link=0'
    . ' -w socialtext '
;

=cut


sub r2s {
#
# Converts the specified string of restructuredText to Socialtext markup, then
# returns the Socialtext markup as a string.
#
    my $rst_text = shift;

    # Open the temporary input file and load it with the restructuredText.
    #
    open my $in_fh, '>', $TEMP_INPUT_PATHNAME
        or die "Unable to open file $TEMP_INPUT_PATHNAME -- $!\n";

    print {$in_fh} $rst_text;

    close $in_fh;

    my $cmdline = $CMD_BASE . " $TEMP_INPUT_PATHNAME >$TEMP_OUTPUT_PATHNAME";

    # diag 'cmdline: ' . $cmdline;

    # Generate the output using the prest command.
    #
    system($cmdline);

    # Open the output file and read it into a string.
    #
    open my $out_fh, '<', $TEMP_OUTPUT_PATHNAME
        or die "Unable to open file $TEMP_OUTPUT_PATHNAME -- $!\n";

    my $stm_text = do { local $/; <$out_fh>; };

    close $out_fh;

    # Clean up.
    #
    unlink $TEMP_INPUT_PATHNAME;
    unlink $TEMP_OUTPUT_PATHNAME;

    return $stm_text;
}


sub trim_newlines {
    my $string = shift;

    $string =~ s/^\n+//;
    $string =~ s/\n+$//;

    return $string;
}


sub check {
#
# Calls Test::More::is() with the converted reST markup and the specified
# Socialtext markup. Cleans up leading and trailing newlines, to make
# some comparisons easier.
#
    my $r = shift; # source restructuredText
    my $s = shift; # expected Socialtext markup
    my $message = shift;

    my $stm_text = r2s($r);

    $stm_text = trim_newlines($stm_text);
    $s        = trim_newlines($s);

    is( $stm_text, $s, $message);
}


## Main

# XXX: Add tests for markup within markup.
#
# XXX: How to best deal with (accidental) Socialtext markup within
#      reST?

my $r; # restructuredText markup
my $s; # Socialtext markup

check('', '',                                           'empty string');
check('unadorned text'      ,   'unadorned text'    ,   'unadorned text');
check('*italicized text*'   ,   '_italicized text_' ,   'italics');
check('**bold text**'       ,   '*bold text*'       ,   'bold');
check('`interpreted text`'  ,   '`interpreted text`',   'interpreted text');

check(
    'string with an ``inline **literal** with *markup*``',
    'string with an {{inline **literal** with *markup*}}',
    'inline markup'
);

#########################

$r = <<END_R;
First paragraph.

Second paragraph.
END_R

$s = <<END_S;
First paragraph.

Second paragraph.
END_S

check($r, $s, 'two paragraphs');

#########################

$r = q(
This is a normal, unindented paragraph. It wraps
across multiple lines.

  This is an indented paragraph. It also wraps across
  multiple lines.

      This paragraph is even more
      indented, and wraps across even
      more lines.

Now we're back to a regular unindented paragraph.
);

$s = q(
This is a normal, unindented paragraph. It wraps across multiple lines.

>This is an indented paragraph. It also wraps across multiple lines.
>
>>This paragraph is even more indented, and wraps across even more lines.

Now we're back to a regular unindented paragraph.
);

check($r, $s, 'indented paragraphs');

#########################

$r = q(
1. First item

2. Second item

3. Third item
);

$s = q(
# First item

# Second item

# Third item
);

check($r, $s, 'simple enumerated list');

#########################

$r = q(
- Item one

- Item two

- Item three
);

$s = q(
* Item one

* Item two

* Item three
);

check($r, $s, 'simple bullet list');

#########################

$r = q(
- Item one

  - Item one sub one

- Item two

  - Item two sub one

    - Item two sub one sub one

- Item three
);

$s = q(
* Item one

** Item one sub one

* Item two

** Item two sub one

*** Item two sub one sub one

* Item three
);

check($r, $s, 'nested bullet list');

#########################

=pod

$r = q(
1. Item one

2. Item two

  a. Item two, subitem one
  b. Item two, subitem two

3. Item three, wrapped across
   multiple lines.

    1. three one

        1. three one one

    2. three two
    3. three three
);

$s = q(
# Item one

# Item two

## Item two, subitem one
## Item two, subitem two

# Item three, wrapped across multiple lines.

## three one

### three one one

## three two
## three three
);

check($r, $s, 'nested enumerated list');

=cut


#########################

# XXX: Make sure to deal with document title and subtitle. From the spec:
#
# The title of the whole document is distinct from section titles and may be
# formatted somewhat differently (e.g. the HTML writer by default shows it as a
# centered heading).
#
# To indicate the document title in reStructuredText, use a unique adornment
# style at the beginning of the document. To indicate the document subtitle,
# use another unique adornment style immediately after the document title.
#

$r = q(
This is the top of the document.

Level 1
=======

Content for level 1

Level 2
-------

Content for level 2

Level 3
~~~~~~~

Content for level 3

Back to level 1
===============

Content for the return to level 1
);

$s = q(
This is the top of the document.

^ Level 1

Content for level 1

^^ Level 2

Content for level 2

^^^ Level 3

Content for level 3

^ Back to level 1

Content for the return to level 1
);

check($r, $s, 'section header levels');

#########################

$r = q(
.. contents ::

The First Section
=================

Contents of the first section.

The second section
------------------

Contents of the second section.

);

$s = q(
{toc}

^ The First Section

Contents of the first section.

^^ The second section

Contents of the second section.
);

check($r, $s, 'simple table of contents');

#########################

$r = q(
.. contents :: This is the Table of Contents

The First Section
=================

Contents of the first section.

The second section
------------------

Contents of the second section.
);

$s = q(
*This is the Table of Contents*

{toc}

^ The First Section

Contents of the first section.

^^ The second section

Contents of the second section.
);

check($r, $s, 'table of contents with label');

#########################

$r = q(
Normal paragraph.

::

    Literal block. No **markup** is processed within
    this block.

    Another paragraph within the literal block.

Trailing normal paragraph.
);

$s = q(
Normal paragraph.

.pre
Literal block. No **markup** is processed within
this block.

Another paragraph within the literal block.

.pre

Trailing normal paragraph.
);

check($r, $s, 'literal block');

#########################

# XXX: These blocks are *very* indentation-sensitive,
# so much so that I think there may be a bug in the reST parser.
# For now, I'm not going to dig too deeply, but it may be an
# issue for actual documents (and if so, I'll revisit).

$r = q(
Normal paragraph

.. RAW :: HTML

   <TABLE>
   <TR><TD>Col 1</TD><TD>Col 2</TD></TR>
   <TR><TD>Name 1</TD><TD>Phone 1</TD></TR>
   </TABLE>

Normal paragraph.

.. RAW :: sushi

   This isn't really anything, but it should come through as a pre block,
   instead of as HTML.

Normal paragraph.
);

$s = q(
Normal paragraph

.html
<TABLE>
<TR><TD>Col 1</TD><TD>Col 2</TD></TR>
<TR><TD>Name 1</TD><TD>Phone 1</TD></TR>
</TABLE>
.html

Normal paragraph.

.pre
This isn't really anything, but it should come through as a pre block,
instead of as HTML.
.pre

Normal paragraph.
);

check($r, $s, 'raw blocks');

#########################

$r = q(
Normal paragraph.

A quoted block::

> Here's the beginning of a quote.
>> Here's a quote of a quote.
>>> A quote of a quote of a quote.
>
> Just a quote.

Normal paragraph.
);

$s = q(
Normal paragraph.

A quoted block:

.pre
> Here's the beginning of a quote.
>> Here's a quote of a quote.
>>> A quote of a quote of a quote.
>
> Just a quote.

.pre

Normal paragraph.
);

check($r, $s, 'quoted block');

#########################

# Note the the number of dashes -- five for reST, four for ST.

$r = q(
Before the transition.

-----

After the transition.
);

$s = q(
Before the transition.

----

After the transition.
);

check($r, $s, 'transition');

#########################

$r = q(
Normal paragraph.

.. sidebar :: This is the sidebar title

  This is a sidebar.

  Here's another line in the sidebar. Sidebars can contain other things, like lists.

  - Item 1 in the sidebar

  - Item 2 in the sidebar

Normal paragraph.
);

$s = q(
Normal paragraph.

----

*This is the sidebar title*

>This is a sidebar.
>
>Here's another line in the sidebar. Sidebars can contain other things, like lists.
>
>* Item 1 in the sidebar
>
>* Item 2 in the sidebar

----

Normal paragraph.
);

check($r, $s, 'simple sidebar');

#########################

$r = q(
Normal paragraph.

.. sidebar :: This is the sidebar title

  This is the first paragraph in the sidebar.

  This is the second paragraph in the sidebar.

Normal paragraph.
);

$s = q(
Normal paragraph.

----

*This is the sidebar title*

>This is the first paragraph in the sidebar.
>
>This is the second paragraph in the sidebar.

----

Normal paragraph.
);

check($r, $s, 'sidebar');

#########################

$r = q(
Normal paragraph.

.. admonition:: This is the admonition label

    Here's the text of the admonition. It can extend over
    multiple lines.

    It can contain multiple paragraphs.

Normal paragraph.
);

$s = q(
Normal paragraph.

----

*This is the admonition label*

>Here's the text of the admonition. It can extend over multiple lines.
>
>It can contain multiple paragraphs.

----

Normal paragraph.
);

check($r, $s, 'admonition');

#########################

# XXX: According to the reST spec, "Any text immediately following the
# directive indicator (on the same line and/or indented on following lines) is
# interpreted as a directive block and is parsed for normal body elements."
#
# In other words, text after the :: should become part of the text that follows.
# It's not a title (as it is for sidebars, for example). However, it doesn't look
# like Text::Restructured handles this properly, so I don't attempt to handle
# it, either.
#

for my $admonition (qw(
    attention
    caution 
    danger  
    error   
    hint    
    important
    note    
    tip     
    warning 
)) {

    my $admonition_label = uc($admonition);

    $r = qq(
Normal paragraph.

.. ${admonition}::

    Here's the text of the $admonition. It can extend over
    multiple lines.

    It can contain multiple paragraphs.

Normal paragraph.
);

    $s = qq(
Normal paragraph.

----

*${admonition_label}*

>Here's the text of the $admonition. It can extend over multiple lines.
>
>It can contain multiple paragraphs.

----

Normal paragraph.
);

    check($r, $s, "$admonition admonition");
}


#########################

$r = q(
Normal paragraph.

.. line-block::

    Line One
    Line Two
    Line Three

    Line Five
    Line Six
    Line Seven

Normal paragraph.
);

$s = q(
Normal paragraph.

----

Line One
Line Two
Line Three

Line Five
Line Six
Line Seven

----

Normal paragraph.
);

check($r, $s, 'line block');

#########################

$r = q(
Simple external hyperlink, like Python_

.. _Python: http://www.python.org/ 
);

$s = q(
Simple external hyperlink, like "Python"<http://www.python.org/>
);

check($r, $s, 'simple external hyperlink');

#########################

$r = q(
Phrase external hyperlink, like `the Python website`_

.. _the Python website: http://www.python.org/
);

$s = q(
Phrase external hyperlink, like "the Python website"<http://www.python.org/>
);

check($r, $s, 'phrase external hyperlink');

#########################

$r = q(
Simple external hyperlink with embedded URI, like `Python <http://www.python.org/>`_.
);

$s = q(
Simple external hyperlink with embedded URI, like "Python"<http://www.python.org/> .
);

check($r, $s, 'simple external hyperlink with embedded URI');

#########################

$r = q(
Normal paragraph.

Titles are targets, too
=======================

Implicit references, like `Titles are targets, too`_.

Normal paragraph.
);

$s = q(
Normal paragraph.

^ Titles are targets, too

Implicit references, like {link: Titles are targets, too} .

Normal paragraph.
);

check($r, $s, 'implicit reference to title');

#########################

$r = q(
Simple inline hyperlink to http://www.example.com.
);

$s = q(
Simple inline hyperlink to http://www.example.com.
);

check($r, $s, 'simple inline hyperlink');

#########################

$r = q(
Normal paragraph.

`This doesn't have a predefined target`_ so it should resolve to an internal link.

Normal paragraph.
);

$s = q(
Normal paragraph.

"This doesn't have a predefined target"[this-doesn-t-have-a-predefined-target] so it should resolve to an internal link.

Normal paragraph.
);

check($r, $s, 'hyperlinks - untargeted, resolved to internal link');

#########################

$r = q(
Simple inline email address, like someone@example.com
);

$s = q(
Simple inline email address, like someone@example.com
);

check($r, $s, 'simple inline email address');

#########################

$r = q(
Start of document

Python_ is `a programming language`__.
And Perl_ is `another one`__.

__ Python_

__ Perl_

.. _Python: http://www.python.org/

.. _Perl: http://www.perl.org/

End of document
);

    $s = q(
Start of document

"Python"<http://www.python.org/>  is "a programming language"<http://www.python.org/> . And "Perl"<http://www.perl.org/>  is "another one"<http://www.perl.org/> .

End of document
);

check($r, $s, 'hyperlinks - anonymous');


#########################

$r = q(
Normal paragraph.

.. image :: http://external.example.com/someimage.png

Normal paragraph.
);

$s = q(
Normal paragraph.

<http://external.example.com/someimage.png>

Normal paragraph.
);

check($r, $s, 'simple external image');

#########################

$r = q(
Normal paragraph.

.. image:: http://www.example.com/group/xyz-example-group/file/12345/someimage.png

Normal paragraph.
);

$s = q(
Normal paragraph.

{image: someimage.png}

Normal paragraph.
);

check($r, $s, 'simple internal image');


#########################

$r = q(
Normal paragraph.

.. figure:: http://internal.example.com/someimage.png

   This is the caption for the figure.

   This is the legend for the figure.

Normal paragraph.
);

$s = q(
Normal paragraph.

<http://internal.example.com/someimage.png>

This is the caption for the figure.

This is the legend for the figure.

Normal paragraph.
);

check($r, $s, 'figure');

#########################

$r = q(
Normal paragraph.

.. This is a comment.

Normal paragraph.

..

    This is an indented paragraph.

Normal paragraph.
);

$s = q(
Normal paragraph.

.pre
This is a comment.
.pre

Normal paragraph.

>This is an indented paragraph.

Normal paragraph.
);

check($r, $s, 'comments');

#########################


$r = q(
+------------+------------+-----------+
| body row 1 | column 2   | column 3  |
+------------+------------+-----------+
);

$s = q(
| body row 1 | column 2 | column 3 |
);

check($r, $s, 'grid table - single row, no header');

#########################

$r = q(
+------------+------------+-----------+
| Header 1   | Header 2   | Header 3  |
+============+============+===========+
| body row 1 | column 2   | column 3  |
+------------+------------+-----------+
| body row 2 | column 2   | column 3  |
+------------+------------+-----------+
);

$s = q(
| Header 1 | Header 2 | Header 3 |
| body row 1 | column 2 | column 3 |
| body row 2 | column 2 | column 3 |
);

check($r, $s, 'grid table - multiple rows, with header');

#########################

=pod

# Not worried about this one right now.
# The parser doesn't think it's a table, so I officially Don't Care.
#

$r = q(
+------------+------------+-----------+
| Header 1   | Header 2   | Header 3  |
+============+============+===========+
);

$s = q(
| Header 1 | Header 2 | Header 3 |
);

check($r, $s, 'grid table - single row, just header');

=cut

#########################


$r = q(
+------------+
| body row 1 |
+------------+
);

$s = q(
| body row 1 |
);

check($r, $s, 'grid table - single cell, no header');

#########################

$r = q(
Normal paragraph.

=====  =====
  A    not A
=====  =====
False  True
True   False
=====  =====

Normal paragraph.
);

$s = q(
Normal paragraph.

| A | not A |
| False | True |
| True | False |

Normal paragraph.
);

check($r, $s, 'simple table');


#########################

$r = q(
Normal paragraph.

.. table:: Truth table for "not"

   =====  =====
     A    not A
   =====  =====
   False  True
   True   False
   =====  =====

Normal paragraph.
);

$s = q(
Normal paragraph.

*Truth table for "not"*

| A | not A |
| False | True |
| True | False |

Normal paragraph.
);

check($r, $s, 'simple table with title');

#########################

$r = q(
Normal paragraph.

.. csv-table:: 
   :widths: 3,4,3,2,2
   :header: "Wire Date", "Investee", "Amount", "ONFI #", "Fund LLC #" 
   :delim: ;

   02.02.07;Smith Industries;$650,000;1; 
   02.14.07;  Jones Consulting, Inc.;$500,000;2;
   02.14.07;Brown LLC;$280,001;;1
   02.28.07;   XYZ-Incorporated   ; $200,000;;2
   ;;$1,630,001;$1,150,000;$480,001

Normal paragraph.
);

$s = q(
Normal paragraph.

| Wire Date | Investee | Amount | ONFI # | Fund LLC # |
| 02.02.07 | Smith Industries | $650,000 | 1 |  |
| 02.14.07 | Jones Consulting, Inc. | $500,000 | 2 |  |
| 02.14.07 | Brown LLC | $280,001 |  | 1 |
| 02.28.07 | XYZ-Incorporated | $200,000 |  | 2 |
|  |  | $1,630,001 | $1,150,000 | $480,001 |

Normal paragraph.
);

check($r, $s, 'csv table');

#########################

TODO: { local $TODO = 'csv tables with embedded delimiters need Text::CSV_XS support';

$r = q(
Normal paragraph.

.. csv-table::
   :widths: 3,4,3,2,2
   :header: "Wire Date", "Investee", "Amount", "ONFI #", "Fund LLC #" 
   :delim: ,

   02.02.07 , Smith Industries , $650.000 , 1 ,  
   02.14.07 ,   "Jones Consulting, Inc." , $500.000 , 2 , 
   02.14.07 , Brown LLC , $280.001 ,  , 1
   02.28.07 ,    "Lots, and lots, of Commas, Corporation, Inc." ,  $200.000 ,  , 2
    ,  , $1.630.001 , $1.150.000 , $480.001

Normal paragraph.
);

$s = q(
Normal paragraph.

| Wire Date | Investee | Amount | ONFI # | Fund LLC # |
| 02.02.07 | Smith Industries | $650.000 | 1 |  |
| 02.14.07 | Jones Consulting, Inc. | $500.000 | 2 |  |
| 02.14.07 | Brown LLC | $280.001 |  | 1 |
| 02.28.07 | Lots, and lots, of Commas, Corporation, Inc. | $200.000 |  | 2 |
|  |  | $1.630.001 | $1.150.000 | $480.001 |

Normal paragraph.
);

check($r, $s, 'csv table - embedded delimiters');

} # end TODO

#########################

$r = q(
Normal paragraph.

.. csv-table::
   :delim: ,

   1,2,3

Normal paragraph.
);

$s = q(
Normal paragraph.

| 1 | 2 | 3 |

Normal paragraph.
);

check($r, $s, 'csv table - simple');

#########################

$r = q(
Normal paragraph.

.. csv-table::
   :delim: ,

   ,,,1,2,3,,,

Normal paragraph.
);

$s = q(
Normal paragraph.

|  |  |  | 1 | 2 | 3 |  |  |  |

Normal paragraph.
);

check($r, $s, 'csv table - leading and trailing empty cells');

#########################

$r = q(
Normal paragraph.

.. csv-table::
   :delim: ,

   1,2,3,4,5
   1,2,3
   ,

Normal paragraph.
);

$s = q(
Normal paragraph.

| 1 | 2 | 3 | 4 | 5 |
| 1 | 2 | 3 |  |  |
|  |  |  |  |  |

Normal paragraph.
);

check($r, $s, 'csv table - automatic row expansion');

#########################

$r = q(
Normal paragraph

Field list
----------

:Some field: The value of some field.

:Another field: The value of another field.

:Yet Another Field:

    The field value can be a paragraph, too.
    It can extend over multiple lines,
    like this.

This is after the end of the field list.

Normal paragraph
);

$s = q(
Normal paragraph

^ Field list

*Some field:*

>The value of some field.

*Another field:*

>The value of another field.

*Yet Another Field:*

>The field value can be a paragraph, too. It can extend over multiple lines, like this.

This is after the end of the field list.

Normal paragraph
);

check($r, $s, 'field list');

#########################

$r = q(
Definition lists:

what
  Definition lists associate a term with
  a definition.

how
  The term is a one-line phrase, and the
  definition is one or more paragraphs or
  body elements, indented relative to the
  term. Blank lines are not allowed
  between term and definition.
);

$s = q(
Definition lists:

*what*

>Definition lists associate a term with a definition.

*how*

>The term is a one-line phrase, and the definition is one or more paragraphs or body elements, indented relative to the term. Blank lines are not allowed between term and definition.
);

check($r, $s, 'definition list');

#########################

$r = q(
This is an option list:

-a            command-line option "a"
-b file       options can have arguments
              and long descriptions
--long        options can be long also
--input=file  long options can also have
              arguments
/V            DOS/VMS-style options too

-2, --two  This option has two variants.

-f FILE, --file=FILE  These two options are synonyms; both have
                      arguments.

This is after the option list.
);

$s = q(
This is an option list:

`-a`

>command-line option "a"

`-b` _file_

>options can have arguments and long descriptions

`--long`

>options can be long also

`--input`=_file_

>long options can also have arguments

`/V`

>DOS/VMS-style options too

`-2`

`--two`

>This option has two variants.

`-f` _FILE_

`--file`=_FILE_

>These two options are synonyms; both have arguments.

This is after the option list.
);

check($r, $s, 'option list');

#########################

# XXX: Change footnotes and citations to use {section: } syntax.

$r = q(
Normal paragraph.

Footnote references, like [5]_. Footnotes may get rearranged,
e.g., to the bottom of the "page".

There may be paragraphs between the reference and the target.

.. [5] A numerical footnote.

    Footnotes may contain multiple paragraphs.

Normal paragraph.
);

$s = q(
Normal paragraph.

Footnote references, like {link: Footnote 5}. Footnotes may get rearranged, e.g., to the bottom of the "page".

There may be paragraphs between the reference and the target.

Normal paragraph.

----

^^^^^^ Footnote 5

A numerical footnote.

Footnotes may contain multiple paragraphs.
);

check($r, $s, 'footnote - numerical');

#########################

$r = q(
Normal paragraph

Autonumbered footnotes are
possible, like using [#]_ and [#]_.

.. [#] This is the first one.
.. [#] This is the second one.

Normal paragraph
);

$s = q(
Normal paragraph

Autonumbered footnotes are possible, like using {link: Footnote 1} and {link: Footnote 2}.

Normal paragraph

----

^^^^^^ Footnote 1

This is the first one.

^^^^^^ Footnote 2

This is the second one.
);

check($r, $s, 'footnotes - autonumber');

#########################

# XXX: I don't think the label functionality is quite complete, but
# it's good enough for the moment. May just be a problem with in-page
# hyperlinks.
#

$r = q(
Normal paragraph

They may be assigned 'autonumber
labels' - for instance,
[#fourth]_ and [#third]_.

.. [#third] a.k.a. third_

.. [#fourth] a.k.a. fourth_ 

Normal paragraph
);

$s = q(
Normal paragraph

They may be assigned 'autonumber labels' - for instance, {link: Footnote 2} and {link: Footnote 1}.

Normal paragraph

----

^^^^^^ Footnote 1

a.k.a. {link: third}

^^^^^^ Footnote 2

a.k.a. {link: fourth}
);

check($r, $s, 'footnotes - autonumber with labels');

#########################

# XXX: This produces a "wide character in print" warning.
# It's coming from the prest utility itself, so I'm not going to worry
# about suppressing it just yet.
#
$r = q(
Normal paragraph

Auto-symbol footnotes are also
possible, like this: [*]_ and [*]_.

.. [*] This is the first one.
.. [*] This is the second one. 

Normal paragraph
);

$s = q(
Normal paragraph

Auto-symbol footnotes are also possible, like this: {link: Footnote *} and {link: Footnote †}.

Normal paragraph

----

^^^^^^ Footnote *

This is the first one.

^^^^^^ Footnote †

This is the second one.
);

check($r, $s, 'footnotes - autosymbol');


=pod

$r = q(
);

$s = q(
);

check($r, $s, '');

#########################

=cut


=pod



=cut

# end conversions.t
