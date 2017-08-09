<cfparam name="attributes.remove" type="string" default="form" />

<cfswitch expression="#attributes.remove#">
	<cfcase value="form">
		<!--- shows the management form to import / remove coldbox apps --->
		<cfset getLib().ls("%tap_pluginmanager_title","Managing ColdBox Imports",true) />
		<cfinclude template="/plugins/coldbox/form.cfm" />
	</cfcase>
	
	<cfcase value="coldbox">
		<!--- remove any files that may have been installed by the plugin --->
		<cfset plugin.getConfig().uninstall()>
		
		<!--- indicate that the plugin state has changed to prompt 
		a reload of the framework and redirect the page to the plugin manager index --->
		<cfset plugin.setInstallationStatus(false) />
		
		<!--- return to the plugin manager index --->
		<cfoutput>#plugin.getPluginManager().goHome()#</cfoutput>
	</cfcase>
	
	<cfcase value="all">
		<!--- removes all imported coldbox apps --->
		<cfset plugin.getConfig().removeAll() />
		<cfoutput>#plugin.getPluginManager().goHome()#</cfoutput>
	</cfcase>
	
	<cfdefaultcase>
		<!--- removes a single imported coldbox app --->
		<cfset getIoC().getContainer("coldbox").uninstall(attributes.remove) />
		<cfoutput>#plugin.getPluginManager().goHome()#</cfoutput>
	</cfdefaultcase>
</cfswitch>

