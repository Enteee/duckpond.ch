// Checks if a link is external or internal
function link_is_external(link_element) {
  return (link_element.host !== window.location.host);
}

$(function(){
  // initialize supersearch
  superSearch({
    searchFile: '/feed.xml',
    searchSelector: '#js-super-search', // CSS Selector for search container element.
    inputSelector: '#js-super-search__input', // CSS selector for <input>
    resultsSelector: '#js-super-search__results' // CSS selector for results container
  });

  // mark external / internal links so that we don't have to do this in the markdown
  $('a').each(function(){
    if (link_is_external(this)) {
      // external link
      $(this).addClass('external');
      // add target blank to all external links
      $(this).attr('target', '_blank');
    }else{
      // internal link
      $(this).addClass('internal');
    }
  });

});
