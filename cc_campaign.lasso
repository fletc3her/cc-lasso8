<?LassoScript

	//
	// Constant Contact Campaign Library
	//
	// These tags allow campaigns (individual messages sent to contact lists) to be accessed. Requires the tags
	// in the Constant Contact Utility Library cc.lasso.
	//
	// http://v2.developer.constantcontact.com/docs/email-campaigns/email-campaign-api-index.html
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	//
	// Find Campaigns
	//
	// http://v2.developer.constantcontact.com/docs/email-campaigns/email-campaigns-collection.html
	//
	// cc_findcampaigns() // All campaigns
	// -modified_since=date
	// -limit=50 // Max records, default 50
	// -next={pagination} // Use cc_next to extract from results
	// -status='draft' // Draft, can be modified
	// -status='running' // Mail is currently being sent (read-only)
	// -status='sent' // Mail has been sent (read-only)
	// -status='scheduled' // Scheduled for future send (modify by setting to draft)
	define_tag('cc_findcampaigns', -optional='modified_since', -optional='limit', -optional='status', -optional='next');
		local('params' = array);
		local_defined('modified_since') && #modified_since != '' ? #params->insert('modified_since'=cc_date(#modified_since));
		local_defined('status') && #status != '' ? #params->insert('status'=#status);
		local_defined('limit') && #limit != '' ? #params->insert('limit'=#limit);
		if(local_defined('next') && #next != '');
			#params = array('next'=#next);
		/if;
		return(cc_get('emailmarketing/campaigns', -params=#params));
	/define_tag;

	//
	// Get Campaign
	//
	// cc_getcampaign('3');
	// The ID can be a campaign number 3, the ID attribute of a Campaign record
	// cc_getcampaign(cc_findcampaigns()->get(1)->find('id'));
	define_tag('cc_getcampaign', -required='campaignid');
		return(cc_get('emailmarketing/campaigns/' + integer(#campaignid)));
	/define_tag;

	//
	// Get Campaign Tracking Summary
	//
	// cc_getcampaigntrackingsummary('3');
	// The ID can be a campaign number 3, the ID attribute of a Campaign record
	// cc_getcampaign(cc_findcampaigns()->get(1)->find('id'));
	define_tag('cc_getcampaigntrackingsummary', -required='campaignid');
		return(cc_get('emailmarketing/campaigns/' + integer(#campaignid) + '/tracking/reports/summary'));
	/define_tag;

	//
	// New Campaign Template
	//
	// Returns a minimal template map for a new campaign. Requires the following parameters:
	// 'name'='name', // Name of the campaign
	// 'subject'='subject', // Subject for the email
	// 'from_email'='address' // Sender address
	// 'from_name'='name', // Sender name
	// 'reply_to_email'='address', // Reply-to address
	// 'email_content'='html/xhtml' // Message content
	// 'email_content_format'='html' // Content type HTML (default) or XHTML
	// 'text_content'='text' // Message content
	//
	// There are many other parameters which can be specified.  See the online help for a list.

	// http://v2.developer.constantcontact.com/docs/email-campaigns/email-campaigns-collection.html?method=POST
	//
	// Note - Do not add an ID member to a new campaign or it will overwrite the campaign with that ID
	//
	// cc_newcampaign
	// -email='user@server.com' // or array
	// -list=1 // list ID or array of IDs
	define_tag('cc_newcampaign', -required='email', -required='list', -namespace=namespace_global);
		local('output' = map);
		local('required' = array('name','subject','from_email','from_name','reply_to_email','email_content','text_content'));
		iterate(params, local('param'));
			!#param->isa('pair') ? loop_continue;
			local('name' = string(#param->first)->removeleading('-')&);
			local('value' = #param->second);
			#required->removeall(#name);
			#output->insert(#name = #value);
		/iterate;
		fail_if(#required->size > 0, -1, 'New campaign requires field' + (#required->size > 1 ? 's') + ': ' + #required->join(', '));
		return(@#output);
	/define_tag;

	// cc_putcampaign(map)
	// expects the output of cc_getcampaign (or cc_newcampaign) as input
	// updates the embedded xml and puts (or posts) the data on the server
	define_tag('cc_putcampaign', -required='input');
		fail_if(!#input->isa('map'), -1, 'Input not a map');
		if(#input !>> 'id');
			// Post New Campaign
			cc_post('emailmarketing/campaigns', -data=#input);
		else;
			// Push Campaign
			cc_post('emailmarketing/campaigns/' + integer(#input->find('id')), -data=#input);
		/if;
	/define_tag;

	//
	// Get Campaign Preview
	//
	// cc_getcampaignpreview('3');
	// The ID can be a campaign number 3, the ID attribute of a Campaign record
	// cc_getcampaignpreview(cc_findcampaigns()->get(1)->find('id'));
	define_tag('cc_getcampaignpreview', -required='campaignid');
		return(cc_get('emailmarketing/campaigns/' + integer(#campaignid) + '/preview'));
	/define_tag;

	//
	// Send Campaign Test
	//
	// cc_testcampaign('3', -email_addresses='test@example.com', -format='html_and_text', -personal_message='testing');
	// The ID can be a campaign number 3, the ID attribute of a Campaign record
	// cc_testcampaign(cc_findcampaigns()->get(1)->find('id'), ...);
	define_tag('cc_testcampaign', -required='campaignid', -optional='email_addresses', -optional='format', -optional='personal_message');
		local('required' = array('email_addresses','format','personal_message'));
		local('form' = map);
		iterate(params, local('param'));
			!#param->isa('pair') ? loop_continue;
			local('name' = string(#param->first)->removeleading('-')&);
			local('value' = #param->second);
			#required->removeall(#name);
			if(#name == 'email_addresses');
				iterate(#value->isa('array') ? #value | array(#value), local('v'));
					if(#form >> #name);
						#form->find(#name)->insert(#v);
					else;
						#form->insert(#name = array(#v));
					/if;
				/iterate;
			else;
				#form->insert(#name = #value);
			/if;
		/iterate;
		fail_if(#required->size > 0, -1, 'Testing campaign requires field' + (#required->size > 1 ? 's') + ': ' + #required->join(', '));
		// Push Campaign
		cc_post('emailmarketing/campaigns/' + integer(#campaignid) + '/tests', -data=#form);
	/define_tag;

	//
	// Get Campaign Schedules
	//
	// cc_getcampaignschedules('3');
	// The ID can be a campaign number 3, the ID attribute of a Campaign record
	// cc_getcampaignschedules(cc_findcampaigns()->get(1)->find('id'));
	define_tag('cc_getcampaignschedules', -required='campaignid');
		return(cc_get('emailmarketing/campaigns/' + integer(#campaignid) + '/campaigns'));
	/define_tag;


?>
