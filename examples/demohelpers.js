/* General demo helpers */
$(function() {
  hostname = document.location.hostname;
  if (hostname && (hostname.indexOf('github') >= 0 || hostname.indexOf('sebastianhelzle') >= 0)) {
    try {
      piwikTracker = Piwik.getTracker('https://tracking.sebastianhelzle.net/piwik.php', 5);
      piwikTracker.trackPageView();
      piwikTracker.enableLinkTracking();
    } catch (err) {}

    document.write(unescape("%3Cscript src='http://s7.addthis.com/js/250/addthis_widget.js#pubid=sebobo' type='text/javascript'%3E%3C/script%3E"));
    s = document.createElement('script');
    t = document.getElementsByTagName('script')[0];
    s.type = 'text/javascript';
    s.async = true;
    s.src = 'http://api.flattr.com/js/0.6/load.js?mode=auto';
    return t.parentNode.insertBefore(s, t);
  }
});
