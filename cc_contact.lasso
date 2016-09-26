<?LassoScript

	//
	// Constant Contact Contact Library
	//
	// These tags allow contacts (individual end users) to be accessed. Requires the tags in the Constant
	// Contact Utility Library cc.lasso.
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-index.html
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	//
	// Find Contacts
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html
	//
	// cc_findcontacts() All contacts
	// -email='john@doe.com' // One email
	// -email=array('john@doe.com','jill@doe.com') // Multiple emails
	// -listid={listid} // Contacts for one list (Only supports modified_since and limit)
	// -modified_since=date
	// -limit=50 // Max records, default 50
	// -next={pagination} // Use cc_next to extract from results
	// -status='active' // Subscribed
	// -status='unconfirmed' // Subscribed, but not confirmed
	// -status='optout' // Do Not Mail
	// -status='removed' // Unsubscribed
	define_tag('cc_findcontacts', -optional='email', -optional='listid', -optional='modified_since', -optional='status', -optional='limit', -optional='next', -namespace=namespace_global);
		local('params' = array);
		if(local_defined('listid') && #listid != '');
			local('path' = 'lists/' + integer(#listid) + '/contacts');
		else;
			local('path' = 'contacts');
			local_defined('email') && #email != '' ? #params->insert('email'=#email);
			local_defined('status') && #status != '' ? #params->insert('status'=#status);
		/if;
		local_defined('modified_since') && #modified_since != '' ? #params->insert('modified_since'=cc_date(#modified_since));
		local_defined('limit') && #limit != '' ? #params->insert('limit'=#limit);
		if(local_defined('next') && #next != '');
			#params = array('next'=#next);
		/if;
		return(cc_get(#path, -params=#params, -retry=5));
	/define_tag;

	//
	// Get Contact
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// cc_getcontact('35')
	// The ID can be a contact number (35), the ID attribute of a Contact record
	// cc_getcontact(cc_findcontacts('email'='john@doe.com')->get(1)->find('id'));
	define_tag('cc_getcontact', -required='contactid', -namespace=namespace_global);
		return(cc_get('contacts/' + integer(#contactid)));
	/define_tag;

	//
	// Get Contact Tracking
	//
	// http://developer.constantcontact.com/docs/contact-tracking/contact-tracking-all-activities-api.html
	//
	// cc_getcontacttracking('35')
	// The ID is be a contact number (35), the ID attribute of a Contact record
	// cc_getcontact(cc_findcontacts('email'='john@doe.com')->get(1)->find('id'));
	// -contactid={contactid}
	// -type={bounces, clicks, forwards, opens, reports/summary, reports/summarybycampaign, sends, unsubscribes} (default: all)
	// -created_since=date
	// -limit=50 // Max records, default 50
	// -next={pagination} // Use cc_next to extract from results
	define_tag('cc_getcontacttracking', -required='contactid', -optional='type', -optional='created_since', -optional='limit', -optional='next', -namespace=namespace_global);
		local('path' = 'contacts/' + integer(#contactid) + '/tracking');
		if(local_defined('type'));
			if(#type >> 'summarybycampaign');
				#path->append('/reports/summaryByCampaign');
			else(#type >> 'summary');
				#path->append('/reports/summary');
			else(#type != '');
				#path->append('/' + string(#type));
			/if;
		/if;
		local('params' = array);
		local_defined('created_since') && #created_since != '' ? #params->insert('created_since'=cc_date(#created_since));
		local_defined('limit') && #limit != '' ? #params->insert('limit'=#limit);
		local_defined('next') && #next != '' ? #params->insert('next'=#next);
		return(cc_get(#path, -params=#params));
	/define_tag;

	//
	// New Contact Template
	//
	// Returns a minimal template map for a new contact.  The cc_setcontact(parameters) tag can be used to
	// efficiently set values for the new contact if necessary.  Or, the map structure can be manipulated
	// directly.
	// The full list of values in a new template can be found here:
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// Note - Do not add an ID member to a new contact or it will overwrite the contact with that ID
	//
	// cc_newcontact()
	define_tag('cc_newcontact', -namespace=namespace_global);
		return(map(
			'cell_phone'='',
			'company_name'='',
			'email_addresses'=array(map('email_address'='')),
			'fax'='',
			'first_name'='',
			'home_phone'='',
			'job_title'='',
			'last_name'='',
			'lists'=array,
			'middle_name'='',
			'prefix_name'='',
			'work_phone'=''
		));
	/define_tag;

	//
	// Set Contact
	//
	// Any parameters modify values in the map for the contact.  Simple
	// parameters modify the corresponding map element to the new value.  The
	// contact is modified in-place.  The result is true if the contact was
	// modified or false otherwise.
	//
	// Several parameter names are specially handled:
	//
	// -email_address='address' can be specified to replace the email address of the contact.
	//
	// -list='id' or -lists=array('id') sets the lists to the specified set of IDs
	// -addlist='id' or -addlists=array('id') can be specified one or more times to subscribe the contact to lists
	// -remlist='id' or -remlists=array('id') can be specified one or more times to unsubscribe the contact from lists
	// -nolists can be specified to empty the list array, unsubscribing the contact from all lists
	//
	// The full list of possible parameters can be found here:
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// Note - Do not add an ID member to a new contact or it will overwrite the contact with that ID
	//
	// cc_setcontact(contact, parameters) => boolean
	// cc_setcontact(contact, 'email_address'='user@server.com', 'list'=1)
	define_tag('cc_setcontact', -required='input', -optional='params', -namespace=namespace_global);
		local('changed' = false);
		#input !>> 'email_addresses' || !#input->find('email_addresses')->isa('array') ? #input->insert('email_addresses' = array);
		#input !>> 'lists' || !#input->find('lists')->isa('array') ? #input->insert('lists' = array);
		iterate(params, local('param'));
			!#param->isa('pair') ? loop_continue;
			local('name' = string(#param->first)->removeleading('-')&);
			#name == 'input' || #name == 'params' ? loop_continue;
			local('value' = #param->second);
			if(#name == 'email_address');
				iterate(#value->isa('array') ? #value | array(#value), local('temp'));
					if(#input >> 'email_addresses' && #input->find('email_addresses')->isa('array'));
						#input->find('email_addresses')->removeall;
						#input->find('email_addresses')->insert(map('email_address'=#temp));
					else;
						#input->insert('email_addresses' = array(map('email_address'=#temp)));
					/if;
				/iterate;
				#changed = true;
			else(#name == 'list' || #name == 'lists' || #name == 'addlist' || #name == 'addlists' || #name == 'remlist' || #name == 'remlists' || #name == 'nolist' || #name == 'nolists');
				if(#input !>> 'lists' || !#input->find('lists')->isa('array'));
					#input->insert('lists' = array);
				/if;
				if(#name == 'list' || #name == 'lists');
					#input->find('lists')->removeall;
					iterate(#value->isa('array') ? #value | array(#value), local('temp'));
						#input->find('lists')->insert(map('id'=string(#temp),'status'='ACTIVE'));
					/iterate;
					#changed = true;
				else(#name == 'addlist' || #name == 'addlists');
					iterate(#value->isa('array') ? #value | array(#value), local('temp'));
						#input->find('lists')->insert(map('id'=string(#temp),'status'='ACTIVE'));
					/iterate;
					#changed = true;
				else(#name == 'remlist' || #name == 'remlists');
					iterate(#value->isa('array') ? #value | array(#value), local('temp'));
						loop(-from=#input->find('lists')->size, -to=1, -by=-1);
							#input->find('lists')->get(loop_count)->find('id') == #temp ? #input->find('lists')->remove(loop_count);
						/loop;
					/iterate;
					#changed = true;
				else(#name == 'nolist' || #name == 'nolists');
					#input->find('lists')->removeall;
					#changed = true;
				/if;
			else;
				if(#input->find(#name) != #value);
					#input->insert(#name = #value);
					#changed = true;
				/if;
			/if;
		/iterate;
		return(@#changed);
	/define_tag;

	//
	// Process Form
	//
	// An array of parameters modify values in the map for the contact. The
	// contact is modified in-place.  The result is true if the contact was
	// modified or false otherwise.
	//
	// Specifies a set of parameters using -Params (usually action parameters)
	// which must be in one of the following formats. The first simply appends
	// the contactid to the start of the name which can make editing multiple
	// contacts easier.  New contacts have an empty contactid so the parameter
	// names start with a colon. Elements with array values can have their
	// elements set by including the elementid in the name. One new element can
	// be added to an array by omitting the elementid.
	//
	// contactid:name = value (sets name in specified contact only)
	// contactid:name:elementid:name = value (sets name in specified element)
	//
	// The full list of possible parameters can be found here:
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// Note - Do not add an ID member to a new contact or it will overwrite the contact with that ID
	//
	// cc_processform(contact, action_params) => boolean
	define_tag('cc_processform', -required='input', -required='params', -optional='prefix', -namespace=namespace_global);
		local('_prefix' = string(local('prefix')) + #input->find('id') + ':');
		local('changed' = false);
		local('lists' = array);
		iterate(#params, local('param'));
			!#param->isa('pair') ? loop_continue;
			!#param->first->beginswith(#_prefix) ? loop_continue;
			local('name' = #param->first - #_prefix);
			if(#name == 'lists');
				#lists->insert(#param->second);
			else(#name >> ':');
				local('parse' = #name->split(':'));
				#parse->size < 3 ? loop_continue;
				local('name' = #parse->get(1));
				local('id' = #parse->get(2));
				local('ename' = #parse->get(3));
				#input !>> #name ? loop_continue;
				if(#id != '');
					iterate(#input->find(#name),local('etemp'));
						if(#etemp->find('id') == #id);
							local('echanged' = cc_processform(#etemp,-params=array(#id + ':' + #ename=#param->second)));
							#changed = #changed || #echanged;
						/if;
					/iterate;
				else;
					#input->find(#name)->insert(map(#ename,#param->second));
				/if;
			else;
				#input !>> #name ? loop_continue;
				#input->find(#name) == #param->second ? loop_continue;
				#input->insert(#name = #param->second);
				#changed = true;
			/if;
		/iterate;
		// Remove unchecked lists from cc_contact
		loop(-from=#input->find('lists')->size, -to=1, -by=-1);
			if(#lists !>> #input->find('lists')->get(loop_count)->find('id'));
				#input->find('lists')->remove(loop_count);
				#changed = true;
			/if;
		/loop;
		// Remove existing lists from lists variable
		iterate(#input->find('lists'), local('list'));
			#lists->removeall(#list->find('id'));
		/iterate;
		// Add new lists to cc_contact
		iterate(#lists,local('listid'));
			#input->find('lists')->insert(map('id'=#listid, 'status'='ACTIVE'));
			#changed = true;
		/iterate;
		return(@#changed);
	/define_tag;


	//
	// Put Contact or Post New Contact
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html?method=POST
	//
	// cc_putcontact(map)
	// -by='owner' // Default, action by list owner (email sender)
	// -by='visitor' // Action by end-user site visitor (email receiver)
	// expects the output of cc_getcontact (or cc_newcontact) as input
	// puts (or posts new contacts) the data on the server
	define_tag('cc_putcontact', -required='input', -optional='by', -namespace=namespace_global);
		fail_if(!#input->isa('map'), -1, 'Input not a map');
		local('params' = array('action_by'=(local('by') >> 'owner' ? 'ACTION_BY_OWNER' | 'ACTION_BY_VISITOR')));
		if(#input !>> 'id');
			// Post New Contact
			fail_if(#input !>> 'email_addresses' || #input->find('email_addresses')->size == 0, -1, 'New contact requires one or more emails');
			fail_if(#input !>> 'lists' || #input->find('lists')->size == 0, -1, 'New contact requires one or more lists');
			return(cc_post('contacts', -data=#input, -params=#params));
		else;
			// Push Contact
			return(cc_put('contacts/' + integer(#input->find('id')), -data=#input, -params=#params));
		/if;
	/define_tag;

	//
	// Delete Contact
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// cc_deletecontact(id)
	// cc_deletecontact(map)
	// Accepts either an ID or a contact map from the output of cc_getcontact()
	// deletes the contact from the server
	define_tag('cc_deletecontact', -required='input', -namespace=namespace_global);
		if(#input->isa('map'));
			fail_if(#input !>> 'id', -1, 'Input does not contain ID');
			return(cc_delete('contacts/' + integer(#input->find('id'))));
		else;
			fail_if(#input == '' || #input == '0', -1, 'Requires non-zero input');
			return(cc_delete('contacts/' + integer(#input)));
		/if;
	/define_tag;

?>
