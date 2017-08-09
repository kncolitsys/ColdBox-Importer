<cfcomponent displayname="ColdBox.ContentExtractor" extends="cfc.ontap" output="false">
	
	<cfset variables.instance = structNew() />
	<cfset variables.iCanREMatch = StructKeyExists(getFunctionList(),"rematch") />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="app" type="any" required="true" />
		<cfargument name="location" type="string" required="true" />
		
		<cfset structAppend(instance,arguments,true) />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getCache" access="private" output="false">
		<cfreturn instance.cache />
	</cffunction>
	
	<cffunction name="getApp" access="private" output="false">
		<cfreturn instance.app />
	</cffunction>
	
	<cffunction name="getLocation" access="private" output="false">
		<cfreturn instance.location />
	</cffunction>
	
	<cffunction name="MyREMatch" access="private" output="false" returntype="array" 
	hint="performs a rematch() or equivalent if the function isn't available">
		<cfargument name="expression" type="string" required="true" />
		<cfargument name="string" type="string" required="true" />
		<cfset var result = "" />
		<cfset var i = 0 />
		
		<cfif iCanREMatch>
			<cfreturn rematchnocase(expression,string) />
		<cfelse>
			<cfset result = refindnocase(expression,string,1,true) />
			<cfloop index="i" from="1" to="#ArrayLen(result.pos)#">
				<cfset result.pos[i] = mid(string,result.pos[i],result.len[i]) />
			</cfloop>
			<cfset result = result.pos />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="extractHTMLHead" access="private" output="false">
		<cfargument name="content" type="string" required="true" />
		<cfscript>
			var page = getTap().getPage(); 
			var loc = structNew(); 
			var i = 0; 
			// get the html head content 
			loc.head = rereplacenocase(arguments.content,"^.*<head(\s[^>]*)?>(.*)</head>.*$","\2"); 
			if (not len(trim(loc.head))) { return false; } 
			
			loc.rex = "^(.*)<title>([^<]*)</title>(.*)$"; 
			loc.title = rereplacenocase(loc.head,loc.rex,"\2"); 
			if (len(loc.title)) { 
				page.head.title = loc.title; 
				loc.head = rereplacenocase(loc.head,loc.rex,"\1\3"); 
			} 
			
			// set metatags the way we do it in the onTap framework 
			loc.meta = MyREMatch("<meta\s[^>]*>",loc.head); 
			for (i = 1; i lte ArrayLen(loc.meta); i = i + 1) { 
				try { 
					loc.meta[i] = XmlParse(rereplacenocase(loc.meta[i],"/?>","/>")).meta; 
					loc.name = iif(structKeyExists(loc.meta[i].xmlAttributes,"name"),de("name"),de("http-equiv")); 
					page.meta[loc.meta[i].xmlAttributes[loc.name]] = loc.meta[i].xmlAttributes.content; 
				} catch (any e) { ; } 
			} 
			
			// remove meta tags from the remaining head content 
			loc.head = rereplacenocase(loc.head,"<meta\s[^>]*>","","ALL"); 
			
			// put the remaining content into a variable we can use later 
			page.head.coldbox = trim(loc.head); 
			
			return true; 
		</cfscript>
	</cffunction>
	
	<cffunction name="extractHTMLBody" access="public" output="false">
		<cfargument name="content" type="string" required="true" />
		<cfscript>
			var page = getTap().getPage(); 
			var loc = structNew(); 
			var i = 0; 
			
			// find the body tag 
			loc.rex = "<body(\s[^>]*)?>"; 
			loc.tag = rereplacenocase(arguments.content,"^.*(#loc.rex#).*$","\1"); 
			loc.content = rereplacenocase(arguments.content,"^.*#loc.rex#(.*)</body>.*$","\2"); 
			
			// add javascript events from the body tag 
			loc.event = MyREMatch("\son\w+""[^""]+""",loc.tag); 
			for (i = 1; i lte ArrayLen(loc.event); i = i + 1) { 
				page.eventAdd(rereplacenocase(loc.event[i],"^\son(\w+)"".*","\1"), 
					rereplacenocase(loc.event[i],"^\son\w+""([^""]+).*","\1")); 
			} 
			
			// fix src attributes in images, etc. 
			return loc.content; 
		</cfscript>
	</cffunction>
	
	<cffunction name="fixSRC" access="private" output="false">
		<cfargument name="content" type="string" required="true" />
		<cfset var href = getTap().getHREF() />
		<cfset var loc = structNew() />
		<cfset loc.here = rereplacenocase(href.getURL("","C"),"\?$","") />
		<cfset loc.domain = href.getURL("/","D") />
		<cfset loc.location = href.getURL("/#getLocation()#/","D") />
		
		<!--- replace all href and src attributes for images, script tags, buttons, etc. 
		-- don't include any links with fully-qualified urls including the protocol, i.e. http:// or mailto: --->
		<cfset content = rereplacenocase(content,"(<a\s[^>]*href="")#loc.location#index.cfm","\1#loc.here#","ALL") />
		<cfset content = rereplacenocase(content,"(src|href)=""/","\1=""#loc.domain#","ALL") />
		<cfset content = rereplacenocase(content,"(src|href)=""(?!\w+:)([^""]+)","\1=""#loc.location#\2","AlL") />
		<cfset content = replacenocase(content,"/index.cfm?","/?","ALL") />
		
		<cfreturn content />
	</cffunction>
	
	<cffunction name="extractContent" access="public" output="false">
		<cfset var app = getApp() />
		<cfset var result = "" />
		
		<cfsavecontent variable="result">
			<cfset app.onRequestStart(cgi.SCRIPT_NAME) />
		</cfsavecontent>
		
		<!--- fix SRC attributes for css, images, etc. --->
		<cfset result = fixSRC(trim(result)) />
		
		<!--- if we don't find an html head, then don't bother trying to extract html body from the content --->
		<cfif extractHTMLHead(result)>
			<cfset result = extractHTMLBody(result) />
		<cfelse>
			<!---  couldn't find the html head tags, so lets just return the content unchanged - this suppresses the onTap HTML structure for the request --->
			<cfset getTap().getPage().doctype = "unknown" />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>