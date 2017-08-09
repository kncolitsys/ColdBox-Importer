<!--- this file checks to make sure the user is running a version of the onTap framework 
	that will support the plugin - earlier versions may not support it, so we check here to be sure --->

<cfset minversion = 3.3>
<cfset minbuild = 20091012>
<cfif not plugin.checkDependency("ontapframework",minversion,minbuild)>
	<cf_html parent="#pluginmanager.view.error#">
		<div xmlns:tap="xml.tapogee.com">
			<cfoutput>
				<p>This version of the #getLib().xmlFormat(plugin.getValue('name'))# plugin requires 
				version #minversion# build number #minbuild# or later of the onTap framework.</p>
			</cfoutput>
			
			<p><tap:text>Download the latest version at </tap:text>
			<a href="http://on.tapogee.com" /></p>
		</div>
	</cf_html>
	
	<!--- display the error message and abort the request --->
	<cfinclude template="/inc/pluginmanager/view.cfm">
	<cf_abort>
</cfif>