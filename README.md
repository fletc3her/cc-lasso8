cc-lasso8
=========

Constant Contact V2 API (REST/JSON) for Lasso 8.6

A collection of custom tags for Lasso which provide integration with
Constant Contact's V2 API.  The JSON payloads of the REST API are 
automatically converted to/from native Lasso arrays and maps.

http://developer.constantcontact.com/docs/developer-guides/overview-of-api-endpoints.html


License
--------
Copyright (c) 2014 by Fletcher Sandbeck <fletc3her@gmail.com>

Released Under MIT License: http://fletc3her.mit-license.org/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Release Notes
--------

2014-02-13 - Initial release including CURL-based actions, error
processing, basic Contact and Contact List functionality.


Usage
--------
```lasso
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

// ... more to come ...
```
