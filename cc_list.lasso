<?LassoScript

	//
	// Constant Contact Contact List Library
	//
	// These tags allow contact lists (subscribers to campaigns) to be accessed. Requires the tags in the
	// Constant Contact Utility Library cc.lasso.
	//
	// http://developer.constantcontact.com/docs/contact-list-api/contactlist-collection.html
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	//
	// Find Lists
	//
	// http://developer.constantcontact.com/docs/contacts-api/contacts-collection.html
	//
	// cc_findlists() // All lists
	// -modified_since=date
	define_tag('cc_findlists', -optional='modified_since', -namespace=namespace_global);
		local('params' = array);
		local_defined('modified_since') && #modified_since != '' ? #params->insert('modified_since'=cc_date(#modified_since));
		return(cc_get('lists', -params=#params));
	/define_tag;

	//
	// Get List
	//
	// http://developer.constantcontact.com/docs/contact-list-api/contactlist-collection.html
	//
	// cc_getlist('3')
	// The ID can be a list number (3), the ID attribute of a List record
	// Or the names of the special lists do_not_contact, active, bounced, removed
	// cc_getlist(cc_findlists()->get(1)->find('id'));
	define_tag('cc_getlist', -required='listid', -namespace=namespace_global);
		return(cc_get('lists/' + integer(#listid)));
	/define_tag;

	//
	// Get List Members
	//
	// Use cc_findcontacts(-listid=ID)
	//

	//
	// New List Template
	//
	// Returns a minimal template map for a new list. Requires a list name and a status (VISIBLE or HIDDEN)
	//
	// http://developer.constantcontact.com/docs/contacts-api/contactlist-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contactlist-resource.html
	//
	// Note - Do not add an ID member to a new list or it will overwrite the list with that ID
	//
	// cc_newlist(parameters)
	// cc_newlist('name'='My List', 'status'='ACTIVE')
	define_tag('cc_newlist', -namespace=namespace_global);
		local('output' = map);
		iterate(params, local('param'));
			!#param->isa('pair') ? loop_continue;
			local('name' = string(#param->first)->removeleading('-')&);
			local('value' = #param->second);
			#output->insert(#name = #value);
		/iterate;
		fail_if(#output !>> 'name', -1, 'New list requires a name');
		fail_if(#output !>> 'status', -1, 'New list requires a status');
		return(@#output);
	/define_tag;

	//
	// Put List or Post New List
	//
	// http://developer.constantcontact.com/docs/contacts-api/contactlist-collection.html?method=POST
	// http://developer.constantcontact.com/docs/contacts-api/contactlist-resource.html
	//
	// cc_putlist(map)
	// expects the output of cc_getlist (or cc_newlist) as input
	// puts (or posts new lists) the data on the server
	define_tag('cc_putlist', -required='input', -namespace=namespace_global);
		fail_if(!#input->isa('map'), -1, 'Input not a map');
		if(#input !>> 'id');
			// Post New List
			return(cc_post('lists', -data=#input));
		else;
			// Push Contact
			return(cc_put('lists/' + integer(#input->find('id')), -data=#input));
		/if;
	/define_tag;

	//
	// Delete List
	//
	// http://developer.constantcontact.com/docs/contacts-api/contactlist-resource.html
	//
	// cc_deletecontact(id)
	// cc_deletecontact(map)
	// Accepts either an ID or a list map from the output of cc_getlist()
	// deletes the list from the server
	define_tag('cc_deletelist', -required='input', -namespace=namespace_global);
		if(#input->isa('map'));
			fail_if(#input !>> 'id', -1, 'Input does not contain ID');
			return(cc_delete('lists/' + integer(#input->find('id'))));
		else;
			fail_if(#input == '' || #input == '0', -1, 'Requires non-zero input');
			return(cc_delete('lists/' + integer(#input)));
		/if;
	/define_tag;

?>
