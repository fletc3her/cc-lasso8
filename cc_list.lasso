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
	define_tag('cc_getlists', -required='listid', -namespace=namespace_global);
		return(cc_get('lists/' + integer(#listid)));
	/define_tag;

	//
	// Get List Members
	//
	// Use cc_findcontacts(-listid=ID)
	//

?>
