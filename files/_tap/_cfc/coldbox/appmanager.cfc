<cfcomponent displayname="ColdBox.AppManager" extends="cfc.ontap" output="false">
	
	<cfset variables.instance = structNew() />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="string" required="false" default="#ExpandPath('/tap/_tap/_config/coldbox.xml.cfm')#" />
		
		<!--- make sure the config path is an unadulterated strait path from the file system root --->
		<cfset arguments.config = CreateObject("java","java.io.File").init(arguments.config).getCanonicalPath() />
		
		<!--- set instance variables --->
		<cfset structAppend(instance,arguments,true) />
		<cfset structDelete(instance,"xml") />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getConfig" access="private" output="false">
		<cfif not structKeyExists(instance,"xml")>
			<cfif fileExists(instance.config)>
				<cfset instance.xml = XmlParse(instance.config) />
			<cfelse>
				<cfset instance.xml = XmlParse("<coldbox />") />
			</cfif>
		</cfif>
		<cfreturn instance.xml />
	</cffunction>
	
	<cffunction name="SaveConfig" access="private" output="false">
		<cffile action="write" file="#instance.config#" output="#trim(toString(getConfig()))#" charset="UTF-8" addnewline="false" />
	</cffunction>
	
	<cffunction name="getAppConfig" access="private" output="false">
		<cfargument name="appname" type="string" required="true" />
		<cfset var array = XmlSearch(getConfig(),"/*/app[@name='#lcase(arguments.appname)#']") />
		<cfreturn array[1] />
	</cffunction>
	
	<cffunction name="getEventFile" access="private" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfreturn CreateObject("component","cfc.file").init("",ExpandPath("/tap/_tap/#arguments.path#")) />
	</cffunction>
	
	<cffunction name="getColdBoxApplicationPath" access="private" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="location" type="string" required="true" />
		<cfset var goback = repeatString("../",listlen(path,"/\")) />
		<cfset var result = listchangedelims(goback & "/" & location,"/","\/") & "/" />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="writeApplicationCFC" access="private" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfargument name="location" type="string" required="true" />
		<cfset var extend = listchangedelims(arguments.location,".","\/") & ".Application" />
		<cfset var f = CreateObject("component","cfc.file").init("coldbox/app/#arguments.name#.cfc","CFC") />
		<cfset var fbpath = getColdBoxApplicationPath(arguments.path,arguments.location) />
		<cfset var oApp = CreateObject("component",extend) />
		<cfset var content = ArrayNew(1) />
		
		<cfset ArrayAppend(content,"<cfcomponent extends=""#extend#"" output=""false"">") />
		<cfset ArrayAppend(content,"	<cfset variables.COLDBOX_APP_ROOT_PATH = ExpandPath(""/#location#"") />") />
		<cfset ArrayAppend(content,"	<cfset variables.COLDBOX_APP_KEY = ""cbx_#name#"" />") />
		<cfif not structKeyExists(oApp,"onRequestEnd")>
			<!--- the root component coldbox.system.coldbox doesn't have an onRequestEnd method, 
			-- so the application won't have one unless the author provided one 
			-- this ensures we have one later when we're running the app in our context 
			-- and simplifies the logic for ExecuteEvent() --->
			<cfset ArrayAppend(content,"	<cffunction name=""onRequestEnd"" access=""public"" output=""false""></cffunction>") />
		</cfif>
		<cfset ArrayAppend(content,"</cfcomponent>") />
		
		<cfset f.write(ArrayToList(content,chr(13) & chr(10))) />
	</cffunction>
	
	<cffunction name="extractContent" access="public" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfset var app = getBean(arguments.name) />
		<cfset var config = getAppConfig(arguments.name) />
		
		<cfreturn CreateObject("component","cfc.coldbox.contentextractor").init(app,config.xmlAttributes.location).extractContent() />
	</cffunction>
	
	<cffunction name="writeRequestEvents" access="private" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfset var f = getEventFile(arguments.path) />
		
		<cfset f.setValue("file","/_application/100_coldbox.cfm").write("<cfset tap.view.content = getIoC().getContainer('coldbox').extractContent('#name#') />") />
		<cfset f.setValue("file","/_onrequestend/100_coldbox.cfm").write("<cfset getIoC().getBean('#name#','coldbox').onRequestEnd(cgi.script_name) />") />
		
		<cfif not f.init(path & ".cfm","T").exists()>
			<cfset f.write("<cfinclude template=""/tags/process.cfm"" />") />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteRequestEvents" access="private" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfset var f = getEventFile(arguments.path) />
		<cfset f.setValue("file","/_application/100_coldbox.cfm").delete() />
		<cfset f.setValue("file","/_onrequestend/100_coldbox.cfm").delete() />
	</cffunction>
	
	<cffunction name="install" access="public" output="false">
		<cfargument name="name" type="string" required="true" hint="name of the coldbox application as it will be internally referenced in the onTap framework" />
		<cfargument name="location" type="string" required="false" default="#ExpandPath('/' & name)#" hint="full path to the ColdBox application directory (not the framework directory)" />
		<cfargument name="path" type="string" required="false" default="#name#/index" hint="application path - how the FB app will be referenced by a browser" />
		<cfargument name="coldbox" type="string" required="false" default="5.5.1" hint="the version of ColdBox framework the installed application runs under" />
		
		<!--- create a new xml element to store the config --->
		<cfset var xml = getConfig() />
		<cfset var node = XmlElemNew(xml,"app") />
		<cfset var i = 0 />
		
		<!--- format the app config to make sure it's consistent --->
		<cfset arguments.name = trim(lcase(arguments.name)) />
		<cfset arguments.path = trim(lcase(arguments.path)) />
		<cfset arguments.location = removechars(arguments.location,1,len(ExpandPath('/'))) />
		
		<!--- add config to the xml element --->
		<cfloop item="i" collection="#arguments#">
			<cfset node.xmlAttributes["#lcase(i)#"] = arguments[i] />
		</cfloop>
		
		<!--- remove the app if it was already installed to ensure it's not doubled-up --->
		<cfset uninstall(arguments.name) />
		
		<!--- add the new xml element --->
		<cflock name="#instance.config#" type="exclusive" timeout="10">
			<cfset ArrayAppend(xml.coldbox.xmlChildren,node) />
			<cfset SaveConfig() />
		</cflock>
		
		<!--- write a wrapper for the project's application.cfc --->
		<cfset writeApplicationCFC(argumentcollection=arguments) />
		
		<!--- add code to handle onRequestStart and onRequestEnd events for the sub-app --->
		<cfset writeRequestEvents(arguments.name,arguments.path) />
	</cffunction>
	
	<cffunction name="uninstall" access="public" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfset var config = getConfig() />
		<cfset var path = "" />
		<cfset var i = 0 />
		
		<cflock name="#instance.config#" type="exclusive" timeout="10">
			<cfloop index="i" from="#ArrayLen(config.coldbox.xmlChildren)#" to="1" step="-1">
				<cfif config.coldbox.xmlChildren[i].xmlAttributes.name is trim(lcase(arguments.name))>
					<!--- remove the onRequestStart and onRequestEnd code for this app --->
					<cfset deleteRequestEvents(arguments.name,config.coldbox.xmlChildren[i].xmlAttributes.path) />
					
					<!--- remove the app config --->
					<cfset ArrayDeleteAt(config.coldbox.xmlChildren,i) />
					
					<!--- save all config --->
					<cfset saveConfig() />
					
					<!--- we don't need to loop through the array any more since we found the one to remove --->
					<cfbreak />
				</cfif>
			</cfloop>
		</cflock>
	</cffunction>
	
	<cffunction name="ExecuteEvent" access="public" output="false">
		<cfargument name="EventName" type="string" required="true" />
		<cfargument name="ApplicationScope" type="struct" />
		<cfargument name="SessionScope" type="struct" />
		<cfset var app = getConfig().coldbox.xmlChildren />
		<cfset var i = 0 />
		
		<cfloop index="i" from="1" to="#ArrayLen(app)#">
			<cfinvoke component="#getBean(app[i].xmlAttributes.name)#" method="#EventName#">
				<cfif isDefined("arguments.sessionscope")>
					<cfinvokeargument name="1" value="#arguments.sessionscope#" />
					<cfinvokeargument name="2" value="#arguments.applicationscope#" />
				<cfelseif isDefined("arguments.applicationscope")>
					<cfinvokeargument name="1" value="#arguments.applicationscope#" />
				</cfif>
			</cfinvoke>
		</cfloop>
	</cffunction>
	
	<cffunction name="getController" access="public" output="false">
		<cfargument name="appname" type="string" required="true" />
		<cfargument name="errordetail" type="string" required="false" default="" />
		
		<cftry>
			<cfreturn application["cbx_#trim(arguments.appname)#"] />
			<cfcatch>
				<cfthrow type="onTap.ColdBox.ApplicationNotFound" 
					message="onTap: Can't find ColdBox application #arguments.appname#" 
					detail="#arguments.errordetail#" />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="RunEvent" access="public" output="true" returntype="struct">
		<cfargument name="appname" type="string" required="true" />
		<cfargument name="event" type="string" required="true" />
		<cfargument name="parameters" type="struct" required="false" default="#structNew()#" />
		<cfargument name="prepostExempt" type="boolean" required="false" default="false" />
		<cfargument name="private" type="boolean" required="false" default="true" />
		<cfscript>
			var Controller = getController(appname,"Failed executing event: #arguments.event#");
			var Context = Controller.getRequestService().getContext(); 
			var args = structNew(); 
			
			args.default = false; 
			structAppend(args,arguments,false); 
			structDelete(args,"appname"); 
			structDelete(args,"parameters"); 
			
			Context.setValue(Controller.getSetting("EventName"),arguments.event); 
			Context.collectionAppend(arguments.parameters,true); 
			Controller.runEvent(argumentcollection=args); 
			return Context.getCollection(); 
		</cfscript>
	</cffunction>
	
	<cffunction name="getRequestCollection" access="public" output="false">
		<cfargument name="appname" type="string" required="true" />
		<cfset var Controller = getController(appname,"Failed getting request collection") />
		<cfreturn Controller.getRequestService().getContext().getCollection() />
	</cffunction>
	
	<cffunction name="containsBean" access="public" output="false">
		<cfargument name="BeanName" type="string" required="true" />
		<cfset var array = XmlSearch(getConfig(),"/*/app[@name='#lcase(arguments.BeanName)#']") />
		<cfreturn iif(ArrayLen(array),true,false) />
	</cffunction>
	
	<cffunction name="getBean" access="public" output="false">
		<cfargument name="BeanName" type="string" required="true" />
		<cfset var config = getAppConfig(BeanName) />
		<cfset var app = CreateObject("component","cfc.coldbox.app.#lcase(trim(arguments.BeanName))#") />
		<cfreturn app />
	</cffunction>
	
	<cffunction name="getImportedApplicationList" access="public" output="false">
		<cfset var cfg = getConfig() />
		<cfset var loc = structNew() />
		<cfset var result = QueryNew("name,location,path") />
		<cfset var x = 0 />
		<cfset var i = 0 />
		
		<cfset i = ArrayLen(cfg.coldbox.xmlChildren)>
		<cfif i>
			<cfset QueryAddRow(result,i) />
			
			<!--- use a structure to sort the query results because we can't use order by upper(column) in a qeury of query --->
			<cfset loc.st = structNew() />
			<cfloop index="i" from="1" to="#ArrayLen(cfg.coldbox.xmlChildren)#">
				<cfset loc.st[cfg.coldbox.xmlChildren[i].xmlAttributes.name] = cfg.coldbox.xmlChildren[i].xmlAttributes />
			</cfloop>
			
			<cfset i = 1 />
			<cfloop index="x" list="#listSort(structKeyList(loc.st),'textnocase')#">
				<cfset result.name[i] = loc.st[x].name />
				<cfset result.location[i] = loc.st[x].location />
				<cfset result.path[i] = loc.st[x].path />
				<cfset i = i + 1 />
			</cfloop>
		</cfif>
		
		<cfreturn result />
	</cffunction>
</cfcomponent>
