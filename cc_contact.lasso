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
	// Returns a minimal template map for a new contact. Requires an email address and the ID of a list (either
	// can be an array as well). Other parameters are added to the map or values can be added to the returned
	// map before the contact is submitted using cc_putcontact() (e.g. prefix_name, first_name, middle_name,
	// last_name, company_name, job_title, work_phone, etc.) The full list of values can be found here:
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contacts-resource.html
	//
	// Note - Do not add an ID member to a new contact or it will overwrite the contact with that ID
	//
	// cc_newcontact(parameters)
	// cc_newcontact('email'='user@server.com', 'list'=1)
	// Shortcuts:
	// 	   'email'='user@server.com' // or array
	// 	   'list'=1 // list ID or array of IDs
	define_tag('cc_newcontact', -namespace=namespace_global);
		local('emails' = array);
		local('lists' = array);
		local('output' = map);
		iterate(params, local('param'));
			!#param->isa('pair') ? loop_continue;
			local('name' = string(#param->first)->removeleading('-')&);
			local('value' = #param->second);
			if(#name == 'email');
				iterate(#value->isa('array') ? #value | array(#value), local('temp'));
					#emails->insert(map('email_address'=#temp));
				/iterate;
			else(#name == 'list');
				iterate(#value->isa('array') ? #value | array(#value), local('temp'));
					#lists->insert(map('id'=#temp));
				/iterate;
			else;
				#output->insert(#name = #value);
			/if;
		/iterate;
		#emails->size > 0 ? #output->insert('email_addresses'=#emails);
		#lists->size > 0 ? #output->insert('lists'=#lists);
		fail_if(#output !>> 'email_addresses', -1, 'New contact requires one or more emails');
		fail_if(#output !>> 'lists', -1, 'New contact requires one or more lists');
		return(@#output);
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
