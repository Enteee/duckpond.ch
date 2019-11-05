---
layout: post
categories: [test]
keywords: [Design, test]
---

* TOC
{:toc}

---

## <hr>

---

## Images

### Normal

![duck.png](/static/posts/design-test/duck.png)
*This is a duck. Who would have guessed that?*

### Stretched

![duck.png](/static/posts/design-test/duck.png){: .stretch }
*This is a streched duck.*

### Responsive

{%
  responsive_image
  path: static/posts/my-first-moon-image/panorama-processed.png
  caption: 'A hidden because the duck is smaller than the smallest'
%}

### Broken Responsive

{%
  responsive_image
  path: static/posts/design-test/duck.png
  caption: 'Not displayed because the source is smaller than the smallest responsive image'
%}

### Broken link

![this text should show instead of the image](this/is/a/broken/link.png)

## Math

The well known Pythagorean theorem $$x^2 + y^2 = z^2$$ was 
proved to be invalid for other exponents. 
Meaning the next equation has no integer solutions:
 
$$x^n + y^n = z^n$$

Let's try something harder.

$$
 \frac{1}{\displaystyle 1+
   \frac{1}{\displaystyle 2+
   \frac{1}{\displaystyle 3+x}}} +
 \frac{1}{1+\frac{1}{2+\frac{1}{3+x}}}
$$

$$\int_0^\infty e^{-x^2} dx=\frac{\sqrt{\pi}}{2}$$

## Block Elements

### Paragraphs and Line Breaks

A paragraph is simply one or more consecutive lines of text, separated
by one or more blank lines. (A blank line is any line that looks like a
blank line -- a line containing nothing but spaces or tabs is considered
blank.) Normal paragraphs should not be indented with spaces or tabs.

The implication of the "one or more consecutive lines of text" rule is
that Markdown supports "hard-wrapped" text paragraphs. This differs
significantly from most other text-to-HTML formatters (including Movable
Type's "Convert Line Breaks" option) which translate every line break
character in a paragraph into a `<br />` tag.

When you *do* want to insert a `<br />` break tag using Markdown, you
end a line with two or more spaces, then type return.

### Headers

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. Vivamus tempus vitae metus vel consectetur. Curabitur ornare maximus mauris eget euismod. Ut non nunc id odio ullamcorper vestibulum vel a enim. Donec varius sagittis nunc, eu porttitor tellus. Duis sodales magna elit, nec posuere purus porttitor vehicula. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent ipsum lorem, consectetur eu molestie eget, egestas nec lectus. Sed tincidunt urna sit amet erat euismod dictum. 

# Header level 1

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

## Header level 2

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

### Header level 3

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

#### Header level 4

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

##### Header level 5

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

###### Header level 6

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. 

### Blockquotes

Markdown uses email-style `>` characters for blockquoting. If you're
familiar with quoting passages of text in an email message, then you
know how to create a blockquote in Markdown. It looks best if you hard
wrap the text and put a `>` before every line:

> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
> consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
> Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.
> 
> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
> id sem consectetuer libero luctus adipiscing.

Markdown allows you to be lazy and only put the `>` before the first
line of a hard-wrapped paragraph:

> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.

> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
id sem consectetuer libero luctus adipiscing.

Blockquotes can be nested (i.e. a blockquote-in-a-blockquote) by
adding additional levels of `>`:

> This is the first level of quoting.
>
> > This is nested blockquote.
>
> Back to the first level.

Blockquotes can contain other Markdown elements, including headers, lists,
and code blocks:

> ## This is a header.
> 
> 1.   This is the first list item.
> 2.   This is the second list item.
> 
> Here's some example code:
> 
>     return shell_exec("echo $input | $markdown_script");
> 
> Here's an image:
> 
> ![duck.png](/static/posts/design-test/duck.png)


Any decent text editor should make email-style quoting easy. For
example, with BBEdit, you can make a selection and choose Increase
Quote Level from the Text menu.


### Lists

Markdown supports ordered (numbered) and unordered (bulleted) lists.

Unordered lists use asterisks, pluses, and hyphens -- interchangably
-- as list markers:

*   Red
*   Green
*   Blue

is equivalent to:

+   Red
+   Green
+   Blue

and:

-   Red
-   Green
-   Blue

Ordered lists use numbers followed by periods:

1.  Bird
2.  McHale
3.  Parish

It's important to note that the actual numbers you use to mark the
list have no effect on the HTML output Markdown produces. The HTML
Markdown produces from the above list is:

If you instead wrote the list in Markdown like this:

1.  Bird
1.  McHale
1.  Parish

or even:

3. Bird
1. McHale
8. Parish

you'd get the exact same HTML output. The point is, if you want to,
you can use ordinal numbers in your ordered Markdown lists, so that
the numbers in your source match the numbers in your published HTML.
But if you want to be lazy, you don't have to.

To make lists look nice, you can wrap items with hanging indents:

*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
    Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
    viverra nec, fringilla in, laoreet vitae, risus.
*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
    Suspendisse id sem consectetuer libero luctus adipiscing.

But if you want to be lazy, you don't have to:

*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
viverra nec, fringilla in, laoreet vitae, risus.
*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
Suspendisse id sem consectetuer libero luctus adipiscing.

List items may consist of multiple paragraphs. Each subsequent
paragraph in a list item must be indented by either 4 spaces
or one tab:

1.  This is a list item with two paragraphs. Lorem ipsum dolor
    sit amet, consectetuer adipiscing elit. Aliquam hendrerit
    mi posuere lectus.

    Vestibulum enim wisi, viverra nec, fringilla in, laoreet
    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
    sit amet velit.

2.  Suspendisse id sem consectetuer libero luctus adipiscing.

It looks nice if you indent every line of the subsequent
paragraphs, but here again, Markdown will allow you to be
lazy:

*   This is a list item with two paragraphs.

    This is the second paragraph in the list item. You're
only required to indent the first line. Lorem ipsum dolor
sit amet, consectetuer adipiscing elit.

*   Another item in the same list.

To put a blockquote within a list item, the blockquote's `>`
delimiters need to be indented:

*   A list item with a blockquote:

    > This is a blockquote
    > inside a list item.

To put a code block within a list item, the code block needs
to be indented *twice* -- 8 spaces or two tabs:

*   A list item with a code block:

        <code goes here>

### Code Blocks

Pre-formatted code blocks are used for writing about programming or
markup source code. Rather than forming normal paragraphs, the lines
of a code block are interpreted literally. Markdown wraps a code block
in both `<pre>` and `<code>` tags.

To produce a code block in Markdown, simply indent every line of the
block by at least 4 spaces or 1 tab.

This is a normal paragraph:

    This is a code block.

Here is an example of AppleScript:

    tell application "Foo"
        beep
    end tell

A code block continues until it reaches a line that is not indented
(or the end of the article).

Within a code block, ampersands (`&`) and angle brackets (`<` and `>`)
are automatically converted into HTML entities. This makes it very
easy to include example HTML source code using Markdown -- just paste
it and indent it, and Markdown will handle the hassle of encoding the
ampersands and angle brackets. For example, this:

    <div class="footer">
        &copy; 2004 Foo Corporation
    </div>

Regular Markdown syntax is not processed within code blocks. E.g.,
asterisks are just literal asterisks within a code block. This means
it's also easy to use Markdown to write about Markdown's own syntax.

```
tell application "Foo"
    beep
end tell
```

```
iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFew3nPiS65O7umPFMGLbO6Nrry4O9EInddFrQVbPVWZAVOytM1fosk5MqXlYvz+ldghNE3cKVqmdUpimZKtH/Oe02fA1pCy1USuWGhxE2rFpLJeUenFixP3UFnd+Biqnou8ppcQzN6GJIVyeNoWt4jIJHcsTOaKZqAMo/zi8cGVdfByIdRPR2cN4PEQHnCsmEXj8MeywM6SC1Ebhi1a5mc9+byELm9SeSf3cC/xg8F2SwBTVbQQwAAAABJRU5ErkJggg==iVBORw0KGgoAAAANSUhEUgAAAG8AAABvAQMAAADYCwwjAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlP//8i138cAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAErSURBVDiN1dQxbsQgEAXQsSjo7AsgcQ06rrRcYL2+wPpKdFwDiQvgbgrkyXhjaZMiHoooUpBl+RUW/GEA6NuA/8EKEFJZyQBYkRu1OeUQ20wdjObu84Dtprs4J1rR9BLLElsXqd0d7fq9yAu+8hp+vsT/kTyqV1t6F/aC1XFe ...
```

#### Shell

```shell
$ tshark -i eth0 -T pdml
```

#### Bash

```bash
#!/bin/bash
# Counting the number of lines in a list of files
# for loop over arguments

if [ $# -lt 1 ]
then
  echo "Usage: $0 file ..."
  exit 1
fi

echo "$0 counts the lines of code" 
l=0
n=0
s=0
for f in $*
do
	l=`wc -l $f | sed 's/^\([0-9]*\).*$/\1/'`
	echo "$f: $l"
        n=$[ $n + 1 ]
        s=$[ $s + $l ]
done

echo "$n files in total, with $s lines in total"
```

#### Python

```python
state = (2147483648, 80334302, 2582826967, 658996914, 108179463, 1252125035, 96362690, 1370822754, 504586903, 869433376, 3169798841, 4016685807, 25736907, 2670614602, 3510858902, 4183218872, 1507694435, 571544519, 3749899098, 1889562419, 2843925689, 3209162224, 4293645487, 2150486616, 2792048381, 3326674289, 2354435060, 959119818, 1771370852, 1736453723, 2302276770, 3264217997, 2615511290, 1827916191, 1491287354, 714992219, 2013548877, 1954664105, 2949277279, 4249756921, 1610439075, 3802113140, 427028445, 1868708060, 3806186508, 1101311238, 2372992176, 2254751436, 1293433374, 2001404293, 129879827, 2549674696, 2921901661, 2478095551, 974415959, 3581422201, 508256321, 108488358, 357521834, 41309255, 1449937187, 3534707978, 3477659598, 3906698808, 1682120988, 1102179843, 958504543, 3117409020, 1339320787, 183168377, 3126006818, 895661207, 2081943532, 2800550919, 3825384181, 11788969, 336653968, 3806760405, 2695115852, 1407349646, 4105929839, 3444634939, 3183786525, 4083217533, 380893012, 905256437, 3473084557, 1729072843, 589090346, 4257046117, 3475611761, 1201602571, 4038017692, 3784706051, 3130563315, 3846731885, 2333363044, 3304852225, 629233718, 1898913461, 2313801921, 2252000614, 2566490008, 1503454065, 2619788391, 1217824893, 876023633, 1703406736, 2408558497, 4002515449, 87271640, 1936188713, 3490838276, 758703031, 4063603083, 898353391, 747282151, 1344914975, 814867467, 2691856265, 1439721377, 3827947975, 2986337626, 2564285211, 177335347, 1682140806, 769865631, 1420940351, 1423858907, 2091838677, 4148160237, 2133109957, 2373603470, 1886489684, 2935002178, 4041684923, 3882138902, 3196605695, 842331337, 1452426979, 93035244, 3359637220, 1249336865, 3605810926, 454647780, 174249701, 3941456425, 367237129, 505053224, 2186431116, 2232862030, 4258629402, 3806038136, 1423731032, 3522860723, 3260056109, 183639574, 2903347922, 1476462162, 1060769512, 3028629610, 3437623182, 1419194752, 3607116511, 1154366857, 3168037133, 3171264213, 323209731, 3308229586, 76089955, 3393326122, 2379394222, 1641946584, 2144865673, 2613874219, 1124633155, 3409117953, 762929476, 1741552314, 1339994629, 455182974, 3880447542, 1673216689, 3048049942, 1715229339, 4131038145, 3430353814, 2065113375, 569796659, 2214336751, 2143010524, 260838276, 3599241249, 2070267573, 822581877, 4167132767, 1889780715, 3122523553, 2733748598, 486858438, 3156209085, 1386355060, 2474269950, 489287216, 3963582133, 2847499668, 3703228743, 1901815701, 3719532546, 3755499635, 599295249, 4000268237, 3535439828, 3408865, 3394674549, 2155314783, 2888589252, 898006214, 2331584667, 2896176011, 3952218903, 2284798341, 4259287596, 406891482, 1705011774, 1235908731, 1702974178, 731817876, 1286907220, 3572725262, 2938315711, 4161284747, 3861264172, 1549196864, 4207914889, 1829956990, 527030257, 33269413, 679461349, 2497930426, 2547593865, 2617747730, 4189714876, 1691479229, 3921442295, 1768106171, 1239454490, 1541303168)

def same_flow(f, xi, t, A):
  """ Returns True iff f belongs to xi in respect to t and A """
  for test in xi:
    if abs(tau(test) - tau(f)) < t and all([ test[a] == f[a] for a in A ]):
      return True
  return False
```

#### Javascript

```javascript
function requireFromString(src) {
  var Module = module.constructor;
  var m = new Module();
  m._compile(src, __filename);
  return m.exports;
}
```

### Tables

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. Vivamus tempus vitae metus vel consectetur. 

{:.table}
| this | is  | a very | long | table |
| ---- | --- | ------ | ---- | ----- |
| this | is  | a very | long | table |
| this | is  | a very | long | table |
| this | is  | a very | long | table |

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. Vivamus tempus vitae metus vel consectetur. 

{:.table}
| where | how   |
| ----- | ----- |
| email | ducksource[at]duckpond.ch |
| pgp   | [80EA 1448 72C2 A93B 2FCB B7CE 0F1C 362B 6F42 0C0A](https://sks-keyservers.net/pks/lookup?op=get&search=0x80EA144872C2A93B2FCBB7CE0F1C362B6F420C0A) |
| irc   | enteee @ freenode.net |
| github | <a aria-label="Follow @Enteee on GitHub" data-style="mega" href="https://github.com/Enteee" class="github-button">Follow @Enteee</a> |
| stack overflow | <a href="https://stackoverflow.com/users/3215929/ente"><img src="https://stackoverflow.com/users/flair/3215929.png?theme=clean" width="208" height="58" alt="profile for Ente at Stack Overflow, Q&amp;A for professional and enthusiast programmers" title="profile for Ente at Stack Overflow, Q&amp;A for professional and enthusiast programmers"></a> |
| twitter | <a href="https://twitter.com/Enteeeeeee" class="twitter-follow-button" data-show-count="false" data-size="large" data-dnt="true">Follow @Enteeeeeee</a> |

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia eros nec scelerisque semper. Vivamus tempus vitae metus vel consectetur. 

## Span Elements

### Links

Markdown supports two style of links: *inline* and *reference*.

In both styles, the link text is delimited by [square brackets].

To create an inline link, use a set of regular parentheses immediately
after the link text's closing square bracket. Inside the parentheses,
put the URL where you want the link to point, along with an *optional*
title for the link, surrounded in quotes. For example:

This is [an example](http://example.com/) inline link.

[This link](http://example.net/) has no title attribute.

### Emphasis

Markdown treats asterisks (`*`) and underscores (`_`) as indicators of
emphasis. Text wrapped with one `*` or `_` will be wrapped with an
HTML `<em>` tag; double `*`'s or `_`'s will be wrapped with an HTML
`<strong>` tag. E.g., this input:

*single asterisks*

_single underscores_

**double asterisks**

__double underscores__

### Code

To indicate a span of code, wrap it with backtick quotes (`` ` ``).
Unlike a pre-formatted code block, a code span indicates code within a
normal paragraph. For example:

Use the `printf()` function.

