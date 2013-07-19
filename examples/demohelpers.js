/* General demo helpers */
$(function() {
  hostname = document.location.hostname;
  if (hostname && (hostname.indexOf('github') >= 0 || hostname.indexOf('sebastianhelzle') >= 0)) {
    try {
      piwikTracker = Piwik.getTracker('https://tracking.sebastianhelzle.net/piwik.php', 5);
      piwikTracker.trackPageView();
      piwikTracker.enableLinkTracking();
    } catch (err) {}
    s = document.createElement('script');
    t = document.getElementsByTagName('script')[0];
    s.type = 'text/javascript';
    s.async = true;
    s.src = 'http://api.flattr.com/js/0.6/load.js?mode=auto';
    return t.parentNode.insertBefore(s, t);
  }
});
