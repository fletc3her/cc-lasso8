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
	// Shell methodology from http://tagswap.net/shell/
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
		#date->isa('string') && #date !>> 'Z' ? return(date(date_localtogmt(date(#date)))->format('%QT%T'));
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
		return(var('_cc_next_'));
	/define_tag;

	define_tag('cc_encode', -required='data', -namespace=namespace_global);
	//	#data >> '\\' ? #data->replace('\\', '\\\\');
		#data >> '\'' ? #data->replace('\'', '\\\'');
	//	#data >> '"' ? #data->replace('\"', '\\\\"');
		#data >> '!' ? #data->replace('!', '\\!');
		return(@#data);
	/define_tag;

	//
	// AWS Verbs
	//

	// cc_get(path);
	// GETs the specified data from the path at the endpoint
	// Command, URL, and raw output can be accessed using tags below for debugging
	// Note: Requires [os_process] permission
	define_tag('cc_get', -required='path', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		local('output' = cc_curl(-path=#path, -verb='GET', -params=local('params'), -headers=local('headers'), -token=local('token')));
		cc_next(#output);
		return(#output->isa('map') && #output >> 'results' ? @#output->find('results') | @#output);
	/define_tag;

	// cc_post(path,data);
	// POSTs the specified data to the path at the endpoint
	// Command, URL, and raw output can be accessed using tags below for debugging
	// Note: Requires [os_process] permission
	define_tag('cc_post', -required='path', -optional='data', -optional='params', -optional='form', -optional='headers', -optional='token', -namespace=namespace_global);
		return(cc_curl(-path=#path, -verb='POST', -data=local('data'), -params=local('params'), -form=local('form'), -headers=local('headers'), -token=local('token')));
	/define_tag;

	// cc_put(path, data)
	// PUTs the specified data at the specified path
	define_tag('cc_put', -required='path', -required='data', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		return(cc_curl(-path=#path, -verb='PUT', -data=#data, -params=local('params'), -headers=local('headers'), -token=local('token')));
	/define_tag;

	// cc_delete(path, data)
	// DELETEs the specified data from the specified path
	// Command, URL, and raw output can be accessed using tags below for debugging
	// Note: Requires [os_process] permission
	define_tag('cc_delete', -required='path', -optional='params', -optional='headers', -optional='token', -namespace=namespace_global);
		return(cc_curl(-path=#path, -verb='DELETE', -params=local('params'), -headers=local('headers'), -token=local('token')));
	/define_tag;

	// cc_curl(verb, path, data, params, headers, token);
	// Calls curl with the specified verb (GET, POST, PUT, DELETE), path, data, params, and headers
	// Command, URL, and raw output can be accessed using tags below for debugging
	// Note: Requires [os_process] permission
	define_tag('cc_curl', -required='path', -optional='verb', -optional='data', -optional='params', -optional='form', -optional='headers', -optional='token', -optional='retry', -namespace=namespace_global);

		// Assemble URL
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params') && #params->isa('array') && #params->size > 0);
			iterate(#params, local('p'));
				!#p->isa('pair') ? loop_continue;
				#post->append(#and + encode_stricturl(#p->first) + '=' + encode_stricturl(#p->second));
				#and = '&';
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));

		// Assemble curl command
		var('_cc_cmd_' = array);
		local('has' = array);
		$_cc_cmd_->insert('--silent');
		$_cc_cmd_->insert('--show-error');
		$_cc_cmd_->insert('--insecure'); // Does not check SSL certificates
		local_defined('verb') && #verb != '' ? $_cc_cmd_->insert('--request') & insert(string_uppercase(#verb));
		if(local_defined('headers') && (#headers->isa('array') || #headers->isa('map')) && #headers->size > 0);
			iterate(local('headers'), local('h'));
				!#h->isa('pair') ? loop_continue;
				#has->insert(#h->first);
				$_cc_cmd_->insert('--header') & insert(#h->first + ': ' + #h->second);
			/iterate;
		/if;
		if(local_defined('form') && (#form->isa('array') || #form->isa('map')) && #form->size > 0);
			iterate(local('form'), local('f'));
				!#f->isa('pair') ? loop_continue;
				$_cc_cmd_->insert('--form') & insert(#f->first + ': ' + #f->second);
			/iterate;
		/if;
		#has !>> 'Content-Type' ? $_cc_cmd_->insert('--header') & insert('Content-Type: application/json;charset=UTF-8');
		#has !>> 'Authorization' ? $_cc_cmd_->insert('--header') & insert('Authorization: Bearer ' + (local_defined('token') && #token != '' ? #token | cc_token()));
		if(local_defined('data') && (#data->isa('map') || #data->isa('array')));
			$_cc_cmd_->insert('--data-binary') & insert(encode_json(#data));
		/if;
		$_cc_cmd_->insert('--url') & insert($_cc_url_);

		loop(math_max(integer(local('retry')),1));
			// Call shell
			local('sh' = os_process(cc_curlpath, $_cc_cmd_));
			var('_cc_raw_' = #sh->read);
			// Process output
			if($_cc_raw_ == '');
				local('err' = #sh->readerror);
				fail_if(#err != '', -1, 'Curl Error: "' + #err + '"');
				sleep(1000); // retry delay
			/if;
		/loop;
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->size > 0 && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		return(@#output);
	/define_tag;

	define_tag('cc_curlpath', -optional='in', -namespace=namespace_global);
		local('out' = string(if_empty(local('in'),var('_cc_curlpath_'))));
		if(#out == '');
			local('sh' = os_process('/usr/bin/curl', array('-V')));
			#sh->read != '' ? local('out' = '/usr/bin/curl');
		/if;
		if(#out == '');
			local('sh' = os_process('/bin/sh', array('-l', '-c','which curl')));
			local('out' = #sh->read);
		/if;
		#out != '' ? var('_cc_curlpath_' = #out);
		return(@$_cc_curlpath_);
	/define_tag;

	define_tag('cc_sh_curl', -required='path', -optional='verb', -optional='data', -optional='params', -optional='form', -optional='headers', -optional='token', -namespace=namespace_global);

		// Assemble URL
		local('post' = '');
		local('and' = #post !>> '?' ? '?' | '&');
		if(local_defined('params') && #params->isa('array') && #params->size > 0);
			iterate(#params, local('p'));
				!#p->isa('pair') ? loop_continue;
				#post->append(#and + encode_stricturl(#p->first) + '=' + encode_stricturl(#p->second));
				#and = '&';
			/iterate;
		/if;
		if(#path !>> 'api_key=' && #path !>> 'client_id=');
			#post->append(#and + 'api_key=' + encode_stricturl(cc_apikey));
			#and = '&';
		/if;
		var('_cc_url_' = 'https://' + cc_endpoint + (#path !>> 'v2/' ? '/v2') + (!#path->beginswith('/') ? '/') + #path + local('post'));

		// Assemble curl command
		var('_cc_cmd_' = 'curl');
		$_cc_cmd_->append(' --silent');
		$_cc_cmd_->append(' --show-error');
		$_cc_cmd_->append(' --insecure'); // Does not check SSL certificates
		local_defined('verb') && #verb != '' ? $_cc_cmd_->append(' --request ' + string_uppercase(#verb));
		if(local_defined('headers') && (#headers->isa('array') || #headers->isa('map')) && #headers->size > 0);
			iterate(local('headers'), local('h'));
				!#h->isa('pair') ? loop_continue;
				$_cc_cmd_->append(' --header \'' + cc_encode(#h->first) + ': ' + cc_encode(#h->second) + '\'');
			/iterate;
		/if;
		if(local_defined('form') && (#form->isa('array') || #form->isa('map')) && #form->size > 0);
			iterate(local('form'), local('f'));
				!#f->isa('pair') ? loop_continue;
				$_cc_cmd_->append(' --form \'' + cc_encode(#f->first) + ': ' + cc_encode(#f->second) + '\'');
			/iterate;
		/if;
		$_cc_cmd_ !>> '--header "Content-Type' ? $_cc_cmd_->append(' --header \'Content-Type: application/json;charset=UTF-8\'');
		$_cc_cmd_ !>> '--header "Authorization' ? $_cc_cmd_->append(' --header \'Authorization: Bearer ' + cc_encode(local_defined('token') && #token != '' ? #token | cc_token()) + '\'');
		if(local_defined('data') && (#data->isa('map') || #data->isa('array')));
			$_cc_cmd_->append(' --data-binary \'' + cc_encode(encode_json(#data)) + '\'');
		/if;
		$_cc_cmd_->append(' --url \'' + cc_encode($_cc_url_) + '\'');

		// Call shell
		$_cc_cmd_ >> '!' ? $_cc_cmd_->replace('!','\\!');
		local('sh' = os_process('/bin/sh', array('-c', $_cc_cmd_)));
		var('_cc_raw_' = #sh->read);

		// Process output
		if($_cc_raw_ == '');
			local('err' = #sh->readerror);
			fail_if(#err != '', -1, 'Curl Error: "' + #err + '"');
		/if;
		local('output' = decode_json($_cc_raw_));
		fail_if(#output->isa('array') && #output->size > 0 && #output->get(1)->isa('map') && #output->get(1) >> 'error_message', -1, #output->get(1)->find('error_message') + ' (' + #output->get(1)->find('error_key') + ')');
		return(@#output);
	/define_tag;


	//
	// Debugging
	//

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

	// cc_cmd();
	// Returns the raw curl command
	define_tag('cc_cmd', -namespace=namespace_global);
		return(var('_cc_cmd_'));
	/define_tag;

?>
