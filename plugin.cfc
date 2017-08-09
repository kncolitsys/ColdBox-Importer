<cfcomponent output="false" extends="cfc.plugin">
	<cfscript>
		setValue("name","ColdBox Importer"); 
		setValue("version","1.0"); 
		setValue("revision","beta"); 
		setValue("releasedate","12-Oct-2009"); 
		setValue("buildnumber",dateformat(getValue("releasedate"),"yyyymmdd")); 
		setValue("description","Imports and executes ColdBox applications within the context of your onTap application."); 
		setValue("providerName","Projects onTap"); 
		setValue("providerEmail","info@tapogee.com"); 
		setValue("providerURL","http://ontap.riaforge.org"); 
		setValue("install","install/license"); 
		setValue("remove","remove"); 
		setValue("docs","coldbox"); 
	</cfscript>
	
	<cffunction name="getConfig" access="public" output="false">
		<cfif not structKeyExists(variables,"config")>
			<cfset variables.config = CreateObject("component","config").init(this) />
		</cfif>
		<cfreturn variables.config />
	</cffunction>
	
	<cffunction name="getWizardIndex" access="public" output="false">
		<cfargument name="html" type="struct" required="true" />
		<cfset var ht = getLib().html />
		<cfset var button = 0 />
		<cfif this.isInstalled()>
			<cfset button = ht.elementArray(html,structNew(),"button") />
			<cfif arraylen(button)>
				<cfset ht.childSet(button[1],1,"Manage Imports") />
			</cfif>
		</cfif>
	</cffunction>
	
</cfcomponent>
