---
layout: post
title:  "super-search for Atom"
keywords: [Atom, super-search]
categories: [web, meta]
---

I use [super-search] on an [Atom-feed] to make duckpond.ch searchable[^1]. From [super-search] readme:

> super-search adds search feature to your blog. super-search works on your blog's RSS feeds to enable searching posts.

I prefere Atom over RSS. Mainly because Atom is [a proposed standard][Atom-standard] and there is a [plugin for jekyll][jekyll-Atom]. Btw; RSS should also be [fairly easy][jekyll-rss] to integrate. Anyway here's a patch for [super-search] which should make it Atom compatible [^2][^3][^4]:

```javascript
--- supersearch.js.old
+++ supersearch.js.new
@@ -47,7 +47,10 @@
 
    function getPostsFromXml(xml) {
        var json = xmlToJson(xml);
-       return json.channel.item;
+       if(Object.prototype.toString.call(json.entry) !== '[object Array]'){
+           return [json.entry];
+       }
+       return json.entry;
    }
 
    window.toggleSearch = function toggleSearch() {
@@ -76,7 +79,7 @@
        searchResultsEl.style.offsetWidth;
 
        var matchingPosts = posts.filter(function (post) {
-           if ((post.title + '').toLowerCase().indexOf(currentInputValue) !== -1 || (post.description + '').toLowerCase().indexOf(currentInputValue) !== -1) {
+           if ((post.title + '').toLowerCase().indexOf(currentInputValue) !== -1 || (post.content + '').toLowerCase().indexOf(currentInputValue) !== -1) {
                return true;
            }
        });
@@ -87,8 +90,8 @@
        if (matchingPosts.length && currentResultHash !== lastSearchResultHash) {
            searchResultsEl.classList.remove('is-hidden');
            searchResultsEl.innerHTML = matchingPosts.map(function (post) {
-               d = new Date(post.pubDate);
-               return '<li><a href="' + post.link + '">' + post.title + '<span class="search__result-date">' + d.toUTCString().replace(/.*(\d{2})\s+(\w{3})\s+(\d{4}).*/,'$2 $1, $3') + '</span></a></li>';
+               d = new Date(post.published);
+               return '<li><a href="' + post.id + '">' + post.title + '&raquo; <span class="search__result-date">' + d.toUTCString().replace(/.*(\d{2})\s+(\w{3})\s+(\d{4}).*/,'$2 $1, $3') + '</span></a></li>';
            }).join('');
        }
        lastSearchResultHash = currentResultHash;
@@ -100,7 +103,7 @@
        searchInputEl = document.querySelector(options.inputSelector || '#js-super-search__input');
        searchResultsEl = document.querySelector(options.resultsSelector || '#js-super-search__results');
 
-       var xmlhttp=new XMLHttpRequest();
+       var xmlhttp = new XMLHttpRequest();
        xmlhttp.open('GET', searchFile);
        xmlhttp.onreadystatechange = function () {
            if (xmlhttp.readyState != 4) return;
```

[^1]:Press ESC, '/' or the magnifying glass in the upper right corner to toggle the search.
[^2]:Work in progress
[^3]:Not tested
[^4]:Who needs testing anyway?

[super-search]:https://github.com/chinchang/super-search
[Atom-standard]: https://tools.ietf.org/html/rfc4287
[jekyll-Atom]:https://github.com/jekyll/jekyll-feed
[jekyll-rss]:https://github.com/snaptortoise/jekyll-rss-feeds
[Atom-feed]:/feed.xml
