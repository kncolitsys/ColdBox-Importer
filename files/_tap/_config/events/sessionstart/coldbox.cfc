<cfcomponent extends="config">
	
	<cffunction name="configure" access="public" output="false" returntype="void" hint="execute event code in this method">
		<cfset getIoC().getContainer("coldbox").ExecuteEvent("onSessionStart") />
	</cffunction>
	
</cfcomponent>