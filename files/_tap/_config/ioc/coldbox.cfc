<cfcomponent extends="config" hint="manages ColdBox Application objects">
	
	<cffunction name="configure" access="public" output="false" returntype="void" hint="attach IoC containers to the manager here">
		<cfset var adapter = CreateObject("component","cfc.coldbox.appmanager").init() />
		<cfset addContainer("coldbox",adapter) />
	</cffunction>
	
</cfcomponent>