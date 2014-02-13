cc-lasso8
=========

Constant Contact V2 API (REST/JSON) for Lasso 8.6

A collection of custom tags for Lasso which provide integration with
Constant Contact's V2 API.  The JSON payloads of the REST API are 
automatically converted to/from native Lasso arrays and maps.

http://developer.constantcontact.com/docs/developer-guides/overview-of-api-endpoints.html


Release Notes
=========

2014-02-13 - Initial release including CURL-based actions, error
processing, basic Contact and Contact List functionality.


Usage
=========

  cc_apikey('abcdefghijklmnopqrstuvwxyz');
  cc_token('1234567890-1234-1234-1234-1234567890');
  
  // Find array of contacts with email address
  cc_findcontacts(-email='john@example.com');
  
  // Get one contact, modify, and put changes
  var('mycontact' = cc_getcontact(12345));
  $mycontact->insert('status'='ACTIVE');
  var('mycontact' = cc_putcontact($mycontact, -by='visitor'));

  // Get array of contact lists
  var('mylists' = cc_findlists());

  ... more to come ...
  
