<?lassoscript

	//
	// Constant Contact Utility Library
	//
	// This is a utility library which is used by the individual
	// Constant Contact modules for basic network GET, POST, PUT, and
	// DELETE actions and authorization.  Most pages will call the CC
	// Variables tags to set up global values for the API access key,
	// but otherwise most of the tags in this library are not called
	// directly.
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	//
	// CC Variables
	//
	// Most CC calls require an API Key and Access Token for access to
	// the API. These tags allow these values to be set once and used
	// automatically by all other tags.
	//
	// Follow the instructions here to get an API Key and Access Token.
	// https://constantcontact.mashery.com/apps/register
	//
	// Note you do not need the API secret to use this API.  It is only
	// required to generate the access token which will be valid for ten
	// years.
	//
	// The endpoint defaults to "http://api.constantcontact.com" and
	// should not need to be changed.  The path to curl can be set if
	// necessary.
	//
	// Call with a value to set.  Call without a value to retrieve the
	// set value.
	//
	// cc_apikey(key)
	// cc_token(token)
	// cc_endpoint(url)
	// cc_curl(path/to/curl) default '/usr/bin/curl'
	//
	define_tag('cc_apikey', -optional='key', -namespace=namespace_global);
		local_defined('key') ? return(var('_cc_apikey_' = #key));
		fail_if(!var_defined('_cc_apikey_'), -1, 'cc_apikey must be defined');
		return(@$_cc_apikey_);
	/define_tag;
	define_tag('cc_token', -optional='tok', -namespace=namespace_global);
		local_defined('tok') ? return(var('_cc_token_' = #tok));
		fail_if(!var_defined('_cc_token_'), -1, 'cc_token must be defined');
		return(@$_cc_token_);
	/define_tag;
	define_tag('cc_endpoint', -optional='url', -namespace=namespace_global);
		local_defined('url') ? return(var('_cc_endpoint_' = #url));
		!var_defined('_cc_endpoint_') ? var('_cc_endpoint_' = 'api.constantcontact.com');
		return(@$_cc_endpoint_);
	/define_tag;
	define_tag('cc_curl', -optional='path', -namespace=namespace_global);
		local_defined('path') ? return(var('_cc_curl_' = #path));
		var('_cc_curl_' = os_process('/usr/bin/which', array('curl'))->read);
		$_cc_curl_ == '' ? $_cc_curl_ = '/usr/bin/curl';
		return(@$_cc_curl_);
	/define_tag;

	//
	// AWS Utilities
	//

	// cc_date()
	// Utility function returns properly formatted date string
	// Manual format (GMT): %Q or %QT%T
	// http://developer.constantcontact.com/docs/developer-guides/general-considerations.html
	define_tag('cc_date', -optional='date', -namespace=namespace_global);
		!local_defined('date') ? return(date->format('%QT%T'));
		if(#date->isa('date'));
			!date->gmt ? return(date_localtogmt(#date)->format('%QT%T'));
			return(#date->format('%QT%T'));
		/if;
		#date->isa('string') && #date !>> 'Z' ? return(date_localtogmt(#date)->format('%QT%T'));
		return(date(#date)->format('%QT%T'));
	/define_tag;

	//
	// cc_next(data)
	// Returns the current pagination value or extracts the pagination value from a map
	//
	define_tag('cc_next', -optional='data', -namespace=namespace_global);
		if(local_defined('data'));
			var('_cc_next_' = '');
			if(#data->isa('map'));
				#data >> 'meta' ? return(cc_next(#data->find('meta')));
				#data >> 'pagination' ? return(cc_next(#data->find('pagination')));
				#data >> 'next_link' ? return(cc_next(#data->find('next_link')));
			else(#data->isa('string') && #data >> 'next=');
				return(var('_cc_next_' = string_replaceregexp(#data, -find='.*next=([a-zA-Z0-9]+)', -replace='\\1')));
			/if;
		/if;
		return(@var('_cc_next_'));
	/define_tag;


	//
	// AWS Verbs
	//

	// cc_get(path);
	// GETs the specified path from the endpoint
	// Returns the JSON decoded response
	// Sets $_cc_headers_ to response headers and $_cc_sendheaders_ to sent headers
	define_tag('cc_get', -required='path', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		var('_cc_sendheaders_' = array(
			'Host' = cc_endpoint,
			'Accept' = 'application/json',
			'Content-Type' = 'application/json',
			'Authorization' = 'Bearer ' + (local_defined('token') ? #token | cc_token())
		));
		iterate(local('headers'), local('h'));
			!#h->isa('pair') ? loop_continue;
			$_cc_sendheaders_->insert(#h->first = #h->second);
		/iterate;
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params'));
			iterate(#params, local('param'));
				if(#param->isa('pair'));
					#post->append(#and + encode_stricturl(#param->first) + '=' + encode_stricturl(#param->second));
					#and = '&';
				/if;
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));
		var('_cc_raw_' = include_url($_cc_url_, -sendmimeheaders=$_cc_sendheaders_, -retrievemimeheaders='_cc_headers_'));
		$_cc_raw_ == '' ? return;
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		cc_next(#output);
		return(#output->isa('map') && #output >> 'results' ? @#output->find('results') | @#output);
	/define_tag;

	// cc_post(path,data);
	// POSTs the specified data to the path at the endpoint
	// Note: Requires [os_process] permission
	// Sets $_cc_headers_ to response headers and $_cc_sendheaders_ to sent headers
	define_tag('cc_post', -required='path', -required='data', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		var('_cc_sendheaders_' = array(
			'Host' = cc_endpoint,
			'Accept' = 'application/json',
			'Content-Type' = 'application/json',
			'Authorization' = 'Bearer ' + (local_defined('token') ? #token | cc_token())
		));
		iterate(local('headers'), local('h'));
			!#h->isa('pair') ? loop_continue;
			$_cc_sendheaders_->insert(#h->first = #h->second);
		/iterate;
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params'));
			iterate(#params, local('param'));
				if(#param->isa('pair'));
					#post->append(#and + encode_stricturl(#param->first) + '=' + encode_stricturl(#param->second));
					#and = '&';
				/if;
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));
		var('_cc_curl_' = array('--silent', '--include', '--request', 'PUT'));
		iterate($_cc_sendheaders_,local('h'));
			$_cc_curl_->insert('--header', '"' + #h->first + ': ' + #h->second + '"');
		/iterate;
		$_cc_curl_->insert('--data', '"' + encode_sql(#data) + '"');
		$_cc_curl_->insert('--url', $_cc_url_);
		var('_cc_raw_' = os_process(cc_curl, $_cc_curl_)->read);
		$_cc_raw_ == '' ? return;
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		return(@#output);
	/define_tag;

	// cc_put(path,data);
	// PUTs the specified data to the path at the endpoint
	// Note: Requires [os_process] permission
	// Sets $_cc_headers_ to response headers and $_cc_sendheaders_ to sent headers
	define_tag('cc_put', -required='path', -required='data', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		var('_cc_sendheaders_' = array(
			'Host' = cc_endpoint,
			'Accept' = 'application/json',
			'Content-Type' = 'application/json',
			'Authorization' = 'Bearer ' + (local_defined('token') ? #token | cc_token())
		));
		iterate(local('headers'), local('h'));
			!#h->isa('pair') ? loop_continue;
			$_cc_sendheaders_->insert(#h->first = #h->second);
		/iterate;
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params'));
			iterate(#params, local('param'));
				if(#param->isa('pair'));
					#post->append(#and + encode_stricturl(#param->first) + '=' + encode_stricturl(#param->second));
					#and = '&';
				/if;
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));
		var('_cc_curl_' = array('--silent', '--include', '--request', 'PUT'));
		iterate($_cc_sendheaders_,local('h'));
			$_cc_curl_->insert('--header', '"' + #h->first + ': ' + #h->second + '"');
		/iterate;
		$_cc_curl_->insert('--data', '"' + encode_sql(#data) + '"');
		$_cc_curl_->insert('--url', $_cc_url_);
		$_cc_raw_ == '' ? return;
		var('_cc_raw_' = os_process(cc_curl, $_cc_curl_)->read);
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		return(@#output);
	/define_tag;

	// cc_delete(path);
	// DELETEs the specified path at the endpoint
	// Note: Requires [os_process] permission
	// Returns the xml response
	define_tag('cc_delete', -required='path', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		var('_cc_sendheaders_' = array(
			'Host' = cc_endpoint,
			'Accept' = 'application/json',
			'Content-Type' = 'application/json',
			'Authorization' = 'Bearer ' + (local_defined('token') ? #token | cc_token())
		));
		iterate(local('headers'), local('h'));
			!#h->isa('pair') ? loop_continue;
			$_cc_sendheaders_->insert(#h->first = #h->second);
		/iterate;
		var('_cc_curl_' = array('curl', '--silent', '--include', '--request', 'DELETE'));
		iterate($_cc_sendheaders_,local('h'));
			$_cc_curl_->insert('--header', '"' + #h->first + ': ' + #h->second + '"');
		/iterate;
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params'));
			iterate(#params, local('param'));
				if(#param->isa('pair'));
					#post->append(#and + encode_stricturl(#param->first) + '=' + encode_stricturl(#param->second));
					#and = '&';
				/if;
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));
		$_cc_curl_->insert('--url', $_cc_url_);
		var('_cc_raw_' = os_process(cc_curl, $_cc_curl)->read);
		$_cc_raw_ == '' ? return;
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		return(@#output);
	/define_tag;

	//
	// Debugging
	//

	// cc_sendheaders();
	// Returns the headers sent
	define_tag('cc_sendheaders', -namespace=namespace_global);
		return(var('_cc_sendheaders_'));
	/define_tag;

	// cc_headers();
	// Returns the headers sent back
	define_tag('cc_headers', -namespace=namespace_global);
		return(var('_cc_headers_'));
	/define_tag;

	// cc_raw();
	// Returns the raw result
	define_tag('cc_raw', -namespace=namespace_global);
		return(var('_cc_raw_'));
	/define_tag;

	// cc_url();
	// Returns the raw called URL
	define_tag('cc_url', -namespace=namespace_global);
		return(var('_cc_url_'));
	/define_tag;

?>
