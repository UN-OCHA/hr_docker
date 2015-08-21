#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "web";
    .port = "80";
    .connect_timeout = 3600s;
    .first_byte_timeout = 3600s;
    .between_bytes_timeout = 3600s;
}


sub vcl_recv {

# Domain Exclusion test for Ticket #232653
if (req.http.host ~ "stats\.humanitarianresponse\.info" ) {
    return (pass);
  }

# sparql is acting as a webservice, and seems to act weird when passed. 
# Just relay the bytes.
  if (req.url ~ "^/sparql") {
    return (pipe);
  }

  if (req.url ~ ".*/cron.php$") {
    return (pass);
  }

  if (req.http.host == "stats.humanitarianresponse.info") {
	set req.http.X-Forwarded-For = client.ip;
	return(pass);
  }


  # Remove all cookies that Drupal doesn't need to know about. ANY remaining
  # cookie will cause the request to pass-through to Apache. For the most part
  # we always set the NO_CACHE cookie after any POST request, disabling the
  # Varnish cache temporarily. The session cookie allows all authenticated users
  # to pass through as long as they're logged in.
  if (req.http.Cookie && !(req.url ~ "wp-(login|admin)")) {
    # identify language cookie
    if (req.http.cookie ~ "language=") {
      #unset all the cookie from request except language
      set req.http.X-Varnish-Language = regsub(req.http.cookie, "(.*?)(language=)([^;]*)(.*)$", "\3");
    }
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(S?SESS[a-z0-9]+|NO_CACHE)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z0-9A-Z_-]+|has_js)=[^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_pk_(ses|id|ref)[\.a-z0-9]*)=[^;]*", "");
    # Remove the language cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "language=[^;]+(; )?", "");
    # Remove the "Drupal. cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "Drupal.toolbar.collapsed=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "Drupal.tableDrag.showWeight=[^;]+(; )?", "");

    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      # If there are no remaining cookies, remove the cookie header. If there
      # aren't any cookie headers, Varnish's default behavior will be to cache
      # the page.
      unset req.http.Cookie;
    }
    else {
      # If there are any cookies left (a session or NO_CACHE cookie), do not
      # cache the page. Pass it on to Apache directly.
      return (pass);
    }
  }



  # cache these file types - remember to also update vcl_fetch if you change this list!
  if (req.url ~ "\.(jpg|png|css|js|ico|gz|tgz|bz2|tbz|gif)$") {
    if (!(req.url ~ "imagecache")) {
      unset req.http.cookie;
    }
  }
  # Force lookup if the request is a no-cache request from the client
  if (req.http.Cache-Control ~ "no-cache") {
    return(pass);
  }
 
  # Properly handle different encoding types
  if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
    # No point in compressing these
      unset req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      set req.http.Accept-Encoding = "deflate";
    } else {
      # unknown algorithm
      unset req.http.Accept-Encoding;
    }
  }
 

  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
  }
 
  if (req.method != "GET" && req.method != "HEAD") {
    /* We only deal with GET and HEAD by default */
    return (pass);
  }
}

sub vcl_backend_response {

    #Since we strip cookies, if for some reason these give us something that
    #runs PHP (e.g. a 404), if we don't strip out the set-cookie, we'll be
    #treated as an anonymous user and given a fresh cookie.
    if ( bereq.url ~ "\.(jpg|png|css|js|ico|gz|tgz|bz2|tbz|gif)$" )
    {
        unset beresp.http.Set-Cookie;
    }

    if (bereq.http.host == "stats.humanitarianresponse.info") {
        set beresp.uncacheable = true;
        return(deliver);
    }
 
    if (beresp.ttl <= 0s ||
        beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
              /*
               * Mark as "Hit-For-Pass" for the next 2 minutes
               */
              set beresp.ttl = 120 s;
              set beresp.uncacheable = true;
              return (deliver);
    }
    set beresp.grace = 1d;
    return (deliver);

}

