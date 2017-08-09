<cfcomponent output="false" extends="cfc.ontap">
	<cfset setValue("source",listlast(thispath(),"/\")) />
	
	<cffunction name="init" access="public">
		<cfargument name="plugin" type="any" required="true" />
		<cfset setValue("plugin",arguments.plugin) />
		<cfreturn this>
	</cffunction>
	
	<cffunction name="thisPath" access="private" output="false" returntype="string">
		<cfreturn getDirectoryFromPath(getCurrentTemplatePath())>
	</cffunction>
	
	<cffunction name="install" access="public" output="false">
		<cfset attachIoCContainer() />
		<cfset installFiles() />
	</cffunction>
	
	<cffunction name="uninstall" access="public" output="false">
		<cfset removeFiles() />
		<cfset detachIoCContainer() />
	</cffunction>
	
	<cffunction name="attachIoCContainer" access="public" output="false">
		<cfset var adapter = CreateObject("component","files._tap._cfc.coldbox.appmanager").init() />
		<cfset getIoC().addContainer("coldbox",adapter) />
	</cffunction>
	
	<cffunction name="detachIoCContainer" access="public" output="false">
		<cfset getIoC().detach("coldbox") />
	</cffunction>
	
	<cffunction name="getFile" access="public" output="false">
		<cfargument name="filename" type="string" required="true" />
		<cfargument name="directory" type="string" required="false" default="#thispath()#" />
		<cfargument name="type" type="string" required="false" default="text" />
		<cfreturn CreateObject("component","cfc.file").init(filename,directory,type) />
	</cffunction>
	
	<cffunction name="getFileMap" access="private" output="false">
		<cfreturn getFile(filename="files/map.xml.cfm",type="wddx") />
	</cffunction>
	
	<cffunction name="installFiles" access="public" output="false">
		<cfset myfile = getFile("files/docs") />
		<cfset map = getFileMap() />
		
		<!--- move the plugin documentation to the documentation section --->
		<cfset myfile.move("plugins/" & getValue("source"),"docs") />
		
		<!--- make a map of other files to install - we'll need this if we uninstall later --->
		<cfset map.write(myFile.init("files/_tap",thispath()).map()) />
		
		<!--- install the remaining files --->
		<cfset myFile.move("","P") />
	</cffunction>
	
	<cffunction name="removeFiles" access="public" output="false">
		<cfset var map = getFileMap() />
		<cfset var myfile = getFile("plugins/" & getValue("source"),"docs") />
		
		<!--- remove the plugin documentation from the documentation section --->
		<cfset myfile.move("files/docs",thispath()) />
		
		<cfif not map.exists()>
			<cfif getValue("plugin").isInstalled()>
				<cfthrow type="application" 
				message="Could not fine the file map - the system doesn't know which files to remove." 
				detail="#map.getValue('filepath')#" />
			<cfelse>
				<cfreturn />
			</cfif>
		</cfif>
		
		<!--- remove other files --->
		<cfset myfile.init("","P").move("files/_tap",thispath(),map.read()) />
		<cfset map.delete() />
	</cffunction>
	
	<cffunction name="removeAll" access="public" output="false">
		<cfset var ioc = getIoC().getContainer("coldbox") />
		<cfset var rsColdBox = ioc.getImportedApplicationList() />
		<cfloop query="rsColdBox">
			<cfset ioc.uninstall(rsColdBox.name) />
		</cfloop>
	</cffunction>
</cfcomponent>