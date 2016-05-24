$(function(){
    // initialize supersearch
    superSearch({
        searchFile: '/feed.xml',
        searchSelector: '#js-super-search', // CSS Selector for search container element.
        inputSelector: '#js-super-search__input', // CSS selector for <input>
        resultsSelector: '#js-super-search__results' // CSS selector for results container
    });
 
});
