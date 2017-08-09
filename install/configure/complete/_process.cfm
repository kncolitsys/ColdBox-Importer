<!--- this file overrides the framework's default view to perform the plugin installation if applicable --->
<cf_validate form="#variables.installForm#">
	<cfset htlib = getLib().html />
	
	<cftry>
		<cfparam name="attributes.appname" type="string" default="" />
		<cfparam name="attributes.location" type="string" default="" />
		<cfparam name="attributes.path" type="string" default="" />
		
		<cfset attributes.appname = lcase(trim(attributes.appname)) />
		<cfset attributes.location = trim(attributes.location) />
		<cfset attributes.path = lcase(trim(attributes.path)) />
		
		<cfif len(trim(attributes.appname))>
			<!--- perform some validation of the user inputs to ensure that the installation provides reasonable values, 
			-- i.e. if there is no Application.cfc, then we can't import the app, and we don't want to generate any files 
			-- with strange characters like $ in them during the import process, so we don't allow those in path or name ---> 
			<cfif not refindnocase("^[A-Za-z0-9_]+$",attributes.appname)>
				<cfthrow type="form" message="The application name can contain only letters, numbers and underscores" />
			</cfif>
			<cfif not refindnocase("^\w[-A-Za-z0-9_/]+$",attributes.path)>
				<cfthrow type="form" message="The local path can contain only letters, numbers, underscores and forward-slashes, beginning with a letter" />
			</cfif>
			<cfif not FileExists(attributes.location & "/Application.cfc")>
				<cfset temp = ExpandPath("/" & attributes.location) />
				<cfif fileExists(temp & "/Application.cfc")>
					<cfset attributes.location = temp />
				<cfelse>
					<cfthrow type="form" message="There is no Application.cfc in the directory #htmleditformat(attributes.location)#." />
				</cfif>
			</cfif>
		</cfif>
		
		<!--- the same form is also used to import / install new coldbox apps, 
		-- so we need to check to be sure this is the initial installation --->
		<cfif not plugin.isInstalled()>
			<cfset plugin.getConfig().install() />
		</cfif>
		
		<!--- then we check to see if they provided some application info --->
		<cfif len(trim(attributes.appname))>
			<cfset getIoC().getContainer("coldbox").install(attributes.appname,attributes.location,attributes.path) />
		</cfif>
		
		<!--- let the pluginmanager know that this plugin has been successfully installed --->
		<cfset plugin.setInstallationStatus(true) />
		
		<!--- return the user to the plugin list --->
		<cfoutput>#plugin.getPluginManager().goHome()#</cfoutput>
		<cf_abort />
		
		<cfcatch type="any">
			<!--- only remove files, etc. if we failed to install the plugin --->
			<cfif not plugin.isInstalled() and cfcatch.type is not "form">
				<cfset plugin.getConfig().uninstall() />
			</cfif>
			<!--- something went wrong during installation, display the error --->
			<cfset htlib.childAdd(pluginManager.view.error,"<p>#cfcatch.message#</p><p>#cfcatch.detail#</p>")>
		</cfcatch>
	</cftry>
</cf_validate>

<cfinclude template="/inc/pluginmanager/view.cfm">
